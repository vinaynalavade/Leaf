package com.vinaynalavade.expensetracker.domain.model

import com.vinaynalavade.expensetracker.core.model.Amount

/**
 * Domain model representing a shared split expense.
 *
 * Designed to cleanly isolate shared expense calculation and collection from
 * regular personal ledger transactions, preventing any accidental double-counting.
 */
data class SplitExpense(
    val id: Long = 0L,
    val title: String,
    val totalAmount: Amount,
    val date: Long,
    val categoryId: Long,
    val category: Category? = null,
    val paidBy: String = "Me",
    val splitMethod: SplitMethod = SplitMethod.EQUAL,
    val qrImagePath: String? = null,
    val addToTransactions: Boolean = false,
    val expenseTransactionId: Long? = null,
    val paymentMethod: PaymentMethod = PaymentMethod.CASH,
    val groupId: Long? = null,
    val participants: List<SplitParticipant> = emptyList(),
    val createdAt: Long = date,
    val updatedAt: Long = date
) {
    /** The current user's own portion of this shared expense. */
    val userShare: Amount
        get() = participants.firstOrNull { it.isCurrentUser }?.amount ?: Amount.ZERO

    /** All participants other than the current user (those who owe money). */
    val otherParticipants: List<SplitParticipant>
        get() = participants.filterNot { it.isCurrentUser }

    /** Total outstanding amount waiting to be collected from other participants. */
    val toCollectAmount: Amount
        get() {
            val pendingSum = otherParticipants
                .filter { it.isPending }
                .sumOf { it.amount.subunits }
            return Amount(pendingSum)
        }

    /** Total amount that has been collected / settled so far from other participants. */
    val collectedAmount: Amount
        get() {
            val settledSum = otherParticipants
                .filter { it.isSettled }
                .sumOf { it.amount.subunits }
            return Amount(settledSum)
        }

    /** Total amount allocated to all other participants combined. */
    val totalOtherShares: Amount
        get() {
            val otherSum = otherParticipants.sumOf { it.amount.subunits }
            return Amount(otherSum)
        }

    /** True if all other participants have settled their shares. */
    val isFullySettled: Boolean
        get() = otherParticipants.isNotEmpty() && otherParticipants.all { it.isSettled }

    /** True if all other participants owe the exact same amount. */
    val hasEqualShares: Boolean
        get() {
            val nonPayerShares = otherParticipants.map { it.amount.subunits }
            return nonPayerShares.isNotEmpty() && nonPayerShares.distinct().size == 1
        }
}
