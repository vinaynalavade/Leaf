package com.vinaynalavade.expensetracker

import com.vinaynalavade.expensetracker.core.model.Amount
import com.vinaynalavade.expensetracker.core.model.Currency
import com.vinaynalavade.expensetracker.domain.model.SettlementStatus
import com.vinaynalavade.expensetracker.domain.model.SplitItem
import com.vinaynalavade.expensetracker.domain.model.SplitParticipant
import com.vinaynalavade.expensetracker.domain.split.SplitCalculationEngine
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class SplitCalculationEngineTest {

    // --- TEST 1: Real-world Overallocated Inconsistent Edge Case ---
    @Test
    fun test1_realWorldOverallocated_catchesInconsistencyAndPreventsCompletion() {
        // Total bill = ₹1,000.00 (100000 subunits)
        // Items: ₹500 (A), ₹250 (A+B), ₹150 (C), ₹140 (D) => Total = ₹1,040.00
        val totalBill = Amount.fromSubunits(100000L)
        val participants = listOf("A", "B", "C", "D", "E")
        val items = listOf(
            SplitItem(id = "1", name = "Product 1", amount = Amount.fromSubunits(50000L), participantNames = listOf("A")),
            SplitItem(id = "2", name = "Product 2", amount = Amount.fromSubunits(25000L), participantNames = listOf("A", "B")),
            SplitItem(id = "3", name = "Product 3", amount = Amount.fromSubunits(15000L), participantNames = listOf("C")),
            SplitItem(id = "4", name = "Product 4", amount = Amount.fromSubunits(14000L), participantNames = listOf("D"))
        )

        val result = SplitCalculationEngine.calculateItemizedSplit(
            totalBill = totalBill,
            participants = participants,
            items = items,
            sharedRemainingParticipants = emptyList()
        )

        assertFalse("Must not be valid when items exceed bill", result.isValid)
        assertTrue("Must be flagged as overallocated", result.isOverallocated)
        assertEquals(Amount.fromSubunits(4000L), result.overallocatedAmount) // Over by ₹40.00
        assertEquals(Amount.fromSubunits(104000L), result.itemizedTotalAmount)
        assertTrue(result.errorMessage?.contains("Overallocated") == true)
    }

    // --- TEST 2: Items Total Exactly Bill ---
    @Test
    fun test2_itemsTotalExactlyBill_validatesAndReconcilesToPaisa() {
        val totalBill = Amount.fromSubunits(100000L) // ₹1,000.00
        val participants = listOf("A", "B", "C", "D", "E")
        val items = listOf(
            SplitItem(id = "1", name = "Product 1", amount = Amount.fromSubunits(50000L), participantNames = listOf("A")),
            SplitItem(id = "2", name = "Product 2", amount = Amount.fromSubunits(25000L), participantNames = listOf("A", "B")),
            SplitItem(id = "3", name = "Product 3", amount = Amount.fromSubunits(15000L), participantNames = listOf("C")),
            SplitItem(id = "4", name = "Product 4", amount = Amount.fromSubunits(10000L), participantNames = listOf("D"))
        )

        val result = SplitCalculationEngine.calculateItemizedSplit(
            totalBill = totalBill,
            participants = participants,
            items = items,
            sharedRemainingParticipants = emptyList()
        )

        assertTrue(result.isValid)
        assertFalse(result.isOverallocated)
        assertFalse(result.isUnderallocated)
        assertEquals(totalBill, result.totalAllocatedAmount)

        val sumCalculated = result.participantShares.values.sumOf { it.subunits }
        assertEquals(100000L, sumCalculated)
        assertEquals(Amount.fromSubunits(62500L), result.participantShares["A"]) // 500 + 125
        assertEquals(Amount.fromSubunits(12500L), result.participantShares["B"]) // 125
        assertEquals(Amount.fromSubunits(15000L), result.participantShares["C"]) // 150
        assertEquals(Amount.fromSubunits(10000L), result.participantShares["D"]) // 100
        assertEquals(Amount.ZERO, result.participantShares["E"]) // 0
    }

    // --- TEST 3: Shared Item Between Multiple People ---
    @Test
    fun test3_sharedItem_dividesEquallyBetweenConsumers() {
        val item = SplitItem(
            id = "item-2",
            name = "Product 2",
            amount = Amount.fromSubunits(25000L), // ₹250.00
            participantNames = listOf("A", "B")
        )

        val shareA = SplitCalculationEngine.calculateItemShareForParticipant(item, "A")
        val shareB = SplitCalculationEngine.calculateItemShareForParticipant(item, "B")
        val shareC = SplitCalculationEngine.calculateItemShareForParticipant(item, "C")

        assertEquals(Amount.fromSubunits(12500L), shareA) // ₹125.00
        assertEquals(Amount.fromSubunits(12500L), shareB) // ₹125.00
        assertEquals(Amount.ZERO, shareC) // Not a consumer
    }

    // --- TEST 4: Custom Allocation for Item ---
    @Test
    fun test4_customItemAllocation_allocatesSpecifiedAmounts() {
        val item = SplitItem(
            id = "item-custom",
            name = "Special Item",
            amount = Amount.fromSubunits(50000L), // ₹500.00
            participantNames = listOf("A", "B"),
            isCustomAllocation = true,
            customAllocations = mapOf(
                "A" to Amount.fromSubunits(30000L), // ₹300.00
                "B" to Amount.fromSubunits(20000L)  // ₹200.00
            )
        )

        val shareA = SplitCalculationEngine.calculateItemShareForParticipant(item, "A")
        val shareB = SplitCalculationEngine.calculateItemShareForParticipant(item, "B")

        assertEquals(Amount.fromSubunits(30000L), shareA)
        assertEquals(Amount.fromSubunits(20000L), shareB)
    }

    // --- TEST 5: Decimal and Paisa Precision ---
    @Test
    fun test5_decimalPaisaValues_reconcilesWithoutFloatingPointErrors() {
        val totalBill = Amount.fromSubunits(10050L) // ₹100.50
        val participants = listOf("A", "B")
        val items = listOf(
            SplitItem(
                id = "item-decimal",
                name = "Snacks",
                amount = Amount.fromSubunits(10050L),
                participantNames = listOf("A", "B")
            )
        )

        val result = SplitCalculationEngine.calculateItemizedSplit(
            totalBill = totalBill,
            participants = participants,
            items = items,
            sharedRemainingParticipants = emptyList()
        )

        assertTrue(result.isValid)
        assertEquals(Amount.fromSubunits(5025L), result.participantShares["A"]) // ₹50.25
        assertEquals(Amount.fromSubunits(5025L), result.participantShares["B"]) // ₹50.25
        assertEquals(10050L, result.totalAllocatedAmount.subunits)
    }

    // --- TEST 6: Editing an Item Recalculates Affected Participants ---
    @Test
    fun test6_editingItemRecalculatesAffectedParticipants() {
        val totalBill = Amount.fromSubunits(100000L)
        val participants = listOf("A", "B")
        val itemOriginal = SplitItem(id = "1", name = "Item 1", amount = Amount.fromSubunits(60000L), participantNames = listOf("A"))

        val resultBefore = SplitCalculationEngine.calculateItemizedSplit(
            totalBill = totalBill,
            participants = participants,
            items = listOf(itemOriginal),
            sharedRemainingParticipants = emptyList()
        )
        assertEquals(Amount.fromSubunits(60000L), resultBefore.participantShares["A"])

        // Edit item amount from ₹600.00 to ₹700.00
        val itemEdited = itemOriginal.copy(amount = Amount.fromSubunits(70000L))
        val resultAfter = SplitCalculationEngine.calculateItemizedSplit(
            totalBill = totalBill,
            participants = participants,
            items = listOf(itemEdited),
            sharedRemainingParticipants = emptyList()
        )
        assertEquals(Amount.fromSubunits(70000L), resultAfter.participantShares["A"])
        assertEquals(Amount.fromSubunits(30000L), resultAfter.unallocatedRemainingAmount)
    }

    // --- TEST 7: Removing a Participant Updates Items Safely ---
    @Test
    fun test7_removingParticipantUpdatesItemsSafely() {
        val originalConsumers = listOf("A", "B", "C")
        val item = SplitItem(id = "1", amount = Amount.fromSubunits(30000L), participantNames = originalConsumers)

        // Participant "C" is removed from the split
        val remainingParticipants = listOf("A", "B")
        val updatedItemConsumers = item.participantNames.filter { it in remainingParticipants }
        val updatedItem = item.copy(participantNames = updatedItemConsumers)

        val result = SplitCalculationEngine.calculateItemizedSplit(
            totalBill = Amount.fromSubunits(30000L),
            participants = remainingParticipants,
            items = listOf(updatedItem),
            sharedRemainingParticipants = emptyList()
        )

        assertTrue(result.isValid)
        assertEquals(Amount.fromSubunits(15000L), result.participantShares["A"])
        assertEquals(Amount.fromSubunits(15000L), result.participantShares["B"])
        assertFalse(result.participantShares.containsKey("C"))
    }

    // --- TEST 8: Base Bill / Shared Remaining Participation ---
    @Test
    fun test8_sharedRemainingDistribution_handlesNonItemConsumerInvolvement() {
        // Total bill = ₹1,000.00
        // Item 1 = ₹900.00 consumed by A
        // Remaining ₹100.00 is split among all 5 participants (A, B, C, D, E)
        // E consumed NO individual items, but is part of the overall bill.
        val totalBill = Amount.fromSubunits(100000L)
        val participants = listOf("A", "B", "C", "D", "E")
        val items = listOf(
            SplitItem(id = "1", name = "Expensive Dish", amount = Amount.fromSubunits(90000L), participantNames = listOf("A"))
        )

        val result = SplitCalculationEngine.calculateItemizedSplit(
            totalBill = totalBill,
            participants = participants,
            items = items,
            sharedRemainingParticipants = participants // All 5 share remaining ₹100
        )

        assertTrue(result.isValid)
        assertEquals(Amount.ZERO, result.unallocatedRemainingAmount)
        assertEquals(totalBill, result.totalAllocatedAmount)

        // Remaining ₹100 / 5 = ₹20 each
        assertEquals(Amount.fromSubunits(92000L), result.participantShares["A"]) // 900 + 20
        assertEquals(Amount.fromSubunits(2000L), result.participantShares["B"])  // 20
        assertEquals(Amount.fromSubunits(2000L), result.participantShares["C"])  // 20
        assertEquals(Amount.fromSubunits(2000L), result.participantShares["D"])  // 20
        assertEquals(Amount.fromSubunits(2000L), result.participantShares["E"])  // 20

        // Total must equal exactly ₹1,000.00
        val sum = result.participantShares.values.sumOf { it.subunits }
        assertEquals(100000L, sum)
    }

    // --- TEST 9: Contact Participant Preserves Phone Number ---
    @Test
    fun test9_contactParticipantStoresNameAndPhone() {
        val participant = SplitParticipant(
            name = "Rahul",
            amount = Amount.fromSubunits(32500L),
            phoneNumber = "+91 98765 43210"
        )
        assertEquals("Rahul", participant.name)
        assertEquals("+91 98765 43210", participant.phoneNumber)
        assertEquals(32500L, participant.amount.subunits)
    }

    // --- TEST 10: Existing Equal Split Behavior Unbroken ---
    @Test
    fun test10_existingEqualSplitBehaviorRemainsCorrect() {
        val totalAmount = Amount.fromMainUnit(1000L, Currency.INR)
        val participants = listOf("A", "B", "C", "D", "E")
        val result = SplitCalculationEngine.calculateEqualSplit(totalAmount, participants, "A")

        assertEquals(5, result.size)
        result.forEach {
            assertEquals(20000L, it.amount.subunits) // ₹200.00 each
        }
        assertEquals(100000L, result.sumOf { it.amount.subunits })
    }

    // --- TEST 11: Uneven Equal Division Deterministic Pennies ---
    @Test
    fun test11_unevenDivisionDeterministicPennies() {
        val totalAmount = Amount.fromMainUnit(100L, Currency.INR) // 10000 subunits
        val participants = listOf("Me", "Rahul", "Akash")
        val result = SplitCalculationEngine.calculateEqualSplit(totalAmount, participants, "Me")

        assertEquals(3334L, result[0].amount.subunits)
        assertEquals(3333L, result[1].amount.subunits)
        assertEquals(3333L, result[2].amount.subunits)
        assertEquals(10000L, result.sumOf { it.amount.subunits })
    }

    // --- TEST 12: hasEqualNonPayerShares Preserved ---
    @Test
    fun test12_hasEqualNonPayerSharesPreserved() {
        val participants = listOf(
            SplitParticipant(id = 1, name = "Me", isCurrentUser = true, amount = Amount.fromSubunits(100000L)),
            SplitParticipant(id = 2, name = "Rahul", isCurrentUser = false, amount = Amount.fromSubunits(100000L)),
            SplitParticipant(id = 3, name = "Akash", isCurrentUser = false, amount = Amount.fromSubunits(100000L))
        )
        assertTrue(SplitCalculationEngine.hasEqualNonPayerShares(participants))
    }

    // =========================================================================
    // SPECIFICATION SECTION 17: EXACT MODEL VERIFICATION TESTS (TEST A -> TEST J)
    // =========================================================================

    // --- TEST A: Bill ₹1,000, 5 people, Base ₹200 each ---
    @Test
    fun testA_baseEqualShare_initialStateWithoutItems() {
        val totalBill = Amount.fromSubunits(100000L) // ₹1,000.00
        val participants = listOf("A", "B", "C", "D", "E")

        val result = SplitCalculationEngine.calculateItemizedSplit(
            totalBill = totalBill,
            participants = participants,
            items = emptyList(),
            sharedRemainingParticipants = participants // All 5 share base bill
        )

        assertTrue("Calculation must be valid when base bill is shared", result.isValid)
        assertEquals(Amount.fromSubunits(20000L), result.baselineEqualShare) // ₹200.00 / person
        assertEquals(totalBill, result.totalAllocatedAmount)
        assertEquals(Amount.ZERO, result.unallocatedRemainingAmount)

        // Verify each participant gets exactly ₹200.00
        assertEquals(Amount.fromSubunits(20000L), result.participantShares["A"])
        assertEquals(Amount.fromSubunits(20000L), result.participantShares["B"])
        assertEquals(Amount.fromSubunits(20000L), result.participantShares["C"])
        assertEquals(Amount.fromSubunits(20000L), result.participantShares["D"])
        assertEquals(Amount.fromSubunits(20000L), result.participantShares["E"])

        // Verify breakdown shows base share = ₹200, item responsibility = ₹0
        result.participantDetails.forEach { detail ->
            assertEquals(Amount.fromSubunits(20000L), detail.sharedRemainingShare)
            assertEquals(Amount.ZERO, detail.itemizedShare)
            assertEquals(Amount.fromSubunits(20000L), detail.totalShare)
        }
    }

    // --- TEST B: Add ₹500 -> A: reflects base + item responsibility ---
    @Test
    fun testB_addItem_reflectsBasePlusItemResponsibility() {
        val totalBill = Amount.fromSubunits(100000L) // ₹1,000.00
        val participants = listOf("A", "B", "C", "D", "E")
        val items = listOf(
            SplitItem(id = "item-1", name = "Dish 1", amount = Amount.fromSubunits(50000L), participantNames = listOf("A"))
        )

        val result = SplitCalculationEngine.calculateItemizedSplit(
            totalBill = totalBill,
            participants = participants,
            items = items,
            sharedRemainingParticipants = participants // Remaining ₹500 is shared among 5 (₹100 each)
        )

        assertTrue(result.isValid)
        assertEquals(Amount.fromSubunits(50000L), result.itemizedTotalAmount)
        assertEquals(totalBill, result.totalAllocatedAmount)

        // A = ₹100 base share + ₹500 item responsibility = ₹600.00
        val detailA = result.participantDetails.first { it.participantName == "A" }
        assertEquals(Amount.fromSubunits(10000L), detailA.sharedRemainingShare)
        assertEquals(Amount.fromSubunits(50000L), detailA.itemizedShare)
        assertEquals(Amount.fromSubunits(60000L), detailA.totalShare)
        assertEquals(Amount.fromSubunits(60000L), result.participantShares["A"])

        // B, C, D, E each get ₹100 base share + ₹0 item = ₹100.00
        listOf("B", "C", "D", "E").forEach { name ->
            val detail = result.participantDetails.first { it.participantName == name }
            assertEquals(Amount.fromSubunits(10000L), detail.sharedRemainingShare)
            assertEquals(Amount.ZERO, detail.itemizedShare)
            assertEquals(Amount.fromSubunits(10000L), detail.totalShare)
            assertEquals(Amount.fromSubunits(10000L), result.participantShares[name])
        }

        // Sum must strictly equal bill total: 600 + 100 + 100 + 100 + 100 = 1,000
        val totalSum = result.participantShares.values.sumOf { it.subunits }
        assertEquals(100000L, totalSum)
    }

    // --- TEST C: Add ₹400 -> A+B: A gets ₹200, B gets ₹200 ---
    @Test
    fun testC_sharedItem_dividesEquallyBetweenParticipants() {
        val totalBill = Amount.fromSubunits(100000L) // ₹1,000.00
        val participants = listOf("A", "B", "C", "D", "E")
        val items = listOf(
            SplitItem(id = "item-1", name = "Dish 1", amount = Amount.fromSubunits(50000L), participantNames = listOf("A")),
            SplitItem(id = "item-2", name = "Dish 2", amount = Amount.fromSubunits(40000L), participantNames = listOf("A", "B"))
        )

        // From item-2: A gets ₹200, B gets ₹200
        val item2ShareA = SplitCalculationEngine.calculateItemShareForParticipant(items[1], "A")
        val item2ShareB = SplitCalculationEngine.calculateItemShareForParticipant(items[1], "B")
        assertEquals(Amount.fromSubunits(20000L), item2ShareA)
        assertEquals(Amount.fromSubunits(20000L), item2ShareB)

        val result = SplitCalculationEngine.calculateItemizedSplit(
            totalBill = totalBill,
            participants = participants,
            items = items,
            sharedRemainingParticipants = participants // Remaining ₹100 shared among 5 = ₹20 each
        )

        assertTrue(result.isValid)
        assertEquals(Amount.fromSubunits(90000L), result.itemizedTotalAmount)
        assertEquals(totalBill, result.totalAllocatedAmount)

        // A: ₹20 base + ₹500 item1 + ₹200 item2 = ₹720
        assertEquals(Amount.fromSubunits(72000L), result.participantShares["A"])
        // B: ₹20 base + ₹200 item2 = ₹220
        assertEquals(Amount.fromSubunits(22000L), result.participantShares["B"])
        // C, D, E: ₹20 base = ₹20
        assertEquals(Amount.fromSubunits(2000L), result.participantShares["C"])
        assertEquals(Amount.fromSubunits(2000L), result.participantShares["D"])
        assertEquals(Amount.fromSubunits(2000L), result.participantShares["E"])

        // Total = 720 + 220 + 20 + 20 + 20 = 1000
        val sum = result.participantShares.values.sumOf { it.subunits }
        assertEquals(100000L, sum)
    }

    // --- TEST D: Multiple items breakdown: ₹500 -> A, ₹250 -> A+B, ₹150 -> C ---
    @Test
    fun testD_multipleItems_fullBreakdownCalculatedAccurately() {
        val totalBill = Amount.fromSubunits(100000L) // ₹1,000.00
        val participants = listOf("A", "B", "C", "D", "E")
        val items = listOf(
            SplitItem(id = "1", name = "Item 1", amount = Amount.fromSubunits(50000L), participantNames = listOf("A")),
            SplitItem(id = "2", name = "Item 2", amount = Amount.fromSubunits(25000L), participantNames = listOf("A", "B")),
            SplitItem(id = "3", name = "Item 3", amount = Amount.fromSubunits(15000L), participantNames = listOf("C"))
        )

        val result = SplitCalculationEngine.calculateItemizedSplit(
            totalBill = totalBill,
            participants = participants,
            items = items,
            sharedRemainingParticipants = participants // Remaining ₹100 shared among 5 = ₹20 each
        )

        assertTrue(result.isValid)
        assertEquals(Amount.fromSubunits(90000L), result.itemizedTotalAmount)

        // A: 20 base + 500 item1 + 125 item2 = ₹645
        assertEquals(Amount.fromSubunits(64500L), result.participantShares["A"])
        val detailA = result.participantDetails.first { it.participantName == "A" }
        assertEquals(Amount.fromSubunits(2000L), detailA.sharedRemainingShare)
        assertEquals(Amount.fromSubunits(62500L), detailA.itemizedShare)
        assertEquals(2, detailA.itemBreakdown.size)

        // B: 20 base + 125 item2 = ₹145
        assertEquals(Amount.fromSubunits(14500L), result.participantShares["B"])

        // C: 20 base + 150 item3 = ₹170
        assertEquals(Amount.fromSubunits(17000L), result.participantShares["C"])

        // D & E: 20 base = ₹20
        assertEquals(Amount.fromSubunits(2000L), result.participantShares["D"])
        assertEquals(Amount.fromSubunits(2000L), result.participantShares["E"])

        assertEquals(100000L, result.participantShares.values.sumOf { it.subunits })
    }

    // --- TEST E: Item total less than bill: remaining detected ---
    @Test
    fun testE_itemTotalLessThanBill_remainingAmountDetected() {
        val totalBill = Amount.fromSubunits(100000L) // ₹1,000.00
        val participants = listOf("A", "B", "C", "D", "E")
        val items = listOf(
            SplitItem(id = "1", name = "Item 1", amount = Amount.fromSubunits(50000L), participantNames = listOf("A")),
            SplitItem(id = "2", name = "Item 2", amount = Amount.fromSubunits(25000L), participantNames = listOf("A", "B")),
            SplitItem(id = "3", name = "Item 3", amount = Amount.fromSubunits(15000L), participantNames = listOf("C"))
        ) // Total items = ₹900.00

        val result = SplitCalculationEngine.calculateItemizedSplit(
            totalBill = totalBill,
            participants = participants,
            items = items,
            sharedRemainingParticipants = emptyList() // Not yet distributed
        )

        assertFalse("Must not be complete until remaining is distributed or allocated", result.isValid)
        assertTrue(result.isUnderallocated)
        assertEquals(Amount.fromSubunits(10000L), result.unallocatedRemainingAmount) // Remaining ₹100.00
        assertEquals(Amount.fromSubunits(90000L), result.itemizedTotalAmount)
        assertEquals(Amount.ZERO, result.overallocatedAmount)
    }

    // --- TEST F: Item total greater than bill: overallocation detected ---
    @Test
    fun testF_itemTotalGreaterThanBill_overallocationDetected() {
        val totalBill = Amount.fromSubunits(100000L) // ₹1,000.00
        val participants = listOf("A", "B", "C", "D", "E")
        val items = listOf(
            SplitItem(id = "1", name = "Item 1", amount = Amount.fromSubunits(50000L), participantNames = listOf("A")),
            SplitItem(id = "2", name = "Item 2", amount = Amount.fromSubunits(25000L), participantNames = listOf("A", "B")),
            SplitItem(id = "3", name = "Item 3", amount = Amount.fromSubunits(15000L), participantNames = listOf("C")),
            SplitItem(id = "4", name = "Item 4", amount = Amount.fromSubunits(14000L), participantNames = listOf("D"))
        ) // Total = ₹1,040.00

        val result = SplitCalculationEngine.calculateItemizedSplit(
            totalBill = totalBill,
            participants = participants,
            items = items,
            sharedRemainingParticipants = emptyList()
        )

        assertFalse(result.isValid)
        assertTrue(result.isOverallocated)
        assertEquals(Amount.fromSubunits(4000L), result.overallocatedAmount) // Over by ₹40.00
        assertEquals(Amount.fromSubunits(104000L), result.itemizedTotalAmount)
        assertTrue(result.errorMessage?.contains("Overallocated") == true)
    }

    // --- TEST G: Custom item allocation: ₹500 (A ₹300, B ₹200) ---
    @Test
    fun testG_customItemAllocation_exactShares() {
        val item = SplitItem(
            id = "custom-1",
            name = "Wine Bottle",
            amount = Amount.fromSubunits(50000L),
            participantNames = listOf("A", "B"),
            isCustomAllocation = true,
            customAllocations = mapOf(
                "A" to Amount.fromSubunits(30000L),
                "B" to Amount.fromSubunits(20000L)
            )
        )

        val shareA = SplitCalculationEngine.calculateItemShareForParticipant(item, "A")
        val shareB = SplitCalculationEngine.calculateItemShareForParticipant(item, "B")

        assertEquals(Amount.fromSubunits(30000L), shareA)
        assertEquals(Amount.fromSubunits(20000L), shareB)

        val result = SplitCalculationEngine.calculateItemizedSplit(
            totalBill = Amount.fromSubunits(50000L),
            participants = listOf("A", "B"),
            items = listOf(item),
            sharedRemainingParticipants = emptyList()
        )
        assertTrue(result.isValid)
        assertEquals(Amount.fromSubunits(30000L), result.participantShares["A"])
        assertEquals(Amount.fromSubunits(20000L), result.participantShares["B"])
    }

    // --- TEST H: Edit item participant: all affected totals update ---
    @Test
    fun testH_editItemParticipant_allAffectedTotalsUpdate() {
        val totalBill = Amount.fromSubunits(60000L) // ₹600.00
        val participants = listOf("A", "B", "C")
        val originalItem = SplitItem(
            id = "1",
            name = "Appetizer",
            amount = Amount.fromSubunits(60000L),
            participantNames = listOf("A", "B") // ₹300 each
        )

        val result1 = SplitCalculationEngine.calculateItemizedSplit(
            totalBill = totalBill,
            participants = participants,
            items = listOf(originalItem),
            sharedRemainingParticipants = emptyList()
        )
        assertEquals(Amount.fromSubunits(30000L), result1.participantShares["A"])
        assertEquals(Amount.fromSubunits(30000L), result1.participantShares["B"])
        assertEquals(Amount.ZERO, result1.participantShares["C"])

        // Edit item consumers: A, B, C (₹200 each)
        val editedItem = originalItem.copy(participantNames = listOf("A", "B", "C"))
        val result2 = SplitCalculationEngine.calculateItemizedSplit(
            totalBill = totalBill,
            participants = participants,
            items = listOf(editedItem),
            sharedRemainingParticipants = emptyList()
        )
        assertEquals(Amount.fromSubunits(20000L), result2.participantShares["A"])
        assertEquals(Amount.fromSubunits(20000L), result2.participantShares["B"])
        assertEquals(Amount.fromSubunits(20000L), result2.participantShares["C"])
    }

    // --- TEST I: Remove item: totals update immediately ---
    @Test
    fun testI_removeItem_totalsUpdateImmediately() {
        val totalBill = Amount.fromSubunits(70000L)
        val participants = listOf("A", "B")
        val item1 = SplitItem(id = "1", amount = Amount.fromSubunits(50000L), participantNames = listOf("A"))
        val item2 = SplitItem(id = "2", amount = Amount.fromSubunits(20000L), participantNames = listOf("B"))

        val resultWithBoth = SplitCalculationEngine.calculateItemizedSplit(
            totalBill = totalBill,
            participants = participants,
            items = listOf(item1, item2),
            sharedRemainingParticipants = emptyList()
        )
        assertEquals(Amount.fromSubunits(50000L), resultWithBoth.participantShares["A"])
        assertEquals(Amount.fromSubunits(20000L), resultWithBoth.participantShares["B"])

        // Remove item1
        val resultAfterRemove = SplitCalculationEngine.calculateItemizedSplit(
            totalBill = totalBill,
            participants = participants,
            items = listOf(item2),
            sharedRemainingParticipants = emptyList()
        )
        assertEquals(Amount.ZERO, resultAfterRemove.participantShares["A"])
        assertEquals(Amount.fromSubunits(20000L), resultAfterRemove.participantShares["B"])
        assertEquals(Amount.fromSubunits(50000L), resultAfterRemove.unallocatedRemainingAmount)
    }

    // --- TEST J: Equal Split remains unchanged ---
    @Test
    fun testJ_equalSplitRemainsUnchanged() {
        val totalAmount = Amount.fromSubunits(100000L) // ₹1,000.00
        val participants = listOf("A", "B", "C", "D", "E")
        val equalResult = SplitCalculationEngine.calculateEqualSplit(totalAmount, participants, "A")

        assertEquals(5, equalResult.size)
        equalResult.forEach { participant ->
            assertEquals(Amount.fromSubunits(20000L), participant.amount) // ₹200.00 each
        }
        assertEquals(100000L, equalResult.sumOf { it.amount.subunits })
    }
}

