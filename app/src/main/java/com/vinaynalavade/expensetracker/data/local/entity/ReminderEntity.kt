package com.vinaynalavade.expensetracker.data.local.entity

import androidx.room.ColumnInfo
import androidx.room.Entity
import androidx.room.Index
import androidx.room.PrimaryKey
import com.vinaynalavade.expensetracker.core.model.Amount
import com.vinaynalavade.expensetracker.domain.model.Reminder
import com.vinaynalavade.expensetracker.domain.model.ReminderRecurrence
import com.vinaynalavade.expensetracker.domain.model.ReminderType

@Entity(
    tableName = "reminders",
    indices = [
        Index(value = ["due_date"]),
        Index(value = ["is_enabled"]),
        Index(value = ["type"])
    ]
)
data class ReminderEntity(
    @PrimaryKey(autoGenerate = true)
    @ColumnInfo(name = "id")
    val id: Long = 0L,

    @ColumnInfo(name = "title")
    val title: String,

    @ColumnInfo(name = "description")
    val description: String? = null,

    @ColumnInfo(name = "amount_subunits")
    val amountSubunits: Long,

    @ColumnInfo(name = "type")
    val type: String,

    @ColumnInfo(name = "due_date")
    val dueDate: Long,

    @ColumnInfo(name = "recurrence")
    val recurrence: String,

    @ColumnInfo(name = "configured_day_of_month", defaultValue = "1")
    val configuredDayOfMonth: Int = 1,

    @ColumnInfo(name = "reminder_offset_days", defaultValue = "1")
    val reminderOffsetDays: Int = 1,

    @ColumnInfo(name = "additional_offsets")
    val additionalOffsets: String? = null,

    @ColumnInfo(name = "notification_hour", defaultValue = "9")
    val notificationHour: Int = 9,

    @ColumnInfo(name = "notification_minute", defaultValue = "0")
    val notificationMinute: Int = 0,

    @ColumnInfo(name = "is_enabled", defaultValue = "1")
    val isEnabled: Boolean = true,

    @ColumnInfo(name = "is_paid", defaultValue = "0")
    val isPaid: Boolean = false,

    @ColumnInfo(name = "last_paid_date")
    val lastPaidDate: Long? = null,

    @ColumnInfo(name = "created_at")
    val createdAt: Long = System.currentTimeMillis(),

    @ColumnInfo(name = "updated_at")
    val updatedAt: Long = System.currentTimeMillis()
) {
    fun toDomainModel(): Reminder {
        return Reminder(
            id = id,
            title = title,
            description = description,
            amount = Amount.fromSubunits(amountSubunits),
            type = ReminderType.fromString(type),
            dueDate = dueDate,
            recurrence = ReminderRecurrence.fromString(recurrence),
            configuredDayOfMonth = configuredDayOfMonth,
            reminderOffsetDays = reminderOffsetDays,
            additionalOffsets = additionalOffsets,
            notificationHour = notificationHour,
            notificationMinute = notificationMinute,
            isEnabled = isEnabled,
            isPaid = isPaid,
            lastPaidDate = lastPaidDate,
            createdAt = createdAt,
            updatedAt = updatedAt
        )
    }

    companion object {
        fun fromDomainModel(reminder: Reminder): ReminderEntity {
            return ReminderEntity(
                id = reminder.id,
                title = reminder.title,
                description = reminder.description,
                amountSubunits = reminder.amount.subunits,
                type = reminder.type.name,
                dueDate = reminder.dueDate,
                recurrence = reminder.recurrence.name,
                configuredDayOfMonth = reminder.configuredDayOfMonth,
                reminderOffsetDays = reminder.reminderOffsetDays,
                additionalOffsets = reminder.additionalOffsets,
                notificationHour = reminder.notificationHour,
                notificationMinute = reminder.notificationMinute,
                isEnabled = reminder.isEnabled,
                isPaid = reminder.isPaid,
                lastPaidDate = reminder.lastPaidDate,
                createdAt = reminder.createdAt,
                updatedAt = reminder.updatedAt
            )
        }
    }
}
