import Foundation

/// Analytical category breakdown item with spending share, count, and previous period comparisons.
public struct CategoryAnalysisItem: Identifiable, Hashable, Sendable {
    public var id: Int64 { category.id }
    public let category: Category
    public let amount: Amount
    public let percentageOfTotal: Double // 0.0 to 100.0
    public let transactionCount: Int
    public let previousPeriodAmount: Amount?
    public let changePercentageVsPrevious: Double? // e.g. +14.2% or -8.5%

    public init(
        category: Category,
        amount: Amount,
        percentageOfTotal: Double,
        transactionCount: Int,
        previousPeriodAmount: Amount? = nil,
        changePercentageVsPrevious: Double? = nil
    ) {
        self.category = category
        self.amount = amount
        self.percentageOfTotal = percentageOfTotal
        self.transactionCount = transactionCount
        self.previousPeriodAmount = previousPeriodAmount
        self.changePercentageVsPrevious = changePercentageVsPrevious
    }
}

