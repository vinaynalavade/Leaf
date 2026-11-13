import Foundation
import UserNotifications

/// Local notification manager for bill payment alerts and scheduled recurring obligations.
/// Adheres strictly to iOS local notification limits (capping at 60 pending requests)
/// and handles authorization states gracefully.
public final class NotificationService: Sendable {

    public static let shared = NotificationService()

    public init() {}

    /// Requests notification permissions with alert, sound, and badge options.
    @discardableResult
    public func requestAuthorization() async -> Bool {
        do {
            let center = UNUserNotificationCenter.current()
            return try await center.requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            return false
        }
    }

    /// Checks the current notification authorization status.
    public func checkAuthorizationStatus() async -> UNAuthorizationStatus {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        return settings.authorizationStatus
    }

    /// Schedules a local notification for an upcoming bill occurrence.
    public func scheduleBillReminder(
        occurrenceId: Int64,
        title: String,
        amountFormatted: String,
        dueDate: Date,
        reminderDaysBefore: Int = 1
    ) async {
        let status = await checkAuthorizationStatus()
        guard status == .authorized || status == .provisional else { return }

        let center = UNUserNotificationCenter.current()
        let identifier = identifierForOccurrence(occurrenceId)

        // Remove any previous notification for this occurrence
        center.removePendingNotificationRequests(withIdentifiers: [identifier, "bill_reminder_\(occurrenceId)"])

        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone.current

        // Calculate reminder trigger date
        guard let reminderDate = cal.date(byAdding: .day, value: -reminderDaysBefore, to: dueDate) else {
            return
        }

        // Target 9:00 AM on the reminder day
        var fireComponents = cal.dateComponents([.year, .month, .day], from: reminderDate)
        fireComponents.hour = 9
        fireComponents.minute = 0
        fireComponents.second = 0

        guard let fireDate = cal.date(from: fireComponents) else { return }

        // If 9 AM on reminder day is already past, but due date is today or future, schedule soon
        let now = Date()
        let finalTriggerDate: Date
        if fireDate > now {
            finalTriggerDate = fireDate
        } else if cal.isDateInToday(dueDate) && dueDate > now {
            // Due later today
            finalTriggerDate = now.addingTimeInterval(60) // 1 minute from now
        } else {
            // Already overdue or past trigger window
            return
        }

        let triggerComponents = cal.dateComponents([.year, .month, .day, .hour, .minute], from: finalTriggerDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerComponents, repeats: false)

        let content = UNMutableNotificationContent()
        content.title = "Upcoming Bill: \(title)"
        if reminderDaysBefore == 0 {
            content.body = "\(amountFormatted) is due today. Tap to view details or record payment."
        } else if reminderDaysBefore == 1 {
            content.body = "\(amountFormatted) is due tomorrow. Tap to review your payment."
        } else {
            content.body = "\(amountFormatted) is due in \(reminderDaysBefore) days."
        }
        content.sound = .default
        content.userInfo = ["occurrenceId": occurrenceId]

        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        try? await center.add(request)
    }

    /// Cancels scheduled reminder for an occurrence (e.g. after payment or skip).
    public func cancelBillReminder(occurrenceId: Int64) {
        let center = UNUserNotificationCenter.current()
        let ids = [identifierForOccurrence(occurrenceId), "bill_reminder_\(occurrenceId)"]
        center.removePendingNotificationRequests(withIdentifiers: ids)
        center.removeDeliveredNotifications(withIdentifiers: ids)
    }

    public static let dailyExpenseReminderId = "leaf_daily_expense_reminder"

    /// Schedules a recurring daily reminder encouraging the user to log expenses.
    public func scheduleDailyExpenseReminder(hour: Int, minute: Int) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [Self.dailyExpenseReminderId])

        let content = UNMutableNotificationContent()
        content.title = "Review Today's Expenses"
        content.body = "Take a moment to record your spending and stay on track with your Leaf budget."
        content.sound = .default

        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: Self.dailyExpenseReminderId, content: content, trigger: trigger)
        Task {
            _ = await requestAuthorization()
            try? await center.add(request)
        }
    }

    /// Cancels active daily expense reminder.
    public func cancelDailyExpenseReminder() {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [Self.dailyExpenseReminderId])
        center.removeDeliveredNotifications(withIdentifiers: [Self.dailyExpenseReminderId])
    }

    /// Reconciles and synchronizes pending notifications for upcoming bills.
    /// Prioritizes the nearest 60 reminders to strictly respect the iOS 64-notification limit.
    public func reconcilePendingNotifications(
        occurrences: [RecurringTransactionOccurrence],
        currency: Currency
    ) async {
        let status = await checkAuthorizationStatus()
        guard status == .authorized || status == .provisional else { return }

        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone.current
        let now = Date()

        // 1. Gather all candidate unsettled reminders
        struct CandidateReminder {
            let occurrence: RecurringTransactionOccurrence
            let fireDate: Date
            let daysBefore: Int
        }

        var candidates: [CandidateReminder] = []

        for occ in occurrences where occ.status.isUnsettled {
            let dueDate = Date(timeIntervalSince1970: Double(occ.dueDate) / 1000.0)
            let daysBefore = occ.recurringTransaction?.reminderDaysBefore ?? 1

            guard let reminderDate = cal.date(byAdding: .day, value: -daysBefore, to: dueDate) else {
                continue
            }

            var fireComponents = cal.dateComponents([.year, .month, .day], from: reminderDate)
            fireComponents.hour = 9
            fireComponents.minute = 0
            fireComponents.second = 0

            guard let baseFireDate = cal.date(from: fireComponents) else { continue }

            let triggerDate: Date
            if baseFireDate > now {
                triggerDate = baseFireDate
            } else if (cal.isDateInToday(dueDate) || dueDate > now) {
                triggerDate = now.addingTimeInterval(300) // Within 5 minutes
            } else {
                continue
            }

            candidates.append(CandidateReminder(occurrence: occ, fireDate: triggerDate, daysBefore: daysBefore))
        }

        // 2. Sort nearest first and take at most 60
        candidates.sort { $0.fireDate < $1.fireDate }
        let topCandidates = candidates.prefix(60)

        // 3. Reschedule active requests
        for item in topCandidates {
            let occ = item.occurrence
            let dueDate = Date(timeIntervalSince1970: Double(occ.dueDate) / 1000.0)
            await scheduleBillReminder(
                occurrenceId: occ.id,
                title: occ.title,
                amountFormatted: occ.amount.formatted(currency: currency),
                dueDate: dueDate,
                reminderDaysBefore: item.daysBefore
            )
        }
    }

    private func identifierForOccurrence(_ occurrenceId: Int64) -> String {
        "leaf_bill_\(occurrenceId)"
    }
}
