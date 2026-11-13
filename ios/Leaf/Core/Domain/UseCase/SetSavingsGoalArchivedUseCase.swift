import Foundation

/// UseCase toggling the archival state of a savings goal without deleting historical contributions.
public final class SetSavingsGoalArchivedUseCase: Sendable {

    private let savingsGoalRepository: SavingsGoalRepositoryProtocol

    public init(savingsGoalRepository: SavingsGoalRepositoryProtocol) {
        self.savingsGoalRepository = savingsGoalRepository
    }

    public func execute(id: Int64, isArchived: Bool) async throws {
        try await savingsGoalRepository.setGoalArchived(id: id, isArchived: isArchived)
    }
}

