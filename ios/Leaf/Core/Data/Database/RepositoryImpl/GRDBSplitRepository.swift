import Foundation
import GRDB

public final class GRDBSplitRepository: SplitRepositoryProtocol, Sendable {

    private let database: AppDatabase

    public init(database: AppDatabase) {
        self.database = database
    }

    public func getAllSplitExpenses() async throws -> [SplitExpense] {
        try await database.writer.read { db in
            let expenses = try SplitExpenseRecord.order(Column("date").desc).fetchAll(db)
            var results: [SplitExpense] = []

            for exp in expenses {
                guard let expId = exp.id else { continue }
                let participantRecords = try SplitParticipantRecord
                    .filter(Column("split_expense_id") == expId)
                    .fetchAll(db)

                var participants: [SplitParticipant] = []
                for p in participantRecords {
                    guard let pId = p.id else { continue }
                    let paymentRecords = try SplitPaymentRecord
                        .filter(Column("participant_id") == pId)
                        .order(Column("date").desc)
                        .fetchAll(db)

                    participants.append(Self.buildParticipantFromRecord(p, payments: paymentRecords))
                }

                results.append(
                    SplitExpense(
                        id: expId,
                        title: exp.title,
                        totalAmount: Amount(subunits: exp.totalAmountSubunits),
                        date: exp.date,
                        categoryId: exp.categoryId,
                        paidBy: exp.paidBy,
                        splitMethod: exp.splitMethod,
                        qrImagePath: exp.qrImagePath,
                        addToTransactions: exp.addToTransactions,
                        expenseTransactionId: exp.expenseTransactionId,
                        paymentMethod: PaymentMethod.fromString(exp.paymentMethod),
                        groupId: exp.groupId,
                        itemsJson: exp.itemsJson,
                        currencyCode: exp.currencyCode,
                        exchangeRate: exp.exchangeRate,
                        primaryTotalAmount: Amount(subunits: exp.primaryTotalAmountSubunits),
                        participants: participants,
                        createdAt: exp.createdAt,
                        updatedAt: exp.updatedAt
                    )
                )
            }

            return results
        }
    }

    public func getSplitExpense(id: Int64) async throws -> SplitExpense? {
        try await database.writer.read { db in
            guard let exp = try SplitExpenseRecord.fetchOne(db, key: id), let expId = exp.id else { return nil }
            let participantRecords = try SplitParticipantRecord
                .filter(Column("split_expense_id") == expId)
                .fetchAll(db)

            var participants: [SplitParticipant] = []
            for p in participantRecords {
                guard let pId = p.id else { continue }
                let paymentRecords = try SplitPaymentRecord
                    .filter(Column("participant_id") == pId)
                    .order(Column("date").desc)
                    .fetchAll(db)

                participants.append(Self.buildParticipantFromRecord(p, payments: paymentRecords))
            }

            return SplitExpense(
                id: expId,
                title: exp.title,
                totalAmount: Amount(subunits: exp.totalAmountSubunits),
                date: exp.date,
                categoryId: exp.categoryId,
                paidBy: exp.paidBy,
                splitMethod: exp.splitMethod,
                qrImagePath: exp.qrImagePath,
                addToTransactions: exp.addToTransactions,
                expenseTransactionId: exp.expenseTransactionId,
                paymentMethod: PaymentMethod.fromString(exp.paymentMethod),
                groupId: exp.groupId,
                itemsJson: exp.itemsJson,
                participants: participants,
                createdAt: exp.createdAt,
                updatedAt: exp.updatedAt
            )
        }
    }

    public func insertSplitExpense(_ split: SplitExpense) async throws -> Int64 {
        try await database.writer.write { db in
            let isCurrentUserPayer = Self.isUserCurrent(name: split.paidBy, participants: split.participants)
            var expenseTxId: Int64? = isCurrentUserPayer ? split.expenseTransactionId : nil

            // Scenario A: Current user paid original bill -> Record total amount as EXPENSE in personal ledger
            // Scenario B: Another participant paid (e.g. Alice) -> Do NOT record total bill as an expense for current user upon split creation
            if split.addToTransactions && isCurrentUserPayer && expenseTxId == nil {
                var txRecord = TransactionRecord(
                    amountSubunits: split.totalAmount.subunits,
                    type: TransactionType.expense.rawValue,
                    categoryId: split.categoryId,
                    paymentMethod: split.paymentMethod.rawValue,
                    note: "Split – \(split.title)",
                    timestamp: split.date,
                    createdAt: split.date,
                    updatedAt: split.date
                )
                try txRecord.insert(db)
                expenseTxId = txRecord.id
            }

            var record = SplitExpenseRecord(
                title: split.title,
                totalAmountSubunits: split.totalAmount.subunits,
                date: split.date,
                categoryId: split.categoryId,
                paidBy: split.paidBy,
                splitMethod: split.splitMethod,
                qrImagePath: split.qrImagePath,
                addToTransactions: split.addToTransactions,
                expenseTransactionId: expenseTxId,
                paymentMethod: split.paymentMethod.rawValue,
                groupId: split.groupId,
                itemsJson: split.itemsJson,
                currencyCode: split.currencyCode,
                exchangeRate: split.exchangeRate,
                primaryTotalAmountSubunits: split.primaryTotalAmount.subunits,
                createdAt: split.createdAt,
                updatedAt: split.updatedAt
            )
            try record.insert(db)
            guard let expenseId = record.id else { return 0 }

            for p in split.participants {
                var pRecord = SplitParticipantRecord(
                    splitExpenseId: expenseId,
                    name: p.name,
                    isCurrentUser: p.isCurrentUser,
                    amountSubunits: p.amount.subunits,
                    settlementStatus: p.settlementStatus.rawValue,
                    settledAt: p.settledAt,
                    settlementTransactionId: p.settlementTransactionId,
                    phoneNumber: p.phoneNumber
                )
                try pRecord.insert(db)
            }

            return expenseId
        }
    }

    public func updateSplitExpense(_ split: SplitExpense) async throws {
        try await database.writer.write { db in
            let isCurrentUserPayer = Self.isUserCurrent(name: split.paidBy, participants: split.participants)
            var currentTxId = split.expenseTransactionId

            if isCurrentUserPayer {
                if split.addToTransactions {
                    if let txId = currentTxId, var existingTx = try TransactionRecord.fetchOne(db, key: txId) {
                        existingTx.amountSubunits = split.totalAmount.subunits
                        existingTx.categoryId = split.categoryId
                        existingTx.paymentMethod = split.paymentMethod.rawValue
                        existingTx.note = "Split – \(split.title)"
                        existingTx.timestamp = split.date
                        existingTx.updatedAt = Int64(Date().timeIntervalSince1970 * 1000)
                        try existingTx.update(db)
                    } else if currentTxId == nil {
                        var txRecord = TransactionRecord(
                            amountSubunits: split.totalAmount.subunits,
                            type: TransactionType.expense.rawValue,
                            categoryId: split.categoryId,
                            paymentMethod: split.paymentMethod.rawValue,
                            note: "Split – \(split.title)",
                            timestamp: split.date,
                            createdAt: split.date,
                            updatedAt: split.date
                        )
                        try txRecord.insert(db)
                        currentTxId = txRecord.id
                    }
                } else if let txId = currentTxId {
                    _ = try TransactionRecord.deleteOne(db, key: txId)
                    currentTxId = nil
                }
            } else {
                // If current user is not the payer, remove any lingering upfront bill transaction
                if let txId = currentTxId {
                    _ = try TransactionRecord.deleteOne(db, key: txId)
                    currentTxId = nil
                }
            }

            var record = SplitExpenseRecord(
                id: split.id,
                title: split.title,
                totalAmountSubunits: split.totalAmount.subunits,
                date: split.date,
                categoryId: split.categoryId,
                paidBy: split.paidBy,
                splitMethod: split.splitMethod,
                qrImagePath: split.qrImagePath,
                addToTransactions: split.addToTransactions,
                expenseTransactionId: currentTxId,
                paymentMethod: split.paymentMethod.rawValue,
                groupId: split.groupId,
                itemsJson: split.itemsJson,
                currencyCode: split.currencyCode,
                exchangeRate: split.exchangeRate,
                primaryTotalAmountSubunits: split.primaryTotalAmount.subunits,
                createdAt: split.createdAt,
                updatedAt: Int64(Date().timeIntervalSince1970 * 1000)
            )
            try record.update(db)

            // Update participant records
            let existingParticipants = try SplitParticipantRecord
                .filter(Column("split_expense_id") == split.id)
                .fetchAll(db)
            let existingIds = Set(existingParticipants.compactMap { $0.id })
            let currentIds = Set(split.participants.filter { $0.id > 0 }.map { $0.id })

            // Delete removed participants
            let toDelete = existingIds.subtracting(currentIds)
            for delId in toDelete {
                _ = try SplitParticipantRecord.deleteOne(db, key: delId)
            }

            // Insert or update current participants
            for p in split.participants {
                if p.id > 0 && existingIds.contains(p.id) {
                    var pRecord = SplitParticipantRecord(
                        id: p.id,
                        splitExpenseId: split.id,
                        name: p.name,
                        isCurrentUser: p.isCurrentUser,
                        amountSubunits: p.amount.subunits,
                        settlementStatus: p.settlementStatus.rawValue,
                        settledAt: p.settledAt,
                        settlementTransactionId: p.settlementTransactionId,
                        phoneNumber: p.phoneNumber
                    )
                    try pRecord.update(db)
                } else {
                    var pRecord = SplitParticipantRecord(
                        splitExpenseId: split.id,
                        name: p.name,
                        isCurrentUser: p.isCurrentUser,
                        amountSubunits: p.amount.subunits,
                        settlementStatus: p.settlementStatus.rawValue,
                        settledAt: p.settledAt,
                        settlementTransactionId: p.settlementTransactionId,
                        phoneNumber: p.phoneNumber
                    )
                    try pRecord.insert(db)
                }
            }
        }
    }

    public func deleteSplitExpense(id: Int64) async throws {
        try await database.writer.write { db in
            // Preserves historical transactions in the ledger; removes split & participants & payments
            _ = try SplitPaymentRecord.filter(Column("split_expense_id") == id).deleteAll(db)
            _ = try SplitParticipantRecord.filter(Column("split_expense_id") == id).deleteAll(db)
            _ = try SplitExpenseRecord.deleteOne(db, key: id)
        }
    }

    public func settleParticipant(participantId: Int64, settledAt: Int64, settlementTransactionId: Int64?) async throws {
        try await database.writer.write { db in
            try db.execute(
                sql: "UPDATE split_participants SET settlement_status = 'SETTLED', settled_at = ?, settlement_transaction_id = ? WHERE id = ?",
                arguments: [settledAt, settlementTransactionId, participantId]
            )
        }
    }

    public func unsettleParticipant(participantId: Int64) async throws {
        try await database.writer.write { db in
            // If an offset transaction was created, remove it from transactions
            if let pRecord = try SplitParticipantRecord.fetchOne(db, key: participantId),
               let txId = pRecord.settlementTransactionId {
                _ = try TransactionRecord.deleteOne(db, key: txId)
            }

            try db.execute(
                sql: "UPDATE split_participants SET settlement_status = 'PENDING', settled_at = NULL, settlement_transaction_id = NULL WHERE id = ?",
                arguments: [participantId]
            )
        }
    }

    // MARK: - Partial Payments & History

    public enum SplitPaymentError: LocalizedError {
        case participantNotFound
        case invalidAmount
        case exceedsOutstandingBalance(remaining: Amount)

        public var errorDescription: String? {
            switch self {
            case .participantNotFound:
                return "Participant not found."
            case .invalidAmount:
                return "Payment amount must be strictly greater than zero."
            case .exceedsOutstandingBalance(let remaining):
                return "Payment amount cannot exceed the remaining balance of \(remaining.subunits) subunits."
            }
        }
    }

    public func recordPayment(
        splitExpenseId: Int64,
        participantId: Int64,
        amount: Amount,
        paymentMethod: PaymentMethod = .cash,
        date: Int64 = Int64(Date().timeIntervalSince1970 * 1000),
        note: String? = nil,
        createOffsetTransaction: Bool = true
    ) async throws -> SplitPayment {
        try await database.writer.write { db in
            guard let participant = try SplitParticipantRecord.fetchOne(db, key: participantId) else {
                throw SplitPaymentError.participantNotFound
            }

            guard let expense = try SplitExpenseRecord.fetchOne(db, key: splitExpenseId) else {
                throw SplitPaymentError.participantNotFound
            }

            if amount.subunits <= 0 {
                throw SplitPaymentError.invalidAmount
            }

            // Calculate current total paid
            let existingPayments = try SplitPaymentRecord
                .filter(Column("participant_id") == participantId)
                .fetchAll(db)
            let currentPaidSubunits = existingPayments.reduce(Int64(0)) { $0 + $1.amountSubunits }
            let remainingSubunits = participant.amountSubunits - currentPaidSubunits

            if amount.subunits > remainingSubunits {
                throw SplitPaymentError.exceedsOutstandingBalance(remaining: Amount(subunits: max(0, remainingSubunits)))
            }

            let allParticipants = try SplitParticipantRecord
                .filter(Column("split_expense_id") == splitExpenseId)
                .fetchAll(db)

            let isRecipientMe = Self.isUserCurrentRecord(name: expense.paidBy, participants: allParticipants)
            let isDebtorMe = participant.isCurrentUser ||
                             participant.name.caseInsensitiveCompare("Me") == .orderedSame ||
                             participant.name.caseInsensitiveCompare("You") == .orderedSame

            // Direction-aware personal ledger integration:
            // Scenario A / D: Current user is the bill payer receiving money from participant -> INCOME
            // Scenario B: Current user is settling their share with another bill payer -> EXPENSE
            // Scenario C: Neither recipient nor debtor is current user -> ZERO ledger transactions
            var offsetTxId: Int64? = nil
            if createOffsetTransaction && expense.addToTransactions {
                if isRecipientMe && !isDebtorMe {
                    // Scenario A & D: Money in -> INCOME
                    let txNote = "\(participant.name) — \(expense.title) settlement"
                    var tx = TransactionRecord(
                        amountSubunits: amount.subunits,
                        type: TransactionType.income.rawValue,
                        categoryId: expense.categoryId,
                        paymentMethod: paymentMethod.rawValue,
                        note: txNote,
                        timestamp: date,
                        createdAt: date,
                        updatedAt: date
                    )
                    try tx.insert(db)
                    offsetTxId = tx.id
                } else if !isRecipientMe && isDebtorMe {
                    // Scenario B: Money out -> EXPENSE
                    let txNote = "Settlement: \(expense.title) to \(expense.paidBy)"
                    var tx = TransactionRecord(
                        amountSubunits: amount.subunits,
                        type: TransactionType.expense.rawValue,
                        categoryId: expense.categoryId,
                        paymentMethod: paymentMethod.rawValue,
                        note: txNote,
                        timestamp: date,
                        createdAt: date,
                        updatedAt: date
                    )
                    try tx.insert(db)
                    offsetTxId = tx.id
                } else {
                    // Scenario C: External settlement between two other participants -> No personal ledger entry
                    offsetTxId = nil
                }
            }

            // Insert SplitPaymentRecord
            var paymentRecord = SplitPaymentRecord(
                splitExpenseId: splitExpenseId,
                participantId: participantId,
                amountSubunits: amount.subunits,
                date: date,
                paymentMethod: paymentMethod.rawValue,
                note: note?.trimmingCharacters(in: .whitespacesAndNewlines),
                transactionId: offsetTxId,
                createdAt: date
            )
            try paymentRecord.insert(db)

            // Recalculate participant settlement status
            let newTotalPaid = currentPaidSubunits + amount.subunits
            let newStatus: String
            let settledAtVal: Int64?

            if newTotalPaid >= participant.amountSubunits {
                newStatus = SettlementStatus.settled.rawValue
                settledAtVal = date
            } else if newTotalPaid > 0 {
                newStatus = SettlementStatus.partiallySettled.rawValue
                settledAtVal = nil
            } else {
                newStatus = SettlementStatus.pending.rawValue
                settledAtVal = nil
            }

            try db.execute(
                sql: "UPDATE split_participants SET settlement_status = ?, settled_at = ? WHERE id = ?",
                arguments: [newStatus, settledAtVal, participantId]
            )

            return SplitPayment(
                id: paymentRecord.id ?? 0,
                splitExpenseId: splitExpenseId,
                participantId: participantId,
                amount: amount,
                date: date,
                paymentMethod: paymentMethod,
                note: note,
                transactionId: offsetTxId,
                createdAt: date
            )
        }
    }

    public func reversePayment(paymentId: Int64) async throws {
        try await database.writer.write { db in
            guard let payment = try SplitPaymentRecord.fetchOne(db, key: paymentId) else { return }

            // Delete linked ledger transaction if present (whether INCOME or EXPENSE)
            if let txId = payment.transactionId {
                _ = try TransactionRecord.deleteOne(db, key: txId)
            }

            // Delete the payment record
            _ = try SplitPaymentRecord.deleteOne(db, key: paymentId)

            // Recompute remaining payments for participant
            guard let participant = try SplitParticipantRecord.fetchOne(db, key: payment.participantId) else { return }
            let remainingPayments = try SplitPaymentRecord
                .filter(Column("participant_id") == payment.participantId)
                .fetchAll(db)
            let remainingPaidSubunits = remainingPayments.reduce(Int64(0)) { $0 + $1.amountSubunits }

            let newStatus: String
            let settledAtVal: Int64?

            if remainingPaidSubunits >= participant.amountSubunits {
                newStatus = SettlementStatus.settled.rawValue
                settledAtVal = remainingPayments.last?.date ?? payment.date
            } else if remainingPaidSubunits > 0 {
                newStatus = SettlementStatus.partiallySettled.rawValue
                settledAtVal = nil
            } else {
                newStatus = SettlementStatus.pending.rawValue
                settledAtVal = nil
            }

            try db.execute(
                sql: "UPDATE split_participants SET settlement_status = ?, settled_at = ? WHERE id = ?",
                arguments: [newStatus, settledAtVal, payment.participantId]
            )
        }
    }

    public func getPaymentsForParticipant(participantId: Int64) async throws -> [SplitPayment] {
        try await database.writer.read { db in
            let records = try SplitPaymentRecord
                .filter(Column("participant_id") == participantId)
                .order(Column("date").desc)
                .fetchAll(db)

            return records.map {
                SplitPayment(
                    id: $0.id ?? 0,
                    splitExpenseId: $0.splitExpenseId,
                    participantId: $0.participantId,
                    amount: Amount(subunits: $0.amountSubunits),
                    date: $0.date,
                    paymentMethod: PaymentMethod.fromString($0.paymentMethod),
                    note: $0.note,
                    transactionId: $0.transactionId,
                    createdAt: $0.createdAt
                )
            }
        }
    }

    public func getPaymentsForSplit(splitExpenseId: Int64) async throws -> [SplitPayment] {
        try await database.writer.read { db in
            let records = try SplitPaymentRecord
                .filter(Column("split_expense_id") == splitExpenseId)
                .order(Column("date").desc)
                .fetchAll(db)

            return records.map {
                SplitPayment(
                    id: $0.id ?? 0,
                    splitExpenseId: $0.splitExpenseId,
                    participantId: $0.participantId,
                    amount: Amount(subunits: $0.amountSubunits),
                    date: $0.date,
                    paymentMethod: PaymentMethod.fromString($0.paymentMethod),
                    note: $0.note,
                    transactionId: $0.transactionId,
                    createdAt: $0.createdAt
                )
            }
        }
    }

    // MARK: - Internal Helpers

    private static func buildParticipantFromRecord(
        _ p: SplitParticipantRecord,
        payments: [SplitPaymentRecord]
    ) -> SplitParticipant {
        let paymentModels = payments.map { pay in
            SplitPayment(
                id: pay.id ?? 0,
                splitExpenseId: pay.splitExpenseId,
                participantId: pay.participantId,
                amount: Amount(subunits: pay.amountSubunits),
                date: pay.date,
                paymentMethod: PaymentMethod.fromString(pay.paymentMethod),
                note: pay.note,
                transactionId: pay.transactionId,
                createdAt: pay.createdAt
            )
        }

        let totalPaidSubunits = paymentModels.reduce(Int64(0)) { $0 + $1.amount.subunits }
        let paidAmount: Amount
        let status: SettlementStatus

        if !paymentModels.isEmpty {
            paidAmount = Amount(subunits: totalPaidSubunits)
            if totalPaidSubunits >= p.amountSubunits {
                status = .settled
            } else if totalPaidSubunits > 0 {
                status = .partiallySettled
            } else {
                status = .pending
            }
        } else {
            let rawStatus = SettlementStatus(rawValue: p.settlementStatus) ?? .pending
            status = rawStatus
            paidAmount = (rawStatus == .settled) ? Amount(subunits: p.amountSubunits) : .zero
        }

        return SplitParticipant(
            id: p.id ?? 0,
            splitExpenseId: p.splitExpenseId,
            name: p.name,
            isCurrentUser: p.isCurrentUser,
            amount: Amount(subunits: p.amountSubunits),
            paidAmount: paidAmount,
            settlementStatus: status,
            settledAt: p.settledAt,
            settlementTransactionId: p.settlementTransactionId,
            phoneNumber: p.phoneNumber,
            payments: paymentModels
        )
    }

    private static func isUserCurrent(name: String, participants: [SplitParticipant]) -> Bool {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.caseInsensitiveCompare("Me") == .orderedSame || trimmed.caseInsensitiveCompare("You") == .orderedSame {
            return true
        }
        return participants.first { $0.name.caseInsensitiveCompare(trimmed) == .orderedSame }?.isCurrentUser == true
    }

    private static func isUserCurrentRecord(name: String, participants: [SplitParticipantRecord]) -> Bool {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.caseInsensitiveCompare("Me") == .orderedSame || trimmed.caseInsensitiveCompare("You") == .orderedSame {
            return true
        }
        return participants.first { $0.name.caseInsensitiveCompare(trimmed) == .orderedSame }?.isCurrentUser == true
    }

    // MARK: - Split Groups

    public func getAllSplitGroups() async throws -> [SplitGroup] {
        try await database.writer.read { db in
            let records = try SplitGroupRecord
                .order(Column("name").asc)
                .fetchAll(db)
            return records.map {
                SplitGroup(
                    id: $0.id ?? 0,
                    name: $0.name,
                    iconName: $0.iconName,
                    colorHex: $0.colorHex,
                    createdAt: $0.createdAt
                )
            }
        }
    }

    public func getSplitGroup(id: Int64) async throws -> SplitGroup? {
        try await database.writer.read { db in
            guard let record = try SplitGroupRecord.fetchOne(db, key: id) else { return nil }
            return SplitGroup(
                id: record.id ?? 0,
                name: record.name,
                iconName: record.iconName,
                colorHex: record.colorHex,
                createdAt: record.createdAt
            )
        }
    }

    public func insertSplitGroup(_ group: SplitGroup) async throws -> Int64 {
        try await database.writer.write { db in
            var record = SplitGroupRecord(
                name: group.name,
                iconName: group.iconName,
                colorHex: group.colorHex,
                createdAt: group.createdAt
            )
            try record.insert(db)
            return record.id ?? 0
        }
    }

    public func updateSplitGroup(_ group: SplitGroup) async throws {
        try await database.writer.write { db in
            let record = SplitGroupRecord(
                id: group.id,
                name: group.name,
                iconName: group.iconName,
                colorHex: group.colorHex,
                createdAt: group.createdAt
            )
            try record.update(db)
        }
    }

    public func deleteSplitGroup(id: Int64) async throws {
        try await database.writer.write { db in
            _ = try SplitGroupRecord.deleteOne(db, key: id)
        }
    }

    public func getSplitExpensesForGroup(groupId: Int64) async throws -> [SplitExpense] {
        try await database.writer.read { db in
            let expenseRecords = try SplitExpenseRecord
                .filter(Column("group_id") == groupId)
                .order(Column("date").desc)
                .fetchAll(db)

            var results: [SplitExpense] = []
            for exp in expenseRecords {
                guard let expId = exp.id else { continue }
                let participantRecords = try SplitParticipantRecord
                    .filter(Column("split_expense_id") == expId)
                    .fetchAll(db)

                var participants: [SplitParticipant] = []
                for p in participantRecords {
                    guard let pId = p.id else { continue }
                    let paymentRecords = try SplitPaymentRecord
                        .filter(Column("participant_id") == pId)
                        .order(Column("date").desc)
                        .fetchAll(db)

                    participants.append(Self.buildParticipantFromRecord(p, payments: paymentRecords))
                }

                results.append(
                    SplitExpense(
                        id: expId,
                        title: exp.title,
                        totalAmount: Amount(subunits: exp.totalAmountSubunits),
                        date: exp.date,
                        categoryId: exp.categoryId,
                        paidBy: exp.paidBy,
                        splitMethod: exp.splitMethod,
                        qrImagePath: exp.qrImagePath,
                        addToTransactions: exp.addToTransactions,
                        expenseTransactionId: exp.expenseTransactionId,
                        paymentMethod: PaymentMethod.fromString(exp.paymentMethod),
                        groupId: exp.groupId,
                        itemsJson: exp.itemsJson,
                        currencyCode: exp.currencyCode,
                        exchangeRate: exp.exchangeRate,
                        primaryTotalAmount: Amount(subunits: exp.primaryTotalAmountSubunits),
                        participants: participants,
                        createdAt: exp.createdAt,
                        updatedAt: exp.updatedAt
                    )
                )
            }
            return results
        }
    }
}

