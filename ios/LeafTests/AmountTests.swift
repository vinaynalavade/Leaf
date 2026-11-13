import XCTest
#if canImport(LeafCore)
@testable import LeafCore
#elseif canImport(Leaf)
@testable import Leaf
#endif

final class AmountTests: XCTestCase {

    func testSubunitStorageAndBasicArithmetic() {
        let a = Amount(subunits: 10050) // ₹100.50
        let b = Amount(subunits: 5025)  // ₹50.25

        let sum = a + b
        XCTAssertEqual(sum.subunits, 15075)

        let diff = a - b
        XCTAssertEqual(diff.subunits, 5025)

        let scaled = b * 2
        XCTAssertEqual(scaled.subunits, 10050)

        let negated = -a
        XCTAssertEqual(negated.subunits, -10050)
    }

    func testComparisonsAndProperties() {
        let zero = Amount.zero
        let pos = Amount(subunits: 100)
        let neg = Amount(subunits: -100)

        XCTAssertTrue(zero.isZero)
        XCTAssertFalse(pos.isZero)
        XCTAssertTrue(pos.isPositive)
        XCTAssertFalse(pos.isNegative)
        XCTAssertTrue(neg.isNegative)
        XCTAssertEqual(neg.absolute(), pos)

        XCTAssertTrue(neg < zero)
        XCTAssertTrue(zero < pos)
    }

    func testExactStringParsing() {
        // Standard INR (2 decimals)
        let amt1 = Amount.fromStringOrNull("180.50", currency: .inr)
        XCTAssertEqual(amt1?.subunits, 18050)

        let amt2 = Amount.fromStringOrNull("100", currency: .inr)
        XCTAssertEqual(amt2?.subunits, 10000)

        let amt3 = Amount.fromStringOrNull("1,250.75", currency: .inr)
        XCTAssertEqual(amt3?.subunits, 125075)

        let amt4 = Amount.fromStringOrNull("-45.20", currency: .inr)
        XCTAssertEqual(amt4?.subunits, -4520)

        // Zero-decimal JPY
        let jpyAmt = Amount.fromStringOrNull("500", currency: .jpy)
        XCTAssertEqual(jpyAmt?.subunits, 500)
        let jpyAmtWithDot = Amount.fromStringOrNull("500.50", currency: .jpy)
        XCTAssertEqual(jpyAmtWithDot?.subunits, 500)

        // Invalid inputs
        XCTAssertNil(Amount.fromStringOrNull("", currency: .inr))
        XCTAssertNil(Amount.fromStringOrNull("abc", currency: .inr))
        XCTAssertNil(Amount.fromStringOrNull("12.34.56", currency: .inr))
    }

    func testFormatting() {
        let inrAmount = Amount(subunits: 125050) // ₹1,250.50
        XCTAssertEqual(inrAmount.format(currency: .inr, includeSymbol: true), "₹1,250.50")
        XCTAssertEqual(inrAmount.format(currency: .inr, includeSymbol: false), "1,250.50")

        let jpyAmount = Amount(subunits: 500)
        XCTAssertEqual(jpyAmount.format(currency: .jpy, includeSymbol: true), "¥500")

        let negAmount = Amount(subunits: -5000)
        XCTAssertEqual(negAmount.format(currency: .inr, includeSymbol: true), "-₹50.00")
    }

    func testToInputString() {
        XCTAssertEqual(Amount(subunits: 12550).toInputString(currency: .inr), "125.5")
        XCTAssertEqual(Amount(subunits: -12550).toInputString(currency: .inr), "-125.5")
        XCTAssertEqual(Amount(subunits: 10000).toInputString(currency: .inr), "100")
        XCTAssertEqual(Amount(subunits: 0).toInputString(currency: .inr), "")
    }
}

