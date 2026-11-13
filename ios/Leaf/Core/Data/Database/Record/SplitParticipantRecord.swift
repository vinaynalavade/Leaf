import Foundation
import GRDB

public struct SplitParticipantRecord: Codable, FetchableRecord, MutablePersistableRecord, TableRecord, Sendable {
    public static let databaseTableName = "split_participants"

    public var id: Int64?
    public var splitExpenseId: Int64
    public var name: String
    public var isCurrentUser: Bool
    public var amountSubunits: Int64
    public var settlementStatus: String
    public var settledAt: Int64?
    public var settlementTransactionId: Int64?
    public var phoneNumber: String?

    enum CodingKeys: String, CodingKey {
        case id
        case splitExpenseId = "split_expense_id"
        case name
        case isCurrentUser = "is_current_user"
        case amountSubunits = "amount_subunits"
        case settlementStatus = "settlement_status"
        case settledAt = "settled_at"
        case settlementTransactionId = "settlement_transaction_id"
        case phoneNumber = "phone_number"
    }

    public init(
        id: Int64? = nil,
        splitExpenseId: Int64,
        name: String,
        isCurrentUser: Bool,
        amountSubunits: Int64,
        settlementStatus: String = "PENDING",
        settledAt: Int64? = nil,
        settlementTransactionId: Int64? = nil,
        phoneNumber: String? = nil
    ) {
        self.id = id
        self.splitExpenseId = splitExpenseId
        self.name = name
        self.isCurrentUser = isCurrentUser
        self.amountSubunits = amountSubunits
        self.settlementStatus = settlementStatus
        self.settledAt = settledAt
        self.settlementTransactionId = settlementTransactionId
        self.phoneNumber = phoneNumber
    }

    public mutating func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }
}

