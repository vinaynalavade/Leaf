import Foundation
import GRDB

public struct SplitExpenseRecord: Codable, FetchableRecord, MutablePersistableRecord, TableRecord, Sendable {
    public static let databaseTableName = "split_expenses"

    public var id: Int64?
    public var title: String
    public var totalAmountSubunits: Int64
    public var date: Int64
    public var categoryId: Int64
    public var paidBy: String
    public var splitMethod: String
    public var qrImagePath: String?
    public var addToTransactions: Bool
    public var expenseTransactionId: Int64?
    public var paymentMethod: String
    public var groupId: Int64?
    public var itemsJson: String?
    public var currencyCode: String
    public var exchangeRate: Double
    public var primaryTotalAmountSubunits: Int64
    public var createdAt: Int64
    public var updatedAt: Int64

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case totalAmountSubunits = "total_amount_subunits"
        case date
        case categoryId = "category_id"
        case paidBy = "paid_by"
        case splitMethod = "split_method"
        case qrImagePath = "qr_image_path"
        case addToTransactions = "add_to_transactions"
        case expenseTransactionId = "expense_transaction_id"
        case paymentMethod = "payment_method"
        case groupId = "group_id"
        case itemsJson = "items_json"
        case currencyCode = "currency_code"
        case exchangeRate = "exchange_rate"
        case primaryTotalAmountSubunits = "primary_total_amount_subunits"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    public init(
        id: Int64? = nil,
        title: String,
        totalAmountSubunits: Int64,
        date: Int64 = Int64(Date().timeIntervalSince1970 * 1000),
        categoryId: Int64,
        paidBy: String,
        splitMethod: String = "EQUAL",
        qrImagePath: String? = nil,
        addToTransactions: Bool = false,
        expenseTransactionId: Int64? = nil,
        paymentMethod: String = "CASH",
        groupId: Int64? = nil,
        itemsJson: String? = nil,
        currencyCode: String = "INR",
        exchangeRate: Double = 1.0,
        primaryTotalAmountSubunits: Int64? = nil,
        createdAt: Int64 = Int64(Date().timeIntervalSince1970 * 1000),
        updatedAt: Int64 = Int64(Date().timeIntervalSince1970 * 1000)
    ) {
        self.id = id
        self.title = title
        self.totalAmountSubunits = totalAmountSubunits
        self.date = date
        self.categoryId = categoryId
        self.paidBy = paidBy
        self.splitMethod = splitMethod
        self.qrImagePath = qrImagePath
        self.addToTransactions = addToTransactions
        self.expenseTransactionId = expenseTransactionId
        self.paymentMethod = paymentMethod
        self.groupId = groupId
        self.itemsJson = itemsJson
        self.currencyCode = currencyCode
        self.exchangeRate = exchangeRate
        self.primaryTotalAmountSubunits = primaryTotalAmountSubunits ?? totalAmountSubunits
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    public mutating func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }
}

