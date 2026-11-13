import Foundation

/// Represents an exchange rate between two currencies at an effective date.
/// Direction convention: 1 Unit of `baseCurrencyCode` = `rate` Units of `targetCurrencyCode`.
/// Example: Base USD, Target INR, Rate 83.50 means 1 USD = ₹83.50.
public struct ExchangeRate: Identifiable, Hashable, Codable, Sendable {
    public var id: Int64?
    public let baseCurrencyCode: String
    public let targetCurrencyCode: String
    public let rate: Double
    public let effectiveDate: Int64
    public let source: String // "MANUAL", "CACHED", or "PRIMARY"
    public let createdAt: Int64

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
        self.baseCurrencyCode = baseCurrencyCode.uppercased()
        self.targetCurrencyCode = targetCurrencyCode.uppercased()
        self.rate = rate
        self.effectiveDate = effectiveDate
        self.source = source
        self.createdAt = createdAt
    }

    public var baseCurrency: Currency {
        Currency.fromCode(baseCurrencyCode)
    }

    public var targetCurrency: Currency {
        Currency.fromCode(targetCurrencyCode)
    }

    /// Clean human-readable display string: e.g. "1 USD = ₹83.50"
    public var formattedRate: String {
        let formattedValue = String(format: "%.2f", rate)
        return "1 \(baseCurrencyCode) = \(targetCurrency.symbol)\(formattedValue)"
    }
}

