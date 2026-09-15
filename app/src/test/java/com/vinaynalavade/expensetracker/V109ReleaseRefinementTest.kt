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
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test
import java.time.YearMonth
import java.time.ZoneId

class V109ReleaseRefinementTest {

    // 1. Branding test
    @Test
    fun `test exact branding phrase and absence of personal names in global branding`() {
        assertEquals("Crafted with 💚 in India", AppConstants.CREATOR_BRANDING)
        assertFalse(AppConstants.CREATOR_BRANDING.contains("Vinay", ignoreCase = true))
        assertFalse(AppConstants.CREATOR_BRANDING.contains("Nalavade", ignoreCase = true))
    }

    // 2. Savings & Goals internal category filtered from manual selection
    @Test
    fun `test category usecase filters internal savings category by default`() = runBlocking {
        val foodCat = Category(id = 1L, name = "Food", iconName = "restaurant", colorHex = "#FF5722", type = TransactionType.EXPENSE, isDefault = true)
        val savingsCat = Category(id = 2L, name = AppConstants.CATEGORY_SAVINGS_AND_GOALS, iconName = "savings", colorHex = "#10B981", type = TransactionType.EXPENSE, isDefault = false)
        val fakeCatRepo = FakeCategoryRepo(listOf(foodCat, savingsCat))

        val getCategoriesUseCase = GetCategoriesUseCase(fakeCatRepo)

        // By default (includeInternal = false), Savings & Goals should be filtered out
        val filtered = getCategoriesUseCase.getByType(TransactionType.EXPENSE).first()
        assertEquals(1, filtered.size)
        assertEquals("Food", filtered[0].name)

        // When includeInternal = true, it should appear
        val all = getCategoriesUseCase.getByType(TransactionType.EXPENSE, includeInternal = true).first()
        assertEquals(2, all.size)
        assertTrue(all.any { it.name == AppConstants.CATEGORY_SAVINGS_AND_GOALS })
    }

    // 3. Contribution deduction from account balance
    @Test
    fun `test savings contribution with account deduction creates linked transaction`() = runBlocking {
        val goal = SavingsGoal(id = 10L, name = "Emergency Fund", targetAmount = Amount.fromMainUnit(50000))
        val fakeGoalRepo = FakeSavingsGoalRepo(mutableListOf(goal))
        val fakeTxRepo = FakeTxRepo()
        val fakeCatRepo = FakeCategoryRepo()

        val saveContrib = SaveSavingsGoalContributionUseCase(fakeGoalRepo, fakeTxRepo, fakeCatRepo)

        // Deduct from account = true
        val contrib = SavingsGoalContribution(
            goalId = 10L,
            amount = Amount.fromMainUnit(5000),
            timestamp = System.currentTimeMillis(),
            note = "Monthly stash"
        )
        val result = saveContrib(contrib, deductFromAccount = true)
        assertTrue(result is AppResult.Success)

        // Check transaction was created under "Savings & Goals"
        assertEquals(1, fakeTxRepo.transactions.size)
        val createdTx = fakeTxRepo.transactions[0]
        assertEquals(Amount.fromMainUnit(5000), createdTx.amount)
        assertEquals(AppConstants.CATEGORY_SAVINGS_AND_GOALS, createdTx.category.name)
        assertEquals(PaymentMethod.ACCOUNT, createdTx.paymentMethod)
        assertTrue(createdTx.note?.contains("Emergency Fund") == true)

        // Check contribution has linked transactionId
        val savedContrib = fakeGoalRepo.contributions[0]
        assertEquals(createdTx.id, savedContrib.transactionId)
    }

    // 4. Contribution without account deduction
    @Test
    fun `test savings contribution without account deduction creates progress only`() = runBlocking {
        val goal = SavingsGoal(id = 11L, name = "New Laptop", targetAmount = Amount.fromMainUnit(80000))
        val fakeGoalRepo = FakeSavingsGoalRepo(mutableListOf(goal))
        val fakeTxRepo = FakeTxRepo()
        val fakeCatRepo = FakeCategoryRepo()

        val saveContrib = SaveSavingsGoalContributionUseCase(fakeGoalRepo, fakeTxRepo, fakeCatRepo)

        val contrib = SavingsGoalContribution(
            goalId = 11L,
            amount = Amount.fromMainUnit(10000),
            timestamp = System.currentTimeMillis()
        )
        val result = saveContrib(contrib, deductFromAccount = false)
        assertTrue(result is AppResult.Success)

        // No transaction should be created
        assertEquals(0, fakeTxRepo.transactions.size)
        assertNull(fakeGoalRepo.contributions[0].transactionId)
    }

    // 5. Safe deletion of contributions (preserving ledger history by default)
    @Test
    fun `test delete contribution protects linked ledger transaction by default`() = runBlocking {
        val goal = SavingsGoal(id = 1L, name = "Goal", targetAmount = Amount.fromMainUnit(1000))
        val linkedTx = Transaction(
            id = 99L,
            amount = Amount.fromMainUnit(1000),
            type = TransactionType.EXPENSE,
            category = Category(id = 1, name = AppConstants.CATEGORY_SAVINGS_AND_GOALS, iconName = "savings", colorHex = "#10B981", type = TransactionType.EXPENSE, isDefault = false),
            timestamp = System.currentTimeMillis()
        )
        val contrib = SavingsGoalContribution(
            id = 50L,
            goalId = 1L,
            amount = Amount.fromMainUnit(1000),
            timestamp = System.currentTimeMillis(),
            transactionId = 99L
        )

        val fakeGoalRepo = FakeSavingsGoalRepo(mutableListOf(goal), mutableListOf(contrib))
        val fakeTxRepo = FakeTxRepo(mutableListOf(linkedTx))

        val deleteContribUseCase = DeleteSavingsGoalContributionUseCase(fakeGoalRepo, fakeTxRepo)

        // Delete contribution with deleteLinkedTransaction = false
        val delResult = deleteContribUseCase(contributionId = 50L, deleteLinkedTransaction = false)
        assertTrue(delResult is AppResult.Success)

        // Contribution is removed from goal
        assertEquals(0, fakeGoalRepo.contributions.size)
        // But linked transaction is preserved in ledger history!
        assertEquals(1, fakeTxRepo.transactions.size)
        assertEquals(99L, fakeTxRepo.transactions[0].id)

        // Now test deleting with deleteLinkedTransaction = true
        fakeGoalRepo.contributions.add(contrib)
        val delResult2 = deleteContribUseCase(contributionId = 50L, deleteLinkedTransaction = true)
        assertTrue(delResult2 is AppResult.Success)
        assertEquals(0, fakeTxRepo.transactions.size)
    }

    // 6. Active Splits: To Collect vs To Pay calculation
    @Test
    fun `test split expense distinguishes to collect and to pay unsettled amounts`() {
        // Scenario A: User paid 3000 total. Alice owes 1000, Bob owes 1000.
        val splitUserPaid = SplitExpense(
            id = 1L,
            title = "Team Dinner",
            totalAmount = Amount.fromMainUnit(3000),
            date = System.currentTimeMillis(),
            categoryId = 1L,
            paidBy = "Me",
            createdAt = System.currentTimeMillis(),
            participants = listOf(
                SplitParticipant(id = 1L, splitExpenseId = 1L, name = "Me", isCurrentUser = true, amount = Amount.fromMainUnit(1000), settlementStatus = SettlementStatus.SETTLED),
                SplitParticipant(id = 2L, splitExpenseId = 1L, name = "Alice", isCurrentUser = false, amount = Amount.fromMainUnit(1000), settlementStatus = SettlementStatus.PENDING),
                SplitParticipant(id = 3L, splitExpenseId = 1L, name = "Bob", isCurrentUser = false, amount = Amount.fromMainUnit(1000), settlementStatus = SettlementStatus.PENDING)
            )
        )

        assertTrue(splitUserPaid.isPaidByMe)
        assertTrue(splitUserPaid.hasUnsettledForUser)
        assertEquals(Amount.fromMainUnit(2000), splitUserPaid.toCollectAmount)
        assertEquals(Amount.ZERO, splitUserPaid.toPayAmount)
        assertEquals(Amount.fromMainUnit(2000), splitUserPaid.unsettledAmountForUser)

        // Scenario B: Alice paid 3000 total. User owes 1000.
        val splitAlicePaid = SplitExpense(
            id = 2L,
            title = "Weekend Trip",
            totalAmount = Amount.fromMainUnit(3000),
            date = System.currentTimeMillis(),
            categoryId = 1L,
            paidBy = "Alice",
            createdAt = System.currentTimeMillis(),
            participants = listOf(
                SplitParticipant(id = 4L, splitExpenseId = 2L, name = "Alice", isCurrentUser = false, amount = Amount.fromMainUnit(1000), settlementStatus = SettlementStatus.SETTLED),
                SplitParticipant(id = 5L, splitExpenseId = 2L, name = "Me", isCurrentUser = true, amount = Amount.fromMainUnit(1000), settlementStatus = SettlementStatus.PENDING),
                SplitParticipant(id = 6L, splitExpenseId = 2L, name = "Bob", isCurrentUser = false, amount = Amount.fromMainUnit(1000), settlementStatus = SettlementStatus.PENDING)
            )
        )

        assertFalse(splitAlicePaid.isPaidByMe)
        assertTrue(splitAlicePaid.hasUnsettledForUser)
        assertEquals(Amount.ZERO, splitAlicePaid.toCollectAmount)
        assertEquals(Amount.fromMainUnit(1000), splitAlicePaid.toPayAmount)
        assertEquals(Amount.fromMainUnit(1000), splitAlicePaid.unsettledAmountForUser)
    }

    // 7. Monthly Summary: Distinguishes ordinary expenses from savings allocations and computes MoM & daily avg
    @Test
    fun `test monthly summary computes ordinary expenses and savings allocations separately`() = runBlocking {
        val currentYearMonth = YearMonth.now()
        val startEpoch = currentYearMonth.atDay(1).atStartOfDay(ZoneId.systemDefault()).toInstant().toEpochMilli()
        val midEpoch = currentYearMonth.atDay(15).atStartOfDay(ZoneId.systemDefault()).toInstant().toEpochMilli()

        val foodCat = Category(id = 1L, name = "Groceries", iconName = "shopping_cart", colorHex = "#3B82F6", type = TransactionType.EXPENSE, isDefault = true)
        val savingsCat = Category(id = 2L, name = AppConstants.CATEGORY_SAVINGS_AND_GOALS, iconName = "savings", colorHex = "#10B981", type = TransactionType.EXPENSE, isDefault = false)
        val salaryCat = Category(id = 3L, name = "Salary", iconName = "payments", colorHex = "#10B981", type = TransactionType.INCOME, isDefault = true)

        val txs = listOf(
            Transaction(id = 1L, amount = Amount.fromMainUnit(3000), type = TransactionType.EXPENSE, category = foodCat, timestamp = startEpoch),
            Transaction(id = 2L, amount = Amount.fromMainUnit(2000), type = TransactionType.EXPENSE, category = savingsCat, timestamp = midEpoch),
            Transaction(id = 3L, amount = Amount.fromMainUnit(10000), type = TransactionType.INCOME, category = salaryCat, timestamp = startEpoch)
        )

        val fakeTxRepo = FakeTxRepo(txs.toMutableList())
        val fakePrefsRepo = FakePrefsRepo()
        val getMonthlyLedger = GetMonthlyLedgerUseCase(fakeTxRepo, fakePrefsRepo)

        val ledger = getMonthlyLedger(currentYearMonth).first()

        // Total expenses in raw sum = 5000 (3000 groceries + 2000 savings)
        assertEquals(500000L, ledger.totalExpense.subunits)
        // Ordinary expenses = 3000
        assertEquals(300000L, ledger.ordinaryExpense.subunits)
        // Savings allocations = 2000
        assertEquals(200000L, ledger.savingsAllocation.subunits)
        // Net change = 10000 - 5000 = 5000
        assertEquals(500000L, ledger.netChange.subunits)
        assertTrue(ledger.dailyAverageExpense.subunits > 0L)
    }

    // 8. PDF Statement ordering: Newest First
    @Test
    fun `test statement generation sorts transactions newest first`() = runBlocking {
        val cat = Category(id = 1L, name = "Food", iconName = "restaurant", colorHex = "#FF5722", type = TransactionType.EXPENSE, isDefault = true)
        val txOld = Transaction(id = 1L, amount = Amount.fromMainUnit(100), type = TransactionType.EXPENSE, category = cat, timestamp = 1000L)
        val txMid = Transaction(id = 2L, amount = Amount.fromMainUnit(200), type = TransactionType.EXPENSE, category = cat, timestamp = 2000L)
        val txNew = Transaction(id = 3L, amount = Amount.fromMainUnit(300), type = TransactionType.EXPENSE, category = cat, timestamp = 3000L)

        val fakeTxRepo = FakeTxRepo(mutableListOf(txOld, txMid, txNew))
        val fakePrefsRepo = FakePrefsRepo()
        val generateStatement = GenerateStatementUseCase(fakeTxRepo, fakePrefsRepo)

        val statement = generateStatement(0L, 5000L, "September 2026")

        // ledgerItems includes 3 transactions + 1 Opening Balance row
        assertEquals(4, statement.ledgerItems.size)
        // Bank-standard Newest First:
        assertEquals("Food", statement.ledgerItems[0].categoryName)
        assertEquals(Amount.fromMainUnit(300), statement.ledgerItems[0].amount)
        assertEquals(Amount.fromMainUnit(200), statement.ledgerItems[1].amount)
        assertEquals(Amount.fromMainUnit(100), statement.ledgerItems[2].amount)
        assertEquals("Opening Balance", statement.ledgerItems[3].description)
    }

    // Helpers / Test Fakes
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
