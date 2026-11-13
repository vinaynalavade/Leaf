import Foundation

public final class GetRecurringTransactionsUseCase: Sendable {
    private let recurringRepository: RecurringRepositoryProtocol

    public init(recurringRepository: RecurringRepositoryProtocol) {
        self.recurringRepository = recurringRepository
    }

    public func execute() async throws -> [RecurringTransaction] {
        try await recurringRepository.getAllRecurringTransactions()
    }

    public func getById(id: Int64) async throws -> RecurringTransaction? {
        try await recurringRepository.getRecurringTransaction(id: id)
    }
}

