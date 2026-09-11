package com.vinaynalavade.expensetracker

import com.vinaynalavade.expensetracker.core.model.Amount
import com.vinaynalavade.expensetracker.core.result.AppResult
import com.vinaynalavade.expensetracker.domain.model.Category
import com.vinaynalavade.expensetracker.domain.model.FinancialSummary
import com.vinaynalavade.expensetracker.domain.model.SpendingTrendData
import com.vinaynalavade.expensetracker.domain.model.Transaction
import com.vinaynalavade.expensetracker.domain.model.TransactionType
import com.vinaynalavade.expensetracker.domain.repository.CategoryRepository
import com.vinaynalavade.expensetracker.domain.repository.TransactionRepository
import com.vinaynalavade.expensetracker.domain.usecase.GetSpendingTrendsUseCase
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.flowOf
import kotlinx.coroutines.runBlocking
import org.junit.Assert.assertEquals
import org.junit.Test
import java.time.YearMonth
import java.time.ZoneId

class SpendingTrendsTest {

    private class FakeTransactionRepository(
        private var transactions: List<Transaction> = emptyList()
    ) : TransactionRepository {
        override fun getTransactions(): Flow<List<Transaction>> = flowOf(transactions)
        override fun getTransactionById(id: Long): Flow<Transaction?> = flowOf(transactions.find { it.id == id })
        override fun getTransactionsBetween(startDate: Long, endDate: Long): Flow<List<Transaction>> =
            flowOf(transactions.filter { it.timestamp in startDate..endDate })
        override fun getFinancialSummary(): Flow<FinancialSummary> =
            flowOf(FinancialSummary(Amount.ZERO, Amount.ZERO, Amount.ZERO))
        override fun getFinancialSummaryByDateRange(startDate: Long, endDate: Long): Flow<FinancialSummary> =
            flowOf(FinancialSummary(Amount.ZERO, Amount.ZERO, Amount.ZERO))
        override suspend fun insertTransaction(transaction: Transaction): AppResult<Long> = AppResult.Success(0L)
        override suspend fun updateTransaction(transaction: Transaction): AppResult<Unit> = AppResult.Success(Unit)
        override suspend fun deleteTransaction(id: Long): AppResult<Unit> = AppResult.Success(Unit)
    }

    private class FakeCategoryRepository(
        private var categories: List<Category> = emptyList()
    ) : CategoryRepository {
        override fun getCategories(): Flow<List<Category>> = flowOf(categories)
        override fun getCategoriesByType(type: TransactionType): Flow<List<Category>> =
            flowOf(categories.filter { it.type == type })
        override fun getCategoryById(id: Long): Flow<Category?> = flowOf(categories.find { it.id == id })
        override suspend fun insertCategory(category: Category): AppResult<Long> = AppResult.Success(0L)
        override suspend fun updateCategory(category: Category): AppResult<Unit> = AppResult.Success(Unit)
        override suspend fun deleteCategory(id: Long): AppResult<Unit> = AppResult.Success(Unit)
    }

    @Test
    fun `test multi-month trend calculation and MoM rate`() = runBlocking {
        val zone = ZoneId.systemDefault()
        val currentYm = YearMonth.now(zone)
        val prevYm = currentYm.minusMonths(1)

        val currentEpoch = currentYm.atDay(15).atStartOfDay(zone).toInstant().toEpochMilli()
        val prevEpoch = prevYm.atDay(15).atStartOfDay(zone).toInstant().toEpochMilli()

        val cats = listOf(
            Category(id = 1, name = "Food", iconName = "food", colorHex = "#FF0000", type = TransactionType.EXPENSE),
            Category(id = 2, name = "Travel", iconName = "travel", colorHex = "#00FF00", type = TransactionType.EXPENSE)
        )

        val txs = listOf(
            // Previous month: 100 on Food
            Transaction(id = 1, amount = Amount.fromSubunits(10000L), type = TransactionType.EXPENSE, category = cats[0], timestamp = prevEpoch),
            // Current month: 150 on Food, 50 on Travel
            Transaction(id = 2, amount = Amount.fromSubunits(15000L), type = TransactionType.EXPENSE, category = cats[0], timestamp = currentEpoch),
            Transaction(id = 3, amount = Amount.fromSubunits(5000L), type = TransactionType.EXPENSE, category = cats[1], timestamp = currentEpoch)
        )

        val useCase = GetSpendingTrendsUseCase(
            FakeTransactionRepository(txs),
            FakeCategoryRepository(cats)
        )

        var trendData: SpendingTrendData? = null
        useCase(monthsCount = 6).collect { trendData = it }

        val data = trendData!!
        assertEquals(6, data.monthlyPoints.size)

        val lastMonthPoint = data.monthlyPoints.last()
        assertEquals(200.0, lastMonthPoint.totalExpense, 0.001)

        val prevMonthPoint = data.monthlyPoints[data.monthlyPoints.size - 2]
        assertEquals(100.0, prevMonthPoint.totalExpense, 0.001)

        // MoM Growth: (200 - 100) / 100 = +100%
        assertEquals(100.0, data.monthOverMonthGrowthRate, 0.001)

        // Category breakdown: Food = 250 (83.33%), Travel = 50 (16.67%)
        assertEquals(2, data.categoryBreakdown.size)
        assertEquals("Food", data.categoryBreakdown[0].categoryName)
        assertEquals(250.0, data.categoryBreakdown[0].totalAmount, 0.001)
        assertEquals(83.333, data.categoryBreakdown[0].percentageOfTotal, 0.1)

        assertEquals("Travel", data.categoryBreakdown[1].categoryName)
        assertEquals(50.0, data.categoryBreakdown[1].totalAmount, 0.001)
        assertEquals(16.666, data.categoryBreakdown[1].percentageOfTotal, 0.1)
    }
}
