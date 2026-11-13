import Foundation

public struct Transaction: Identifiable, Hashable, Codable, Sendable {
    public let id: Int64
    public let amount: Amount
    public let type: TransactionType
    public let categoryId: Int64
    public let category: Category?
    public let paymentMethod: PaymentMethod
    public let rawPaymentMethod: String?
    public let transferPairId: Int64?
    public let note: String?
    public let timestamp: Int64
    public let createdAt: Int64
    public let updatedAt: Int64
    public let isInternalTransfer: Bool
    public let recurringTransactionId: Int64?
    public let receiptImagePath: String?
    public let originalAmount: Amount
    public let currencyCode: String
    public let exchangeRate: Double
    public let exchangeRateDate: Int64?
    public let exchangeRateSource: String
    public let travelWalletId: Int64?

    public init(
        id: Int64 = 0,
        amount: Amount,
        type: TransactionType,
        categoryId: Int64,
        category: Category? = nil,
        paymentMethod: PaymentMethod = .cash,
        rawPaymentMethod: String? = nil,
        transferPairId: Int64? = nil,
        note: String? = nil,
        timestamp: Int64 = Int64(Date().timeIntervalSince1970 * 1000),
        createdAt: Int64 = Int64(Date().timeIntervalSince1970 * 1000),
        updatedAt: Int64 = Int64(Date().timeIntervalSince1970 * 1000),
        isInternalTransfer: Bool = false,
        recurringTransactionId: Int64? = nil,
        receiptImagePath: String? = nil,
        originalAmount: Amount? = nil,
        currencyCode: String = "INR",
        exchangeRate: Double = 1.0,
        exchangeRateDate: Int64? = nil,
        exchangeRateSource: String = "PRIMARY",
        travelWalletId: Int64? = nil
    ) {
        self.id = id
        self.amount = amount
        self.type = type
        self.categoryId = categoryId
        self.category = category
        self.paymentMethod = paymentMethod
        self.rawPaymentMethod = rawPaymentMethod
        self.transferPairId = transferPairId
        self.note = note
        self.timestamp = timestamp
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.isInternalTransfer = isInternalTransfer
        self.recurringTransactionId = recurringTransactionId
        self.receiptImagePath = receiptImagePath
        self.originalAmount = originalAmount ?? amount
        self.currencyCode = currencyCode.uppercased()
        self.exchangeRate = exchangeRate
        self.exchangeRateDate = exchangeRateDate
        self.exchangeRateSource = exchangeRateSource
        self.travelWalletId = travelWalletId
    }

    public var originalCurrency: Currency {
        Currency.fromCode(currencyCode)
    }

    public func isPrimaryCurrency(primaryCode: String) -> Bool {
        currencyCode.caseInsensitiveCompare(primaryCode) == .orderedSame
    }
}
