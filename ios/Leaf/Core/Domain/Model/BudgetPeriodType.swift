import Foundation

/// Supported financial budget periods in Leaf.
public enum BudgetPeriodType: String, Codable, CaseIterable, Sendable {
    case monthly = "MONTHLY"
    case weekly = "WEEKLY"
    case yearly = "YEARLY"
    case custom = "CUSTOM"

    public var displayName: String {
        switch self {
        case .monthly: return "Monthly"
        case .weekly: return "Weekly"
        case .yearly: return "Yearly"
        case .custom: return "Custom Range"
        }
    }

    public var iconName: String {
        switch self {
        case .monthly: return "calendar"
        case .weekly: return "calendar.badge.clock"
        case .yearly: return "calendar.badge.exclamationmark"
        case .custom: return "calendar.day.timeline.left"
        }
    }
}

