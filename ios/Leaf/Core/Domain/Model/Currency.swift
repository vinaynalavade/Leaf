import Foundation

/// Currency configuration model supporting exact subunit scaling for global currencies.
public struct Currency: Hashable, Identifiable, Codable, Sendable {

    public var id: String { code }

    public let code: String
    public let symbol: String
    public let name: String
    public let subunitName: String
    public let decimalDigits: Int
    public let subunitFactor: Int64
    public let symbolBeforeAmount: Bool

    public init(
        code: String,
        symbol: String,
        name: String,
        subunitName: String,
        decimalDigits: Int = 2,
        subunitFactor: Int64 = 100,
        symbolBeforeAmount: Bool = true
    ) {
        self.code = code
        self.symbol = symbol
        self.name = name
        self.subunitName = subunitName
        self.decimalDigits = decimalDigits
        self.subunitFactor = subunitFactor
        self.symbolBeforeAmount = symbolBeforeAmount
    }

    // MARK: - Supported Global Currencies

    public static let inr = Currency(
        code: "INR",
        symbol: "₹",
        name: "Indian Rupee",
        subunitName: "Paise",
        decimalDigits: 2,
        subunitFactor: 100,
        symbolBeforeAmount: true
    )

    public static let usd = Currency(
        code: "USD",
        symbol: "$",
        name: "US Dollar",
        subunitName: "Cent",
        decimalDigits: 2,
        subunitFactor: 100,
        symbolBeforeAmount: true
    )

    public static let eur = Currency(
        code: "EUR",
        symbol: "€",
        name: "Euro",
        subunitName: "Cent",
        decimalDigits: 2,
        subunitFactor: 100,
        symbolBeforeAmount: true
    )

    public static let gbp = Currency(
        code: "GBP",
        symbol: "£",
        name: "British Pound",
        subunitName: "Penny",
        decimalDigits: 2,
        subunitFactor: 100,
        symbolBeforeAmount: true
    )

    public static let aed = Currency(
        code: "AED",
        symbol: "د.إ",
        name: "UAE Dirham",
        subunitName: "Fils",
        decimalDigits: 2,
        subunitFactor: 100,
        symbolBeforeAmount: true
    )

    public static let sgd = Currency(
        code: "SGD",
        symbol: "S$",
        name: "Singapore Dollar",
        subunitName: "Cent",
        decimalDigits: 2,
        subunitFactor: 100,
        symbolBeforeAmount: true
    )

    public static let cad = Currency(
        code: "CAD",
        symbol: "C$",
        name: "Canadian Dollar",
        subunitName: "Cent",
        decimalDigits: 2,
        subunitFactor: 100,
        symbolBeforeAmount: true
    )

    public static let aud = Currency(
        code: "AUD",
        symbol: "A$",
        name: "Australian Dollar",
        subunitName: "Cent",
        decimalDigits: 2,
        subunitFactor: 100,
        symbolBeforeAmount: true
    )

    public static let jpy = Currency(
        code: "JPY",
        symbol: "¥",
        name: "Japanese Yen",
        subunitName: "Yen",
        decimalDigits: 0,
        subunitFactor: 1,
        symbolBeforeAmount: true
    )

    public static let chf = Currency(
        code: "CHF",
        symbol: "CHF",
        name: "Swiss Franc",
        subunitName: "Rappen",
        decimalDigits: 2,
        subunitFactor: 100,
        symbolBeforeAmount: true
    )

    public static let cny = Currency(
        code: "CNY",
        symbol: "CN¥",
        name: "Chinese Yuan",
        subunitName: "Fen",
        decimalDigits: 2,
        subunitFactor: 100,
        symbolBeforeAmount: true
    )

    public static let `default`: Currency = .inr

    public static let supportedCurrencies: [Currency] = [
        .inr, .usd, .eur, .gbp, .aed, .sgd, .cad, .aud, .jpy
    ]

    public static func fromCode(_ code: String) -> Currency {
        supportedCurrencies.first { $0.code.caseInsensitiveCompare(code) == .orderedSame } ?? .default
    }
}

