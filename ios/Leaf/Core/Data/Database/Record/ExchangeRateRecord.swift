import Foundation
import GRDB

public struct ExchangeRateRecord: Codable, FetchableRecord, MutablePersistableRecord, TableRecord, Sendable {
    public static let databaseTableName = "exchange_rates"

    public var id: Int64?
    public var baseCurrencyCode: String
    public var targetCurrencyCode: String
    public var rate: Double
    public var effectiveDate: Int64
    public var source: String
    public var createdAt: Int64

    enum CodingKeys: String, CodingKey {
        case id
        case baseCurrencyCode = "base_currency_code"
        case targetCurrencyCode = "target_currency_code"
        case rate
        case effectiveDate = "effective_date"
        case source
        case createdAt = "created_at"
    }

    public init(
        id: Int64? = nil,
        baseCurrencyCode: String,
        targetCurrencyCode: String,
        rate: Double,
        effectiveDate: Int64 = Int64(Date().timeIntervalSince1970 * 1000),
        source: String = "MANUAL",
        createdAt: Int64 = Int64(Date().timeIntervalSince1970 * 1000)
    ) {
        self.id = id
        self.baseCurrencyCode = baseCurrencyCode
        self.targetCurrencyCode = targetCurrencyCode
        self.rate = rate
        self.effectiveDate = effectiveDate
        self.source = source
        self.createdAt = createdAt
    }

    public mutating func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }
}

