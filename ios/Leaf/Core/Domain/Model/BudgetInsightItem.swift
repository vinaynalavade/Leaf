import Foundation

/// Analytical evaluation of a budget against actual ordinary spending.
public struct BudgetInsightItem: Identifiable, Hashable, Sendable {
    public var id: Int64 { budget.id }
    public let budget: Budget
    public let category: Category?
    public let spentAmount: Amount
    public let limitAmount: Amount
    public let remainingAmount: Amount
    public let utilisationPercentage: Double // 0.0 to 100.0+
    public let status: BudgetStatus
    public let periodLabel: String
    public let isHistorical: Bool

    public init(
        budget: Budget,
        category: Category?,
        spentAmount: Amount,
        limitAmount: Amount,
        remainingAmount: Amount,
        utilisationPercentage: Double,
        status: BudgetStatus,
        periodLabel: String = "",
        isHistorical: Bool = false
    ) {
        self.budget = budget
        self.category = category
        self.spentAmount = spentAmount
        self.limitAmount = limitAmount
        self.remainingAmount = remainingAmount
        self.utilisationPercentage = utilisationPercentage
        self.status = status
        self.periodLabel = periodLabel
        self.isHistorical = isHistorical
    }
}

