import Foundation

/// Domain model representing a shared finance group or occasion (e.g. "Goa Trip", "Apartment 301", "Office Lunch").
public struct SplitGroup: Identifiable, Hashable, Codable, Sendable {
    public let id: Int64
    public let name: String
    public let iconName: String
    public let colorHex: String
    public let createdAt: Int64

    public init(
        id: Int64 = 0,
        name: String,
        iconName: String = "person.3.fill",
        colorHex: String = "#10B981",
        createdAt: Int64 = Int64(Date().timeIntervalSince1970 * 1000)
    ) {
        self.id = id
        self.name = name
        self.iconName = iconName
        self.colorHex = colorHex
        self.createdAt = createdAt
    }
}

