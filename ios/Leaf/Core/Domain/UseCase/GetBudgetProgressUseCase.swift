import Foundation

/// UseCase evaluating 4-tier budget progress across multiple period types (Monthly, Weekly, Yearly, Custom)
/// and deterministic featured budget selection.
/// Implements the exact threshold calculation from FEAT-04 of the master documentation:
/// - On Track: Spend < 75% of limit
/// - Approaching Limit: 75% <= Spend < 100% of limit
/// - Limit Reached: Spend == 100% of limit
/// - Over Budget: Spend > 100% of limit
public final class GetBudgetProgressUseCase: Sendable {

    private let budgetRepository: BudgetRepositoryProtocol
    private let transactionRepository: TransactionRepositoryProtocol

    public init(
        budgetRepository: BudgetRepositoryProtocol,
        transactionRepository: TransactionRepositoryProtocol
    ) {
        self.budgetRepository = budgetRepository
        self.transactionRepository = transactionRepository
    }

    /// Evaluates all configured budgets active for a given month and year.
    public func execute(year: Int, month: Int) async throws -> [BudgetProgress] {
        let budgets = try await budgetRepository.getBudgetsForMonth(year: year, month: month)
        if budgets.isEmpty {
            return []
        }

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone.current
        let refComps = DateComponents(year: year, month: month, day: 15)
        let refDate = calendar.date(from: refComps) ?? Date()

        var progressList: [BudgetProgress] = []
        for budget in budgets {
            let progress = try await calculateProgress(for: budget, referenceDate: refDate)
            progressList.append(progress)
        }

        return progressList
    }

    /// Evaluates progress for an individual budget based on its specific `periodType` and `dateRange`.
    public func calculateProgress(for budget: Budget, referenceDate: Date = Date()) async throws -> BudgetProgress {
        let (startEpoch, endEpoch) = budget.dateRange(for: referenceDate)
        let transactions = try await transactionRepository.getTransactionsBetween(
            startEpoch: startEpoch,
            endEpoch: endEpoch
        )

        let expenseTransactions = transactions.filter { $0.type == .expense && !$0.isInternalTransfer }

        let usedSubunits: Int64
        if budget.isOverallBudget {
            usedSubunits = expenseTransactions.reduce(0) { $0 + $1.amount.subunits }
        } else {
            usedSubunits = expenseTransactions
                .filter { $0.categoryId == budget.categoryId }
                .reduce(0) { $0 + $1.amount.subunits }
        }

        let budgetSubunits = budget.amount.subunits
        let remainingSubunits = max(0, budgetSubunits - usedSubunits)

        let percentageUsed: Double
        if budgetSubunits > 0 {
            percentageUsed = (Double(usedSubunits) / Double(budgetSubunits)) * 100.0
        } else {
            percentageUsed = 0.0
        }

        // Overflow protection ceiling (10^14 subunits)
        let maxBound: Int64 = 100_000_000_000_000
        let safeBudget = min(budgetSubunits, maxBound)
        let threshold75 = (safeBudget * 75) / 100

        let status: BudgetStatus
        if usedSubunits < threshold75 {
            status = .onTrack
        } else if usedSubunits < safeBudget {
            status = .approachingLimit
        } else if usedSubunits == safeBudget {
            status = .limitReached
        } else {
            status = .overBudget
        }

        return BudgetProgress(
            budget: budget,
            category: budget.category,
            usedAmount: Amount(subunits: usedSubunits),
            remainingAmount: Amount(subunits: remainingSubunits),
            percentageUsed: percentageUsed,
            status: status
        )
    }

    /// Selects the primary featured budget for the dashboard using deterministic rules:
    /// 1. Overall budget (`categoryId == nil`), if configured.
    /// 2. If no overall budget, the category budget with the highest spend (`usedAmount`).
    /// 3. Returns `nil` if no budgets are configured for the month.
    public func getFeaturedBudget(year: Int, month: Int) async throws -> BudgetProgress? {
        let allProgress = try await execute(year: year, month: month)
        if allProgress.isEmpty { return nil }

        if let overall = allProgress.first(where: { $0.budget.isOverallBudget }) {
            return overall
        }

        return allProgress.max(by: { $0.usedAmount.subunits < $1.usedAmount.subunits })
    }
}
