package com.vinaynalavade.expensetracker

import com.vinaynalavade.expensetracker.core.model.Amount
import com.vinaynalavade.expensetracker.core.result.AppResult
import com.vinaynalavade.expensetracker.data.local.dao.CategoryDao
import com.vinaynalavade.expensetracker.data.local.dao.ReminderDao
import com.vinaynalavade.expensetracker.data.local.dao.TransactionDao
import com.vinaynalavade.expensetracker.data.local.entity.CategoryEntity
import com.vinaynalavade.expensetracker.data.local.entity.ReminderEntity
import com.vinaynalavade.expensetracker.data.local.entity.TransactionEntity
import com.vinaynalavade.expensetracker.data.local.entity.TransactionWithCategory
import com.vinaynalavade.expensetracker.data.repository.ReminderRepositoryImpl
import com.vinaynalavade.expensetracker.domain.model.PaymentMethod
import com.vinaynalavade.expensetracker.domain.model.Reminder
import com.vinaynalavade.expensetracker.domain.model.ReminderRecurrence
import com.vinaynalavade.expensetracker.domain.model.ReminderType
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.runBlocking
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test
import java.time.LocalDate
import java.time.ZoneId

class ReminderRepositoryTest {

    private lateinit var fakeReminderDao: FakeReminderDao
    private lateinit var fakeTransactionDao: FakeTransactionDao
    private lateinit var fakeCategoryDao: FakeCategoryDao
    private lateinit var repository: ReminderRepositoryImpl
    private val zoneId = ZoneId.systemDefault()

    @Before
    fun setUp() {
        fakeReminderDao = FakeReminderDao()
        fakeTransactionDao = FakeTransactionDao()
        fakeCategoryDao = FakeCategoryDao()
        repository = ReminderRepositoryImpl(
            reminderDao = fakeReminderDao,
            transactionDao = fakeTransactionDao,
            categoryDao = fakeCategoryDao,
            ioDispatcher = Dispatchers.Unconfined
        )
    }

    @Test
    fun testSaveAndGetReminders() = runBlocking {
        val dueDateMillis = LocalDate.of(2026, 10, 25).atStartOfDay(zoneId).toInstant().toEpochMilli()
        val reminder = Reminder(
            id = 0L,
            title = "Personal Loan EMI",
            amount = Amount.fromSubunits(850000L),
            type = ReminderType.LOAN_EMI,
            dueDate = dueDateMillis,
            recurrence = ReminderRecurrence.MONTHLY,
            reminderOffsetDays = 1,
            configuredDayOfMonth = 25
        )

        val saveResult = repository.saveReminder(reminder)
        assertTrue(saveResult is AppResult.Success)
        val savedId = (saveResult as AppResult.Success).data
        assertTrue(savedId > 0)

        val allReminders = repository.getAllReminders().first()
        assertEquals(1, allReminders.size)
        assertEquals("Personal Loan EMI", allReminders[0].title)
        assertEquals(dueDateMillis, allReminders[0].dueDate)
    }

    @Test
    fun testToggleReminderEnabled() = runBlocking {
        val dueDateMillis = LocalDate.of(2026, 10, 10).atStartOfDay(zoneId).toInstant().toEpochMilli()
        val reminder = Reminder(
            id = 1L,
            title = "Electricity Bill",
            amount = Amount.fromSubunits(120000L),
            type = ReminderType.BILL,
            dueDate = dueDateMillis,
            isEnabled = true
        )
        fakeReminderDao.insertReminder(ReminderEntity.fromDomainModel(reminder))

        val toggleResult = repository.toggleReminderEnabled(1L, false)
        assertTrue(toggleResult is AppResult.Success)

        val updated = repository.getReminderById(1L).first()
        assertNotNull(updated)
        assertFalse(updated!!.isEnabled)
    }

    @Test
    fun testDeleteReminder() = runBlocking {
        val dueDateMillis = LocalDate.of(2026, 10, 10).atStartOfDay(zoneId).toInstant().toEpochMilli()
        val reminder = Reminder(
            id = 5L,
            title = "Test Reminder",
            amount = Amount.fromSubunits(5000L),
            type = ReminderType.CUSTOM,
            dueDate = dueDateMillis,
            recurrence = ReminderRecurrence.ONE_TIME,
            reminderOffsetDays = 0,
            isEnabled = true
        )
        fakeReminderDao.insertReminder(ReminderEntity.fromDomainModel(reminder))

        val deleteResult = repository.deleteReminder(5L)
        assertTrue(deleteResult is AppResult.Success)

        val fetched = repository.getReminderById(5L).first()
        assertNull(fetched)
    }

    @Test
    fun testMarkPaidOneTimeReminder() = runBlocking {
        val dueDateMillis = LocalDate.of(2026, 10, 1).atStartOfDay(zoneId).toInstant().toEpochMilli()
        val reminder = Reminder(
            id = 10L,
            title = "Annual Prime Membership",
            amount = Amount.fromSubunits(149900L),
            type = ReminderType.SUBSCRIPTION,
            dueDate = dueDateMillis,
            recurrence = ReminderRecurrence.ONE_TIME,
            reminderOffsetDays = 1,
            isEnabled = true
        )
        fakeReminderDao.insertReminder(ReminderEntity.fromDomainModel(reminder))

        val markResult = repository.markReminderPaid(10L, recordTransaction = false)
        assertTrue(markResult is AppResult.Success)

        val updated = repository.getReminderById(10L).first()
        assertNotNull(updated)
        assertTrue(updated!!.isPaid) // One-time reminder is marked as isPaid = true
        assertNotNull(updated.lastPaidDate)
        assertEquals(0, fakeTransactionDao.insertedTransactions.size)
    }

    @Test
    fun testMarkPaidWithTransactionCreation() = runBlocking {
        val oct15Millis = LocalDate.of(2026, 10, 15).atStartOfDay(zoneId).toInstant().toEpochMilli()
        val nov15Millis = LocalDate.of(2026, 11, 15).atStartOfDay(zoneId).toInstant().toEpochMilli()

        val reminder = Reminder(
            id = 20L,
            title = "Car Loan EMI",
            amount = Amount.fromSubunits(1250000L),
            type = ReminderType.LOAN_EMI,
            dueDate = oct15Millis,
            recurrence = ReminderRecurrence.MONTHLY,
            reminderOffsetDays = 1,
            configuredDayOfMonth = 15,
            isEnabled = true
        )
        fakeReminderDao.insertReminder(ReminderEntity.fromDomainModel(reminder))

        val markResult = repository.markReminderPaid(20L, recordTransaction = true, paymentMethod = PaymentMethod.CASH)
        assertTrue(markResult is AppResult.Success)

        val updated = repository.getReminderById(20L).first()
        assertNotNull(updated)
        // Recurring reminder advances to next month
        assertEquals(nov15Millis, updated!!.dueDate)
        assertFalse(updated.isPaid) // Ready for next cycle
        assertNotNull(updated.lastPaidDate)

        // Ledger transaction was created
        assertEquals(1, fakeTransactionDao.insertedTransactions.size)
        val tx = fakeTransactionDao.insertedTransactions[0]
        assertEquals("Payment: Car Loan EMI", tx.note)
        assertEquals(1250000L, tx.amountSubunits)
        assertEquals("EXPENSE", tx.type)
        assertEquals("CASH", tx.paymentMethod)
    }

    // --- Fake Room DAO Implementations ---

    class FakeReminderDao : ReminderDao {
        private val storage = mutableMapOf<Long, ReminderEntity>()
        private val flow = MutableStateFlow<List<ReminderEntity>>(emptyList())
        private var idCounter = 1L

        override fun getAllReminders(): Flow<List<ReminderEntity>> = flow

        override fun getActiveReminders(): Flow<List<ReminderEntity>> = flow.map { list ->
            list.filter { it.isEnabled }
        }

        override suspend fun getActiveRemindersSuspend(): List<ReminderEntity> {
            return storage.values.filter { it.isEnabled }
        }

        override fun getReminderById(id: Long): Flow<ReminderEntity?> = flow.map { storage[id] }

        override suspend fun getReminderByIdSuspend(id: Long): ReminderEntity? = storage[id]

        override fun getRemindersBetween(startDate: Long, endDate: Long): Flow<List<ReminderEntity>> = flow.map { list ->
            list.filter { it.dueDate in startDate..endDate }
        }

        override suspend fun insertReminder(reminder: ReminderEntity): Long {
            val id = if (reminder.id <= 0) idCounter++ else reminder.id
            val copy = reminder.copy(id = id)
            storage[id] = copy
            flow.value = storage.values.toList()
            return id
        }

        override suspend fun insertReminders(reminders: List<ReminderEntity>) {
            reminders.forEach { insertReminder(it) }
        }

        override suspend fun updateReminder(reminder: ReminderEntity) {
            storage[reminder.id] = reminder
            flow.value = storage.values.toList()
        }

        override suspend fun updateReminderEnabled(id: Long, isEnabled: Boolean, updatedAt: Long) {
            storage[id]?.let {
                val updated = it.copy(isEnabled = isEnabled, updatedAt = updatedAt)
                storage[id] = updated
                flow.value = storage.values.toList()
            }
        }

        override suspend fun markReminderPaid(
            id: Long,
            isPaid: Boolean,
            lastPaidDate: Long,
            nextDueDate: Long,
            updatedAt: Long
        ) {
            storage[id]?.let {
                val updated = it.copy(
                    isPaid = isPaid,
                    lastPaidDate = lastPaidDate,
                    dueDate = nextDueDate,
                    updatedAt = updatedAt
                )
                storage[id] = updated
                flow.value = storage.values.toList()
            }
        }

        override suspend fun deleteReminderById(id: Long) {
            storage.remove(id)
            flow.value = storage.values.toList()
        }

        override suspend fun deleteAllReminders() {
            storage.clear()
            flow.value = emptyList()
        }
    }

    class FakeCategoryDao : CategoryDao {
        private val categories = mutableListOf(
            CategoryEntity(id = 1L, name = "EMI & Loans", iconName = "account_balance", colorHex = "#DC2626", type = "EXPENSE", isDefault = true),
            CategoryEntity(id = 2L, name = "Bills & Utilities", iconName = "receipt_long", colorHex = "#3B82F6", type = "EXPENSE", isDefault = true),
            CategoryEntity(id = 3L, name = "Housing & Rent", iconName = "home", colorHex = "#F97316", type = "EXPENSE", isDefault = true),
            CategoryEntity(id = 4L, name = "Subscriptions", iconName = "subscriptions", colorHex = "#7C3AED", type = "EXPENSE", isDefault = true),
            CategoryEntity(id = 5L, name = "Other Expense", iconName = "more_horiz", colorHex = "#64748B", type = "EXPENSE", isDefault = true)
        )

        override fun getAllCategories(): Flow<List<CategoryEntity>> = MutableStateFlow(categories)
        override fun getCategoriesByType(type: String): Flow<List<CategoryEntity>> = MutableStateFlow(categories.filter { it.type == type })
        override fun getCategoryById(id: Long): Flow<CategoryEntity?> = MutableStateFlow(categories.firstOrNull { it.id == id })
        override suspend fun getCategoryByName(name: String): CategoryEntity? = categories.firstOrNull { it.name.equals(name, ignoreCase = true) }
        override suspend fun getCategoryCount(): Int = categories.size
        override suspend fun insertCategories(categories: List<CategoryEntity>) {}
        override suspend fun insertCategory(category: CategoryEntity): Long = 1L
        override suspend fun insertOrUpdateCategories(categories: List<CategoryEntity>) {}
        override suspend fun updateCategory(category: CategoryEntity) {}
        override suspend fun deleteCategoryById(id: Long) {}
        override suspend fun deleteAllCategories() {}
    }

    class FakeTransactionDao : TransactionDao {
        val insertedTransactions = mutableListOf<TransactionEntity>()

        override suspend fun insertTransaction(transaction: TransactionEntity): Long {
            insertedTransactions.add(transaction)
            return insertedTransactions.size.toLong()
        }

        override suspend fun insertTransactions(transactions: List<TransactionEntity>) {
            insertedTransactions.addAll(transactions)
        }

        override fun getAllTransactionsWithCategory(): Flow<List<TransactionWithCategory>> = MutableStateFlow(emptyList())
        override fun getRecentTransactionsWithCategory(limit: Int): Flow<List<TransactionWithCategory>> = MutableStateFlow(emptyList())
        override fun getTransactionWithCategoryById(id: Long): Flow<TransactionWithCategory?> = MutableStateFlow(null)
        override suspend fun getTransactionByIdSuspend(id: Long): TransactionEntity? = null
        override fun getTransactionsBetween(startDate: Long, endDate: Long): Flow<List<TransactionWithCategory>> = MutableStateFlow(emptyList())
        override fun getTotalIncomeSubunits(): Flow<Long> = MutableStateFlow(0L)
        override fun getTotalExpenseSubunits(): Flow<Long> = MutableStateFlow(0L)
        override suspend fun updateTransaction(transaction: TransactionEntity) {}
        override suspend fun deleteTransactionById(id: Long) {}
        override suspend fun deleteAllTransactions() {}
    }
}
