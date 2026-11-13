import Foundation
import GRDB

public final class GRDBBudgetRepository: BudgetRepositoryProtocol, Sendable {

    private let database: AppDatabase

    public init(database: AppDatabase) {
        self.database = database
    }

    public func getBudgetsForMonth(year: Int, month: Int) async throws -> [Budget] {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone.current

        var startComp = DateComponents(year: year, month: month, day: 1, hour: 0, minute: 0, second: 0)
        let startDate = calendar.date(from: startComp) ?? Date()
        let daysInMonth = calendar.range(of: .day, in: .month, for: startDate)?.count ?? 30
        var endComp = DateComponents(year: year, month: month, day: daysInMonth, hour: 23, minute: 59, second: 59)
        let endDate = calendar.date(from: endComp) ?? Date()

        let monthStartEpoch = Int64(startDate.timeIntervalSince1970 * 1000)
        let monthEndEpoch = Int64(endDate.timeIntervalSince1970 * 1000)

        return try await database.writer.read { db in
            let rows = try Row.fetchAll(db, sql: """
                SELECT b.*,
                       c.name as cat_name,
                       c.icon_name as cat_icon,
                       c.color_hex as cat_color,
                       c.type as cat_type,
                       c.is_default as cat_is_default
                FROM budgets b
                LEFT JOIN categories c ON b.category_id = c.id
                WHERE (b.period_type = 'MONTHLY' AND b.year = ? AND b.month = ?)
                   OR (b.period_type = 'YEARLY' AND b.year = ?)
                   OR (b.period_type IN ('WEEKLY', 'CUSTOM') AND (
                         (b.start_date <= ? AND b.end_date >= ?)
                         OR (b.year = ? AND b.month = ?)
                      ))
                   OR (b.is_recurring = 1 AND b.period_type != 'CUSTOM')
                ORDER BY (b.category_id IS NOT NULL) ASC, b.amount_subunits DESC
            """, arguments: [year, month, year, monthEndEpoch, monthStartEpoch, year, month])

            // Deduplicate by budget id
            var seenIds = Set<Int64>()
            var results: [Budget] = []

            for row in rows {
                guard let id: Int64 = row["id"], !seenIds.contains(id) else { continue }
                seenIds.insert(id)

                var category: Category? = nil
                if let catId: Int64 = row["category_id"], let catName: String = row["cat_name"] {
                    category = Category(
                        id: catId,
                        name: catName,
                        iconName: row["cat_icon"] ?? "tag",
                        colorHex: row["cat_color"] ?? "#10B981",
                        type: TransactionType(rawValue: row["cat_type"] ?? "EXPENSE") ?? .expense,
                        isDefault: (row["cat_is_default"] as Int?) == 1
                    )
                }

                let pTypeRaw: String = row["period_type"] ?? "MONTHLY"
                let pType = BudgetPeriodType(rawValue: pTypeRaw) ?? .monthly
                let isRecur: Bool = (row["is_recurring"] as Int? ?? 1) == 1

                results.append(Budget(
                    id: id,
                    categoryId: row["category_id"],
                    category: category,
                    amount: Amount(subunits: row["amount_subunits"]),
                    month: row["month"],
                    year: row["year"],
                    periodType: pType,
                    startDate: row["start_date"],
                    endDate: row["end_date"],
                    isRecurring: isRecur,
                    createdAt: row["created_at"],
                    updatedAt: row["updated_at"]
                ))
            }

            return results
        }
    }

    public func getAllBudgets() async throws -> [Budget] {
        try await database.writer.read { db in
            let rows = try Row.fetchAll(db, sql: """
                SELECT b.*,
                       c.name as cat_name,
                       c.icon_name as cat_icon,
                       c.color_hex as cat_color,
                       c.type as cat_type,
                       c.is_default as cat_is_default
                FROM budgets b
                LEFT JOIN categories c ON b.category_id = c.id
                ORDER BY b.year DESC, b.month DESC, (b.category_id IS NOT NULL) ASC
            """)

            return rows.map { row in
                var category: Category? = nil
                if let catId: Int64 = row["category_id"], let catName: String = row["cat_name"] {
                    category = Category(
                        id: catId,
                        name: catName,
                        iconName: row["cat_icon"] ?? "tag",
                        colorHex: row["cat_color"] ?? "#10B981",
                        type: TransactionType(rawValue: row["cat_type"] ?? "EXPENSE") ?? .expense,
                        isDefault: (row["cat_is_default"] as Int?) == 1
                    )
                }

                let pTypeRaw: String = row["period_type"] ?? "MONTHLY"
                let pType = BudgetPeriodType(rawValue: pTypeRaw) ?? .monthly
                let isRecur: Bool = (row["is_recurring"] as Int? ?? 1) == 1

                return Budget(
                    id: row["id"],
                    categoryId: row["category_id"],
                    category: category,
                    amount: Amount(subunits: row["amount_subunits"]),
                    month: row["month"],
                    year: row["year"],
                    periodType: pType,
                    startDate: row["start_date"],
                    endDate: row["end_date"],
                    isRecurring: isRecur,
                    createdAt: row["created_at"],
                    updatedAt: row["updated_at"]
                )
            }
        }
    }

    public func getBudget(id: Int64) async throws -> Budget? {
        try await database.writer.read { db in
            guard let row = try Row.fetchOne(db, sql: """
                SELECT b.*,
                       c.name as cat_name,
                       c.icon_name as cat_icon,
                       c.color_hex as cat_color,
                       c.type as cat_type,
                       c.is_default as cat_is_default
                FROM budgets b
                LEFT JOIN categories c ON b.category_id = c.id
                WHERE b.id = ?
            """, arguments: [id]) else { return nil }

            var category: Category? = nil
            if let catId: Int64 = row["category_id"], let catName: String = row["cat_name"] {
                category = Category(
                    id: catId,
                    name: catName,
                    iconName: row["cat_icon"] ?? "tag",
                    colorHex: row["cat_color"] ?? "#10B981",
                    type: TransactionType(rawValue: row["cat_type"] ?? "EXPENSE") ?? .expense,
                    isDefault: (row["cat_is_default"] as Int?) == 1
                )
            }

            let pTypeRaw: String = row["period_type"] ?? "MONTHLY"
            let pType = BudgetPeriodType(rawValue: pTypeRaw) ?? .monthly
            let isRecur: Bool = (row["is_recurring"] as Int? ?? 1) == 1

            return Budget(
                id: row["id"],
                categoryId: row["category_id"],
                category: category,
                amount: Amount(subunits: row["amount_subunits"]),
                month: row["month"],
                year: row["year"],
                periodType: pType,
                startDate: row["start_date"],
                endDate: row["end_date"],
                isRecurring: isRecur,
                createdAt: row["created_at"],
                updatedAt: row["updated_at"]
            )
        }
    }

    public func insertBudget(_ budget: Budget) async throws -> Int64 {
        try await database.writer.write { db in
            var record = BudgetRecord(
                categoryId: budget.categoryId,
                amountSubunits: budget.amount.subunits,
                month: budget.month,
                year: budget.year,
                periodType: budget.periodType.rawValue,
                startDate: budget.startDate,
                endDate: budget.endDate,
                isRecurring: budget.isRecurring,
                createdAt: budget.createdAt,
                updatedAt: budget.updatedAt
            )
            try record.insert(db)
            return record.id ?? 0
        }
    }

    public func updateBudget(_ budget: Budget) async throws {
        try await database.writer.write { db in
            let now = Int64(Date().timeIntervalSince1970 * 1000)
            var record = BudgetRecord(
                id: budget.id,
                categoryId: budget.categoryId,
                amountSubunits: budget.amount.subunits,
                month: budget.month,
                year: budget.year,
                periodType: budget.periodType.rawValue,
                startDate: budget.startDate,
                endDate: budget.endDate,
                isRecurring: budget.isRecurring,
                createdAt: budget.createdAt,
                updatedAt: now
            )
            try record.update(db)
        }
    }

    public func deleteBudget(id: Int64) async throws {
        try await database.writer.write { db in
            _ = try BudgetRecord.deleteOne(db, key: id)
        }
    }
}
