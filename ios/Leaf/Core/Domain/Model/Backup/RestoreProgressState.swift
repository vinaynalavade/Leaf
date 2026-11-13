import Foundation

/// Progress phases during the atomic backup restoration and recovery process.
public enum RestoreProgressState: Equatable, Sendable {
    case idle
    case validating
    case decrypting
    case preparing
    case restoringRecords
    case restoringStatements
    case finalizing
    case completed
    case failed(String)

    public var title: String {
        switch self {
        case .idle:
            return "Ready"
        case .validating:
            return "Validating backup"
        case .decrypting:
            return "Decrypting backup"
        case .preparing:
            return "Preparing restore"
        case .restoringRecords:
            return "Restoring financial records"
        case .restoringStatements:
            return "Restoring statements"
        case .finalizing:
            return "Finalizing"
        case .completed:
            return "Restore Complete"
        case .failed(let reason):
            return "Restoration Failed: \(reason)"
        }
    }

    public var isTerminal: Bool {
        switch self {
        case .completed, .failed: return true
        default: return false
        }
    }

    public var progressRatio: Double {
        switch self {
        case .idle: return 0.0
        case .validating: return 0.15
        case .decrypting: return 0.30
        case .preparing: return 0.45
        case .restoringRecords: return 0.65
        case .restoringStatements: return 0.85
        case .finalizing: return 0.95
        case .completed: return 1.0
        case .failed: return 0.0
        }
    }
}

