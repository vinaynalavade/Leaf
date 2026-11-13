import Foundation
import GRDB

public struct SavingsGoalRecord: Codable, FetchableRecord, MutablePersistableRecord, TableRecord, Sendable {
    public static let databaseTableName = "savings_goals"

    public var id: Int64?
    public var name: String
    public var targetAmountSubunits: Int64
    public var targetDate: Int64?
    public var note: String?
    public var iconName: String
    public var colorHex: String
    public var isArchived: Bool
    public var createdAt: Int64
    public var updatedAt: Int64

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case targetAmountSubunits = "target_amount_subunits"
        case targetDate = "target_date"
        case note
        case iconName = "icon_name"
        case colorHex = "color_hex"
        case isArchived = "is_archived"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    public init(
        id: Int64? = nil,
        name: String,
        targetAmountSubunits: Int64,
        targetDate: Int64? = nil,
        note: String? = nil,
        iconName: String = "savings",
        colorHex: String = "#10B981",
        isArchived: Bool = false,
        createdAt: Int64 = Int64(Date().timeIntervalSince1970 * 1000),
        updatedAt: Int64 = Int64(Date().timeIntervalSince1970 * 1000)
    ) {
        self.id = id
        self.name = name
        self.targetAmountSubunits = targetAmountSubunits
        self.targetDate = targetDate
        self.note = note
        self.iconName = iconName
        self.colorHex = colorHex
        self.isArchived = isArchived
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    public mutating func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }
}

