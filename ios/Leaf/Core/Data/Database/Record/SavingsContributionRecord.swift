import Foundation
import GRDB

public struct SavingsContributionRecord: Codable, FetchableRecord, MutablePersistableRecord, TableRecord, Sendable {
    public static let databaseTableName = "savings_goal_contributions"

    public var id: Int64?
    public var goalId: Int64
    public var amountSubunits: Int64
    public var note: String?
    public var timestamp: Int64
    public var createdAt: Int64
    public var transactionId: Int64?

    enum CodingKeys: String, CodingKey {
        case id
        case goalId = "goal_id"
        case amountSubunits = "amount_subunits"
        case note
        case timestamp
        case createdAt = "created_at"
        case transactionId = "transaction_id"
    }

    public init(
        id: Int64? = nil,
        goalId: Int64,
        amountSubunits: Int64,
        note: String? = nil,
        timestamp: Int64 = Int64(Date().timeIntervalSince1970 * 1000),
        createdAt: Int64 = Int64(Date().timeIntervalSince1970 * 1000),
        transactionId: Int64? = nil
    ) {
        self.id = id
        self.goalId = goalId
        self.amountSubunits = amountSubunits
        self.note = note
        self.timestamp = timestamp
        self.createdAt = createdAt
        self.transactionId = transactionId
    }

    public mutating func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }
}

