import Foundation

public final class DeleteTransactionUseCase: Sendable {

    private let repository: TransactionRepositoryProtocol

    public init(repository: TransactionRepositoryProtocol) {
        self.repository = repository
    }

    public func execute(id: Int64) async throws {
        try await repository.deleteTransaction(id: id)
    }
}

