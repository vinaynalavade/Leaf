import Foundation

/// Filter options for date range filtering in Split Group analytics.
public enum SplitGroupDateFilter: String, CaseIterable, Identifiable, Sendable {
    case allTime = "All Time"
    case thisMonth = "This Month"
    case lastMonth = "Last Month"
    case last3Months = "Last 3 Months"
    case custom = "Custom"

    public var id: String { rawValue }
}

/// Category spending aggregation within a specific SplitGroup.
public struct SplitGroupCategorySpending: Identifiable, Hashable, Sendable {
    public var id: Int64 { categoryId }
    public let categoryId: Int64
    public let categoryName: String
    public let categoryIcon: String
    public let categoryColorHex: String
    public let totalAmount: Amount
    public let percentage: Double
    public let expenseCount: Int

    public init(
        categoryId: Int64,
        categoryName: String,
        categoryIcon: String,
        categoryColorHex: String,
        totalAmount: Amount,
        percentage: Double,
        expenseCount: Int
    ) {
        self.categoryId = categoryId
        self.categoryName = categoryName
        self.categoryIcon = categoryIcon
        self.categoryColorHex = categoryColorHex
        self.totalAmount = totalAmount
        self.percentage = percentage
        self.expenseCount = expenseCount
    }
}

/// Time-bucketed spending aggregation point for timeline charts within a specific SplitGroup.
public struct SplitGroupTimelinePoint: Identifiable, Hashable, Sendable {
    public let id: String
    public let date: Date
    public let dateLabel: String
    public let totalAmount: Amount
    public let expenseCount: Int

    public init(
        id: String,
        date: Date,
        dateLabel: String,
        totalAmount: Amount,
        expenseCount: Int
    ) {
        self.id = id
        self.date = date
        self.dateLabel = dateLabel
        self.totalAmount = totalAmount
        self.expenseCount = expenseCount
    }
}

/// Comprehensive analytics model strictly scoped to an individual SplitGroup.
/// All monetary values use integer subunits (`Amount`) to prevent floating-point calculation drift.
public struct SplitGroupAnalytics: Sendable {
    public let group: SplitGroup
    public let totalSpending: Amount
    public let expenseCount: Int
    public let participantCount: Int
    public let averagePerParticipant: Amount
    public let highestExpense: SplitExpense?
    public let mostExpensiveCategory: SplitGroupCategorySpending?
    public let categoryBreakdown: [SplitGroupCategorySpending]
    public let timelinePoints: [SplitGroupTimelinePoint]
    public let highestSpendingDate: Date?
    public let highestSpendingAmount: Amount
    public let expenses: [SplitExpense]

    public init(
        group: SplitGroup,
        totalSpending: Amount,
        expenseCount: Int,
        participantCount: Int,
        averagePerParticipant: Amount,
        highestExpense: SplitExpense?,
        mostExpensiveCategory: SplitGroupCategorySpending?,
        categoryBreakdown: [SplitGroupCategorySpending],
        timelinePoints: [SplitGroupTimelinePoint],
        highestSpendingDate: Date?,
        highestSpendingAmount: Amount,
        expenses: [SplitExpense]
    ) {
        self.group = group
        self.totalSpending = totalSpending
        self.expenseCount = expenseCount
        self.participantCount = participantCount
        self.averagePerParticipant = averagePerParticipant
        self.highestExpense = highestExpense
        self.mostExpensiveCategory = mostExpensiveCategory
        self.categoryBreakdown = categoryBreakdown
        self.timelinePoints = timelinePoints
        self.highestSpendingDate = highestSpendingDate
        self.highestSpendingAmount = highestSpendingAmount
        self.expenses = expenses
    }
}

