import Foundation

/// UseCase responsible for deleting a split expense and its associated participants.
public final class DeleteSplitExpenseUseCase: Sendable {

    private let splitRepository: SplitRepositoryProtocol

    public init(splitRepository: SplitRepositoryProtocol) {
        self.splitRepository = splitRepository
    }

    public func execute(id: Int64) async throws {
        try await splitRepository.deleteSplitExpense(id: id)
    }
}

