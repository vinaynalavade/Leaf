import Foundation

/// UseCase recording a manual or account-linked monetary contribution towards a savings goal.
public final class RecordSavingsContributionUseCase: Sendable {

    private let savingsGoalRepository: SavingsGoalRepositoryProtocol

    public init(savingsGoalRepository: SavingsGoalRepositoryProtocol) {
        self.savingsGoalRepository = savingsGoalRepository
    }

    public enum ContributionError: LocalizedError {
        case nonPositiveAmount
        case goalNotFound

        public var errorDescription: String? {
            switch self {
            case .nonPositiveAmount:
                return "Contribution amount must be strictly greater than zero."
            case .goalNotFound:
                return "The target savings goal was not found."
            }
        }
    }

    @discardableResult
    public func execute(
        goalId: Int64,
        amount: Amount,
        note: String? = nil,
        timestamp: Int64 = Int64(Date().timeIntervalSince1970 * 1000),
        createTransaction: Bool = false,
        paymentMethod: PaymentMethod = .account
    ) async throws -> SavingsGoalContribution {
        if amount.subunits <= 0 {
            throw ContributionError.nonPositiveAmount
        }

        guard (try await savingsGoalRepository.getGoal(id: goalId)) != nil else {
            throw ContributionError.goalNotFound
        }

        return try await savingsGoalRepository.addContribution(
            goalId: goalId,
            amount: amount,
            note: note,
            timestamp: timestamp,
            createTransaction: createTransaction,
            paymentMethod: paymentMethod
        )
    }
}

