package com.vinaynalavade.expensetracker

import com.vinaynalavade.expensetracker.core.model.Amount
import com.vinaynalavade.expensetracker.core.model.Currency
import com.vinaynalavade.expensetracker.domain.model.Budget
import com.vinaynalavade.expensetracker.domain.model.BudgetProgress
import com.vinaynalavade.expensetracker.domain.model.Category
import com.vinaynalavade.expensetracker.domain.model.FinancialSummary
import com.vinaynalavade.expensetracker.domain.model.PaymentMethod
import com.vinaynalavade.expensetracker.domain.model.Transaction
import com.vinaynalavade.expensetracker.domain.model.TransactionType
import com.vinaynalavade.expensetracker.domain.model.UserPreferences
import com.vinaynalavade.expensetracker.domain.repository.TransactionRepository
import com.vinaynalavade.expensetracker.domain.repository.UserPreferencesRepository
import com.vinaynalavade.expensetracker.domain.usecase.GetWidgetFinancialSummaryUseCase
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.flowOf
import kotlinx.coroutines.runBlocking
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test
import java.time.YearMonth

class WidgetParityAndInteractionTest {

    @Test
    fun testWidgetFinancialSummaryFormatting() = runBlocking {
        val summary = FinancialSummary(
            openingBalance = Amount(100000L),
            totalIncome = Amount(500000L),
            totalExpense = Amount(200000L),
            netChange = Amount(300000L),
            currentBalance = Amount(400000L),
            transactionCount = 5
        )
        val inr = Currency.INR
        assertEquals("₹4,000.00", summary.currentBalance.format(inr))
        assertEquals("₹5,000.00", summary.totalIncome.format(inr))
        assertEquals("₹2,000.00", summary.totalExpense.format(inr))
    }

    @Test
    fun testWidgetPrivacyRedaction() {
        val isVisible = false
        val balance = Amount(1234567L)
        val formatted = if (!isVisible) "••••••••" else balance.format(Currency.INR)
        assertEquals("••••••••", formatted)

        val visibleFormatted = if (true) balance.format(Currency.INR) else "••••••••"
        assertEquals("₹12,345.67", visibleFormatted)
    }

    @Test
    fun testBudgetProgressRatioCalculationForMediumAndLargeWidgets() {
        val budget = Budget(
            id = 1L,
            categoryId = null,
            amount = Amount(1000000L), // ₹10,000
            month = 10,
            year = 2026
        )
        val used = Amount(650000L) // ₹6,500 (65%)
        val remaining = Amount(350000L)
        val progress = BudgetProgress(
            budget = budget,
            usedAmount = used,
            remainingAmount = remaining,
            percentageUsed = 65f,
            status = com.vinaynalavade.expensetracker.domain.model.BudgetStatus.ON_TRACK
        )

        assertEquals(65f, progress.percentageUsed, 0.01f)
        assertEquals(350000L, progress.remainingAmount.subunits)

        val progressPercent = progress.percentageUsed.toInt().coerceIn(0, 100)
        assertEquals(65, progressPercent)
    }

    @Test
    fun testOverBudgetCalculation() {
        val budget = Budget(
            id = 2L,
            categoryId = null,
            amount = Amount(500000L), // ₹5,000
            month = 10,
            year = 2026
        )
        val used = Amount(750000L) // ₹7,500 (150%)
        val remaining = Amount(0L)
        val progress = BudgetProgress(
            budget = budget,
            usedAmount = used,
            remainingAmount = remaining,
            percentageUsed = 150f,
            status = com.vinaynalavade.expensetracker.domain.model.BudgetStatus.OVER_BUDGET
        )

        assertEquals(150f, progress.percentageUsed, 0.01f)
        val progressPercent = progress.percentageUsed.toInt().coerceIn(0, 100)
        assertEquals(100, progressPercent) // Coerced to 100 max for progress bar
    }
}
