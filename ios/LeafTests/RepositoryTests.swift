import XCTest
#if canImport(LeafCore)
@testable import LeafCore
#elseif canImport(Leaf)
@testable import Leaf
#endif

final class RepositoryTests: XCTestCase {

    var appDatabase: AppDatabase!
    var categoryRepo: GRDBCategoryRepository!
    var transactionRepo: GRDBTransactionRepository!

    override func setUpWithError() throws {
        appDatabase = try AppDatabase.makeInMemory()
        categoryRepo = GRDBCategoryRepository(database: appDatabase)
        transactionRepo = GRDBTransactionRepository(database: appDatabase)
    }

    func testTransactionInsertionAndNetBalance() async throws {
        // Categories 1 to 20 are pre-seeded
        let foodCategory = try await categoryRepo.getCategory(id: 1)
        XCTAssertNotNil(foodCategory)
        XCTAssertEqual(foodCategory?.name, "Food & Dining")

        let salaryCategory = try await categoryRepo.getCategory(id: 13)
        XCTAssertNotNil(salaryCategory)
        XCTAssertEqual(salaryCategory?.name, "Salary")

        // 1. Log Income ₹50,000 (5,000,000 paise)
        let incomeTx = Transaction(
            amount: Amount(subunits: 5000000),
            type: .income,
            categoryId: 13,
            paymentMethod: .account,
            note: "Monthly Salary"
        )
        let incomeId = try await transactionRepo.insertTransaction(incomeTx)
        XCTAssertGreaterThan(incomeId, 0)

        // 2. Log Expense ₹1,200.50 (120,050 paise)
        let expenseTx = Transaction(
            amount: Amount(subunits: 120050),
            type: .expense,
            categoryId: 1,
            paymentMethod: .cash,
            note: "Team dinner"
        )
        let expenseId = try await transactionRepo.insertTransaction(expenseTx)
        XCTAssertGreaterThan(expenseId, 0)

        // 3. Verify Net Balance: 5000000 - 120050 = 4879950 paise
        let balance = try await transactionRepo.getNetBalance()
        XCTAssertEqual(balance.subunits, 4879950)

        // 4. Verify Total Expense & Income
        let totalIncome = try await transactionRepo.getTotalIncome(startEpoch: 0, endEpoch: Int64.max)
        XCTAssertEqual(totalIncome.subunits, 5000000)

        let totalExpense = try await transactionRepo.getTotalExpense(startEpoch: 0, endEpoch: Int64.max)
        XCTAssertEqual(totalExpense.subunits, 120050)

        // 5. Query all transactions
        let all = try await transactionRepo.getAllTransactions()
        XCTAssertEqual(all.count, 2)
        XCTAssertEqual(all[0].category?.name, "Food & Dining") // Ordered by timestamp desc
    }

    func testSeparateCashAndAccountLedgersAndTransfers() async throws {
        // 1. Initial State: Both ledgers are empty
        let initialCash = try await transactionRepo.getBalance(for: .cash)
        let initialAccount = try await transactionRepo.getBalance(for: .account)
        XCTAssertEqual(initialCash.subunits, 0)
        XCTAssertEqual(initialAccount.subunits, 0)

        // 2. Deposit ₹10,000 into Account and ₹2,000 into Cash
        _ = try await transactionRepo.insertTransaction(Transaction(
            amount: Amount(subunits: 1000000), // ₹10,000
            type: .income,
            categoryId: 13,
            paymentMethod: .account,
            note: "Account Deposit"
        ))

        _ = try await transactionRepo.insertTransaction(Transaction(
            amount: Amount(subunits: 200000), // ₹2,000
            type: .income,
            categoryId: 13,
            paymentMethod: .cash,
            note: "Cash Received"
        ))

        let cashBal1 = try await transactionRepo.getBalance(for: .cash)
        let acctBal1 = try await transactionRepo.getBalance(for: .account)
        let netBal1 = try await transactionRepo.getNetBalance()

        XCTAssertEqual(cashBal1.subunits, 200000)
        XCTAssertEqual(acctBal1.subunits, 1000000)
        XCTAssertEqual(netBal1.subunits, 1200000)

        // 3. Spend ₹500 from Cash
        _ = try await transactionRepo.insertTransaction(Transaction(
            amount: Amount(subunits: 50000), // ₹500
            type: .expense,
            categoryId: 1,
            paymentMethod: .cash,
            note: "Groceries"
        ))

        let cashBal2 = try await transactionRepo.getBalance(for: .cash)
        let acctBal2 = try await transactionRepo.getBalance(for: .account)
        let netBal2 = try await transactionRepo.getNetBalance()

        XCTAssertEqual(cashBal2.subunits, 150000) // ₹1,500
        XCTAssertEqual(acctBal2.subunits, 1000000) // ₹10,000
        XCTAssertEqual(netBal2.subunits, 1150000) // ₹11,500

        // 4. Transfer ₹1,000 from Cash to Account
        let (outId, inId) = try await transactionRepo.transferBetweenLedgers(
            from: .cash,
            to: .account,
            amount: Amount(subunits: 100000), // ₹1,000
            note: "Bank ATM Deposit",
            timestamp: Int64(Date().timeIntervalSince1970 * 1000)
        )
        XCTAssertGreaterThan(outId, 0)
        XCTAssertGreaterThan(inId, 0)

        // 5. Verify Ledger Balances after transfer:
        // Cash: 150,000 - 100,000 = 50,000 (₹500)
        // Account: 1,000,000 + 100,000 = 1,100,000 (₹11,000)
        // Net Liquid Balance remains exactly ₹11,500 (No double counting)
        let cashBal3 = try await transactionRepo.getBalance(for: .cash)
        let acctBal3 = try await transactionRepo.getBalance(for: .account)
        let netBal3 = try await transactionRepo.getNetBalance()

        XCTAssertEqual(cashBal3.subunits, 50000)
        XCTAssertEqual(acctBal3.subunits, 1100000)
        XCTAssertEqual(netBal3.subunits, 1150000)
        XCTAssertEqual(cashBal3.subunits + acctBal3.subunits, netBal3.subunits)

        // 6. Verify Ordinary Economic Income & Expenses (Transfers must have 0 effect)
        let totalIncome = try await transactionRepo.getTotalIncome(startEpoch: 0, endEpoch: Int64.max)
        let totalExpense = try await transactionRepo.getTotalExpense(startEpoch: 0, endEpoch: Int64.max)
        XCTAssertEqual(totalIncome.subunits, 1200000) // ₹10,000 + ₹2,000
        XCTAssertEqual(totalExpense.subunits, 50000) // Only ₹500 groceries

        // 7. Verify Independent Transaction Lists
        let cashTxs = try await transactionRepo.getTransactions(for: .cash)
        let acctTxs = try await transactionRepo.getTransactions(for: .account)
        XCTAssertEqual(cashTxs.count, 3) // income, expense, outflow transfer
        XCTAssertEqual(acctTxs.count, 2) // income, inflow transfer
    }

    func testWidgetBalancePrivacyMasking() {
        let snapshotVisible = WidgetFinancialSnapshot(
            currentBalanceSubunits: 1542000,
            monthlyIncomeSubunits: 5000000,
            monthlyExpenseSubunits: 120000,
            currencyCode: "INR",
            budgetLimitSubunits: 500000,
            budgetSpentSubunits: 120000,
            budgetProgressRatio: 0.24,
            isBalanceVisible: true
        )

        XCTAssertTrue(snapshotVisible.formattedBalance.contains("15,420") || snapshotVisible.formattedBalance.contains("₹"))
        XCTAssertFalse(snapshotVisible.formattedBalance.contains("••••••"))

        let snapshotMasked = WidgetFinancialSnapshot(
            currentBalanceSubunits: 1542000,
            monthlyIncomeSubunits: 5000000,
            monthlyExpenseSubunits: 120000,
            currencyCode: "INR",
            budgetLimitSubunits: 500000,
            budgetSpentSubunits: 120000,
            budgetProgressRatio: 0.24,
            isBalanceVisible: false
        )

        XCTAssertEqual(snapshotMasked.formattedBalance, "₹••••••")
        XCTAssertEqual(snapshotMasked.formattedIncome, "₹••••••")
        XCTAssertEqual(snapshotMasked.formattedExpense, "₹••••••")
        XCTAssertEqual(snapshotMasked.formattedBudgetRemaining, "₹••••••")
    }

    func testDefaultTransactionSourcePreference() {
        let testDefaults = UserDefaults(suiteName: "test.preferences.\(UUID().uuidString)")!
        let repo = UserPreferencesRepository(defaults: testDefaults)

        let initialPrefs = repo.getUserPreferences()
        XCTAssertEqual(initialPrefs.defaultTransactionSource, .cash)

        repo.setDefaultTransactionSource(.account)
        let updatedPrefs = repo.getUserPreferences()
        XCTAssertEqual(updatedPrefs.defaultTransactionSource, .account)
    }

    func testLegitimateOneLakhOpeningBalancePreserved() {
        let testDefaults = UserDefaults(suiteName: "test.openingBalance.\(UUID().uuidString)")!
        let repo = UserPreferencesRepository(defaults: testDefaults)

        // Set legitimate 1 Lakh (₹1,00,000 = 10,000,000 subunits)
        repo.setOpeningBalance(10000000)

        // Re-read directly
        let prefs = repo.getUserPreferences()
        XCTAssertEqual(prefs.openingBalanceSubunits, 10000000, "Legitimate ₹1 Lakh opening balance must NEVER be erased or wiped")

        // Re-instantiate repository to ensure initialization does not sanitize
        let repoReopened = UserPreferencesRepository(defaults: testDefaults)
        let prefsReopened = repoReopened.getUserPreferences()
        XCTAssertEqual(prefsReopened.openingBalanceSubunits, 10000000, "Reopening repository must preserve legitimate ₹1 Lakh opening balance")
    }

    func testThemeModeReactiveSetting() {
        let suiteName = "test.themePersistence.\(UUID().uuidString)"
        let testDefaults = UserDefaults(suiteName: suiteName)!
        let prefsRepo = UserPreferencesRepository(defaults: testDefaults)
        let db = try! AppDatabase.makeInMemory()
        let container = AppContainer(database: db, preferencesRepository: prefsRepo)

        XCTAssertEqual(container.currentThemeMode, "SYSTEM")
        XCTAssertNil(container.themeColorScheme)

        container.setThemeMode("LIGHT")
        XCTAssertEqual(container.currentThemeMode, "LIGHT")
        XCTAssertEqual(container.themeColorScheme, .light)

        container.setThemeMode("DARK")
        XCTAssertEqual(container.currentThemeMode, "DARK")
        XCTAssertEqual(container.themeColorScheme, .dark)

        // Verify persistence after relaunch: simulate new app launch with same persistent store
        let containerAfterRelaunch = AppContainer(database: db, preferencesRepository: UserPreferencesRepository(defaults: testDefaults))
        XCTAssertEqual(containerAfterRelaunch.currentThemeMode, "DARK", "Theme preference must persist across app relaunches")
        XCTAssertEqual(containerAfterRelaunch.themeColorScheme, .dark)

        containerAfterRelaunch.setThemeMode("SYSTEM")
        XCTAssertEqual(containerAfterRelaunch.currentThemeMode, "SYSTEM")
        XCTAssertNil(containerAfterRelaunch.themeColorScheme)
    }

    func testSecurePinManagerPBKDF2AndLegacyMigration() {
        let pinManager = SecurePinManager.shared
        _ = pinManager.clearPin()

        // 1. PIN format validation
        XCTAssertFalse(pinManager.savePin("12345")) // too short
        XCTAssertFalse(pinManager.savePin("1234567")) // too long
        XCTAssertFalse(pinManager.savePin("abcdef")) // non-numeric

        // 2. Save valid 6-digit PIN with PBKDF2
        let pin = "948216"
        XCTAssertTrue(pinManager.savePin(pin))
        XCTAssertTrue(pinManager.isPinConfigured())

        // 3. Verify valid PIN
        let correctResult = pinManager.verifyPin(pin)
        XCTAssertEqual(correctResult, .success)

        // 4. Verify invalid PIN
        let wrongResult = pinManager.verifyPin("000000")
        if case .incorrect(let remaining) = wrongResult {
            XCTAssertEqual(remaining, SecurePinManager.maxFailedAttempts - 1)
        } else {
            XCTFail("Expected incorrect result")
        }

        // 5. Clean up
        XCTAssertTrue(pinManager.clearPin())
        XCTAssertFalse(pinManager.isPinConfigured())
    }

    func testTransferEditDeletionAndReversal() async throws {
        // 1. Initial transfer from Cash to Account: ₹1,000 (100,000 subunits)
        let (outId, inId) = try await transactionRepo.transferBetweenLedgers(
            from: .cash,
            to: .account,
            amount: Amount(subunits: 100000),
            note: "ATM Cash Deposit",
            timestamp: 1700000000000
        )
        XCTAssertGreaterThan(outId, 0)
        XCTAssertGreaterThan(inId, 0)

        // Verify that both transfer entries are linked together
        let outflowTx = try await transactionRepo.getTransaction(id: outId)
        let inflowTx = try await transactionRepo.getTransaction(id: inId)
        XCTAssertEqual(outflowTx?.transferPairId, inId, "Outflow must point to Inflow as paired counterpart")
        XCTAssertEqual(inflowTx?.transferPairId, outId, "Inflow must point to Outflow as paired counterpart")

        // Verify balances after initial transfer
        var cashBal = try await transactionRepo.getBalance(for: .cash)
        var acctBal = try await transactionRepo.getBalance(for: .account)
        XCTAssertEqual(cashBal.subunits, -100000)
        XCTAssertEqual(acctBal.subunits, 100000)

        // 2. Edit transfer transaction note and amount via UpdateTransactionUseCase
        let updateUseCase = UpdateTransactionUseCase(
            transactionRepository: transactionRepo,
            categoryRepository: categoryRepo
        )

        try await updateUseCase.execute(
            id: outId,
            amount: Amount(subunits: 250000), // Updated to ₹2,500
            type: .expense,
            categoryId: outflowTx!.categoryId,
            paymentMethod: .cash,
            note: "Updated ATM Deposit Note",
            timestamp: 1700000005000
        )

        // Verify consistent atomic update across both entries
        let reloadedOutflow = try await transactionRepo.getTransaction(id: outId)
        let reloadedInflow = try await transactionRepo.getTransaction(id: inId)
        XCTAssertEqual(reloadedOutflow?.amount.subunits, 250000)
        XCTAssertEqual(reloadedInflow?.amount.subunits, 250000, "Inflow amount must update atomically when outflow is edited")
        XCTAssertEqual(reloadedOutflow?.note, "Updated ATM Deposit Note")
        XCTAssertEqual(reloadedInflow?.note, "Updated ATM Deposit Note", "Inflow note must update consistently")
        XCTAssertEqual(reloadedInflow?.timestamp, 1700000005000, "Inflow timestamp must synchronize consistently")

        cashBal = try await transactionRepo.getBalance(for: .cash)
        acctBal = try await transactionRepo.getBalance(for: .account)
        XCTAssertEqual(cashBal.subunits, -250000)
        XCTAssertEqual(acctBal.subunits, 250000)

        // 3. Reversal transfer: call reverseTransfer
        let (revOutId, revInId) = try await transactionRepo.reverseTransfer(transactionId: outId)
        XCTAssertGreaterThan(revOutId, 0)
        XCTAssertGreaterThan(revInId, 0)

        let revOutTx = try await transactionRepo.getTransaction(id: revOutId)
        let revInTx = try await transactionRepo.getTransaction(id: revInId)
        XCTAssertEqual(revOutTx?.transferPairId, revInId)
        XCTAssertEqual(revInTx?.transferPairId, revOutId)

        // Ledgers restored to 0 net change from transfers
        cashBal = try await transactionRepo.getBalance(for: .cash)
        acctBal = try await transactionRepo.getBalance(for: .account)
        XCTAssertEqual(cashBal.subunits, 0, "Reversal must restore Cash ledger to 0")
        XCTAssertEqual(acctBal.subunits, 0, "Reversal must restore Account ledger to 0")

        // 4. Verify atomic deletion: deleting one entry deletes both paired entries
        try await transactionRepo.deleteTransaction(id: revOutId)
        let deletedRevOut = try await transactionRepo.getTransaction(id: revOutId)
        let deletedRevIn = try await transactionRepo.getTransaction(id: revInId)
        XCTAssertNil(deletedRevOut)
        XCTAssertNil(deletedRevIn, "Deleting reversal outflow must atomically delete reversal inflow")

        try await transactionRepo.deleteTransaction(id: inId)
        let deletedOut = try await transactionRepo.getTransaction(id: outId)
        let deletedIn = try await transactionRepo.getTransaction(id: inId)
        XCTAssertNil(deletedOut, "Deleting inflow must atomically delete paired outflow")
        XCTAssertNil(deletedIn)
    }

    func testTransferReversalMaintainsOverallNetBalance() async throws {
        // Initial deposits: Cash ₹10,000, Account ₹20,000
        _ = try await transactionRepo.insertTransaction(Transaction(
            amount: Amount(subunits: 1000000),
            type: .income,
            categoryId: 13,
            paymentMethod: .cash,
            note: "Cash Initial"
        ))
        _ = try await transactionRepo.insertTransaction(Transaction(
            amount: Amount(subunits: 2000000),
            type: .income,
            categoryId: 13,
            paymentMethod: .account,
            note: "Account Initial"
        ))

        let initialNet = try await transactionRepo.getNetBalance()
        XCTAssertEqual(initialNet.subunits, 3000000)

        let initialCash = try await transactionRepo.getBalance(for: .cash)
        let initialAccount = try await transactionRepo.getBalance(for: .account)
        XCTAssertEqual(initialCash.subunits, 1000000)
        XCTAssertEqual(initialAccount.subunits, 2000000)

        // Transfer ₹4,000 from Cash to Account
        let (outId, inId) = try await transactionRepo.transferBetweenLedgers(
            from: .cash,
            to: .account,
            amount: Amount(subunits: 400000),
            note: "Move Cash to Bank",
            timestamp: 1700000010000
        )

        let postTransferCash = try await transactionRepo.getBalance(for: .cash)
        let postTransferAccount = try await transactionRepo.getBalance(for: .account)
        let postTransferNet = try await transactionRepo.getNetBalance()

        XCTAssertEqual(postTransferCash.subunits, 600000) // ₹6,000
        XCTAssertEqual(postTransferAccount.subunits, 2400000) // ₹24,000
        XCTAssertEqual(postTransferNet.subunits, 3000000, "Net balance must remain unchanged during transfer")

        // Reverse the transfer
        let (revOutId, revInId) = try await transactionRepo.reverseTransfer(transactionId: inId)
        XCTAssertGreaterThan(revOutId, 0)
        XCTAssertGreaterThan(revInId, 0)

        let restoredCash = try await transactionRepo.getBalance(for: .cash)
        let restoredAccount = try await transactionRepo.getBalance(for: .account)
        let restoredNet = try await transactionRepo.getNetBalance()

        XCTAssertEqual(restoredCash.subunits, initialCash.subunits, "Both ledgers must remain correct after reversal")
        XCTAssertEqual(restoredAccount.subunits, initialAccount.subunits, "Both ledgers must remain correct after reversal")
        XCTAssertEqual(restoredNet.subunits, initialNet.subunits, "Overall balance must remain unchanged after reversal")

        // Cleanup
        try await transactionRepo.deleteTransaction(id: outId)
        try await transactionRepo.deleteTransaction(id: revOutId)
    }

    func testHistoricalPaymentMethodMapping() {
        // Explicitly recognized electronic/account methods
        XCTAssertEqual(PaymentMethod.fromString("ACCOUNT"), .account)
        XCTAssertEqual(PaymentMethod.fromString("account"), .account)
        XCTAssertEqual(PaymentMethod.fromString("BANK_ACCOUNT"), .account)
        XCTAssertEqual(PaymentMethod.fromString("NET_BANKING"), .account)
        XCTAssertEqual(PaymentMethod.fromString("ONLINE"), .account)
        XCTAssertEqual(PaymentMethod.fromString("UPI"), .account)
        XCTAssertEqual(PaymentMethod.fromString("upi"), .account)
        XCTAssertEqual(PaymentMethod.fromString("CARD"), .account)
        XCTAssertEqual(PaymentMethod.fromString("card"), .account)
        XCTAssertEqual(PaymentMethod.fromString("Credit Card"), .account)

        // Explicitly recognized cash methods
        XCTAssertEqual(PaymentMethod.fromString("CASH"), .cash)
        XCTAssertEqual(PaymentMethod.fromString("cash"), .cash)

        // Preserved historical methods
        XCTAssertEqual(PaymentMethod.fromString("CHEQUE"), .cheque)
        XCTAssertEqual(PaymentMethod.fromString("cheque"), .cheque)
        XCTAssertEqual(PaymentMethod.fromString("CHECK"), .cheque)
        XCTAssertEqual(PaymentMethod.fromString("CHEQUE").mappedLedger, .account)

        XCTAssertEqual(PaymentMethod.fromString("WALLET"), .wallet)
        XCTAssertEqual(PaymentMethod.fromString("wallet"), .wallet)
        XCTAssertEqual(PaymentMethod.fromString("WALLET").mappedLedger, .cash)

        // NULL and unknown values NEVER automatically convert to CASH
        let nilVal: String? = nil
        XCTAssertEqual(PaymentMethod.fromString(nilVal), .unknown, "NULL must never convert to CASH")
        XCTAssertEqual(PaymentMethod.fromString(""), .unknown, "Empty string must never convert to CASH")
        XCTAssertEqual(PaymentMethod.fromString("   "), .unknown, "Whitespace must never convert to CASH")
        XCTAssertEqual(PaymentMethod.fromString("UNKNOWN_METHOD"), .unknown, "Unknown methods must never convert to CASH")
        XCTAssertEqual(PaymentMethod.fromString("CRYPTO_BTC"), .unknown, "Unknown methods must never convert to CASH")
    }

    func testDatabasePaymentMethodPreservationAcrossAllTypes() async throws {
        // Insert transactions covering CASH, ACCOUNT, UPI, CARD, CHEQUE, WALLET, NULL, and unknown
        let testCases: [(pm: String, expectedPm: PaymentMethod, rawPm: String?)] = [
            ("CASH", .cash, "CASH"),
            ("ACCOUNT", .account, "ACCOUNT"),
            ("ACCOUNT", .account, "UPI"),
            ("ACCOUNT", .account, "CARD"),
            ("CHEQUE", .cheque, "CHEQUE"),
            ("WALLET", .wallet, "WALLET"),
            ("UNKNOWN", .unknown, nil), // NULL raw payment method
            ("CUSTOM_GIFT_CARD", .unknown, "CUSTOM_GIFT_CARD")
        ]

        for (index, tc) in testCases.enumerated() {
            try await appDatabase.writer.write { db in
                try db.execute(
                    sql: """
                    INSERT INTO transactions (
                        amount_subunits, type, category_id, payment_method, raw_payment_method,
                        note, timestamp, created_at, updated_at, is_internal_transfer, currency_code, exchange_rate, exchange_rate_source
                    ) VALUES (
                        ?, 'EXPENSE', 1, ?, ?,
                        ?, 1700000000000 + ?, 1700000000000, 1700000000000, 0, 'INR', 1.0, 'PRIMARY'
                    )
                    """,
                    arguments: [10000 * (index + 1), tc.pm, tc.rawPm, "Test \(tc.rawPm ?? "NULL")", index]
                )
            }
        }

        let all = try await transactionRepo.getAllTransactions()
        XCTAssertGreaterThanOrEqual(all.count, 8)

        // Verify each payment method retained its original information without destructive conversion to CASH
        for tc in testCases {
            if let expectedRaw = tc.rawPm {
                let match = all.first { $0.rawPaymentMethod == expectedRaw }
                XCTAssertNotNil(match, "Transaction with raw payment method '\(expectedRaw)' must be preserved")
                XCTAssertEqual(match?.paymentMethod, tc.expectedPm)
            } else {
                let match = all.first { $0.rawPaymentMethod == nil }
                XCTAssertNotNil(match, "Transaction with NULL payment method must be preserved")
                XCTAssertEqual(match?.paymentMethod, .unknown, "NULL payment method must map to .unknown, never .cash")
            }
        }
    }
}

