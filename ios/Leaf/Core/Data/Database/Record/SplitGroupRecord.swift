import Foundation
import GRDB

public struct SplitGroupRecord: Codable, FetchableRecord, MutablePersistableRecord, TableRecord, Sendable {
    public static let databaseTableName = "split_groups"

    public var id: Int64?
    public var name: String
    public var iconName: String
    public var colorHex: String
    public var createdAt: Int64

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case iconName = "icon_name"
        case colorHex = "color_hex"
        case createdAt = "created_at"
    }

    public init(
        id: Int64? = nil,
        name: String,
        iconName: String = "group",
        colorHex: String = "#3B82F6",
        createdAt: Int64 = Int64(Date().timeIntervalSince1970 * 1000)
    ) {
        self.id = id
        self.name = name
        self.iconName = iconName
        self.colorHex = colorHex
        self.createdAt = createdAt
    }

    public mutating func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }
}

