import Foundation

/// Represents aggregated spending for a specific category within a defined time period.
public struct CategorySpending: Identifiable, Hashable, Sendable {
    public var id: Int64 { category.id }
    public let category: Category
    public let totalAmount: Amount
    public var amount: Amount { totalAmount }
    public let transactionCount: Int
    public let percentageOfTotal: Double // 0.0 to 100.0
    public var percentage: Double { percentageOfTotal }

    public init(
        category: Category,
        totalAmount: Amount,
        transactionCount: Int,
        percentageOfTotal: Double
    ) {
        self.category = category
        self.totalAmount = totalAmount
        self.transactionCount = transactionCount
        self.percentageOfTotal = percentageOfTotal
    }
}

