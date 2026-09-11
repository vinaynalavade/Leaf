package com.vinaynalavade.expensetracker

import com.vinaynalavade.expensetracker.core.model.Amount
import com.vinaynalavade.expensetracker.core.result.AppResult
import com.vinaynalavade.expensetracker.data.local.dao.SplitDao
import com.vinaynalavade.expensetracker.data.local.dao.TransactionDao
import com.vinaynalavade.expensetracker.data.local.database.ExpenseTrackerDatabase
import com.vinaynalavade.expensetracker.data.local.entity.SplitExpenseEntity
import com.vinaynalavade.expensetracker.data.local.entity.SplitExpenseWithDetails
import com.vinaynalavade.expensetracker.data.local.entity.SplitParticipantEntity
import com.vinaynalavade.expensetracker.data.local.entity.TransactionEntity
import com.vinaynalavade.expensetracker.data.local.entity.TransactionWithCategory
import com.vinaynalavade.expensetracker.data.repository.SplitRepositoryImpl
import com.vinaynalavade.expensetracker.domain.model.PaymentMethod
import com.vinaynalavade.expensetracker.domain.model.SettlementStatus
import com.vinaynalavade.expensetracker.domain.model.SplitExpense
import com.vinaynalavade.expensetracker.domain.model.SplitMethod
import com.vinaynalavade.expensetracker.domain.model.SplitParticipant
import com.vinaynalavade.expensetracker.domain.model.TransactionType
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.flowOf
import kotlinx.coroutines.runBlocking
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test

class SplitTransactionIntegrationTest {

    private lateinit var fakeTransactionDao: FakeTransactionDao
    private lateinit var fakeSplitDao: FakeSplitDao
    private lateinit var splitRepository: SplitRepositoryImpl

    @Before
    fun setUp() {
        fakeTransactionDao = FakeTransactionDao()
        fakeSplitDao = FakeSplitDao()

        splitRepository = SplitRepositoryImpl(
            database = null,
            splitDao = fakeSplitDao,
            transactionDao = fakeTransactionDao,
            ioDispatcher = Dispatchers.Unconfined
        )
    }

    @Test
    fun testCreateSplitWithIntegrationEnabled_createsExactlyOneExpenseTransaction() = runBlocking {
        val participants = listOf(
            SplitParticipant(id = 1L, name = "Me", isCurrentUser = true, amount = Amount.fromSubunits(100000L)),
            SplitParticipant(id = 2L, name = "Rahul", isCurrentUser = false, amount = Amount.fromSubunits(100000L)),
            SplitParticipant(id = 3L, name = "Akash", isCurrentUser = false, amount = Amount.fromSubunits(100000L)),
            SplitParticipant(id = 4L, name = "Sameer", isCurrentUser = false, amount = Amount.fromSubunits(100000L))
        )

        val splitExpense = SplitExpense(
            id = 10L,
            title = "Hotel",
            totalAmount = Amount.fromSubunits(400000L),
            date = 1000L,
            categoryId = 1L,
            paidBy = "Me",
            splitMethod = SplitMethod.EQUAL,
            addToTransactions = true,
            paymentMethod = PaymentMethod.ACCOUNT,
            participants = participants
        )

        val result = splitRepository.insertSplitExpense(splitExpense)
        assertTrue(result is AppResult.Success)

        // Verify exactly ONE normal Expense transaction was created
        assertEquals(1, fakeTransactionDao.transactions.size)
        val createdTx = fakeTransactionDao.transactions.first()
        assertEquals(400000L, createdTx.amountSubunits)
        assertEquals(TransactionType.EXPENSE.name, createdTx.type)
        assertEquals(1L, createdTx.categoryId)
        assertEquals(PaymentMethod.ACCOUNT.name, createdTx.paymentMethod)
        assertEquals("Split – Hotel", createdTx.note)
        assertEquals(1000L, createdTx.timestamp)

        // Verify split entity links to created transaction
        val savedExpense = fakeSplitDao.splitExpenses[10L]
        assertNotNull(savedExpense)
        assertEquals(createdTx.id, savedExpense!!.expenseTransactionId)
        assertTrue(savedExpense.addToTransactions)
        assertEquals("ACCOUNT", savedExpense.paymentMethod)
    }

    @Test
    fun testCreateSplitWithIntegrationDisabled_createsZeroTransactions() = runBlocking {
        val participants = listOf(
            SplitParticipant(id = 1L, name = "Me", isCurrentUser = true, amount = Amount.fromSubunits(100000L)),
            SplitParticipant(id = 2L, name = "Rahul", isCurrentUser = false, amount = Amount.fromSubunits(100000L))
        )

        val splitExpense = SplitExpense(
            id = 20L,
            title = "Dinner",
            totalAmount = Amount.fromSubunits(200000L),
            date = 2000L,
            categoryId = 2L,
            paidBy = "Me",
            splitMethod = SplitMethod.EQUAL,
            addToTransactions = false,
            paymentMethod = PaymentMethod.CASH,
            participants = participants
        )

        val result = splitRepository.insertSplitExpense(splitExpense)
        assertTrue(result is AppResult.Success)

        // 0 normal transactions created
        assertEquals(0, fakeTransactionDao.transactions.size)

        val savedExpense = fakeSplitDao.splitExpenses[20L]
        assertNotNull(savedExpense)
        assertFalse(savedExpense!!.addToTransactions)
        assertNull(savedExpense.expenseTransactionId)
    }

    @Test
    fun testSettlementWithIntegrationEnabled_createsExactlyOneIncomeTransactionWithParticipantNote() = runBlocking {
        val participants = listOf(
            SplitParticipant(id = 101L, name = "Me", isCurrentUser = true, amount = Amount.fromSubunits(100000L)),
            SplitParticipant(id = 102L, name = "Rahul", isCurrentUser = false, amount = Amount.fromSubunits(100000L), settlementStatus = SettlementStatus.PENDING),
            SplitParticipant(id = 103L, name = "Akash", isCurrentUser = false, amount = Amount.fromSubunits(100000L), settlementStatus = SettlementStatus.PENDING),
            SplitParticipant(id = 104L, name = "Sameer", isCurrentUser = false, amount = Amount.fromSubunits(100000L), settlementStatus = SettlementStatus.PENDING)
        )

        val splitExpense = SplitExpense(
            id = 50L,
            title = "Goa Trip",
            totalAmount = Amount.fromSubunits(400000L),
            date = 3000L,
            categoryId = 3L,
            paidBy = "Me",
            splitMethod = SplitMethod.EQUAL,
            addToTransactions = true,
            paymentMethod = PaymentMethod.ACCOUNT,
            participants = participants
        )

        splitRepository.insertSplitExpense(splitExpense)
        assertEquals(1, fakeTransactionDao.transactions.size) // 1 initial expense tx

        // Settle Rahul with Cash
        val settleTime = 5000L
        splitRepository.updateParticipantSettlement(
            participantId = 102L,
            status = SettlementStatus.SETTLED,
            paymentMethod = PaymentMethod.CASH,
            settledAt = settleTime
        )

        // Exactly 2 transactions now (1 expense + 1 income)
        assertEquals(2, fakeTransactionDao.transactions.size)
        val rahulIncomeTx = fakeTransactionDao.transactions.last()
        assertEquals(100000L, rahulIncomeTx.amountSubunits)
        assertEquals(TransactionType.INCOME.name, rahulIncomeTx.type)
        assertEquals(3L, rahulIncomeTx.categoryId)
        assertEquals(PaymentMethod.CASH.name, rahulIncomeTx.paymentMethod)
        assertEquals("Rahul — Goa Trip settlement", rahulIncomeTx.note)
        assertEquals(settleTime, rahulIncomeTx.timestamp)

        // Settle Akash with Account
        splitRepository.updateParticipantSettlement(
            participantId = 103L,
            status = SettlementStatus.SETTLED,
            paymentMethod = PaymentMethod.ACCOUNT,
            settledAt = 6000L
        )

        // Settle Sameer with Cash
        splitRepository.updateParticipantSettlement(
            participantId = 104L,
            status = SettlementStatus.SETTLED,
            paymentMethod = PaymentMethod.CASH,
            settledAt = 7000L
        )

        // Total 4 transactions: 1 expense ₹4,000 + 3 incomes of ₹1,000 each = net ₹1,000 personal cost
        assertEquals(4, fakeTransactionDao.transactions.size)
        val expenseSum = fakeTransactionDao.transactions.filter { it.type == TransactionType.EXPENSE.name }.sumOf { it.amountSubunits }
        val incomeSum = fakeTransactionDao.transactions.filter { it.type == TransactionType.INCOME.name }.sumOf { it.amountSubunits }
        assertEquals(400000L, expenseSum)
        assertEquals(300000L, incomeSum)
        assertEquals(100000L, expenseSum - incomeSum) // Net ₹1,000 personal share
    }

    @Test
    fun testSettlementForCurrentUser_neverCreatesIncomeTransaction() = runBlocking {
        val participants = listOf(
            SplitParticipant(id = 201L, name = "Me", isCurrentUser = true, amount = Amount.fromSubunits(100000L))
        )

        val splitExpense = SplitExpense(
            id = 60L,
            title = "Coffee",
            totalAmount = Amount.fromSubunits(100000L),
            date = 1000L,
            categoryId = 1L,
            paidBy = "Me",
            splitMethod = SplitMethod.EQUAL,
            addToTransactions = true,
            participants = participants
        )

        splitRepository.insertSplitExpense(splitExpense)
        assertEquals(1, fakeTransactionDao.transactions.size) // only original expense

        // Mark current user as settled
        splitRepository.updateParticipantSettlement(
            participantId = 201L,
            status = SettlementStatus.SETTLED,
            paymentMethod = PaymentMethod.ACCOUNT
        )

        // Should NOT create any income transaction for "Me"
        assertEquals(1, fakeTransactionDao.transactions.size)
    }

    @Test
    fun testDuplicateSettlementProtection_doesNotCreateDuplicateTransactions() = runBlocking {
        val participants = listOf(
            SplitParticipant(id = 301L, name = "Me", isCurrentUser = true, amount = Amount.fromSubunits(100000L)),
            SplitParticipant(id = 302L, name = "Rahul", isCurrentUser = false, amount = Amount.fromSubunits(100000L))
        )

        val splitExpense = SplitExpense(
            id = 70L,
            title = "Lunch",
            totalAmount = Amount.fromSubunits(200000L),
            date = 1000L,
            categoryId = 1L,
            paidBy = "Me",
            splitMethod = SplitMethod.EQUAL,
            addToTransactions = true,
            participants = participants
        )

        splitRepository.insertSplitExpense(splitExpense)
        assertEquals(1, fakeTransactionDao.transactions.size)

        // First settle action
        splitRepository.updateParticipantSettlement(
            participantId = 302L,
            status = SettlementStatus.SETTLED,
            paymentMethod = PaymentMethod.CASH
        )
        assertEquals(2, fakeTransactionDao.transactions.size)

        // Repeated settle action (e.g. recomposition, re-trigger)
        splitRepository.updateParticipantSettlement(
            participantId = 302L,
            status = SettlementStatus.SETTLED,
            paymentMethod = PaymentMethod.CASH
        )

        // Transaction count must stay at 2
        assertEquals(2, fakeTransactionDao.transactions.size)
    }

    @Test
    fun testUndoSettlement_preservesHistoricalLedgerTransaction() = runBlocking {
        val participants = listOf(
            SplitParticipant(id = 401L, name = "Me", isCurrentUser = true, amount = Amount.fromSubunits(100000L)),
            SplitParticipant(id = 402L, name = "Rahul", isCurrentUser = false, amount = Amount.fromSubunits(100000L))
        )

        val splitExpense = SplitExpense(
            id = 80L,
            title = "Dinner",
            totalAmount = Amount.fromSubunits(200000L),
            date = 1000L,
            categoryId = 1L,
            paidBy = "Me",
            splitMethod = SplitMethod.EQUAL,
            addToTransactions = true,
            participants = participants
        )

        splitRepository.insertSplitExpense(splitExpense)
        splitRepository.updateParticipantSettlement(402L, SettlementStatus.SETTLED, PaymentMethod.CASH)
        assertEquals(2, fakeTransactionDao.transactions.size)

        // Undo settlement -> status becomes PENDING
        splitRepository.updateParticipantSettlement(402L, SettlementStatus.PENDING, PaymentMethod.CASH)

        // Historical income transaction must NOT be silently deleted
        assertEquals(2, fakeTransactionDao.transactions.size)
        val participant = fakeSplitDao.participants[402L]
        assertNotNull(participant)
        assertEquals(SettlementStatus.PENDING.name, participant!!.settlementStatus)
    }

    @Test
    fun testDeleteSplit_preservesNormalLedgerTransactions() = runBlocking {
        val participants = listOf(
            SplitParticipant(id = 501L, name = "Me", isCurrentUser = true, amount = Amount.fromSubunits(100000L)),
            SplitParticipant(id = 502L, name = "Rahul", isCurrentUser = false, amount = Amount.fromSubunits(100000L))
        )

        val splitExpense = SplitExpense(
            id = 90L,
            title = "Movie",
            totalAmount = Amount.fromSubunits(200000L),
            date = 1000L,
            categoryId = 1L,
            paidBy = "Me",
            splitMethod = SplitMethod.EQUAL,
            addToTransactions = true,
            participants = participants
        )

        splitRepository.insertSplitExpense(splitExpense)
        splitRepository.updateParticipantSettlement(502L, SettlementStatus.SETTLED, PaymentMethod.CASH)
        assertEquals(2, fakeTransactionDao.transactions.size)

        // Delete Split
        splitRepository.deleteSplitExpense(90L)

        // Split records are removed
        assertNull(fakeSplitDao.splitExpenses[90L])
        assertFalse(fakeSplitDao.participants.containsKey(501L))
        assertFalse(fakeSplitDao.participants.containsKey(502L))

        // Normal financial ledger transactions are PRESERVED
        assertEquals(2, fakeTransactionDao.transactions.size)
    }

    @Test
    fun testEditSplitExpense_updatesLinkedExpenseTransaction() = runBlocking {
        val participants = listOf(
            SplitParticipant(id = 601L, name = "Me", isCurrentUser = true, amount = Amount.fromSubunits(100000L)),
            SplitParticipant(id = 602L, name = "Rahul", isCurrentUser = false, amount = Amount.fromSubunits(100000L))
        )

        val splitExpense = SplitExpense(
            id = 95L,
            title = "Weekend Trip",
            totalAmount = Amount.fromSubunits(200000L),
            date = 1000L,
            categoryId = 1L,
            paidBy = "Me",
            splitMethod = SplitMethod.EQUAL,
            addToTransactions = true,
            paymentMethod = PaymentMethod.CASH,
            participants = participants
        )

        splitRepository.insertSplitExpense(splitExpense)
        val originalTx = fakeTransactionDao.transactions.first()

        // Edit split title, amount, and payment method
        val updatedSplit = splitExpense.copy(
            title = "Goa Weekend Trip",
            totalAmount = Amount.fromSubunits(300000L),
            paymentMethod = PaymentMethod.ACCOUNT,
            expenseTransactionId = originalTx.id
        )

        splitRepository.updateSplitExpense(updatedSplit)

        // Transaction is updated without creating duplicate
        assertEquals(1, fakeTransactionDao.transactions.size)
        val updatedTx = fakeTransactionDao.transactions.first()
        assertEquals(300000L, updatedTx.amountSubunits)
        assertEquals("Split – Goa Weekend Trip", updatedTx.note)
        assertEquals(PaymentMethod.ACCOUNT.name, updatedTx.paymentMethod)
    }

    // --- Fake Test Implementations ---

    private class FakeTransactionDao : TransactionDao {
        val transactions = mutableListOf<TransactionEntity>()
        private var idCounter = 1L

        override fun getAllTransactionsWithCategory(): Flow<List<TransactionWithCategory>> =
            flowOf(transactions.map { TransactionWithCategory(it, null) })

        override fun getRecentTransactionsWithCategory(limit: Int): Flow<List<TransactionWithCategory>> =
            flowOf(transactions.take(limit).map { TransactionWithCategory(it, null) })

        override fun getTransactionWithCategoryById(id: Long): Flow<TransactionWithCategory?> =
            flowOf(transactions.find { it.id == id }?.let { TransactionWithCategory(it, null) })

        override suspend fun getTransactionByIdSuspend(id: Long): TransactionEntity? =
            transactions.find { it.id == id }

        override fun getTransactionsBetween(startDate: Long, endDate: Long): Flow<List<TransactionWithCategory>> =
            flowOf(transactions.filter { it.timestamp in startDate..endDate }.map { TransactionWithCategory(it, null) })

        override fun getTotalIncomeSubunits(): Flow<Long> =
            flowOf(transactions.filter { it.type == TransactionType.INCOME.name }.sumOf { it.amountSubunits })

        override fun getTotalExpenseSubunits(): Flow<Long> =
            flowOf(transactions.filter { it.type == TransactionType.EXPENSE.name }.sumOf { it.amountSubunits })

        override suspend fun insertTransaction(transaction: TransactionEntity): Long {
            val assignedId = if (transaction.id != 0L) transaction.id else idCounter++
            val saved = transaction.copy(id = assignedId)
            transactions.add(saved)
            return assignedId
        }

        override suspend fun insertTransactions(transactions: List<TransactionEntity>) {
            transactions.forEach { insertTransaction(it) }
        }

        override suspend fun updateTransaction(transaction: TransactionEntity) {
            val index = transactions.indexOfFirst { it.id == transaction.id }
            if (index >= 0) {
                transactions[index] = transaction
            }
        }

        override suspend fun deleteTransactionById(id: Long) {
            transactions.removeAll { it.id == id }
        }

        override suspend fun deleteAllTransactions() {
            transactions.clear()
        }
    }

    private class FakeSplitDao : SplitDao {
        val splitExpenses = mutableMapOf<Long, SplitExpenseEntity>()
        val participants = mutableMapOf<Long, SplitParticipantEntity>()
        private var expenseIdCounter = 1L
        private var participantIdCounter = 1L

        override fun getAllSplitExpenses(): Flow<List<SplitExpenseWithDetails>> {
            val list = splitExpenses.values.map { exp ->
                val pList = participants.values.filter { it.splitExpenseId == exp.id }
                SplitExpenseWithDetails(exp, null, pList)
            }
            return flowOf(list)
        }

        override fun getSplitExpensesByGroupId(groupId: Long): Flow<List<SplitExpenseWithDetails>> {
            val list = splitExpenses.values.filter { it.groupId == groupId }.map { exp ->
                val pList = participants.values.filter { it.splitExpenseId == exp.id }
                SplitExpenseWithDetails(exp, null, pList)
            }
            return flowOf(list)
        }

        override fun getSplitExpenseById(id: Long): Flow<SplitExpenseWithDetails?> {
            val exp = splitExpenses[id]
            val details = exp?.let {
                val pList = participants.values.filter { it.splitExpenseId == id }
                SplitExpenseWithDetails(it, null, pList)
            }
            return flowOf(details)
        }

        override suspend fun getSplitExpenseByIdSuspend(id: Long): SplitExpenseWithDetails? {
            val exp = splitExpenses[id] ?: return null
            val pList = participants.values.filter { it.splitExpenseId == id }
            return SplitExpenseWithDetails(exp, null, pList)
        }

        override suspend fun getParticipantById(participantId: Long): SplitParticipantEntity? =
            participants[participantId]

        override suspend fun getParticipantsByExpenseId(expenseId: Long): List<SplitParticipantEntity> =
            participants.values.filter { it.splitExpenseId == expenseId }

        override suspend fun insertExpense(expense: SplitExpenseEntity): Long {
            val assignedId = if (expense.id != 0L) expense.id else expenseIdCounter++
            splitExpenses[assignedId] = expense.copy(id = assignedId)
            return assignedId
        }

        override suspend fun insertExpenses(expenses: List<SplitExpenseEntity>) {
            expenses.forEach { insertExpense(it) }
        }

        override suspend fun insertParticipants(participants: List<SplitParticipantEntity>) {
            participants.forEach {
                val assignedId = if (it.id != 0L) it.id else participantIdCounter++
                this.participants[assignedId] = it.copy(id = assignedId)
            }
        }

        override suspend fun updateExpense(expense: SplitExpenseEntity) {
            splitExpenses[expense.id] = expense
        }

        override suspend fun deleteParticipantsByExpenseId(expenseId: Long) {
            participants.entries.removeAll { it.value.splitExpenseId == expenseId }
        }

        override suspend fun deleteExpenseById(id: Long) {
            splitExpenses.remove(id)
            deleteParticipantsByExpenseId(id)
        }

        override suspend fun deleteAllParticipants() {
            participants.clear()
        }

        override suspend fun deleteAllSplitExpenses() {
            splitExpenses.clear()
            participants.clear()
        }

        override suspend fun updateParticipantSettlement(participantId: Long, status: String, settledAt: Long?) {
            val p = participants[participantId]
            if (p != null) {
                participants[participantId] = p.copy(settlementStatus = status, settledAt = settledAt)
            }
        }

        override suspend fun updateParticipantSettlementWithTransaction(
            participantId: Long,
            status: String,
            settledAt: Long?,
            transactionId: Long?
        ) {
            val p = participants[participantId]
            if (p != null) {
                participants[participantId] = p.copy(
                    settlementStatus = status,
                    settledAt = settledAt,
                    settlementTransactionId = transactionId
                )
            }
        }
    }
}
