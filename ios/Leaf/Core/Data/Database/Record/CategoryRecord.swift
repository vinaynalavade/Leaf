import Foundation
import GRDB

public struct CategoryRecord: Codable, FetchableRecord, MutablePersistableRecord, TableRecord, Sendable {
    public static let databaseTableName = "categories"

    public var id: Int64?
    public var name: String
    public var iconName: String
    public var colorHex: String
    public var type: String
    public var isDefault: Bool

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case iconName = "icon_name"
        case colorHex = "color_hex"
        case type
        case isDefault = "is_default"
    }

    public init(
        id: Int64? = nil,
        name: String,
        iconName: String,
        colorHex: String,
        type: String,
        isDefault: Bool = false
    ) {
        self.id = id
        self.name = name
        self.iconName = iconName
        self.colorHex = colorHex
        self.type = type
        self.isDefault = isDefault
    }

    public mutating func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }
}

