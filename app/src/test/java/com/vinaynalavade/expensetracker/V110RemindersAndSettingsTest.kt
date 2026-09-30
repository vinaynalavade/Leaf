package com.vinaynalavade.expensetracker

import com.vinaynalavade.expensetracker.core.constants.AppConstants
import com.vinaynalavade.expensetracker.core.model.Amount
import com.vinaynalavade.expensetracker.data.local.entity.ReminderEntity
import com.vinaynalavade.expensetracker.domain.model.Reminder
import com.vinaynalavade.expensetracker.domain.model.ReminderRecurrence
import com.vinaynalavade.expensetracker.domain.model.ReminderType
import com.vinaynalavade.expensetracker.domain.model.UpcomingPaymentItem
import com.vinaynalavade.expensetracker.domain.model.UserPreferences
import com.vinaynalavade.expensetracker.presentation.navigation.Screen
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertTrue
import org.junit.Test
import java.time.LocalDate
import java.time.ZoneId

/**
 * Release contract and unit test suite for Leaf v1.1.0 — Reminders, Payment Planning & Settings UX 2.0.
 */
class V110RemindersAndSettingsTest {

    private val zoneId = ZoneId.systemDefault()

    // ==========================================
    // 1. VERSION CONTRACT
    // ==========================================
    @Test
    fun testVersionContract() {
        assertEquals("1.1.0", AppConstants.APP_VERSION)
        assertEquals("reminders", Screen.Reminders.route)
    }

    // ==========================================
    // 2. RECURRENCE CALCULATIONS & MONTH-END PINNING
    // ==========================================
    @Test
    fun testOneTimeRecurrenceDoesNotAdvance() {
        val dueDateMillis = LocalDate.of(2026, 10, 15).atStartOfDay(zoneId).toInstant().toEpochMilli()
        val reminder = Reminder(
            id = 1L,
            title = "Car Insurance",
            amount = Amount.fromSubunits(1500000L),
            type = ReminderType.INSURANCE,
            dueDate = dueDateMillis,
            recurrence = ReminderRecurrence.ONE_TIME,
            configuredDayOfMonth = 15
        )
        val next = reminder.calculateNextDueDate(zoneId = zoneId)
        assertEquals(dueDateMillis, next)
    }

    @Test
    fun testDailyRecurrenceAdvancesByOneDay() {
        val sep30 = LocalDate.of(2026, 9, 30).atStartOfDay(zoneId).toInstant().toEpochMilli()
        val oct1 = LocalDate.of(2026, 10, 1).atStartOfDay(zoneId).toInstant().toEpochMilli()

        val reminder = Reminder(
            id = 2L,
            title = "Daily Milk",
            amount = Amount.fromSubunits(6000L),
            type = ReminderType.BILL,
            dueDate = sep30,
            recurrence = ReminderRecurrence.DAILY
        )
        val next = reminder.calculateNextDueDate(zoneId = zoneId)
        assertEquals(oct1, next)
    }

    @Test
    fun testWeeklyRecurrenceAdvancesBySevenDays() {
        val oct1 = LocalDate.of(2026, 10, 1).atStartOfDay(zoneId).toInstant().toEpochMilli()
        val oct8 = LocalDate.of(2026, 10, 8).atStartOfDay(zoneId).toInstant().toEpochMilli()

        val reminder = Reminder(
            id = 3L,
            title = "Weekly Grocery",
            amount = Amount.fromSubunits(200000L),
            type = ReminderType.BILL,
            dueDate = oct1,
            recurrence = ReminderRecurrence.WEEKLY
        )
        val next = reminder.calculateNextDueDate(zoneId = zoneId)
        assertEquals(oct8, next)
    }

    @Test
    fun testMonthlyRecurrenceStandard() {
        val sep25 = LocalDate.of(2026, 9, 25).atStartOfDay(zoneId).toInstant().toEpochMilli()
        val oct25 = LocalDate.of(2026, 10, 25).atStartOfDay(zoneId).toInstant().toEpochMilli()

        val reminder = Reminder(
            id = 4L,
            title = "Personal Loan EMI",
            amount = Amount.fromSubunits(850000L),
            type = ReminderType.LOAN_EMI,
            dueDate = sep25,
            recurrence = ReminderRecurrence.MONTHLY,
            configuredDayOfMonth = 25
        )
        val next = reminder.calculateNextDueDate(zoneId = zoneId)
        assertEquals(oct25, next)
    }

    @Test
    fun testMonthlyRecurrenceMonthEndPinning31st() {
        val jan31 = LocalDate.of(2026, 1, 31).atStartOfDay(zoneId).toInstant().toEpochMilli()
        val feb28 = LocalDate.of(2026, 2, 28).atStartOfDay(zoneId).toInstant().toEpochMilli()
        val mar31 = LocalDate.of(2026, 3, 31).atStartOfDay(zoneId).toInstant().toEpochMilli()
        val apr30 = LocalDate.of(2026, 4, 30).atStartOfDay(zoneId).toInstant().toEpochMilli()
        val may31 = LocalDate.of(2026, 5, 31).atStartOfDay(zoneId).toInstant().toEpochMilli()

        val janReminder = Reminder(
            id = 5L,
            title = "Subscription 31st",
            amount = Amount.fromSubunits(49900L),
            type = ReminderType.SUBSCRIPTION,
            dueDate = jan31,
            recurrence = ReminderRecurrence.MONTHLY,
            configuredDayOfMonth = 31
        )

        // Jan 31 -> Feb 28 (2026 non-leap year has 28 days)
        val febDueDate = janReminder.calculateNextDueDate(zoneId = zoneId)
        assertEquals(feb28, febDueDate)

        // Continuing from Feb 28 with configuredDayOfMonth = 31 -> March 31!
        val febReminder = janReminder.copy(dueDate = febDueDate)
        val marDueDate = febReminder.calculateNextDueDate(zoneId = zoneId)
        assertEquals(mar31, marDueDate)

        // March 31 -> April 30 (April has 30 days)
        val marReminder = febReminder.copy(dueDate = marDueDate)
        val aprDueDate = marReminder.calculateNextDueDate(zoneId = zoneId)
        assertEquals(apr30, aprDueDate)

        // April 30 -> May 31 (pins back to 31st)
        val aprReminder = marReminder.copy(dueDate = aprDueDate)
        val mayDueDate = aprReminder.calculateNextDueDate(zoneId = zoneId)
        assertEquals(may31, mayDueDate)
    }

    @Test
    fun testMonthlyRecurrenceLeapYearFeb29() {
        // 2028 is a leap year
        val jan31Leap = LocalDate.of(2028, 1, 31).atStartOfDay(zoneId).toInstant().toEpochMilli()
        val feb29Leap = LocalDate.of(2028, 2, 29).atStartOfDay(zoneId).toInstant().toEpochMilli()

        val reminder = Reminder(
            id = 6L,
            title = "EMI 31st Leap",
            amount = Amount.fromSubunits(1000000L),
            type = ReminderType.LOAN_EMI,
            dueDate = jan31Leap,
            recurrence = ReminderRecurrence.MONTHLY,
            configuredDayOfMonth = 31
        )
        val febLeapDueDate = reminder.calculateNextDueDate(zoneId = zoneId)
        assertEquals(feb29Leap, febLeapDueDate)
    }

    @Test
    fun testMonthlyRecurrenceDay30InFebruary() {
        val jan30 = LocalDate.of(2026, 1, 30).atStartOfDay(zoneId).toInstant().toEpochMilli()
        val feb28 = LocalDate.of(2026, 2, 28).atStartOfDay(zoneId).toInstant().toEpochMilli()
        val mar30 = LocalDate.of(2026, 3, 30).atStartOfDay(zoneId).toInstant().toEpochMilli()

        val reminder = Reminder(
            id = 7L,
            title = "Rent 30th",
            amount = Amount.fromSubunits(2500000L),
            type = ReminderType.RENT,
            dueDate = jan30,
            recurrence = ReminderRecurrence.MONTHLY,
            configuredDayOfMonth = 30
        )
        val febDueDate = reminder.calculateNextDueDate(zoneId = zoneId)
        assertEquals(feb28, febDueDate)

        // From Feb 28, configuredDayOfMonth = 30 returns March 30
        val febReminder = reminder.copy(dueDate = febDueDate)
        val marDueDate = febReminder.calculateNextDueDate(zoneId = zoneId)
        assertEquals(mar30, marDueDate)
    }

    @Test
    fun testYearlyRecurrence() {
        val nov20_2026 = LocalDate.of(2026, 11, 20).atStartOfDay(zoneId).toInstant().toEpochMilli()
        val nov20_2027 = LocalDate.of(2027, 11, 20).atStartOfDay(zoneId).toInstant().toEpochMilli()

        val yearly = Reminder(
            id = 8L,
            title = "Life Insurance",
            amount = Amount.fromSubunits(4500000L),
            type = ReminderType.INSURANCE,
            dueDate = nov20_2026,
            recurrence = ReminderRecurrence.YEARLY,
            configuredDayOfMonth = 20
        )
        val next = yearly.calculateNextDueDate(zoneId = zoneId)
        assertEquals(nov20_2027, next)
    }

    // ==========================================
    // 3. MULTIPLE OFFSETS & PARSING
    // ==========================================
    @Test
    fun testGetAllOffsetsSingleOffset() {
        val dueDate = LocalDate.of(2026, 10, 5).atStartOfDay(zoneId).toInstant().toEpochMilli()
        val reminder = Reminder(
            id = 9L,
            title = "Card Bill",
            amount = Amount.fromSubunits(500000L),
            type = ReminderType.CREDIT_CARD,
            dueDate = dueDate,
            reminderOffsetDays = 1,
            additionalOffsets = null
        )
        val offsets = reminder.getAllOffsets()
        assertEquals(listOf(1), offsets)
    }

    @Test
    fun testGetAllOffsetsMultipleSorted() {
        val dueDate = LocalDate.of(2026, 10, 25).atStartOfDay(zoneId).toInstant().toEpochMilli()
        val reminder = Reminder(
            id = 10L,
            title = "Loan EMI",
            amount = Amount.fromSubunits(850000L),
            type = ReminderType.LOAN_EMI,
            dueDate = dueDate,
            reminderOffsetDays = 1,
            additionalOffsets = "7, 0, 3"
        )
        val offsets = reminder.getAllOffsets()
        assertEquals(listOf(0, 1, 3, 7), offsets)
    }

    @Test
    fun testGetAllOffsetsDeduplication() {
        val dueDate = LocalDate.of(2026, 10, 10).atStartOfDay(zoneId).toInstant().toEpochMilli()
        val reminder = Reminder(
            id = 11L,
            title = "Deduplication Test",
            amount = Amount.fromSubunits(10000L),
            type = ReminderType.CUSTOM,
            dueDate = dueDate,
            reminderOffsetDays = 2,
            additionalOffsets = "2, 5, 2, invalid"
        )
        val offsets = reminder.getAllOffsets()
        assertEquals(listOf(2, 5), offsets)
    }

    // ==========================================
    // 4. ENTITY & DOMAIN MAPPING
    // ==========================================
    @Test
    fun testEntityDomainBidirectionalMapping() {
        val dueEpoch = LocalDate.of(2026, 10, 10).atStartOfDay(zoneId).toInstant().toEpochMilli()
        val paidEpoch = LocalDate.of(2026, 9, 10).atStartOfDay(zoneId).toInstant().toEpochMilli()

        val original = Reminder(
            id = 42L,
            title = "Home Loan EMI",
            description = "HDFC Bank A/C",
            amount = Amount.fromSubunits(3250000L),
            type = ReminderType.LOAN_EMI,
            dueDate = dueEpoch,
            recurrence = ReminderRecurrence.MONTHLY,
            reminderOffsetDays = 3,
            additionalOffsets = "1, 7",
            notificationHour = 8,
            notificationMinute = 30,
            isEnabled = true,
            isPaid = false,
            configuredDayOfMonth = 10,
            lastPaidDate = paidEpoch,
            createdAt = 1000L,
            updatedAt = 2000L
        )

        val entity = ReminderEntity.fromDomainModel(original)
        assertEquals(42L, entity.id)
        assertEquals("Home Loan EMI", entity.title)
        assertEquals("HDFC Bank A/C", entity.description)
        assertEquals(3250000L, entity.amountSubunits)
        assertEquals("LOAN_EMI", entity.type)
        assertEquals(dueEpoch, entity.dueDate)
        assertEquals("MONTHLY", entity.recurrence)
        assertEquals(3, entity.reminderOffsetDays)
        assertEquals("1, 7", entity.additionalOffsets)
        assertEquals(8, entity.notificationHour)
        assertEquals(30, entity.notificationMinute)
        assertTrue(entity.isEnabled)
        assertFalse(entity.isPaid)
        assertEquals(10, entity.configuredDayOfMonth)
        assertEquals(paidEpoch, entity.lastPaidDate)

        val mappedBack = entity.toDomainModel()
        assertEquals(original, mappedBack)
    }

    // ==========================================
    // 5. UPCOMING PAYMENT ITEM MODEL
    // ==========================================
    @Test
    fun testUpcomingPaymentItemState() {
        val today = LocalDate.of(2026, 9, 30)

        // Due tomorrow
        val dueTomorrowDate = LocalDate.of(2026, 10, 1)
        val itemTomorrow = UpcomingPaymentItem(
            id = "reminder_1",
            sourceId = 1L,
            title = "Personal Loan",
            amount = Amount.fromSubunits(850000L),
            type = ReminderType.LOAN_EMI,
            dueDate = dueTomorrowDate,
            isRecurring = true,
            recurrenceLabel = "Monthly",
            isOverdue = false,
            isDueToday = false,
            daysRemaining = 1
        )
        assertEquals(1, itemTomorrow.daysRemaining)
        assertFalse(itemTomorrow.isOverdue)
        assertFalse(itemTomorrow.isDueToday)

        // Due today
        val itemToday = itemTomorrow.copy(
            dueDate = today,
            isDueToday = true,
            isOverdue = false,
            daysRemaining = 0
        )
        assertEquals(0, itemToday.daysRemaining)
        assertTrue(itemToday.isDueToday)
        assertFalse(itemToday.isOverdue)

        // Overdue by 3 days
        val itemOverdue = itemTomorrow.copy(
            dueDate = today.minusDays(3),
            isDueToday = false,
            isOverdue = true,
            daysRemaining = -3
        )
        assertEquals(-3, itemOverdue.daysRemaining)
        assertTrue(itemOverdue.isOverdue)
        assertFalse(itemOverdue.isDueToday)
    }

    // ==========================================
    // 6. USER PREFERENCES DEFAULTS
    // ==========================================
    @Test
    fun testUserPreferencesDefaults() {
        val prefs = UserPreferences()
        assertFalse(prefs.notificationsMasterEnabled)
        assertTrue(prefs.emiRemindersEnabled)
        assertTrue(prefs.billRemindersEnabled)
        assertTrue(prefs.creditCardRemindersEnabled)
        assertEquals(1, prefs.defaultReminderOffsetDays)
        assertEquals(9, prefs.defaultReminderHour)
        assertEquals(0, prefs.defaultReminderMinute)
    }
}
