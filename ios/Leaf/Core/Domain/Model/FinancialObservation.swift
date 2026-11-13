import Foundation

/// Defines observation category and contextual meaning.
public enum ObservationType: String, Hashable, Sendable {
    case highestCategory
    case categorySurge
    case spendingReduction
    case budgetWarning
    case budgetExceeded
    case peakSpendingDay
    case healthyCashFlow
    case savingsMilestone
}

/// Sentiment for visual styling and badge coloring.
public enum ObservationSentiment: Hashable, Sendable {
    case positive
    case neutral
    case warning
    case critical
}

/// Action trigger target when an observation card is tapped for drill-down.
public enum ObservationAction: Hashable, Sendable {
    case category(categoryId: Int64)
    case budgets
    case savingsGoal(goalId: Int64)
    case date(Date)
}

/// Dynamic, rule-based observation generated strictly from persisted financial data.
public struct FinancialObservation: Identifiable, Hashable, Sendable {
    public let id: String
    public let type: ObservationType
    public let title: String
    public let message: String
    public let iconName: String
    public let sentiment: ObservationSentiment
    public let action: ObservationAction?

    public init(
        id: String,
        type: ObservationType,
        title: String,
        message: String,
        iconName: String,
        sentiment: ObservationSentiment,
        action: ObservationAction? = nil
    ) {
        self.id = id
        self.type = type
        self.title = title
        self.message = message
        self.iconName = iconName
        self.sentiment = sentiment
        self.action = action
    }
}

