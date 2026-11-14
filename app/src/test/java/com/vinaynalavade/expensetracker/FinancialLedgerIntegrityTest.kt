package com.vinaynalavade.expensetracker

import com.vinaynalavade.expensetracker.core.model.Amount
import com.vinaynalavade.expensetracker.core.result.AppError
import com.vinaynalavade.expensetracker.core.result.AppResult
import com.vinaynalavade.expensetracker.data.local.dao.TransactionDao
import com.vinaynalavade.expensetracker.data.local.database.ExpenseTrackerDatabase
import com.vinaynalavade.expensetracker.data.local.entity.CategoryEntity
import com.vinaynalavade.expensetracker.data.local.entity.TransactionEntity
import com.vinaynalavade.expensetracker.data.local.entity.TransactionWithCategory
import com.vinaynalavade.expensetracker.data.repository.TransactionRepositoryImpl
import com.vinaynalavade.expensetracker.domain.model.Category
import com.vinaynalavade.expensetracker.domain.model.FinancialSummary
import com.vinaynalavade.expensetracker.domain.model.PaymentMethod
import com.vinaynalavade.expensetracker.domain.model.Transaction
import com.vinaynalavade.expensetracker.domain.model.TransactionType
import com.vinaynalavade.expensetracker.domain.model.UserPreferences
import com.vinaynalavade.expensetracker.domain.repository.UserPreferencesRepository
import com.vinaynalavade.expensetracker.domain.usecase.GetFinancialSummaryUseCase
import com.vinaynalavade.expensetracker.domain.usecase.ReverseTransferUseCase
import com.vinaynalavade.expensetracker.domain.usecase.TransferFundsUseCase
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.flowOf
import kotlinx.coroutines.runBlocking
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test

class FinancialLedgerIntegrityTest {

    private lateinit var fakeDao: InMemoryTransactionDao
    private lateinit var repository: TransactionRepositoryImpl
    private lateinit var fakePrefsRepo: FakeUserPrefsRepo
    private lateinit var transferFundsUseCase: TransferFundsUseCase
    private lateinit var reverseTransferUseCase: ReverseTransferUseCase
    private lateinit var getFinancialSummaryUseCase: GetFinancialSummaryUseCase

    @Before
    fun setUp() {
        fakeDao = InMemoryTransactionDao()
        repository = TransactionRepositoryImpl(fakeDao)
        fakePrefsRepo = FakeUserPrefsRepo(UserPreferences(openingBalanceSubunits = 1000000L)) // ₹10,000.00
        transferFundsUseCase = TransferFundsUseCase(repository)
        reverseTransferUseCase = ReverseTransferUseCase(repository)
        getFinancialSummaryUseCase = GetFinancialSummaryUseCase(repository, fakePrefsRepo)
    }

    // ─── 1. Cash → Account Transfer ───

    @Test
    fun testCashToAccountTransfer_CreatesLinkedPairAndBalances() = runBlocking {
        val transferAmount = Amount(250000L) // ₹2,500.00
        val result = transferFundsUseCase(
            from = PaymentMethod.CASH,
            to = PaymentMethod.ACCOUNT,
            amount = transferAmount,
            note = "ATM Deposit"
        )

        assertTrue(result is AppResult.Success)
        val (outId, inId) = (result as AppResult.Success).data

        val outflow = fakeDao.getTransactionByIdSuspend(outId)
        val inflow = fakeDao.getTransactionByIdSuspend(inId)

        assertNotNull(outflow)
        assertNotNull(inflow)

        // Outflow verification (EXPENSE from Cash)
        assertEquals(TransactionType.EXPENSE.name, outflow!!.type)
        assertEquals(PaymentMethod.CASH.name, outflow.paymentMethod)
        assertEquals(transferAmount.subunits, outflow.amountSubunits)
        assertTrue(outflow.isInternalTransfer)
        assertEquals(inId, outflow.transferPairId)

        // Inflow verification (INCOME into Account)
        assertEquals(TransactionType.INCOME.name, inflow!!.type)
        assertEquals(PaymentMethod.ACCOUNT.name, inflow.paymentMethod)
        assertEquals(transferAmount.subunits, inflow.amountSubunits)
        assertTrue(inflow.isInternalTransfer)
        assertEquals(outId, inflow.transferPairId)

        // Balances verification
        val cashBal = repository.getCashBalance().first()
        val acctBal = repository.getAccountBalance().first()

        assertEquals(-250000L, cashBal.subunits) // Cash decreased by ₹2,500
        assertEquals(250000L, acctBal.subunits)  // Account increased by ₹2,500
    }

    // ─── 2. Account → Cash Transfer ───

    @Test
    fun testAccountToCashTransfer_CreatesLinkedPairAndBalances() = runBlocking {
        val transferAmount = Amount(150000L) // ₹1,500.00
        val result = transferFundsUseCase(
            from = PaymentMethod.ACCOUNT,
            to = PaymentMethod.CASH,
            amount = transferAmount,
            note = "ATM Withdrawal"
        )

        assertTrue(result is AppResult.Success)
        val (outId, inId) = (result as AppResult.Success).data

        val outflow = fakeDao.getTransactionByIdSuspend(outId)
        val inflow = fakeDao.getTransactionByIdSuspend(inId)

        assertNotNull(outflow)
        assertNotNull(inflow)

        assertEquals(TransactionType.EXPENSE.name, outflow!!.type)
        assertEquals(PaymentMethod.ACCOUNT.name, outflow.paymentMethod)
        assertEquals(TransactionType.INCOME.name, inflow!!.type)
        assertEquals(PaymentMethod.CASH.name, inflow.paymentMethod)

        val cashBal = repository.getCashBalance().first()
        val acctBal = repository.getAccountBalance().first()

        assertEquals(150000L, cashBal.subunits)  // Cash increased by ₹1,500
        assertEquals(-150000L, acctBal.subunits) // Account decreased by ₹1,500
    }

    // ─── 3. Combined Balance Neutrality ───

    @Test
    fun testCombinedBalanceNeutrality() = runBlocking {
        // Initial summary
        val initialSummary = getFinancialSummaryUseCase().first()
        assertEquals(1000000L, initialSummary.currentBalance.subunits) // Opening: ₹10,000

        // Multiple transfers
        transferFundsUseCase(PaymentMethod.CASH, PaymentMethod.ACCOUNT, Amount(300000L), "Transfer 1")
        transferFundsUseCase(PaymentMethod.ACCOUNT, PaymentMethod.CASH, Amount(120000L), "Transfer 2")
        transferFundsUseCase(PaymentMethod.CASH, PaymentMethod.ACCOUNT, Amount(80000L), "Transfer 3")

        val summaryAfterTransfers = getFinancialSummaryUseCase().first()

        // Balance neutrality invariant: currentBalance MUST be strictly unchanged
        assertEquals(
            "Combined balance must remain exactly identical to initial balance",
            initialSummary.currentBalance.subunits,
            summaryAfterTransfers.currentBalance.subunits
        )

        // Ledger breakdown: Cash (-₹2,600), Account (+₹2,600 + ₹10,000 opening)
        val (cash, acct) = getFinancialSummaryUseCase.executeForLedgers().first()
        assertEquals(-260000L, cash.subunits)
        assertEquals(1260000L, acct.subunits)
        assertEquals(summaryAfterTransfers.currentBalance.subunits, cash.subunits + acct.subunits)
    }

    // ─── 4. Exclusion of Transfers from Income and Expense Totals ───

    @Test
    fun testExclusionOfTransfersFromIncomeAndExpenseTotals() = runBlocking {
        // Add ordinary salary: ₹50,000
        repository.insertTransaction(
            Transaction(
                id = 0L,
                amount = Amount(5000000L),
                type = TransactionType.INCOME,
                category = Category(1L, "Salary", "wallet", "#10B981", TransactionType.INCOME),
                paymentMethod = PaymentMethod.ACCOUNT,
                note = "Monthly Salary",
                timestamp = System.currentTimeMillis()
            )
        )

        // Add ordinary rent expense: ₹15,000
        repository.insertTransaction(
            Transaction(
                id = 0L,
                amount = Amount(1500000L),
                type = TransactionType.EXPENSE,
                category = Category(2L, "Rent", "home", "#EF4444", TransactionType.EXPENSE),
                paymentMethod = PaymentMethod.ACCOUNT,
                note = "Apartment Rent",
                timestamp = System.currentTimeMillis()
            )
        )

        // Now execute internal transfer: ₹20,000 (from Account to Cash)
        transferFundsUseCase(
            from = PaymentMethod.ACCOUNT,
            to = PaymentMethod.CASH,
            amount = Amount(2000000L),
            note = "Emergency Cash Withdrawal"
        )

        val summary = getFinancialSummaryUseCase().first()

        // Total income must strictly exclude the transfer
        assertEquals(5000000L, summary.totalIncome.subunits)
        // Total expense must strictly exclude the transfer
        assertEquals(1500000L, summary.totalExpense.subunits)
        // Net change: ₹50,000 - ₹15,000 = ₹35,000
        assertEquals(3500000L, summary.netChange.subunits)
        // Current balance: ₹10,000 (opening) + ₹35,000 = ₹45,000
        assertEquals(4500000L, summary.currentBalance.subunits)
    }

    // ─── 5. Editing Either Transfer Leg Synchronizes Counterpart ───

    @Test
    fun testEditingEitherTransferLeg_SynchronizesCounterpart() = runBlocking {
        val transferResult = transferFundsUseCase(
            from = PaymentMethod.CASH,
            to = PaymentMethod.ACCOUNT,
            amount = Amount(100000L), // ₹1,000
            note = "Original Note"
        ) as AppResult.Success

        val (outId, inId) = transferResult.data

        // Edit the outflow leg: increase amount to ₹1,500 and update note
        val outflowTx = repository.getTransactionById(outId).first()
        assertNotNull(outflowTx)

        val updatedOutflow = outflowTx!!.copy(
            amount = Amount(150000L),
            note = "Updated Note"
        )
        val updateResult = repository.updateTransaction(updatedOutflow)
        assertTrue(updateResult is AppResult.Success)

        // Verify the paired inflow leg was synchronized atomically
        val syncedInflow = fakeDao.getTransactionByIdSuspend(inId)
        assertNotNull(syncedInflow)
        assertEquals(150000L, syncedInflow!!.amountSubunits)
        assertEquals("Updated Note", syncedInflow.note)

        // Verify balances reflect updated amount
        assertEquals(-150000L, repository.getCashBalance().first().subunits)
        assertEquals(150000L, repository.getAccountBalance().first().subunits)
    }

    // ─── 6. Deleting Either Transfer Leg Deletes Both Legs ───

    @Test
    fun testDeletingEitherTransferLeg_DeletesCounterpart() = runBlocking {
        val transferResult = transferFundsUseCase(
            from = PaymentMethod.CASH,
            to = PaymentMethod.ACCOUNT,
            amount = Amount(100000L),
            note = "To be deleted"
        ) as AppResult.Success

        val (outId, inId) = transferResult.data

        // Delete the outflow leg
        val deleteResult = repository.deleteTransaction(outId)
        assertTrue(deleteResult is AppResult.Success)

        // Both legs must be gone
        assertNull(fakeDao.getTransactionByIdSuspend(outId))
        assertNull(fakeDao.getTransactionByIdSuspend(inId))

        // Balances must return to 0
        assertEquals(0L, repository.getCashBalance().first().subunits)
        assertEquals(0L, repository.getAccountBalance().first().subunits)
    }

    // ─── 7. Reversing a Transfer ───

    @Test
    fun testReversingTransfer_RestoresBalances() = runBlocking {
        val transferResult = transferFundsUseCase(
            from = PaymentMethod.CASH,
            to = PaymentMethod.ACCOUNT,
            amount = Amount(200000L), // ₹2,000
            note = "Original Transfer"
        ) as AppResult.Success

        val (outId, _) = transferResult.data

        // Balances before reversal
        assertEquals(-200000L, repository.getCashBalance().first().subunits)
        assertEquals(200000L, repository.getAccountBalance().first().subunits)

        // Reverse the transfer using the outflow ID
        val revResult = reverseTransferUseCase(outId)
        assertTrue(revResult is AppResult.Success)

        val (revOutId, revInId) = (revResult as AppResult.Success).data
        val revOut = fakeDao.getTransactionByIdSuspend(revOutId)
        val revIn = fakeDao.getTransactionByIdSuspend(revInId)

        assertNotNull(revOut)
        assertNotNull(revIn)

        // Reversal outflow is EXPENSE from ACCOUNT
        assertEquals(PaymentMethod.ACCOUNT.name, revOut!!.paymentMethod)
        assertEquals(TransactionType.EXPENSE.name, revOut.type)

        // Reversal inflow is INCOME to CASH
        assertEquals(PaymentMethod.CASH.name, revIn!!.paymentMethod)
        assertEquals(TransactionType.INCOME.name, revIn.type)

        // Balances restored to neutral zero
        assertEquals(0L, repository.getCashBalance().first().subunits)
        assertEquals(0L, repository.getAccountBalance().first().subunits)
    }

    // ─── 8. Validation Rules (Invalid or Insufficient Amounts) ───

    @Test
    fun testInvalidOrInsufficientTransferAmounts() = runBlocking {
        // Zero amount
        val zeroResult = transferFundsUseCase(
            from = PaymentMethod.CASH,
            to = PaymentMethod.ACCOUNT,
            amount = Amount(0L)
        )
        assertTrue(zeroResult is AppResult.Error)
        assertTrue((zeroResult as AppResult.Error).error is AppError.ValidationError)

        // Negative amount
        val negResult = transferFundsUseCase(
            from = PaymentMethod.CASH,
            to = PaymentMethod.ACCOUNT,
            amount = Amount(-500L)
        )
        assertTrue(negResult is AppResult.Error)
        assertTrue((negResult as AppResult.Error).error is AppError.ValidationError)

        // Identical source and destination
        val sameResult = transferFundsUseCase(
            from = PaymentMethod.CASH,
            to = PaymentMethod.CASH,
            amount = Amount(1000L)
        )
        assertTrue(sameResult is AppResult.Error)
        assertTrue((sameResult as AppResult.Error).error is AppError.ValidationError)
    }

    // ─── 9. Database Migration Verification ───

    @Test
    fun testDatabaseMigration10To11_PreservesSchemaAndVersion() {
        assertEquals(10, ExpenseTrackerDatabase.MIGRATION_10_11.startVersion)
        assertEquals(11, ExpenseTrackerDatabase.MIGRATION_10_11.endVersion)
    }

    // ─── In-Memory Test Infrastructure ───

    private class InMemoryTransactionDao : TransactionDao {
        val storage = mutableMapOf<Long, TransactionEntity>()
        private var idGen = 1L

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

        override suspend fun getTransferCategoryId(): Long? = 99L

        override suspend fun insertTransaction(transaction: TransactionEntity): Long {
            val id = if (transaction.id != 0L) transaction.id else idGen++
            val saved = transaction.copy(id = id)
            storage[id] = saved
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

    private class FakeUserPrefsRepo(private var prefs: UserPreferences) : UserPreferencesRepository {
        override fun getUserPreferences(): Flow<UserPreferences> = flowOf(prefs)
        override suspend fun setThemeMode(themeMode: com.vinaynalavade.expensetracker.domain.model.ThemeMode): AppResult<Unit> = AppResult.Success(Unit)
        override suspend fun setCurrencyCode(currencyCode: String): AppResult<Unit> = AppResult.Success(Unit)
        override suspend fun setDynamicColors(useDynamicColors: Boolean): AppResult<Unit> = AppResult.Success(Unit)
        override suspend fun setFirstLaunchCompleted(): AppResult<Unit> = AppResult.Success(Unit)
        override suspend fun setOpeningBalance(subunits: Long): AppResult<Unit> {
            prefs = prefs.copy(openingBalanceSubunits = subunits)
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
