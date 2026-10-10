package com.vinaynalavade.expensetracker

import com.vinaynalavade.expensetracker.core.model.Amount
import com.vinaynalavade.expensetracker.domain.model.ItemizedSplitData
import com.vinaynalavade.expensetracker.domain.model.SplitItem
import com.vinaynalavade.expensetracker.domain.split.SplitItemJsonAdapter
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

class SplitItemJsonAdapterTest {

    @Test
    fun serializeAndDeserialize_preservesAllItemFields() {
        val original = ItemizedSplitData(
            items = listOf(
                SplitItem(
                    id = "item-1",
                    name = "Butter Chicken",
                    amount = Amount.fromSubunits(50000L),
                    amountInput = "500",
                    participantNames = listOf("A", "B"),
                    isCustomAllocation = true,
                    customAllocations = mapOf("A" to Amount.fromSubunits(30000L), "B" to Amount.fromSubunits(20000L)),
                    customAllocationInputs = mapOf("A" to "300", "B" to "200")
                )
            ),
            sharedRemainingParticipantNames = listOf("A", "B", "C"),
            isSharedRemainingDistributed = true
        )

        val json = SplitItemJsonAdapter.toJson(original)
        assertNotNull(json)

        val restored = SplitItemJsonAdapter.fromJson(json)
        assertNotNull(restored)
        assertEquals(1, restored!!.items.size)

        val item = restored.items[0]
        assertEquals("item-1", item.id)
        assertEquals("Butter Chicken", item.name)
        assertEquals(50000L, item.amount.subunits)
        assertEquals("500", item.amountInput)
        assertEquals(listOf("A", "B"), item.participantNames)
        assertTrue(item.isCustomAllocation)
        assertEquals(30000L, item.customAllocations["A"]?.subunits)
        assertEquals(20000L, item.customAllocations["B"]?.subunits)
        assertEquals("300", item.customAllocationInputs["A"])
        assertEquals("200", item.customAllocationInputs["B"])

        assertEquals(listOf("A", "B", "C"), restored.sharedRemainingParticipantNames)
        assertTrue(restored.isSharedRemainingDistributed)
    }

    @Test
    fun fromJson_nullOrBlank_returnsNull() {
        assertNull(SplitItemJsonAdapter.fromJson(null))
        assertNull(SplitItemJsonAdapter.fromJson(""))
        assertNull(SplitItemJsonAdapter.fromJson("   "))
    }
}
