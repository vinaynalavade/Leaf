import Foundation

/// UseCase responsible for updating existing SplitExpense details, categories, and participants.
public final class UpdateSplitExpenseUseCase: Sendable {

    private let splitRepository: SplitRepositoryProtocol

    public init(splitRepository: SplitRepositoryProtocol) {
        self.splitRepository = splitRepository
    }

    public enum UpdateSplitError: LocalizedError {
        case emptyTitle
        case invalidAmount
        case insufficientParticipants
        case unbalancedAllocation

        public var errorDescription: String? {
            switch self {
            case .emptyTitle: return "Please enter a valid expense title."
            case .invalidAmount: return "Expense amount must be strictly greater than zero."
            case .insufficientParticipants: return "Split expenses require at least two participants."
            case .unbalancedAllocation: return "Participant shares must exactly match total bill amount."
            }
        }
    }

    public func execute(_ split: SplitExpense) async throws {
        let trimmedTitle = split.title.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedTitle.isEmpty {
            throw UpdateSplitError.emptyTitle
        }

        if split.totalAmount.subunits <= 0 {
            throw UpdateSplitError.invalidAmount
        }

        if split.participants.count < 2 {
            throw UpdateSplitError.insufficientParticipants
        }

        let allocated = split.participants.reduce(Int64(0)) { $0 + $1.amount.subunits }
        if allocated != split.totalAmount.subunits {
            throw UpdateSplitError.unbalancedAllocation
        }

        try await splitRepository.updateSplitExpense(split)
    }
}

