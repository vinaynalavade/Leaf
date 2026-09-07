package com.vinaynalavade.expensetracker

import com.vinaynalavade.expensetracker.core.model.Amount
import com.vinaynalavade.expensetracker.domain.model.SettlementStatus
import com.vinaynalavade.expensetracker.domain.model.SplitExpense
import com.vinaynalavade.expensetracker.domain.model.SplitMethod
import com.vinaynalavade.expensetracker.domain.model.SplitParticipant
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class SplitDomainTest {

    @Test
    fun splitExpense_financialSummaryCalculations_areAccurate() {
        val participants = listOf(
            SplitParticipant(id = 1, name = "Me", isCurrentUser = true, amount = Amount.fromSubunits(150000L), settlementStatus = SettlementStatus.PENDING),
            SplitParticipant(id = 2, name = "Rahul", isCurrentUser = false, amount = Amount.fromSubunits(80000L), settlementStatus = SettlementStatus.PENDING),
            SplitParticipant(id = 3, name = "Akash", isCurrentUser = false, amount = Amount.fromSubunits(120000L), settlementStatus = SettlementStatus.SETTLED),
            SplitParticipant(id = 4, name = "Sameer", isCurrentUser = false, amount = Amount.fromSubunits(100000L), settlementStatus = SettlementStatus.PENDING)
        )

        val splitExpense = SplitExpense(
            id = 1L,
            title = "Goa Trip",
            totalAmount = Amount.fromSubunits(450000L),
            date = 1000L,
            categoryId = 1L,
            paidBy = "Me",
            splitMethod = SplitMethod.CUSTOM,
            participants = participants
        )

        // Current user share: ₹1,500.00
        assertEquals(150000L, splitExpense.userShare.subunits)

        // Collected from settled non-payers (Akash = ₹1,200.00)
        assertEquals(120000L, splitExpense.collectedAmount.subunits)

        // To collect from pending non-payers (Rahul ₹800 + Sameer ₹1,000 = ₹1,800.00)
        assertEquals(180000L, splitExpense.toCollectAmount.subunits)

        // Not fully settled yet
        assertFalse(splitExpense.isFullySettled)

        // Total other shares = 800 + 1200 + 1000 = ₹3,000.00
        assertEquals(300000L, splitExpense.totalOtherShares.subunits)
    }

    @Test
    fun splitExpense_whenAllNonPayersSettled_isFullySettledIsTrue() {
        val participants = listOf(
            SplitParticipant(id = 1, name = "Me", isCurrentUser = true, amount = Amount.fromSubunits(100000L), settlementStatus = SettlementStatus.PENDING),
            SplitParticipant(id = 2, name = "Rahul", isCurrentUser = false, amount = Amount.fromSubunits(100000L), settlementStatus = SettlementStatus.SETTLED),
            SplitParticipant(id = 3, name = "Akash", isCurrentUser = false, amount = Amount.fromSubunits(100000L), settlementStatus = SettlementStatus.SETTLED)
        )

        val splitExpense = SplitExpense(
            id = 1L,
            title = "Dinner",
            totalAmount = Amount.fromSubunits(300000L),
            date = 1000L,
            categoryId = 1L,
            paidBy = "Me",
            splitMethod = SplitMethod.EQUAL,
            participants = participants
        )

        assertTrue(splitExpense.isFullySettled)
        assertEquals(0L, splitExpense.toCollectAmount.subunits)
        assertEquals(200000L, splitExpense.collectedAmount.subunits)
    }
}
