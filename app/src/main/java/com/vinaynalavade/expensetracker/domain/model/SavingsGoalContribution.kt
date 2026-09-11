package com.vinaynalavade.expensetracker.domain.model

import com.vinaynalavade.expensetracker.core.model.Amount

/**
 * Domain model representing a manually tracked goal-progress contribution.
 */
data class SavingsGoalContribution(
    val id: Long = 0L,
    val goalId: Long,
    val amount: Amount,
    val note: String? = null,
    val timestamp: Long = System.currentTimeMillis(),
    val createdAt: Long = System.currentTimeMillis()
)
