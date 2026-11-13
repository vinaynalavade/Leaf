import Foundation

public final class CancelRecurringTransactionUseCase: Sendable {
    private let recurringRepository: RecurringRepositoryProtocol
    private let notificationService: NotificationService

    public init(
        recurringRepository: RecurringRepositoryProtocol,
        notificationService: NotificationService = .shared
    ) {
        self.recurringRepository = recurringRepository
        self.notificationService = notificationService
    }

    public func execute(id: Int64) async throws {
        try await recurringRepository.setRecurringTransactionStatus(id: id, status: .cancelled)
        let occIds = try await recurringRepository.getOccurrenceIds(forRecurringId: id)
        for occId in occIds {
            notificationService.cancelBillReminder(occurrenceId: occId)
        }
    }
}
