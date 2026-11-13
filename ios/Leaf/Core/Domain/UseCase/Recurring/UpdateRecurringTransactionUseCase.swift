import Foundation

/// Defines whether schedule edits apply to future occurrences only, or include the immediate pending due occurrence.
public enum RecurringScheduleEditScope: String, CaseIterable, Identifiable, Sendable {
    case futureOnly = "FUTURE_ONLY"
    case thisAndFuture = "THIS_AND_FUTURE"

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .futureOnly:
            return "Future Occurrences Only"
        case .thisAndFuture:
            return "This & Future Occurrences"
        }
    }

    public var description: String {
        switch self {
        case .futureOnly:
            return "Leaves current pending due payment unchanged. Future occurrences will use the new schedule."
        case .thisAndFuture:
            return "Updates current pending occurrence and future occurrences. Historical paid records remain preserved."
        }
    }
}

public final class UpdateRecurringTransactionUseCase: Sendable {
    private let recurringRepository: RecurringRepositoryProtocol
    private let notificationService: NotificationService

    public init(
        recurringRepository: RecurringRepositoryProtocol,
        notificationService: NotificationService = .shared
    ) {
        self.recurringRepository = recurringRepository
        self.notificationService = notificationService
    }

    public func execute(
        _ schedule: RecurringTransaction,
        editScope: RecurringScheduleEditScope = .futureOnly
    ) async throws {
        // 1. Update parent schedule record
        try await recurringRepository.updateRecurringTransaction(schedule)

        // 2. Reconcile future unpaid occurrences
        let removedIds = try await recurringRepository.reconcileFutureOccurrences(
            forRecurringId: schedule.id,
            updateUpcomingDueOccurrence: editScope == .thisAndFuture,
            newSchedule: schedule
        )

        // 3. Cancel notifications for any removed occurrences
        for occId in removedIds {
            notificationService.cancelBillReminder(occurrenceId: occId)
        }
    }
}
