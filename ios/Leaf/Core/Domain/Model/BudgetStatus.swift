import Foundation

/// 4-tier threshold alert status of a budget relative to current spending,
/// specified in FEAT-04 of the master documentation.
public enum BudgetStatus: String, Hashable, Codable, CaseIterable, Sendable {
    case onTrack = "ON_TRACK"
    case approachingLimit = "APPROACHING_LIMIT"
    case limitReached = "LIMIT_REACHED"
    case overBudget = "OVER_BUDGET"

    public var displayName: String {
        switch self {
        case .onTrack: return "On Track"
        case .approachingLimit: return "Approaching Limit"
        case .limitReached: return "Limit Reached"
        case .overBudget: return "Over Budget"
        }
    }

    /// Master specification color tokens:
    /// - On Track (< 75%): Emerald Green (#10B981)
    /// - Approaching Limit (75% <= Usage < 100%): Amber Gold (#F59E0B)
    /// - Limit Reached (100%): Warning Amber (#D97706)
    /// - Over Budget (> 100%): Crimson Red (#DC2626)
    public var colorHex: String {
        switch self {
        case .onTrack: return "#10B981"
        case .approachingLimit: return "#F59E0B"
        case .limitReached: return "#D97706"
        case .overBudget: return "#DC2626"
        }
    }

    // Convenience aliases
    public static let warning = BudgetStatus.approachingLimit
    public static let exceeded = BudgetStatus.overBudget
}

