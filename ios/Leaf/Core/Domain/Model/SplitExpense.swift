import Foundation

public struct SplitExpense: Identifiable, Hashable, Codable, Sendable {
    public let id: Int64
    public let title: String
    public let totalAmount: Amount
    public let date: Int64
    public let categoryId: Int64
    public let paidBy: String
    public let splitMethod: String
    public let qrImagePath: String?
    public let addToTransactions: Bool
    public let expenseTransactionId: Int64?
    public let paymentMethod: PaymentMethod
    public let groupId: Int64?
    public let itemsJson: String?
    public let currencyCode: String
    public let exchangeRate: Double
    public let primaryTotalAmount: Amount
    public let participants: [SplitParticipant]
    public let createdAt: Int64
    public let updatedAt: Int64

    public init(
        id: Int64 = 0,
        title: String,
        totalAmount: Amount,
        date: Int64 = Int64(Date().timeIntervalSince1970 * 1000),
        categoryId: Int64,
        paidBy: String,
        splitMethod: String = "EQUAL",
        qrImagePath: String? = nil,
        addToTransactions: Bool = false,
        expenseTransactionId: Int64? = nil,
        paymentMethod: PaymentMethod = .cash,
        groupId: Int64? = nil,
        itemsJson: String? = nil,
        currencyCode: String = "INR",
        exchangeRate: Double = 1.0,
        primaryTotalAmount: Amount? = nil,
        participants: [SplitParticipant] = [],
        createdAt: Int64 = Int64(Date().timeIntervalSince1970 * 1000),
        updatedAt: Int64 = Int64(Date().timeIntervalSince1970 * 1000)
    ) {
        self.id = id
        self.title = title
        self.totalAmount = totalAmount
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
        self.primaryTotalAmount = primaryTotalAmount ?? totalAmount
        self.participants = participants
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    public var currency: Currency {
        Currency.fromCode(currencyCode)
    }
}

