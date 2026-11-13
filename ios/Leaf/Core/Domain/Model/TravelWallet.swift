import Foundation

/// Represents a designated travel wallet for categorizing and monitoring expenses in a specific destination currency.
/// Travel wallets organize expenditures for trips and projects without fabricating artificial bank accounts.
public struct TravelWallet: Identifiable, Hashable, Codable, Sendable {
    public let id: Int64
    public let name: String
    public let currencyCode: String
    public let budgetAmount: Amount?
    public let note: String?
    public let colorHex: String
    public let iconName: String
    public let isArchived: Bool
    public let createdAt: Int64
    public let updatedAt: Int64

    public init(
        id: Int64 = 0,
        name: String,
        currencyCode: String,
        budgetAmount: Amount? = nil,
        note: String? = nil,
        colorHex: String = "#10B981",
        iconName: String = "airplane",
        isArchived: Bool = false,
        createdAt: Int64 = Int64(Date().timeIntervalSince1970 * 1000),
        updatedAt: Int64 = Int64(Date().timeIntervalSince1970 * 1000)
    ) {
        self.id = id
        self.name = name
        self.currencyCode = currencyCode.uppercased()
        self.budgetAmount = budgetAmount
        self.note = note
        self.colorHex = colorHex
        self.iconName = iconName
        self.isArchived = isArchived
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    public var currency: Currency {
        Currency.fromCode(currencyCode)
    }
}

/// Aggregate summary providing financial metrics for a travel wallet.
public struct TravelWalletSummary: Identifiable, Hashable, Sendable {
    public var id: Int64 { wallet.id }
    public let wallet: TravelWallet
    public let totalSpentInWalletCurrency: Amount
    public let totalSpentInPrimaryCurrency: Amount
    public let transactionCount: Int
    public let categorySpendings: [CategorySpending]

    public init(
        wallet: TravelWallet,
        totalSpentInWalletCurrency: Amount,
        totalSpentInPrimaryCurrency: Amount,
        transactionCount: Int,
        categorySpendings: [CategorySpending] = []
    ) {
        self.wallet = wallet
        self.totalSpentInWalletCurrency = totalSpentInWalletCurrency
        self.totalSpentInPrimaryCurrency = totalSpentInPrimaryCurrency
        self.transactionCount = transactionCount
        self.categorySpendings = categorySpendings
    }

    /// Progress percentage towards wallet budget, if one is configured (0.0 to 1.0+).
    public var budgetProgressRatio: Double? {
        guard let budget = wallet.budgetAmount, budget.subunits > 0 else { return nil }
        return Double(totalSpentInWalletCurrency.subunits) / Double(budget.subunits)
    }

    /// Budget progress ratio as a non-optional Double (0.0 if not configured).
    public var budgetProgress: Double {
        budgetProgressRatio ?? 0.0
    }

    /// Whether spending has exceeded the wallet's allocated budget.
    public var isOverBudget: Bool {
        guard let budget = wallet.budgetAmount, budget.subunits > 0 else { return false }
        return totalSpentInWalletCurrency.subunits > budget.subunits
    }

    /// Formatted total spent in the travel wallet's destination currency.
    public var formattedWalletSpent: String {
        totalSpentInWalletCurrency.formatted(with: wallet.currency)
    }

    /// Formatted equivalent total spent in the primary currency.
    public var formattedPrimarySpent: String {
        totalSpentInPrimaryCurrency.formatted()
    }
}

