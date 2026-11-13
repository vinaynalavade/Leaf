import Foundation
import GRDB

/// GRDB SQLite record mapping for the `split_payments` table.
public struct SplitPaymentRecord: Codable, FetchableRecord, MutablePersistableRecord, TableRecord, Sendable {
    public static let databaseTableName = "split_payments"

    public var id: Int64?
    public var splitExpenseId: Int64
    public var participantId: Int64
    public var amountSubunits: Int64
    public var date: Int64
    public var paymentMethod: String
    public var note: String?
    public var transactionId: Int64?
    public var createdAt: Int64

    public enum CodingKeys: String, CodingKey {
        case id
        case splitExpenseId = "split_expense_id"
        case participantId = "participant_id"
        case amountSubunits = "amount_subunits"
        case date
        case paymentMethod = "payment_method"
        case note
        case transactionId = "transaction_id"
        case createdAt = "created_at"
    }

    public enum Columns {
        public static let id = Column(CodingKeys.id)
        public static let splitExpenseId = Column(CodingKeys.splitExpenseId)
        public static let participantId = Column(CodingKeys.participantId)
        public static let amountSubunits = Column(CodingKeys.amountSubunits)
        public static let date = Column(CodingKeys.date)
        public static let paymentMethod = Column(CodingKeys.paymentMethod)
        public static let note = Column(CodingKeys.note)
        public static let transactionId = Column(CodingKeys.transactionId)
        public static let createdAt = Column(CodingKeys.createdAt)
    }

    public init(
        id: Int64? = nil,
        splitExpenseId: Int64,
        participantId: Int64,
        amountSubunits: Int64,
        date: Int64,
        paymentMethod: String = "CASH",
        note: String? = nil,
        transactionId: Int64? = nil,
        createdAt: Int64 = Int64(Date().timeIntervalSince1970 * 1000)
    ) {
        self.id = id
        self.splitExpenseId = splitExpenseId
        self.participantId = participantId
        self.amountSubunits = amountSubunits
        self.date = date
        self.paymentMethod = paymentMethod
        self.note = note
        self.transactionId = transactionId
        self.createdAt = createdAt
    }

    public mutating func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }
}

