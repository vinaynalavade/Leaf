import XCTest
#if canImport(LeafCore)
@testable import LeafCore
#elseif canImport(Leaf)
@testable import Leaf
#endif

final class InsightsAnalyticsTests: XCTestCase {

    var container: AppContainer!

    override func setUp() async throws {
        container = AppContainer.makeInMemory()
        container.preferencesRepository.setCurrencyCode("USD")
        _ = try await container.categoryRepository.getAllCategories()
    }

    override func tearDown() async throws {
        container = nil
    }

    // MARK: - 1. Time Period Windows & Comparison Intervals

    func testInsightsPeriod_CalculationsAndEquivalencies() {
        let calendar = Calendar.current
        var comps = DateComponents()
        comps.year = 2026
        comps.month = 11
        comps.day = 15
        comps.hour = 12
        let refDate = calendar.date(from: comps)!

        // This Month: Nov 1 to Dec 1
        let thisMonth = InsightsPeriod.thisMonth
        let thisMonthInterval = thisMonth.dateInterval(calendar: calendar, referenceDate: refDate)
        XCTAssertEqual(calendar.component(.month, from: thisMonthInterval.start), 11)
        XCTAssertEqual(calendar.component(.year, from: thisMonthInterval.start), 2026)

        // Previous Equivalent: Oct 1 to Nov 1
        let prevMonthInterval = thisMonth.previousEquivalentInterval(calendar: calendar, referenceDate: refDate)
        XCTAssertEqual(calendar.component(.month, from: prevMonthInterval.start), 10)
        XCTAssertEqual(calendar.component(.year, from: prevMonthInterval.start), 2026)
        XCTAssertEqual(prevMonthInterval.end, thisMonthInterval.start)

        // This Week
        let thisWeek = InsightsPeriod.thisWeek
        let weekInterval = thisWeek.dateInterval(calendar: calendar, referenceDate: refDate)
        let prevWeekInterval = thisWeek.previousEquivalentInterval(calendar: calendar, referenceDate: refDate)
        XCTAssertTrue(weekInterval.start < weekInterval.end)
        XCTAssertEqual(prevWeekInterval.end, weekInterval.start)

        // Custom Date Range
        let customStart = calendar.date(byAdding: .day, value: -10, to: refDate)!
        let customEnd = refDate
        let customPeriod = InsightsPeriod.custom(startDate: customStart, endDate: customEnd)
        let customInterval = customPeriod.dateInterval(calendar: calendar, referenceDate: refDate)
        let customPrevInterval = customPeriod.previousEquivalentInterval(calendar: calendar, referenceDate: refDate)

        XCTAssertTrue(customInterval.duration > 0)
        XCTAssertEqual(customPrevInterval.end, customInterval.start)
    }

    // MARK: - 2. Category Analysis Rollup & Share Calculation

    func testCategoryAnalysisUseCase_RankingsAndPercentages() async throws {
        let now = Date()
        let timestamp = Int64(now.timeIntervalSince1970 * 1000)

        // Category 1: Food ($300)
        _ = try await container.addTransactionUseCase.execute(
            amount: Amount(subunits: 30000),
            type: .expense,
            categoryId: 1,
            paymentMethod: .account,
            note: "Groceries",
            timestamp: timestamp
        )

        // Category 2: Transport ($100)
        _ = try await container.addTransactionUseCase.execute(
            amount: Amount(subunits: 10000),
            type: .expense,
            categoryId: 2,
            paymentMethod: .account,
            note: "Metro",
            timestamp: timestamp
        )

        // Category 3: Entertainment ($100)
        _ = try await container.addTransactionUseCase.execute(
            amount: Amount(subunits: 10000),
            type: .expense,
            categoryId: 3,
            paymentMethod: .cash,
            note: "Movie",
            timestamp: timestamp
        )

        let analysis = try await container.getCategoryAnalysisUseCase.execute(
            period: .thisMonth,
            referenceDate: now
        )

        XCTAssertEqual(analysis.count, 3)
        // Highest spend must be first (Food)
        XCTAssertEqual(analysis[0].category.id, 1)
        XCTAssertEqual(analysis[0].amount.subunits, 30000)
        XCTAssertEqual(analysis[0].percentageOfTotal, 60.0, accuracy: 0.1)

        XCTAssertEqual(analysis[1].amount.subunits, 10000)
        XCTAssertEqual(analysis[1].percentageOfTotal, 20.0, accuracy: 0.1)
    }

    // MARK: - 3. Category Analysis Strictly Excludes Internal Transfers

    func testCategoryAnalysisUseCase_ExcludesInternalTransfers() async throws {
        let now = Date()
        let timestamp = Int64(now.timeIntervalSince1970 * 1000)

        // 1. Ordinary Expense: $150 in Food (cat 1)
        _ = try await container.addTransactionUseCase.execute(
            amount: Amount(subunits: 15000),
            type: .expense,
            categoryId: 1,
            paymentMethod: .account,
            note: "Dinner",
            timestamp: timestamp
        )

        // 2. Savings Goal Deposit: $500 (creates checking outflow marked isInternalTransfer: true)
        let goalId = try await container.saveSavingsGoalUseCase.execute(
            name: "Vacation",
            targetAmount: Amount(subunits: 100000),
            colorHex: "#10B981"
        )
        _ = try await container.recordSavingsContributionUseCase.execute(
            goalId: goalId,
            amount: Amount(subunits: 50000),
            note: "Trip fund",
            createTransaction: true,
            paymentMethod: .account
        )

        let analysis = try await container.getCategoryAnalysisUseCase.execute(
            period: .thisMonth,
            referenceDate: now
        )

        // Only the $150 ordinary expense should be counted; the $500 internal transfer must be completely excluded
        let totalExpenseSubunits = analysis.reduce(Int64(0)) { $0 + $1.amount.subunits }
        XCTAssertEqual(totalExpenseSubunits, 15000)
        XCTAssertEqual(analysis.first?.category.id, 1)
        XCTAssertEqual(analysis.first?.amount.subunits, 15000)
    }

    // MARK: - 4. Spending Trends Bucket Generation & Safety

    func testSpendingTrendsUseCase_HandlesEmptyAndActiveDays() async throws {
        let now = Date()
        let timestamp = Int64(now.timeIntervalSince1970 * 1000)

        // Log one expense of $50
        _ = try await container.addTransactionUseCase.execute(
            amount: Amount(subunits: 5000),
            type: .expense,
            categoryId: 1,
            paymentMethod: .cash,
            note: "Snacks",
            timestamp: timestamp
        )

        let trends = try await container.getSpendingTrendsUseCase.execute(
            period: .thisWeek,
            forcedGranularity: .daily,
            referenceDate: now
        )

        // Must produce 7 daily points for a week
        XCTAssertEqual(trends.count, 7)

        // Sum of all daily points must equal $50
        let totalExpense = trends.reduce(Int64(0)) { $0 + $1.expenseSubunits }
        XCTAssertEqual(totalExpense, 5000)

        // Zero days must have exactly 0 subunits, avoiding crashes or NaN
        let zeroDays = trends.filter { $0.expenseSubunits == 0 }
        XCTAssertEqual(zeroDays.count, 6)
    }

    // MARK: - 5. Insights Financial Overview & Segregated Savings

    func testInsightsSummaryUseCase_FinancialOverviewAndSavingsRate() async throws {
        let now = Date()
        let timestamp = Int64(now.timeIntervalSince1970 * 1000)

        // Earned Income: $5,000
        _ = try await container.addTransactionUseCase.execute(
            amount: Amount(subunits: 500000),
            type: .income,
            categoryId: 1,
            paymentMethod: .account,
            note: "Salary",
            timestamp: timestamp
        )

        // Ordinary Expenses: $2,000
        _ = try await container.addTransactionUseCase.execute(
            amount: Amount(subunits: 200000),
            type: .expense,
            categoryId: 1,
            paymentMethod: .account,
            note: "Rent",
            timestamp: timestamp
        )

        // Savings Deposit: $1,000
        let goalId = try await container.saveSavingsGoalUseCase.execute(
            name: "Emergency Fund",
            targetAmount: Amount(subunits: 1000000),
            colorHex: "#10B981"
        )
        _ = try await container.recordSavingsContributionUseCase.execute(
            goalId: goalId,
            amount: Amount(subunits: 100000),
            note: "Monthly savings",
            createTransaction: true,
            paymentMethod: .account
        )

        let summary = try await container.getInsightsSummaryUseCase.execute(
            period: .thisMonth,
            referenceDate: now
        )

        let overview = summary.financialOverview

        // 1. Operating Cash Flow (Earned Income $5,000 - Ordinary Expense $2,000)
        XCTAssertEqual(overview.earnedIncome.subunits, 500000)
        XCTAssertEqual(overview.ordinaryExpenses.subunits, 200000)
        XCTAssertEqual(overview.operatingCashFlow.subunits, 300000)

        // 2. Unspent Income Rate: (5000 - 2000) / 5000 * 100 = 60.0%
        XCTAssertEqual(overview.unspentIncomeRate, 60.0, accuracy: 0.1)

        // 3. Checking Balance Movement: Inflow $5,000 - Outflow $3,000 ($2,000 ordinary + $1,000 savings deposit) = $2,000
        XCTAssertEqual(overview.totalCheckingInflow.subunits, 500000)
        XCTAssertEqual(overview.totalCheckingOutflow.subunits, 300000)
        XCTAssertEqual(overview.checkingBalanceMovement.subunits, 200000)

        // 4. Actual Savings Rate: $1,000 net savings / $5,000 earned income = 20.0%
        XCTAssertEqual(overview.netSavingsContributions.subunits, 100000)
        XCTAssertEqual(overview.actualSavingsRate, 20.0, accuracy: 0.1)

        // 5. Savings Summary: Segregated from expenses with activity feed
        XCTAssertEqual(overview.savingsSummary.periodContributionsTotal.subunits, 100000)
        XCTAssertEqual(overview.savingsSummary.netContributionsTotal.subunits, 100000)
        XCTAssertEqual(overview.savingsSummary.totalSavedAcrossActiveGoals.subunits, 100000)
        XCTAssertEqual(overview.savingsSummary.recentActivity.count, 1)
        XCTAssertEqual(overview.savingsSummary.recentActivity.first?.amount.subunits, 100000)
        XCTAssertFalse(overview.savingsSummary.recentActivity.first?.isWithdrawal ?? true)
    }

    // MARK: - 6. Budget Insights Utilisation & Status Evaluation

    func testBudgetInsightsUseCase_DetectsWarningAndExceeded() async throws {
        let now = Date()
        let timestamp = Int64(now.timeIntervalSince1970 * 1000)
        let calendar = Calendar.current
        let month = calendar.component(.month, from: now)
        let year = calendar.component(.year, from: now)

        // Budget of $1,000 for Food (Category 1)
        _ = try await container.saveBudgetUseCase.execute(
            categoryId: 1,
            amount: Amount(subunits: 100000),
            month: month,
            year: year
        )

        // Spend $850 (85% -> Warning status)
        _ = try await container.addTransactionUseCase.execute(
            amount: Amount(subunits: 85000),
            type: .expense,
            categoryId: 1,
            paymentMethod: .account,
            note: "Dining",
            timestamp: timestamp
        )

        var budgetInsights = try await container.getBudgetInsightsUseCase.execute(
            period: .thisMonth,
            referenceDate: now
        )

        XCTAssertEqual(budgetInsights.count, 1)
        XCTAssertEqual(budgetInsights[0].status, .approachingLimit)
        XCTAssertEqual(budgetInsights[0].utilisationPercentage, 85.0, accuracy: 0.1)

        // Additional $200 spend -> Total $1,050 (105% -> Exceeded status)
        _ = try await container.addTransactionUseCase.execute(
            amount: Amount(subunits: 20000),
            type: .expense,
            categoryId: 1,
            paymentMethod: .cash,
            note: "Coffee",
            timestamp: timestamp
        )

        budgetInsights = try await container.getBudgetInsightsUseCase.execute(
            period: .thisMonth,
            referenceDate: now
        )

        XCTAssertEqual(budgetInsights[0].status, .overBudget)
        XCTAssertEqual(budgetInsights[0].utilisationPercentage, 105.0, accuracy: 0.1)
    }

    // MARK: - 6b. Historical Budget Insights Evaluation

    func testBudgetInsightsUseCase_EvaluatesHistoricalBudgetsWithoutInventingData() async throws {
        let calendar = Calendar.current
        var nowComps = DateComponents()
        nowComps.year = 2026
        nowComps.month = 11
        nowComps.day = 15
        let now = calendar.date(from: nowComps)!

        // 1. Save past budget for October 2026 (Month 10): $800
        _ = try await container.saveBudgetUseCase.execute(
            categoryId: 1,
            amount: Amount(subunits: 80000),
            month: 10,
            year: 2026,
            isRecurring: false
        )

        // 2. Add an expense in October: $600 (75% utilisation -> On Track)
        var octComps = DateComponents()
        octComps.year = 2026
        octComps.month = 10
        octComps.day = 10
        let octDate = calendar.date(from: octComps)!
        let octTimestamp = Int64(octDate.timeIntervalSince1970 * 1000)

        _ = try await container.addTransactionUseCase.execute(
            amount: Amount(subunits: 60000),
            type: .expense,
            categoryId: 1,
            paymentMethod: .account,
            note: "Oct Dining",
            timestamp: octTimestamp
        )

        // 3. Query budget insights for "Last Month"
        let lastMonthInsights = try await container.getBudgetInsightsUseCase.execute(
            period: .lastMonth,
            referenceDate: now
        )

        // Must report exactly 1 budget record (does not invent unrecorded categories)
        XCTAssertEqual(lastMonthInsights.count, 1)
        let histItem = lastMonthInsights[0]
        XCTAssertTrue(histItem.isHistorical)
        XCTAssertEqual(histItem.spentAmount.subunits, 60000)
        XCTAssertEqual(histItem.limitAmount.subunits, 80000)
        XCTAssertEqual(histItem.utilisationPercentage, 75.0, accuracy: 0.1)
        XCTAssertEqual(histItem.status, .onTrack)
    }

    // MARK: - 7. Rule-Based Observations Generation

    func testFinancialObservationsUseCase_GeneratesActionableInsights() async throws {
        let now = Date()
        let timestamp = Int64(now.timeIntervalSince1970 * 1000)
        let calendar = Calendar.current
        let month = calendar.component(.month, from: now)
        let year = calendar.component(.year, from: now)

        // Income $5,000
        _ = try await container.addTransactionUseCase.execute(
            amount: Amount(subunits: 500000),
            type: .income,
            categoryId: 1,
            paymentMethod: .account,
            note: "Income",
            timestamp: timestamp
        )

        // Over-budget spending: Budget $500, Spent $600
        _ = try await container.saveBudgetUseCase.execute(
            categoryId: 1,
            amount: Amount(subunits: 50000),
            month: month,
            year: year
        )
        _ = try await container.addTransactionUseCase.execute(
            amount: Amount(subunits: 60000),
            type: .expense,
            categoryId: 1,
            paymentMethod: .account,
            note: "Groceries",
            timestamp: timestamp
        )

        let summary = try await container.getInsightsSummaryUseCase.execute(
            period: .thisMonth,
            referenceDate: now
        )
        let budgets = try await container.getBudgetInsightsUseCase.execute(
            period: .thisMonth,
            referenceDate: now
        )

        let observations = container.getFinancialObservationsUseCase.execute(
            summaryResult: summary,
            budgets: budgets,
            currency: .usd
        )

        XCTAssertFalse(observations.isEmpty)

        // Verify budget exceeded observation is triggered
        let budgetObs = observations.first { $0.type == .budgetExceeded }
        XCTAssertNotNil(budgetObs)
        XCTAssertEqual(budgetObs?.sentiment, .critical)

        // Verify healthy cashflow observation is triggered (Net income positive and savings rate >= 15%)
        let cashflowObs = observations.first { $0.type == .healthyCashFlow }
        XCTAssertNotNil(cashflowObs)
        XCTAssertEqual(cashflowObs?.sentiment, .positive)
    }
}
