package com.vinaynalavade.expensetracker.core.notification

import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import com.vinaynalavade.expensetracker.MainActivity
import com.vinaynalavade.expensetracker.R
import com.vinaynalavade.expensetracker.core.model.Currency
import com.vinaynalavade.expensetracker.core.receiver.ReminderReceiver
import com.vinaynalavade.expensetracker.core.utils.DateTimeUtils
import com.vinaynalavade.expensetracker.domain.model.Reminder
import com.vinaynalavade.expensetracker.domain.model.ReminderType

object ReminderNotificationManager {

    fun showReminderNotification(
        context: Context,
        reminder: Reminder,
        offsetDays: Int,
        currency: Currency = Currency.DEFAULT
    ) {
        val title = when (reminder.type) {
            ReminderType.LOAN_EMI -> "Loan Payment Reminder"
            ReminderType.CREDIT_CARD -> "Credit Card Payment Reminder"
            ReminderType.BILL -> "Bill Payment Reminder"
            ReminderType.INSURANCE -> "Insurance Payment Reminder"
            ReminderType.RENT -> "Rent Payment Reminder"
            ReminderType.SUBSCRIPTION -> "Subscription Reminder"
            ReminderType.CUSTOM -> "Payment Reminder"
        }

        val formattedAmount = reminder.amount.format(currency)
        val formattedDueDate = DateTimeUtils.formatDate(reminder.dueDate)

        val dueText = when (offsetDays) {
            0 -> "is due today"
            1 -> "is due tomorrow"
            else -> "is due in $offsetDays days"
        }

        val content = "${reminder.title} of $formattedAmount $dueText.\nDue date: $formattedDueDate"

        // 1. Open Leaf PendingIntent
        val openIntent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            putExtra(NotificationHelper.EXTRA_START_ROUTE, NotificationHelper.ROUTE_PLANNING)
        }
        val openPendingIntent = PendingIntent.getActivity(
            context,
            (reminder.id * 10).toInt(),
            openIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        // 2. Mark Paid Action PendingIntent
        val markPaidIntent = Intent(context, ReminderReceiver::class.java).apply {
            action = NotificationHelper.ACTION_REMINDER_MARK_PAID
            putExtra(NotificationHelper.EXTRA_REMINDER_ID, reminder.id)
        }
        val markPaidPendingIntent = PendingIntent.getBroadcast(
            context,
            (reminder.id * 10 + 1).toInt(),
            markPaidIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        // 3. Snooze Action PendingIntent (snoozes for 24 hours)
        val snoozeIntent = Intent(context, ReminderReceiver::class.java).apply {
            action = NotificationHelper.ACTION_REMINDER_SNOOZE
            putExtra(NotificationHelper.EXTRA_REMINDER_ID, reminder.id)
        }
        val snoozePendingIntent = PendingIntent.getBroadcast(
            context,
            (reminder.id * 10 + 2).toInt(),
            snoozeIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val notificationId = NotificationHelper.NOTIFICATION_ID_REMINDER_BASE + (reminder.id % 1000).toInt()

        val notification = NotificationCompat.Builder(context, NotificationHelper.CHANNEL_PAYMENT_REMINDERS)
            .setSmallIcon(R.drawable.ic_stat_leaf)
            .setContentTitle(title)
            .setContentText("${reminder.title} of $formattedAmount $dueText.")
            .setStyle(NotificationCompat.BigTextStyle().bigText(content))
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setContentIntent(openPendingIntent)
            .setAutoCancel(true)
            .addAction(
                R.drawable.ic_stat_leaf,
                "Mark Paid",
                markPaidPendingIntent
            )
            .addAction(
                R.drawable.ic_stat_leaf,
                "Snooze",
                snoozePendingIntent
            )
            .build()

        try {
            NotificationManagerCompat.from(context).notify(notificationId, notification)
        } catch (_: SecurityException) {
            // Handled safely without crashing
        }
    }
}
