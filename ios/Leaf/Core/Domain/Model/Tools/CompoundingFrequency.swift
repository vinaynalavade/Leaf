import Foundation

/// Compounding intervals supported across FD and RD investment calculations.
public enum CompoundingFrequency: String, CaseIterable, Identifiable, Sendable {
    case monthly = "MONTHLY"
    case quarterly = "QUARTERLY"
    case halfYearly = "HALF_YEARLY"
    case annually = "ANNUALLY"

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .monthly: return "Monthly"
        case .quarterly: return "Quarterly (Standard)"
        case .halfYearly: return "Half-Yearly"
        case .annually: return "Annually"
        }
    }

    public var periodsPerYear: Double {
        switch self {
        case .monthly: return 12.0
        case .quarterly: return 4.0
        case .halfYearly: return 2.0
        case .annually: return 1.0
        }
    }
}

