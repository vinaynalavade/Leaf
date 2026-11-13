import XCTest
#if canImport(LeafCore)
@testable import LeafCore
#elseif canImport(Leaf)
@testable import Leaf
#endif

final class SplitViewModelTests: XCTestCase {

    var container: AppContainer!

    override func setUp() async throws {
        container = AppContainer.makeInMemory()
        try await container.preferencesRepository.setCurrencyCode("INR")
        _ = try await container.categoryRepository.getAllCategories()
    }

    override func tearDown() async throws {
        container = nil
    }

    // MARK: - 1. Split Calculation Engine Tests

    func testEqualSplitCalculation_ReconcilesPenniesDeterministically() {
        // ₹100.00 (10000 subunits) among 3 participants
        let shares = SplitCalculationEngine.calculateEqualSplit(
            totalAmount: Amount(subunits: 10000),
            participants: ["Me", "Alice", "Bob"],
            payerName: "Me"
        )

        XCTAssertEqual(shares.count, 3)
        // 10000 / 3 = 3333 with remainder 1 -> first gets 3334, others 3333
        XCTAssertEqual(shares[0].amount.subunits, 3334)
        XCTAssertEqual(shares[1].amount.subunits, 3333)
        XCTAssertEqual(shares[2].amount.subunits, 3333)

        let totalAllocated = shares.reduce(Int64(0)) { $0 + $1.amount.subunits }
        XCTAssertEqual(totalAllocated, 10000)
        XCTAssertTrue(shares[0].isCurrentUser)
        XCTAssertFalse(shares[1].isCurrentUser)
    }

    func testPercentageSplitCalculation_ReconcilesToExactTotal() {
        // ₹150.00 (15000 subunits) with 50%, 25%, 25%
        let shares = SplitCalculationEngine.calculatePercentageSplit(
            totalAmount: Amount(subunits: 15000),
            participants: [("Me", 50.0), ("Alice", 25.0), ("Bob", 25.0)],
            payerName: "Me"
        )

        XCTAssertEqual(shares.count, 3)
        XCTAssertEqual(shares[0].amount.subunits, 7500)
        XCTAssertEqual(shares[1].amount.subunits, 3750)
        XCTAssertEqual(shares[2].amount.subunits, 3750)

        let totalAllocated = shares.reduce(Int64(0)) { $0 + $1.amount.subunits }
        XCTAssertEqual(totalAllocated, 15000)
    }

    // MARK: - 2. Net Balance Engine Tests

    func testNetBalanceEngine_CalculatesDirectAndReverseDebts() {
        let p1 = [
            SplitParticipant(id: 1, splitExpenseId: 1, name: "Me", isCurrentUser: true, amount: Amount(subunits: 5000)),
            SplitParticipant(id: 2, splitExpenseId: 1, name: "Alice", isCurrentUser: false, amount: Amount(subunits: 5000))
        ]

        // Split 1: Total ₹100, Paid by "Me". Alice owes Me ₹50.
        let split1 = SplitExpense(
            id: 1,
            title: "Lunch",
            totalAmount: Amount(subunits: 10000),
            categoryId: 1,
            paidBy: "Me",
            participants: p1
        )

        let summary1 = NetBalanceEngine.calculateNetBalances(expenses: [split1])
        XCTAssertEqual(summary1.netOwedToCurrentUser.subunits, 5000) // Alice owes me ₹50
        XCTAssertEqual(summary1.netCurrentUserOwes.subunits, 0)
        XCTAssertEqual(summary1.activeSplitsCount, 1)

        // Split 2: Total ₹60, Paid by "Alice". Me owes Alice ₹30.
        let p2 = [
            SplitParticipant(id: 3, splitExpenseId: 2, name: "Me", isCurrentUser: true, amount: Amount(subunits: 3000)),
            SplitParticipant(id: 4, splitExpenseId: 2, name: "Alice", isCurrentUser: false, amount: Amount(subunits: 3000))
        ]
        let split2 = SplitExpense(
            id: 2,
            title: "Coffee",
            totalAmount: Amount(subunits: 6000),
            categoryId: 1,
            paidBy: "Alice",
            participants: p2
        )

        // Net balance combined: Alice owes Me ₹50 - ₹30 = ₹20 net!
        let summary2 = NetBalanceEngine.calculateNetBalances(expenses: [split1, split2])
        XCTAssertEqual(summary2.netOwedToCurrentUser.subunits, 2000)
        XCTAssertEqual(summary2.netCurrentUserOwes.subunits, 0)
    }

    // MARK: - 3. End-to-End Creation and Settlement Flow

    func testSplitCreationAndSettlement_IntegratesWithLedger() async throws {
        let shares = SplitCalculationEngine.calculateEqualSplit(
            totalAmount: Amount(subunits: 20000), // ₹200.00
            participants: ["Me", "John"],
            payerName: "Me"
        )

        // 1. Create Split with addToTransactions = true
        let splitId = try await container.createSplitExpenseUseCase.execute(
            title: "Weekend Dinner",
            totalAmount: Amount(subunits: 20000),
            categoryId: 1,
            paidBy: "Me",
            splitMethod: "EQUAL",
            paymentMethod: .cash,
            addToTransactions: true,
            participants: shares
        )

        XCTAssertGreaterThan(splitId, 0)

        // Verify split inserted
        let fetched = try await container.splitRepository.getSplitExpense(id: splitId)
        XCTAssertNotNil(fetched)
        XCTAssertEqual(fetched?.participants.count, 2)
        XCTAssertNotNil(fetched?.expenseTransactionId) // Ledger integration verified

        // 2. Settle John's share
        guard let john = fetched?.participants.first(where: { $0.name == "John" }) else {
            XCTFail("John participant not found")
            return
        }

        try await container.settleParticipantUseCase.execute(
            participant: john,
            createOffsetTransaction: true
        )

        // Verify John is now settled
        let fetchedAfterSettle = try await container.splitRepository.getSplitExpense(id: splitId)
        let updatedJohn = fetchedAfterSettle?.participants.first(where: { $0.id == john.id })
        XCTAssertEqual(updatedJohn?.settlementStatus, .settled)
        XCTAssertNotNil(updatedJohn?.settlementTransactionId)

        // 3. Unsettle John's share
        try await container.settleParticipantUseCase.unsettle(participantId: john.id)

        let fetchedAfterUnsettle = try await container.splitRepository.getSplitExpense(id: splitId)
        let revertedJohn = fetchedAfterUnsettle?.participants.first(where: { $0.id == john.id })
        XCTAssertEqual(revertedJohn?.settlementStatus, .pending)
        XCTAssertNil(revertedJohn?.settlementTransactionId)

        // 4. Delete Split
        try await container.deleteSplitExpenseUseCase.execute(id: splitId)
        let afterDelete = try await container.splitRepository.getSplitExpense(id: splitId)
        XCTAssertNil(afterDelete)
    }

    // MARK: - 4. Partial Payments & Payment History Tests

    func testPartialSettlements_RecalculatesStatusAndSupportsReversal() async throws {
        // Bill of ₹100 among Me and Alice (₹50 each)
        let shares = SplitCalculationEngine.calculateEqualSplit(
            totalAmount: Amount(subunits: 10000),
            participants: ["Me", "Alice"],
            payerName: "Me"
        )

        let splitId = try await container.createSplitExpenseUseCase.execute(
            title: "Movie Night",
            totalAmount: Amount(subunits: 10000),
            categoryId: 1,
            paidBy: "Me",
            splitMethod: "EQUAL",
            paymentMethod: .cash,
            addToTransactions: true,
            participants: shares
        )

        var fetched = try await container.splitRepository.getSplitExpense(id: splitId)
        var alice = fetched!.participants.first { $0.name == "Alice" }!
        XCTAssertEqual(alice.settlementStatus, .pending)
        XCTAssertEqual(alice.remainingAmount.subunits, 5000)
        XCTAssertEqual(alice.paidAmount.subunits, 0)

        // 1. Partial Payment: Alice pays ₹20 (2000 subunits)
        let pay1 = try await container.recordParticipantPaymentUseCase.execute(
            splitExpenseId: splitId,
            participant: alice,
            amount: Amount(subunits: 2000),
            paymentMethod: .account,
            note: "First installment",
            createOffsetTransaction: true
        )

        XCTAssertNotNil(pay1.transactionId) // Ledger income transaction created

        fetched = try await container.splitRepository.getSplitExpense(id: splitId)
        alice = fetched!.participants.first { $0.name == "Alice" }!
        XCTAssertEqual(alice.settlementStatus, .partiallySettled)
        XCTAssertEqual(alice.paidAmount.subunits, 2000)
        XCTAssertEqual(alice.remainingAmount.subunits, 3000) // ₹30 left

        // Verify NetBalanceEngine reflects ₹30 remaining debt
        let summaryPartial = NetBalanceEngine.calculateNetBalances(expenses: [fetched!])
        XCTAssertEqual(summaryPartial.netOwedToCurrentUser.subunits, 3000)

        // 2. Overpayment attempt: Alice tries to pay ₹40 (exceeds ₹30) -> Must fail
        do {
            _ = try await container.recordParticipantPaymentUseCase.execute(
                splitExpenseId: splitId,
                participant: alice,
                amount: Amount(subunits: 4000)
            )
            XCTFail("Should have thrown overpayment error")
        } catch {
            // Expected error
        }

        // 3. Second Partial Payment: Alice pays remaining ₹30 (3000 subunits)
        let pay2 = try await container.recordParticipantPaymentUseCase.execute(
            splitExpenseId: splitId,
            participant: alice,
            amount: Amount(subunits: 3000),
            paymentMethod: .cash,
            note: "Final payment",
            createOffsetTransaction: true
        )

        fetched = try await container.splitRepository.getSplitExpense(id: splitId)
        alice = fetched!.participants.first { $0.name == "Alice" }!
        XCTAssertEqual(alice.settlementStatus, .settled)
        XCTAssertEqual(alice.paidAmount.subunits, 5000)
        XCTAssertEqual(alice.remainingAmount.subunits, 0)
        XCTAssertEqual(alice.payments.count, 2)

        // Net balance: all settled
        let summarySettled = NetBalanceEngine.calculateNetBalances(expenses: [fetched!])
        XCTAssertEqual(summarySettled.netOwedToCurrentUser.subunits, 0)

        // 4. Reverse pay1 (₹20): Only pay1 is removed; pay2 (₹30) remains
        try await container.reverseParticipantPaymentUseCase.execute(paymentId: pay1.id)

        fetched = try await container.splitRepository.getSplitExpense(id: splitId)
        alice = fetched!.participants.first { $0.name == "Alice" }!
        XCTAssertEqual(alice.settlementStatus, .partiallySettled)
        XCTAssertEqual(alice.paidAmount.subunits, 3000)
        XCTAssertEqual(alice.remainingAmount.subunits, 2000)
        XCTAssertEqual(alice.payments.count, 1)

        // Clean up
        try await container.deleteSplitExpenseUseCase.execute(id: splitId)
    }

    // MARK: - 5. Direction-Aware Settlement Accounting Tests

    func testScenarioA_CurrentUserPaidBill_IncomeRecordedOnParticipantPayment_NoExtraExpense() async throws {
        // Total bill: ₹3,000.
        // Current user paid: ₹3,000.
        // Shares: Me: ₹1,000, Alice: ₹1,000, Bob: ₹1,000.
        let shares = SplitCalculationEngine.calculateEqualSplit(
            totalAmount: Amount(subunits: 300000),
            participants: ["Me", "Alice", "Bob"],
            payerName: "Me"
        )

        let splitId = try await container.createSplitExpenseUseCase.execute(
            title: "Dinner Party",
            totalAmount: Amount(subunits: 300000),
            categoryId: 1,
            paidBy: "Me",
            splitMethod: "EQUAL",
            paymentMethod: .cash,
            addToTransactions: true,
            participants: shares
        )

        // Verify upfront ₹3,000 EXPENSE was recorded in personal ledger
        let fetchedSplit = try await container.splitRepository.getSplitExpense(id: splitId)
        XCTAssertNotNil(fetchedSplit?.expenseTransactionId)
        guard let expenseTxId = fetchedSplit?.expenseTransactionId else { return }

        let upfrontTx = try await container.transactionRepository.getTransaction(id: expenseTxId)
        XCTAssertEqual(upfrontTx?.type, .expense)
        XCTAssertEqual(upfrontTx?.amount.subunits, 300000)

        let alice = fetchedSplit!.participants.first { $0.name == "Alice" }!

        // 1. Alice pays ₹500 partial payment -> Must record ₹500 as INCOME
        let pay1 = try await container.recordParticipantPaymentUseCase.execute(
            splitExpenseId: splitId,
            participant: alice,
            amount: Amount(subunits: 50000),
            paymentMethod: .account,
            createOffsetTransaction: true
        )

        XCTAssertNotNil(pay1.transactionId)
        let tx1 = try await container.transactionRepository.getTransaction(id: pay1.transactionId!)
        XCTAssertEqual(tx1?.type, .income)
        XCTAssertEqual(tx1?.amount.subunits, 50000)

        // 2. Alice pays remaining ₹500 -> Must record another ₹500 as INCOME
        let refetchedAlice = (try await container.splitRepository.getSplitExpense(id: splitId))!.participants.first { $0.name == "Alice" }!
        let pay2 = try await container.recordParticipantPaymentUseCase.execute(
            splitExpenseId: splitId,
            participant: refetchedAlice,
            amount: Amount(subunits: 50000),
            paymentMethod: .account,
            createOffsetTransaction: true
        )

        XCTAssertNotNil(pay2.transactionId)
        let tx2 = try await container.transactionRepository.getTransaction(id: pay2.transactionId!)
        XCTAssertEqual(tx2?.type, .income)
        XCTAssertEqual(tx2?.amount.subunits, 50000)

        // 3. Reversing pay1 removes the ₹500 income transaction
        try await container.reverseParticipantPaymentUseCase.execute(paymentId: pay1.id)
        let revertedTx = try await container.transactionRepository.getTransaction(id: pay1.transactionId!)
        XCTAssertNil(revertedTx)

        // Pay2 income transaction remains preserved
        let remainingTx2 = try await container.transactionRepository.getTransaction(id: pay2.transactionId!)
        XCTAssertNotNil(remainingTx2)

        // Clean up
        try await container.deleteSplitExpenseUseCase.execute(id: splitId)
    }

    func testScenarioB_AnotherParticipantPaidBill_ExpenseRecordedOnUserPayment_NoUpfrontBillExpense() async throws {
        // Total bill: ₹3,000.
        // Alice paid: ₹3,000.
        // Shares: Me: ₹1,000, Alice: ₹1,000, Bob: ₹1,000.
        let shares = SplitCalculationEngine.calculateEqualSplit(
            totalAmount: Amount(subunits: 300000),
            participants: ["Me", "Alice", "Bob"],
            payerName: "Alice"
        )

        let initialTransactions = try await container.transactionRepository.getAllTransactions()
        let initialTxCount = initialTransactions.count

        // 1. Create split with Alice as payer and addToTransactions = true
        let splitId = try await container.createSplitExpenseUseCase.execute(
            title: "Alice Hosted Dinner",
            totalAmount: Amount(subunits: 300000),
            categoryId: 1,
            paidBy: "Alice",
            splitMethod: "EQUAL",
            paymentMethod: .cash,
            addToTransactions: true,
            participants: shares
        )

        // Verify: ZERO upfront expense recorded for current user upon split creation
        let fetchedSplit = try await container.splitRepository.getSplitExpense(id: splitId)
        XCTAssertNil(fetchedSplit?.expenseTransactionId)

        let txsAfterCreation = try await container.transactionRepository.getAllTransactions()
        XCTAssertEqual(txsAfterCreation.count, initialTxCount, "No upfront expense transaction should be recorded when someone else paid")

        let me = fetchedSplit!.participants.first { $0.isCurrentUser }!
        XCTAssertEqual(me.amount.subunits, 100000)
        XCTAssertEqual(me.remainingAmount.subunits, 100000)

        // 2. Current user pays ₹500 towards their share -> Must record ₹500 as EXPENSE in personal ledger
        let pay1 = try await container.recordParticipantPaymentUseCase.execute(
            splitExpenseId: splitId,
            participant: me,
            amount: Amount(subunits: 50000),
            paymentMethod: .account,
            note: "Half share to Alice",
            createOffsetTransaction: true
        )

        XCTAssertNotNil(pay1.transactionId)
        let tx1 = try await container.transactionRepository.getTransaction(id: pay1.transactionId!)
        XCTAssertEqual(tx1?.type, .expense, "Settlement payment made by current user must be recorded as EXPENSE")
        XCTAssertEqual(tx1?.amount.subunits, 50000)

        // 3. Current user pays remaining ₹500 -> Must record another ₹500 as EXPENSE
        let refetchedMe = (try await container.splitRepository.getSplitExpense(id: splitId))!.participants.first { $0.isCurrentUser }!
        let pay2 = try await container.recordParticipantPaymentUseCase.execute(
            splitExpenseId: splitId,
            participant: refetchedMe,
            amount: Amount(subunits: 50000),
            paymentMethod: .cash,
            note: "Second half to Alice",
            createOffsetTransaction: true
        )

        XCTAssertNotNil(pay2.transactionId)
        let tx2 = try await container.transactionRepository.getTransaction(id: pay2.transactionId!)
        XCTAssertEqual(tx2?.type, .expense, "Second settlement payment by current user must also be an EXPENSE")
        XCTAssertEqual(tx2?.amount.subunits, 50000)

        // 4. Reverse pay1: EXPENSE transaction tx1 must be removed
        try await container.reverseParticipantPaymentUseCase.execute(paymentId: pay1.id)
        let deletedTx1 = try await container.transactionRepository.getTransaction(id: pay1.transactionId!)
        XCTAssertNil(deletedTx1, "Reversing settlement payment must remove the EXPENSE transaction")

        // Pay2 expense transaction tx2 remains preserved
        let survivingTx2 = try await container.transactionRepository.getTransaction(id: pay2.transactionId!)
        XCTAssertNotNil(survivingTx2)

        // Clean up
        try await container.deleteSplitExpenseUseCase.execute(id: splitId)
    }

    func testScenarioC_SettlementBetweenExternalParticipants_ZeroLedgerTransactions() async throws {
        // Alice paid ₹3,000. Bob owes ₹1,000. Current user owes ₹1,000.
        let shares = SplitCalculationEngine.calculateEqualSplit(
            totalAmount: Amount(subunits: 300000),
            participants: ["Me", "Alice", "Bob"],
            payerName: "Alice"
        )

        let splitId = try await container.createSplitExpenseUseCase.execute(
            title: "Team Outing",
            totalAmount: Amount(subunits: 300000),
            categoryId: 1,
            paidBy: "Alice",
            splitMethod: "EQUAL",
            paymentMethod: .cash,
            addToTransactions: true,
            participants: shares
        )

        let initialTxCount = (try await container.transactionRepository.getAllTransactions()).count

        let fetchedSplit = try await container.splitRepository.getSplitExpense(id: splitId)
        let bob = fetchedSplit!.participants.first { $0.name == "Bob" }!

        // Bob pays ₹1,000 to Alice
        let payBob = try await container.recordParticipantPaymentUseCase.execute(
            splitExpenseId: splitId,
            participant: bob,
            amount: Amount(subunits: 100000),
            paymentMethod: .cash,
            createOffsetTransaction: true
        )

        // Verify: ZERO transactions created in current user's personal ledger
        XCTAssertNil(payBob.transactionId, "Third-party settlement must not link any personal ledger transaction")
        let finalTxCount = (try await container.transactionRepository.getAllTransactions()).count
        XCTAssertEqual(finalTxCount, initialTxCount, "Personal ledger must not be affected by external participant settlements")

        // Split status should still be properly updated
        let refetched = try await container.splitRepository.getSplitExpense(id: splitId)
        let updatedBob = refetched!.participants.first { $0.name == "Bob" }!
        XCTAssertEqual(updatedBob.settlementStatus, .settled)
        XCTAssertEqual(updatedBob.remainingAmount.subunits, 0)

        // Clean up
        try await container.deleteSplitExpenseUseCase.execute(id: splitId)
    }
}

