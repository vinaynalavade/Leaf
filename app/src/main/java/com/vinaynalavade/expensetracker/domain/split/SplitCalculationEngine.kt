package com.vinaynalavade.expensetracker.domain.split

import com.vinaynalavade.expensetracker.core.model.Amount
import com.vinaynalavade.expensetracker.domain.model.SettlementStatus
import com.vinaynalavade.expensetracker.domain.model.SplitItem
import com.vinaynalavade.expensetracker.domain.model.SplitParticipant

/**
 * Validation result for direct custom split allocations.
 */
data class CustomSplitValidation(
    val isValid: Boolean,
    val allocatedAmount: Amount,
    val remainingAmount: Amount,
    val overallocatedAmount: Amount,
    val errorMessage: String? = null
)

/**
 * Detailed breakdown of a participant's calculated portion in an itemized bill.
 */
data class ParticipantShareDetail(
    val participantName: String,
    val itemizedShare: Amount,
    val sharedRemainingShare: Amount,
    val totalShare: Amount,
    val itemBreakdown: List<Pair<String, Amount>> = emptyList()
)

/**
 * Complete calculation result for item-based custom splitting in Split 2.0.
 */
data class ItemizedSplitCalculationResult(
    val isValid: Boolean,
    val totalBill: Amount,
    val totalAllocatedAmount: Amount,
    val itemizedTotalAmount: Amount,
    val unallocatedRemainingAmount: Amount,
    val overallocatedAmount: Amount,
    val isOverallocated: Boolean,
    val isUnderallocated: Boolean,
    val participantShares: Map<String, Amount>,
    val participantDetails: List<ParticipantShareDetail>,
    val baselineEqualShare: Amount = Amount.ZERO,
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
     * Calculates the share of an individual item for a specific participant.
     */
    fun calculateItemShareForParticipant(item: SplitItem, participantName: String): Amount {
        if (!item.participantNames.any { it.equals(participantName, ignoreCase = true) }) {
            return Amount.ZERO
        }
        if (item.amount.subunits <= 0L) return Amount.ZERO

        if (item.isCustomAllocation) {
            val matchedKey = item.customAllocations.keys.firstOrNull { it.equals(participantName, ignoreCase = true) }
            return if (matchedKey != null) item.customAllocations[matchedKey] ?: Amount.ZERO else Amount.ZERO
        }

        // Equal split among consumers of this item
        val count = item.participantNames.size
        if (count == 0) return Amount.ZERO

        val index = item.participantNames.indexOfFirst { it.equals(participantName, ignoreCase = true) }
        if (index < 0) return Amount.ZERO

        val baseSubunits = item.amount.subunits / count
        val remainder = (item.amount.subunits % count).toInt()
        val extra = if (index < remainder) 1L else 0L
        return Amount(baseSubunits + extra)
    }

    /**
     * Evaluates itemized custom bill splitting with item consumers, custom allocation,
     * base/shared bill distribution, and exact penny/paisa reconciliation.
     *
     * @param totalBill The full bill amount.
     * @param participants All participants in the split.
     * @param items List of itemized products and their assigned consumers.
     * @param sharedRemainingParticipants Participants sharing the unallocated / base portion of the bill.
     */
    fun calculateItemizedSplit(
        totalBill: Amount,
        participants: List<String>,
        items: List<SplitItem>,
        sharedRemainingParticipants: List<String>
    ): ItemizedSplitCalculationResult {
        val distinctParticipants = participants.map { it.trim() }.distinct()
        val baselineEqualShare = if (distinctParticipants.isNotEmpty() && totalBill.subunits > 0L) {
            Amount(totalBill.subunits / distinctParticipants.size)
        } else {
            Amount.ZERO
        }

        if (distinctParticipants.isEmpty() || totalBill.subunits <= 0L) {
            return ItemizedSplitCalculationResult(
                isValid = false,
                totalBill = totalBill,
                totalAllocatedAmount = Amount.ZERO,
                itemizedTotalAmount = Amount.ZERO,
                unallocatedRemainingAmount = totalBill,
                overallocatedAmount = Amount.ZERO,
                isOverallocated = false,
                isUnderallocated = totalBill.subunits > 0L,
                participantShares = distinctParticipants.associateWith { Amount.ZERO },
                participantDetails = distinctParticipants.map {
                    ParticipantShareDetail(it, Amount.ZERO, Amount.ZERO, Amount.ZERO)
                },
                baselineEqualShare = baselineEqualShare,
                errorMessage = if (totalBill.subunits <= 0L) "Please enter an amount greater than 0." else "Please add participants."
            )
        }

        val participantItemSubunits = mutableMapOf<String, Long>()
        val participantBreakdowns = mutableMapOf<String, MutableList<Pair<String, Amount>>>()
        distinctParticipants.forEach {
            participantItemSubunits[it] = 0L
            participantBreakdowns[it] = mutableListOf()
        }

        var totalItemsSubunits = 0L

        // 1. Calculate each item's shares
        for (item in items) {
            val itemSubunits = item.amount.subunits
            if (itemSubunits <= 0L) continue

            val validConsumers = item.participantNames
                .map { it.trim() }
                .filter { p -> distinctParticipants.any { it.equals(p, ignoreCase = true) } }

            if (validConsumers.isEmpty()) continue

            if (item.isCustomAllocation) {
                var customTotal = 0L
                for (consumer in validConsumers) {
                    val pName = distinctParticipants.first { it.equals(consumer, ignoreCase = true) }
                    val customSubunits = item.customAllocations.entries
                        .firstOrNull { it.key.equals(consumer, ignoreCase = true) }?.value?.subunits ?: 0L
                    participantItemSubunits[pName] = (participantItemSubunits[pName] ?: 0L) + customSubunits
                    customTotal += customSubunits
                    if (customSubunits > 0L) {
                        participantBreakdowns[pName]?.add((item.name.ifBlank { "Item" }) to Amount(customSubunits))
                    }
                }
                totalItemsSubunits += if (customTotal > 0L) customTotal else itemSubunits
            } else {
                totalItemsSubunits += itemSubunits
                val count = validConsumers.size
                val base = itemSubunits / count
                val rem = (itemSubunits % count).toInt()

                validConsumers.forEachIndexed { idx, consumer ->
                    val pName = distinctParticipants.first { it.equals(consumer, ignoreCase = true) }
                    val share = base + (if (idx < rem) 1L else 0L)
                    participantItemSubunits[pName] = (participantItemSubunits[pName] ?: 0L) + share
                    participantBreakdowns[pName]?.add((item.name.ifBlank { "Item" }) to Amount(share))
                }
            }
        }

        val diff = totalBill.subunits - totalItemsSubunits
        val isOverallocated = diff < 0L
        val overallocatedAmount = if (isOverallocated) Amount(-diff) else Amount.ZERO

        val participantSharedSubunits = mutableMapOf<String, Long>()
        distinctParticipants.forEach { participantSharedSubunits[it] = 0L }

        val validSharedParticipants = sharedRemainingParticipants
            .map { it.trim() }
            .filter { p -> distinctParticipants.any { it.equals(p, ignoreCase = true) } }

        var remainingAfterDistribution = if (diff > 0L) diff else 0L

        // 2. Distribute remaining amount among shared participants if available
        if (diff > 0L && validSharedParticipants.isNotEmpty()) {
            val count = validSharedParticipants.size
            val base = diff / count
            val rem = (diff % count).toInt()

            validSharedParticipants.forEachIndexed { idx, pName ->
                val canonicalName = distinctParticipants.first { it.equals(pName, ignoreCase = true) }
                val sharedShare = base + (if (idx < rem) 1L else 0L)
                participantSharedSubunits[canonicalName] = sharedShare
            }
            remainingAfterDistribution = 0L
        }

        val isUnderallocated = remainingAfterDistribution > 0L
        val totalAllocatedSubunits = if (isOverallocated) {
            totalItemsSubunits
        } else {
            totalItemsSubunits + (diff - remainingAfterDistribution)
        }

        val isValid = !isOverallocated && !isUnderallocated && totalAllocatedSubunits == totalBill.subunits

        val participantShares = mutableMapOf<String, Amount>()
        val participantDetails = mutableListOf<ParticipantShareDetail>()

        for (p in distinctParticipants) {
            val itemShare = participantItemSubunits[p] ?: 0L
            val sharedShare = participantSharedSubunits[p] ?: 0L
            val totalShare = itemShare + sharedShare
            participantShares[p] = Amount(totalShare)

            participantDetails.add(
                ParticipantShareDetail(
                    participantName = p,
                    itemizedShare = Amount(itemShare),
                    sharedRemainingShare = Amount(sharedShare),
                    totalShare = Amount(totalShare),
                    itemBreakdown = participantBreakdowns[p] ?: emptyList()
                )
            )
        }

        val errorMessage = when {
            isOverallocated -> "Overallocated: Items exceed total bill by ₹${overallocatedAmount.subunits / 100.0}"
            isUnderallocated -> "Remaining to allocate: ₹${remainingAfterDistribution / 100.0}"
            else -> null
        }

        return ItemizedSplitCalculationResult(
            isValid = isValid,
            totalBill = totalBill,
            totalAllocatedAmount = Amount(totalAllocatedSubunits),
            itemizedTotalAmount = Amount(totalItemsSubunits),
            unallocatedRemainingAmount = Amount(remainingAfterDistribution),
            overallocatedAmount = overallocatedAmount,
            isOverallocated = isOverallocated,
            isUnderallocated = isUnderallocated,
            participantShares = participantShares,
            participantDetails = participantDetails,
            baselineEqualShare = baselineEqualShare,
            errorMessage = errorMessage
        )
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
