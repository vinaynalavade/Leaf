import Foundation

/// UseCase to evaluate active budgets against ordinary spending within the selected period.
public final class GetBudgetInsightsUseCase: Sendable {
    private let budgetRepository: BudgetRepositoryProtocol
    private let transactionRepository: TransactionRepositoryProtocol

    public init(
        budgetRepository: BudgetRepositoryProtocol,
        transactionRepository: TransactionRepositoryProtocol
    ) {
        self.budgetRepository = budgetRepository
        self.transactionRepository = transactionRepository
    }

    public func execute(
        period: InsightsPeriod,
        calendar: Calendar = .current,
        referenceDate: Date = Date()
    ) async throws -> [BudgetInsightItem] {
        let interval = period.dateInterval(calendar: calendar, referenceDate: referenceDate)
        let allBudgets = try await budgetRepository.getAllBudgets()

        var results: [BudgetInsightItem] = []

        for budget in allBudgets {
            // Determine budget active evaluation range
            let budgetInterval: DateInterval
            if let start = budget.startDate, let end = budget.endDate {
                budgetInterval = DateInterval(
                    start: Date(timeIntervalSince1970: Double(start) / 1000.0),
                    end: Date(timeIntervalSince1970: Double(end) / 1000.0)
                )
            } else {
                // Monthly budget default
                var comps = DateComponents()
                comps.year = budget.year
                comps.month = budget.month
                comps.day = 1
                let start = calendar.date(from: comps) ?? interval.start
                let end = calendar.date(byAdding: .month, value: 1, to: start) ?? interval.end
                budgetInterval = DateInterval(start: start, end: end)
            }

            // Only evaluate budgets that overlap the selected insights period
            guard budgetInterval.intersects(interval) || budget.isRecurring else {
                continue
            }

            // Evaluate spend within the overlapping window
            let evalStart = max(budgetInterval.start, interval.start)
            let evalEnd = min(budgetInterval.end, interval.end)

            let startEpoch = Int64(evalStart.timeIntervalSince1970 * 1000)
            let endEpoch = Int64(evalEnd.timeIntervalSince1970 * 1000)

            let transactions = try await transactionRepository.getTransactionsBetween(
                startEpoch: startEpoch,
                endEpoch: endEpoch
            )

            // Strictly exclude internal transfers from budget consumption
            let relevantExpenses = transactions.filter { tx in
                tx.type == .expense &&
                !tx.isInternalTransfer &&
                (budget.category == nil || tx.category?.id == budget.category?.id)
            }

            let spentSubunits = relevantExpenses.reduce(Int64(0)) { $0 + $1.amount.subunits }
            let spentAmount = Amount(spentSubunits)
            let limitAmount = budget.amount

            let utilisation = limitAmount.subunits > 0
                ? (Double(spentSubunits) / Double(limitAmount.subunits)) * 100.0
                : 0.0

            let remainingSubunits = max(0, limitAmount.subunits - spentSubunits)
            let remainingAmount = Amount(remainingSubunits)

            let status: BudgetStatus
            if spentSubunits > limitAmount.subunits {
                status = .overBudget
            } else if spentSubunits == limitAmount.subunits && spentSubunits > 0 {
                status = .limitReached
            } else if utilisation >= 80.0 {
                status = .approachingLimit
            } else {
                status = .onTrack
            }

            let periodLabel: String
            switch budget.periodType {
            case .monthly:
                var monthComps = DateComponents()
                monthComps.year = budget.year
                monthComps.month = budget.month
                if let d = calendar.date(from: monthComps) {
                    let f = DateFormatter()
                    f.dateFormat = "MMM yyyy"
                    periodLabel = f.string(from: d)
                } else {
                    periodLabel = "\(budget.month)/\(budget.year)"
                }
            case .weekly:
                periodLabel = "Weekly"
            case .yearly:
                periodLabel = "\(budget.year)"
            case .custom:
                if let s = budget.startDate, let e = budget.endDate {
                    let dStart = Date(timeIntervalSince1970: Double(s) / 1000.0)
                    let dEnd = Date(timeIntervalSince1970: Double(e) / 1000.0)
                    let f = DateFormatter()
                    f.dateFormat = "MMM d"
                    periodLabel = "\(f.string(from: dStart)) – \(f.string(from: dEnd))"
                } else {
                    periodLabel = "Custom"
                }
            }

            let isHistorical = budgetInterval.end <= referenceDate

            results.append(BudgetInsightItem(
                budget: budget,
                category: budget.category,
                spentAmount: spentAmount,
                limitAmount: limitAmount,
                remainingAmount: remainingAmount,
                utilisationPercentage: utilisation,
                status: status,
                periodLabel: periodLabel,
                isHistorical: isHistorical
            ))
        }

        // Sort: exceeded first, then warning, then on-track (descending utilisation)
        results.sort(by: { (lhs: BudgetInsightItem, rhs: BudgetInsightItem) -> Bool in
            let lp = lhs.status.sortPriority
            let rp = rhs.status.sortPriority
            if lp != rp { return lp > rp }
            return lhs.utilisationPercentage > rhs.utilisationPercentage
        })

        return results
    }
}

private extension BudgetStatus {
    var sortPriority: Int {
        switch self {
        case .overBudget: return 4
        case .limitReached: return 3
        case .approachingLimit: return 2
        case .onTrack: return 1
        }
    }
}
