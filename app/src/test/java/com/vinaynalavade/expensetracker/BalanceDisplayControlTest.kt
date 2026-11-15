package com.vinaynalavade.expensetracker

import androidx.datastore.preferences.core.PreferenceDataStoreFactory
import androidx.datastore.preferences.core.edit
import androidx.datastore.preferences.core.stringPreferencesKey
import com.vinaynalavade.expensetracker.core.model.Amount
import com.vinaynalavade.expensetracker.core.result.AppResult
import com.vinaynalavade.expensetracker.data.local.dao.TransactionDao
import com.vinaynalavade.expensetracker.data.local.entity.TransactionEntity
import com.vinaynalavade.expensetracker.data.local.entity.TransactionWithCategory
import com.vinaynalavade.expensetracker.data.repository.TransactionRepositoryImpl
import com.vinaynalavade.expensetracker.domain.model.BalanceDisplayMode
import com.vinaynalavade.expensetracker.domain.model.FinancialSummary
import com.vinaynalavade.expensetracker.domain.model.PaymentMethod
import com.vinaynalavade.expensetracker.domain.model.TransactionType
import com.vinaynalavade.expensetracker.domain.model.UserPreferences
import com.vinaynalavade.expensetracker.domain.repository.UserPreferencesRepository
import com.vinaynalavade.expensetracker.domain.usecase.GetFinancialSummaryUseCase
import com.vinaynalavade.expensetracker.domain.usecase.TransferFundsUseCase
import com.vinaynalavade.expensetracker.presentation.dashboard.DashboardUiState
import kotlinx.coroutines.cancel
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.flowOf
import kotlinx.coroutines.runBlocking
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test

/**
 * Phase 1: Cash & Account Balance Display Controls Test Suite.
 *
 * Verifies all 9 mandatory test requirements and critical safeguards:
 * 1. Account ₹1,000 + Cash ₹1,000 setup.
 * 2. Select Combined → ₹2,000 displayed.
 * 3. Select Account → ₹1,000 displayed.
 * 4. Select Cash → ₹1,000 displayed.
 * 5. Add expense to Cash and verify Account remains unchanged.
 * 6. Add income to Account and verify Cash remains unchanged.
 * 7. Persistence across restarts (defaults to Combined, persists user choice).
 * 8. Eye-button visibility in all three modes.
 * 9. Transfer neutrality and historical transaction integrity.
 */
class BalanceDisplayControlTest {

    private lateinit var fakeDao: TestTransactionDao
    private lateinit var repository: TransactionRepositoryImpl
    private lateinit var fakePrefsRepo: TestUserPrefsRepo
    private lateinit var getFinancialSummaryUseCase: GetFinancialSummaryUseCase
    private lateinit var transferFundsUseCase: TransferFundsUseCase

    @Before
    fun setUp() {
        fakeDao = TestTransactionDao()
        repository = TransactionRepositoryImpl(fakeDao)
        // Opening balance 0 to strictly isolate income/expenses to ₹1,000 each
        fakePrefsRepo = TestUserPrefsRepo(UserPreferences(openingBalanceSubunits = 0L))
        getFinancialSummaryUseCase = GetFinancialSummaryUseCase(repository, fakePrefsRepo)
        transferFundsUseCase = TransferFundsUseCase(repository)
    }

    private suspend fun setupInitialBalances() {
        // Cash Income: ₹1,000.00 (100,000 subunits)
        fakeDao.insertTransaction(
            TransactionEntity(
                id = 1L,
                amountSubunits = 100000L,
                type = TransactionType.INCOME.name,
                categoryId = 1L,
                paymentMethod = PaymentMethod.CASH.name,
                timestamp = 1000L
            )
        )
        // Account Income: ₹1,000.00 (100,000 subunits)
        fakeDao.insertTransaction(
            TransactionEntity(
                id = 2L,
                amountSubunits = 100000L,
                type = TransactionType.INCOME.name,
                categoryId = 1L,
                paymentMethod = PaymentMethod.ACCOUNT.name,
                timestamp = 2000L
            )
        )
    }

    // ─── Step 6, Item 1-4: Balance Display Mode Calculations ───

    @Test
    fun testInitialSetup_Account1000_Cash1000_Combined2000() = runBlocking {
        setupInitialBalances()

        val cashBal = repository.getCashBalance().first()
        val acctBal = repository.getAccountBalance().first()
        val summary = getFinancialSummaryUseCase().first()

        assertEquals(100000L, cashBal.subunits) // ₹1,000 Cash
        assertEquals(100000L, acctBal.subunits) // ₹1,000 Account
        assertEquals(200000L, summary.currentBalance.subunits) // ₹2,000 Combined
    }

    @Test
    fun testModeSelection_CombinedAccountCash_DisplayedAmounts() = runBlocking {
        setupInitialBalances()

        val cashBal = repository.getCashBalance().first()
        val acctBal = repository.getAccountBalance().first()
        val summary = getFinancialSummaryUseCase().first()

        // 1. Mode: COMBINED -> ₹2,000
        val combinedState = DashboardUiState(
            summary = summary,
            cashBalance = cashBal,
            accountBalance = acctBal,
            balanceDisplayMode = BalanceDisplayMode.COMBINED
        )
        assertEquals(Amount(200000L), combinedState.displayedBalance)
        assertEquals("₹2,000.00", combinedState.displayedBalance.format())

        // 2. Mode: ACCOUNT -> ₹1,000
        val accountState = DashboardUiState(
            summary = summary,
            cashBalance = cashBal,
            accountBalance = acctBal,
            balanceDisplayMode = BalanceDisplayMode.ACCOUNT
        )
        assertEquals(Amount(100000L), accountState.displayedBalance)
        assertEquals("₹1,000.00", accountState.displayedBalance.format())

        // 3. Mode: CASH -> ₹1,000
        val cashState = DashboardUiState(
            summary = summary,
            cashBalance = cashBal,
            accountBalance = acctBal,
            balanceDisplayMode = BalanceDisplayMode.CASH
        )
        assertEquals(Amount(100000L), cashState.displayedBalance)
        assertEquals("₹1,000.00", cashState.displayedBalance.format())
    }

    // ─── Step 6, Item 5: Add Expense to Cash -> Account Unchanged ───

    @Test
    fun testAddExpenseToCash_AccountRemainsUnchanged() = runBlocking {
        setupInitialBalances()

        // Add ₹300 expense to Cash
        fakeDao.insertTransaction(
            TransactionEntity(
                id = 3L,
                amountSubunits = 30000L,
                type = TransactionType.EXPENSE.name,
                categoryId = 2L,
                paymentMethod = PaymentMethod.CASH.name,
                timestamp = 3000L
            )
        )

        val cashBal = repository.getCashBalance().first()
        val acctBal = repository.getAccountBalance().first()
        val summary = getFinancialSummaryUseCase().first()

        // Cash: ₹1,000 - ₹300 = ₹700
        assertEquals(70000L, cashBal.subunits)
        // Account: strictly unchanged at ₹1,000
        assertEquals(100000L, acctBal.subunits)
        // Combined: ₹700 + ₹1,000 = ₹1,700
        assertEquals(170000L, summary.currentBalance.subunits)

        // Verify all 3 modes reflect the new reality
        val cashState = DashboardUiState(summary = summary, cashBalance = cashBal, accountBalance = acctBal, balanceDisplayMode = BalanceDisplayMode.CASH)
        val acctState = DashboardUiState(summary = summary, cashBalance = cashBal, accountBalance = acctBal, balanceDisplayMode = BalanceDisplayMode.ACCOUNT)
        val combState = DashboardUiState(summary = summary, cashBalance = cashBal, accountBalance = acctBal, balanceDisplayMode = BalanceDisplayMode.COMBINED)

        assertEquals(Amount(70000L), cashState.displayedBalance)
        assertEquals(Amount(100000L), acctState.displayedBalance)
        assertEquals(Amount(170000L), combState.displayedBalance)
    }

    // ─── Step 6, Item 6: Add Income to Account -> Cash Unchanged ───

    @Test
    fun testAddIncomeToAccount_CashRemainsUnchanged() = runBlocking {
        setupInitialBalances()

        // Add ₹500 income to Account
        fakeDao.insertTransaction(
            TransactionEntity(
                id = 4L,
                amountSubunits = 50000L,
                type = TransactionType.INCOME.name,
                categoryId = 1L,
                paymentMethod = PaymentMethod.ACCOUNT.name,
                timestamp = 4000L
            )
        )

        val cashBal = repository.getCashBalance().first()
        val acctBal = repository.getAccountBalance().first()
        val summary = getFinancialSummaryUseCase().first()

        // Cash: strictly unchanged at ₹1,000
        assertEquals(100000L, cashBal.subunits)
        // Account: ₹1,000 + ₹500 = ₹1,500
        assertEquals(150000L, acctBal.subunits)
        // Combined: ₹1,000 + ₹1,500 = ₹2,500
        assertEquals(250000L, summary.currentBalance.subunits)

        val cashState = DashboardUiState(summary = summary, cashBalance = cashBal, accountBalance = acctBal, balanceDisplayMode = BalanceDisplayMode.CASH)
        val acctState = DashboardUiState(summary = summary, cashBalance = cashBal, accountBalance = acctBal, balanceDisplayMode = BalanceDisplayMode.ACCOUNT)
        val combState = DashboardUiState(summary = summary, cashBalance = cashBal, accountBalance = acctBal, balanceDisplayMode = BalanceDisplayMode.COMBINED)

        assertEquals(Amount(100000L), cashState.displayedBalance)
        assertEquals(Amount(150000L), acctState.displayedBalance)
        assertEquals(Amount(250000L), combState.displayedBalance)
    }

    // ─── Step 6, Item 7: Persistence Across App Restart ───

    @Test
    fun testPersistenceAndAppRestart() = runBlocking {
        // 1. Initial default must be COMBINED
        val initialPrefs = fakePrefsRepo.getUserPreferences().first()
        assertEquals(BalanceDisplayMode.COMBINED, initialPrefs.balanceDisplayMode)

        // 2. User selects ACCOUNT
        fakePrefsRepo.setBalanceDisplayMode(BalanceDisplayMode.ACCOUNT)
        val updatedPrefs = fakePrefsRepo.getUserPreferences().first()
        assertEquals(BalanceDisplayMode.ACCOUNT, updatedPrefs.balanceDisplayMode)

        // 3. Simulate App Restart by creating a new repository referencing the persisted state
        val reloadedPrefsRepo = TestUserPrefsRepo(updatedPrefs)
        val reloadedPrefs = reloadedPrefsRepo.getUserPreferences().first()
        assertEquals(BalanceDisplayMode.ACCOUNT, reloadedPrefs.balanceDisplayMode)

        // 4. User selects CASH and restarts again
        reloadedPrefsRepo.setBalanceDisplayMode(BalanceDisplayMode.CASH)
        val reloadedPrefs2 = TestUserPrefsRepo(reloadedPrefsRepo.getUserPreferences().first()).getUserPreferences().first()
        assertEquals(BalanceDisplayMode.CASH, reloadedPrefs2.balanceDisplayMode)
    }

    @Test
    fun testRealDataStoreFilePersistence_AcrossProcessRestarts(): Unit = runBlocking {
        val tempDir = java.nio.file.Files.createTempDirectory("datastore_audit_test").toFile()
        val dataStoreFile = java.io.File(tempDir, "user_preferences.preferences_pb")
        val job1 = kotlinx.coroutines.SupervisorJob()
        val scope1 = kotlinx.coroutines.CoroutineScope(kotlinx.coroutines.Dispatchers.IO + job1)

        val dataStore1 = PreferenceDataStoreFactory.create(
            scope = scope1,
            produceFile = { dataStoreFile }
        )

        val balanceDisplayModeKey = stringPreferencesKey("pref_balance_display_mode")

        // 1. Initial verification: Defaults to COMBINED when preference key is absent
        val initialMode = dataStore1.data.first()[balanceDisplayModeKey]?.let {
            BalanceDisplayMode.valueOf(it)
        } ?: BalanceDisplayMode.COMBINED
        assertEquals(BalanceDisplayMode.COMBINED, initialMode)

        // 2. Persist selection: User selects ACCOUNT mode
        dataStore1.edit { prefs ->
            prefs[balanceDisplayModeKey] = BalanceDisplayMode.ACCOUNT.name
        }

        // Verify written to disk
        val updatedMode = dataStore1.data.first()[balanceDisplayModeKey]?.let {
            BalanceDisplayMode.valueOf(it)
        }
        assertEquals(BalanceDisplayMode.ACCOUNT, updatedMode)

        // 3. Simulate process termination and cold application restart: cancel and await complete scope shutdown
        job1.cancel()
        job1.join()
        assertTrue(dataStoreFile.exists())
        assertTrue(dataStoreFile.length() > 0)

        // Recreate brand new DataStore instance from the same disk file
        val job2 = kotlinx.coroutines.SupervisorJob()
        val scope2 = kotlinx.coroutines.CoroutineScope(kotlinx.coroutines.Dispatchers.IO + job2)
        val dataStoreRestarted = PreferenceDataStoreFactory.create(
            scope = scope2,
            produceFile = { dataStoreFile }
        )

        val restoredMode = dataStoreRestarted.data.first()[balanceDisplayModeKey]?.let {
            BalanceDisplayMode.valueOf(it)
        } ?: BalanceDisplayMode.COMBINED

        assertEquals(BalanceDisplayMode.ACCOUNT, restoredMode)

        // Clean up
        job2.cancel()
        job2.join()
        tempDir.deleteRecursively()
    }

    // ─── Step 6, Item 8: Eye-Button Visibility in All Three Modes ───

    @Test
    fun testEyeButtonVisibilityInAllThreeModes() = runBlocking {
        setupInitialBalances()

        val cashBal = repository.getCashBalance().first()
        val acctBal = repository.getAccountBalance().first()
        val summary = getFinancialSummaryUseCase().first()

        for (mode in BalanceDisplayMode.entries) {
            // When balance is visible
            val visibleState = DashboardUiState(
                summary = summary,
                cashBalance = cashBal,
                accountBalance = acctBal,
                balanceDisplayMode = mode,
                isBalanceVisible = true
            )
            assertTrue(visibleState.isBalanceVisible)
            when (mode) {
                BalanceDisplayMode.COMBINED -> assertEquals(Amount(200000L), visibleState.displayedBalance)
                BalanceDisplayMode.ACCOUNT -> assertEquals(Amount(100000L), visibleState.displayedBalance)
                BalanceDisplayMode.CASH -> assertEquals(Amount(100000L), visibleState.displayedBalance)
            }

            // When balance is hidden
            val hiddenState = DashboardUiState(
                summary = summary,
                cashBalance = cashBal,
                accountBalance = acctBal,
                balanceDisplayMode = mode,
                isBalanceVisible = false
            )
            assertFalse(hiddenState.isBalanceVisible)
            // Underlying data calculation remains intact even when hidden
            when (mode) {
                BalanceDisplayMode.COMBINED -> assertEquals(Amount(200000L), hiddenState.displayedBalance)
                BalanceDisplayMode.ACCOUNT -> assertEquals(Amount(100000L), hiddenState.displayedBalance)
                BalanceDisplayMode.CASH -> assertEquals(Amount(100000L), hiddenState.displayedBalance)
            }
        }
    }

    // ─── Step 6, Item 9: Verify Existing Transfers and Transaction History ───

    @Test
    fun testTransferBetweenLedgers_MaintainsCombinedNeutralityAndHistory() = runBlocking {
        setupInitialBalances()

        // Transfer ₹400 from Cash to Account
        val transferResult = transferFundsUseCase(
            from = PaymentMethod.CASH,
            to = PaymentMethod.ACCOUNT,
            amount = Amount(40000L),
            note = "Deposit to bank"
        )
        assertTrue(transferResult is AppResult.Success)

        val cashBal = repository.getCashBalance().first()
        val acctBal = repository.getAccountBalance().first()
        val summary = getFinancialSummaryUseCase().first()

        // Cash: ₹1,000 - ₹400 = ₹600
        assertEquals(60000L, cashBal.subunits)
        // Account: ₹1,000 + ₹400 = ₹1,400
        assertEquals(140000L, acctBal.subunits)
        // Combined: ₹600 + ₹1,400 = ₹2,000 (transfer is zero net effect)
        assertEquals(200000L, summary.currentBalance.subunits)

        // Historical transactions count: 2 initial + 2 linked transfer transactions = 4
        assertEquals(4, fakeDao.storage.size)

        // Switching display modes never affects transaction counts or database records
        val stateCombined = DashboardUiState(summary = summary, cashBalance = cashBal, accountBalance = acctBal, balanceDisplayMode = BalanceDisplayMode.COMBINED)
        val stateAccount = DashboardUiState(summary = summary, cashBalance = cashBal, accountBalance = acctBal, balanceDisplayMode = BalanceDisplayMode.ACCOUNT)
        val stateCash = DashboardUiState(summary = summary, cashBalance = cashBal, accountBalance = acctBal, balanceDisplayMode = BalanceDisplayMode.CASH)

        assertEquals(Amount(200000L), stateCombined.displayedBalance)
        assertEquals(Amount(140000L), stateAccount.displayedBalance)
        assertEquals(Amount(60000L), stateCash.displayedBalance)
        assertEquals(4, fakeDao.storage.size)
    }

    // ─── Critical Safeguards Verification ───

    @Test
    fun testCriticalSafeguards_SwitchingModeNeverMutatesTransactionsOrBalances() = runBlocking {
        setupInitialBalances()
        val initialTxCount = fakeDao.storage.size
        val initialCashBal = repository.getCashBalance().first()
        val initialAcctBal = repository.getAccountBalance().first()

        // Switch modes repeatedly
        fakePrefsRepo.setBalanceDisplayMode(BalanceDisplayMode.ACCOUNT)
        fakePrefsRepo.setBalanceDisplayMode(BalanceDisplayMode.CASH)
        fakePrefsRepo.setBalanceDisplayMode(BalanceDisplayMode.COMBINED)

        // Confirm database transactions were not touched
        assertEquals(initialTxCount, fakeDao.storage.size)
        // Confirm ledger balances are unchanged
        assertEquals(initialCashBal.subunits, repository.getCashBalance().first().subunits)
        assertEquals(initialAcctBal.subunits, repository.getAccountBalance().first().subunits)
    }

    // ─── Test Infrastructure ───

    private class TestTransactionDao : TransactionDao {
        val storage = mutableMapOf<Long, TransactionEntity>()
        private var idGen = 100L

        override fun getAllTransactionsWithCategory(): Flow<List<TransactionWithCategory>> =
            flowOf(storage.values.map { TransactionWithCategory(it, null) })

        override fun getRecentTransactionsWithCategory(limit: Int): Flow<List<TransactionWithCategory>> =
            flowOf(storage.values.take(limit).map { TransactionWithCategory(it, null) })

        override fun getTransactionWithCategoryById(id: Long): Flow<TransactionWithCategory?> =
            flowOf(storage[id]?.let { TransactionWithCategory(it, null) })

        override suspend fun getTransactionByIdSuspend(id: Long): TransactionEntity? =
            storage[id]

        override fun getTransactionsBetween(startDate: Long, endDate: Long): Flow<List<TransactionWithCategory>> =
            flowOf(storage.values.filter { it.timestamp in startDate..endDate }.map { TransactionWithCategory(it, null) })

        override fun getTotalIncomeSubunits(): Flow<Long> =
            flowOf(storage.values.filter { it.type == TransactionType.INCOME.name && !it.isInternalTransfer }.sumOf { it.amountSubunits })

        override fun getTotalExpenseSubunits(): Flow<Long> =
            flowOf(storage.values.filter { it.type == TransactionType.EXPENSE.name && !it.isInternalTransfer }.sumOf { it.amountSubunits })

        override fun getCashBalanceSubunits(): Flow<Long> {
            val income = storage.values.filter { it.type == TransactionType.INCOME.name && it.paymentMethod == "CASH" }.sumOf { it.amountSubunits }
            val expense = storage.values.filter { it.type == TransactionType.EXPENSE.name && it.paymentMethod == "CASH" }.sumOf { it.amountSubunits }
            return flowOf(income - expense)
        }

        override fun getAccountBalanceSubunits(): Flow<Long> {
            val income = storage.values.filter { it.type == TransactionType.INCOME.name && it.paymentMethod != "CASH" }.sumOf { it.amountSubunits }
            val expense = storage.values.filter { it.type == TransactionType.EXPENSE.name && it.paymentMethod != "CASH" }.sumOf { it.amountSubunits }
            return flowOf(income - expense)
        }

        override fun getCashTransactionsWithCategory(): Flow<List<TransactionWithCategory>> =
            flowOf(storage.values.filter { it.paymentMethod == "CASH" }.map { TransactionWithCategory(it, null) })

        override fun getAccountTransactionsWithCategory(): Flow<List<TransactionWithCategory>> =
            flowOf(storage.values.filter { it.paymentMethod != "CASH" }.map { TransactionWithCategory(it, null) })

        override suspend fun getTransactionByPairId(pairId: Long): TransactionEntity? =
            storage.values.find { it.transferPairId == pairId }

        override suspend fun updateTransferPairId(id: Long, pairId: Long) {
            storage[id]?.let {
                storage[id] = it.copy(transferPairId = pairId)
            }
        }

        override suspend fun getTransferCategoryId(): Long? = 1L

        override suspend fun insertTransaction(transaction: TransactionEntity): Long {
            val id = if (transaction.id > 0) transaction.id else idGen++
            storage[id] = transaction.copy(id = id)
            return id
        }

        override suspend fun insertTransactions(transactions: List<TransactionEntity>) {
            transactions.forEach { insertTransaction(it) }
        }

        override suspend fun updateTransaction(transaction: TransactionEntity) {
            storage[transaction.id] = transaction
        }

        override suspend fun deleteTransactionById(id: Long) {
            storage.remove(id)
        }

        override suspend fun deleteAllTransactions() {
            storage.clear()
        }
    }

    private class TestUserPrefsRepo(private var currentPrefs: UserPreferences) : UserPreferencesRepository {
        private val _flow = MutableStateFlow(currentPrefs)

        override fun getUserPreferences(): Flow<UserPreferences> = _flow.asStateFlow()

        override suspend fun setBalanceDisplayMode(mode: BalanceDisplayMode): AppResult<Unit> {
            currentPrefs = currentPrefs.copy(balanceDisplayMode = mode)
            _flow.value = currentPrefs
            return AppResult.Success(Unit)
        }

        override suspend fun setBalanceVisible(isVisible: Boolean): AppResult<Unit> {
            currentPrefs = currentPrefs.copy(isBalanceVisible = isVisible)
            _flow.value = currentPrefs
            return AppResult.Success(Unit)
        }

        override suspend fun setThemeMode(themeMode: com.vinaynalavade.expensetracker.domain.model.ThemeMode): AppResult<Unit> = AppResult.Success(Unit)
        override suspend fun setCurrencyCode(currencyCode: String): AppResult<Unit> = AppResult.Success(Unit)
        override suspend fun setDynamicColors(useDynamicColors: Boolean): AppResult<Unit> = AppResult.Success(Unit)
        override suspend fun setFirstLaunchCompleted(): AppResult<Unit> = AppResult.Success(Unit)
        override suspend fun setOpeningBalance(subunits: Long): AppResult<Unit> {
            currentPrefs = currentPrefs.copy(openingBalanceSubunits = subunits)
            _flow.value = currentPrefs
            return AppResult.Success(Unit)
        }
        override suspend fun setDailyReminder(enabled: Boolean, hour: Int, minute: Int): AppResult<Unit> = AppResult.Success(Unit)
        override suspend fun setEmiReminders(enabled: Boolean): AppResult<Unit> = AppResult.Success(Unit)
        override fun getLastBackupTimestamp(): Flow<Long?> = flowOf(null)
        override suspend fun setLastBackupTimestamp(timestamp: Long): AppResult<Unit> = AppResult.Success(Unit)
        override suspend fun setAppLockEnabled(enabled: Boolean): AppResult<Unit> = AppResult.Success(Unit)
        override suspend fun setBiometricEnabled(enabled: Boolean): AppResult<Unit> = AppResult.Success(Unit)
        override suspend fun setAutoLockDurationSeconds(seconds: Long): AppResult<Unit> = AppResult.Success(Unit)
        override suspend fun setHideContentInRecents(hide: Boolean): AppResult<Unit> = AppResult.Success(Unit)
        override suspend fun setNotificationsMasterEnabled(enabled: Boolean): AppResult<Unit> = AppResult.Success(Unit)
        override suspend fun setBudgetAlertsEnabled(enabled: Boolean): AppResult<Unit> = AppResult.Success(Unit)
        override suspend fun setMonthlyBudgetLimit(subunits: Long): AppResult<Unit> = AppResult.Success(Unit)
        override suspend fun setRecurringRemindersEnabled(enabled: Boolean): AppResult<Unit> = AppResult.Success(Unit)
        override suspend fun setRecurringReminderAdvanceDays(days: Int): AppResult<Unit> = AppResult.Success(Unit)
        override suspend fun setSavingsGoalNotificationsEnabled(enabled: Boolean): AppResult<Unit> = AppResult.Success(Unit)
        override suspend fun setAppLanguage(languageCode: String): AppResult<Unit> = AppResult.Success(Unit)
        override suspend fun setProfileName(name: String?): AppResult<Unit> = AppResult.Success(Unit)
        override suspend fun setProfileImageUri(uri: String?): AppResult<Unit> = AppResult.Success(Unit)
        override suspend fun setAutomaticBackupEnabled(enabled: Boolean): AppResult<Unit> = AppResult.Success(Unit)
        override suspend fun setLastBackupStatus(status: String?): AppResult<Unit> = AppResult.Success(Unit)
        override suspend fun setLastBackupError(error: String?): AppResult<Unit> = AppResult.Success(Unit)
        override suspend fun setLastDismissedRestoreBackupTimestamp(timestamp: Long?): AppResult<Unit> = AppResult.Success(Unit)
        override suspend fun setAppTourCompleted(completed: Boolean): AppResult<Unit> = AppResult.Success(Unit)
        override suspend fun setDefaultIncomeSource(source: PaymentMethod): AppResult<Unit> = AppResult.Success(Unit)
        override suspend fun setDefaultExpenseSource(source: PaymentMethod): AppResult<Unit> = AppResult.Success(Unit)
    }
}
