import Foundation

/// UseCase atomically reversing a previously executed internal transfer between ledgers.
/// Creates a linked reverse transfer, restoring both ledger balances to their original amounts
/// while maintaining overall net balance strictly unchanged.
public final class ReverseTransferUseCase: Sendable {

    private let repository: TransactionRepositoryProtocol

    public init(repository: TransactionRepositoryProtocol) {
        self.repository = repository
    }

    public func execute(transactionId: Int64) async throws -> (outflowId: Int64, inflowId: Int64) {
        try await repository.reverseTransfer(transactionId: transactionId)
    }
}
