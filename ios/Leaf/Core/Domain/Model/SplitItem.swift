import Foundation

public struct SplitItem: Identifiable, Hashable, Codable, Sendable {
    public let id: String
    public let name: String
    public let amount: Amount
    public let participantNames: [String]
    public let isCustomAllocation: Bool
    public let customAllocations: [String: Amount]

    public init(
        id: String = UUID().uuidString,
        name: String,
        amount: Amount,
        participantNames: [String],
        isCustomAllocation: Bool = false,
        customAllocations: [String: Amount] = [:]
    ) {
        self.id = id
        self.name = name
        self.amount = amount
        self.participantNames = participantNames
        self.isCustomAllocation = isCustomAllocation
        self.customAllocations = customAllocations
    }
}

