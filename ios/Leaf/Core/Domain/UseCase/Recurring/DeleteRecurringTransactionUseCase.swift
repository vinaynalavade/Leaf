import Foundation

public final class DeleteRecurringTransactionUseCase: Sendable {
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
        let occIds = (try? await recurringRepository.getOccurrenceIds(forRecurringId: id)) ?? []
        try await recurringRepository.deleteRecurringTransaction(id: id)
        for occId in occIds {
            notificationService.cancelBillReminder(occurrenceId: occId)
        }
    }
}
