package com.vinaynalavade.expensetracker.core.notification

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import com.vinaynalavade.expensetracker.core.receiver.ReminderReceiver
import com.vinaynalavade.expensetracker.domain.model.Reminder
import java.time.Instant
import java.time.ZoneId

interface ReminderScheduler {
    fun scheduleReminder(reminder: Reminder)
    fun cancelReminder(reminder: Reminder)
    fun rescheduleAll(reminders: List<Reminder>)
    fun snoozeReminder(reminderId: Long, snoozeDurationMillis: Long = 24 * 60 * 60 * 1000L) // Default 24 hours
}

class AlarmReminderScheduler(
    private val context: Context
) : ReminderScheduler {

    private val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as? AlarmManager

    override fun scheduleReminder(reminder: Reminder) {
        if (alarmManager == null || !reminder.isEnabled || reminder.isPaid) return

        val zoneId = ZoneId.systemDefault()
        val dueLocalDate = Instant.ofEpochMilli(reminder.dueDate).atZone(zoneId).toLocalDate()
        val now = System.currentTimeMillis()

        for (offset in reminder.getAllOffsets()) {
            val triggerDate = dueLocalDate.minusDays(offset.toLong())
            val triggerZonedDateTime = triggerDate.atTime(reminder.notificationHour, reminder.notificationMinute).atZone(zoneId)
            val triggerMillis = triggerZonedDateTime.toInstant().toEpochMilli()

            // Schedule only if trigger time is strictly in the future
            if (triggerMillis > now) {
                val intent = Intent(context, ReminderReceiver::class.java).apply {
                    action = NotificationHelper.ACTION_REMINDER_ALERT
                    putExtra(NotificationHelper.EXTRA_REMINDER_ID, reminder.id)
                    putExtra(NotificationHelper.EXTRA_REMINDER_OFFSET, offset)
                }

                val requestCode = generateRequestCode(reminder.id, offset)
                val pendingIntent = PendingIntent.getBroadcast(
                    context,
                    requestCode,
                    intent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )

                scheduleAlarmSafely(triggerMillis, pendingIntent)
            }
        }
    }

    override fun cancelReminder(reminder: Reminder) {
        if (alarmManager == null) return

        for (offset in reminder.getAllOffsets()) {
            val intent = Intent(context, ReminderReceiver::class.java).apply {
                action = NotificationHelper.ACTION_REMINDER_ALERT
            }
            val requestCode = generateRequestCode(reminder.id, offset)
            val pendingIntent = PendingIntent.getBroadcast(
                context,
                requestCode,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            alarmManager.cancel(pendingIntent)
        }
    }

    override fun rescheduleAll(reminders: List<Reminder>) {
        reminders.forEach { reminder ->
            if (reminder.isEnabled && !reminder.isPaid) {
                scheduleReminder(reminder)
            } else {
                cancelReminder(reminder)
            }
        }
    }

    override fun snoozeReminder(reminderId: Long, snoozeDurationMillis: Long) {
        if (alarmManager == null) return
        val triggerMillis = System.currentTimeMillis() + snoozeDurationMillis

        val intent = Intent(context, ReminderReceiver::class.java).apply {
            action = NotificationHelper.ACTION_REMINDER_ALERT
            putExtra(NotificationHelper.EXTRA_REMINDER_ID, reminderId)
            putExtra(NotificationHelper.EXTRA_REMINDER_OFFSET, 0)
        }

        val requestCode = generateRequestCode(reminderId, 999) // Special snooze slot
        val pendingIntent = PendingIntent.getBroadcast(
            context,
            requestCode,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        scheduleAlarmSafely(triggerMillis, pendingIntent)
    }

    private fun scheduleAlarmSafely(triggerMillis: Long, pendingIntent: PendingIntent) {
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                if (alarmManager?.canScheduleExactAlarms() == true) {
                    alarmManager.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, triggerMillis, pendingIntent)
                } else {
                    alarmManager?.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, triggerMillis, pendingIntent)
                }
            } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                alarmManager?.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, triggerMillis, pendingIntent)
            } else {
                alarmManager?.set(AlarmManager.RTC_WAKEUP, triggerMillis, pendingIntent)
            }
        } catch (_: SecurityException) {
            // Graceful fallback for devices restricting exact alarms
            try {
                alarmManager?.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, triggerMillis, pendingIntent)
            } catch (_: Exception) {
                // Safe failure
            }
        }
    }

    private fun generateRequestCode(reminderId: Long, offset: Int): Int {
        return ((reminderId % 10000) * 100 + (offset.coerceIn(0, 999))).toInt()
    }
}
