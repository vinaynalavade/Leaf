package com.vinaynalavade.expensetracker.domain.model

import com.vinaynalavade.expensetracker.core.model.Amount

/**
 * Domain model representing a participant in a split expense.
 *
 * @param id Unique participant identifier.
 * @param splitExpenseId Reference to the parent split expense.
 * @param name Name of the participant.
 * @param isCurrentUser True if this participant is the current user ("Me").
 * @param amount The individual share owed/allocated to this participant.
 * @param settlementStatus Current settlement state (PENDING or SETTLED).
 * @param settledAt Timestamp when the share was marked as settled, or null if pending.
 */
data class SplitParticipant(
    val id: Long = 0L,
    val splitExpenseId: Long = 0L,
    val name: String,
    val isCurrentUser: Boolean = false,
    val amount: Amount,
    val settlementStatus: SettlementStatus = SettlementStatus.PENDING,
    val settledAt: Long? = null
) {
    val isSettled: Boolean get() = settlementStatus == SettlementStatus.SETTLED
    val isPending: Boolean get() = settlementStatus == SettlementStatus.PENDING
}
