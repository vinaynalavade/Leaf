import Foundation

/// Combined result of the financial overview, aggregate spending statistics,
/// and category rollup ranking.
public struct InsightsSummaryResult: Hashable, Sendable {
    public let period: InsightsPeriod
    public let dateInterval: DateInterval
    public let previousInterval: DateInterval
    public let financialOverview: InsightsFinancialOverview
    public let statistics: SpendingStatistics
    public let categoryBreakdown: [CategoryAnalysisItem]
}

/// Primary UseCase coordinating the financial overview, ordinary income/expense analytics,
/// savings performance, and period-over-period comparisons.
public final class GetInsightsSummaryUseCase: Sendable {
    private let transactionRepository: TransactionRepositoryProtocol
    private let categoryAnalysisUseCase: GetCategoryAnalysisUseCase
    private let savingsInsightsUseCase: GetSavingsInsightsUseCase

    public init(
        transactionRepository: TransactionRepositoryProtocol,
        categoryAnalysisUseCase: GetCategoryAnalysisUseCase,
        savingsInsightsUseCase: GetSavingsInsightsUseCase
    ) {
        self.transactionRepository = transactionRepository
        self.categoryAnalysisUseCase = categoryAnalysisUseCase
        self.savingsInsightsUseCase = savingsInsightsUseCase
    }

    public func execute(
        period: InsightsPeriod,
        calendar: Calendar = .current,
        referenceDate: Date = Date()
    ) async throws -> InsightsSummaryResult {
        let currentInterval = period.dateInterval(calendar: calendar, referenceDate: referenceDate)
        let prevInterval = period.previousEquivalentInterval(calendar: calendar, referenceDate: referenceDate)

        let currentStartEpoch = Int64(currentInterval.start.timeIntervalSince1970 * 1000)
        let currentEndEpoch = Int64(currentInterval.end.timeIntervalSince1970 * 1000)

        let prevStartEpoch = Int64(prevInterval.start.timeIntervalSince1970 * 1000)
        let prevEndEpoch = Int64(prevInterval.end.timeIntervalSince1970 * 1000)

        // 1. Operating Cash Flow (strictly excluding internal transfers)
        let ordinaryExpenses = try await transactionRepository.getTotalExpense(
            startEpoch: currentStartEpoch,
            endEpoch: currentEndEpoch
        )
        let earnedIncome = try await transactionRepository.getTotalIncome(
            startEpoch: currentStartEpoch,
            endEpoch: currentEndEpoch
        )

        let prevOrdinaryExpenses = try await transactionRepository.getTotalExpense(
            startEpoch: prevStartEpoch,
            endEpoch: prevEndEpoch
        )
        let prevEarnedIncome = try await transactionRepository.getTotalIncome(
            startEpoch: prevStartEpoch,
            endEpoch: prevEndEpoch
        )

        let operatingCashFlow = Amount(earnedIncome.subunits - ordinaryExpenses.subunits)
        let prevOperatingCashFlow = Amount(prevEarnedIncome.subunits - prevOrdinaryExpenses.subunits)

        let unspentIncomeRate: Double = earnedIncome.subunits > 0
            ? ((Double(earnedIncome.subunits - ordinaryExpenses.subunits)) / Double(earnedIncome.subunits)) * 100.0
            : 0.0

        let expenseChangePct: Double? = prevOrdinaryExpenses.subunits > 0
            ? ((Double(ordinaryExpenses.subunits - prevOrdinaryExpenses.subunits)) / Double(prevOrdinaryExpenses.subunits)) * 100.0
            : nil

        let incomeChangePct: Double? = prevEarnedIncome.subunits > 0
            ? ((Double(earnedIncome.subunits - prevEarnedIncome.subunits)) / Double(prevEarnedIncome.subunits)) * 100.0
            : nil

        let operatingCashFlowChangePct: Double? = prevOperatingCashFlow.subunits != 0
            ? ((Double(operatingCashFlow.subunits - prevOperatingCashFlow.subunits)) / Double(abs(prevOperatingCashFlow.subunits))) * 100.0
            : nil

        // 2. Checking Balance Movement (Total checking inflows minus total checking outflows)
        let totalCheckingInflow = try await transactionRepository.getTotalInflow(
            startEpoch: currentStartEpoch,
            endEpoch: currentEndEpoch
        )
        let totalCheckingOutflow = try await transactionRepository.getTotalOutflow(
            startEpoch: currentStartEpoch,
            endEpoch: currentEndEpoch
        )
        let checkingBalanceMovement = Amount(totalCheckingInflow.subunits - totalCheckingOutflow.subunits)

        let prevCheckingInflow = try await transactionRepository.getTotalInflow(
            startEpoch: prevStartEpoch,
            endEpoch: prevEndEpoch
        )
        let prevCheckingOutflow = try await transactionRepository.getTotalOutflow(
            startEpoch: prevStartEpoch,
            endEpoch: prevEndEpoch
        )
        let prevCheckingBalanceMovement = Amount(prevCheckingInflow.subunits - prevCheckingOutflow.subunits)

        // 3. Savings goals summary & actual contribution rate (segregated from ordinary flows)
        let savingsSummary = try await savingsInsightsUseCase.execute(
            period: period,
            calendar: calendar,
            referenceDate: referenceDate
        )

        let netSavingsContributions = savingsSummary.netContributionsTotal
        let actualSavingsRate: Double = earnedIncome.subunits > 0
            ? (Double(netSavingsContributions.subunits) / Double(earnedIncome.subunits)) * 100.0
            : 0.0

        let financialOverview = InsightsFinancialOverview(
            earnedIncome: earnedIncome,
            ordinaryExpenses: ordinaryExpenses,
            operatingCashFlow: operatingCashFlow,
            unspentIncomeRate: unspentIncomeRate,
            totalCheckingInflow: totalCheckingInflow,
            totalCheckingOutflow: totalCheckingOutflow,
            checkingBalanceMovement: checkingBalanceMovement,
            netSavingsContributions: netSavingsContributions,
            actualSavingsRate: actualSavingsRate,
            previousEarnedIncome: prevEarnedIncome,
            previousOrdinaryExpenses: prevOrdinaryExpenses,
            previousOperatingCashFlow: prevOperatingCashFlow,
            previousCheckingBalanceMovement: prevCheckingBalanceMovement,
            expenseChangePercentage: expenseChangePct,
            incomeChangePercentage: incomeChangePct,
            operatingCashFlowChangePercentage: operatingCashFlowChangePct,
            savingsSummary: savingsSummary
        )

        // 4. Category analysis rollup
        let categoryBreakdown = try await categoryAnalysisUseCase.execute(
            period: period,
            calendar: calendar,
            referenceDate: referenceDate
        )

        // 5. Spending statistics & highest spending day
        let currentTransactions = try await transactionRepository.getTransactionsBetween(
            startEpoch: currentStartEpoch,
            endEpoch: currentEndEpoch
        )
        let prevTransactions = try await transactionRepository.getTransactionsBetween(
            startEpoch: prevStartEpoch,
            endEpoch: prevEndEpoch
        )

        let ordinaryExpensesList = currentTransactions.filter { $0.type == .expense && !$0.isInternalTransfer }
        let ordinaryCount = currentTransactions.filter { !$0.isInternalTransfer }.count
        let prevOrdinaryCount = prevTransactions.filter { !$0.isInternalTransfer }.count

        let daysCount = max(1, calendar.dateComponents([.day], from: currentInterval.start, to: currentInterval.end).day ?? 1)
        let dailyAverageSubunits = ordinaryExpenses.subunits / Int64(daysCount)
        let dailyAverageExpense = Amount(dailyAverageSubunits)

        let prevDaysCount = max(1, calendar.dateComponents([.day], from: prevInterval.start, to: prevInterval.end).day ?? 1)
        let prevDailyAverageSubunits = prevOrdinaryExpenses.subunits / Int64(prevDaysCount)
        let prevDailyAverageExpense = Amount(prevDailyAverageSubunits)

        let dailyAverageChangePct: Double? = prevDailyAverageSubunits > 0
            ? ((Double(dailyAverageSubunits - prevDailyAverageSubunits)) / Double(prevDailyAverageSubunits)) * 100.0
            : nil

        let txCountChangePct: Double? = prevOrdinaryCount > 0
            ? ((Double(ordinaryCount - prevOrdinaryCount)) / Double(prevOrdinaryCount)) * 100.0
            : nil

        let avgTxSubunits = ordinaryExpensesList.isEmpty ? 0 : ordinaryExpenses.subunits / Int64(ordinaryExpensesList.count)
        let avgTxAmount = Amount(avgTxSubunits)

        // Highest spending day computation
        var daySpendingMap: [Date: (subunits: Int64, count: Int)] = [:]
        for tx in ordinaryExpensesList {
            let txDate = Date(timeIntervalSince1970: Double(tx.timestamp) / 1000.0)
            let dayKey = calendar.startOfDay(for: txDate)
            if let entry = daySpendingMap[dayKey] {
                daySpendingMap[dayKey] = (entry.subunits + tx.amount.subunits, entry.count + 1)
            } else {
                daySpendingMap[dayKey] = (tx.amount.subunits, 1)
            }
        }

        var highestDay: SpendingDayPoint? = nil
        if let topEntry = daySpendingMap.max(by: { $0.value.subunits < $1.value.subunits }), topEntry.value.subunits > 0 {
            highestDay = SpendingDayPoint(
                date: topEntry.key,
                amount: Amount(topEntry.value.subunits),
                transactionCount: topEntry.value.count
            )
        }

        let statistics = SpendingStatistics(
            dailyAverageExpense: dailyAverageExpense,
            highestSpendingDay: highestDay,
            transactionCount: ordinaryCount,
            averageTransactionAmount: avgTxAmount,
            topCategory: categoryBreakdown.first,
            previousDailyAverageExpense: prevDailyAverageExpense,
            dailyAverageChangePercentage: dailyAverageChangePct,
            previousTransactionCount: prevOrdinaryCount,
            transactionCountChangePercentage: txCountChangePct
        )

        return InsightsSummaryResult(
            period: period,
            dateInterval: currentInterval,
            previousInterval: prevInterval,
            financialOverview: financialOverview,
            statistics: statistics,
            categoryBreakdown: categoryBreakdown
        )
    }
}

