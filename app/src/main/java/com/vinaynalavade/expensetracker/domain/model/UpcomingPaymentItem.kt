package com.vinaynalavade.expensetracker.domain.model

import com.vinaynalavade.expensetracker.core.model.Amount
import java.time.LocalDate

/**
 * Unified model for upcoming payment items displayed across
 * Dashboard Upcoming Payments, Payment Calendar, and Planning section.
 */
data class UpcomingPaymentItem(
    val id: String, // e.g. "reminder_1" or "recurring_2"
    val sourceId: Long,
    val title: String,
    val amount: Amount,
    val type: ReminderType,
    val dueDate: LocalDate,
    val isRecurring: Boolean,
    val recurrenceLabel: String,
    val isOverdue: Boolean,
    val isDueToday: Boolean,
    val daysRemaining: Int, // < 0: Overdue, 0: Today, 1: Tomorrow, > 1: Future
    val reminder: Reminder? = null,
    val recurringTransaction: RecurringTransaction? = null
)
