package com.vinaynalavade.expensetracker.domain.model

data class MonthlySpendingPoint(
    val yearMonth: String, // e.g. "Oct 2023" or "2023-10"
    val epochMonthStart: Long,
    val totalExpense: Double,
    val totalIncome: Double,
    val epochMonthEnd: Long = 0L,
    val transactions: List<Transaction> = emptyList()
)

data class CategorySpendingSummary(
    val categoryId: Long?,
    val categoryName: String,
    val categoryIcon: String,
    val categoryColorHex: String,
    val totalAmount: Double,
    val percentageOfTotal: Double,
    val transactions: List<Transaction> = emptyList()
)

data class SpendingTrendData(
    val monthlyPoints: List<MonthlySpendingPoint>,
    val averageMonthlyExpense: Double,
    val monthOverMonthGrowthRate: Double, // e.g. +5.2% or -12.0%
    val categoryBreakdown: List<CategorySpendingSummary>
)
