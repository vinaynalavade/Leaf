package com.vinaynalavade.expensetracker.data.local.dao

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import androidx.room.Update
import com.vinaynalavade.expensetracker.data.local.entity.ReminderEntity
import kotlinx.coroutines.flow.Flow

@Dao
interface ReminderDao {

    @Query("SELECT * FROM reminders ORDER BY due_date ASC, id ASC")
    fun getAllReminders(): Flow<List<ReminderEntity>>

    @Query("SELECT * FROM reminders WHERE is_enabled = 1 ORDER BY due_date ASC, id ASC")
    fun getActiveReminders(): Flow<List<ReminderEntity>>

    @Query("SELECT * FROM reminders WHERE is_enabled = 1")
    suspend fun getActiveRemindersSuspend(): List<ReminderEntity>

    @Query("SELECT * FROM reminders WHERE id = :id LIMIT 1")
    fun getReminderById(id: Long): Flow<ReminderEntity?>

    @Query("SELECT * FROM reminders WHERE id = :id LIMIT 1")
    suspend fun getReminderByIdSuspend(id: Long): ReminderEntity?

    @Query("SELECT * FROM reminders WHERE due_date >= :startDate AND due_date <= :endDate ORDER BY due_date ASC")
    fun getRemindersBetween(startDate: Long, endDate: Long): Flow<List<ReminderEntity>>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertReminder(reminder: ReminderEntity): Long

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertReminders(reminders: List<ReminderEntity>)

    @Update
    suspend fun updateReminder(reminder: ReminderEntity)

    @Query("UPDATE reminders SET is_enabled = :isEnabled, updated_at = :updatedAt WHERE id = :id")
    suspend fun updateReminderEnabled(id: Long, isEnabled: Boolean, updatedAt: Long = System.currentTimeMillis())

    @Query("UPDATE reminders SET is_paid = :isPaid, last_paid_date = :lastPaidDate, due_date = :nextDueDate, updated_at = :updatedAt WHERE id = :id")
    suspend fun markReminderPaid(
        id: Long,
        isPaid: Boolean,
        lastPaidDate: Long,
        nextDueDate: Long,
        updatedAt: Long = System.currentTimeMillis()
    )

    @Query("DELETE FROM reminders WHERE id = :id")
    suspend fun deleteReminderById(id: Long)

    @Query("DELETE FROM reminders")
    suspend fun deleteAllReminders()
}
