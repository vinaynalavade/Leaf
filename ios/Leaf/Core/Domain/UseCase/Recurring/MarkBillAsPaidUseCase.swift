import Foundation

public final class MarkBillAsPaidUseCase: Sendable {
    private let recurringRepository: RecurringRepositoryProtocol
    private let notificationService: NotificationService

    public init(
        recurringRepository: RecurringRepositoryProtocol,
        notificationService: NotificationService = .shared
    ) {
        self.recurringRepository = recurringRepository
        self.notificationService = notificationService
    }

    @discardableResult
    public func execute(
        occurrenceId: Int64,
        paymentMethod: PaymentMethod = .cash,
        paidAt: Int64 = Int64(Date().timeIntervalSince1970 * 1000)
    ) async throws -> Int64 {
        let txId = try await recurringRepository.markOccurrenceAsPaid(
            occurrenceId: occurrenceId,
            paymentMethod: paymentMethod,
            paidAt: paidAt
        )

        // Cancel notification for this bill occurrence
        notificationService.cancelBillReminder(occurrenceId: occurrenceId)

        return txId
    }
}

