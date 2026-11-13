import Foundation

/// Aggregated domain model for financial dashboard and summary statistics.
public struct FinancialSummary: Hashable, Codable, Sendable {
    public let openingBalance: Amount
    public let totalIncome: Amount
    public let totalExpense: Amount
    public let netChange: Amount
    public let currentBalance: Amount
    public let transactionCount: Int

    public init(
        openingBalance: Amount = .zero,
        totalIncome: Amount = .zero,
        totalExpense: Amount = .zero,
        netChange: Amount = .zero,
        currentBalance: Amount = .zero,
        transactionCount: Int = 0
    ) {
        self.openingBalance = openingBalance
        self.totalIncome = totalIncome
        self.totalExpense = totalExpense
        self.netChange = netChange
        self.currentBalance = currentBalance
        self.transactionCount = transactionCount
    }

    public static let empty = FinancialSummary()
}

