import Foundation

/// UseCase compiling comprehensive, verified financial statement datasets
/// strictly honoring Phase 4.2 & 5.1 accounting rules (ordinary cash flow vs internal transfers).
public final class CompileStatementDataUseCase: Sendable {
    private let transactionRepository: TransactionRepositoryProtocol
    private let categoryRepository: CategoryRepositoryProtocol
    private let preferencesRepository: UserPreferencesRepositoryProtocol
    private let savingsGoalRepository: SavingsGoalRepositoryProtocol
    private let categoryAnalysisUseCase: GetCategoryAnalysisUseCase
    private let savingsInsightsUseCase: GetSavingsInsightsUseCase
    private let budgetInsightsUseCase: GetBudgetInsightsUseCase

    public init(
        transactionRepository: TransactionRepositoryProtocol,
        categoryRepository: CategoryRepositoryProtocol,
        preferencesRepository: UserPreferencesRepositoryProtocol,
        savingsGoalRepository: SavingsGoalRepositoryProtocol,
        categoryAnalysisUseCase: GetCategoryAnalysisUseCase,
        savingsInsightsUseCase: GetSavingsInsightsUseCase,
        budgetInsightsUseCase: GetBudgetInsightsUseCase
    ) {
        self.transactionRepository = transactionRepository
        self.categoryRepository = categoryRepository
        self.preferencesRepository = preferencesRepository
        self.savingsGoalRepository = savingsGoalRepository
        self.categoryAnalysisUseCase = categoryAnalysisUseCase
        self.savingsInsightsUseCase = savingsInsightsUseCase
        self.budgetInsightsUseCase = budgetInsightsUseCase
    }

    public enum StatementError: LocalizedError {
        case invalidDateRange
        case emptyDateRange

        public var errorDescription: String? {
            switch self {
            case .invalidDateRange:
                return "The statement start date cannot be later than the end date."
            case .emptyDateRange:
                return "Please select a valid date range."
            }
        }
    }

    public func execute(
        period: StatementPeriod,
        customTitle: String? = nil,
        calendar: Calendar = .current,
        referenceDate: Date = Date()
    ) async throws -> FinancialStatementData {
        let interval = period.dateInterval(calendar: calendar, referenceDate: referenceDate)
        if interval.start > interval.end {
            throw StatementError.invalidDateRange
        }

        let startEpoch = Int64(interval.start.timeIntervalSince1970 * 1000)
        let endEpoch = Int64(interval.end.timeIntervalSince1970 * 1000)

        let prefs = preferencesRepository.getUserPreferences()
        let currency = prefs.currency
        let baseOpening = prefs.openingBalance

        // 1. Calculate opening balance prior to statement start
        let pastInflows = startEpoch > 0
            ? try await transactionRepository.getTotalInflow(startEpoch: 0, endEpoch: max(0, startEpoch - 1))
            : Amount.zero
        let pastOutflows = startEpoch > 0
            ? try await transactionRepository.getTotalOutflow(startEpoch: 0, endEpoch: max(0, startEpoch - 1))
            : Amount.zero
        let openingBalance = Amount(baseOpening.subunits + pastInflows.subunits - pastOutflows.subunits)

        // 2. Checking balance movements during period
        let totalCheckingInflow = try await transactionRepository.getTotalInflow(startEpoch: startEpoch, endEpoch: endEpoch)
        let totalCheckingOutflow = try await transactionRepository.getTotalOutflow(startEpoch: startEpoch, endEpoch: endEpoch)
        let checkingBalanceMovement = Amount(totalCheckingInflow.subunits - totalCheckingOutflow.subunits)
        let closingBalance = Amount(openingBalance.subunits + checkingBalanceMovement.subunits)

        // 3. Operating Cash Flow (strictly ordinary, excludes internal transfers)
        let ordinaryExpenses = try await transactionRepository.getTotalExpense(startEpoch: startEpoch, endEpoch: endEpoch)
        let earnedIncome = try await transactionRepository.getTotalIncome(startEpoch: startEpoch, endEpoch: endEpoch)
        let operatingCashFlow = Amount(earnedIncome.subunits - ordinaryExpenses.subunits)
        let unspentIncomeRate: Double = earnedIncome.subunits > 0
            ? (Double(operatingCashFlow.subunits) / Double(earnedIncome.subunits)) * 100.0
            : 0.0

        // 4. Savings activity (segregated from ordinary flows)
        let savingsSummary = try await savingsInsightsUseCase.execute(
            period: .custom(startDate: interval.start, endDate: interval.end),
            calendar: calendar,
            referenceDate: referenceDate
        )
        let netSavingsContributions = savingsSummary.netContributionsTotal
        let actualSavingsRate: Double = earnedIncome.subunits > 0
            ? (Double(netSavingsContributions.subunits) / Double(earnedIncome.subunits)) * 100.0
            : 0.0

        // 5. Category expense breakdown
        let categoryBreakdown = try await categoryAnalysisUseCase.execute(
            period: .custom(startDate: interval.start, endDate: interval.end),
            calendar: calendar,
            referenceDate: referenceDate
        )

        // 6. Transactions list (chronological order)
        let allTxs = try await transactionRepository.getTransactionsBetween(startEpoch: startEpoch, endEpoch: endEpoch)
        let sortedTransactions = allTxs.sorted(by: { $0.timestamp < $1.timestamp })

        // 7. Income category breakdown
        let incomeTxs = sortedTransactions.filter { $0.type == .income && !$0.isInternalTransfer }
        var incomeMap: [Int64: (category: Category, subunits: Int64, count: Int)] = [:]
        for tx in incomeTxs {
            guard let cat = tx.category else { continue }
            if let existing = incomeMap[cat.id] {
                incomeMap[cat.id] = (existing.category, existing.subunits + tx.amount.subunits, existing.count + 1)
            } else {
                incomeMap[cat.id] = (cat, tx.amount.subunits, 1)
            }
        }
        var incomeBreakdown: [CategoryAnalysisItem] = []
        for (_, entry) in incomeMap {
            let pct = earnedIncome.subunits > 0
                ? (Double(entry.subunits) / Double(earnedIncome.subunits)) * 100.0
                : 0.0
            incomeBreakdown.append(CategoryAnalysisItem(
                category: entry.category,
                amount: Amount(entry.subunits),
                percentageOfTotal: pct,
                transactionCount: entry.count
            ))
        }
        incomeBreakdown.sort(by: { $0.amount.subunits > $1.amount.subunits })

        // 8. Budgets covering this period
        let budgetSummaries = try await budgetInsightsUseCase.execute(
            period: .custom(startDate: interval.start, endDate: interval.end),
            calendar: calendar,
            referenceDate: referenceDate
        )

        // 9. Detailed savings contributions and withdrawals with goal titles
        let allGoals = try await savingsGoalRepository.getAllGoals()
        var detailedSavings: [DetailedSavingsItem] = []
        for goal in allGoals {
            let contributions = try await savingsGoalRepository.getContributions(goalId: goal.id)
            for item in contributions {
                if item.timestamp >= startEpoch && item.timestamp <= endEpoch {
                    detailedSavings.append(DetailedSavingsItem(
                        id: item.id,
                        goalId: goal.id,
                        goalTitle: goal.name,
                        amount: Amount(abs(item.amount.subunits)),
                        isWithdrawal: item.isWithdrawal,
                        date: Date(timeIntervalSince1970: TimeInterval(item.timestamp) / 1000.0),
                        note: item.note
                    ))
                }
            }
        }
        detailedSavings.sort(by: { $0.date < $1.date })

        let title = customTitle?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
            ? customTitle!.trimmingCharacters(in: .whitespacesAndNewlines)
            : period.defaultStatementTitle(calendar: calendar, referenceDate: referenceDate)

        return FinancialStatementData(
            title: title,
            period: period,
            dateInterval: interval,
            generatedAt: Date(),
            currency: currency,
            openingBalance: openingBalance,
            closingBalance: closingBalance,
            earnedIncome: earnedIncome,
            ordinaryExpenses: ordinaryExpenses,
            operatingCashFlow: operatingCashFlow,
            unspentIncomeRate: unspentIncomeRate,
            totalCheckingInflow: totalCheckingInflow,
            totalCheckingOutflow: totalCheckingOutflow,
            checkingBalanceMovement: checkingBalanceMovement,
            netSavingsContributions: netSavingsContributions,
            actualSavingsRate: actualSavingsRate,
            savingsSummary: savingsSummary,
            categoryBreakdown: categoryBreakdown,
            incomeBreakdown: incomeBreakdown,
            transactions: sortedTransactions,
            budgetSummaries: budgetSummaries,
            detailedSavings: detailedSavings
        )
    }
}

