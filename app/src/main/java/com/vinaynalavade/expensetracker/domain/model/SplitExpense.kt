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
    /** True if the current user paid upfront for the split. */
    val isPaidByMe: Boolean
        get() = paidBy.equals("Me", ignoreCase = true)

    /** The current user's own portion of this shared expense. */
    val userShare: Amount
        get() = participants.firstOrNull { it.isCurrentUser }?.amount ?: Amount.ZERO

    /** All participants other than the current user. */
    val otherParticipants: List<SplitParticipant>
        get() = participants.filterNot { it.isCurrentUser }

    /** Total outstanding amount waiting to be collected from other participants (when user paid). */
    val toCollectAmount: Amount
        get() {
            if (!isPaidByMe) return Amount.ZERO
            val pendingSum = otherParticipants
                .filter { it.isPending }
                .sumOf { it.amount.subunits }
            return Amount(pendingSum)
        }

    /** Total outstanding amount the user owes to the payer (when someone else paid). */
    val toPayAmount: Amount
        get() {
            if (isPaidByMe) return Amount.ZERO
            val userParticipant = participants.firstOrNull { it.isCurrentUser }
            return if (userParticipant != null && userParticipant.isPending) {
                userParticipant.amount
            } else {
                Amount.ZERO
            }
        }

    /** Unsettled amount relevant to the current user (either to collect from others or to pay). */
    val unsettledAmountForUser: Amount
        get() = if (isPaidByMe) toCollectAmount else toPayAmount

    /** True if there is an unsettled balance for the current user. */
    val hasUnsettledForUser: Boolean
        get() = if (isPaidByMe) toCollectAmount.subunits > 0L else toPayAmount.subunits > 0L

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
        get() = if (isPaidByMe) {
            otherParticipants.isNotEmpty() && otherParticipants.all { it.isSettled }
        } else {
            val userParticipant = participants.firstOrNull { it.isCurrentUser }
            userParticipant?.isSettled ?: true
        }

    /** True if all other participants owe the exact same amount. */
    val hasEqualShares: Boolean
        get() {
            val nonPayerShares = otherParticipants.map { it.amount.subunits }
            return nonPayerShares.isNotEmpty() && nonPayerShares.distinct().size == 1
        }
}
