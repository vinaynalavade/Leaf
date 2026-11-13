import Foundation

/// Value-based financial amount model stored strictly in the smallest currency unit (subunits / paise / cents / yen)
/// as a 64-bit signed integer (`Int64`) to completely eliminate floating-point arithmetic rounding errors.
///
/// For example:
/// - ₹125.50 is stored as 12,550 paise (`subunits = 12550`).
/// - $10.00 is stored as 1,000 cents (`subunits = 1000`).
/// - ¥500 is stored as 500 yen (`subunits = 500`).
public struct Amount: Hashable, Comparable, Codable, CustomStringConvertible, Sendable, AdditiveArithmetic {

    public let subunits: Int64

    public init(subunits: Int64) {
        self.subunits = subunits
    }

    public init(_ subunits: Int64) {
        self.subunits = subunits
    }

    public static let zero = Amount(subunits: 0)

    // MARK: - AdditiveArithmetic & Operators

    public static func + (lhs: Amount, rhs: Amount) -> Amount {
        Amount(subunits: lhs.subunits + rhs.subunits)
    }

    public static func - (lhs: Amount, rhs: Amount) -> Amount {
        Amount(subunits: lhs.subunits - rhs.subunits)
    }

    public static func * (lhs: Amount, rhs: Int64) -> Amount {
        Amount(subunits: lhs.subunits * rhs)
    }

    public static func * (lhs: Int64, rhs: Amount) -> Amount {
        Amount(subunits: lhs * rhs.subunits)
    }

    public static prefix func - (operand: Amount) -> Amount {
        Amount(subunits: -operand.subunits)
    }

    public static func < (lhs: Amount, rhs: Amount) -> Bool {
        lhs.subunits < rhs.subunits
    }

    // MARK: - Properties

    public var isZero: Bool { subunits == 0 }
    public var isPositive: Bool { subunits > 0 }
    public var isNegative: Bool { subunits < 0 }

    public func absolute() -> Amount {
        Amount(subunits: abs(subunits))
    }

    public var description: String {
        format(currency: .default, includeSymbol: true)
    }

    // MARK: - Formatting

    /// Formats the amount into a clean display string using the provided `Currency`.
    /// Examples:
    /// - `₹125.50`
    /// - `₹1,250.00`
    /// - `-₹50.00`
    /// - `¥500`
    public func format(currency: Currency = .default, includeSymbol: Bool = true) -> String {
        let absVal = abs(subunits)
        let mainUnit = absVal / currency.subunitFactor
        let fractional = absVal % currency.subunitFactor

        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.numberStyle = .decimal
        formatter.usesGroupingSeparator = true
        formatter.groupingSeparator = ","
        formatter.groupingSize = 3
        let formattedMain = formatter.string(from: NSNumber(value: mainUnit)) ?? "\(mainUnit)"

        let numberString: String
        if currency.decimalDigits > 0 {
            let fractionRaw = String(fractional)
            let fractionPadded = String(repeating: "0", count: max(0, currency.decimalDigits - fractionRaw.count)) + fractionRaw
            numberString = "\(formattedMain).\(fractionPadded)"
        } else {
            numberString = formattedMain
        }

        let prefix = subunits < 0 ? "-" : ""
        if includeSymbol {
            if currency.symbolBeforeAmount {
                return "\(prefix)\(currency.symbol)\(numberString)"
            } else {
                return "\(prefix)\(numberString) \(currency.symbol)"
            }
        } else {
            return "\(prefix)\(numberString)"
        }
    }

    /// Convenience alias for `format(currency:includeSymbol:)`.
    public func formatted(with currency: Currency, includeSymbol: Bool = true) -> String {
        format(currency: currency, includeSymbol: includeSymbol)
    }

    /// Convenience alias for `format(currency:includeSymbol:)`.
    public func formatted(currency: Currency = .default, includeSymbol: Bool = true) -> String {
        format(currency: currency, includeSymbol: includeSymbol)
    }

    /// Formats the amount to an unformatted decimal string for text editing inputs (e.g., "125.50", "100", or empty if zero).
    public func toInputString(currency: Currency = .default) -> String {
        if subunits == 0 { return "" }
        let absVal = abs(subunits)
        let mainUnit = absVal / currency.subunitFactor
        let fractional = absVal % currency.subunitFactor
        let prefix = subunits < 0 ? "-" : ""

        if currency.decimalDigits > 0 {
            let fractionRaw = String(fractional)
            let fractionPadded = String(repeating: "0", count: max(0, currency.decimalDigits - fractionRaw.count)) + fractionRaw
            var trimmed = fractionPadded
            while trimmed.hasSuffix("0") {
                trimmed.removeLast()
            }
            if trimmed.isEmpty {
                return "\(prefix)\(mainUnit)"
            } else {
                return "\(prefix)\(mainUnit).\(trimmed)"
            }
        } else {
            return "\(prefix)\(mainUnit)"
        }
    }

    // MARK: - Parsing & Factory Methods

    public static func fromSubunits(_ subunits: Int64) -> Amount {
        Amount(subunits: subunits)
    }

    public static func fromMainUnit(_ mainUnit: Int64, currency: Currency = .default) -> Amount {
        Amount(subunits: mainUnit * currency.subunitFactor)
    }

    /// Safely parses a user-entered string representation (e.g., "125.50", "180", "-45.00") into an `Amount`
    /// using purely integer arithmetic without intermediate floating-point types.
    public static func fromStringOrNull(_ input: String, currency: Currency = .default) -> Amount? {
        var clean = input.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: ",", with: "")
        if clean.isEmpty { return nil }

        let isNegative = clean.hasPrefix("-")
        if isNegative {
            clean.removeFirst()
        }

        let parts = clean.split(separator: ".", omittingEmptySubsequences: false)
        if parts.count > 2 { return nil }

        let mainPart = String(parts[0])
        let mainVal: Int64
        if mainPart.isEmpty {
            mainVal = 0
        } else {
            guard let parsed = Int64(mainPart) else { return nil }
            mainVal = parsed
        }

        let fractionPart = parts.count == 2 ? String(parts[1]) : ""

        if fractionPart.count > currency.decimalDigits {
            // Truncate excess decimal digits beyond currency precision
            let truncated = String(fractionPart.prefix(currency.decimalDigits))
            let padded = truncated.padding(toLength: currency.decimalDigits, withPad: "0", startingAt: 0)
            let fractionVal: Int64
            if padded.isEmpty {
                fractionVal = 0
            } else {
                guard let parsed = Int64(padded) else { return nil }
                fractionVal = parsed
            }
            let totalSubunits = (mainVal * currency.subunitFactor) + fractionVal
            return Amount(subunits: isNegative ? -totalSubunits : totalSubunits)
        }

        let padded = fractionPart.padding(toLength: currency.decimalDigits, withPad: "0", startingAt: 0)
        let fractionVal: Int64
        if padded.isEmpty {
            fractionVal = 0
        } else {
            guard let parsed = Int64(padded) else { return nil }
            fractionVal = parsed
        }

        let totalSubunits = (mainVal * currency.subunitFactor) + fractionVal
        return Amount(subunits: isNegative ? -totalSubunits : totalSubunits)
    }
}

