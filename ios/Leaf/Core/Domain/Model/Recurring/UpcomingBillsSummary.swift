import Foundation

/// Overview metrics for upcoming and overdue bill payments.
public struct UpcomingBillsSummary: Hashable, Sendable {
    public let totalUpcomingAmount: Amount
    public let totalOverdueAmount: Amount
    public let overdueCount: Int
    public let dueTodayCount: Int
    public let upcomingCount: Int
    public let bills: [RecurringTransactionOccurrence]

    public init(
        totalUpcomingAmount: Amount = .zero,
        totalOverdueAmount: Amount = .zero,
        overdueCount: Int = 0,
        dueTodayCount: Int = 0,
        upcomingCount: Int = 0,
        bills: [RecurringTransactionOccurrence] = []
    ) {
        self.totalUpcomingAmount = totalUpcomingAmount
        self.totalOverdueAmount = totalOverdueAmount
        self.overdueCount = overdueCount
        self.dueTodayCount = dueTodayCount
        self.upcomingCount = upcomingCount
        self.bills = bills
    }

    public static let zero = UpcomingBillsSummary()
}

