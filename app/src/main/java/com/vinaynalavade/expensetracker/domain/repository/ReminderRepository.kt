package com.vinaynalavade.expensetracker.domain.repository

import com.vinaynalavade.expensetracker.core.result.AppResult
import com.vinaynalavade.expensetracker.domain.model.PaymentMethod
import com.vinaynalavade.expensetracker.domain.model.Reminder
import kotlinx.coroutines.flow.Flow

/**
 * Repository interface contract for managing user payment reminders and obligations.
 */
interface ReminderRepository {
    fun getAllReminders(): Flow<List<Reminder>>
    fun getActiveReminders(): Flow<List<Reminder>>
    fun getReminderById(id: Long): Flow<Reminder?>
    suspend fun getReminderByIdSuspend(id: Long): Reminder?
    fun getRemindersBetween(startDate: Long, endDate: Long): Flow<List<Reminder>>
    suspend fun saveReminder(reminder: Reminder): AppResult<Long>
    suspend fun updateReminder(reminder: Reminder): AppResult<Unit>
    suspend fun deleteReminder(id: Long): AppResult<Unit>
    suspend fun markReminderPaid(
        id: Long,
        recordTransaction: Boolean = false,
        paymentMethod: PaymentMethod = PaymentMethod.CASH
    ): AppResult<Unit>
    suspend fun toggleReminderEnabled(id: Long, isEnabled: Boolean): AppResult<Unit>
    suspend fun deleteAllReminders(): AppResult<Unit>
}
