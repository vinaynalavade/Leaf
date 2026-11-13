import Foundation

/// Operational status of a recurring transaction schedule.
public enum RecurringScheduleStatus: String, Codable, CaseIterable, Identifiable, Sendable {
    case active = "ACTIVE"
    case paused = "PAUSED"
    case cancelled = "CANCELLED"

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .active: return "Active"
        case .paused: return "Paused"
        case .cancelled: return "Cancelled"
        }
    }
}

