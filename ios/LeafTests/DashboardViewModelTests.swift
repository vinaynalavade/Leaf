import XCTest
#if canImport(LeafCore)
@testable import LeafCore
#elseif canImport(Leaf)
@testable import Leaf
#endif

final class DashboardViewModelTests: XCTestCase {

    var appDatabase: AppDatabase!
    var categoryRepo: GRDBCategoryRepository!
    var transactionRepo: GRDBTransactionRepository!
    var budgetRepo: GRDBBudgetRepository!
    var prefsRepo: UserPreferencesRepository!

    var getFinancialSummaryUseCase: GetFinancialSummaryUseCase!
    var getBudgetProgressUseCase: GetBudgetProgressUseCase!
    var getTransactionsUseCase: GetTransactionsUseCase!
    var deleteTransactionUseCase: DeleteTransactionUseCase!
    var addTransactionUseCase: AddTransactionUseCase!

    override func setUpWithError() throws {
        appDatabase = try AppDatabase.makeInMemory()
        categoryRepo = GRDBCategoryRepository(database: appDatabase)
        transactionRepo = GRDBTransactionRepository(database: appDatabase)
        budgetRepo = GRDBBudgetRepository(database: appDatabase)
        prefsRepo = UserPreferencesRepository(defaults: UserDefaults(suiteName: "LeafTestDefaults")!)

        // Reset test prefs
        prefsRepo.setOpeningBalance(0)
        prefsRepo.setBalanceVisible(true)
        prefsRepo.setCurrencyCode("INR")
        prefsRepo.setProfileName("Vinay")

        getFinancialSummaryUseCase = GetFinancialSummaryUseCase(
            transactionRepository: transactionRepo,
            preferencesRepository: prefsRepo
        )
        getBudgetProgressUseCase = GetBudgetProgressUseCase(
            budgetRepository: budgetRepo,
            transactionRepository: transactionRepo
        )
        getTransactionsUseCase = GetTransactionsUseCase(repository: transactionRepo)
        deleteTransactionUseCase = DeleteTransactionUseCase(repository: transactionRepo)
        addTransactionUseCase = AddTransactionUseCase(
            transactionRepository: transactionRepo,
            categoryRepository: categoryRepo
        )
    }

    func testFinancialSummaryWithOpeningBalance() async throws {
        // Set opening balance of ₹10,000 (1,000,000 paise)
        prefsRepo.setOpeningBalance(1000000)

        // Log Income ₹50,000 (5,000,000 paise)
        _ = try await addTransactionUseCase.execute(
            amount: Amount(subunits: 5000000),
            type: .income,
            categoryId: 13, // Salary
            paymentMethod: .account,
            note: "Salary"
        )

        // Log Expense ₹12,000 (1,200,000 paise)
        _ = try await addTransactionUseCase.execute(
            amount: Amount(subunits: 1200000),
            type: .expense,
            categoryId: 1, // Food & Dining
            paymentMethod: .cash,
            note: "Groceries"
        )

        let summary = try await getFinancialSummaryUseCase.execute()
        XCTAssertEqual(summary.openingBalance.subunits, 1000000)
        XCTAssertEqual(summary.totalIncome.subunits, 5000000)
        XCTAssertEqual(summary.totalExpense.subunits, 1200000)
        XCTAssertEqual(summary.netChange.subunits, 3800000)
        // Current Balance = 1000000 + 3800000 = 4800000
        XCTAssertEqual(summary.currentBalance.subunits, 4800000)
        XCTAssertEqual(summary.transactionCount, 2)
    }

    func testPrivacyToggleState() async throws {
        let viewModel = DashboardViewModel(
            getFinancialSummaryUseCase: getFinancialSummaryUseCase,
            getBudgetProgressUseCase: getBudgetProgressUseCase,
            getTransactionsUseCase: getTransactionsUseCase,
            deleteTransactionUseCase: deleteTransactionUseCase,
            preferencesRepository: prefsRepo
        )

        XCTAssertTrue(viewModel.isBalanceVisible)

        viewModel.toggleBalanceVisibility()
        XCTAssertFalse(viewModel.isBalanceVisible)
        XCTAssertFalse(prefsRepo.getUserPreferences().isBalanceVisible)

        viewModel.toggleBalanceVisibility()
        XCTAssertTrue(viewModel.isBalanceVisible)
        XCTAssertTrue(prefsRepo.getUserPreferences().isBalanceVisible)
    }

    func testBudgetFourTierThresholds() async throws {
        let calendar = Calendar.current
        let now = Date()
        let year = calendar.component(.year, from: now)
        let month = calendar.component(.month, from: now)

        // Monthly Budget of ₹10,000 (1,000,000 paise)
        let budget = Budget(
            categoryId: nil, // Overall budget
            amount: Amount(subunits: 1000000),
            month: month,
            year: year
        )
        _ = try await budgetRepo.insertBudget(budget)

        // Tier 1: On Track (< 75% -> e.g. ₹5,000 / 500,000 paise)
        _ = try await addTransactionUseCase.execute(
            amount: Amount(subunits: 500000),
            type: .expense,
            categoryId: 1
        )
        var featured = try await getBudgetProgressUseCase.getFeaturedBudget(year: year, month: month)
        XCTAssertNotNil(featured)
        XCTAssertEqual(featured?.status, .onTrack)
        XCTAssertEqual(featured?.percentageUsed, 50.0)
        XCTAssertEqual(featured?.remainingAmount.subunits, 500000)

        // Tier 2: Approaching Limit (75% to 99% -> add ₹3,000 -> total ₹8,000 / 80%)
        _ = try await addTransactionUseCase.execute(
            amount: Amount(subunits: 300000),
            type: .expense,
            categoryId: 1
        )
        featured = try await getBudgetProgressUseCase.getFeaturedBudget(year: year, month: month)
        XCTAssertEqual(featured?.status, .approachingLimit)
        XCTAssertEqual(featured?.percentageUsed, 80.0)
        XCTAssertEqual(featured?.remainingAmount.subunits, 200000)

        // Tier 3: Limit Reached (Exactly 100% -> add ₹2,000 -> total ₹10,000 / 100%)
        _ = try await addTransactionUseCase.execute(
            amount: Amount(subunits: 200000),
            type: .expense,
            categoryId: 1
        )
        featured = try await getBudgetProgressUseCase.getFeaturedBudget(year: year, month: month)
        XCTAssertEqual(featured?.status, .limitReached)
        XCTAssertEqual(featured?.percentageUsed, 100.0)
        XCTAssertEqual(featured?.remainingAmount.subunits, 0)

        // Tier 4: Over Budget (> 100% -> add ₹500 -> total ₹10,500 / 105%)
        _ = try await addTransactionUseCase.execute(
            amount: Amount(subunits: 50000),
            type: .expense,
            categoryId: 1
        )
        featured = try await getBudgetProgressUseCase.getFeaturedBudget(year: year, month: month)
        XCTAssertEqual(featured?.status, .overBudget)
        XCTAssertEqual(featured?.percentageUsed, 105.0)
        XCTAssertEqual(featured?.remainingAmount.subunits, 0)
    }

    func testRecentTransactionsOrderingAndLimit() async throws {
        // Insert 7 transactions
        for i in 1...7 {
            _ = try await addTransactionUseCase.execute(
                amount: Amount(subunits: Int64(i * 1000)),
                type: .expense,
                categoryId: 1,
                note: "Tx \(i)",
                timestamp: Int64(1700000000000 + (i * 100000))
            )
        }

        let recent = try await getTransactionsUseCase.getRecent(limit: 5)
        XCTAssertEqual(recent.count, 5)
        // Tx 7 should be first (most recent timestamp)
        XCTAssertEqual(recent[0].note, "Tx 7")
        XCTAssertEqual(recent[4].note, "Tx 3")
    }

    func testEmptyStateWhenNoData() async throws {
        let viewModel = DashboardViewModel(
            getFinancialSummaryUseCase: getFinancialSummaryUseCase,
            getBudgetProgressUseCase: getBudgetProgressUseCase,
            getTransactionsUseCase: getTransactionsUseCase,
            deleteTransactionUseCase: deleteTransactionUseCase,
            preferencesRepository: prefsRepo
        )

        await viewModel.loadData()

        XCTAssertEqual(viewModel.summary.currentBalance.subunits, 0)
        XCTAssertEqual(viewModel.monthlyIncome.subunits, 0)
        XCTAssertEqual(viewModel.monthlyExpense.subunits, 0)
        XCTAssertNil(viewModel.featuredBudget)
        XCTAssertTrue(viewModel.recentTransactions.isEmpty)
    }

    func testLargeMonetaryValuesAndFormatting() async throws {
        // ₹10,000,000.00 (1,000,000,000 paise - Ten Million)
        let largeAmount = Amount(subunits: 1000000000)
        XCTAssertEqual(largeAmount.format(currency: .inr), "₹10,000,000.00")

        // Negative net balance
        let negBalance = Amount(subunits: -45050)
        XCTAssertEqual(negBalance.format(currency: .inr), "-₹450.50")
    }

    // MARK: - App Lock & PIN Security Tests

    func testNewUserInitialZeroBalanceWithoutOpeningBalanceCalibration() async throws {
        let freshRepo = UserPreferencesRepository(defaults: UserDefaults(suiteName: "FreshUserDefaults.\(UUID().uuidString)")!)
        let summaryUseCase = GetFinancialSummaryUseCase(
            transactionRepository: transactionRepo,
            preferencesRepository: freshRepo
        )

        let summary = try await summaryUseCase.execute()
        XCTAssertEqual(summary.openingBalance.subunits, 0, "Default opening balance must be 0")
        XCTAssertEqual(summary.currentBalance.subunits, 0, "Default current balance for new user must be ₹0.00")
        XCTAssertEqual(summary.totalIncome.subunits, 0)
        XCTAssertEqual(summary.totalExpense.subunits, 0)
    }

    func testSecurePinLifecycleAndThrottling() {
        let pinManager = SecurePinManager.shared
        _ = pinManager.clearPin()
        XCTAssertFalse(pinManager.isPinConfigured(), "PIN must not be configured initially")

        // 1. Invalid PINs (< 6 digits or non-numeric)
        XCTAssertFalse(pinManager.savePin("12345"), "Must reject 5-digit PIN")
        XCTAssertFalse(pinManager.savePin("1234567"), "Must reject 7-digit PIN")
        XCTAssertFalse(pinManager.savePin("12345a"), "Must reject alphanumeric PIN")

        // 2. Valid PIN
        XCTAssertTrue(pinManager.savePin("123456"), "Must accept valid 6-digit PIN")
        XCTAssertTrue(pinManager.isPinConfigured(), "PIN must now be configured")

        // 3. Successful verification
        XCTAssertEqual(pinManager.verifyPin("123456"), .success)

        // 4. Incorrect attempts and rate-limiting
        let wrong1 = pinManager.verifyPin("654321")
        XCTAssertEqual(wrong1, .incorrect(remainingAttempts: 4))

        let wrong2 = pinManager.verifyPin("000000")
        XCTAssertEqual(wrong2, .incorrect(remainingAttempts: 3))

        let wrong3 = pinManager.verifyPin("111111")
        XCTAssertEqual(wrong3, .incorrect(remainingAttempts: 2))

        let wrong4 = pinManager.verifyPin("222222")
        XCTAssertEqual(wrong4, .incorrect(remainingAttempts: 1))

        // 5th failed attempt -> 30-second lockout
        let wrong5 = pinManager.verifyPin("333333")
        if case .lockedOut(let seconds) = wrong5 {
            XCTAssertTrue(seconds > 0 && seconds <= 30)
        } else {
            XCTFail("5 consecutive failed attempts must trigger lockout")
        }

        // Subsequent attempt during lockout remains locked out
        let lockedAttempt = pinManager.verifyPin("123456")
        if case .lockedOut = lockedAttempt {
            // Success: locked out even with correct PIN
        } else {
            XCTFail("Must reject attempts during active lockout")
        }

        // Clean up
        _ = pinManager.clearPin()
        XCTAssertFalse(pinManager.isPinConfigured())
    }

    func testAppLockAutoSanitizationWhenEnabledWithoutPin() {
        let suite = "SanitizationDefaults.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defaults.set(true, forKey: "pref_app_lock_enabled")

        let prefsRepo = UserPreferencesRepository(defaults: defaults)
        let pinManager = SecurePinManager.shared
        _ = pinManager.clearPin() // Ensure no PIN is configured

        let appLockService = AppLockService(preferencesRepository: prefsRepo, pinManager: pinManager)

        // Defense: Must sanitize and not lock users out
        XCTAssertFalse(appLockService.isAppLockEnabled, "App Lock must be automatically disabled when no PIN exists")
        XCTAssertFalse(appLockService.isLocked, "App must NOT be locked when no PIN exists")
        XCTAssertFalse(prefsRepo.getUserPreferences().appLockEnabled, "Preferences must be sanitized to disabled")
    }

    func testAppLockEnableDisableAndChangePinFlow() {
        let suite = "FlowDefaults.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        let prefsRepo = UserPreferencesRepository(defaults: defaults)
        let pinManager = SecurePinManager.shared
        _ = pinManager.clearPin()

        let appLockService = AppLockService(preferencesRepository: prefsRepo, pinManager: pinManager)
        XCTAssertFalse(appLockService.isAppLockEnabled)

        // Enable App Lock with PIN
        let enabled = appLockService.enableAppLock(pin: "987654", enableBiometrics: true)
        XCTAssertTrue(enabled)
        XCTAssertTrue(appLockService.isAppLockEnabled)
        XCTAssertTrue(appLockService.isBiometricEnabled)
        XCTAssertTrue(prefsRepo.getUserPreferences().appLockEnabled)

        // Change PIN
        let changeResult = appLockService.changePin(currentPin: "987654", newPin: "456789")
        XCTAssertEqual(changeResult, .success)
        XCTAssertEqual(pinManager.verifyPin("456789"), .success)
        XCTAssertNotEqual(pinManager.verifyPin("987654"), .success)

        // Disable App Lock (requires current PIN)
        let badDisable = appLockService.disableAppLock(currentPin: "000000")
        XCTAssertNotEqual(badDisable, .success)
        XCTAssertTrue(appLockService.isAppLockEnabled)

        let goodDisable = appLockService.disableAppLock(currentPin: "456789")
        XCTAssertEqual(goodDisable, .success)
        XCTAssertFalse(appLockService.isAppLockEnabled)
        XCTAssertFalse(pinManager.isPinConfigured())
    }
}
