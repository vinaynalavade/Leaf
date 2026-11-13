import Foundation

/// Summary projection of active and recurring subscriptions for budgeting overhead analysis.
public struct SubscriptionSummary: Hashable, Sendable {
    public let totalMonthlyAmount: Amount
    public let totalAnnualAmount: Amount
    public let activeCount: Int
    public let pausedCount: Int
    public let subscriptions: [RecurringTransaction]
    public let upcomingRenewals: [RecurringTransactionOccurrence]

    public init(
        totalMonthlyAmount: Amount = .zero,
        totalAnnualAmount: Amount = .zero,
        activeCount: Int = 0,
        pausedCount: Int = 0,
        subscriptions: [RecurringTransaction] = [],
        upcomingRenewals: [RecurringTransactionOccurrence] = []
    ) {
        self.totalMonthlyAmount = totalMonthlyAmount
        self.totalAnnualAmount = totalAnnualAmount
        self.activeCount = activeCount
        self.pausedCount = pausedCount
        self.subscriptions = subscriptions
        self.upcomingRenewals = upcomingRenewals
    }

    public static let zero = SubscriptionSummary()
}

