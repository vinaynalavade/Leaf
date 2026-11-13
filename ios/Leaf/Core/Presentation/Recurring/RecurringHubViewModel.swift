import Foundation
import SwiftUI
import UserNotifications

public enum RecurringHubSection: String, CaseIterable, Identifiable, Sendable {
    case upcomingBills = "Bills & Reminders"
    case allSchedules = "Schedules"
    case subscriptions = "Subscriptions"

    public var id: String { rawValue }
}

public enum BillsFilter: String, CaseIterable, Identifiable, Sendable {
    case all = "All"
    case overdue = "Overdue"
    case dueToday = "Due Today"
    case upcoming = "Upcoming"
    case paid = "Paid"

    public var id: String { rawValue }
}

@Observable
public final class RecurringHubViewModel {

    private let getRecurringTransactionsUseCase: GetRecurringTransactionsUseCase
    private let getUpcomingBillsUseCase: GetUpcomingBillsUseCase
    private let getSubscriptionSummaryUseCase: GetSubscriptionSummaryUseCase
    private let markBillAsPaidUseCase: MarkBillAsPaidUseCase
    private let skipBillOccurrenceUseCase: SkipBillOccurrenceUseCase
    private let snoozeBillReminderUseCase: SnoozeBillReminderUseCase
    private let pauseRecurringTransactionUseCase: PauseRecurringTransactionUseCase
    private let resumeRecurringTransactionUseCase: ResumeRecurringTransactionUseCase
    private let deleteRecurringTransactionUseCase: DeleteRecurringTransactionUseCase
    private let generateDueOccurrencesUseCase: GenerateDueOccurrencesUseCase

    public var selectedSection: RecurringHubSection = .upcomingBills
    public var billsFilter: BillsFilter = .all

    public var upcomingBillsSummary: UpcomingBillsSummary = .zero
    public var allSchedules: [RecurringTransaction] = []
    public var subscriptionSummary: SubscriptionSummary = .zero
    public var isLoading: Bool = false
    public var isCreateSheetPresented: Bool = false
    public var notificationStatus: UNAuthorizationStatus = .notDetermined

    public init(
        getRecurringTransactionsUseCase: GetRecurringTransactionsUseCase,
        getUpcomingBillsUseCase: GetUpcomingBillsUseCase,
        getSubscriptionSummaryUseCase: GetSubscriptionSummaryUseCase,
        markBillAsPaidUseCase: MarkBillAsPaidUseCase,
        skipBillOccurrenceUseCase: SkipBillOccurrenceUseCase,
        snoozeBillReminderUseCase: SnoozeBillReminderUseCase,
        pauseRecurringTransactionUseCase: PauseRecurringTransactionUseCase,
        resumeRecurringTransactionUseCase: ResumeRecurringTransactionUseCase,
        deleteRecurringTransactionUseCase: DeleteRecurringTransactionUseCase,
        generateDueOccurrencesUseCase: GenerateDueOccurrencesUseCase
    ) {
        self.getRecurringTransactionsUseCase = getRecurringTransactionsUseCase
        self.getUpcomingBillsUseCase = getUpcomingBillsUseCase
        self.getSubscriptionSummaryUseCase = getSubscriptionSummaryUseCase
        self.markBillAsPaidUseCase = markBillAsPaidUseCase
        self.skipBillOccurrenceUseCase = skipBillOccurrenceUseCase
        self.snoozeBillReminderUseCase = snoozeBillReminderUseCase
        self.pauseRecurringTransactionUseCase = pauseRecurringTransactionUseCase
        self.resumeRecurringTransactionUseCase = resumeRecurringTransactionUseCase
        self.deleteRecurringTransactionUseCase = deleteRecurringTransactionUseCase
        self.generateDueOccurrencesUseCase = generateDueOccurrencesUseCase
    }

    public var filteredBills: [RecurringTransactionOccurrence] {
        let bills = upcomingBillsSummary.bills
        switch billsFilter {
        case .all:
            return bills
        case .overdue:
            return bills.filter { $0.status == .overdue }
        case .dueToday:
            return bills.filter { $0.status == .due }
        case .upcoming:
            return bills.filter { $0.status == .upcoming }
        case .paid:
            return bills.filter { $0.status == .paid }
        }
    }

    public func loadData() async {
        isLoading = true
        defer { isLoading = false }

        // Run occurrence generation first so any due occurrences are fresh
        try? await generateDueOccurrencesUseCase.execute()
        notificationStatus = await NotificationService.shared.checkAuthorizationStatus()

        async let billsTask = getUpcomingBillsUseCase.execute()
        async let schedulesTask = getRecurringTransactionsUseCase.execute()
        async let subsTask = getSubscriptionSummaryUseCase.execute()

        do {
            let (bills, schedules, subs) = try await (billsTask, schedulesTask, subsTask)
            self.upcomingBillsSummary = bills
            self.allSchedules = schedules
            self.subscriptionSummary = subs
        } catch {
            // Keep existing state on error
        }
    }

    public func markAsPaid(occurrenceId: Int64) async {
        do {
            try await markBillAsPaidUseCase.execute(occurrenceId: occurrenceId)
            await loadData()
        } catch {}
    }

    public func skipOccurrence(occurrenceId: Int64) async {
        do {
            try await skipBillOccurrenceUseCase.execute(occurrenceId: occurrenceId)
            await loadData()
        } catch {}
    }

    public func snoozeOccurrence(occurrenceId: Int64, days: Int) async {
        do {
            try await snoozeBillReminderUseCase.execute(occurrenceId: occurrenceId, snoozeDays: days)
            await loadData()
        } catch {}
    }

    public func togglePause(schedule: RecurringTransaction) async {
        do {
            if schedule.status == .active {
                try await pauseRecurringTransactionUseCase.execute(id: schedule.id)
            } else {
                try await resumeRecurringTransactionUseCase.execute(id: schedule.id)
            }
            await loadData()
        } catch {}
    }

    public func deleteSchedule(id: Int64) async {
        do {
            try await deleteRecurringTransactionUseCase.execute(id: id)
            await loadData()
        } catch {}
    }

    public func requestNotificationPermission() async {
        let granted = await NotificationService.shared.requestAuthorization()
        notificationStatus = await NotificationService.shared.checkAuthorizationStatus()
        if granted {
            try? await generateDueOccurrencesUseCase.execute()
        }
    }
}

