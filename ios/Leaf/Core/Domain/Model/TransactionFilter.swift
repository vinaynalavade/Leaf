import Foundation

/// Criteria used to search, filter, and sort transactions within the Expenses screen.
public struct TransactionFilter: Hashable, Sendable {
    public var searchQuery: String = ""
    public var selectedCategoryIds: Set<Int64> = []
    public var paymentMethod: PaymentMethod? = nil // nil = All
    public var minAmountSubunits: Int64? = nil
    public var maxAmountSubunits: Int64? = nil
    public var dateRange: DateRangeOption = .thisMonth
    public var customStartDate: Date? = nil
    public var customEndDate: Date? = nil

    public init(
        searchQuery: String = "",
        selectedCategoryIds: Set<Int64> = [],
        paymentMethod: PaymentMethod? = nil,
        minAmountSubunits: Int64? = nil,
        maxAmountSubunits: Int64? = nil,
        dateRange: DateRangeOption = .thisMonth,
        customStartDate: Date? = nil,
        customEndDate: Date? = nil
    ) {
        self.searchQuery = searchQuery
        self.selectedCategoryIds = selectedCategoryIds
        self.paymentMethod = paymentMethod
        self.minAmountSubunits = minAmountSubunits
        self.maxAmountSubunits = maxAmountSubunits
        self.dateRange = dateRange
        self.customStartDate = customStartDate
        self.customEndDate = customEndDate
    }

    public enum DateRangeOption: String, CaseIterable, Identifiable, Sendable {
        case thisMonth = "This Month"
        case lastMonth = "Last Month"
        case last90Days = "Last 90 Days"
        case allTime = "All Time"
        case custom = "Custom Range"

        public var id: String { rawValue }
    }

    /// Whether any non-default filter or search query is currently applied.
    public var isActive: Bool {
        !searchQuery.trimmingCharacters(in: .whitespaces).isEmpty ||
        !selectedCategoryIds.isEmpty ||
        paymentMethod != nil ||
        minAmountSubunits != nil ||
        maxAmountSubunits != nil ||
        dateRange != .thisMonth
    }

    /// Count of active filter facets (excluding the search text).
    public var activeFilterCount: Int {
        var count = 0
        if !selectedCategoryIds.isEmpty { count += 1 }
        if paymentMethod != nil { count += 1 }
        if minAmountSubunits != nil || maxAmountSubunits != nil { count += 1 }
        if dateRange != .thisMonth { count += 1 }
        return count
    }

    public mutating func clear() {
        searchQuery = ""
        selectedCategoryIds.removeAll()
        paymentMethod = nil
        minAmountSubunits = nil
        maxAmountSubunits = nil
        dateRange = .thisMonth
        customStartDate = nil
        customEndDate = nil
    }

    /// Tests whether a transaction matches the current filter settings.
    public func matches(transaction: Transaction) -> Bool {
        // 1. Text search (note, category name, payment method)
        let trimmedQuery = searchQuery.trimmingCharacters(in: .whitespaces).lowercased()
        if !trimmedQuery.isEmpty {
            let noteMatch = transaction.note?.lowercased().contains(trimmedQuery) ?? false
            let categoryMatch = transaction.category?.name.lowercased().contains(trimmedQuery) ?? false
            let paymentMatch = transaction.paymentMethod.rawValue.lowercased().contains(trimmedQuery)
            if !noteMatch && !categoryMatch && !paymentMatch {
                return false
            }
        }

        // 2. Category selection
        if !selectedCategoryIds.isEmpty && !selectedCategoryIds.contains(transaction.categoryId) {
            return false
        }

        // 3. Payment method
        if let method = paymentMethod, transaction.paymentMethod != method && transaction.paymentMethod.mappedLedger != method {
            return false
        }

        // 4. Min / Max amount
        if let min = minAmountSubunits, transaction.amount.subunits < min {
            return false
        }
        if let max = maxAmountSubunits, transaction.amount.subunits > max {
            return false
        }

        // 5. Date range
        let calendar = Calendar.current
        let txDate = Date(timeIntervalSince1970: Double(transaction.timestamp) / 1000.0)

        switch dateRange {
        case .thisMonth:
            // Handled at month-scope query level, but verify calendar bounds
            break
        case .lastMonth:
            guard let lastMonth = calendar.date(byAdding: .month, value: -1, to: Date()),
                  let start = calendar.date(from: calendar.dateComponents([.year, .month], from: lastMonth)),
                  let end = calendar.date(byAdding: DateComponents(month: 1, second: -1), to: start) else { break }
            if txDate < start || txDate > end { return false }
        case .last90Days:
            guard let ninetyDaysAgo = calendar.date(byAdding: .day, value: -90, to: Date()) else { break }
            if txDate < ninetyDaysAgo { return false }
        case .allTime:
            break
        case .custom:
            if let start = customStartDate, txDate < start { return false }
            if let end = customEndDate, txDate > end { return false }
        }

        return true
    }
}

