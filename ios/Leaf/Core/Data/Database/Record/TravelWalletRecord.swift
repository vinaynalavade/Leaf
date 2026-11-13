import Foundation
import GRDB

public struct TravelWalletRecord: Codable, FetchableRecord, MutablePersistableRecord, TableRecord, Sendable {
    public static let databaseTableName = "travel_wallets"

    public var id: Int64?
    public var name: String
    public var currencyCode: String
    public var budgetAmountSubunits: Int64?
    public var note: String?
    public var colorHex: String
    public var iconName: String
    public var isArchived: Bool
    public var createdAt: Int64
    public var updatedAt: Int64

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case currencyCode = "currency_code"
        case budgetAmountSubunits = "budget_amount_subunits"
        case note
        case colorHex = "color_hex"
        case iconName = "icon_name"
        case isArchived = "is_archived"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    public init(
        id: Int64? = nil,
        name: String,
        currencyCode: String,
        budgetAmountSubunits: Int64? = nil,
        note: String? = nil,
        colorHex: String = "#10B981",
        iconName: String = "airplane",
        isArchived: Bool = false,
        createdAt: Int64 = Int64(Date().timeIntervalSince1970 * 1000),
        updatedAt: Int64 = Int64(Date().timeIntervalSince1970 * 1000)
    ) {
        self.id = id
        self.name = name
        self.currencyCode = currencyCode
        self.budgetAmountSubunits = budgetAmountSubunits
        self.note = note
        self.colorHex = colorHex
        self.iconName = iconName
        self.isArchived = isArchived
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    public mutating func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }
}

