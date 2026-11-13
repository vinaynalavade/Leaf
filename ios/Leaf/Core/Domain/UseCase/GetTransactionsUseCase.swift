import Foundation

public final class GetTransactionsUseCase: Sendable {

    private let repository: TransactionRepositoryProtocol

    public init(repository: TransactionRepositoryProtocol) {
        self.repository = repository
    }

    public func execute(
        type: TransactionType? = nil,
        categoryId: Int64? = nil,
        startEpoch: Int64? = nil,
        endEpoch: Int64? = nil,
        excludeInternalTransfers: Bool = false
    ) async throws -> [Transaction] {
        let all: [Transaction]
        if let start = startEpoch, let end = endEpoch {
            all = try await repository.getTransactionsBetween(startEpoch: start, endEpoch: end)
        } else {
            all = try await repository.getAllTransactions()
        }

        return all.filter { tx in
            if excludeInternalTransfers && tx.isInternalTransfer { return false }
            if let type = type, tx.type != type { return false }
            if let catId = categoryId, tx.categoryId != catId { return false }
            return true
        }
    }

    /// Fetches the top recent transactions, ordered chronologically descending.
    public func getRecent(limit: Int = 5) async throws -> [Transaction] {
        let all = try await repository.getAllTransactions()
        return Array(all.prefix(limit))
    }
}
