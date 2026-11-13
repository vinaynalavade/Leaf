import Foundation
import GRDB

public struct TransactionRecord: Codable, FetchableRecord, MutablePersistableRecord, TableRecord, Sendable {
    public static let databaseTableName = "transactions"

    public var id: Int64?
    public var amountSubunits: Int64
    public var type: String
    public var categoryId: Int64
    public var paymentMethod: String?
    public var rawPaymentMethod: String?
    public var transferPairId: Int64?
    public var note: String?
    public var timestamp: Int64
    public var createdAt: Int64
    public var updatedAt: Int64
    public var isInternalTransfer: Bool
    public var recurringTransactionId: Int64?
    public var receiptImagePath: String?
    public var originalAmountSubunits: Int64?
    public var currencyCode: String
    public var exchangeRate: Double
    public var exchangeRateDate: Int64?
    public var exchangeRateSource: String
    public var travelWalletId: Int64?

    enum CodingKeys: String, CodingKey {
        case id
        case amountSubunits = "amount_subunits"
        case type
        case categoryId = "category_id"
        case paymentMethod = "payment_method"
        case rawPaymentMethod = "raw_payment_method"
        case transferPairId = "transfer_pair_id"
        case note
        case timestamp
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case isInternalTransfer = "is_internal_transfer"
        case recurringTransactionId = "recurring_transaction_id"
        case receiptImagePath = "receipt_image_path"
        case originalAmountSubunits = "original_amount_subunits"
        case currencyCode = "currency_code"
        case exchangeRate = "exchange_rate"
        case exchangeRateDate = "exchange_rate_date"
        case exchangeRateSource = "exchange_rate_source"
        case travelWalletId = "travel_wallet_id"
    }

    public init(
        id: Int64? = nil,
        amountSubunits: Int64,
        type: String,
        categoryId: Int64,
        paymentMethod: String? = "CASH",
        rawPaymentMethod: String? = nil,
        transferPairId: Int64? = nil,
        note: String? = nil,
        timestamp: Int64 = Int64(Date().timeIntervalSince1970 * 1000),
        createdAt: Int64 = Int64(Date().timeIntervalSince1970 * 1000),
        updatedAt: Int64 = Int64(Date().timeIntervalSince1970 * 1000),
        isInternalTransfer: Bool = false,
        recurringTransactionId: Int64? = nil,
        receiptImagePath: String? = nil,
        originalAmountSubunits: Int64? = nil,
        currencyCode: String = "INR",
        exchangeRate: Double = 1.0,
        exchangeRateDate: Int64? = nil,
        exchangeRateSource: String = "PRIMARY",
        travelWalletId: Int64? = nil
    ) {
        self.id = id
        self.amountSubunits = amountSubunits
        self.type = type
        self.categoryId = categoryId
        self.paymentMethod = paymentMethod
        self.rawPaymentMethod = rawPaymentMethod ?? paymentMethod
        self.transferPairId = transferPairId
        self.note = note
        self.timestamp = timestamp
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.isInternalTransfer = isInternalTransfer
        self.recurringTransactionId = recurringTransactionId
        self.receiptImagePath = receiptImagePath
        self.originalAmountSubunits = originalAmountSubunits ?? amountSubunits
        self.currencyCode = currencyCode
        self.exchangeRate = exchangeRate
        self.exchangeRateDate = exchangeRateDate
        self.exchangeRateSource = exchangeRateSource
        self.travelWalletId = travelWalletId
    }

    public mutating func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }
}
