import Foundation

/// A single scheduled instance / bill occurrence generated from a recurring transaction schedule.
public struct RecurringTransactionOccurrence: Identifiable, Hashable, Codable, Sendable {
    public let id: Int64
    public let recurringTransactionId: Int64
    public let recurringTransaction: RecurringTransaction?
    public let scheduledDate: Int64
    public let dueDate: Int64
    public let amount: Amount
    public let status: BillPaymentStatus
    public let transactionId: Int64?
    public let paidAt: Int64?
    public let snoozedUntil: Int64?
    public let createdAt: Int64
    public let updatedAt: Int64

    public init(
        id: Int64 = 0,
        recurringTransactionId: Int64,
        recurringTransaction: RecurringTransaction? = nil,
        scheduledDate: Int64,
        dueDate: Int64,
        amount: Amount,
        status: BillPaymentStatus = .upcoming,
        transactionId: Int64? = nil,
        paidAt: Int64? = nil,
        snoozedUntil: Int64? = nil,
        createdAt: Int64 = Int64(Date().timeIntervalSince1970 * 1000),
        updatedAt: Int64 = Int64(Date().timeIntervalSince1970 * 1000)
    ) {
        self.id = id
        self.recurringTransactionId = recurringTransactionId
        self.recurringTransaction = recurringTransaction
        self.scheduledDate = scheduledDate
        self.dueDate = dueDate
        self.amount = amount
        self.status = status
        self.transactionId = transactionId
        self.paidAt = paidAt
        self.snoozedUntil = snoozedUntil
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    /// Convenience accessors
    public var title: String {
        recurringTransaction?.title ?? "Recurring Payment"
    }

    public var type: TransactionType {
        recurringTransaction?.type ?? .expense
    }

    public var category: Category? {
        recurringTransaction?.category
    }

    public var paymentMethod: PaymentMethod {
        recurringTransaction?.paymentMethod ?? .cash
    }

    public var isSubscription: Bool {
        recurringTransaction?.isSubscription ?? false
    }

    public var isPaid: Bool {
        status == .paid
    }

    public var isOverdue: Bool {
        status == .overdue
    }
}

