package com.vinaynalavade.expensetracker

import com.vinaynalavade.expensetracker.core.model.Amount
import com.vinaynalavade.expensetracker.core.result.AppResult
import com.vinaynalavade.expensetracker.domain.model.Budget
import com.vinaynalavade.expensetracker.domain.model.BudgetProgress
import com.vinaynalavade.expensetracker.domain.model.BudgetStatus
import com.vinaynalavade.expensetracker.domain.model.Category
import com.vinaynalavade.expensetracker.domain.model.FinancialSummary
import com.vinaynalavade.expensetracker.domain.model.Transaction
import com.vinaynalavade.expensetracker.domain.model.TransactionType
import com.vinaynalavade.expensetracker.domain.repository.BudgetRepository
import com.vinaynalavade.expensetracker.domain.repository.TransactionRepository
import com.vinaynalavade.expensetracker.domain.usecase.GetBudgetProgressUseCase
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.flowOf
import kotlinx.coroutines.runBlocking
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotNull
import org.junit.Test
import java.time.LocalDate
import java.time.YearMonth
import java.time.ZoneId

class BudgetCalculationTest {

    private class FakeBudgetRepository(
        private var budgets: List<Budget> = emptyList()
    ) : BudgetRepository {
        override fun getAllBudgets(): Flow<List<Budget>> = flowOf(budgets)
        override fun getBudgetsForMonth(year: Int, month: Int): Flow<List<Budget>> =
            flowOf(budgets.filter { it.year == year && it.month == month })
        override fun getBudgetById(id: Long): Flow<Budget?> = flowOf(budgets.find { it.id == id })
        override suspend fun getBudgetByIdSuspend(id: Long): Budget? = budgets.find { it.id == id }
        override fun getOverallBudget(year: Int, month: Int): Flow<Budget?> =
            flowOf(budgets.find { it.year == year && it.month == month && it.isOverall })
        override fun getCategoryBudget(year: Int, month: Int, categoryId: Long): Flow<Budget?> =
            flowOf(budgets.find { it.year == year && it.month == month && it.categoryId == categoryId })
        override suspend fun saveBudget(budget: Budget): AppResult<Long> = AppResult.Success(budget.id)
        override suspend fun deleteBudget(id: Long): AppResult<Unit> = AppResult.Success(Unit)
        override suspend fun deleteAllBudgets(): AppResult<Unit> = AppResult.Success(Unit)
    }

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

    @Test
    fun `test budget threshold calculation exact boundaries`() = runBlocking {
        val zone = ZoneId.systemDefault()
        val currentYm = YearMonth.now(zone)
        val startOfMonth = currentYm.atDay(1).atStartOfDay(zone).toInstant().toEpochMilli()
        val txDate = startOfMonth + 1000

        val cat = Category(id = 10L, name = "Food", iconName = "food", colorHex = "#FF0000", type = TransactionType.EXPENSE)
        val overallBudget = Budget(id = 1L, categoryId = null, amount = Amount.fromMainUnit(1000), month = currentYm.monthValue, year = currentYm.year)
        val catBudget = Budget(id = 2L, categoryId = 10L, amount = Amount.fromMainUnit(500), month = currentYm.monthValue, year = currentYm.year)

        val fakeBudgets = listOf(overallBudget, catBudget)

        // Test ON_TRACK (< 75% -> 740 spent out of 1000)
        val txs1 = listOf(
            Transaction(id = 1L, amount = Amount.fromMainUnit(740), type = TransactionType.EXPENSE, category = cat, timestamp = txDate)
        )
        val useCase1 = GetBudgetProgressUseCase(
            FakeBudgetRepository(fakeBudgets),
            FakeTransactionRepository(txs1)
        )

        var result: List<BudgetProgress> = emptyList()
        useCase1(currentYm).collect { result = it }

        val overallProgress1 = result.find { it.budget.categoryId == null }
        assertNotNull(overallProgress1)
        assertEquals(Amount.fromMainUnit(740), overallProgress1!!.usedAmount)
        assertEquals(Amount.fromMainUnit(260), overallProgress1.remainingAmount)
        assertEquals(74.0f, overallProgress1.percentageUsed, 0.001f)
        assertEquals(BudgetStatus.ON_TRACK, overallProgress1.status)

        // Test APPROACHING_LIMIT (>= 75% and < 100% -> 750 spent out of 1000)
        val txs2 = listOf(
            Transaction(id = 1L, amount = Amount.fromMainUnit(750), type = TransactionType.EXPENSE, category = cat, timestamp = txDate)
        )
        val useCase2 = GetBudgetProgressUseCase(
            FakeBudgetRepository(fakeBudgets),
            FakeTransactionRepository(txs2)
        )
        useCase2(currentYm).collect { result = it }
        val overallProgress2 = result.find { it.budget.categoryId == null }!!
        assertEquals(BudgetStatus.APPROACHING_LIMIT, overallProgress2.status)

        // Test LIMIT_REACHED (== 100% -> 1000 spent out of 1000)
        val txs3 = listOf(
            Transaction(id = 1L, amount = Amount.fromMainUnit(1000), type = TransactionType.EXPENSE, category = cat, timestamp = txDate)
        )
        val useCase3 = GetBudgetProgressUseCase(
            FakeBudgetRepository(fakeBudgets),
            FakeTransactionRepository(txs3)
        )
        useCase3(currentYm).collect { result = it }
        val overallProgress3 = result.find { it.budget.categoryId == null }!!
        assertEquals(BudgetStatus.LIMIT_REACHED, overallProgress3.status)
        assertEquals(Amount.ZERO, overallProgress3.remainingAmount)

        // Test OVER_BUDGET (> 100% -> 1001 spent out of 1000)
        val txs4 = listOf(
            Transaction(id = 1L, amount = Amount.fromMainUnit(1001), type = TransactionType.EXPENSE, category = cat, timestamp = txDate)
        )
        val useCase4 = GetBudgetProgressUseCase(
            FakeBudgetRepository(fakeBudgets),
            FakeTransactionRepository(txs4)
        )
        useCase4(currentYm).collect { result = it }
        val overallProgress4 = result.find { it.budget.categoryId == null }!!
        assertEquals(BudgetStatus.OVER_BUDGET, overallProgress4.status)
        assertEquals(Amount.ZERO, overallProgress4.remainingAmount)
    }

    @Test
    fun `test category budget isolation`() = runBlocking {
        val zone = ZoneId.systemDefault()
        val currentYm = YearMonth.now(zone)
        val startOfMonth = currentYm.atDay(1).atStartOfDay(zone).toInstant().toEpochMilli()
        val txDate = startOfMonth + 1000

        val cat1 = Category(id = 10L, name = "Food", iconName = "food", colorHex = "#FF0000", type = TransactionType.EXPENSE)
        val cat2 = Category(id = 20L, name = "Travel", iconName = "travel", colorHex = "#00FF00", type = TransactionType.EXPENSE)

        val cat1Budget = Budget(id = 1L, categoryId = 10L, amount = Amount.fromMainUnit(200), month = currentYm.monthValue, year = currentYm.year)
        val cat2Budget = Budget(id = 2L, categoryId = 20L, amount = Amount.fromMainUnit(300), month = currentYm.monthValue, year = currentYm.year)

        val fakeBudgets = listOf(cat1Budget, cat2Budget)

        val txs = listOf(
            Transaction(id = 1L, amount = Amount.fromMainUnit(150), type = TransactionType.EXPENSE, category = cat1, timestamp = txDate),
            Transaction(id = 2L, amount = Amount.fromMainUnit(350), type = TransactionType.EXPENSE, category = cat2, timestamp = txDate)
        )

        val useCase = GetBudgetProgressUseCase(
            FakeBudgetRepository(fakeBudgets),
            FakeTransactionRepository(txs)
        )

        var result: List<BudgetProgress> = emptyList()
        useCase(currentYm).collect { result = it }

        val p1 = result.find { it.budget.categoryId == 10L }!!
        assertEquals(Amount.fromMainUnit(150), p1.usedAmount)
        assertEquals(BudgetStatus.APPROACHING_LIMIT, p1.status) // 150/200 = 75%

        val p2 = result.find { it.budget.categoryId == 20L }!!
        assertEquals(Amount.fromMainUnit(350), p2.usedAmount)
        assertEquals(BudgetStatus.OVER_BUDGET, p2.status) // 350/300 > 100%
    }
}
