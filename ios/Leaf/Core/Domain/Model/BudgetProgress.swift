import Foundation

/// Calculated progress of a budget for a specific month,
/// pairing the budget definition with current spending analytics.
public struct BudgetProgress: Identifiable, Hashable, Codable, Sendable {
    public var id: Int64 { budget.id }
    public let budget: Budget
    public let category: Category?
    public let usedAmount: Amount
    public let remainingAmount: Amount
    public let percentageUsed: Double
    public let status: BudgetStatus

    public init(
        budget: Budget,
        category: Category? = nil,
        usedAmount: Amount = .zero,
        remainingAmount: Amount = .zero,
        percentageUsed: Double = 0.0,
        status: BudgetStatus = .onTrack
    ) {
        self.budget = budget
        self.category = category
        self.usedAmount = usedAmount
        self.remainingAmount = remainingAmount
        self.percentageUsed = percentageUsed
        self.status = status
    }
}

