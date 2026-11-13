import Foundation

/// UseCase reversing a previously settled recurring occurrence.
/// Atomically deletes the generated transaction from the transactions ledger,
/// clears the occurrence's paid timestamp and linked transaction pointer,
/// and re-resolves its payment status based on its scheduled date.
public final class ReversePaidOccurrenceUseCase: Sendable {
    private let recurringRepository: RecurringRepositoryProtocol

    public init(recurringRepository: RecurringRepositoryProtocol) {
        self.recurringRepository = recurringRepository
    }

    public func execute(occurrenceId: Int64) async throws {
        try await recurringRepository.reversePaidOccurrence(occurrenceId: occurrenceId)
    }
}

