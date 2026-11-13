import XCTest
#if canImport(LeafCore)
@testable import LeafCore
#elseif canImport(Leaf)
@testable import Leaf
#endif

final class PlanningViewModelTests: XCTestCase {

    var container: AppContainer!

    override func setUp() async throws {
        container = AppContainer.makeInMemory()
        try await container.preferencesRepository.setCurrencyCode("INR")
        _ = try await container.categoryRepository.getAllCategories()
    }

    override func tearDown() async throws {
        container = nil
    }

    // MARK: - 1. Budget Creation & Update Tests

    func testBudgetSave_CreatesOverallAndCategoryBudgets() async throws {
        // 1. Overall monthly budget: ₹50,000
        let overallId = try await container.saveBudgetUseCase.execute(
            categoryId: nil,
            amount: Amount(subunits: 5000000),
            month: 11,
            year: 2026
        )
        XCTAssertGreaterThan(overallId, 0)

        // 2. Category budget (Food & Dining): ₹15,000
        let catBudgetId = try await container.saveBudgetUseCase.execute(
            categoryId: 1,
            amount: Amount(subunits: 1500000),
            month: 11,
            year: 2026
        )
        XCTAssertGreaterThan(catBudgetId, 0)

        let budgets = try await container.budgetRepository.getBudgetsForMonth(year: 2026, month: 11)
        XCTAssertEqual(budgets.count, 2)

        let overall = budgets.first { $0.isOverallBudget }
        XCTAssertNotNil(overall)
        XCTAssertEqual(overall?.amount.subunits, 5000000)

        let categoryBudget = budgets.first { $0.categoryId == 1 }
        XCTAssertNotNil(categoryBudget)
        XCTAssertEqual(categoryBudget?.amount.subunits, 1500000)
    }

    func testBudgetSave_UpdatesExistingBudgetWithoutDuplication() async throws {
        // Insert initial budget
        let id1 = try await container.saveBudgetUseCase.execute(
            categoryId: 1,
            amount: Amount(subunits: 1000000),
            month: 11,
            year: 2026
        )

        // Re-saving for same category and month updates existing record
        let id2 = try await container.saveBudgetUseCase.execute(
            categoryId: 1,
            amount: Amount(subunits: 1200000),
            month: 11,
            year: 2026
        )

        XCTAssertEqual(id1, id2, "SaveBudgetUseCase must update in-place for same month & category")

        let budgets = try await container.budgetRepository.getBudgetsForMonth(year: 2026, month: 11)
        let matched = budgets.filter { $0.categoryId == 1 }
        XCTAssertEqual(matched.count, 1)
        XCTAssertEqual(matched.first?.amount.subunits, 1200000)
    }

    // MARK: - 2. 4-Tier Threshold Alert Calculations

    func testBudgetAlertThresholds_4TierProgression() async throws {
        // Setup Overall Budget: ₹10,000 (1,000,000 subunits)
        // 75% = ₹7,500 (750,000 subunits)
        // 100% = ₹10,000 (1,000,000 subunits)
        _ = try await container.saveBudgetUseCase.execute(
            categoryId: nil,
            amount: Amount(subunits: 1000000),
            month: 11,
            year: 2026
        )

        var calendar = Calendar.current
        var comps = DateComponents(year: 2026, month: 11, day: 5, hour: 12)
        let testEpoch = Int64((calendar.date(from: comps) ?? Date()).timeIntervalSince1970 * 1000)

        // Tier 1: On Track (<75%) -> Spend ₹5,000
        let tx1Id = try await container.addTransactionUseCase.execute(
            amount: Amount(subunits: 500000),
            type: .expense,
            categoryId: 1,
            paymentMethod: .cash,
            note: "Groceries",
            timestamp: testEpoch
        )

        var progressList = try await container.getBudgetProgressUseCase.execute(year: 2026, month: 11)
        XCTAssertEqual(progressList.count, 1)
        XCTAssertEqual(progressList[0].status, .onTrack)
        XCTAssertEqual(progressList[0].percentageUsed, 50.0, accuracy: 0.1)
        XCTAssertEqual(progressList[0].remainingAmount.subunits, 500000)

        // Tier 2: Approaching Limit (75% to <100%) -> Add ₹3,000 (Total spend: ₹8,000 = 80%)
        let tx2Id = try await container.addTransactionUseCase.execute(
            amount: Amount(subunits: 300000),
            type: .expense,
            categoryId: 1,
            paymentMethod: .cash,
            note: "Dining out",
            timestamp: testEpoch
        )

        progressList = try await container.getBudgetProgressUseCase.execute(year: 2026, month: 11)
        XCTAssertEqual(progressList[0].status, .approachingLimit)
        XCTAssertEqual(progressList[0].percentageUsed, 80.0, accuracy: 0.1)
        XCTAssertEqual(progressList[0].remainingAmount.subunits, 200000)

        // Tier 3: Limit Reached (Exactly 100%) -> Add ₹2,000 (Total spend: ₹10,000 = 100%)
        let tx3Id = try await container.addTransactionUseCase.execute(
            amount: Amount(subunits: 200000),
            type: .expense,
            categoryId: 1,
            paymentMethod: .cash,
            note: "Coffee",
            timestamp: testEpoch
        )

        progressList = try await container.getBudgetProgressUseCase.execute(year: 2026, month: 11)
        XCTAssertEqual(progressList[0].status, .limitReached)
        XCTAssertEqual(progressList[0].percentageUsed, 100.0, accuracy: 0.1)
        XCTAssertEqual(progressList[0].remainingAmount.subunits, 0)

        // Tier 4: Over Budget (>100%) -> Add ₹1,500 (Total spend: ₹11,500 = 115%)
        let tx4Id = try await container.addTransactionUseCase.execute(
            amount: Amount(subunits: 150000),
            type: .expense,
            categoryId: 1,
            paymentMethod: .cash,
            note: "Extra item",
            timestamp: testEpoch
        )

        progressList = try await container.getBudgetProgressUseCase.execute(year: 2026, month: 11)
        XCTAssertEqual(progressList[0].status, .overBudget)
        XCTAssertEqual(progressList[0].percentageUsed, 115.0, accuracy: 0.1)
        XCTAssertEqual(progressList[0].remainingAmount.subunits, 0)

        // Clean up
        try await container.deleteTransactionUseCase.execute(id: tx1Id)
        try await container.deleteTransactionUseCase.execute(id: tx2Id)
        try await container.deleteTransactionUseCase.execute(id: tx3Id)
        try await container.deleteTransactionUseCase.execute(id: tx4Id)
    }

    // MARK: - 3. Multi-Period Budget Management

    func testBudgetPeriods_WeeklyYearlyAndCustomPeriods() async throws {
        // 1. Weekly Budget: Week of Nov 9, 2026
        var calendar = Calendar.current
        var startComps = DateComponents(year: 2026, month: 11, day: 9, hour: 0, minute: 0, second: 0)
        var endComps = DateComponents(year: 2026, month: 11, day: 15, hour: 23, minute: 59, second: 59)
        let weekStartEpoch = Int64((calendar.date(from: startComps) ?? Date()).timeIntervalSince1970 * 1000)
        let weekEndEpoch = Int64((calendar.date(from: endComps) ?? Date()).timeIntervalSince1970 * 1000)

        let weeklyId = try await container.saveBudgetUseCase.execute(
            categoryId: 1,
            amount: Amount(subunits: 500000), // ₹5,000
            month: 11,
            year: 2026,
            periodType: .weekly,
            startDate: weekStartEpoch,
            endDate: weekEndEpoch,
            isRecurring: true
        )
        XCTAssertGreaterThan(weeklyId, 0)

        // 2. Yearly Budget: 2026
        let yearlyId = try await container.saveBudgetUseCase.execute(
            categoryId: nil,
            amount: Amount(subunits: 60000000), // ₹600,000
            month: 1,
            year: 2026,
            periodType: .yearly,
            isRecurring: true
        )
        XCTAssertGreaterThan(yearlyId, 0)

        // 3. Custom Date-Range Budget: Nov 10 to Nov 20
        var custStartComps = DateComponents(year: 2026, month: 11, day: 10, hour: 0, minute: 0, second: 0)
        var custEndComps = DateComponents(year: 2026, month: 11, day: 20, hour: 23, minute: 59, second: 59)
        let custStartEpoch = Int64((calendar.date(from: custStartComps) ?? Date()).timeIntervalSince1970 * 1000)
        let custEndEpoch = Int64((calendar.date(from: custEndComps) ?? Date()).timeIntervalSince1970 * 1000)

        let customId = try await container.saveBudgetUseCase.execute(
            categoryId: 2,
            amount: Amount(subunits: 1000000), // ₹10,000
            month: 11,
            year: 2026,
            periodType: .custom,
            startDate: custStartEpoch,
            endDate: custEndEpoch,
            isRecurring: false
        )
        XCTAssertGreaterThan(customId, 0)

        // Query budgets for November 2026
        let budgets = try await container.budgetRepository.getBudgetsForMonth(year: 2026, month: 11)
        XCTAssertTrue(budgets.contains { $0.id == weeklyId && $0.periodType == .weekly })
        XCTAssertTrue(budgets.contains { $0.id == yearlyId && $0.periodType == .yearly })
        XCTAssertTrue(budgets.contains { $0.id == customId && $0.periodType == .custom })

        // Verify date ranges
        let weeklyBudget = budgets.first { $0.id == weeklyId }
        XCTAssertNotNil(weeklyBudget)
        let (wStart, wEnd) = weeklyBudget!.dateRange()
        XCTAssertEqual(wStart, weekStartEpoch)
        XCTAssertEqual(wEnd, weekEndEpoch)

        // Clean up
        try await container.deleteBudgetUseCase.execute(id: weeklyId)
        try await container.deleteBudgetUseCase.execute(id: yearlyId)
        try await container.deleteBudgetUseCase.execute(id: customId)
    }

    // MARK: - 4. Savings Goal Creation, Deposits & Target Tracking

    func testSavingsGoal_CreationAndTargetProgress() async throws {
        // Goal: ₹200,000 target with ₹20,000 initial seed
        let goalId = try await container.saveSavingsGoalUseCase.execute(
            name: "MacBook Pro",
            targetAmount: Amount(subunits: 20000000),
            initialSavedAmount: Amount(subunits: 2000000),
            note: "M3 Max for iOS dev",
            iconName: "laptop",
            colorHex: "#3B82F6"
        )
        XCTAssertGreaterThan(goalId, 0)

        var goal = try await container.savingsGoalRepository.getGoal(id: goalId)
        XCTAssertNotNil(goal)
        XCTAssertEqual(goal?.name, "MacBook Pro")
        XCTAssertEqual(goal?.currentSavedAmount.subunits, 2000000)
        XCTAssertEqual(goal?.remainingAmount.subunits, 18000000)
        XCTAssertEqual(goal?.progressPercentage ?? 0, 10.0, accuracy: 0.1)
        XCTAssertFalse(goal?.isCompleted ?? true)

        // Add Deposit 1: ₹80,000
        let contrib1 = try await container.recordSavingsContributionUseCase.execute(
            goalId: goalId,
            amount: Amount(subunits: 8000000),
            note: "Monthly bonus deposit"
        )
        XCTAssertGreaterThan(contrib1.id, 0)

        goal = try await container.savingsGoalRepository.getGoal(id: goalId)
        XCTAssertEqual(goal?.currentSavedAmount.subunits, 10000000) // ₹100,000
        XCTAssertEqual(goal?.progressPercentage ?? 0, 50.0, accuracy: 0.1)
        XCTAssertFalse(goal?.isCompleted ?? true)

        // Clean up
        try await container.deleteSavingsGoalUseCase.execute(id: goalId)
        let deleted = try await container.savingsGoalRepository.getGoal(id: goalId)
        XCTAssertNil(deleted)
    }

    // MARK: - 5. Savings Withdrawal Workflow & Validation

    func testSavingsWithdrawal_ReducesGoalBalanceAndUpdatesProgress() async throws {
        // Setup goal with ₹50,000 saved out of ₹100,000 target
        let goalId = try await container.saveSavingsGoalUseCase.execute(
            name: "Vacation Fund",
            targetAmount: Amount(subunits: 10000000),
            initialSavedAmount: Amount(subunits: 5000000)
        )

        var goal = try await container.savingsGoalRepository.getGoal(id: goalId)
        XCTAssertEqual(goal?.currentSavedAmount.subunits, 5000000) // ₹50,000
        XCTAssertEqual(goal?.progressPercentage ?? 0, 50.0, accuracy: 0.1)

        // Withdraw ₹15,000 (1,500,000 subunits)
        let withdrawal = try await container.recordSavingsWithdrawalUseCase.execute(
            goalId: goalId,
            amount: Amount(subunits: 1500000),
            note: "Flight tickets",
            returnToAccount: true
        )

        XCTAssertTrue(withdrawal.isWithdrawal)
        XCTAssertEqual(withdrawal.displayAmount.subunits, 1500000)

        goal = try await container.savingsGoalRepository.getGoal(id: goalId)
        XCTAssertEqual(goal?.currentSavedAmount.subunits, 3500000, "Current saved balance must decrease to ₹35,000")
        XCTAssertEqual(goal?.remainingAmount.subunits, 6500000, "Remaining target must increase to ₹65,000")
        XCTAssertEqual(goal?.progressPercentage ?? 0, 35.0, accuracy: 0.1)

        // History must record both initial seed and withdrawal
        let history = try await container.savingsGoalRepository.getContributions(goalId: goalId)
        XCTAssertEqual(history.count, 2)
        XCTAssertTrue(history[0].isWithdrawal)
        XCTAssertFalse(history[1].isWithdrawal)

        // Clean up
        try await container.deleteSavingsGoalUseCase.execute(id: goalId)
    }

    func testSavingsWithdrawal_FailsWhenExceedingAvailableSavings() async throws {
        let goalId = try await container.saveSavingsGoalUseCase.execute(
            name: "Car Downpayment",
            targetAmount: Amount(subunits: 10000000),
            initialSavedAmount: Amount(subunits: 2000000) // ₹20,000 available
        )

        // Attempt to withdraw ₹30,000 -> Must fail!
        do {
            _ = try await container.recordSavingsWithdrawalUseCase.execute(
                goalId: goalId,
                amount: Amount(subunits: 3000000),
                note: "Overdraw attempt"
            )
            XCTFail("Withdrawal exceeding available savings must throw an error")
        } catch {
            // Expected validation failure
            XCTAssertTrue(error is RecordSavingsWithdrawalUseCase.WithdrawalError)
        }

        // Available balance must remain intact
        let goal = try await container.savingsGoalRepository.getGoal(id: goalId)
        XCTAssertEqual(goal?.currentSavedAmount.subunits, 2000000)

        try await container.deleteSavingsGoalUseCase.execute(id: goalId)
    }

    func testSavingsWithdrawal_FailsForNonPositiveAmount() async throws {
        let goalId = try await container.saveSavingsGoalUseCase.execute(
            name: "Emergency",
            targetAmount: Amount(subunits: 10000000),
            initialSavedAmount: Amount(subunits: 5000000)
        )

        // Zero withdrawal
        do {
            _ = try await container.recordSavingsWithdrawalUseCase.execute(
                goalId: goalId,
                amount: Amount.zero
            )
            XCTFail("Zero withdrawal must fail")
        } catch {
            XCTAssertTrue(error is RecordSavingsWithdrawalUseCase.WithdrawalError)
        }

        try await container.deleteSavingsGoalUseCase.execute(id: goalId)
    }

    func testSavingsWithdrawal_ReversalRestoresGoalBalanceAndLedger() async throws {
        let goalId = try await container.saveSavingsGoalUseCase.execute(
            name: "Wedding",
            targetAmount: Amount(subunits: 10000000),
            initialSavedAmount: Amount(subunits: 8000000)
        )

        // Make withdrawal of ₹20,000 with returnToAccount: true
        let withdrawal = try await container.recordSavingsWithdrawalUseCase.execute(
            goalId: goalId,
            amount: Amount(subunits: 2000000),
            note: "Venue deposit",
            returnToAccount: true
        )

        XCTAssertNotNil(withdrawal.transactionId)
        let txId = withdrawal.transactionId!

        // Checking ledger must have recorded the inflow transaction
        let tx = try await container.transactionRepository.getTransaction(id: txId)
        XCTAssertNotNil(tx)
        XCTAssertEqual(tx?.type, .income)
        XCTAssertEqual(tx?.amount.subunits, 2000000)

        var goal = try await container.savingsGoalRepository.getGoal(id: goalId)
        XCTAssertEqual(goal?.currentSavedAmount.subunits, 6000000)

        // Reverse the withdrawal!
        try await container.reverseSavingsWithdrawalUseCase.execute(withdrawalId: withdrawal.id)

        // Goal balance must be restored
        goal = try await container.savingsGoalRepository.getGoal(id: goalId)
        XCTAssertEqual(goal?.currentSavedAmount.subunits, 8000000, "Reversing withdrawal must restore available savings")

        // Linked ledger transaction must be deleted
        let reversedTx = try await container.transactionRepository.getTransaction(id: txId)
        XCTAssertNil(reversedTx, "Reversing withdrawal must delete linked inflow ledger transaction")

        try await container.deleteSavingsGoalUseCase.execute(id: goalId)
    }

    // MARK: - 6. Savings Accounting Verification (No Artificial Earned Income)

    func testSavingsWithdrawal_AccountingDoesNotCountAsEarnedIncome() async throws {
        let initialIncome = try await container.transactionRepository.getTotalIncome(
            startEpoch: 0,
            endEpoch: Int64.max
        )

        let goalId = try await container.saveSavingsGoalUseCase.execute(
            name: "Gold Reserve",
            targetAmount: Amount(subunits: 10000000),
            initialSavedAmount: Amount(subunits: 5000000)
        )

        // Withdraw ₹20,000 back to checking
        _ = try await container.recordSavingsWithdrawalUseCase.execute(
            goalId: goalId,
            amount: Amount(subunits: 2000000),
            note: "Return to checking",
            returnToAccount: true
        )

        // Earned Income report must NOT count the withdrawal as new earned income
        let postWithdrawalEarnedIncome = try await container.transactionRepository.getTotalIncome(
            startEpoch: 0,
            endEpoch: Int64.max
        )

        XCTAssertEqual(
            postWithdrawalEarnedIncome.subunits,
            initialIncome.subunits,
            "Internal transfer / savings withdrawal must NOT be counted as earned income in financial reports"
        )

        try await container.deleteSavingsGoalUseCase.execute(id: goalId)
    }

    // MARK: - 7. Archival Lifecycle

    func testSavingsGoal_ArchivalLifecycle() async throws {
        let goalId = try await container.saveSavingsGoalUseCase.execute(
            name: "Summer Vacation",
            targetAmount: Amount(subunits: 5000000)
        )

        var active = try await container.getSavingsGoalsUseCase.getActiveGoals()
        XCTAssertTrue(active.contains { $0.id == goalId })

        // Archive goal
        try await container.setSavingsGoalArchivedUseCase.execute(id: goalId, isArchived: true)

        active = try await container.getSavingsGoalsUseCase.getActiveGoals()
        XCTAssertFalse(active.contains { $0.id == goalId })

        let archived = try await container.getSavingsGoalsUseCase.getArchivedGoals()
        XCTAssertTrue(archived.contains { $0.id == goalId })

        // Unarchive goal
        try await container.setSavingsGoalArchivedUseCase.execute(id: goalId, isArchived: false)

        active = try await container.getSavingsGoalsUseCase.getActiveGoals()
        XCTAssertTrue(active.contains { $0.id == goalId })

        // Clean up
        try await container.deleteSavingsGoalUseCase.execute(id: goalId)
    }

    // MARK: - 8. Internal Transfer Accounting Matrix Verification

    func testInternalTransferAccountingMatrix_ComprehensiveVerification() async throws {
        // Calibrate Opening Balance: ₹100,000 (10,000,000 subunits)
        container.preferencesRepository.setOpeningBalance(10000000)

        // Set Monthly Budget: ₹20,000 (2,000,000 subunits) for Nov 2026
        _ = try await container.saveBudgetUseCase.execute(
            categoryId: nil,
            amount: Amount(subunits: 2000000),
            month: 11,
            year: 2026
        )

        var calendar = Calendar.current
        var comps = DateComponents(year: 2026, month: 11, day: 10, hour: 12)
        let testEpoch = Int64((calendar.date(from: comps) ?? Date()).timeIntervalSince1970 * 1000)

        // 1. Log ordinary expense of ₹5,000 (Food & Dining)
        let ordinaryTxId = try await container.addTransactionUseCase.execute(
            amount: Amount(subunits: 500000),
            type: .expense,
            categoryId: 1,
            paymentMethod: .account,
            note: "Weekly Groceries",
            timestamp: testEpoch
        )
        XCTAssertGreaterThan(ordinaryTxId, 0)

        // Baseline verification:
        var summary = try await container.getFinancialSummaryUseCase.execute()
        XCTAssertEqual(summary.currentBalance.subunits, 9500000, "Checking balance = ₹100,000 - ₹5,000 = ₹95,000")
        XCTAssertEqual(summary.totalExpense.subunits, 500000, "Ordinary expense = ₹5,000")
        XCTAssertEqual(summary.totalIncome.subunits, 0, "Earned income = ₹0")

        var budgetProgress = try await container.getBudgetProgressUseCase.execute(year: 2026, month: 11)
        XCTAssertEqual(budgetProgress.first?.usedAmount.subunits, 500000, "Budget spend = ₹5,000")
        XCTAssertEqual(budgetProgress.first?.percentageUsed ?? 0, 25.0, accuracy: 0.1)

        // 2. Create Savings Goal and deposit ₹10,000 with ledger deduction
        let goalId = try await container.saveSavingsGoalUseCase.execute(
            name: "Emergency Fund",
            targetAmount: Amount(subunits: 50000000)
        )

        let depositContrib = try await container.recordSavingsContributionUseCase.execute(
            goalId: goalId,
            amount: Amount(subunits: 1000000), // ₹10,000
            note: "Transfer to Savings",
            timestamp: testEpoch,
            createTransaction: true,
            paymentMethod: .account
        )
        XCTAssertNotNil(depositContrib.transactionId)

        // Verify Matrix after Savings Deposit:
        // - Checking balance: Decreased by ₹10,000 (₹95,000 -> ₹85,000)
        // - Savings goal balance: Increased to ₹10,000
        // - Ordinary expenses: Excluded (remains ₹5,000)
        // - Earned income: Excluded (remains ₹0)
        // - Budget utilisation: Excluded (remains 25%, ₹5,000 used)
        summary = try await container.getFinancialSummaryUseCase.execute()
        XCTAssertEqual(summary.currentBalance.subunits, 8500000, "Checking balance must decrease by ₹10,000 to ₹85,000")
        XCTAssertEqual(summary.totalExpense.subunits, 500000, "Savings deposit must NOT count as ordinary expense")
        XCTAssertEqual(summary.totalIncome.subunits, 0, "Savings deposit must NOT count as income")

        var goal = try await container.savingsGoalRepository.getGoal(id: goalId)
        XCTAssertEqual(goal?.currentSavedAmount.subunits, 1000000, "Goal saved amount must be ₹10,000")

        budgetProgress = try await container.getBudgetProgressUseCase.execute(year: 2026, month: 11)
        XCTAssertEqual(budgetProgress.first?.usedAmount.subunits, 500000, "Savings deposit must NOT consume budget")
        XCTAssertEqual(budgetProgress.first?.percentageUsed ?? 0, 25.0, accuracy: 0.1)

        let monthlyExpense = try await container.getMonthlyExpenseSummaryUseCase.execute(year: 2026, month: 11)
        XCTAssertEqual(monthlyExpense.totalExpense.subunits, 500000, "Monthly expense summary must NOT include savings deposit")

        // 3. Withdraw ₹4,000 from Savings Goal back to checking
        let withdrawal = try await container.recordSavingsWithdrawalUseCase.execute(
            goalId: goalId,
            amount: Amount(subunits: 400000), // ₹4,000
            note: "Transfer from Savings",
            timestamp: testEpoch,
            returnToAccount: true,
            paymentMethod: .account
        )
        XCTAssertNotNil(withdrawal.transactionId)

        // Verify Matrix after Savings Withdrawal:
        // - Checking balance: Increased by ₹4,000 (₹85,000 -> ₹89,000)
        // - Savings goal balance: Decreased to ₹6,000 (₹10,000 - ₹4,000)
        // - Ordinary expenses: Excluded (remains ₹5,000)
        // - Earned income: Excluded (remains ₹0, NOT counted as earned income)
        // - Budget utilisation: Excluded (remains 25%)
        summary = try await container.getFinancialSummaryUseCase.execute()
        XCTAssertEqual(summary.currentBalance.subunits, 8900000, "Checking balance must increase by ₹4,000 to ₹89,000")
        XCTAssertEqual(summary.totalExpense.subunits, 500000, "Savings withdrawal must NOT change ordinary expense")
        XCTAssertEqual(summary.totalIncome.subunits, 0, "Savings withdrawal must NOT count as earned income")

        goal = try await container.savingsGoalRepository.getGoal(id: goalId)
        XCTAssertEqual(goal?.currentSavedAmount.subunits, 600000, "Goal saved amount must decrease to ₹6,000")

        budgetProgress = try await container.getBudgetProgressUseCase.execute(year: 2026, month: 11)
        XCTAssertEqual(budgetProgress.first?.usedAmount.subunits, 500000, "Savings withdrawal must NOT change budget utilisation")

        let monthCashflow = try await container.getFinancialSummaryUseCase.executeForMonth(year: 2026, month: 11)
        XCTAssertEqual(monthCashflow.income.subunits, 0, "Monthly cash flow earned income must exclude internal transfer withdrawal")
        XCTAssertEqual(monthCashflow.expense.subunits, 500000, "Monthly cash flow ordinary expense must exclude internal transfer deposit")

        // 4. Reversal of withdrawal: restores balances cleanly
        try await container.reverseSavingsWithdrawalUseCase.execute(withdrawalId: withdrawal.id)

        summary = try await container.getFinancialSummaryUseCase.execute()
        XCTAssertEqual(summary.currentBalance.subunits, 8500000, "Reversing withdrawal restores checking balance to ₹85,000")

        goal = try await container.savingsGoalRepository.getGoal(id: goalId)
        XCTAssertEqual(goal?.currentSavedAmount.subunits, 1000000, "Reversing withdrawal restores goal saved amount to ₹10,000")

        // Clean up
        try await container.deleteTransactionUseCase.execute(id: ordinaryTxId)
        try await container.deleteSavingsGoalUseCase.execute(id: goalId)
    }
}
