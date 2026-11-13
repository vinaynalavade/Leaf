import Foundation
import GRDB

public final class GRDBSavingsGoalRepository: SavingsGoalRepositoryProtocol, Sendable {

    private let database: AppDatabase

    public init(database: AppDatabase) {
        self.database = database
    }

    public func getActiveGoals() async throws -> [SavingsGoal] {
        try await database.writer.read { db in
            let goalRecords = try SavingsGoalRecord
                .filter(Column("is_archived") == false)
                .order(Column("created_at").desc)
                .fetchAll(db)

            return try goalRecords.map { try Self.buildGoal(record: $0, db: db) }
        }
    }

    public func getArchivedGoals() async throws -> [SavingsGoal] {
        try await database.writer.read { db in
            let goalRecords = try SavingsGoalRecord
                .filter(Column("is_archived") == true)
                .order(Column("created_at").desc)
                .fetchAll(db)

            return try goalRecords.map { try Self.buildGoal(record: $0, db: db) }
        }
    }

    public func getAllGoals() async throws -> [SavingsGoal] {
        try await database.writer.read { db in
            let goalRecords = try SavingsGoalRecord
                .order(Column("created_at").desc)
                .fetchAll(db)

            return try goalRecords.map { try Self.buildGoal(record: $0, db: db) }
        }
    }

    public func getGoal(id: Int64) async throws -> SavingsGoal? {
        try await database.writer.read { db in
            guard let record = try SavingsGoalRecord.fetchOne(db, key: id) else { return nil }
            return try Self.buildGoal(record: record, db: db)
        }
    }

    public func insertGoal(_ goal: SavingsGoal, initialContribution: Amount? = nil) async throws -> Int64 {
        try await database.writer.write { db in
            var record = SavingsGoalRecord(
                name: goal.name,
                targetAmountSubunits: goal.targetAmount.subunits,
                targetDate: goal.targetDate,
                note: goal.note,
                iconName: goal.iconName,
                colorHex: goal.colorHex,
                isArchived: goal.isArchived,
                createdAt: goal.createdAt,
                updatedAt: goal.updatedAt
            )
            try record.insert(db)
            let goalId = record.id ?? 0

            // If initial seed was provided, insert initial contribution
            if let seed = initialContribution, seed.subunits > 0 {
                var contrib = SavingsGoalContributionRecord(
                    goalId: goalId,
                    amountSubunits: seed.subunits,
                    note: "Initial Seed",
                    timestamp: goal.createdAt,
                    createdAt: goal.createdAt
                )
                try contrib.insert(db)
            }

            return goalId
        }
    }

    public func updateGoal(_ goal: SavingsGoal) async throws {
        try await database.writer.write { db in
            let now = Int64(Date().timeIntervalSince1970 * 1000)
            var record = SavingsGoalRecord(
                id: goal.id,
                name: goal.name,
                targetAmountSubunits: goal.targetAmount.subunits,
                targetDate: goal.targetDate,
                note: goal.note,
                iconName: goal.iconName,
                colorHex: goal.colorHex,
                isArchived: goal.isArchived,
                createdAt: goal.createdAt,
                updatedAt: now
            )
            try record.update(db)
        }
    }

    public func deleteGoal(id: Int64) async throws {
        try await database.writer.write { db in
            // Clean up any linked personal transactions for this goal's contributions
            let contribs = try SavingsGoalContributionRecord
                .filter(Column("goal_id") == id)
                .fetchAll(db)

            for c in contribs {
                if let txId = c.transactionId {
                    _ = try TransactionRecord.deleteOne(db, key: txId)
                }
            }

            _ = try SavingsGoalContributionRecord.filter(Column("goal_id") == id).deleteAll(db)
            _ = try SavingsGoalRecord.deleteOne(db, key: id)
        }
    }

    public func setGoalArchived(id: Int64, isArchived: Bool) async throws {
        try await database.writer.write { db in
            let now = Int64(Date().timeIntervalSince1970 * 1000)
            try db.execute(
                sql: "UPDATE savings_goals SET is_archived = ?, updated_at = ? WHERE id = ?",
                arguments: [isArchived ? 1 : 0, now, id]
            )
        }
    }

    public func addContribution(
        goalId: Int64,
        amount: Amount,
        note: String?,
        timestamp: Int64 = Int64(Date().timeIntervalSince1970 * 1000),
        createTransaction: Bool = false,
        paymentMethod: PaymentMethod = .account
    ) async throws -> SavingsGoalContribution {
        try await database.writer.write { db in
            guard let goal = try SavingsGoalRecord.fetchOne(db, key: goalId) else {
                throw SavingsGoalError.goalNotFound
            }

            if amount.subunits <= 0 {
                throw SavingsGoalError.invalidAmount
            }

            var linkedTxId: Int64? = nil
            if createTransaction {
                // Find or create "Savings & Goals" category
                let catRow = try Row.fetchOne(db, sql: "SELECT id FROM categories WHERE name = 'Savings & Goals' OR name LIKE '%saving%' LIMIT 1")
                let catId: Int64
                if let cid: Int64 = catRow?["id"] {
                    catId = cid
                } else {
                    var newCat = CategoryRecord(
                        name: "Savings & Goals",
                        iconName: "savings",
                        colorHex: "#10B981",
                        type: "EXPENSE",
                        isDefault: false
                    )
                    try newCat.insert(db)
                    catId = newCat.id ?? 1
                }

                let txNote = "Savings: \(goal.name)" + (note.map { " — \($0)" } ?? "")
                var tx = TransactionRecord(
                    amountSubunits: amount.subunits,
                    type: TransactionType.expense.rawValue,
                    categoryId: catId,
                    paymentMethod: paymentMethod.rawValue,
                    note: txNote,
                    timestamp: timestamp,
                    createdAt: timestamp,
                    updatedAt: timestamp,
                    isInternalTransfer: true
                )
                try tx.insert(db)
                linkedTxId = tx.id
            }

            var contribRecord = SavingsGoalContributionRecord(
                goalId: goalId,
                amountSubunits: amount.subunits,
                note: note?.trimmingCharacters(in: .whitespacesAndNewlines),
                timestamp: timestamp,
                createdAt: timestamp,
                transactionId: linkedTxId
            )
            try contribRecord.insert(db)

            // Touch goal updated_at
            try db.execute(
                sql: "UPDATE savings_goals SET updated_at = ? WHERE id = ?",
                arguments: [timestamp, goalId]
            )

            return SavingsGoalContribution(
                id: contribRecord.id ?? 0,
                goalId: goalId,
                amount: amount,
                note: note,
                timestamp: timestamp,
                transactionId: linkedTxId,
                createdAt: timestamp
            )
        }
    }

    public func addWithdrawal(
        goalId: Int64,
        amount: Amount,
        note: String?,
        timestamp: Int64 = Int64(Date().timeIntervalSince1970 * 1000),
        returnToAccount: Bool = true,
        paymentMethod: PaymentMethod = .account
    ) async throws -> SavingsGoalContribution {
        try await database.writer.write { db in
            guard let goal = try SavingsGoalRecord.fetchOne(db, key: goalId) else {
                throw SavingsGoalError.goalNotFound
            }

            if amount.subunits <= 0 {
                throw SavingsGoalError.invalidAmount
            }

            // Verify available savings balance
            let existingContribs = try SavingsGoalContributionRecord
                .filter(Column("goal_id") == goalId)
                .fetchAll(db)
            let totalSavedSubunits = existingContribs.reduce(Int64(0)) { $0 + $1.amountSubunits }

            if amount.subunits > totalSavedSubunits {
                throw SavingsGoalError.insufficientFunds(available: Amount(subunits: max(0, totalSavedSubunits)))
            }

            var linkedTxId: Int64? = nil
            if returnToAccount {
                // Internal transfer back to checking ledger
                let catRow = try Row.fetchOne(db, sql: "SELECT id FROM categories WHERE name = 'Savings & Goals' OR name LIKE '%saving%' LIMIT 1")
                let catId: Int64
                if let cid: Int64 = catRow?["id"] {
                    catId = cid
                } else {
                    var newCat = CategoryRecord(
                        name: "Savings & Goals",
                        iconName: "savings",
                        colorHex: "#10B981",
                        type: "INCOME",
                        isDefault: false
                    )
                    try newCat.insert(db)
                    catId = newCat.id ?? 1
                }

                let txNote = "Savings Withdrawal: \(goal.name)" + (note.map { " — \($0)" } ?? "")
                var tx = TransactionRecord(
                    amountSubunits: amount.subunits,
                    type: TransactionType.income.rawValue,
                    categoryId: catId,
                    paymentMethod: paymentMethod.rawValue,
                    note: txNote,
                    timestamp: timestamp,
                    createdAt: timestamp,
                    updatedAt: timestamp,
                    isInternalTransfer: true
                )
                try tx.insert(db)
                linkedTxId = tx.id
            }

            // Insert negative subunit record in savings_goal_contributions
            var contribRecord = SavingsGoalContributionRecord(
                goalId: goalId,
                amountSubunits: -amount.subunits,
                note: note?.trimmingCharacters(in: .whitespacesAndNewlines),
                timestamp: timestamp,
                createdAt: timestamp,
                transactionId: linkedTxId
            )
            try contribRecord.insert(db)

            // Touch goal updated_at
            try db.execute(
                sql: "UPDATE savings_goals SET updated_at = ? WHERE id = ?",
                arguments: [timestamp, goalId]
            )

            return SavingsGoalContribution(
                id: contribRecord.id ?? 0,
                goalId: goalId,
                amount: Amount(subunits: -amount.subunits),
                note: note,
                timestamp: timestamp,
                transactionId: linkedTxId,
                createdAt: timestamp
            )
        }
    }

    public func deleteContribution(id: Int64) async throws {
        try await database.writer.write { db in
            guard let contrib = try SavingsGoalContributionRecord.fetchOne(db, key: id) else { return }

            if let txId = contrib.transactionId {
                _ = try TransactionRecord.deleteOne(db, key: txId)
            }

            _ = try SavingsGoalContributionRecord.deleteOne(db, key: id)

            let now = Int64(Date().timeIntervalSince1970 * 1000)
            try db.execute(
                sql: "UPDATE savings_goals SET updated_at = ? WHERE id = ?",
                arguments: [now, contrib.goalId]
            )
        }
    }

    public func getContributions(goalId: Int64) async throws -> [SavingsGoalContribution] {
        try await database.writer.read { db in
            let records = try SavingsGoalContributionRecord
                .filter(Column("goal_id") == goalId)
                .order(Column("timestamp").desc, Column("id").desc)
                .fetchAll(db)

            return records.map {
                SavingsGoalContribution(
                    id: $0.id ?? 0,
                    goalId: $0.goalId,
                    amount: Amount(subunits: $0.amountSubunits),
                    note: $0.note,
                    timestamp: $0.timestamp,
                    transactionId: $0.transactionId,
                    createdAt: $0.createdAt
                )
            }
        }
    }

    // MARK: - Private Helpers

    private static func buildGoal(record: SavingsGoalRecord, db: Database) throws -> SavingsGoal {
        let contribRecords = try SavingsGoalContributionRecord
            .filter(Column("goal_id") == record.id!)
            .order(Column("timestamp").desc, Column("id").desc)
            .fetchAll(db)

        let contributions = contribRecords.map {
            SavingsGoalContribution(
                id: $0.id ?? 0,
                goalId: $0.goalId,
                amount: Amount(subunits: $0.amountSubunits),
                note: $0.note,
                timestamp: $0.timestamp,
                transactionId: $0.transactionId,
                createdAt: $0.createdAt
            )
        }

        return SavingsGoal(
            id: record.id ?? 0,
            name: record.name,
            targetAmount: Amount(subunits: record.targetAmountSubunits),
            targetDate: record.targetDate,
            note: record.note,
            iconName: record.iconName,
            colorHex: record.colorHex,
            isArchived: record.isArchived,
            contributions: contributions,
            createdAt: record.createdAt,
            updatedAt: record.updatedAt
        )
    }

    public enum SavingsGoalError: LocalizedError {
        case goalNotFound
        case invalidAmount
        case insufficientFunds(available: Amount)

        public var errorDescription: String? {
            switch self {
            case .goalNotFound:
                return "Savings goal not found."
            case .invalidAmount:
                return "Amount must be strictly greater than zero."
            case .insufficientFunds(let available):
                return "Withdrawal amount exceeds available savings of \(available.subunits) subunits."
            }
        }
    }
}
