import Foundation
import WidgetKit

/// Codable snapshot of user's core financial state shared between the main Leaf app
/// and home screen WidgetKit extensions via App Group shared storage.
public struct WidgetFinancialSnapshot: Codable, Sendable {
    public let currentBalanceSubunits: Int64
    public let monthlyIncomeSubunits: Int64
    public let monthlyExpenseSubunits: Int64
    public let currencyCode: String
    public let budgetLimitSubunits: Int64
    public let budgetSpentSubunits: Int64
    public let budgetProgressRatio: Double
    public let lastUpdated: Date
    public let isBalanceVisible: Bool

    public init(
        currentBalanceSubunits: Int64 = 0,
        monthlyIncomeSubunits: Int64 = 0,
        monthlyExpenseSubunits: Int64 = 0,
        currencyCode: String = "USD",
        budgetLimitSubunits: Int64 = 0,
        budgetSpentSubunits: Int64 = 0,
        budgetProgressRatio: Double = 0.0,
        lastUpdated: Date = Date(),
        isBalanceVisible: Bool = true
    ) {
        self.currentBalanceSubunits = currentBalanceSubunits
        self.monthlyIncomeSubunits = monthlyIncomeSubunits
        self.monthlyExpenseSubunits = monthlyExpenseSubunits
        self.currencyCode = currencyCode
        self.budgetLimitSubunits = budgetLimitSubunits
        self.budgetSpentSubunits = budgetSpentSubunits
        self.budgetProgressRatio = budgetProgressRatio
        self.lastUpdated = lastUpdated
        self.isBalanceVisible = isBalanceVisible
    }

    public static var placeholder: WidgetFinancialSnapshot {
        WidgetFinancialSnapshot(
            currentBalanceSubunits: 0,
            monthlyIncomeSubunits: 0,
            monthlyExpenseSubunits: 0,
            currencyCode: "INR",
            budgetLimitSubunits: 0,
            budgetSpentSubunits: 0,
            budgetProgressRatio: 0.0,
            lastUpdated: Date(),
            isBalanceVisible: true
        )
    }

    public var currencySymbol: String {
        switch currencyCode.uppercased() {
        case "INR": return "₹"
        case "EUR": return "€"
        case "GBP": return "£"
        case "JPY": return "¥"
        case "CAD": return "CA$"
        case "AUD": return "A$"
        default: return "$"
        }
    }

    public var formattedBalance: String {
        if !isBalanceVisible {
            return "\(currencySymbol)••••••"
        }
        return formatAmount(subunits: currentBalanceSubunits)
    }

    public var formattedExpense: String {
        if !isBalanceVisible {
            return "\(currencySymbol)••••••"
        }
        return formatAmount(subunits: monthlyExpenseSubunits)
    }

    public var formattedIncome: String {
        if !isBalanceVisible {
            return "\(currencySymbol)••••••"
        }
        return formatAmount(subunits: monthlyIncomeSubunits)
    }

    public var formattedBudgetRemaining: String {
        if !isBalanceVisible {
            return "\(currencySymbol)••••••"
        }
        let remaining = max(0, budgetLimitSubunits - budgetSpentSubunits)
        return formatAmount(subunits: remaining)
    }

    private func formatAmount(subunits: Int64) -> String {
        let doubleVal = Double(subunits) / 100.0
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currencyCode
        formatter.currencySymbol = currencySymbol
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 0
        return formatter.string(from: NSNumber(value: doubleVal)) ?? "\(currencySymbol)\(doubleVal)"
    }
}

/// Centralized manager for synchronizing data to App Group container and triggering WidgetKit refreshes.
public final class WidgetDataManager: @unchecked Sendable {
    public static let shared = WidgetDataManager()
    public static let appGroupId = "group.com.vinaynalavade.Leaf"
    private static let storageKey = "leaf_widget_financial_snapshot"
    public static let balanceVisibilityKey = "leaf_widget_is_balance_visible"
    private static let legacyPrefKey = "pref_is_balance_visible"

    private let defaults: UserDefaults

    public init(defaults: UserDefaults? = nil) {
        if let custom = defaults {
            self.defaults = custom
        } else if let suite = UserDefaults(suiteName: WidgetDataManager.appGroupId) {
            self.defaults = suite
        } else {
            self.defaults = .standard
        }
    }

    /// Whether balances should be displayed or masked across all widgets.
    public func isBalanceVisible() -> Bool {
        if let val = defaults.object(forKey: WidgetDataManager.balanceVisibilityKey) as? Bool {
            return val
        }
        if let val = defaults.object(forKey: WidgetDataManager.legacyPrefKey) as? Bool {
            return val
        }
        if let stdVal = UserDefaults.standard.object(forKey: WidgetDataManager.legacyPrefKey) as? Bool {
            return stdVal
        }
        return true
    }

    /// Sets persistent balance visibility across App Group defaults and updates the cached snapshot.
    public func setBalanceVisible(_ isVisible: Bool) {
        defaults.set(isVisible, forKey: WidgetDataManager.balanceVisibilityKey)
        defaults.set(isVisible, forKey: WidgetDataManager.legacyPrefKey)
        UserDefaults.standard.set(isVisible, forKey: WidgetDataManager.balanceVisibilityKey)
        UserDefaults.standard.set(isVisible, forKey: WidgetDataManager.legacyPrefKey)

        let current = loadRawSnapshot() ?? .placeholder
        let updated = WidgetFinancialSnapshot(
            currentBalanceSubunits: current.currentBalanceSubunits,
            monthlyIncomeSubunits: current.monthlyIncomeSubunits,
            monthlyExpenseSubunits: current.monthlyExpenseSubunits,
            currencyCode: current.currencyCode,
            budgetLimitSubunits: current.budgetLimitSubunits,
            budgetSpentSubunits: current.budgetSpentSubunits,
            budgetProgressRatio: current.budgetProgressRatio,
            lastUpdated: Date(),
            isBalanceVisible: isVisible
        )
        if let encoded = try? JSONEncoder().encode(updated) {
            defaults.set(encoded, forKey: WidgetDataManager.storageKey)
        }
        reloadWidgets()
    }

    /// Toggles the balance visibility state between shown and masked.
    public func toggleBalanceVisibility() {
        setBalanceVisible(!isBalanceVisible())
    }

    private func loadRawSnapshot() -> WidgetFinancialSnapshot? {
        guard let data = defaults.data(forKey: WidgetDataManager.storageKey),
              let snapshot = try? JSONDecoder().decode(WidgetFinancialSnapshot.self, from: data) else {
            return nil
        }
        return snapshot
    }

    /// Persists a new snapshot and triggers an immediate reload across all active Leaf widgets.
    public func saveSnapshot(_ snapshot: WidgetFinancialSnapshot) {
        let visibility = isBalanceVisible()
        let enriched = WidgetFinancialSnapshot(
            currentBalanceSubunits: snapshot.currentBalanceSubunits,
            monthlyIncomeSubunits: snapshot.monthlyIncomeSubunits,
            monthlyExpenseSubunits: snapshot.monthlyExpenseSubunits,
            currencyCode: snapshot.currencyCode,
            budgetLimitSubunits: snapshot.budgetLimitSubunits,
            budgetSpentSubunits: snapshot.budgetSpentSubunits,
            budgetProgressRatio: snapshot.budgetProgressRatio,
            lastUpdated: snapshot.lastUpdated,
            isBalanceVisible: visibility
        )
        if let encoded = try? JSONEncoder().encode(enriched) {
            defaults.set(encoded, forKey: WidgetDataManager.storageKey)
            reloadWidgets()
        }
    }

    /// Loads the latest cached snapshot, returning placeholder data if none exists.
    public func loadSnapshot() -> WidgetFinancialSnapshot {
        let visibility = isBalanceVisible()
        guard let snapshot = loadRawSnapshot() else {
            let p = WidgetFinancialSnapshot.placeholder
            return WidgetFinancialSnapshot(
                currentBalanceSubunits: p.currentBalanceSubunits,
                monthlyIncomeSubunits: p.monthlyIncomeSubunits,
                monthlyExpenseSubunits: p.monthlyExpenseSubunits,
                currencyCode: p.currencyCode,
                budgetLimitSubunits: p.budgetLimitSubunits,
                budgetSpentSubunits: p.budgetSpentSubunits,
                budgetProgressRatio: p.budgetProgressRatio,
                lastUpdated: p.lastUpdated,
                isBalanceVisible: visibility
            )
        }
        return WidgetFinancialSnapshot(
            currentBalanceSubunits: snapshot.currentBalanceSubunits,
            monthlyIncomeSubunits: snapshot.monthlyIncomeSubunits,
            monthlyExpenseSubunits: snapshot.monthlyExpenseSubunits,
            currencyCode: snapshot.currencyCode,
            budgetLimitSubunits: snapshot.budgetLimitSubunits,
            budgetSpentSubunits: snapshot.budgetSpentSubunits,
            budgetProgressRatio: snapshot.budgetProgressRatio,
            lastUpdated: snapshot.lastUpdated,
            isBalanceVisible: visibility
        )
    }

    /// Signals WidgetKit to invalidate timelines and re-render.
    public func reloadWidgets() {
        WidgetCenter.shared.reloadAllTimelines()
    }
}
