package com.vinaynalavade.expensetracker.domain.model

import com.vinaynalavade.expensetracker.core.model.Amount

/**
 * Domain model representing a target-driven savings goal.
 *
 * Progress and completion status are derived dynamically from tracked contributions.
 */
data class SavingsGoal(
    val id: Long = 0L,
    val name: String,
    val targetAmount: Amount,
    val targetDate: Long? = null,
    val note: String? = null,
    val iconName: String = "savings",
    val colorHex: String = "#10B981",
    val isArchived: Boolean = false,
    val contributions: List<SavingsGoalContribution> = emptyList(),
    val createdAt: Long = System.currentTimeMillis(),
    val updatedAt: Long = System.currentTimeMillis()
) {
    /** Total amount saved so far derived from contributions. */
    val currentSavedAmount: Amount
        get() = Amount(contributions.sumOf { it.amount.subunits })

    /** Remaining amount to reach target. */
    val remainingAmount: Amount
        get() = Amount(maxOf(0L, targetAmount.subunits - currentSavedAmount.subunits))

    /** Progress percentage (0% to 100%). */
    val progressPercentage: Float
        get() = if (targetAmount.subunits > 0L) {
            minOf(100f, (currentSavedAmount.subunits.toFloat() / targetAmount.subunits.toFloat()) * 100f)
        } else {
            0f
        }

    /** Dynamically derived completion status. */
    val isCompleted: Boolean
        get() = targetAmount.subunits > 0L && currentSavedAmount.subunits >= targetAmount.subunits
}
