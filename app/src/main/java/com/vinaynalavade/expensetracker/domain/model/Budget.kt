package com.vinaynalavade.expensetracker.domain.model

import com.vinaynalavade.expensetracker.core.model.Amount

/**
 * Status representation of a budget relative to current spending.
 */
enum class BudgetStatus {
    ON_TRACK,
    APPROACHING_LIMIT,
    LIMIT_REACHED,
    OVER_BUDGET
}

/**
 * Domain model representing a monthly overall or category spending budget.
 */
data class Budget(
    val id: Long = 0L,
    val categoryId: Long? = null,
    val category: Category? = null,
    val amount: Amount,
    val month: Int,
    val year: Int,
    val createdAt: Long = System.currentTimeMillis(),
    val updatedAt: Long = System.currentTimeMillis()
) {
    val isOverall: Boolean
        get() = categoryId == null
}

/**
 * Calculated progress of a budget for a specific month.
 */
data class BudgetProgress(
    val budget: Budget,
    val usedAmount: Amount,
    val remainingAmount: Amount,
    val percentageUsed: Float,
    val status: BudgetStatus
)
