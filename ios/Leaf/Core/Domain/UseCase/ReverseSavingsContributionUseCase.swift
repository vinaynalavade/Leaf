import Foundation

/// UseCase reversing or correcting an individual savings goal contribution, removing any linked checking transaction.
public final class ReverseSavingsContributionUseCase: Sendable {

    private let savingsGoalRepository: SavingsGoalRepositoryProtocol

    public init(savingsGoalRepository: SavingsGoalRepositoryProtocol) {
        self.savingsGoalRepository = savingsGoalRepository
    }

    public func execute(contributionId: Int64) async throws {
        try await savingsGoalRepository.deleteContribution(id: contributionId)
    }
}

