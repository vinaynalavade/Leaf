import Foundation

/// UseCase removing a budget definition while preserving all underlying transaction history.
public final class DeleteBudgetUseCase: Sendable {

    private let budgetRepository: BudgetRepositoryProtocol

    public init(budgetRepository: BudgetRepositoryProtocol) {
        self.budgetRepository = budgetRepository
    }

    public func execute(id: Int64) async throws {
        try await budgetRepository.deleteBudget(id: id)
    }
}

