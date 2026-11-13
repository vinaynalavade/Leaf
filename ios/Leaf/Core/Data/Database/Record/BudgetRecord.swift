import Foundation
import GRDB

public struct BudgetRecord: Codable, FetchableRecord, MutablePersistableRecord, TableRecord, Sendable {
    public static let databaseTableName = "budgets"

    public var id: Int64?
    public var categoryId: Int64?
    public var amountSubunits: Int64
    public var month: Int
    public var year: Int
    public var periodType: String
    public var startDate: Int64?
    public var endDate: Int64?
    public var isRecurring: Bool
    public var createdAt: Int64
    public var updatedAt: Int64

    enum CodingKeys: String, CodingKey {
        case id
        case categoryId = "category_id"
        case amountSubunits = "amount_subunits"
        case month
        case year
        case periodType = "period_type"
        case startDate = "start_date"
        case endDate = "end_date"
        case isRecurring = "is_recurring"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    public init(
        id: Int64? = nil,
        categoryId: Int64? = nil,
        amountSubunits: Int64,
        month: Int,
        year: Int,
        periodType: String = "MONTHLY",
        startDate: Int64? = nil,
        endDate: Int64? = nil,
        isRecurring: Bool = false,
        createdAt: Int64 = Int64(Date().timeIntervalSince1970 * 1000),
        updatedAt: Int64 = Int64(Date().timeIntervalSince1970 * 1000)
    ) {
        self.id = id
        self.categoryId = categoryId
        self.amountSubunits = amountSubunits
        self.month = month
        self.year = year
        self.periodType = periodType
        self.startDate = startDate
        self.endDate = endDate
        self.isRecurring = isRecurring
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    public mutating func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }
}
