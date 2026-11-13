import Foundation

/// Domain model representing an individual contribution (deposit) or withdrawal towards a savings goal.
public struct SavingsGoalContribution: Identifiable, Hashable, Codable, Sendable {
    public let id: Int64
    public let goalId: Int64
    public let amount: Amount
    public let note: String?
    public let timestamp: Int64
    public let transactionId: Int64?
    public let createdAt: Int64

    public init(
        id: Int64 = 0,
        goalId: Int64,
        amount: Amount,
        note: String? = nil,
        timestamp: Int64 = Int64(Date().timeIntervalSince1970 * 1000),
        transactionId: Int64? = nil,
        createdAt: Int64 = Int64(Date().timeIntervalSince1970 * 1000)
    ) {
        self.id = id
        self.goalId = goalId
        self.amount = amount
        self.note = note
        self.timestamp = timestamp
        self.transactionId = transactionId
        self.createdAt = createdAt
    }

    /// Whether this entry represents a withdrawal (negative subunit value).
    public var isWithdrawal: Bool {
        amount.subunits < 0
    }

    /// Absolute display amount for presentation in UI cards and lists.
    public var displayAmount: Amount {
        Amount(subunits: abs(amount.subunits))
    }
}
