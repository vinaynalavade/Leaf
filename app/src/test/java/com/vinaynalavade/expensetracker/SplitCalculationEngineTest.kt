package com.vinaynalavade.expensetracker

import com.vinaynalavade.expensetracker.core.model.Amount
import com.vinaynalavade.expensetracker.core.model.Currency
import com.vinaynalavade.expensetracker.domain.model.SettlementStatus
import com.vinaynalavade.expensetracker.domain.model.SplitParticipant
import com.vinaynalavade.expensetracker.domain.split.SplitCalculationEngine
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class SplitCalculationEngineTest {

    @Test
    fun calculateEqualSplit_evenDivision_splitsEqually() {
        val totalAmount = Amount.fromMainUnit(4000L, Currency.INR) // ₹4,000.00 = 400000 subunits
        val participants = listOf("Vinay", "Rahul", "Akash", "Sameer")

        val result = SplitCalculationEngine.calculateEqualSplit(
            totalAmount = totalAmount,
            participants = participants,
            payerName = "Vinay"
        )

        assertEquals(4, result.size)
        // Each person gets exactly ₹1,000.00 (100000 subunits)
        val expectedSubunits = 100000L
        result.forEach { participant ->
            assertEquals(expectedSubunits, participant.amount.subunits)
        }

        // Sum matches total amount exactly
        val totalSubunits = result.sumOf { it.amount.subunits }
        assertEquals(totalAmount.subunits, totalSubunits)

        // Payer "Vinay" is marked as currentUser
        assertTrue(result[0].isCurrentUser)
        assertFalse(result[1].isCurrentUser)
    }

    @Test
    fun calculateEqualSplit_unevenDivision_reconcilesPenniesDeterministically() {
        // ₹100.00 / 3 people = 10000 subunits / 3
        // Base = 3333 subunits (₹33.33), Remainder = 1 subunit (1 paisa)
        // Person 0: 3334 subunits (₹33.34)
        // Person 1: 3333 subunits (₹33.33)
        // Person 2: 3333 subunits (₹33.33)
        // Total = 3334 + 3333 + 3333 = 10000 subunits = exactly ₹100.00
        val totalAmount = Amount.fromMainUnit(100L, Currency.INR)
        val participants = listOf("Me", "Rahul", "Akash")

        val result = SplitCalculationEngine.calculateEqualSplit(
            totalAmount = totalAmount,
            participants = participants,
            payerName = "Me"
        )

        assertEquals(3, result.size)
        assertEquals(3334L, result[0].amount.subunits)
        assertEquals(3333L, result[1].amount.subunits)
        assertEquals(3333L, result[2].amount.subunits)

        // Critical reconciliation test: Sum must match original total with ZERO floating-point inaccuracy
        val totalCalculated = result.sumOf { it.amount.subunits }
        assertEquals(totalAmount.subunits, totalCalculated)
    }

    @Test
    fun validateCustomSplit_exactAllocation_returnsValid() {
        val totalAmount = Amount.fromMainUnit(5000L, Currency.INR) // 500000 subunits
        // 1000 + 1500 + 2500 = 5000
        val allocatedSubunits = (100000L + 150000L + 250000L)

        val validation = SplitCalculationEngine.validateCustomSplit(
            totalAmount = totalAmount,
            allocatedSubunits = allocatedSubunits
        )

        assertTrue(validation.isValid)
        assertEquals(Amount(allocatedSubunits), validation.allocatedAmount)
        assertEquals(Amount.ZERO, validation.remainingAmount)
        assertEquals(Amount.ZERO, validation.overallocatedAmount)
    }

    @Test
    fun validateCustomSplit_underAllocation_returnsInvalidWithRemaining() {
        val totalAmount = Amount.fromMainUnit(5000L, Currency.INR) // 500000 subunits
        val allocatedSubunits = 450000L // ₹4,500.00

        val validation = SplitCalculationEngine.validateCustomSplit(
            totalAmount = totalAmount,
            allocatedSubunits = allocatedSubunits
        )

        assertFalse(validation.isValid)
        assertEquals(Amount(50000L), validation.remainingAmount) // ₹500 remaining
        assertEquals(Amount.ZERO, validation.overallocatedAmount)
    }

    @Test
    fun validateCustomSplit_overAllocation_returnsInvalidWithOverallocated() {
        val totalAmount = Amount.fromMainUnit(5000L, Currency.INR) // 500000 subunits
        val allocatedSubunits = 550000L // ₹5,500.00

        val validation = SplitCalculationEngine.validateCustomSplit(
            totalAmount = totalAmount,
            allocatedSubunits = allocatedSubunits
        )

        assertFalse(validation.isValid)
        assertEquals(Amount.ZERO, validation.remainingAmount)
        assertEquals(Amount(50000L), validation.overallocatedAmount) // ₹500 overallocated
    }

    @Test
    fun hasEqualNonPayerShares_equalShares_returnsTrue() {
        val participants = listOf(
            SplitParticipant(id = 1, name = "Me", isCurrentUser = true, amount = Amount.fromSubunits(100000L)),
            SplitParticipant(id = 2, name = "Rahul", isCurrentUser = false, amount = Amount.fromSubunits(100000L)),
            SplitParticipant(id = 3, name = "Akash", isCurrentUser = false, amount = Amount.fromSubunits(100000L))
        )

        val isEqual = SplitCalculationEngine.hasEqualNonPayerShares(participants)
        assertTrue(isEqual)
    }

    @Test
    fun hasEqualNonPayerShares_differentShares_returnsFalse() {
        val participants = listOf(
            SplitParticipant(id = 1, name = "Me", isCurrentUser = true, amount = Amount.fromSubunits(150000L)),
            SplitParticipant(id = 2, name = "Rahul", isCurrentUser = false, amount = Amount.fromSubunits(80000L)),
            SplitParticipant(id = 3, name = "Akash", isCurrentUser = false, amount = Amount.fromSubunits(120000L))
        )

        val isEqual = SplitCalculationEngine.hasEqualNonPayerShares(participants)
        assertFalse(isEqual)
    }
}
