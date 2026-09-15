package com.vinaynalavade.expensetracker

import com.vinaynalavade.expensetracker.core.constants.AppConstants
import com.vinaynalavade.expensetracker.core.model.Amount
import com.vinaynalavade.expensetracker.core.result.AppResult
import com.vinaynalavade.expensetracker.domain.model.Category
import com.vinaynalavade.expensetracker.domain.model.FinancialSummary
import com.vinaynalavade.expensetracker.domain.model.PaymentMethod
import com.vinaynalavade.expensetracker.domain.model.SavingsGoal
import com.vinaynalavade.expensetracker.domain.model.SavingsGoalContribution
import com.vinaynalavade.expensetracker.domain.model.SettlementStatus
import com.vinaynalavade.expensetracker.domain.model.SplitExpense
import com.vinaynalavade.expensetracker.domain.model.SplitParticipant
import com.vinaynalavade.expensetracker.domain.model.ThemeMode
import com.vinaynalavade.expensetracker.domain.model.Transaction
import com.vinaynalavade.expensetracker.domain.model.TransactionType
import com.vinaynalavade.expensetracker.domain.model.UserPreferences
import com.vinaynalavade.expensetracker.domain.repository.CategoryRepository
import com.vinaynalavade.expensetracker.domain.repository.SavingsGoalRepository
import com.vinaynalavade.expensetracker.domain.repository.TransactionRepository
import com.vinaynalavade.expensetracker.domain.repository.UserPreferencesRepository
import com.vinaynalavade.expensetracker.domain.usecase.DeleteSavingsGoalContributionUseCase
import com.vinaynalavade.expensetracker.domain.usecase.DeleteSavingsGoalUseCase
import com.vinaynalavade.expensetracker.domain.usecase.GenerateStatementUseCase
import com.vinaynalavade.expensetracker.domain.usecase.GetCategoriesUseCase
import com.vinaynalavade.expensetracker.domain.usecase.GetMonthlyLedgerUseCase
import com.vinaynalavade.expensetracker.domain.usecase.SaveSavingsGoalContributionUseCase
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.flowOf
import kotlinx.coroutines.runBlocking
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test
import java.time.YearMonth
import java.time.ZoneId

/**
 * Production validation test suite verifying all Leaf v1.0.9 release requirements.
 */
class ProductionReleaseValidationTest {

    // ==========================================
    // 1. BRANDING & PRIVACY ACROSS SURFACES
    // ==========================================
    @Test
    fun `validate exact branding phrase and absence of personal names in global branding`() {
        assertEquals("Crafted with 💚 in India", AppConstants.CREATOR_BRANDING)
        assertFalse(AppConstants.CREATOR_BRANDING.contains("Vinay", ignoreCase = true))
        assertFalse(AppConstants.CREATOR_BRANDING.contains("Nalavade", ignoreCase = true))
    }

    // ==========================================
    // 2. SAVINGS ALLOCATION CATEGORY ISOLATION
    // ==========================================
    @Test
    fun `validate Savings and Goals category isolation from manual expense selection`() = runBlocking {
        val foodCat = Category(id = 1L, name = "Food & Dining", iconName = "restaurant", colorHex = "#FF5722", type = TransactionType.EXPENSE, isDefault = true)
        val billsCat = Category(id = 2L, name = "Bills & Utilities", iconName = "receipt_long", colorHex = "#3B82F6", type = TransactionType.EXPENSE, isDefault = true)
        val savingsCat = Category(id = 3L, name = AppConstants.CATEGORY_SAVINGS_AND_GOALS, iconName = "savings", colorHex = "#10B981", type = TransactionType.EXPENSE, isDefault = false)

        val catRepo = FakeCategoryRepo(listOf(foodCat, billsCat, savingsCat))
        val getCategoriesUseCase = GetCategoriesUseCase(catRepo)

        // Default manual category list MUST exclude internal "Savings & Goals"
        val manualExpenseCategories = getCategoriesUseCase.getByType(TransactionType.EXPENSE, includeInternal = false).first()
        assertEquals(2, manualExpenseCategories.size)
        assertFalse(manualExpenseCategories.any { it.name.equals(AppConstants.CATEGORY_SAVINGS_AND_GOALS, ignoreCase = true) })

        // Internal category querying CAN access it when requested
        val internalCategories = getCategoriesUseCase.getByType(TransactionType.EXPENSE, includeInternal = true).first()
        assertEquals(3, internalCategories.size)
        assertTrue(internalCategories.any { it.name.equals(AppConstants.CATEGORY_SAVINGS_AND_GOALS, ignoreCase = true) })
    }

    // ==========================================
    // 3. SAVINGS CONTRIBUTION FLOWS (DEDUCT YES / NO, SAFE DELETION)
    // ==========================================
    @Test
    fun `validate contribution deduct Yes creates exactly one linked transaction and Deduct No creates none`() = runBlocking {
        val goal = SavingsGoal(id = 100L, name = "New Phone", targetAmount = Amount.fromMainUnit(60000))
        val goalRepo = FakeSavingsGoalRepo(mutableListOf(goal))
        val txRepo = FakeTxRepo()
        val catRepo = FakeCategoryRepo()

        val saveContribUseCase = SaveSavingsGoalContributionUseCase(goalRepo, txRepo, catRepo)

        // Case A: Deduct = Yes
        val contrib1 = SavingsGoalContribution(
            id = 0L,
            goalId = 100L,
            amount = Amount.fromMainUnit(10000),
            timestamp = System.currentTimeMillis(),
            note = "First installment"
        )
        val res1 = saveContribUseCase(contrib1, deductFromAccount = true)
        assertTrue(res1 is AppResult.Success)

        // Exactly 1 linked transaction created
        assertEquals(1, txRepo.transactions.size)
        val tx1 = txRepo.transactions[0]
        assertEquals(Amount.fromMainUnit(10000), tx1.amount)
        assertEquals(AppConstants.CATEGORY_SAVINGS_AND_GOALS, tx1.category.name)
        assertEquals(PaymentMethod.ACCOUNT, tx1.paymentMethod)
        assertEquals(tx1.id, goalRepo.contributions[0].transactionId)

        // Case B: Deduct = No
        val contrib2 = SavingsGoalContribution(
            id = 0L,
            goalId = 100L,
            amount = Amount.fromMainUnit(5000),
            timestamp = System.currentTimeMillis()
        )
        val res2 = saveContribUseCase(contrib2, deductFromAccount = false)
        assertTrue(res2 is AppResult.Success)

        // No new transaction created (still 1 total)
        assertEquals(1, txRepo.transactions.size)
        assertNull(goalRepo.contributions[1].transactionId)
    }

    @Test
    fun `validate safe deletion of contribution preserves ledger history by default`() = runBlocking {
        val goal = SavingsGoal(id = 1L, name = "Emergency Fund", targetAmount = Amount.fromMainUnit(10000))
        val tx = Transaction(
            id = 777L,
            amount = Amount.fromMainUnit(2500),
            type = TransactionType.EXPENSE,
            category = Category(id = 10, name = AppConstants.CATEGORY_SAVINGS_AND_GOALS, iconName = "savings", colorHex = "#10B981", type = TransactionType.EXPENSE, isDefault = false),
            timestamp = System.currentTimeMillis()
        )
        val contrib = SavingsGoalContribution(
            id = 1L,
            goalId = 1L,
            amount = Amount.fromMainUnit(2500),
            timestamp = System.currentTimeMillis(),
            transactionId = 777L
        )

        val goalRepo = FakeSavingsGoalRepo(mutableListOf(goal), mutableListOf(contrib))
        val txRepo = FakeTxRepo(mutableListOf(tx))
        val deleteContribUseCase = DeleteSavingsGoalContributionUseCase(goalRepo, txRepo)

        // Safe delete (default deleteLinkedTransaction = false)
        val deleteResult = deleteContribUseCase(contributionId = 1L, deleteLinkedTransaction = false)
        assertTrue(deleteResult is AppResult.Success)

        // Goal contribution is deleted
        assertEquals(0, goalRepo.contributions.size)
        // Ledger transaction is safely PRESERVED
        assertEquals(1, txRepo.transactions.size)
        assertEquals(777L, txRepo.transactions[0].id)

        // Reversal delete (deleteLinkedTransaction = true)
        goalRepo.contributions.add(contrib)
        val reverseResult = deleteContribUseCase(contributionId = 1L, deleteLinkedTransaction = true)
        assertTrue(reverseResult is AppResult.Success)
        assertEquals(0, txRepo.transactions.size)
    }

    @Test
    fun `validate safe deletion of entire goal preserves or deletes linked transactions`() = runBlocking {
        val goal = SavingsGoal(id = 5L, name = "Car Downpayment", targetAmount = Amount.fromMainUnit(50000))
        val tx1 = Transaction(id = 101L, amount = Amount.fromMainUnit(5000), type = TransactionType.EXPENSE, category = Category(1, AppConstants.CATEGORY_SAVINGS_AND_GOALS, "savings", "#10B981", TransactionType.EXPENSE, false), timestamp = 1000L)
        val tx2 = Transaction(id = 102L, amount = Amount.fromMainUnit(5000), type = TransactionType.EXPENSE, category = Category(1, AppConstants.CATEGORY_SAVINGS_AND_GOALS, "savings", "#10B981", TransactionType.EXPENSE, false), timestamp = 2000L)
        val c1 = SavingsGoalContribution(id = 1L, goalId = 5L, amount = Amount.fromMainUnit(5000), timestamp = 1000L, transactionId = 101L)
        val c2 = SavingsGoalContribution(id = 2L, goalId = 5L, amount = Amount.fromMainUnit(5000), timestamp = 2000L, transactionId = 102L)

        val goalRepo = FakeSavingsGoalRepo(mutableListOf(goal), mutableListOf(c1, c2))
        val txRepo = FakeTxRepo(mutableListOf(tx1, tx2))
        val deleteGoalUseCase = DeleteSavingsGoalUseCase(goalRepo, txRepo)

        // Preserve ledger transactions
        val resPreserve = deleteGoalUseCase(id = 5L, deleteLinkedTransactions = false)
        assertTrue(resPreserve is AppResult.Success)
        assertEquals(0, goalRepo.goals.size)
        assertEquals(2, txRepo.transactions.size)

        // Reverse ledger transactions
        goalRepo.goals.add(goal)
        goalRepo.contributions.addAll(listOf(c1, c2))
        val resReverse = deleteGoalUseCase(id = 5L, deleteLinkedTransactions = true)
        assertTrue(resReverse is AppResult.Success)
        assertEquals(0, goalRepo.goals.size)
        assertEquals(0, txRepo.transactions.size)
    }

    // ==========================================
    // 4. ACTIVE SPLITS ON DASHBOARD (TO COLLECT / TO PAY / SETTLED)
    // ==========================================
    @Test
    fun `validate split expense payer states - to collect vs to pay vs fully settled`() {
        // 1. To Collect (User paid, participants owe user)
        val toCollectSplit = SplitExpense(
            id = 1L,
            title = "Dinner with Friends",
            totalAmount = Amount.fromMainUnit(3000),
            date = 1000L,
            categoryId = 1L,
            paidBy = "Me",
            participants = listOf(
                SplitParticipant(id = 1L, splitExpenseId = 1L, name = "Me", isCurrentUser = true, amount = Amount.fromMainUnit(1000), settlementStatus = SettlementStatus.SETTLED),
                SplitParticipant(id = 2L, splitExpenseId = 1L, name = "Bob", isCurrentUser = false, amount = Amount.fromMainUnit(1000), settlementStatus = SettlementStatus.PENDING),
                SplitParticipant(id = 3L, splitExpenseId = 1L, name = "Charlie", isCurrentUser = false, amount = Amount.fromMainUnit(1000), settlementStatus = SettlementStatus.PENDING)
            )
        )
        assertTrue(toCollectSplit.isPaidByMe)
        assertTrue(toCollectSplit.hasUnsettledForUser)
        assertEquals(Amount.fromMainUnit(2000), toCollectSplit.toCollectAmount)
        assertEquals(Amount.ZERO, toCollectSplit.toPayAmount)
        assertEquals(Amount.fromMainUnit(2000), toCollectSplit.unsettledAmountForUser)

        // 2. To Pay (Alice paid, user owes Alice)
        val toPaySplit = SplitExpense(
            id = 2L,
            title = "Movie Tickets",
            totalAmount = Amount.fromMainUnit(1500),
            date = 2000L,
            categoryId = 1L,
            paidBy = "Alice",
            participants = listOf(
                SplitParticipant(id = 4L, splitExpenseId = 2L, name = "Alice", isCurrentUser = false, amount = Amount.fromMainUnit(500), settlementStatus = SettlementStatus.SETTLED),
                SplitParticipant(id = 5L, splitExpenseId = 2L, name = "Me", isCurrentUser = true, amount = Amount.fromMainUnit(500), settlementStatus = SettlementStatus.PENDING),
                SplitParticipant(id = 6L, splitExpenseId = 2L, name = "Bob", isCurrentUser = false, amount = Amount.fromMainUnit(500), settlementStatus = SettlementStatus.PENDING)
            )
        )
        assertFalse(toPaySplit.isPaidByMe)
        assertTrue(toPaySplit.hasUnsettledForUser)
        assertEquals(Amount.ZERO, toPaySplit.toCollectAmount)
        assertEquals(Amount.fromMainUnit(500), toPaySplit.toPayAmount)
        assertEquals(Amount.fromMainUnit(500), toPaySplit.unsettledAmountForUser)

        // 3. Fully Settled (User paid and all participants settled)
        val settledSplit = SplitExpense(
            id = 3L,
            title = "Cab Fare",
            totalAmount = Amount.fromMainUnit(600),
            date = 3000L,
            categoryId = 1L,
            paidBy = "Me",
            participants = listOf(
                SplitParticipant(id = 7L, splitExpenseId = 3L, name = "Me", isCurrentUser = true, amount = Amount.fromMainUnit(300), settlementStatus = SettlementStatus.SETTLED),
                SplitParticipant(id = 8L, splitExpenseId = 3L, name = "Dave", isCurrentUser = false, amount = Amount.fromMainUnit(300), settlementStatus = SettlementStatus.SETTLED)
            )
        )
        assertFalse(settledSplit.hasUnsettledForUser)
        assertEquals(Amount.ZERO, settledSplit.toCollectAmount)
        assertEquals(Amount.ZERO, settledSplit.toPayAmount)
        assertEquals(Amount.ZERO, settledSplit.unsettledAmountForUser)
    }

    // ==========================================
    // 5. MONTHLY SUMMARY CALCULATIONS & ZERO-DATA EDGE CASES
    // ==========================================
    @Test
    fun `validate monthly summary separates ordinary expense and savings allocations and computes MoM`() = runBlocking {
        val currentYearMonth = YearMonth.now()
        val startEpoch = currentYearMonth.atDay(1).atStartOfDay(ZoneId.systemDefault()).toInstant().toEpochMilli()
        val midEpoch = currentYearMonth.atDay(10).atStartOfDay(ZoneId.systemDefault()).toInstant().toEpochMilli()

        val foodCat = Category(id = 1L, name = "Food", iconName = "restaurant", colorHex = "#EF4444", type = TransactionType.EXPENSE, isDefault = true)
        val savingsCat = Category(id = 2L, name = AppConstants.CATEGORY_SAVINGS_AND_GOALS, iconName = "savings", colorHex = "#10B981", type = TransactionType.EXPENSE, isDefault = false)
        val salaryCat = Category(id = 3L, name = "Salary", iconName = "payments", colorHex = "#10B981", type = TransactionType.INCOME, isDefault = true)

        val txs = listOf(
            Transaction(id = 1L, amount = Amount.fromMainUnit(4000), type = TransactionType.EXPENSE, category = foodCat, timestamp = startEpoch),
            Transaction(id = 2L, amount = Amount.fromMainUnit(3000), type = TransactionType.EXPENSE, category = savingsCat, timestamp = midEpoch),
            Transaction(id = 3L, amount = Amount.fromMainUnit(15000), type = TransactionType.INCOME, category = salaryCat, timestamp = startEpoch)
        )

        val txRepo = FakeTxRepo(txs.toMutableList())
        val prefsRepo = FakePrefsRepo()
        val getMonthlyLedger = GetMonthlyLedgerUseCase(txRepo, prefsRepo)

        val summary = getMonthlyLedger(currentYearMonth).first()

        assertEquals(1500000L, summary.totalIncome.subunits)
        assertEquals(700000L, summary.totalExpense.subunits) // raw expense sum
        assertEquals(400000L, summary.ordinaryExpense.subunits) // actual spending
        assertEquals(300000L, summary.savingsAllocation.subunits) // wealth allocation
        assertEquals(800000L, summary.netChange.subunits) // 15000 - 7000 = 8000
        assertTrue(summary.dailyAverageExpense.subunits > 0L)
    }

    @Test
    fun `validate monthly summary zero-data edge case handles empty months safely`() = runBlocking {
        val emptyMonth = YearMonth.now().plusMonths(6)
        val txRepo = FakeTxRepo()
        val prefsRepo = FakePrefsRepo()
        val getMonthlyLedger = GetMonthlyLedgerUseCase(txRepo, prefsRepo)

        val summary = getMonthlyLedger(emptyMonth).first()

        assertEquals(Amount.ZERO, summary.totalIncome)
        assertEquals(Amount.ZERO, summary.totalExpense)
        assertEquals(Amount.ZERO, summary.ordinaryExpense)
        assertEquals(Amount.ZERO, summary.savingsAllocation)
        assertEquals(Amount.ZERO, summary.dailyAverageExpense)
        assertEquals(0, summary.transactions.size)
        assertEquals(0, summary.expenseBreakdown.size)
    }

    // ==========================================
    // 6. STATEMENT PDF GENERATION ORDERING
    // ==========================================
    @Test
    fun `validate statement generation produces bank standard newest-first ordering`() = runBlocking {
        val cat = Category(id = 1L, name = "General", iconName = "tag", colorHex = "#64748B", type = TransactionType.EXPENSE, isDefault = true)
        val t1 = Transaction(id = 10L, amount = Amount.fromMainUnit(100), type = TransactionType.EXPENSE, category = cat, timestamp = 1000L)
        val t2 = Transaction(id = 20L, amount = Amount.fromMainUnit(500), type = TransactionType.INCOME, category = cat, timestamp = 2000L)
        val t3 = Transaction(id = 30L, amount = Amount.fromMainUnit(250), type = TransactionType.EXPENSE, category = cat, timestamp = 3000L)

        val txRepo = FakeTxRepo(mutableListOf(t1, t2, t3))
        val prefsRepo = FakePrefsRepo()
        val generateStatement = GenerateStatementUseCase(txRepo, prefsRepo)

        val report = generateStatement(0L, 5000L, "September 2026")

        // 3 transactions + 1 Opening Balance row
        assertEquals(4, report.ledgerItems.size)
        // Newest transaction (t3 at 3000L) must be first:
        assertEquals(Amount.fromMainUnit(250), report.ledgerItems[0].amount)
        // Followed by t2 (2000L):
        assertEquals(Amount.fromMainUnit(500), report.ledgerItems[1].amount)
        // Followed by t1 (1000L):
        assertEquals(Amount.fromMainUnit(100), report.ledgerItems[2].amount)
        // Final row is Opening Balance:
        assertEquals("Opening Balance", report.ledgerItems[3].description)
    }

    // Helpers / Fakes
    private class FakeCategoryRepo(private val categories: List<Category> = emptyList()) : CategoryRepository {
        private val list = categories.toMutableList()
        override fun getCategories(): Flow<List<Category>> = flowOf(list)
        override fun getCategoriesByType(type: TransactionType): Flow<List<Category>> = flowOf(list.filter { it.type == type })
        override fun getCategoryById(id: Long): Flow<Category?> = flowOf(list.find { it.id == id })
        override suspend fun insertCategory(category: Category): AppResult<Long> {
            val id = if (category.id != 0L) category.id else (list.size + 1).toLong()
            list.add(category.copy(id = id))
            return AppResult.Success(id)
        }
        override suspend fun updateCategory(category: Category): AppResult<Unit> = AppResult.Success(Unit)
        override suspend fun deleteCategory(id: Long): AppResult<Unit> = AppResult.Success(Unit)
    }

    private class FakeTxRepo(val transactions: MutableList<Transaction> = mutableListOf()) : TransactionRepository {
        override fun getTransactions(): Flow<List<Transaction>> = flowOf(transactions)
        override fun getTransactionById(id: Long): Flow<Transaction?> = flowOf(transactions.find { it.id == id })
        override fun getTransactionsBetween(startDate: Long, endDate: Long): Flow<List<Transaction>> =
            flowOf(transactions.filter { it.timestamp in startDate..endDate })
        override fun getFinancialSummary(): Flow<FinancialSummary> = flowOf(FinancialSummary.EMPTY)
        override fun getFinancialSummaryByDateRange(startDate: Long, endDate: Long): Flow<FinancialSummary> = flowOf(FinancialSummary.EMPTY)
        override suspend fun insertTransaction(transaction: Transaction): AppResult<Long> {
            val id = if (transaction.id != 0L) transaction.id else (transactions.size + 1).toLong()
            transactions.add(transaction.copy(id = id))
            return AppResult.Success(id)
        }
        override suspend fun updateTransaction(transaction: Transaction): AppResult<Unit> {
            val idx = transactions.indexOfFirst { it.id == transaction.id }
            if (idx != -1) transactions[idx] = transaction
            return AppResult.Success(Unit)
        }
        override suspend fun deleteTransaction(id: Long): AppResult<Unit> {
            transactions.removeAll { it.id == id }
            return AppResult.Success(Unit)
        }
    }

    private class FakePrefsRepo : UserPreferencesRepository {
        override fun getUserPreferences(): Flow<UserPreferences> = flowOf(UserPreferences())
        override suspend fun setThemeMode(themeMode: ThemeMode): AppResult<Unit> = AppResult.Success(Unit)
        override suspend fun setCurrencyCode(currencyCode: String): AppResult<Unit> = AppResult.Success(Unit)
        override suspend fun setDynamicColors(useDynamicColors: Boolean): AppResult<Unit> = AppResult.Success(Unit)
        override suspend fun setFirstLaunchCompleted(): AppResult<Unit> = AppResult.Success(Unit)
        override suspend fun setOpeningBalance(subunits: Long): AppResult<Unit> = AppResult.Success(Unit)
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

    private class FakeSavingsGoalRepo(
        val goals: MutableList<SavingsGoal> = mutableListOf(),
        val contributions: MutableList<SavingsGoalContribution> = mutableListOf()
    ) : SavingsGoalRepository {
        override fun getActiveSavingsGoals(): Flow<List<SavingsGoal>> = flowOf(goals.filter { !it.isArchived })
        override fun getArchivedSavingsGoals(): Flow<List<SavingsGoal>> = flowOf(goals.filter { it.isArchived })
        override fun getAllSavingsGoals(): Flow<List<SavingsGoal>> = flowOf(goals)
        override fun getSavingsGoalById(id: Long): Flow<SavingsGoal?> = flowOf(goals.find { it.id == id })
        override suspend fun getSavingsGoalByIdSuspend(id: Long): SavingsGoal? {
            val g = goals.find { it.id == id } ?: return null
            val goalContribs = contributions.filter { it.goalId == g.id }
            return g.copy(contributions = goalContribs)
        }
        override fun getContributionsForGoal(goalId: Long): Flow<List<SavingsGoalContribution>> = flowOf(contributions.filter { it.goalId == goalId })
        override suspend fun getContributionByIdSuspend(id: Long): SavingsGoalContribution? = contributions.find { it.id == id }
        override suspend fun saveSavingsGoal(goal: SavingsGoal): AppResult<Long> {
            goals.add(goal)
            return AppResult.Success(goal.id)
        }
        override suspend fun deleteSavingsGoal(id: Long): AppResult<Unit> {
            goals.removeAll { it.id == id }
            return AppResult.Success(Unit)
        }
        override suspend fun setGoalArchived(id: Long, isArchived: Boolean): AppResult<Unit> = AppResult.Success(Unit)
        override suspend fun addContribution(contribution: SavingsGoalContribution): AppResult<Long> {
            val id = if (contribution.id != 0L) contribution.id else (contributions.size + 1).toLong()
            contributions.add(contribution.copy(id = id))
            return AppResult.Success(id)
        }
        override suspend fun updateContribution(contribution: SavingsGoalContribution): AppResult<Unit> {
            val idx = contributions.indexOfFirst { it.id == contribution.id }
            if (idx != -1) contributions[idx] = contribution
            return AppResult.Success(Unit)
        }
        override suspend fun deleteContribution(id: Long): AppResult<Unit> {
            contributions.removeAll { it.id == id }
            return AppResult.Success(Unit)
        }
        override suspend fun deleteAllGoals(): AppResult<Unit> = AppResult.Success(Unit)
    }
}
