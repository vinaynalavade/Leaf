import Foundation
import SwiftUI

/// Observable coordinator managing state, filtering, month navigation, and transactions for the Expenses screen.
@Observable
public final class ExpensesViewModel: @unchecked Sendable {

    // MARK: - Dependencies
    private let getMonthlyExpenseSummaryUseCase: GetMonthlyExpenseSummaryUseCase
    private let getCategorySpendingUseCase: GetCategorySpendingUseCase
    private let getTransactionsUseCase: GetTransactionsUseCase
    private let addTransactionUseCase: AddTransactionUseCase
    private let updateTransactionUseCase: UpdateTransactionUseCase
    private let deleteTransactionUseCase: DeleteTransactionUseCase
    private let preferencesRepository: UserPreferencesRepositoryProtocol

    // MARK: - Navigation & Period State
    public var selectedYear: Int
    public var selectedMonth: Int // 1...12

    // MARK: - Presentation State
    public var monthlySummary: MonthlyExpenseSummary = .empty
    public var categoryBreakdowns: [CategorySpending] = []
    public var groupedTransactions: [DateGroupedTransactions] = []
    public var totalFilteredExpense: Amount = Amount(subunits: 0)
    public var filteredTransactionCount: Int = 0

    public var selectedCurrency: Currency = .default
    public var isLoading: Bool = false
    public var errorMessage: String? = nil

    // MARK: - Search & Filter State
    public var filter: TransactionFilter = TransactionFilter()
    public var selectedCategoryForFilter: Category? = nil
    public var isSearchActive: Bool = false
    public var isFilterSheetPresented: Bool = false

    // MARK: - Modal Sheets & Actions
    public var isAddExpenseSheetPresented: Bool = false
    public var transactionToEdit: Transaction? = nil
    public var transactionToDelete: Transaction? = nil

    public init(
        getMonthlyExpenseSummaryUseCase: GetMonthlyExpenseSummaryUseCase,
        getCategorySpendingUseCase: GetCategorySpendingUseCase,
        getTransactionsUseCase: GetTransactionsUseCase,
        addTransactionUseCase: AddTransactionUseCase,
        updateTransactionUseCase: UpdateTransactionUseCase,
        deleteTransactionUseCase: DeleteTransactionUseCase,
        preferencesRepository: UserPreferencesRepositoryProtocol
    ) {
        let calendar = Calendar.current
        let now = Date()
        self.selectedYear = calendar.component(.year, from: now)
        self.selectedMonth = calendar.component(.month, from: now)

        self.getMonthlyExpenseSummaryUseCase = getMonthlyExpenseSummaryUseCase
        self.getCategorySpendingUseCase = getCategorySpendingUseCase
        self.getTransactionsUseCase = getTransactionsUseCase
        self.addTransactionUseCase = addTransactionUseCase
        self.updateTransactionUseCase = updateTransactionUseCase
        self.deleteTransactionUseCase = deleteTransactionUseCase
        self.preferencesRepository = preferencesRepository
    }

    // MARK: - Month Navigation

    public func previousMonth() async {
        if selectedMonth == 1 {
            selectedMonth = 12
            selectedYear -= 1
        } else {
            selectedMonth -= 1
        }
        await loadData()
    }

    public func nextMonth() async {
        if selectedMonth == 12 {
            selectedMonth = 1
            selectedYear += 1
        } else {
            selectedMonth += 1
        }
        await loadData()
    }

    public var formattedPeriod: String {
        var components = DateComponents()
        components.year = selectedYear
        components.month = selectedMonth
        let calendar = Calendar.current
        if let date = calendar.date(from: components) {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMMM yyyy"
            return formatter.string(from: date)
        }
        return "\(selectedMonth)/\(selectedYear)"
    }

    // MARK: - Data Loading & Filtering

    @MainActor
    public func loadData() async {
        isLoading = true
        errorMessage = nil

        do {
            // 1. Fetch user preferences
            let prefs = try await preferencesRepository.getUserPreferences()
            self.selectedCurrency = Currency.fromCode(prefs.currencyCode)

            // 2. Fetch monthly summary for selected (year, month)
            self.monthlySummary = try await getMonthlyExpenseSummaryUseCase.execute(
                year: selectedYear,
                month: selectedMonth
            )

            // 3. Compute epoch window for the month (or custom filter date range)
            let (startEpoch, endEpoch) = computeQueryEpochBounds()

            // 4. Fetch transactions for period
            let periodTransactions = try await getTransactionsUseCase.execute(
                type: .expense,
                startEpoch: startEpoch,
                endEpoch: endEpoch,
                excludeInternalTransfers: true
            )

            // 5. Compute category breakdown across all expenses in this period
            self.categoryBreakdowns = getCategorySpendingUseCase.computeBreakdown(from: periodTransactions)

            // 6. Apply search, category facet, and filters to transactions
            let filtered = periodTransactions.filter { tx in
                // Quick category filter from breakdown section
                if let selectedCat = selectedCategoryForFilter, tx.categoryId != selectedCat.id {
                    return false
                }
                return filter.matches(transaction: tx)
            }

            self.filteredTransactionCount = filtered.count
            let totalSubunits = filtered.reduce(Int64(0)) { $0 + $1.amount.subunits }
            self.totalFilteredExpense = Amount(subunits: totalSubunits)

            // 7. Group filtered transactions by date
            self.groupedTransactions = groupTransactionsByDate(filtered)

        } catch {
            self.errorMessage = "Failed to load expenses: \(error.localizedDescription)"
        }

        isLoading = false
    }

    // MARK: - Filter Operations

    @MainActor
    public func selectCategoryFilter(_ category: Category?) async {
        if selectedCategoryForFilter?.id == category?.id {
            selectedCategoryForFilter = nil
        } else {
            selectedCategoryForFilter = category
        }
        await loadData()
    }

    @MainActor
    public func applyFilter(_ newFilter: TransactionFilter) async {
        self.filter = newFilter
        await loadData()
    }

    @MainActor
    public func clearFilters() async {
        self.filter.clear()
        self.selectedCategoryForFilter = nil
        self.isSearchActive = false
        await loadData()
    }

    // MARK: - Transaction Mutations

    @MainActor
    public func addExpense(
        amount: Amount,
        categoryId: Int64,
        paymentMethod: PaymentMethod,
        note: String?,
        timestamp: Int64,
        receiptImagePath: String? = nil,
        originalAmount: Amount? = nil,
        currencyCode: String? = nil,
        exchangeRate: Double = 1.0,
        travelWalletId: Int64? = nil
    ) async throws {
        let isPrimary = (currencyCode == nil || currencyCode?.uppercased() == selectedCurrency.code.uppercased())
        _ = try await addTransactionUseCase.execute(
            amount: amount,
            type: .expense,
            categoryId: categoryId,
            paymentMethod: paymentMethod,
            note: note,
            timestamp: timestamp,
            receiptImagePath: receiptImagePath,
            originalAmount: originalAmount ?? amount,
            currencyCode: currencyCode ?? selectedCurrency.code,
            exchangeRate: exchangeRate,
            exchangeRateDate: timestamp,
            exchangeRateSource: isPrimary ? "PRIMARY" : "MANUAL",
            travelWalletId: travelWalletId
        )
        await loadData()
    }

    @MainActor
    public func updateExpense(
        id: Int64,
        amount: Amount,
        categoryId: Int64,
        paymentMethod: PaymentMethod,
        note: String?,
        timestamp: Int64,
        receiptImagePath: String? = nil,
        originalAmount: Amount? = nil,
        currencyCode: String? = nil,
        exchangeRate: Double? = nil,
        travelWalletId: Int64? = nil
    ) async throws {
        let isPrimary = (currencyCode == nil || currencyCode?.uppercased() == selectedCurrency.code.uppercased())
        try await updateTransactionUseCase.execute(
            id: id,
            amount: amount,
            type: .expense,
            categoryId: categoryId,
            paymentMethod: paymentMethod,
            note: note,
            timestamp: timestamp,
            receiptImagePath: receiptImagePath,
            originalAmount: originalAmount ?? amount,
            currencyCode: currencyCode ?? selectedCurrency.code,
            exchangeRate: exchangeRate,
            exchangeRateDate: timestamp,
            exchangeRateSource: isPrimary ? "PRIMARY" : "MANUAL",
            travelWalletId: travelWalletId
        )
        await loadData()
    }

    @MainActor
    public func deleteExpense(id: Int64) async {
        do {
            try await deleteTransactionUseCase.execute(id: id)
            self.transactionToDelete = nil
            await loadData()
        } catch {
            self.errorMessage = "Failed to delete expense: \(error.localizedDescription)"
        }
    }

    // MARK: - Helpers

    private func computeQueryEpochBounds() -> (Int64, Int64) {
        let calendar = Calendar.current

        switch filter.dateRange {
        case .thisMonth:
            var components = DateComponents()
            components.year = selectedYear
            components.month = selectedMonth
            components.day = 1
            components.hour = 0
            components.minute = 0
            components.second = 0

            guard let startOfMonth = calendar.date(from: components),
                  let endOfMonth = calendar.date(byAdding: DateComponents(month: 1, second: -1), to: startOfMonth) else {
                return (0, Int64.max)
            }
            return (Int64(startOfMonth.timeIntervalSince1970 * 1000), Int64(endOfMonth.timeIntervalSince1970 * 1000))

        case .lastMonth:
            guard let lastMonth = calendar.date(byAdding: .month, value: -1, to: Date()),
                  let start = calendar.date(from: calendar.dateComponents([.year, .month], from: lastMonth)),
                  let end = calendar.date(byAdding: DateComponents(month: 1, second: -1), to: start) else {
                return (0, Int64.max)
            }
            return (Int64(start.timeIntervalSince1970 * 1000), Int64(end.timeIntervalSince1970 * 1000))

        case .last90Days:
            guard let ninetyDaysAgo = calendar.date(byAdding: .day, value: -90, to: Date()) else {
                return (0, Int64.max)
            }
            return (Int64(ninetyDaysAgo.timeIntervalSince1970 * 1000), Int64(Date().timeIntervalSince1970 * 1000))

        case .allTime:
            return (0, Int64.max)

        case .custom:
            let start = filter.customStartDate.map { Int64($0.timeIntervalSince1970 * 1000) } ?? 0
            let end = filter.customEndDate.map { Int64($0.timeIntervalSince1970 * 1000) } ?? Int64.max
            return (start, end)
        }
    }

    private func groupTransactionsByDate(_ transactions: [Transaction]) -> [DateGroupedTransactions] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!

        // Group into dictionary keyed by start-of-day
        var groups: [Date: [Transaction]] = [:]
        for tx in transactions {
            let txDate = Date(timeIntervalSince1970: Double(tx.timestamp) / 1000.0)
            let startOfDay = calendar.startOfDay(for: txDate)
            groups[startOfDay, default: []].append(tx)
        }

        // Convert to sorted DateGroupedTransactions array
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEEE, d MMMM"

        return groups.keys.sorted(by: >).map { date in
            let txs = groups[date]!.sorted { $0.timestamp > $1.timestamp }
            let totalSubunits = txs.reduce(Int64(0)) { $0 + $1.amount.subunits }

            let headerTitle: String
            if date == today {
                headerTitle = "Today"
            } else if date == yesterday {
                headerTitle = "Yesterday"
            } else {
                headerTitle = dateFormatter.string(from: date)
            }

            return DateGroupedTransactions(
                dateHeader: headerTitle,
                date: date,
                dayTotal: Amount(subunits: totalSubunits),
                transactions: txs
            )
        }
    }
}

/// Represents an aggregated daily section of transactions.
public struct DateGroupedTransactions: Identifiable, Sendable {
    public var id: String { dateHeader }
    public let dateHeader: String
    public let date: Date
    public let dayTotal: Amount
    public let transactions: [Transaction]

    public init(
        dateHeader: String,
        date: Date,
        dayTotal: Amount,
        transactions: [Transaction]
    ) {
        self.dateHeader = dateHeader
        self.date = date
        self.dayTotal = dayTotal
        self.transactions = transactions
    }
}

