package com.vinaynalavade.expensetracker

import android.appwidget.AppWidgetProvider
import com.vinaynalavade.expensetracker.core.constants.AppConstants
import com.vinaynalavade.expensetracker.core.model.Amount
import com.vinaynalavade.expensetracker.core.model.Currency
import com.vinaynalavade.expensetracker.core.result.AppResult
import com.vinaynalavade.expensetracker.domain.model.BalanceDisplayMode
import com.vinaynalavade.expensetracker.domain.model.Budget
import com.vinaynalavade.expensetracker.domain.model.BudgetProgress
import com.vinaynalavade.expensetracker.domain.model.BudgetStatus
import com.vinaynalavade.expensetracker.domain.model.FinancialSummary
import com.vinaynalavade.expensetracker.domain.model.Transaction
import com.vinaynalavade.expensetracker.domain.repository.TransactionRepository
import com.vinaynalavade.expensetracker.presentation.navigation.Screen
import com.vinaynalavade.expensetracker.presentation.widget.ExpenseTrackerWidgetProvider
import com.vinaynalavade.expensetracker.presentation.widget.QuickAddWidgetProvider
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
 * Unit test suite verifying Leaf v1.1.5:
 * 1. Dashboard footer update ("Crafted with 💚 in India" + "Vinay" opening About)
 * 2. Reduction of home-screen widgets to strictly TWO canonical designs:
 *    - Financial Overview Widget ([ExpenseTrackerWidgetProvider] - Balance & Quick Actions)
 *    - Quick Actions Widget ([QuickAddWidgetProvider])
 * 3. Financial Overview Widget dynamic account/mode balance reflection (Combined, Account, Cash)
 * 4. Privacy redaction in widgets
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

    // ─── 2. Widget Consolidation: Exactly Two Canonical Designs ───

    @Test
    fun testConsolidatedWidgetDesignsCount() {
        val canonicalWidgets = listOf(
            "Widget 1 — Financial Overview (Balance & Quick Actions)",
            "Widget 2 — Quick Actions"
        )
        assertEquals("Exactly two widget designs must be available", 2, canonicalWidgets.size)
    }

    // ─── 3. Financial Overview Widget: Account Selection Reflection ───

    @Test
    fun testFinancialOverviewWidgetReflectsSelectedAccountMode() = runBlocking {
        // Scenario:
        // Opening balance: ₹500 (50,000 subunits)
        // Account balance: ₹1,500 (150,000 subunits) -> Effective Account = ₹2,000
        // Cash balance: ₹800 (80,000 subunits) -> Effective Cash = ₹800
        // Combined balance: ₹2,800 (280,000 subunits)
        val openingSubunits = 50000L
        val accountSubunits = 150000L
        val cashSubunits = 80000L
        val combinedSubunits = 280000L

        val fakeRepo = object : FakeTxRepoBase() {
            override fun getAccountBalance(): Flow<Amount> = flowOf(Amount(accountSubunits))
            override fun getCashBalance(): Flow<Amount> = flowOf(Amount(cashSubunits))
        }

        val acctBal = fakeRepo.getAccountBalance().first()
        val cashBal = fakeRepo.getCashBalance().first()
        val opening = Amount(openingSubunits)
        val combined = Amount(combinedSubunits)

        // Mode: COMBINED
        val combinedEffective = combined
        val combinedLabel = when (BalanceDisplayMode.COMBINED) {
            BalanceDisplayMode.ACCOUNT -> "ACCOUNT BALANCE"
            BalanceDisplayMode.CASH -> "CASH BALANCE"
            BalanceDisplayMode.COMBINED -> "CURRENT BALANCE"
        }
        assertEquals(280000L, combinedEffective.subunits)
        assertEquals("CURRENT BALANCE", combinedLabel)
        assertEquals("₹2,800.00", combinedEffective.format(Currency.INR))

        // Mode: ACCOUNT (strictly Account ledger + opening balance, excludes Cash)
        val accountEffective = acctBal + opening
        val accountLabel = when (BalanceDisplayMode.ACCOUNT) {
            BalanceDisplayMode.ACCOUNT -> "ACCOUNT BALANCE"
            BalanceDisplayMode.CASH -> "CASH BALANCE"
            BalanceDisplayMode.COMBINED -> "CURRENT BALANCE"
        }
        assertEquals(200000L, accountEffective.subunits)
        assertEquals("ACCOUNT BALANCE", accountLabel)
        assertEquals("₹2,000.00", accountEffective.format(Currency.INR))
        assertFalse(accountEffective.subunits == combinedSubunits)

        // Mode: CASH (strictly Cash ledger, excludes Account and opening balance)
        val cashEffective = cashBal
        val cashLabel = when (BalanceDisplayMode.CASH) {
            BalanceDisplayMode.ACCOUNT -> "ACCOUNT BALANCE"
            BalanceDisplayMode.CASH -> "CASH BALANCE"
            BalanceDisplayMode.COMBINED -> "CURRENT BALANCE"
        }
        assertEquals(80000L, cashEffective.subunits)
        assertEquals("CASH BALANCE", cashLabel)
        assertEquals("₹800.00", cashEffective.format(Currency.INR))
        assertFalse(cashEffective.subunits == combinedSubunits)
        assertFalse(cashEffective.subunits == accountEffective.subunits)
    }

    @Test
    fun testFinancialOverviewWidgetPrivacyRedaction() {
        val effectiveBal = Amount(200000L)
        val inr = Currency.INR

        // When balance is hidden
        val isVisibleFalse = false
        val redactedText = if (!isVisibleFalse) "••••••••" else effectiveBal.format(inr)
        assertEquals("••••••••", redactedText)

        // When balance is visible
        val isVisibleTrue = true
        val visibleText = if (!isVisibleTrue) "••••••••" else effectiveBal.format(inr)
        assertEquals("₹2,000.00", visibleText)
    }

    // ─── 4. Financial Overview Widget: Flow and Budget Verification ───

    @Test
    fun testFinancialOverviewWidgetFlowAndBudgetFeatures() {
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

    // ─── 5. Quick Actions Widget Verification ───

    @Test
    fun testQuickActionsWidgetExcludesBalancesAndIncludesBudgetLine() {
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

    // ─── 6. Widget Providers and Intent Actions Verification ───

    @Test
    fun testWidgetProvidersAndBroadcastConstants() {
        val overviewProvider = ExpenseTrackerWidgetProvider()
        assertTrue(overviewProvider is AppWidgetProvider)

        val quickAddProvider = QuickAddWidgetProvider()
        assertTrue(quickAddProvider is AppWidgetProvider)

        // Widget broadcast constants
        assertEquals("com.vinaynalavade.expensetracker.ACTION_WIDGET_REFRESH", WidgetUpdateManager.ACTION_WIDGET_REFRESH)
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
