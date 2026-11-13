import Foundation

/// UseCase to evaluate savings goals growth, contribution history, and progress
/// independently of ordinary income and expense metrics.
public final class GetSavingsInsightsUseCase: Sendable {
    private let savingsGoalRepository: SavingsGoalRepositoryProtocol

    public init(savingsGoalRepository: SavingsGoalRepositoryProtocol) {
        self.savingsGoalRepository = savingsGoalRepository
    }

    public func execute(
        period: InsightsPeriod,
        calendar: Calendar = .current,
        referenceDate: Date = Date()
    ) async throws -> InsightsSavingsSummary {
        let interval = period.dateInterval(calendar: calendar, referenceDate: referenceDate)
        let startEpoch = Int64(interval.start.timeIntervalSince1970 * 1000)
        let endEpoch = Int64(interval.end.timeIntervalSince1970 * 1000)

        let activeGoals = try await savingsGoalRepository.getActiveGoals()

        var totalSavedSubunits: Int64 = 0
        var periodContributionsSubunits: Int64 = 0
        var periodWithdrawalsSubunits: Int64 = 0
        var goalItems: [SavingsGoalInsightItem] = []
        var allActivities: [SavingsActivityItem] = []

        for goal in activeGoals {
            totalSavedSubunits += goal.currentSavedAmount.subunits

            let progressPct = goal.targetAmount.subunits > 0
                ? min(100.0, (Double(goal.currentSavedAmount.subunits) / Double(goal.targetAmount.subunits)) * 100.0)
                : 0.0

            let allHistory = try await savingsGoalRepository.getContributions(goalId: goal.id)
            let periodHistory = allHistory.filter { $0.timestamp >= startEpoch && $0.timestamp <= endEpoch }

            var goalPeriodDeposits: Int64 = 0
            var goalPeriodWithdrawals: Int64 = 0
            var depositCount: Int = 0

            for entry in periodHistory {
                let isWithdrawal = entry.amount.subunits < 0
                let absAmount = abs(entry.amount.subunits)

                if !isWithdrawal {
                    goalPeriodDeposits += absAmount
                    depositCount += 1
                } else {
                    goalPeriodWithdrawals += absAmount
                }

                allActivities.append(SavingsActivityItem(
                    id: entry.id,
                    goalId: goal.id,
                    goalName: goal.name,
                    goalColorHex: goal.colorHex,
                    amount: Amount(absAmount),
                    isWithdrawal: isWithdrawal,
                    note: entry.note,
                    timestamp: entry.timestamp,
                    paymentMethod: .account
                ))
            }

            periodContributionsSubunits += goalPeriodDeposits
            periodWithdrawalsSubunits += goalPeriodWithdrawals

            goalItems.append(SavingsGoalInsightItem(
                goal: goal,
                currentAmount: goal.currentSavedAmount,
                targetAmount: goal.targetAmount,
                progressPercentage: progressPct,
                periodContributionsCount: depositCount,
                periodContributionsTotal: Amount(goalPeriodDeposits),
                periodWithdrawalsTotal: Amount(goalPeriodWithdrawals),
                netContributionsTotal: Amount(goalPeriodDeposits - goalPeriodWithdrawals)
            ))
        }

        // Sort goals by progress descending
        goalItems.sort { $0.progressPercentage > $1.progressPercentage }

        // Sort activities by timestamp descending
        allActivities.sort { $0.timestamp > $1.timestamp }

        let netContributionsSubunits = periodContributionsSubunits - periodWithdrawalsSubunits

        return InsightsSavingsSummary(
            totalSavedAcrossActiveGoals: Amount(totalSavedSubunits),
            activeGoalsCount: activeGoals.count,
            periodContributionsTotal: Amount(periodContributionsSubunits),
            periodWithdrawalsTotal: Amount(periodWithdrawalsSubunits),
            netContributionsTotal: Amount(netContributionsSubunits),
            goals: goalItems,
            recentActivity: allActivities
        )
    }
}

