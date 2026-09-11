package com.vinaynalavade.expensetracker

import com.vinaynalavade.expensetracker.core.model.Amount
import com.vinaynalavade.expensetracker.core.split.NetBalanceEngine
import com.vinaynalavade.expensetracker.domain.model.SettlementStatus
import com.vinaynalavade.expensetracker.domain.model.SplitExpense
import com.vinaynalavade.expensetracker.domain.model.SplitMethod
import com.vinaynalavade.expensetracker.domain.model.SplitParticipant
import org.junit.Assert.assertEquals
import org.junit.Test

class SharedFinanceNetBalanceTest {

    @Test
    fun `scenario 1 - current user paid for everyone`() {
        val pMe = SplitParticipant(name = "Vinay", isCurrentUser = true, amount = Amount.fromMainUnit(100), settlementStatus = SettlementStatus.PENDING)
        val pAlice = SplitParticipant(name = "Alice", isCurrentUser = false, amount = Amount.fromMainUnit(100), settlementStatus = SettlementStatus.PENDING)
        val pBob = SplitParticipant(name = "Bob", isCurrentUser = false, amount = Amount.fromMainUnit(100), settlementStatus = SettlementStatus.PENDING)

        val expense = SplitExpense(
            id = 1L,
            title = "Dinner",
            totalAmount = Amount.fromMainUnit(300),
            date = 1000L,
            categoryId = 1L,
            paidBy = "Vinay",
            splitMethod = SplitMethod.EQUAL,
            participants = listOf(pMe, pAlice, pBob)
        )

        val summary = NetBalanceEngine.calculateNetBalances(listOf(expense))

        assertEquals(Amount.fromMainUnit(300), summary.totalGroupSpend)
        assertEquals(Amount.fromMainUnit(200), summary.netOwedToCurrentUser)
        assertEquals(Amount.ZERO, summary.netCurrentUserOwes)
        assertEquals(2, summary.debts.size)

        val aliceDebt = summary.debts.find { it.debtorName == "Alice" && it.creditorName == "Vinay" }
        val bobDebt = summary.debts.find { it.debtorName == "Bob" && it.creditorName == "Vinay" }

        assertEquals(Amount.fromMainUnit(100), aliceDebt?.netAmount)
        assertEquals(Amount.fromMainUnit(100), bobDebt?.netAmount)
    }

    @Test
    fun `scenario 2 - another participant paid for everyone`() {
        val pMe = SplitParticipant(name = "Vinay", isCurrentUser = true, amount = Amount.fromMainUnit(100), settlementStatus = SettlementStatus.PENDING)
        val pAlice = SplitParticipant(name = "Alice", isCurrentUser = false, amount = Amount.fromMainUnit(100), settlementStatus = SettlementStatus.PENDING)
        val pBob = SplitParticipant(name = "Bob", isCurrentUser = false, amount = Amount.fromMainUnit(100), settlementStatus = SettlementStatus.PENDING)

        val expense = SplitExpense(
            id = 1L,
            title = "Lunch",
            totalAmount = Amount.fromMainUnit(300),
            date = 1000L,
            categoryId = 1L,
            paidBy = "Alice",
            splitMethod = SplitMethod.EQUAL,
            participants = listOf(pMe, pAlice, pBob)
        )

        val summary = NetBalanceEngine.calculateNetBalances(listOf(expense))

        assertEquals(Amount.fromMainUnit(300), summary.totalGroupSpend)
        assertEquals(Amount.ZERO, summary.netOwedToCurrentUser)
        assertEquals(Amount.fromMainUnit(100), summary.netCurrentUserOwes) // Current user owes Alice 100

        val myDebtToAlice = summary.debts.find { it.debtorName == "Vinay" && it.creditorName == "Alice" }
        val bobDebtToAlice = summary.debts.find { it.debtorName == "Bob" && it.creditorName == "Alice" }

        assertEquals(Amount.fromMainUnit(100), myDebtToAlice?.netAmount)
        assertEquals(Amount.fromMainUnit(100), bobDebtToAlice?.netAmount)
    }

    @Test
    fun `scenario 3 - multi expense cross offsetting`() {
        // Expense 1: Vinay paid 300, split between Vinay & Alice (150 each) -> Alice owes Vinay 150
        val pMe1 = SplitParticipant(name = "Vinay", isCurrentUser = true, amount = Amount.fromMainUnit(150), settlementStatus = SettlementStatus.PENDING)
        val pAlice1 = SplitParticipant(name = "Alice", isCurrentUser = false, amount = Amount.fromMainUnit(150), settlementStatus = SettlementStatus.PENDING)
        val exp1 = SplitExpense(
            id = 1L,
            title = "Groceries",
            totalAmount = Amount.fromMainUnit(300),
            date = 1000L,
            categoryId = 1L,
            paidBy = "Vinay",
            splitMethod = SplitMethod.EQUAL,
            participants = listOf(pMe1, pAlice1)
        )

        // Expense 2: Alice paid 100, split between Vinay & Alice (50 each) -> Vinay owes Alice 50
        val pMe2 = SplitParticipant(name = "Vinay", isCurrentUser = true, amount = Amount.fromMainUnit(50), settlementStatus = SettlementStatus.PENDING)
        val pAlice2 = SplitParticipant(name = "Alice", isCurrentUser = false, amount = Amount.fromMainUnit(50), settlementStatus = SettlementStatus.PENDING)
        val exp2 = SplitExpense(
            id = 2L,
            title = "Coffee",
            totalAmount = Amount.fromMainUnit(100),
            date = 2000L,
            categoryId = 1L,
            paidBy = "Alice",
            splitMethod = SplitMethod.EQUAL,
            participants = listOf(pMe2, pAlice2)
        )

        val summary = NetBalanceEngine.calculateNetBalances(listOf(exp1, exp2))

        assertEquals(Amount.fromMainUnit(400), summary.totalGroupSpend)
        // Net: 150 - 50 = Alice owes Vinay 100
        assertEquals(Amount.fromMainUnit(100), summary.netOwedToCurrentUser)
        assertEquals(Amount.ZERO, summary.netCurrentUserOwes)
        assertEquals(1, summary.debts.size)

        val netDebt = summary.debts.first()
        assertEquals("Alice", netDebt.debtorName)
        assertEquals("Vinay", netDebt.creditorName)
        assertEquals(Amount.fromMainUnit(100), netDebt.netAmount)
    }
}
