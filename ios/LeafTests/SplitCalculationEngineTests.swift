import XCTest
#if canImport(LeafCore)
@testable import LeafCore
#elseif canImport(Leaf)
@testable import Leaf
#endif

final class SplitCalculationEngineTests: XCTestCase {

    func testEqualSplitWithDeterministicPennyReconciliation() {
        // ₹100.00 (10,000 paise) split among 3 participants
        let total = Amount(subunits: 10000)
        let participants = ["Me", "Rahul", "Priya"]

        let result = SplitCalculationEngine.calculateEqualSplit(
            totalAmount: total,
            participants: participants,
            payerName: "Me"
        )

        XCTAssertEqual(result.count, 3)

        // 10000 / 3 = 3333 with remainder 1. Participant 0 gets 3334, others 3333
        XCTAssertEqual(result[0].name, "Me")
        XCTAssertTrue(result[0].isCurrentUser)
        XCTAssertEqual(result[0].amount.subunits, 3334)

        XCTAssertEqual(result[1].name, "Rahul")
        XCTAssertFalse(result[1].isCurrentUser)
        XCTAssertEqual(result[1].amount.subunits, 3333)

        XCTAssertEqual(result[2].name, "Priya")
        XCTAssertFalse(result[2].isCurrentUser)
        XCTAssertEqual(result[2].amount.subunits, 3333)

        // Strict 0-tolerance equality check
        let sum = result.reduce(0) { $0 + $1.amount.subunits }
        XCTAssertEqual(sum, total.subunits)
    }

    func testEqualSplitWithRemainderTwo() {
        // ₹100.02 (10,002 paise) split among 4 participants
        // 10002 / 4 = 2500 remainder 2 -> First two get 2501, next two get 2500
        let total = Amount(subunits: 10002)
        let participants = ["Alice", "Bob", "Charlie", "David"]

        let result = SplitCalculationEngine.calculateEqualSplit(
            totalAmount: total,
            participants: participants,
            payerName: "Alice"
        )

        XCTAssertEqual(result.count, 4)
        XCTAssertEqual(result[0].amount.subunits, 2501)
        XCTAssertEqual(result[1].amount.subunits, 2501)
        XCTAssertEqual(result[2].amount.subunits, 2500)
        XCTAssertEqual(result[3].amount.subunits, 2500)

        let sum = result.reduce(0) { $0 + $1.amount.subunits }
        XCTAssertEqual(sum, total.subunits)
    }

    func testCustomSplitValidation() {
        let total = Amount(subunits: 10000)

        let exact = SplitCalculationEngine.validateCustomSplit(totalAmount: total, allocatedSubunits: 10000)
        XCTAssertTrue(exact.isValid)
        XCTAssertEqual(exact.remainingAmount, .zero)
        XCTAssertEqual(exact.overallocatedAmount, .zero)

        let under = SplitCalculationEngine.validateCustomSplit(totalAmount: total, allocatedSubunits: 8000)
        XCTAssertFalse(under.isValid)
        XCTAssertEqual(under.remainingAmount.subunits, 2000)
        XCTAssertEqual(under.overallocatedAmount, .zero)

        let over = SplitCalculationEngine.validateCustomSplit(totalAmount: total, allocatedSubunits: 12000)
        XCTAssertFalse(over.isValid)
        XCTAssertEqual(over.remainingAmount, .zero)
        XCTAssertEqual(over.overallocatedAmount.subunits, 2000)
    }

    func testItemizedSplitCalculation() {
        // Total bill ₹1,000.00 (100,000 paise)
        // Item 1: Pizza ₹600.00 shared by Me and Rahul (₹300 each)
        // Remainder: ₹400.00 shared equally among all 3 (Me, Rahul, Priya) -> 13334, 13333, 13333
        let totalBill = Amount(subunits: 100000)
        let participants = ["Me", "Rahul", "Priya"]

        let pizzaItem = SplitItem(
            name: "Pizza",
            amount: Amount(subunits: 60000),
            participantNames: ["Me", "Rahul"]
        )

        let result = SplitCalculationEngine.calculateItemizedSplit(
            totalBill: totalBill,
            participants: participants,
            items: [pizzaItem],
            sharedRemainingParticipants: ["Me", "Rahul", "Priya"]
        )

        XCTAssertTrue(result.isValid)
        XCTAssertFalse(result.isOverallocated)
        XCTAssertFalse(result.isUnderallocated)

        // Pizza item: Me = 30000, Rahul = 30000
        // Shared 40000: Me = 13334, Rahul = 13333, Priya = 13333
        // Total Me: 43334
        // Total Rahul: 43333
        // Total Priya: 13333
        XCTAssertEqual(result.participantShares["Me"]?.subunits, 43334)
        XCTAssertEqual(result.participantShares["Rahul"]?.subunits, 43333)
        XCTAssertEqual(result.participantShares["Priya"]?.subunits, 13333)

        let totalAllocated = result.participantShares.values.reduce(0) { $0 + $1.subunits }
        XCTAssertEqual(totalAllocated, totalBill.subunits)
    }
}

