import Foundation

public struct Category: Identifiable, Hashable, Codable, Sendable {
    public let id: Int64
    public let name: String
    public let iconName: String
    public let colorHex: String
    public let type: TransactionType
    public let isDefault: Bool

    public init(
        id: Int64 = 0,
        name: String,
        iconName: String,
        colorHex: String,
        type: TransactionType,
        isDefault: Bool = false
    ) {
        self.id = id
        self.name = name
        self.iconName = iconName
        self.colorHex = colorHex
        self.type = type
        self.isDefault = isDefault
    }
}

