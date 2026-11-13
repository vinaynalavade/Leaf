import Foundation

public enum SettlementStatus: String, Codable, CaseIterable, Sendable {
    case pending = "PENDING"
    case partiallySettled = "PARTIALLY_SETTLED"
    case settled = "SETTLED"
}

public struct SplitParticipant: Identifiable, Hashable, Codable, Sendable {
    public let id: Int64
    public let splitExpenseId: Int64
    public let name: String
    public let isCurrentUser: Bool
    public let amount: Amount
    public let paidAmount: Amount
    public let settlementStatus: SettlementStatus
    public let settledAt: Int64?
    public let settlementTransactionId: Int64?
    public let phoneNumber: String?
    public let payments: [SplitPayment]

    public var remainingAmount: Amount {
        let remaining = amount.subunits - paidAmount.subunits
        return Amount(subunits: max(0, remaining))
    }

    public init(
        id: Int64 = 0,
        splitExpenseId: Int64 = 0,
        name: String,
        isCurrentUser: Bool,
        amount: Amount,
        paidAmount: Amount = .zero,
        settlementStatus: SettlementStatus = .pending,
        settledAt: Int64? = nil,
        settlementTransactionId: Int64? = nil,
        phoneNumber: String? = nil,
        payments: [SplitPayment] = []
    ) {
        self.id = id
        self.splitExpenseId = splitExpenseId
        self.name = name
        self.isCurrentUser = isCurrentUser
        self.amount = amount
        self.paidAmount = paidAmount
        self.settlementStatus = settlementStatus
        self.settledAt = settledAt
        self.settlementTransactionId = settlementTransactionId
        self.phoneNumber = phoneNumber
        self.payments = payments
    }
}

