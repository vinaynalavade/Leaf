import Foundation

/// UseCase validating and persisting a savings goal definition with optional initial seed amount.
public final class SaveSavingsGoalUseCase: Sendable {

    private let savingsGoalRepository: SavingsGoalRepositoryProtocol

    public init(savingsGoalRepository: SavingsGoalRepositoryProtocol) {
        self.savingsGoalRepository = savingsGoalRepository
    }

    public enum GoalValidationError: LocalizedError {
        case emptyName
        case nonPositiveTarget

        public var errorDescription: String? {
            switch self {
            case .emptyName:
                return "Please enter a valid goal name."
            case .nonPositiveTarget:
                return "Target savings amount must be strictly greater than zero."
            }
        }
    }

    @discardableResult
    public func execute(
        id: Int64 = 0,
        name: String,
        targetAmount: Amount,
        initialSavedAmount: Amount? = nil,
        targetDate: Int64? = nil,
        note: String? = nil,
        iconName: String = "savings",
        colorHex: String = "#10B981"
    ) async throws -> Int64 {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedName.isEmpty {
            throw GoalValidationError.emptyName
        }

        if targetAmount.subunits <= 0 {
            throw GoalValidationError.nonPositiveTarget
        }

        if id > 0 {
            // Update existing goal definition
            let existing = try await savingsGoalRepository.getGoal(id: id)
            let updated = SavingsGoal(
                id: id,
                name: trimmedName,
                targetAmount: targetAmount,
                targetDate: targetDate,
                note: note?.trimmingCharacters(in: .whitespacesAndNewlines),
                iconName: iconName,
                colorHex: colorHex,
                isArchived: existing?.isArchived ?? false,
                contributions: existing?.contributions ?? [],
                createdAt: existing?.createdAt ?? Int64(Date().timeIntervalSince1970 * 1000),
                updatedAt: Int64(Date().timeIntervalSince1970 * 1000)
            )
            try await savingsGoalRepository.updateGoal(updated)
            return id
        } else {
            // New goal
            let newGoal = SavingsGoal(
                name: trimmedName,
                targetAmount: targetAmount,
                targetDate: targetDate,
                note: note?.trimmingCharacters(in: .whitespacesAndNewlines),
                iconName: iconName,
                colorHex: colorHex
            )
            return try await savingsGoalRepository.insertGoal(newGoal, initialContribution: initialSavedAmount)
        }
    }
}

