import Foundation
import GRDB

public final class GRDBTransactionRepository: TransactionRepositoryProtocol, Sendable {

    private let database: AppDatabase

    public init(database: AppDatabase) {
        self.database = database
    }

    public func getAllTransactions() async throws -> [Transaction] {
        try await database.writer.read { db in
            let rows = try Row.fetchAll(db, sql: """
                SELECT t.*, c.name as cat_name, c.icon_name as cat_icon, c.color_hex as cat_color, c.type as cat_type, c.is_default as cat_is_default
                FROM transactions t
                JOIN categories c ON t.category_id = c.id
                ORDER BY t.timestamp DESC, t.id DESC
            """)

            return rows.map { Self.rowToTransaction($0) }
        }
    }

    public func getTransaction(id: Int64) async throws -> Transaction? {
        try await database.writer.read { db in
            guard let row = try Row.fetchOne(db, sql: """
                SELECT t.*, c.name as cat_name, c.icon_name as cat_icon, c.color_hex as cat_color, c.type as cat_type, c.is_default as cat_is_default
                FROM transactions t
                JOIN categories c ON t.category_id = c.id
                WHERE t.id = ?
            """, arguments: [id]) else { return nil }

            return Self.rowToTransaction(row)
        }
    }

    public func getTransactionsBetween(startEpoch: Int64, endEpoch: Int64) async throws -> [Transaction] {
        try await database.writer.read { db in
            let rows = try Row.fetchAll(db, sql: """
                SELECT t.*, c.name as cat_name, c.icon_name as cat_icon, c.color_hex as cat_color, c.type as cat_type, c.is_default as cat_is_default
                FROM transactions t
                JOIN categories c ON t.category_id = c.id
                WHERE t.timestamp >= ? AND t.timestamp <= ?
                ORDER BY t.timestamp DESC, t.id DESC
            """, arguments: [startEpoch, endEpoch])

            return rows.map { Self.rowToTransaction($0) }
        }
    }

    public func insertTransaction(_ transaction: Transaction) async throws -> Int64 {
        try await database.writer.write { db in
            var record = TransactionRecord(
                amountSubunits: transaction.amount.subunits,
                type: transaction.type.rawValue,
                categoryId: transaction.categoryId,
                paymentMethod: transaction.paymentMethod.rawValue,
                rawPaymentMethod: transaction.rawPaymentMethod ?? transaction.paymentMethod.rawValue,
                transferPairId: transaction.transferPairId,
                note: transaction.note,
                timestamp: transaction.timestamp,
                createdAt: transaction.createdAt,
                updatedAt: transaction.updatedAt,
                isInternalTransfer: transaction.isInternalTransfer,
                recurringTransactionId: transaction.recurringTransactionId,
                receiptImagePath: transaction.receiptImagePath,
                originalAmountSubunits: transaction.originalAmount.subunits,
                currencyCode: transaction.currencyCode,
                exchangeRate: transaction.exchangeRate,
                exchangeRateDate: transaction.exchangeRateDate,
                exchangeRateSource: transaction.exchangeRateSource,
                travelWalletId: transaction.travelWalletId
            )
            try record.insert(db)
            return record.id ?? 0
        }
    }

    public func updateTransaction(_ transaction: Transaction) async throws {
        try await database.writer.write { db in
            let now = Int64(Date().timeIntervalSince1970 * 1000)

            // If internal transfer, atomically synchronize its paired counterpart
            if transaction.isInternalTransfer {
                var counterpartId: Int64? = transaction.transferPairId
                if counterpartId == nil {
                    if let row = try Row.fetchOne(db, sql: "SELECT transfer_pair_id, amount_subunits, timestamp, type FROM transactions WHERE id = ?", arguments: [transaction.id]) {
                        counterpartId = row["transfer_pair_id"]
                        if counterpartId == nil {
                            let oldAmount: Int64 = row["amount_subunits"]
                            let oldTs: Int64 = row["timestamp"]
                            let type: String = row["type"]
                            if let partnerRow = try Row.fetchOne(db, sql: """
                                SELECT id FROM transactions
                                WHERE is_internal_transfer = 1
                                  AND id != ?
                                  AND type != ?
                                  AND amount_subunits = ?
                                  AND ABS(timestamp - ?) <= 2000
                                LIMIT 1
                            """, arguments: [transaction.id, type, oldAmount, oldTs]) {
                                counterpartId = partnerRow["id"]
                            }
                        }
                    }
                }

                if let partnerId = counterpartId {
                    try db.execute(sql: """
                        UPDATE transactions
                        SET amount_subunits = ?,
                            original_amount_subunits = ?,
                            note = ?,
                            timestamp = ?,
                            updated_at = ?,
                            transfer_pair_id = ?
                        WHERE id = ?
                    """, arguments: [
                        transaction.amount.subunits,
                        transaction.originalAmount.subunits,
                        transaction.note,
                        transaction.timestamp,
                        now,
                        transaction.id,
                        partnerId
                    ])
                }
            }

            var record = TransactionRecord(
                id: transaction.id,
                amountSubunits: transaction.amount.subunits,
                type: transaction.type.rawValue,
                categoryId: transaction.categoryId,
                paymentMethod: transaction.paymentMethod.rawValue,
                rawPaymentMethod: transaction.rawPaymentMethod ?? transaction.paymentMethod.rawValue,
                transferPairId: transaction.transferPairId,
                note: transaction.note,
                timestamp: transaction.timestamp,
                createdAt: transaction.createdAt,
                updatedAt: now,
                isInternalTransfer: transaction.isInternalTransfer,
                recurringTransactionId: transaction.recurringTransactionId,
                receiptImagePath: transaction.receiptImagePath,
                originalAmountSubunits: transaction.originalAmount.subunits,
                currencyCode: transaction.currencyCode,
                exchangeRate: transaction.exchangeRate,
                exchangeRateDate: transaction.exchangeRateDate,
                exchangeRateSource: transaction.exchangeRateSource,
                travelWalletId: transaction.travelWalletId
            )
            try record.update(db)

            // Synchronize paid occurrence amount if linked to a recurring occurrence
            let txId = transaction.id
            try db.execute(
                sql: """
                UPDATE recurring_transaction_occurrences
                SET amount_subunits = ?, updated_at = ?
                WHERE transaction_id = ?
                """,
                arguments: [transaction.amount.subunits, now, txId]
            )
        }
    }

    private static func rowToTransaction(_ row: Row) -> Transaction {
        let category = Category(
            id: row["category_id"],
            name: row["cat_name"],
            iconName: row["cat_icon"],
            colorHex: row["cat_color"],
            type: TransactionType(rawValue: row["cat_type"]) ?? .expense,
            isDefault: row["cat_is_default"] == 1
        )

        let isTransfer: Bool = (row["is_internal_transfer"] as Int? ?? 0) == 1
        let recurringId: Int64? = row["recurring_transaction_id"]
        let receiptPath: String? = row["receipt_image_path"]
        let origSubunits: Int64 = row["original_amount_subunits"] ?? row["amount_subunits"]
        let currCode: String = row["currency_code"] ?? "INR"
        let rate: Double = row["exchange_rate"] ?? 1.0
        let rateDate: Int64? = row["exchange_rate_date"]
        let rateSource: String = row["exchange_rate_source"] ?? "PRIMARY"
        let walletId: Int64? = row["travel_wallet_id"]
        let rawPm: String? = row["raw_payment_method"]
        let pmString: String? = rawPm ?? row["payment_method"]
        let pairId: Int64? = row["transfer_pair_id"]

        return Transaction(
            id: row["id"],
            amount: Amount(subunits: row["amount_subunits"]),
            type: TransactionType(rawValue: row["type"]) ?? .expense,
            categoryId: row["category_id"],
            category: category,
            paymentMethod: PaymentMethod.fromString(pmString),
            rawPaymentMethod: rawPm,
            transferPairId: pairId,
            note: row["note"],
            timestamp: row["timestamp"],
            createdAt: row["created_at"],
            updatedAt: row["updated_at"],
            isInternalTransfer: isTransfer,
            recurringTransactionId: recurringId,
            receiptImagePath: receiptPath,
            originalAmount: Amount(subunits: origSubunits),
            currencyCode: currCode,
            exchangeRate: rate,
            exchangeRateDate: rateDate,
            exchangeRateSource: rateSource,
            travelWalletId: walletId
        )
    }

    public func getTransactionsForWallet(walletId: Int64) async throws -> [Transaction] {
        try await database.writer.read { db in
            let rows = try Row.fetchAll(db, sql: """
                SELECT t.*, c.name as cat_name, c.icon_name as cat_icon, c.color_hex as cat_color, c.type as cat_type, c.is_default as cat_is_default
                FROM transactions t
                JOIN categories c ON t.category_id = c.id
                WHERE t.travel_wallet_id = ?
                ORDER BY t.timestamp DESC, t.id DESC
            """, arguments: [walletId])
            return rows.map { Self.rowToTransaction($0) }
        }
    }

    public func getTransactionsByCurrency(currencyCode: String) async throws -> [Transaction] {
        try await database.writer.read { db in
            let rows = try Row.fetchAll(db, sql: """
                SELECT t.*, c.name as cat_name, c.icon_name as cat_icon, c.color_hex as cat_color, c.type as cat_type, c.is_default as cat_is_default
                FROM transactions t
                JOIN categories c ON t.category_id = c.id
                WHERE UPPER(t.currency_code) = ?
                ORDER BY t.timestamp DESC, t.id DESC
            """, arguments: [currencyCode.uppercased()])
            return rows.map { Self.rowToTransaction($0) }
        }
    }

    public func deleteTransaction(id: Int64) async throws {
        try await database.writer.write { db in
            let now = Int64(Date().timeIntervalSince1970 * 1000)

            // Look up transaction details for transfer link & cleanup
            if let txRow = try Row.fetchOne(db, sql: "SELECT id, is_internal_transfer, transfer_pair_id, amount_subunits, timestamp, type FROM transactions WHERE id = ?", arguments: [id]) {
                let isTransfer: Bool = (txRow["is_internal_transfer"] as Int? ?? 0) == 1
                if isTransfer {
                    var counterpartId: Int64? = txRow["transfer_pair_id"]
                    if counterpartId == nil {
                        // Safe fallback heuristic for legacy unpaired transfers
                        let amount: Int64 = txRow["amount_subunits"]
                        let ts: Int64 = txRow["timestamp"]
                        let type: String = txRow["type"]
                        if let partnerRow = try Row.fetchOne(db, sql: """
                            SELECT id FROM transactions
                            WHERE is_internal_transfer = 1
                              AND id != ?
                              AND type != ?
                              AND amount_subunits = ?
                              AND ABS(timestamp - ?) <= 2000
                            LIMIT 1
                        """, arguments: [id, type, amount, ts]) {
                            counterpartId = partnerRow["id"]
                        }
                    }

                    // Atomically delete linked counterpart
                    if let partnerId = counterpartId {
                        Self.cleanUpLinkedTransactionResources(db: db, id: partnerId, now: now)
                        _ = try TransactionRecord.deleteOne(db, key: partnerId)
                    }
                }
            }

            Self.cleanUpLinkedTransactionResources(db: db, id: id, now: now)
            _ = try TransactionRecord.deleteOne(db, key: id)
        }
    }

    private static func cleanUpLinkedTransactionResources(db: Database, id: Int64, now: Int64) {
        if let txRow = try? Row.fetchOne(db, sql: "SELECT receipt_image_path FROM transactions WHERE id = ?", arguments: [id]),
           let receiptPath: String = txRow["receipt_image_path"], !receiptPath.isEmpty {
            ReceiptStorageService.shared.deleteReceiptImage(path: receiptPath)
        }

        if let occRow = try? Row.fetchOne(db, sql: "SELECT id, scheduled_date FROM recurring_transaction_occurrences WHERE transaction_id = ?", arguments: [id]) {
            let occId: Int64 = occRow["id"]
            let scheduledDate: Int64 = occRow["scheduled_date"]
            let resolved = RecurrenceEngine.resolveStatus(scheduledDateEpoch: scheduledDate, isPaid: false, isSkipped: false)
            try? db.execute(
                sql: """
                UPDATE recurring_transaction_occurrences
                SET transaction_id = NULL, paid_at = NULL, status = ?, updated_at = ?
                WHERE id = ?
                """,
                arguments: [resolved.rawValue, now, occId]
            )
        }
    }

    public func getNetBalance() async throws -> Amount {
        try await database.writer.read { db in
            let inflow = try Int64.fetchOne(db, sql: "SELECT COALESCE(SUM(amount_subunits), 0) FROM transactions WHERE type = 'INCOME'") ?? 0
            let outflow = try Int64.fetchOne(db, sql: "SELECT COALESCE(SUM(amount_subunits), 0) FROM transactions WHERE type = 'EXPENSE'") ?? 0
            return Amount(subunits: inflow - outflow)
        }
    }

    public func getTotalExpense(startEpoch: Int64, endEpoch: Int64) async throws -> Amount {
        try await database.writer.read { db in
            let expense = try Int64.fetchOne(
                db,
                sql: """
                SELECT COALESCE(SUM(amount_subunits), 0)
                FROM transactions
                WHERE type = 'EXPENSE'
                  AND is_internal_transfer = 0
                  AND timestamp >= ? AND timestamp <= ?
                """,
                arguments: [startEpoch, endEpoch]
            ) ?? 0
            return Amount(subunits: expense)
        }
    }

    public func getTotalIncome(startEpoch: Int64, endEpoch: Int64) async throws -> Amount {
        try await database.writer.read { db in
            let income = try Int64.fetchOne(
                db,
                sql: """
                SELECT COALESCE(SUM(amount_subunits), 0)
                FROM transactions
                WHERE type = 'INCOME'
                  AND is_internal_transfer = 0
                  AND timestamp >= ? AND timestamp <= ?
                """,
                arguments: [startEpoch, endEpoch]
            ) ?? 0
            return Amount(subunits: income)
        }
    }

    public func getTotalInflow(startEpoch: Int64, endEpoch: Int64) async throws -> Amount {
        try await database.writer.read { db in
            let inflow = try Int64.fetchOne(
                db,
                sql: """
                SELECT COALESCE(SUM(amount_subunits), 0)
                FROM transactions
                WHERE type = 'INCOME'
                  AND timestamp >= ? AND timestamp <= ?
                """,
                arguments: [startEpoch, endEpoch]
            ) ?? 0
            return Amount(subunits: inflow)
        }
    }

    public func getTotalOutflow(startEpoch: Int64, endEpoch: Int64) async throws -> Amount {
        try await database.writer.read { db in
            let outflow = try Int64.fetchOne(
                db,
                sql: """
                SELECT COALESCE(SUM(amount_subunits), 0)
                FROM transactions
                WHERE type = 'EXPENSE'
                  AND timestamp >= ? AND timestamp <= ?
                """,
                arguments: [startEpoch, endEpoch]
            ) ?? 0
            return Amount(subunits: outflow)
        }
    }

    // MARK: - Independent Ledger Management (Cash & Account)

    private static func ledgerSqlCondition(for paymentMethod: PaymentMethod, column: String = "payment_method", rawColumn: String = "raw_payment_method") -> String {
        switch paymentMethod {
        case .cash:
            return "(UPPER(COALESCE(\(column), '')) IN ('CASH', 'WALLET') OR UPPER(COALESCE(\(rawColumn), '')) IN ('CASH', 'WALLET'))"
        case .account:
            return "(UPPER(COALESCE(\(column), '')) IN ('ACCOUNT', 'BANK_ACCOUNT', 'UPI', 'BANK', 'CARD', 'NET_BANKING', 'ONLINE', 'CHEQUE') OR UPPER(COALESCE(\(rawColumn), '')) IN ('ACCOUNT', 'BANK_ACCOUNT', 'UPI', 'BANK', 'CARD', 'NET_BANKING', 'ONLINE', 'CHEQUE'))"
        default:
            let raw = paymentMethod.rawValue
            return "(UPPER(COALESCE(\(column), '')) = '\(raw)' OR UPPER(COALESCE(\(rawColumn), '')) = '\(raw)')"
        }
    }

    public func getBalance(for paymentMethod: PaymentMethod) async throws -> Amount {
        try await database.writer.read { db in
            let condition = Self.ledgerSqlCondition(for: paymentMethod)
            let sql = """
            SELECT
                (SELECT COALESCE(SUM(amount_subunits), 0) FROM transactions WHERE type = 'INCOME' AND \(condition))
                -
                (SELECT COALESCE(SUM(amount_subunits), 0) FROM transactions WHERE type = 'EXPENSE' AND \(condition))
            """
            let net = try Int64.fetchOne(db, sql: sql) ?? 0
            return Amount(subunits: net)
        }
    }

    public func getInflow(for paymentMethod: PaymentMethod, startEpoch: Int64, endEpoch: Int64) async throws -> Amount {
        try await database.writer.read { db in
            let condition = Self.ledgerSqlCondition(for: paymentMethod)
            let sql = """
            SELECT COALESCE(SUM(amount_subunits), 0)
            FROM transactions
            WHERE type = 'INCOME'
              AND \(condition)
              AND timestamp >= ? AND timestamp <= ?
            """
            let inflow = try Int64.fetchOne(db, sql: sql, arguments: [startEpoch, endEpoch]) ?? 0
            return Amount(subunits: inflow)
        }
    }

    public func getOutflow(for paymentMethod: PaymentMethod, startEpoch: Int64, endEpoch: Int64) async throws -> Amount {
        try await database.writer.read { db in
            let condition = Self.ledgerSqlCondition(for: paymentMethod)
            let sql = """
            SELECT COALESCE(SUM(amount_subunits), 0)
            FROM transactions
            WHERE type = 'EXPENSE'
              AND \(condition)
              AND timestamp >= ? AND timestamp <= ?
            """
            let outflow = try Int64.fetchOne(db, sql: sql, arguments: [startEpoch, endEpoch]) ?? 0
            return Amount(subunits: outflow)
        }
    }

    public func getTransactions(for paymentMethod: PaymentMethod) async throws -> [Transaction] {
        try await database.writer.read { db in
            let condition = Self.ledgerSqlCondition(for: paymentMethod, column: "t.payment_method", rawColumn: "t.raw_payment_method")
            let sql = """
            SELECT t.*, c.name as cat_name, c.icon_name as cat_icon, c.color_hex as cat_color, c.type as cat_type, c.is_default as cat_is_default
            FROM transactions t
            JOIN categories c ON t.category_id = c.id
            WHERE \(condition)
            ORDER BY t.timestamp DESC, t.id DESC
            """
            let rows = try Row.fetchAll(db, sql: sql)
            return rows.map { Self.rowToTransaction($0) }
        }
    }

    public func transferBetweenLedgers(
        from source: PaymentMethod,
        to destination: PaymentMethod,
        amount: Amount,
        note: String?,
        timestamp: Int64
    ) async throws -> (outflowId: Int64, inflowId: Int64) {
        try await database.writer.write { db in
            let now = Int64(Date().timeIntervalSince1970 * 1000)
            let txTime = timestamp > 0 ? timestamp : now

            var transferCatId: Int64 = 1
            if let catRow = try Row.fetchOne(db, sql: "SELECT id FROM categories WHERE name LIKE '%Transfer%' OR name LIKE '%General%' LIMIT 1") {
                transferCatId = catRow["id"]
            }

            let defaultDesc = "Transfer from \(source.displayName) to \(destination.displayName)"
            let fullNote = (note?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false) ? note! : defaultDesc

            // 1. Outflow transaction from source ledger
            var outflow = TransactionRecord(
                amountSubunits: amount.subunits,
                type: TransactionType.expense.rawValue,
                categoryId: transferCatId,
                paymentMethod: source.rawValue,
                rawPaymentMethod: source.rawValue,
                note: fullNote,
                timestamp: txTime,
                createdAt: now,
                updatedAt: now,
                isInternalTransfer: true,
                originalAmountSubunits: amount.subunits,
                currencyCode: "INR",
                exchangeRate: 1.0,
                exchangeRateDate: txTime,
                exchangeRateSource: "PRIMARY"
            )
            try outflow.insert(db)
            let outId = outflow.id ?? 0

            // 2. Inflow transaction to destination ledger, linked to outflow
            var inflow = TransactionRecord(
                amountSubunits: amount.subunits,
                type: TransactionType.income.rawValue,
                categoryId: transferCatId,
                paymentMethod: destination.rawValue,
                rawPaymentMethod: destination.rawValue,
                transferPairId: outId,
                note: fullNote,
                timestamp: txTime,
                createdAt: now,
                updatedAt: now,
                isInternalTransfer: true,
                originalAmountSubunits: amount.subunits,
                currencyCode: "INR",
                exchangeRate: 1.0,
                exchangeRateDate: txTime,
                exchangeRateSource: "PRIMARY"
            )
            try inflow.insert(db)
            let inId = inflow.id ?? 0

            // 3. Atomically link outflow to inflow
            try db.execute(sql: "UPDATE transactions SET transfer_pair_id = ? WHERE id = ?", arguments: [inId, outId])

            return (outId, inId)
        }
    }

    public func reverseTransfer(transactionId: Int64) async throws -> (outflowId: Int64, inflowId: Int64) {
        try await database.writer.write { db in
            let now = Int64(Date().timeIntervalSince1970 * 1000)

            guard let txRow = try Row.fetchOne(db, sql: """
                SELECT id, type, payment_method, raw_payment_method, amount_subunits, note, transfer_pair_id, is_internal_transfer, timestamp
                FROM transactions WHERE id = ?
            """, arguments: [transactionId]) else {
                throw NSError(domain: "GRDBTransactionRepository", code: 404, userInfo: [NSLocalizedDescriptionKey: "Transaction not found."])
            }

            let isTransfer: Bool = (txRow["is_internal_transfer"] as Int? ?? 0) == 1
            guard isTransfer else {
                throw NSError(domain: "GRDBTransactionRepository", code: 400, userInfo: [NSLocalizedDescriptionKey: "Transaction is not an internal transfer."])
            }

            let currentType: String = txRow["type"]
            let currentPmRaw: String = txRow["payment_method"] ?? "CASH"
            let amountSubunits: Int64 = txRow["amount_subunits"]
            let origNote: String? = txRow["note"]

            // Find counterpart
            var partnerRow: Row? = nil
            if let pairId: Int64 = txRow["transfer_pair_id"] {
                partnerRow = try Row.fetchOne(db, sql: "SELECT id, type, payment_method, raw_payment_method FROM transactions WHERE id = ?", arguments: [pairId])
            }
            if partnerRow == nil {
                let ts: Int64 = txRow["timestamp"]
                partnerRow = try Row.fetchOne(db, sql: """
                    SELECT id, type, payment_method, raw_payment_method FROM transactions
                    WHERE is_internal_transfer = 1
                      AND id != ?
                      AND type != ?
                      AND amount_subunits = ?
                      AND ABS(timestamp - ?) <= 2000
                    LIMIT 1
                """, arguments: [transactionId, currentType, amountSubunits, ts])
            }

            guard let partner = partnerRow else {
                throw NSError(domain: "GRDBTransactionRepository", code: 404, userInfo: [NSLocalizedDescriptionKey: "Linked counterpart of transfer not found."])
            }

            let partnerPmRaw: String = partner["payment_method"] ?? "ACCOUNT"

            // If current was expense (source outflow), then source = currentPm, dest = partnerPm
            // If current was income (dest inflow), then source = partnerPm, dest = currentPm
            let originalSource = (currentType == TransactionType.expense.rawValue) ? currentPmRaw : partnerPmRaw
            let originalDest = (currentType == TransactionType.expense.rawValue) ? partnerPmRaw : currentPmRaw

            // Reverse transfer goes from originalDest back to originalSource
            let revSourceMethod = PaymentMethod.fromString(originalDest)
            let revDestMethod = PaymentMethod.fromString(originalSource)

            var transferCatId: Int64 = 1
            if let catRow = try Row.fetchOne(db, sql: "SELECT id FROM categories WHERE name LIKE '%Transfer%' OR name LIKE '%General%' LIMIT 1") {
                transferCatId = catRow["id"]
            }

            let revNote = "Reversal: " + (origNote ?? "Transfer from \(originalSource) to \(originalDest)")

            // 1. Outflow from reverse source (original destination)
            var outflow = TransactionRecord(
                amountSubunits: amountSubunits,
                type: TransactionType.expense.rawValue,
                categoryId: transferCatId,
                paymentMethod: revSourceMethod.rawValue,
                rawPaymentMethod: originalDest,
                note: revNote,
                timestamp: now,
                createdAt: now,
                updatedAt: now,
                isInternalTransfer: true,
                originalAmountSubunits: amountSubunits,
                currencyCode: "INR",
                exchangeRate: 1.0,
                exchangeRateDate: now,
                exchangeRateSource: "PRIMARY"
            )
            try outflow.insert(db)
            let outId = outflow.id ?? 0

            // 2. Inflow into reverse destination (original source), linked to outflow
            var inflow = TransactionRecord(
                amountSubunits: amountSubunits,
                type: TransactionType.income.rawValue,
                categoryId: transferCatId,
                paymentMethod: revDestMethod.rawValue,
                rawPaymentMethod: originalSource,
                transferPairId: outId,
                note: revNote,
                timestamp: now,
                createdAt: now,
                updatedAt: now,
                isInternalTransfer: true,
                originalAmountSubunits: amountSubunits,
                currencyCode: "INR",
                exchangeRate: 1.0,
                exchangeRateDate: now,
                exchangeRateSource: "PRIMARY"
            )
            try inflow.insert(db)
            let inId = inflow.id ?? 0

            // 3. Atomically link outflow to inflow
            try db.execute(sql: "UPDATE transactions SET transfer_pair_id = ? WHERE id = ?", arguments: [inId, outId])

            return (outId, inId)
        }
    }
}
