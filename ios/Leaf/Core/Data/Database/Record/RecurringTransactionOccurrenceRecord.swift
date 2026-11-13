import Foundation
import GRDB

public struct RecurringTransactionOccurrenceRecord: Codable, FetchableRecord, MutablePersistableRecord, TableRecord, Sendable {
    public static let databaseTableName = "recurring_transaction_occurrences"

    public var id: Int64?
    public var recurringTransactionId: Int64
    public var scheduledDate: Int64
    public var dueDate: Int64
    public var amountSubunits: Int64
    public var status: String
    public var transactionId: Int64?
    public var paidAt: Int64?
    public var snoozedUntil: Int64?
    public var createdAt: Int64
    public var updatedAt: Int64

    enum CodingKeys: String, CodingKey {
        case id
        case recurringTransactionId = "recurring_transaction_id"
        case scheduledDate = "scheduled_date"
        case dueDate = "due_date"
        case amountSubunits = "amount_subunits"
        case status
        case transactionId = "transaction_id"
        case paidAt = "paid_at"
        case snoozedUntil = "snoozed_until"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    public init(
        id: Int64? = nil,
        recurringTransactionId: Int64,
        scheduledDate: Int64,
        dueDate: Int64,
        amountSubunits: Int64,
        status: String = "UPCOMING",
        transactionId: Int64? = nil,
        paidAt: Int64? = nil,
        snoozedUntil: Int64? = nil,
        createdAt: Int64 = Int64(Date().timeIntervalSince1970 * 1000),
        updatedAt: Int64 = Int64(Date().timeIntervalSince1970 * 1000)
    ) {
        self.id = id
        self.recurringTransactionId = recurringTransactionId
        self.scheduledDate = scheduledDate
        self.dueDate = dueDate
        self.amountSubunits = amountSubunits
        self.status = status
        self.transactionId = transactionId
        self.paidAt = paidAt
        self.snoozedUntil = snoozedUntil
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    public mutating func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }
}

