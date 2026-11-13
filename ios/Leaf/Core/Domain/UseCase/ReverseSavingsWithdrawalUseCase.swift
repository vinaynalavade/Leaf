import Foundation

/// UseCase reversing or correcting an individual savings goal withdrawal,
/// cleanly removing any linked checking account inflow transaction.
public final class ReverseSavingsWithdrawalUseCase: Sendable {

    private let savingsGoalRepository: SavingsGoalRepositoryProtocol

    public init(savingsGoalRepository: SavingsGoalRepositoryProtocol) {
        self.savingsGoalRepository = savingsGoalRepository
    }

    public func execute(withdrawalId: Int64) async throws {
        try await savingsGoalRepository.deleteContribution(id: withdrawalId)
    }
}

