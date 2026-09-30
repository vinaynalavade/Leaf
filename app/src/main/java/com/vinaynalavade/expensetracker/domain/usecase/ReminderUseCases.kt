package com.vinaynalavade.expensetracker.domain.usecase

import com.vinaynalavade.expensetracker.core.model.Amount
import com.vinaynalavade.expensetracker.core.notification.ReminderScheduler
import com.vinaynalavade.expensetracker.core.result.AppError
import com.vinaynalavade.expensetracker.core.result.AppResult
import com.vinaynalavade.expensetracker.domain.model.PaymentMethod
import com.vinaynalavade.expensetracker.domain.model.Reminder
import com.vinaynalavade.expensetracker.domain.model.ReminderRecurrence
import com.vinaynalavade.expensetracker.domain.model.ReminderType
import com.vinaynalavade.expensetracker.domain.model.UpcomingPaymentItem
import com.vinaynalavade.expensetracker.domain.repository.RecurringTransactionRepository
import com.vinaynalavade.expensetracker.domain.repository.ReminderRepository
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.combine
import java.time.Instant
import java.time.LocalDate
import java.time.ZoneId
import java.time.temporal.ChronoUnit

class GetRemindersUseCase(
    private val reminderRepository: ReminderRepository
) {
    operator fun invoke(): Flow<List<Reminder>> {
        return reminderRepository.getAllReminders()
    }
}

class GetReminderByIdUseCase(
    private val reminderRepository: ReminderRepository
) {
    operator fun invoke(id: Long): Flow<Reminder?> {
        return reminderRepository.getReminderById(id)
    }

    suspend fun getSuspend(id: Long): Reminder? {
        return reminderRepository.getReminderByIdSuspend(id)
    }
}

class SaveReminderUseCase(
    private val reminderRepository: ReminderRepository,
    private val reminderScheduler: ReminderScheduler
) {
    suspend operator fun invoke(reminder: Reminder): AppResult<Long> {
        if (reminder.title.isBlank()) {
            return AppResult.Error(AppError.ValidationError("Reminder title cannot be empty."))
        }
        if (reminder.amount.subunits <= 0) {
            return AppResult.Error(AppError.ValidationError("Reminder amount must be greater than zero."))
        }

        val result = reminderRepository.saveReminder(reminder)
        if (result is AppResult.Success) {
            val savedReminder = reminder.copy(id = result.data)
            if (savedReminder.isEnabled && !savedReminder.isPaid) {
                reminderScheduler.scheduleReminder(savedReminder)
            } else {
                reminderScheduler.cancelReminder(savedReminder)
            }
        }
        return result
    }
}

class DeleteReminderUseCase(
    private val reminderRepository: ReminderRepository,
    private val reminderScheduler: ReminderScheduler
) {
    suspend operator fun invoke(id: Long): AppResult<Unit> {
        val existing = reminderRepository.getReminderByIdSuspend(id)
        if (existing != null) {
            reminderScheduler.cancelReminder(existing)
        }
        return reminderRepository.deleteReminder(id)
    }
}

class MarkReminderPaidUseCase(
    private val reminderRepository: ReminderRepository,
    private val reminderScheduler: ReminderScheduler
) {
    suspend operator fun invoke(
        id: Long,
        recordTransaction: Boolean = false,
        paymentMethod: PaymentMethod = PaymentMethod.CASH
    ): AppResult<Unit> {
        val result = reminderRepository.markReminderPaid(id, recordTransaction, paymentMethod)
        if (result is AppResult.Success) {
            val updated = reminderRepository.getReminderByIdSuspend(id)
            if (updated != null) {
                if (updated.isEnabled && !updated.isPaid) {
                    reminderScheduler.scheduleReminder(updated)
                } else {
                    reminderScheduler.cancelReminder(updated)
                }
            }
        }
        return result
    }
}

class ToggleReminderEnabledUseCase(
    private val reminderRepository: ReminderRepository,
    private val reminderScheduler: ReminderScheduler
) {
    suspend operator fun invoke(id: Long, isEnabled: Boolean): AppResult<Unit> {
        val result = reminderRepository.toggleReminderEnabled(id, isEnabled)
        if (result is AppResult.Success) {
            val updated = reminderRepository.getReminderByIdSuspend(id)
            if (updated != null) {
                if (isEnabled && !updated.isPaid) {
                    reminderScheduler.scheduleReminder(updated)
                } else {
                    reminderScheduler.cancelReminder(updated)
                }
            }
        }
        return result
    }
}

class GetUpcomingPaymentsUseCase(
    private val reminderRepository: ReminderRepository,
    private val recurringTransactionRepository: RecurringTransactionRepository
) {
    operator fun invoke(
        daysAhead: Int = 30,
        zoneId: ZoneId = ZoneId.systemDefault()
    ): Flow<List<UpcomingPaymentItem>> {
        return combine(
            reminderRepository.getActiveReminders(),
            recurringTransactionRepository.getRecurringTransactions()
        ) { reminders, allRecurring ->
            val recurringTransactions = allRecurring.filter { it.isEnabled }
            val today = LocalDate.now(zoneId)
            val items = mutableListOf<UpcomingPaymentItem>()

            // 1. Process active reminders
            for (reminder in reminders) {
                if (reminder.isPaid && reminder.recurrence == ReminderRecurrence.ONE_TIME) {
                    continue
                }
                val dueLocalDate = Instant.ofEpochMilli(reminder.dueDate).atZone(zoneId).toLocalDate()
                val daysRemaining = ChronoUnit.DAYS.between(today, dueLocalDate).toInt()

                // Include overdue and items up to daysAhead
                if (daysRemaining <= daysAhead) {
                    items.add(
                        UpcomingPaymentItem(
                            id = "reminder_${reminder.id}",
                            sourceId = reminder.id,
                            title = reminder.title,
                            amount = reminder.amount,
                            type = reminder.type,
                            dueDate = dueLocalDate,
                            isRecurring = reminder.recurrence != ReminderRecurrence.ONE_TIME,
                            recurrenceLabel = reminder.recurrence.displayName,
                            isOverdue = daysRemaining < 0,
                            isDueToday = daysRemaining == 0,
                            daysRemaining = daysRemaining,
                            reminder = reminder
                        )
                    )
                }
            }

            // 2. Process active recurring transactions (only expense items that don't duplicate reminders)
            for (recurring in recurringTransactions) {
                if (recurring.type != com.vinaynalavade.expensetracker.domain.model.TransactionType.EXPENSE) {
                    continue
                }
                // Determine next occurrence date for this recurring transaction
                val dueLocalDate = calculateNextRecurringDate(recurring, today)
                val daysRemaining = ChronoUnit.DAYS.between(today, dueLocalDate).toInt()

                // Avoid duplicating if a reminder exists with the same title
                val hasMatchingReminder = reminders.any {
                    it.title.equals(recurring.title, ignoreCase = true)
                }
                if (!hasMatchingReminder && daysRemaining in -3..daysAhead) {
                    val inferredType = inferReminderType(recurring.category.name, recurring.title)
                    items.add(
                        UpcomingPaymentItem(
                            id = "recurring_${recurring.id}",
                            sourceId = recurring.id,
                            title = recurring.title,
                            amount = recurring.amount,
                            type = inferredType,
                            dueDate = dueLocalDate,
                            isRecurring = true,
                            recurrenceLabel = recurring.frequency.displayName,
                            isOverdue = daysRemaining < 0,
                            isDueToday = daysRemaining == 0,
                            daysRemaining = daysRemaining,
                            recurringTransaction = recurring
                        )
                    )
                }
            }

            // Sort: Overdue first (most overdue at top), then today, tomorrow, chronologically
            items.sortedWith(
                compareBy<UpcomingPaymentItem> { it.dueDate }
                    .thenBy { it.title }
            )
        }
    }

    private fun calculateNextRecurringDate(
        recurring: com.vinaynalavade.expensetracker.domain.model.RecurringTransaction,
        today: LocalDate
    ): LocalDate {
        return when (recurring.frequency) {
            com.vinaynalavade.expensetracker.domain.model.RecurrenceFrequency.DAILY -> today
            com.vinaynalavade.expensetracker.domain.model.RecurrenceFrequency.WEEKLY -> {
                var candidate = today
                while (candidate.dayOfWeek.value != recurring.dayOfWeek) {
                    candidate = candidate.plusDays(1)
                }
                candidate
            }
            com.vinaynalavade.expensetracker.domain.model.RecurrenceFrequency.MONTHLY -> {
                val currentMonth = java.time.YearMonth.from(today)
                val dayClamped = minOf(recurring.dayOfMonth, currentMonth.lengthOfMonth())
                val thisMonthDate = currentMonth.atDay(dayClamped)
                if (!thisMonthDate.isBefore(today)) {
                    thisMonthDate
                } else {
                    val nextMonth = currentMonth.plusMonths(1)
                    val nextDayClamped = minOf(recurring.dayOfMonth, nextMonth.lengthOfMonth())
                    nextMonth.atDay(nextDayClamped)
                }
            }
            com.vinaynalavade.expensetracker.domain.model.RecurrenceFrequency.YEARLY -> {
                val thisYearDate = LocalDate.of(
                    today.year,
                    java.time.Month.JANUARY,
                    minOf(recurring.dayOfMonth, 31)
                )
                if (!thisYearDate.isBefore(today)) thisYearDate else thisYearDate.plusYears(1)
            }
        }
    }

    private fun inferReminderType(categoryName: String, title: String): ReminderType {
        val lowerCategory = categoryName.lowercase()
        val lowerTitle = title.lowercase()
        return when {
            lowerCategory.contains("loan") || lowerCategory.contains("emi") || lowerTitle.contains("loan") || lowerTitle.contains("emi") -> ReminderType.LOAN_EMI
            lowerCategory.contains("credit") || lowerTitle.contains("credit card") || lowerTitle.contains("cc bill") -> ReminderType.CREDIT_CARD
            lowerCategory.contains("rent") || lowerTitle.contains("rent") -> ReminderType.RENT
            lowerCategory.contains("subscription") || lowerTitle.contains("netflix") || lowerTitle.contains("spotify") || lowerTitle.contains("prime") -> ReminderType.SUBSCRIPTION
            lowerCategory.contains("insurance") || lowerTitle.contains("insurance") || lowerTitle.contains("lic") -> ReminderType.INSURANCE
            lowerCategory.contains("bill") || lowerCategory.contains("utility") || lowerTitle.contains("bill") || lowerTitle.contains("electricity") || lowerTitle.contains("wifi") -> ReminderType.BILL
            else -> ReminderType.CUSTOM
        }
    }
}
