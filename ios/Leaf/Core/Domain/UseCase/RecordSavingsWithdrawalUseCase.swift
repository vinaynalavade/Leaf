import Foundation

/// UseCase recording a manual or account-linked monetary withdrawal from a savings goal.
/// Strictly enforces that withdrawal amount cannot exceed current available savings.
public final class RecordSavingsWithdrawalUseCase: Sendable {

    private let savingsGoalRepository: SavingsGoalRepositoryProtocol

    public init(savingsGoalRepository: SavingsGoalRepositoryProtocol) {
        self.savingsGoalRepository = savingsGoalRepository
    }

    public enum WithdrawalError: LocalizedError {
        case nonPositiveAmount
        case goalNotFound
        case goalArchived
        case exceedsAvailableSavings(available: Amount)

        public var errorDescription: String? {
            switch self {
            case .nonPositiveAmount:
                return "Withdrawal amount must be strictly greater than zero."
            case .goalNotFound:
                return "The target savings goal was not found."
            case .goalArchived:
                return "Cannot withdraw from an archived savings goal."
            case .exceedsAvailableSavings(let available):
                return "Withdrawal amount cannot exceed available savings of \(available.subunits) subunits."
            }
        }
    }

    @discardableResult
    public func execute(
        goalId: Int64,
        amount: Amount,
        note: String? = nil,
        timestamp: Int64 = Int64(Date().timeIntervalSince1970 * 1000),
        returnToAccount: Bool = true,
        paymentMethod: PaymentMethod = .account
    ) async throws -> SavingsGoalContribution {
        if amount.subunits <= 0 {
            throw WithdrawalError.nonPositiveAmount
        }

        guard let goal = try await savingsGoalRepository.getGoal(id: goalId) else {
            throw WithdrawalError.goalNotFound
        }

        if goal.isArchived {
            throw WithdrawalError.goalArchived
        }

        if amount.subunits > goal.currentSavedAmount.subunits {
            throw WithdrawalError.exceedsAvailableSavings(available: goal.currentSavedAmount)
        }

        return try await savingsGoalRepository.addWithdrawal(
            goalId: goalId,
            amount: amount,
            note: note,
            timestamp: timestamp,
            returnToAccount: returnToAccount,
            paymentMethod: paymentMethod
        )
    }
}

