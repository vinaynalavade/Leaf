package com.vinaynalavade.expensetracker.core.receiver

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import com.vinaynalavade.expensetracker.ExpenseTrackerApp
import com.vinaynalavade.expensetracker.core.notification.NotificationHelper
import com.vinaynalavade.expensetracker.core.utils.DateTimeUtils
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.firstOrNull
import kotlinx.coroutines.launch
import java.time.LocalDate

/**
 * Receiver invoked by AlarmManager to handle smart daily reminders and recurring transaction processing.
 * Suppresses daily reminders if any transaction (Expense or Income) was already recorded today.
 */
class ReminderReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        val app = context.applicationContext as? ExpenseTrackerApp ?: return
        val container = app.container

        val pendingResult = goAsync()

        CoroutineScope(Dispatchers.IO).launch {
            try {
                when (intent.action) {
                    NotificationHelper.ACTION_DAILY_REMINDER -> {
                        val prefs = container.getUserPreferencesUseCase().firstOrNull()

                        if (prefs != null && prefs.notificationsMasterEnabled && prefs.dailyReminderEnabled) {
                            // 1. Smart Check: Has user recorded any transaction today?
                            val todayStartEpoch = DateTimeUtils.getStartOfDayEpoch(LocalDate.now())
                            val todayEndEpoch = DateTimeUtils.getEndOfDayEpoch(LocalDate.now())

                            val todayTransactions = container.transactionRepository
                                .getTransactionsBetween(todayStartEpoch, todayEndEpoch)
                                .firstOrNull() ?: emptyList()

                            // Suppress notification if at least 1 transaction already recorded today
                            if (todayTransactions.isEmpty()) {
                                NotificationHelper.showDailyReminderNotification(context)
                            }

                            // 2. Schedule next occurrence for tomorrow at the configured time
                            container.dailyReminderScheduler.schedule(
                                prefs.dailyReminderHour,
                                prefs.dailyReminderMinute
                            )
                        } else {
                            container.dailyReminderScheduler.cancel()
                        }
                    }

                    NotificationHelper.ACTION_CHECK_FINANCIAL_REMINDERS,
                    NotificationHelper.ACTION_EMI_REMINDER -> {
                        // Process due recurring transactions, budget alerts, and upcoming bills
                        container.processFinancialRemindersUseCase()

                        val prefs = container.getUserPreferencesUseCase().firstOrNull()
                        if (prefs != null && prefs.notificationsMasterEnabled &&
                            (prefs.budgetAlertsEnabled || prefs.recurringRemindersEnabled)
                        ) {
                            container.dailyReminderScheduler.scheduleFinancialChecks()
                        }
                    }

                    NotificationHelper.ACTION_REMINDER_ALERT -> {
                        val reminderId = intent.getLongExtra(NotificationHelper.EXTRA_REMINDER_ID, -1L)
                        val offset = intent.getIntExtra(NotificationHelper.EXTRA_REMINDER_OFFSET, 0)
                        if (reminderId > 0) {
                            val reminder = container.reminderRepository.getReminderByIdSuspend(reminderId)
                            val prefs = container.getUserPreferencesUseCase().firstOrNull()
                            if (reminder != null && reminder.isEnabled && !reminder.isPaid) {
                                val isTypeAllowed = when (reminder.type) {
                                    com.vinaynalavade.expensetracker.domain.model.ReminderType.LOAN_EMI -> prefs?.emiRemindersEnabled ?: true
                                    com.vinaynalavade.expensetracker.domain.model.ReminderType.BILL -> prefs?.billRemindersEnabled ?: true
                                    com.vinaynalavade.expensetracker.domain.model.ReminderType.CREDIT_CARD -> prefs?.creditCardRemindersEnabled ?: true
                                    else -> true
                                }
                                if (prefs?.notificationsMasterEnabled != false && isTypeAllowed) {
                                    val currency = prefs?.currency ?: com.vinaynalavade.expensetracker.core.model.Currency.DEFAULT
                                    com.vinaynalavade.expensetracker.core.notification.ReminderNotificationManager.showReminderNotification(
                                        context = context,
                                        reminder = reminder,
                                        offsetDays = offset,
                                        currency = currency
                                    )
                                }
                            }
                        }
                    }

                    NotificationHelper.ACTION_REMINDER_MARK_PAID -> {
                        val reminderId = intent.getLongExtra(NotificationHelper.EXTRA_REMINDER_ID, -1L)
                        if (reminderId > 0) {
                            container.markReminderPaidUseCase(reminderId, recordTransaction = false)
                            val notificationId = NotificationHelper.NOTIFICATION_ID_REMINDER_BASE + (reminderId % 1000).toInt()
                            androidx.core.app.NotificationManagerCompat.from(context).cancel(notificationId)
                        }
                    }

                    NotificationHelper.ACTION_REMINDER_SNOOZE -> {
                        val reminderId = intent.getLongExtra(NotificationHelper.EXTRA_REMINDER_ID, -1L)
                        if (reminderId > 0) {
                            container.reminderScheduler.snoozeReminder(reminderId)
                            val notificationId = NotificationHelper.NOTIFICATION_ID_REMINDER_BASE + (reminderId % 1000).toInt()
                            androidx.core.app.NotificationManagerCompat.from(context).cancel(notificationId)
                        }
                    }
                }
            } catch (_: Exception) {
                // Fail silently without crashing
            } finally {
                pendingResult.finish()
            }
        }
    }
}
