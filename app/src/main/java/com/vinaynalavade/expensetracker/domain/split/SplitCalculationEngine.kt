package com.vinaynalavade.expensetracker.domain.split

import com.vinaynalavade.expensetracker.core.model.Amount
import com.vinaynalavade.expensetracker.domain.model.SettlementStatus
import com.vinaynalavade.expensetracker.domain.model.SplitParticipant

/**
 * Validation result for custom split allocations.
 */
data class CustomSplitValidation(
    val isValid: Boolean,
    val allocatedAmount: Amount,
    val remainingAmount: Amount,
    val overallocatedAmount: Amount,
    val errorMessage: String? = null
)

/**
 * Pure calculation engine for Leaf's Split & Collect module.
 *
 * Operates strictly on integer currency subunits (paise/cents) to ensure 100% precision
 * without floating-point rounding inaccuracies.
 */
object SplitCalculationEngine {

    /**
     * Calculates equal shares among all participants with deterministic penny/paisa reconciliation.
     *
     * Example: ₹100 divided among 3 people:
     * - Participant 0: ₹34 (3333 + 1 paise)
     * - Participant 1: ₹33 (3333 paise)
     * - Participant 2: ₹33 (3333 paise)
     * Total = 34 + 33 + 33 = ₹100 exactly.
     */
    fun calculateEqualSplit(
        totalAmount: Amount,
        participants: List<String>,
        payerName: String = "Me"
    ): List<SplitParticipant> {
        if (participants.isEmpty() || totalAmount.subunits <= 0L) {
            return emptyList()
        }

        val count = participants.size
        val baseSubunits = totalAmount.subunits / count
        val remainder = (totalAmount.subunits % count).toInt()

        return participants.mapIndexed { index, name ->
            val extra = if (index < remainder) 1L else 0L
            val finalSubunits = baseSubunits + extra
            val isCurrentUser = name.equals(payerName, ignoreCase = true) ||
                name.equals("Me", ignoreCase = true) ||
                name.equals("You", ignoreCase = true)

            SplitParticipant(
                name = name.trim(),
                isCurrentUser = isCurrentUser,
                amount = Amount(finalSubunits),
                settlementStatus = SettlementStatus.PENDING
            )
        }
    }

    /**
     * Validates that manually entered custom shares exactly reconcile with the total expense amount.
     */
    fun validateCustomSplit(
        totalAmount: Amount,
        allocatedSubunits: Long
    ): CustomSplitValidation {
        val diff = totalAmount.subunits - allocatedSubunits
        return when {
            diff == 0L -> CustomSplitValidation(
                isValid = true,
                allocatedAmount = Amount(allocatedSubunits),
                remainingAmount = Amount.ZERO,
                overallocatedAmount = Amount.ZERO,
                errorMessage = null
            )
            diff > 0L -> CustomSplitValidation(
                isValid = false,
                allocatedAmount = Amount(allocatedSubunits),
                remainingAmount = Amount(diff),
                overallocatedAmount = Amount.ZERO,
                errorMessage = "Remaining: ₹${Amount(diff).subunits / 100.0}"
            )
            else -> CustomSplitValidation(
                isValid = false,
                allocatedAmount = Amount(allocatedSubunits),
                remainingAmount = Amount.ZERO,
                overallocatedAmount = Amount(-diff),
                errorMessage = "Overallocated: ₹${Amount(-diff).subunits / 100.0}"
            )
        }
    }

    /**
     * Checks if all non-payer participants have the exact same share amount.
     */
    fun hasEqualNonPayerShares(participants: List<SplitParticipant>): Boolean {
        val nonPayers = participants.filterNot { it.isCurrentUser }
        if (nonPayers.isEmpty()) return false
        val distinctAmounts = nonPayers.map { it.amount.subunits }.distinct()
        return distinctAmounts.size == 1
    }
}
