import Foundation

/// UseCase validating and persisting an overall budget cap or category budget limit across
/// supported periods (Monthly, Weekly, Yearly, Custom date ranges) with optional recurrence.
public final class SaveBudgetUseCase: Sendable {

    private let budgetRepository: BudgetRepositoryProtocol

    public init(budgetRepository: BudgetRepositoryProtocol) {
        self.budgetRepository = budgetRepository
    }

    public enum BudgetValidationError: LocalizedError {
        case nonPositiveAmount
        case invalidPeriod
        case invalidCustomRange

        public var errorDescription: String? {
            switch self {
            case .nonPositiveAmount:
                return "Budget amount must be strictly greater than zero."
            case .invalidPeriod:
                return "Please select a valid month and year."
            case .invalidCustomRange:
                return "Custom range start date must be earlier than or equal to the end date."
            }
        }
    }

    @discardableResult
    public func execute(
        id: Int64 = 0,
        categoryId: Int64? = nil,
        amount: Amount,
        month: Int,
        year: Int,
        periodType: BudgetPeriodType = .monthly,
        startDate: Int64? = nil,
        endDate: Int64? = nil,
        isRecurring: Bool = true
    ) async throws -> Int64 {
        if amount.subunits <= 0 {
            throw BudgetValidationError.nonPositiveAmount
        }

        if periodType == .monthly {
            if month < 1 || month > 12 || year < 2000 || year > 2100 {
                throw BudgetValidationError.invalidPeriod
            }
        }

        if periodType == .custom {
            if let start = startDate, let end = endDate, start > end {
                throw BudgetValidationError.invalidCustomRange
            }
        }

        let existingBudgets = try await budgetRepository.getBudgetsForMonth(year: year, month: month)

        if id > 0 {
            // Update existing
            let budget = Budget(
                id: id,
                categoryId: categoryId,
                amount: amount,
                month: month,
                year: year,
                periodType: periodType,
                startDate: startDate,
                endDate: endDate,
                isRecurring: isRecurring,
                updatedAt: Int64(Date().timeIntervalSince1970 * 1000)
            )
            try await budgetRepository.updateBudget(budget)
            return id
        } else {
            // Check if one already exists for this exact category (or overall) with the same period
            if let existing = existingBudgets.first(where: {
                $0.categoryId == categoryId && $0.periodType == periodType
            }) {
                let updated = Budget(
                    id: existing.id,
                    categoryId: categoryId,
                    amount: amount,
                    month: month,
                    year: year,
                    periodType: periodType,
                    startDate: startDate,
                    endDate: endDate,
                    isRecurring: isRecurring,
                    createdAt: existing.createdAt,
                    updatedAt: Int64(Date().timeIntervalSince1970 * 1000)
                )
                try await budgetRepository.updateBudget(updated)
                return existing.id
            } else {
                let newBudget = Budget(
                    categoryId: categoryId,
                    amount: amount,
                    month: month,
                    year: year,
                    periodType: periodType,
                    startDate: startDate,
                    endDate: endDate,
                    isRecurring: isRecurring
                )
                return try await budgetRepository.insertBudget(newBudget)
            }
        }
    }
}
