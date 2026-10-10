package com.vinaynalavade.expensetracker.domain.model

import com.vinaynalavade.expensetracker.core.model.Amount
import java.util.UUID

/**
 * Domain model representing an individual product/item in an itemized custom split bill.
 *
 * @param id Unique identifier for the item.
 * @param name Name or description of the item (e.g. "Pizza", "Product 1").
 * @param amount Total cost of this item.
 * @param amountInput Raw text entered in the amount field.
 * @param participantNames Names of participants who consumed this item.
 * @param isCustomAllocation Whether this item is split custom (unequally) rather than equally among consumers.
 * @param customAllocations Specific amounts for participants when [isCustomAllocation] is true.
 * @param customAllocationInputs Raw text input for custom allocations.
 */
data class SplitItem(
    val id: String = UUID.randomUUID().toString(),
    val name: String = "",
    val amount: Amount = Amount.ZERO,
    val amountInput: String = "",
    val participantNames: List<String> = emptyList(),
    val isCustomAllocation: Boolean = false,
    val customAllocations: Map<String, Amount> = emptyMap(),
    val customAllocationInputs: Map<String, String> = emptyMap()
)

/**
 * Representation of itemized split state to persist alongside a split expense.
 */
data class ItemizedSplitData(
    val items: List<SplitItem> = emptyList(),
    val sharedRemainingParticipantNames: List<String> = emptyList(),
    val isSharedRemainingDistributed: Boolean = false
)
