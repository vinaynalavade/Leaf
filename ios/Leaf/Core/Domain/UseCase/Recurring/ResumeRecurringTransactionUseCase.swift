import Foundation

public final class ResumeRecurringTransactionUseCase: Sendable {
    private let recurringRepository: RecurringRepositoryProtocol

    public init(recurringRepository: RecurringRepositoryProtocol) {
        self.recurringRepository = recurringRepository
    }

    public func execute(id: Int64) async throws {
        try await recurringRepository.setRecurringTransactionStatus(id: id, status: .active)
    }
}

