package com.vinaynalavade.expensetracker.domain.model

import com.vinaynalavade.expensetracker.core.model.Amount
import java.time.Instant
import java.time.LocalDate
import java.time.YearMonth
import java.time.ZoneId

/**
 * Supported reminder categories / financial obligation types.
 * Extensible for future obligation types.
 */
enum class ReminderType(val displayName: String) {
    LOAN_EMI("Loan / EMI"),
    CREDIT_CARD("Credit Card"),
    BILL("Bill & Utility"),
    INSURANCE("Insurance"),
    RENT("Rent"),
    SUBSCRIPTION("Subscription"),
    CUSTOM("Custom");

    companion object {
        fun fromString(value: String): ReminderType {
            return entries.firstOrNull { it.name.equals(value.trim(), ignoreCase = true) } ?: CUSTOM
        }
    }
}

/**
 * Supported recurrence frequencies for reminders.
 */
enum class ReminderRecurrence(val displayName: String) {
    ONE_TIME("One-time"),
    DAILY("Daily"),
    WEEKLY("Weekly"),
    MONTHLY("Monthly"),
    YEARLY("Yearly");

    companion object {
        fun fromString(value: String): ReminderRecurrence {
            return entries.firstOrNull { it.name.equals(value.trim(), ignoreCase = true) } ?: MONTHLY
        }
    }
}

/**
 * Predefined reminder advance offsets in days before due date.
 */
enum class ReminderOffsetOption(val daysBefore: Int, val label: String) {
    ON_DUE_DATE(0, "On due date"),
    ONE_DAY_BEFORE(1, "1 day before"),
    TWO_DAYS_BEFORE(2, "2 days before"),
    THREE_DAYS_BEFORE(3, "3 days before"),
    FIVE_DAYS_BEFORE(5, "5 days before"),
    SEVEN_DAYS_BEFORE(7, "7 days before"),
    CUSTOM(-1, "Custom");

    companion object {
        fun fromDays(days: Int): ReminderOffsetOption {
            return entries.firstOrNull { it.daysBefore == days } ?: CUSTOM
        }
    }
}

/**
 * Domain model representing a user-created financial reminder / payment obligation.
 */
data class Reminder(
    val id: Long = 0L,
    val title: String,
    val description: String? = null,
    val amount: Amount,
    val type: ReminderType = ReminderType.LOAN_EMI,
    val dueDate: Long, // Epoch millis of next due date
    val recurrence: ReminderRecurrence = ReminderRecurrence.MONTHLY,
    val configuredDayOfMonth: Int = 1, // 1..31, used for monthly/yearly recurrence pinning
    val reminderOffsetDays: Int = 1, // Primary reminder offset (e.g. 1 day before)
    val additionalOffsets: String? = null, // Secondary comma-separated offsets (e.g. "0,7")
    val notificationHour: Int = 9, // 0..23 (e.g. 9 AM)
    val notificationMinute: Int = 0, // 0..59
    val isEnabled: Boolean = true,
    val isPaid: Boolean = false, // Paid status for current cycle
    val lastPaidDate: Long? = null,
    val createdAt: Long = System.currentTimeMillis(),
    val updatedAt: Long = System.currentTimeMillis()
) {
    /**
     * Returns all enabled reminder offsets in days before the due date,
     * combining the primary offset and any additional offsets without duplicates.
     */
    fun getAllOffsets(): List<Int> {
        val offsets = mutableSetOf<Int>()
        offsets.add(reminderOffsetDays)
        additionalOffsets?.split(",")?.forEach { str ->
            str.trim().toIntOrNull()?.let { offsets.add(it) }
        }
        return offsets.sorted()
    }

    /**
     * Checks if this reminder is due within the given number of days from today.
     */
    fun isDueWithin(days: Int, zoneId: ZoneId = ZoneId.systemDefault()): Boolean {
        val today = LocalDate.now(zoneId)
        val dueLocalDate = Instant.ofEpochMilli(dueDate).atZone(zoneId).toLocalDate()
        val daysUntil = java.time.temporal.ChronoUnit.DAYS.between(today, dueLocalDate)
        return daysUntil in 0..days
    }

    /**
     * Calculates the next due date based on recurrence rules.
     * Safely handles month-end clamping (28th, 29th, 30th, 31st).
     */
    fun calculateNextDueDate(fromEpochMillis: Long = dueDate, zoneId: ZoneId = ZoneId.systemDefault()): Long {
        val current = Instant.ofEpochMilli(fromEpochMillis).atZone(zoneId).toLocalDate()
        val nextDate: LocalDate = when (recurrence) {
            ReminderRecurrence.ONE_TIME -> current
            ReminderRecurrence.DAILY -> current.plusDays(1)
            ReminderRecurrence.WEEKLY -> current.plusWeeks(1)
            ReminderRecurrence.MONTHLY -> {
                // Next month clamped to month length, keeping target day of month
                val nextYearMonth = YearMonth.from(current).plusMonths(1)
                val targetDay = minOf(configuredDayOfMonth, nextYearMonth.lengthOfMonth())
                nextYearMonth.atDay(targetDay)
            }
            ReminderRecurrence.YEARLY -> {
                val nextYear = current.year + 1
                val month = current.month
                val isLeap = java.time.Year.of(nextYear).isLeap
                val maxDay = month.length(isLeap)
                val targetDay = minOf(configuredDayOfMonth, maxDay)
                LocalDate.of(nextYear, month, targetDay)
            }
        }
        return nextDate.atStartOfDay(zoneId).toInstant().toEpochMilli()
    }
}
