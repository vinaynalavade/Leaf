import Foundation

/// Time-bucketed financial point representing spending and income dynamics for Swift Charts.
public struct SpendingTrendPoint: Identifiable, Hashable, Sendable {
    public let id: String
    public let label: String
    public let date: Date
    public let expenseSubunits: Int64
    public let incomeSubunits: Int64
    public let netSubunits: Int64

    public var expenseAmount: Amount { Amount(expenseSubunits) }
    public var incomeAmount: Amount { Amount(incomeSubunits) }
    public var netAmount: Amount { Amount(netSubunits) }

    /// Expense in major currency units for smooth chart Mark plotting.
    public var expenseValue: Double {
        Double(expenseSubunits) / 100.0
    }

    /// Income in major currency units for smooth chart Mark plotting.
    public var incomeValue: Double {
        Double(incomeSubunits) / 100.0
    }

    public init(
        id: String,
        label: String,
        date: Date,
        expenseSubunits: Int64,
        incomeSubunits: Int64
    ) {
        self.id = id
        self.label = label
        self.date = date
        self.expenseSubunits = expenseSubunits
        self.incomeSubunits = incomeSubunits
        self.netSubunits = incomeSubunits - expenseSubunits
    }
}

/// Key aggregate statistics across the evaluated period with previous-period comparisons.
public struct SpendingStatistics: Hashable, Sendable {
    public let dailyAverageExpense: Amount
    public let highestSpendingDay: SpendingDayPoint?
    public let transactionCount: Int
    public let averageTransactionAmount: Amount
    public let topCategory: CategoryAnalysisItem?

    // Previous-Period Comparative Metrics
    public let previousDailyAverageExpense: Amount?
    public let dailyAverageChangePercentage: Double?
    public let previousTransactionCount: Int?
    public let transactionCountChangePercentage: Double?

    public var highestSpendingCategory: CategoryAnalysisItem? { topCategory }

    public init(
        dailyAverageExpense: Amount,
        highestSpendingDay: SpendingDayPoint?,
        transactionCount: Int,
        averageTransactionAmount: Amount,
        topCategory: CategoryAnalysisItem?,
        previousDailyAverageExpense: Amount? = nil,
        dailyAverageChangePercentage: Double? = nil,
        previousTransactionCount: Int? = nil,
        transactionCountChangePercentage: Double? = nil
    ) {
        self.dailyAverageExpense = dailyAverageExpense
        self.highestSpendingDay = highestSpendingDay
        self.transactionCount = transactionCount
        self.averageTransactionAmount = averageTransactionAmount
        self.topCategory = topCategory
        self.previousDailyAverageExpense = previousDailyAverageExpense
        self.dailyAverageChangePercentage = dailyAverageChangePercentage
        self.previousTransactionCount = previousTransactionCount
        self.transactionCountChangePercentage = transactionCountChangePercentage
    }

    public static var empty: SpendingStatistics {
        SpendingStatistics(
            dailyAverageExpense: .zero,
            highestSpendingDay: nil,
            transactionCount: 0,
            averageTransactionAmount: .zero,
            topCategory: nil,
            previousDailyAverageExpense: nil,
            dailyAverageChangePercentage: nil,
            previousTransactionCount: nil,
            transactionCountChangePercentage: nil
        )
    }
}

/// Identifies a specific peak spending date in the period.
public struct SpendingDayPoint: Hashable, Sendable {
    public let date: Date
    public let amount: Amount
    public let transactionCount: Int

    public init(date: Date, amount: Amount, transactionCount: Int) {
        self.date = date
        self.amount = amount
        self.transactionCount = transactionCount
    }

    public var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, MMM d"
        return formatter.string(from: date)
    }
}

