import Foundation

/// Represents a persistent historical payment transaction recorded against a participant's split share.
public struct SplitPayment: Identifiable, Hashable, Codable, Sendable {
    public let id: Int64
    public let splitExpenseId: Int64
    public let participantId: Int64
    public let amount: Amount
    public let date: Int64
    public let paymentMethod: PaymentMethod
    public let note: String?
    public let transactionId: Int64?
    public let createdAt: Int64

    public init(
        id: Int64 = 0,
        splitExpenseId: Int64,
        participantId: Int64,
        amount: Amount,
        date: Int64 = Int64(Date().timeIntervalSince1970 * 1000),
        paymentMethod: PaymentMethod = .cash,
        note: String? = nil,
        transactionId: Int64? = nil,
        createdAt: Int64 = Int64(Date().timeIntervalSince1970 * 1000)
    ) {
        self.id = id
        self.splitExpenseId = splitExpenseId
        self.participantId = participantId
        self.amount = amount
        self.date = date
        self.paymentMethod = paymentMethod
        self.note = note
        self.transactionId = transactionId
        self.createdAt = createdAt
    }
}

