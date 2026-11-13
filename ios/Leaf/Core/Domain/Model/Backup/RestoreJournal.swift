import Foundation

/// Persistent journal written to disk in Application Support during the coordinated restore process.
/// Tracks explicit commit states and rollback snapshots to guarantee crash resiliency and atomicity.
public struct RestoreJournal: Codable, Sendable {

    /// Explicit, durable lifecycle steps of the coordinated restore process.
    public enum Step: String, Codable, Sendable {
        case preparing           // Stage 1: Staging incoming statement files & capturing pre-restore snapshots
        case databaseReplaced    // Stage 2: SQLite database records replaced & committed
        case statementsReplaced  // Stage 3: Statement files moved into Documents/Statements
        case committed           // Stage 4: Durable commit point! Both database & statements are verified
        case cleanupCompleted    // Stage 5: Temporary staging and pre-restore snapshots safely purged
        case rollingBack         // Rollback actively executing before commitment
        case rollbackCompleted   // Rollback safely finished; pre-restore state restored
    }

    public let step: Step
    public let timestamp: Int64
    public let originalCurrencyCode: String
    public let stagedStatementFileCount: Int
    public let preRestoreStatementFileCount: Int

    public init(
        step: Step,
        timestamp: Int64 = Int64(Date().timeIntervalSince1970 * 1000),
        originalCurrencyCode: String,
        stagedStatementFileCount: Int = 0,
        preRestoreStatementFileCount: Int = 0
    ) {
        self.step = step
        self.timestamp = timestamp
        self.originalCurrencyCode = originalCurrencyCode
        self.stagedStatementFileCount = stagedStatementFileCount
        self.preRestoreStatementFileCount = preRestoreStatementFileCount
    }
}
