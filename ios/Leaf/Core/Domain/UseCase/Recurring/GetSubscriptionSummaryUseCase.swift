import Foundation

public final class GetSubscriptionSummaryUseCase: Sendable {
    private let recurringRepository: RecurringRepositoryProtocol

    public init(recurringRepository: RecurringRepositoryProtocol) {
        self.recurringRepository = recurringRepository
    }

    public func execute() async throws -> SubscriptionSummary {
        let allSubs = try await recurringRepository.getAllSubscriptions()
        let activeSubs = allSubs.filter { $0.status == .active }
        let pausedSubs = allSubs.filter { $0.status == .paused }

        var totalMonthly = Amount.zero
        for sub in activeSubs {
            totalMonthly = totalMonthly + sub.estimatedMonthlyAmount
        }

        let totalAnnual = Amount(subunits: totalMonthly.subunits * 12)

        // Fetch upcoming renewal occurrences for subscriptions
        let allOccurrences = try await recurringRepository.getUpcomingBills(limit: 50)
        let subRenewals = allOccurrences.filter { $0.isSubscription && $0.status.isUnsettled }

        return SubscriptionSummary(
            totalMonthlyAmount: totalMonthly,
            totalAnnualAmount: totalAnnual,
            activeCount: activeSubs.count,
            pausedCount: pausedSubs.count,
            subscriptions: allSubs,
            upcomingRenewals: subRenewals
        )
    }
}

