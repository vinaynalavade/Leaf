import Foundation

/// UseCase responsible for validating and inserting a new SplitExpense with participants and optional ledger integration.
public final class CreateSplitExpenseUseCase: Sendable {

    private let splitRepository: SplitRepositoryProtocol

    public init(splitRepository: SplitRepositoryProtocol) {
        self.splitRepository = splitRepository
    }

    public enum CreateSplitError: LocalizedError {
        case emptyTitle
        case invalidAmount
        case insufficientParticipants
        case unbalancedAllocation(expected: Amount, actual: Amount)

        public var errorDescription: String? {
            switch self {
            case .emptyTitle:
                return "Please enter a valid expense title."
            case .invalidAmount:
                return "Expense amount must be strictly greater than zero."
            case .insufficientParticipants:
                return "Split expenses require at least two participants."
            case .unbalancedAllocation(let expected, let actual):
                return "Allocated participant shares (\(actual.subunits)) do not match total expense (\(expected.subunits))."
            }
        }
    }

    public func execute(
        title: String,
        totalAmount: Amount,
        date: Int64 = Int64(Date().timeIntervalSince1970 * 1000),
        categoryId: Int64,
        paidBy: String,
        splitMethod: String = "EQUAL",
        paymentMethod: PaymentMethod = .cash,
        addToTransactions: Bool = false,
        groupId: Int64? = nil,
        participants: [SplitParticipant],
        currencyCode: String = "INR",
        exchangeRate: Double = 1.0,
        primaryTotalAmount: Amount? = nil
    ) async throws -> Int64 {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedTitle.isEmpty {
            throw CreateSplitError.emptyTitle
        }

        if totalAmount.subunits <= 0 {
            throw CreateSplitError.invalidAmount
        }

        if participants.count < 2 {
            throw CreateSplitError.insufficientParticipants
        }

        let allocatedSubunits = participants.reduce(Int64(0)) { $0 + $1.amount.subunits }
        if allocatedSubunits != totalAmount.subunits {
            throw CreateSplitError.unbalancedAllocation(
                expected: totalAmount,
                actual: Amount(subunits: allocatedSubunits)
            )
        }

        let expense = SplitExpense(
            title: trimmedTitle,
            totalAmount: totalAmount,
            date: date,
            categoryId: categoryId,
            paidBy: paidBy,
            splitMethod: splitMethod,
            addToTransactions: addToTransactions,
            paymentMethod: paymentMethod,
            groupId: groupId,
            currencyCode: currencyCode,
            exchangeRate: exchangeRate,
            primaryTotalAmount: primaryTotalAmount ?? totalAmount,
            participants: participants,
            createdAt: date,
            updatedAt: Int64(Date().timeIntervalSince1970 * 1000)
        )

        return try await splitRepository.insertSplitExpense(expense)
    }
}

