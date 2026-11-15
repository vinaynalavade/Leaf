package com.vinaynalavade.expensetracker

import com.vinaynalavade.expensetracker.core.model.Amount
import com.vinaynalavade.expensetracker.core.result.AppResult
import com.vinaynalavade.expensetracker.domain.model.BalanceDisplayMode
import com.vinaynalavade.expensetracker.domain.model.Category
import com.vinaynalavade.expensetracker.domain.model.FinancialSummary
import com.vinaynalavade.expensetracker.domain.model.PaymentMethod
import com.vinaynalavade.expensetracker.domain.model.SpendingTrendData
import com.vinaynalavade.expensetracker.domain.model.ThemeMode
import com.vinaynalavade.expensetracker.domain.model.Transaction
import com.vinaynalavade.expensetracker.domain.model.TransactionType
import com.vinaynalavade.expensetracker.domain.model.UserPreferences
import com.vinaynalavade.expensetracker.domain.repository.CategoryRepository
import com.vinaynalavade.expensetracker.domain.repository.TransactionRepository
import com.vinaynalavade.expensetracker.domain.repository.UserPreferencesRepository
import com.vinaynalavade.expensetracker.domain.usecase.GetMonthlyLedgerUseCase
import com.vinaynalavade.expensetracker.domain.usecase.GetSpendingTrendsUseCase
import com.vinaynalavade.expensetracker.presentation.summary.MonthlySummaryViewModel
import com.vinaynalavade.expensetracker.presentation.summary.SummaryFilterTab
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.flowOf
import kotlinx.coroutines.runBlocking
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test
import java.time.YearMonth
import java.time.ZoneId

class InsightsInteractivityTest {

    private class FakeTransactionRepo(
        private val txs: List<Transaction> = emptyList()
    ) : TransactionRepository {
        override fun getTransactions(): Flow<List<Transaction>> = flowOf(txs)
        override fun getTransactionById(id: Long): Flow<Transaction?> = flowOf(txs.find { it.id == id })
        override fun getTransactionsBetween(startDate: Long, endDate: Long): Flow<List<Transaction>> =
            flowOf(txs.filter { it.timestamp in startDate..endDate })
        override fun getFinancialSummary(): Flow<FinancialSummary> =
            flowOf(FinancialSummary(Amount.ZERO, Amount.ZERO, Amount.ZERO))
        override fun getFinancialSummaryByDateRange(startDate: Long, endDate: Long): Flow<FinancialSummary> =
            flowOf(FinancialSummary(Amount.ZERO, Amount.ZERO, Amount.ZERO))
        override suspend fun insertTransaction(transaction: Transaction): AppResult<Long> = AppResult.Success(0L)
        override suspend fun updateTransaction(transaction: Transaction): AppResult<Unit> = AppResult.Success(Unit)
        override suspend fun deleteTransaction(id: Long): AppResult<Unit> = AppResult.Success(Unit)
    }

    private class FakeCategoryRepo(
        private val categories: List<Category> = emptyList()
    ) : CategoryRepository {
        override fun getCategories(): Flow<List<Category>> = flowOf(categories)
        override fun getCategoriesByType(type: TransactionType): Flow<List<Category>> =
            flowOf(categories.filter { it.type == type })
        override fun getCategoryById(id: Long): Flow<Category?> = flowOf(categories.find { it.id == id })
        override suspend fun insertCategory(category: Category): AppResult<Long> = AppResult.Success(0L)
        override suspend fun updateCategory(category: Category): AppResult<Unit> = AppResult.Success(Unit)
        override suspend fun deleteCategory(id: Long): AppResult<Unit> = AppResult.Success(Unit)
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
        override suspend fun setBalanceDisplayMode(mode: BalanceDisplayMode): AppResult<Unit> = AppResult.Success(Unit)
        override suspend fun setBalanceVisible(isVisible: Boolean): AppResult<Unit> = AppResult.Success(Unit)
    }

    @Test
    fun `test MonthlySummaryViewModel category filter toggle and clear`() = runBlocking {
        val fakeTxRepo = FakeTransactionRepo()
        val fakePrefsRepo = FakePrefsRepo()
        val ledgerUseCase = GetMonthlyLedgerUseCase(fakeTxRepo, fakePrefsRepo)
        val viewModel = MonthlySummaryViewModel(ledgerUseCase)

        // Initial state
        assertNull(viewModel.selectedCategoryId.value)
        assertEquals(SummaryFilterTab.ALL, viewModel.selectedTab.value)

        // Select a category (e.g. category 42)
        viewModel.selectCategory(42L)
        assertEquals(42L, viewModel.selectedCategoryId.value)

        // Tap the same category again to toggle off
        viewModel.selectCategory(42L)
        assertNull(viewModel.selectedCategoryId.value)

        // Select category again, then clear explicitly
        viewModel.selectCategory(99L)
        assertEquals(99L, viewModel.selectedCategoryId.value)
        viewModel.clearCategoryFilter()
        assertNull(viewModel.selectedCategoryId.value)

        // Switching tabs should clear active category filter
        viewModel.selectCategory(55L)
        assertEquals(55L, viewModel.selectedCategoryId.value)
        viewModel.onTabSelected(SummaryFilterTab.EXPENSES)
        assertNull(viewModel.selectedCategoryId.value)
        assertEquals(SummaryFilterTab.EXPENSES, viewModel.selectedTab.value)
    }

    @Test
    fun `test SpendingTrendsUseCase attaches contributing transactions to monthly points and categories`() = runBlocking {
        val zone = ZoneId.systemDefault()
        val currentYm = YearMonth.now(zone)
        val prevYm = currentYm.minusMonths(1)

        val currentEpoch = currentYm.atDay(10).atStartOfDay(zone).toInstant().toEpochMilli()
        val prevEpoch = prevYm.atDay(10).atStartOfDay(zone).toInstant().toEpochMilli()

        val catFood = Category(id = 10, name = "Dining", iconName = "restaurant", colorHex = "#FF5722", type = TransactionType.EXPENSE)
        val catFuel = Category(id = 20, name = "Fuel", iconName = "local_gas_station", colorHex = "#2196F3", type = TransactionType.EXPENSE)

        val tx1 = Transaction(id = 101, amount = Amount.fromSubunits(50000L), type = TransactionType.EXPENSE, category = catFood, timestamp = prevEpoch)
        val tx2 = Transaction(id = 102, amount = Amount.fromSubunits(30000L), type = TransactionType.EXPENSE, category = catFuel, timestamp = currentEpoch)
        val tx3 = Transaction(id = 103, amount = Amount.fromSubunits(20000L), type = TransactionType.EXPENSE, category = catFood, timestamp = currentEpoch + 1000)

        val useCase = GetSpendingTrendsUseCase(
            FakeTransactionRepo(listOf(tx1, tx2, tx3)),
            FakeCategoryRepo(listOf(catFood, catFuel))
        )

        var trendData: SpendingTrendData? = null
        useCase(monthsCount = 3).collect { trendData = it }

        assertNotNull(trendData)
        val data = trendData!!

        // Last monthly point is current month
        val currentPoint = data.monthlyPoints.last()
        assertEquals(500.0, currentPoint.totalExpense, 0.001)
        assertEquals(2, currentPoint.transactions.size)
        // Check sorting: descending by timestamp
        assertEquals(103L, currentPoint.transactions[0].id)
        assertEquals(102L, currentPoint.transactions[1].id)

        // Previous month point
        val prevPoint = data.monthlyPoints[data.monthlyPoints.size - 2]
        assertEquals(500.0, prevPoint.totalExpense, 0.001)
        assertEquals(1, prevPoint.transactions.size)
        assertEquals(101L, prevPoint.transactions[0].id)

        // Category breakdown includes contributing transactions
        val foodSummary = data.categoryBreakdown.find { it.categoryId == 10L }
        assertNotNull(foodSummary)
        assertEquals(700.0, foodSummary!!.totalAmount, 0.001)
        assertEquals(2, foodSummary.transactions.size)
        assertTrue(foodSummary.transactions.any { it.id == 101L })
        assertTrue(foodSummary.transactions.any { it.id == 103L })

        val fuelSummary = data.categoryBreakdown.find { it.categoryId == 20L }
        assertNotNull(fuelSummary)
        assertEquals(300.0, fuelSummary!!.totalAmount, 0.001)
        assertEquals(1, fuelSummary.transactions.size)
        assertEquals(102L, fuelSummary.transactions[0].id)
    }
}
