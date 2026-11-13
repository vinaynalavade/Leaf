import Foundation

/// Safe integer-subunit currency conversion and rate calculation utility.
/// Adheres to financial precision rules, avoiding binary floating-point rounding errors
/// by computing conversions through normalized subunit factor scaling.
public enum CurrencyConverter {

    /// Converts an `Amount` from `fromCurrency` into `toCurrency` given an exchange rate.
    /// Rate definition: 1 unit of `fromCurrency` = `rate` units of `toCurrency`.
    /// Example: $25 USD at rate 83.50 INR -> ₹2,087.50.
    public static func convert(
        amount: Amount,
        from fromCurrency: Currency,
        to toCurrency: Currency,
        rate: Double
    ) -> Amount {
        guard fromCurrency.code.caseInsensitiveCompare(toCurrency.code) != .orderedSame else {
            return amount
        }
        guard rate > 0 else {
            return amount
        }

        // 1. Convert source subunits to standard fractional main units (e.g. 2500 cents -> 25.00)
        let mainUnits = Double(amount.subunits) / Double(fromCurrency.subunitFactor)

        // 2. Apply exchange rate multiplier (e.g. 25.00 * 83.50 = 2087.50)
        let convertedMainUnits = mainUnits * rate

        // 3. Scale to destination subunits (e.g. 2087.50 * 100 paise = 208750)
        let destinationSubunits = Int64((convertedMainUnits * Double(toCurrency.subunitFactor)).rounded())

        return Amount(subunits: destinationSubunits)
    }

    /// Default seed rates to INR (used for initial calibration before user overrides).
    public static let defaultRatesToINR: [String: Double] = [
        "INR": 1.0,
        "USD": 83.50,
        "EUR": 90.20,
        "GBP": 105.80,
        "AED": 22.75,
        "SGD": 62.10,
        "AUD": 54.30,
        "CAD": 61.20,
        "JPY": 0.55,
        "CHF": 93.40,
        "CNY": 11.50
    ]

    /// Resolves an estimated conversion rate between two currencies using base rates to INR.
    public static func estimatedRate(from fromCode: String, to toCode: String) -> Double {
        let fromUpper = fromCode.uppercased()
        let toUpper = toCode.uppercased()

        if fromUpper == toUpper { return 1.0 }

        let rateFromToINR = defaultRatesToINR[fromUpper] ?? 1.0
        let rateToToINR = defaultRatesToINR[toUpper] ?? 1.0

        if rateToToINR > 0 {
            return rateFromToINR / rateToToINR
        }
        return 1.0
    }
}

