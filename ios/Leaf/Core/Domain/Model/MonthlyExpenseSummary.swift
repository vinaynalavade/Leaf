import Foundation

/// Represents high-level monthly expense performance metrics.
public struct MonthlyExpenseSummary: Hashable, Sendable {
    public let selectedYear: Int
    public let selectedMonth: Int // 1...12
    public let totalExpense: Amount
    public let transactionCount: Int
    public let dailyAverage: Amount
    public let previousMonthExpense: Amount?
    public let percentageChangeVsPreviousMonth: Double? // Positive means higher expense, negative means lower expense

    public init(
        selectedYear: Int,
        selectedMonth: Int,
        totalExpense: Amount,
        transactionCount: Int,
        dailyAverage: Amount,
        previousMonthExpense: Amount? = nil,
        percentageChangeVsPreviousMonth: Double? = nil
    ) {
        self.selectedYear = selectedYear
        self.selectedMonth = selectedMonth
        self.totalExpense = totalExpense
        self.transactionCount = transactionCount
        self.dailyAverage = dailyAverage
        self.previousMonthExpense = previousMonthExpense
        self.percentageChangeVsPreviousMonth = percentageChangeVsPreviousMonth
    }

    /// Formatted localized title for the month and year, e.g. "November 2026".
    public var formattedPeriod: String {
        var components = DateComponents()
        components.year = selectedYear
        components.month = selectedMonth
        let calendar = Calendar.current
        if let date = calendar.date(from: components) {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMMM yyyy"
            return formatter.string(from: date)
        }
        return "\(selectedMonth)/\(selectedYear)"
    }

    public static var empty: MonthlyExpenseSummary {
        let calendar = Calendar.current
        let now = Date()
        return MonthlyExpenseSummary(
            selectedYear: calendar.component(.year, from: now),
            selectedMonth: calendar.component(.month, from: now),
            totalExpense: Amount(subunits: 0),
            transactionCount: 0,
            dailyAverage: Amount(subunits: 0),
            previousMonthExpense: nil,
            percentageChangeVsPreviousMonth: nil
        )
    }
}

