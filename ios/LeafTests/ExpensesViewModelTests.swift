import XCTest
#if canImport(LeafCore)
@testable import LeafCore
#elseif canImport(Leaf)
@testable import Leaf
#endif

final class ExpensesViewModelTests: XCTestCase {

    var container: AppContainer!

    override func setUp() async throws {
        container = AppContainer.makeInMemory()
        try await container.preferencesRepository.setCurrencyCode("USD")

        // Seed sample categories if not already present
        _ = try await container.categoryRepository.getAllCategories()
    }

    override func tearDown() async throws {
        container = nil
    }

    func testInitialLoading_ComputesCorrectMonthlySummaryAndBreakdown() async throws {
        let calendar = Calendar.current
        let now = Date()
        let year = calendar.component(.year, from: now)
        let month = calendar.component(.month, from: now)

        // Seed 3 expenses in current month
        _ = try await container.addTransactionUseCase.execute(
            amount: Amount(subunits: 5000), // $50.00
            type: .expense,
            categoryId: 1, // Food & Dining
            paymentMethod: .cash,
            note: "Groceries",
            timestamp: Int64(now.timeIntervalSince1970 * 1000)
        )

        _ = try await container.addTransactionUseCase.execute(
            amount: Amount(subunits: 3000), // $30.00
            type: .expense,
            categoryId: 1, // Food & Dining
            paymentMethod: .account,
            note: "Lunch",
            timestamp: Int64(now.timeIntervalSince1970 * 1000)
        )

        _ = try await container.addTransactionUseCase.execute(
            amount: Amount(subunits: 2000), // $20.00
            type: .expense,
            categoryId: 2, // Transportation
            paymentMethod: .cash,
            note: "Bus ticket",
            timestamp: Int64(now.timeIntervalSince1970 * 1000)
        )

        let vm = ExpensesViewModel(
            getMonthlyExpenseSummaryUseCase: container.getMonthlyExpenseSummaryUseCase,
            getCategorySpendingUseCase: container.getCategorySpendingUseCase,
            getTransactionsUseCase: container.getTransactionsUseCase,
            addTransactionUseCase: container.addTransactionUseCase,
            updateTransactionUseCase: container.updateTransactionUseCase,
            deleteTransactionUseCase: container.deleteTransactionUseCase,
            preferencesRepository: container.preferencesRepository
        )

        await vm.loadData()

        // Verify summary
        XCTAssertEqual(vm.monthlySummary.totalExpense.subunits, 10000) // $100.00
        XCTAssertEqual(vm.monthlySummary.transactionCount, 3)
        XCTAssertEqual(vm.selectedCurrency.code, "USD")

        // Verify category breakdowns: Food ($80, 80%), Transportation ($20, 20%)
        XCTAssertEqual(vm.categoryBreakdowns.count, 2)
        XCTAssertEqual(vm.categoryBreakdowns[0].category.id, 1)
        XCTAssertEqual(vm.categoryBreakdowns[0].totalAmount.subunits, 8000)
        XCTAssertEqual(vm.categoryBreakdowns[0].percentageOfTotal, 80.0, accuracy: 0.1)

        XCTAssertEqual(vm.categoryBreakdowns[1].category.id, 2)
        XCTAssertEqual(vm.categoryBreakdowns[1].totalAmount.subunits, 2000)
        XCTAssertEqual(vm.categoryBreakdowns[1].percentageOfTotal, 20.0, accuracy: 0.1)

        // Verify grouped transactions
        XCTAssertFalse(vm.groupedTransactions.isEmpty)
        XCTAssertEqual(vm.groupedTransactions[0].dateHeader, "Today")
        XCTAssertEqual(vm.groupedTransactions[0].transactions.count, 3)
    }

    func testSearchFiltering_FiltersTransactionsByNoteAndCategory() async throws {
        let now = Date()

        _ = try await container.addTransactionUseCase.execute(
            amount: Amount(subunits: 1500),
            type: .expense,
            categoryId: 1,
            paymentMethod: .cash,
            note: "Starbucks Coffee",
            timestamp: Int64(now.timeIntervalSince1970 * 1000)
        )

        _ = try await container.addTransactionUseCase.execute(
            amount: Amount(subunits: 4500),
            type: .expense,
            categoryId: 2,
            paymentMethod: .account,
            note: "Gasoline Shell",
            timestamp: Int64(now.timeIntervalSince1970 * 1000)
        )

        let vm = ExpensesViewModel(
            getMonthlyExpenseSummaryUseCase: container.getMonthlyExpenseSummaryUseCase,
            getCategorySpendingUseCase: container.getCategorySpendingUseCase,
            getTransactionsUseCase: container.getTransactionsUseCase,
            addTransactionUseCase: container.addTransactionUseCase,
            updateTransactionUseCase: container.updateTransactionUseCase,
            deleteTransactionUseCase: container.deleteTransactionUseCase,
            preferencesRepository: container.preferencesRepository
        )

        await vm.loadData()
        XCTAssertEqual(vm.filteredTransactionCount, 2)

        // Search for "Coffee"
        vm.filter.searchQuery = "Coffee"
        await vm.loadData()

        XCTAssertEqual(vm.filteredTransactionCount, 1)
        XCTAssertEqual(vm.groupedTransactions.first?.transactions.first?.note, "Starbucks Coffee")

        // Search for "Shell"
        vm.filter.searchQuery = "Shell"
        await vm.loadData()

        XCTAssertEqual(vm.filteredTransactionCount, 1)
        XCTAssertEqual(vm.groupedTransactions.first?.transactions.first?.note, "Gasoline Shell")

        // Clear search
        await vm.clearFilters()
        XCTAssertEqual(vm.filteredTransactionCount, 2)
    }

    func testCategorySelectionFilter_IsolatesSelectedCategory() async throws {
        let now = Date()

        _ = try await container.addTransactionUseCase.execute(
            amount: Amount(subunits: 2000),
            type: .expense,
            categoryId: 1, // Food
            paymentMethod: .cash,
            note: "Pizza",
            timestamp: Int64(now.timeIntervalSince1970 * 1000)
        )

        _ = try await container.addTransactionUseCase.execute(
            amount: Amount(subunits: 5000),
            type: .expense,
            categoryId: 3, // Shopping
            paymentMethod: .account,
            note: "New Shoes",
            timestamp: Int64(now.timeIntervalSince1970 * 1000)
        )

        let vm = ExpensesViewModel(
            getMonthlyExpenseSummaryUseCase: container.getMonthlyExpenseSummaryUseCase,
            getCategorySpendingUseCase: container.getCategorySpendingUseCase,
            getTransactionsUseCase: container.getTransactionsUseCase,
            addTransactionUseCase: container.addTransactionUseCase,
            updateTransactionUseCase: container.updateTransactionUseCase,
            deleteTransactionUseCase: container.deleteTransactionUseCase,
            preferencesRepository: container.preferencesRepository
        )

        await vm.loadData()
        XCTAssertEqual(vm.filteredTransactionCount, 2)

        // Select Category 1
        if let foodCat = vm.categoryBreakdowns.first(where: { $0.category.id == 1 })?.category {
            await vm.selectCategoryFilter(foodCat)
            XCTAssertEqual(vm.filteredTransactionCount, 1)
            XCTAssertEqual(vm.groupedTransactions.first?.transactions.first?.categoryId, 1)

            // Deselect Category 1 (toggle off)
            await vm.selectCategoryFilter(foodCat)
            XCTAssertEqual(vm.filteredTransactionCount, 2)
        } else {
            XCTFail("Food category not found in breakdown")
        }
    }

    func testTransactionMutation_AddEditDelete_UpdatesStateConsistently() async throws {
        let now = Date()

        let vm = ExpensesViewModel(
            getMonthlyExpenseSummaryUseCase: container.getMonthlyExpenseSummaryUseCase,
            getCategorySpendingUseCase: container.getCategorySpendingUseCase,
            getTransactionsUseCase: container.getTransactionsUseCase,
            addTransactionUseCase: container.addTransactionUseCase,
            updateTransactionUseCase: container.updateTransactionUseCase,
            deleteTransactionUseCase: container.deleteTransactionUseCase,
            preferencesRepository: container.preferencesRepository
        )

        await vm.loadData()
        XCTAssertEqual(vm.filteredTransactionCount, 0)

        // 1. Add
        try await vm.addExpense(
            amount: Amount(subunits: 4000),
            categoryId: 1,
            paymentMethod: .cash,
            note: "Initial Dinner",
            timestamp: Int64(now.timeIntervalSince1970 * 1000)
        )

        XCTAssertEqual(vm.filteredTransactionCount, 1)
        XCTAssertEqual(vm.monthlySummary.totalExpense.subunits, 4000)

        guard let tx = vm.groupedTransactions.first?.transactions.first else {
            XCTFail("Transaction was not inserted")
            return
        }

        // 2. Update
        try await vm.updateExpense(
            id: tx.id,
            amount: Amount(subunits: 6500),
            categoryId: 1,
            paymentMethod: .account,
            note: "Upgraded Dinner",
            timestamp: tx.timestamp
        )

        XCTAssertEqual(vm.filteredTransactionCount, 1)
        XCTAssertEqual(vm.monthlySummary.totalExpense.subunits, 6500)
        XCTAssertEqual(vm.groupedTransactions.first?.transactions.first?.paymentMethod, .account)
        XCTAssertEqual(vm.groupedTransactions.first?.transactions.first?.note, "Upgraded Dinner")

        // 3. Delete
        await vm.deleteExpense(id: tx.id)
        XCTAssertEqual(vm.filteredTransactionCount, 0)
        XCTAssertEqual(vm.monthlySummary.totalExpense.subunits, 0)
    }

    func testMonthNavigation_TraversesBetweenMonths() async throws {
        let vm = ExpensesViewModel(
            getMonthlyExpenseSummaryUseCase: container.getMonthlyExpenseSummaryUseCase,
            getCategorySpendingUseCase: container.getCategorySpendingUseCase,
            getTransactionsUseCase: container.getTransactionsUseCase,
            addTransactionUseCase: container.addTransactionUseCase,
            updateTransactionUseCase: container.updateTransactionUseCase,
            deleteTransactionUseCase: container.deleteTransactionUseCase,
            preferencesRepository: container.preferencesRepository
        )

        let initialMonth = vm.selectedMonth
        let initialYear = vm.selectedYear

        // Previous month
        await vm.previousMonth()
        if initialMonth == 1 {
            XCTAssertEqual(vm.selectedMonth, 12)
            XCTAssertEqual(vm.selectedYear, initialYear - 1)
        } else {
            XCTAssertEqual(vm.selectedMonth, initialMonth - 1)
            XCTAssertEqual(vm.selectedYear, initialYear)
        }

        // Next month (returns to initial)
        await vm.nextMonth()
        XCTAssertEqual(vm.selectedMonth, initialMonth)
        XCTAssertEqual(vm.selectedYear, initialYear)
    }
}

