import Foundation

public final class GetUpcomingBillsUseCase: Sendable {
    private let recurringRepository: RecurringRepositoryProtocol

    public init(recurringRepository: RecurringRepositoryProtocol) {
        self.recurringRepository = recurringRepository
    }

    public func execute(limit: Int? = nil) async throws -> UpcomingBillsSummary {
        let bills = try await recurringRepository.getUpcomingBills(limit: limit)

        var totalUpcoming = Amount.zero
        var totalOverdue = Amount.zero
        var overdueCount = 0
        var dueTodayCount = 0
        var upcomingCount = 0

        for b in bills {
            switch b.status {
            case .overdue:
                totalOverdue = totalOverdue + b.amount
                overdueCount += 1
            case .due:
                totalUpcoming = totalUpcoming + b.amount
                dueTodayCount += 1
            case .upcoming:
                totalUpcoming = totalUpcoming + b.amount
                upcomingCount += 1
            case .paid, .skipped:
                break
            }
        }

        return UpcomingBillsSummary(
            totalUpcomingAmount: totalUpcoming,
            totalOverdueAmount: totalOverdue,
            overdueCount: overdueCount,
            dueTodayCount: dueTodayCount,
            upcomingCount: upcomingCount,
            bills: bills
        )
    }
}

