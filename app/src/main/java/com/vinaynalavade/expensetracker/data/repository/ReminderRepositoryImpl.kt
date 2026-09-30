package com.vinaynalavade.expensetracker.data.repository

import com.vinaynalavade.expensetracker.core.result.AppError
import com.vinaynalavade.expensetracker.core.result.AppResult
import com.vinaynalavade.expensetracker.data.local.dao.CategoryDao
import com.vinaynalavade.expensetracker.data.local.dao.ReminderDao
import com.vinaynalavade.expensetracker.data.local.dao.TransactionDao
import com.vinaynalavade.expensetracker.data.local.entity.ReminderEntity
import com.vinaynalavade.expensetracker.data.local.entity.TransactionEntity
import com.vinaynalavade.expensetracker.domain.model.PaymentMethod
import com.vinaynalavade.expensetracker.domain.model.Reminder
import com.vinaynalavade.expensetracker.domain.model.ReminderRecurrence
import com.vinaynalavade.expensetracker.domain.model.ReminderType
import com.vinaynalavade.expensetracker.domain.model.TransactionType
import com.vinaynalavade.expensetracker.domain.repository.ReminderRepository
import kotlinx.coroutines.CoroutineDispatcher
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.firstOrNull
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.withContext

class ReminderRepositoryImpl(
    private val reminderDao: ReminderDao,
    private val transactionDao: TransactionDao,
    private val categoryDao: CategoryDao,
    private val ioDispatcher: CoroutineDispatcher = Dispatchers.IO
) : ReminderRepository {

    override fun getAllReminders(): Flow<List<Reminder>> {
        return reminderDao.getAllReminders().map { list -> list.map { it.toDomainModel() } }
    }

    override fun getActiveReminders(): Flow<List<Reminder>> {
        return reminderDao.getActiveReminders().map { list -> list.map { it.toDomainModel() } }
    }

    override fun getReminderById(id: Long): Flow<Reminder?> {
        return reminderDao.getReminderById(id).map { it?.toDomainModel() }
    }

    override suspend fun getReminderByIdSuspend(id: Long): Reminder? = withContext(ioDispatcher) {
        reminderDao.getReminderByIdSuspend(id)?.toDomainModel()
    }

    override fun getRemindersBetween(startDate: Long, endDate: Long): Flow<List<Reminder>> {
        return reminderDao.getRemindersBetween(startDate, endDate).map { list -> list.map { it.toDomainModel() } }
    }

    override suspend fun saveReminder(reminder: Reminder): AppResult<Long> = withContext(ioDispatcher) {
        try {
            val entity = ReminderEntity.fromDomainModel(reminder)
            val id = reminderDao.insertReminder(entity)
            AppResult.Success(id)
        } catch (e: Exception) {
            AppResult.Error(AppError.DatabaseError("Failed to save reminder: ${e.message}", e))
        }
    }

    override suspend fun updateReminder(reminder: Reminder): AppResult<Unit> = withContext(ioDispatcher) {
        try {
            val entity = ReminderEntity.fromDomainModel(reminder)
            reminderDao.updateReminder(entity)
            AppResult.Success(Unit)
        } catch (e: Exception) {
            AppResult.Error(AppError.DatabaseError("Failed to update reminder: ${e.message}", e))
        }
    }

    override suspend fun deleteReminder(id: Long): AppResult<Unit> = withContext(ioDispatcher) {
        try {
            reminderDao.deleteReminderById(id)
            AppResult.Success(Unit)
        } catch (e: Exception) {
            AppResult.Error(AppError.DatabaseError("Failed to delete reminder: ${e.message}", e))
        }
    }

    override suspend fun markReminderPaid(
        id: Long,
        recordTransaction: Boolean,
        paymentMethod: PaymentMethod
    ): AppResult<Unit> = withContext(ioDispatcher) {
        try {
            val existing = reminderDao.getReminderByIdSuspend(id)
                ?: return@withContext AppResult.Error(AppError.DatabaseError("Reminder not found with id $id"))

            val domain = existing.toDomainModel()
            val now = System.currentTimeMillis()

            // 1. Optionally record transaction in ledger without creating duplicates
            if (recordTransaction) {
                val targetCategoryName = when (domain.type) {
                    ReminderType.LOAN_EMI -> "EMI & Loans"
                    ReminderType.CREDIT_CARD -> "Bills & Utilities"
                    ReminderType.BILL -> "Bills & Utilities"
                    ReminderType.INSURANCE -> "Bills & Utilities"
                    ReminderType.RENT -> "Housing & Rent"
                    ReminderType.SUBSCRIPTION -> "Subscriptions"
                    ReminderType.CUSTOM -> "Other Expense"
                }

                val allCategories = categoryDao.getAllCategories().firstOrNull() ?: emptyList()
                val matchedCategory = allCategories.firstOrNull {
                    it.name.equals(targetCategoryName, ignoreCase = true) && it.type == "EXPENSE"
                } ?: allCategories.firstOrNull { it.type == "EXPENSE" }

                if (matchedCategory != null) {
                    val transactionEntity = TransactionEntity(
                        amountSubunits = domain.amount.subunits,
                        type = TransactionType.EXPENSE.name,
                        categoryId = matchedCategory.id,
                        paymentMethod = paymentMethod.name,
                        note = "Payment: ${domain.title}",
                        timestamp = now,
                        createdAt = now,
                        updatedAt = now
                    )
                    transactionDao.insertTransaction(transactionEntity)
                }
            }

            // 2. Advance due date or mark completed
            if (domain.recurrence == ReminderRecurrence.ONE_TIME) {
                reminderDao.markReminderPaid(
                    id = id,
                    isPaid = true,
                    lastPaidDate = now,
                    nextDueDate = domain.dueDate,
                    updatedAt = now
                )
            } else {
                val nextDueDate = domain.calculateNextDueDate(domain.dueDate)
                reminderDao.markReminderPaid(
                    id = id,
                    isPaid = false, // Ready for next cycle
                    lastPaidDate = now,
                    nextDueDate = nextDueDate,
                    updatedAt = now
                )
            }

            AppResult.Success(Unit)
        } catch (e: Exception) {
            AppResult.Error(AppError.DatabaseError("Failed to mark reminder as paid: ${e.message}", e))
        }
    }

    override suspend fun toggleReminderEnabled(id: Long, isEnabled: Boolean): AppResult<Unit> = withContext(ioDispatcher) {
        try {
            reminderDao.updateReminderEnabled(id, isEnabled)
            AppResult.Success(Unit)
        } catch (e: Exception) {
            AppResult.Error(AppError.DatabaseError("Failed to update reminder status: ${e.message}", e))
        }
    }

    override suspend fun deleteAllReminders(): AppResult<Unit> = withContext(ioDispatcher) {
        try {
            reminderDao.deleteAllReminders()
            AppResult.Success(Unit)
        } catch (e: Exception) {
            AppResult.Error(AppError.DatabaseError("Failed to delete all reminders: ${e.message}", e))
        }
    }
}
