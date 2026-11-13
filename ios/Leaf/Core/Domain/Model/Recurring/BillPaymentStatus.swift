import Foundation

/// Payment and lifecycle status of a specific recurring occurrence or bill instance.
public enum BillPaymentStatus: String, Codable, CaseIterable, Identifiable, Sendable {
    case upcoming = "UPCOMING"
    case due = "DUE"
    case overdue = "OVERDUE"
    case paid = "PAID"
    case skipped = "SKIPPED"

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .upcoming: return "Upcoming"
        case .due: return "Due Today"
        case .overdue: return "Overdue"
        case .paid: return "Paid"
        case .skipped: return "Skipped"
        }
    }

    /// Whether this occurrence represents an unsettled payment obligation.
    public var isUnsettled: Bool {
        self == .upcoming || self == .due || self == .overdue
    }
}

