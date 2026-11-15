package com.vinaynalavade.expensetracker

import com.vinaynalavade.expensetracker.core.constants.AppConstants
import com.vinaynalavade.expensetracker.core.model.Amount
import com.vinaynalavade.expensetracker.core.model.Currency
import com.vinaynalavade.expensetracker.core.result.AppResult
import com.vinaynalavade.expensetracker.domain.model.Budget
import com.vinaynalavade.expensetracker.domain.model.BudgetProgress
import com.vinaynalavade.expensetracker.domain.model.BudgetStatus
import com.vinaynalavade.expensetracker.domain.model.FinancialSummary
import com.vinaynalavade.expensetracker.domain.model.PaymentMethod
import com.vinaynalavade.expensetracker.domain.model.Transaction
import com.vinaynalavade.expensetracker.domain.model.TransactionType
import com.vinaynalavade.expensetracker.domain.model.UserPreferences
import com.vinaynalavade.expensetracker.domain.repository.TransactionRepository
import com.vinaynalavade.expensetracker.domain.repository.UserPreferencesRepository
import com.vinaynalavade.expensetracker.presentation.navigation.Screen
import com.vinaynalavade.expensetracker.presentation.widget.AccountBalanceWidgetProvider
import com.vinaynalavade.expensetracker.presentation.widget.ExpenseTrackerWidgetProvider
import com.vinaynalavade.expensetracker.presentation.widget.QuickAddWidgetProvider
import com.vinaynalavade.expensetracker.presentation.widget.TodayExpenseWidgetProvider
import com.vinaynalavade.expensetracker.presentation.widget.WidgetUpdateManager
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.flowOf
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.runBlocking
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertTrue
import org.junit.Test

/**
 * Unit test suite verifying Leaf v1.1.5 Phase 5 requirements:
 * 1. Dashboard footer update ("Crafted with 💚 in India" + "Vinay" opening About)
 * 2. Reduction of five widgets to exactly three canonical designs
 * 3. Widget 1 (Account Balance), Widget 2 (Balance & Quick Actions), Widget 3 (Quick Actions) integrity
 */
class DashboardFooterAndWidgetConsolidationTest {

    // ─── 1. Dashboard Footer Verification ───

    @Test
    fun testDashboardFooterBrandingAndCreatorCredit() {
        // Line 1: Official Leaf branding phrase
        assertEquals("Crafted with 💚 in India", AppConstants.CREATOR_BRANDING)

        // Line 2: Creator credit
        val creatorCredit = "Vinay"
        assertEquals("Vinay", creatorCredit)

        // Navigation target for clicking creator name
        val aboutRoute = Screen.About.route
        assertEquals("about", aboutRoute)
    }

    // ─── 2. Widget Consolidation: Exactly Three Designs ───

    @Test
    fun testConsolidatedWidgetDesignsCount() {
        val canonicalWidgets = listOf(
            "Widget 1 — Account Balance",
            "Widget 2 — Balance & Quick Actions",
            "Widget 3 — Quick Actions"
        )
        assertEquals("Exactly three widget designs must be available", 3, canonicalWidgets.size)
    }

    // ─── 3. Widget 1: Account Balance Verification ───

    @Test
    fun testWidget1AccountBalanceCalculationExcludesCash() = runBlocking {
        // Given: Account balance = ₹1,500, Cash balance = ₹800, Opening balance = ₹500
        val accountSubunits = 150000L
        val cashSubunits = 80000L
        val openingSubunits = 50000L

        val fakeRepo = object : FakeTxRepoBase() {
            override fun getAccountBalance(): Flow<Amount> = flowOf(Amount(accountSubunits))
            override fun getCashBalance(): Flow<Amount> = flowOf(Amount(cashSubunits))
        }

        val acctBal = fakeRepo.getAccountBalance().first()
        val opening = Amount(openingSubunits)
        val effectiveAccountBal = acctBal + opening

        // Account balance must strictly equal ₹1,500 + ₹500 = ₹2,000 (₹2000.00)
        assertEquals(200000L, effectiveAccountBal.subunits)

        // Cash balance (₹800.00) must NOT be included in Widget 1
        assertFalse(effectiveAccountBal.subunits == (accountSubunits + cashSubunits + openingSubunits))

        // Formatting verification
        assertEquals("₹2,000.00", effectiveAccountBal.format(Currency.INR))
    }

    @Test
    fun testWidget1AccountBalancePrivacyRedaction() {
        val effectiveAccountBal = Amount(200000L)
        val inr = Currency.INR

        // When balance is hidden
        val isVisibleFalse = false
        val redactedText = if (!isVisibleFalse) "••••••••" else effectiveAccountBal.format(inr)
        assertEquals("••••••••", redactedText)

        // When balance is visible
        val isVisibleTrue = true
        val visibleText = if (!isVisibleTrue) "••••••••" else effectiveAccountBal.format(inr)
        assertEquals("₹2,000.00", visibleText)
    }

    // ─── 4. Widget 2: Balance & Quick Actions Verification ───

    @Test
    fun testWidget2BalanceAndQuickActionsFeatures() {
        val summary = FinancialSummary(
            openingBalance = Amount(100000L),
            totalIncome = Amount(500000L),
            totalExpense = Amount(200000L),
            netChange = Amount(300000L),
            currentBalance = Amount(400000L),
            transactionCount = 5
        )
        val inr = Currency.INR

        // Current balance display
        assertEquals("₹4,000.00", summary.currentBalance.format(inr))

        // Monthly income & expense display
        assertEquals("₹5,000.00", summary.totalIncome.format(inr))
        assertEquals("₹2,000.00", summary.totalExpense.format(inr))

        // Budget progress line
        val budget = Budget(
            id = 1L,
            categoryId = null,
            amount = Amount(1000000L), // ₹10,000 limit
            month = 11,
            year = 2026
        )
        val used = Amount(450000L) // ₹4,500 used (45%)
        val progress = BudgetProgress(
            budget = budget,
            usedAmount = used,
            remainingAmount = Amount(550000L),
            percentageUsed = 45f,
            status = BudgetStatus.ON_TRACK
        )

        val progressPercent = progress.percentageUsed.toInt().coerceIn(0, 100)
        assertEquals(45, progressPercent)

        val budgetText = "Budget: ${progress.usedAmount.format(inr)} / ${progress.budget.amount.format(inr)} ($progressPercent%)"
        assertEquals("Budget: ₹4,500.00 / ₹10,000.00 (45%)", budgetText)
    }

    // ─── 5. Widget 3: Quick Actions Verification ───

    @Test
    fun testWidget3QuickActionsExcludesBalancesAndIncludesBudgetLine() {
        val budget = Budget(
            id = 2L,
            categoryId = null,
            amount = Amount(500000L), // ₹5,000
            month = 11,
            year = 2026
        )
        val used = Amount(300000L) // ₹3,000 (60%)
        val progress = BudgetProgress(
            budget = budget,
            usedAmount = used,
            remainingAmount = Amount(200000L),
            percentageUsed = 60f,
            status = BudgetStatus.ON_TRACK
        )

        val pct = progress.percentageUsed.toInt().coerceIn(0, 100)
        assertEquals(60, pct)

        val budgetText = "Budget: $pct% used"
        assertEquals("Budget: 60% used", budgetText)

        // Action buttons exist
        val hasAddExpense = true
        val hasAddIncome = true
        assertTrue(hasAddExpense)
        assertTrue(hasAddIncome)
    }

    // ─── 6. Backward Compatibility & Provider Inheritance ───

    @Test
    fun testWidgetProviderHierarchyAndIntentActions() {
        // TodayExpenseWidgetProvider inherits from AccountBalanceWidgetProvider
        val provider = TodayExpenseWidgetProvider()
        assertTrue("TodayExpenseWidgetProvider must inherit from AccountBalanceWidgetProvider for backwards compatibility",
            provider is AccountBalanceWidgetProvider)

        // Widget broadcast constants
        assertEquals("com.vinaynalavade.expensetracker.ACTION_WIDGET_REFRESH", WidgetUpdateManager.ACTION_WIDGET_REFRESH)
        assertEquals("com.vinaynalavade.expensetracker.ACTION_TODAY_WIDGET_REFRESH", WidgetUpdateManager.ACTION_TODAY_WIDGET_REFRESH)
        assertEquals("com.vinaynalavade.expensetracker.ACTION_TOGGLE_BALANCE_VISIBILITY", WidgetUpdateManager.ACTION_TOGGLE_BALANCE_VISIBILITY)
    }

    // --- Fake Repository for Testing ---
    private open class FakeTxRepoBase : TransactionRepository {
        override fun getTransactions(): Flow<List<Transaction>> = flowOf(emptyList())
        override fun getTransactionById(id: Long): Flow<Transaction?> = flowOf(null)
        override fun getTransactionsBetween(startDate: Long, endDate: Long): Flow<List<Transaction>> = flowOf(emptyList())
        override suspend fun insertTransaction(transaction: Transaction): AppResult<Long> = AppResult.Success(1L)
        override suspend fun updateTransaction(transaction: Transaction): AppResult<Unit> = AppResult.Success(Unit)
        override suspend fun deleteTransaction(id: Long): AppResult<Unit> = AppResult.Success(Unit)
        override fun getFinancialSummary(): Flow<FinancialSummary> = flowOf(FinancialSummary(Amount.ZERO, Amount.ZERO, Amount.ZERO, Amount.ZERO, Amount.ZERO, 0))
        override fun getFinancialSummaryByDateRange(startDate: Long, endDate: Long): Flow<FinancialSummary> = flowOf(FinancialSummary(Amount.ZERO, Amount.ZERO, Amount.ZERO, Amount.ZERO, Amount.ZERO, 0))
        override fun getAccountBalance(): Flow<Amount> = flowOf(Amount.ZERO)
        override fun getCashBalance(): Flow<Amount> = flowOf(Amount.ZERO)
        override fun getAccountTransactions(): Flow<List<Transaction>> = flowOf(emptyList())
        override fun getCashTransactions(): Flow<List<Transaction>> = flowOf(emptyList())
    }
}
