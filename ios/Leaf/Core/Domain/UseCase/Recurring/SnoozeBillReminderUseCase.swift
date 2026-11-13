import Foundation

public final class SnoozeBillReminderUseCase: Sendable {
    private let recurringRepository: RecurringRepositoryProtocol
    private let notificationService: NotificationService

    public init(
        recurringRepository: RecurringRepositoryProtocol,
        notificationService: NotificationService = .shared
    ) {
        self.recurringRepository = recurringRepository
        self.notificationService = notificationService
    }

    public func execute(occurrenceId: Int64, snoozeDays: Int) async throws {
        let cal = Calendar.current
        guard let snoozeDate = cal.date(byAdding: .day, value: snoozeDays, to: Date()) else { return }
        let snoozeEpoch = Int64(snoozeDate.timeIntervalSince1970 * 1000)

        try await recurringRepository.snoozeOccurrence(occurrenceId: occurrenceId, untilEpoch: snoozeEpoch)

        // Reschedule notification for snooze date
        if let occ = try await recurringRepository.getOccurrence(id: occurrenceId) {
            await notificationService.scheduleBillReminder(
                occurrenceId: occurrenceId,
                title: occ.title,
                amountFormatted: occ.amount.formatted(),
                dueDate: snoozeDate,
                reminderDaysBefore: 0
            )
        }
    }
}

