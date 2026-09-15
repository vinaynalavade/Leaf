package com.vinaynalavade.expensetracker.domain.model

import com.vinaynalavade.expensetracker.core.model.Amount
import java.time.YearMonth

data class CategorySpending(
    val category: Category,
    val totalAmount: Amount,
    val percentageOfTotal: Float,
    val transactionCount: Int
)

data class MonthlyLedgerSummary(
    val yearMonth: YearMonth,
    val openingBalance: Amount,
    val totalIncome: Amount,
    val totalExpense: Amount,
    val ordinaryExpense: Amount,
    val savingsAllocation: Amount,
    val netChange: Amount,
    val closingBalance: Amount,
    val dailyAverageExpense: Amount,
    val previousMonthExpense: Amount? = null,
    val momChangePercentage: Double? = null,
    val transactions: List<Transaction>,
    val expenseBreakdown: List<CategorySpending>,
    val incomeBreakdown: List<CategorySpending>
)
