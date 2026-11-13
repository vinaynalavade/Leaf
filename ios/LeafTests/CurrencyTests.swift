import XCTest
#if canImport(LeafCore)
@testable import LeafCore
#elseif canImport(Leaf)
@testable import Leaf
#endif

final class CurrencyTests: XCTestCase {

    func testSupportedCurrenciesCountAndCodes() {
        XCTAssertEqual(Currency.supportedCurrencies.count, 9)

        let codes = Set(Currency.supportedCurrencies.map { $0.code })
        let expected: Set<String> = ["INR", "USD", "EUR", "GBP", "AED", "SGD", "CAD", "AUD", "JPY"]
        XCTAssertEqual(codes, expected)
    }

    func testFromCodeLookup() {
        XCTAssertEqual(Currency.fromCode("USD").code, "USD")
        XCTAssertEqual(Currency.fromCode("inr").code, "INR")
        XCTAssertEqual(Currency.fromCode("JPY").code, "JPY")
        XCTAssertEqual(Currency.fromCode("UNKNOWN").code, Currency.default.code)
    }

    func testJPYZeroDecimalConvention() {
        let jpy = Currency.jpy
        XCTAssertEqual(jpy.decimalDigits, 0)
        XCTAssertEqual(jpy.subunitFactor, 1)
    }

    func testStandardCurrenciesSubunitFactor() {
        for curr in [Currency.inr, Currency.usd, Currency.eur, Currency.gbp] {
            XCTAssertEqual(curr.decimalDigits, 2)
            XCTAssertEqual(curr.subunitFactor, 100)
        }
    }

    func testPaymentMethodNormalization() {
        XCTAssertEqual(PaymentMethod.fromString("CASH"), .cash)
        XCTAssertEqual(PaymentMethod.fromString("cash"), .cash)
        XCTAssertEqual(PaymentMethod.fromString("ACCOUNT"), .account)
        XCTAssertEqual(PaymentMethod.fromString("BANK_ACCOUNT"), .account)
        XCTAssertEqual(PaymentMethod.fromString("UPI"), .account)
        XCTAssertEqual(PaymentMethod.fromString("upi"), .account)
        XCTAssertEqual(PaymentMethod.fromString("CARD"), .account)
        XCTAssertEqual(PaymentMethod.fromString("NET_BANKING"), .account)
        XCTAssertEqual(PaymentMethod.fromString("Net Banking"), .account)
        XCTAssertEqual(PaymentMethod.fromString("Bank Account"), .account)
        XCTAssertEqual(PaymentMethod.fromString("UNKNOWN"), .unknown)
    }
}

