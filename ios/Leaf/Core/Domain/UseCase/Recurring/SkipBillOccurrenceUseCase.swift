import Foundation

public final class SkipBillOccurrenceUseCase: Sendable {
    private let recurringRepository: RecurringRepositoryProtocol
    private let notificationService: NotificationService

    public init(
        recurringRepository: RecurringRepositoryProtocol,
        notificationService: NotificationService = .shared
    ) {
        self.recurringRepository = recurringRepository
        self.notificationService = notificationService
    }

    public func execute(occurrenceId: Int64) async throws {
        try await recurringRepository.skipOccurrence(occurrenceId: occurrenceId)
        notificationService.cancelBillReminder(occurrenceId: occurrenceId)
    }
}

