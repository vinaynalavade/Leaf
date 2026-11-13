import Foundation

/// UseCase deleting a savings goal and its associated contribution records.
public final class DeleteSavingsGoalUseCase: Sendable {

    private let savingsGoalRepository: SavingsGoalRepositoryProtocol

    public init(savingsGoalRepository: SavingsGoalRepositoryProtocol) {
        self.savingsGoalRepository = savingsGoalRepository
    }

    public func execute(id: Int64) async throws {
        try await savingsGoalRepository.deleteGoal(id: id)
    }
}

