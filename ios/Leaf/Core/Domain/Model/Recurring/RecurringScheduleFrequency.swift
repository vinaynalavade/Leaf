import Foundation

/// Recurrence cadence options for recurring expenses, income, subscriptions, and bill reminders.
public enum RecurringScheduleFrequency: String, Codable, CaseIterable, Identifiable, Sendable {
    case daily = "DAILY"
    case weekly = "WEEKLY"
    case biweekly = "BIWEEKLY"
    case monthly = "MONTHLY"
    case everyTwoMonths = "EVERY_TWO_MONTHS"
    case quarterly = "QUARTERLY"
    case halfYearly = "HALF_YEARLY"
    case yearly = "YEARLY"
    case custom = "CUSTOM"

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .daily: return "Daily"
        case .weekly: return "Weekly"
        case .biweekly: return "Bi-Weekly (Every 2 weeks)"
        case .monthly: return "Monthly"
        case .everyTwoMonths: return "Every 2 Months"
        case .quarterly: return "Quarterly (Every 3 months)"
        case .halfYearly: return "Half-Yearly (Every 6 months)"
        case .yearly: return "Yearly"
        case .custom: return "Custom Interval"
        }
    }

    /// Approximate multiplier to convert recurring amount into monthly equivalent for financial projections.
    public var monthlyMultiplier: Double {
        switch self {
        case .daily: return 30.4167
        case .weekly: return 4.3333
        case .biweekly: return 2.1667
        case .monthly: return 1.0
        case .everyTwoMonths: return 0.5
        case .quarterly: return 1.0 / 3.0
        case .halfYearly: return 1.0 / 6.0
        case .yearly: return 1.0 / 12.0
        case .custom: return 1.0
        }
    }
}

