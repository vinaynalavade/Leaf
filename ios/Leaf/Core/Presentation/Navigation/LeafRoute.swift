import Foundation

public enum LeafRoute: Hashable, Sendable {
    case addTransaction(type: TransactionType)
    case editTransaction(id: Int64)
    case splitDetail(id: Int64)
    case createSplit
    case budgetDetail(month: Int, year: Int)
    case savingsGoalDetail(id: Int64)
    case categoryManager
    case insights
    case categoryAnalytics(categoryId: Int64, startDate: Date, endDate: Date)
    case transactionDetail(id: Int64)
    case securitySettings
    case backupSettings
    case statements
    case tools
    case recurring
    case travelWallets
    case travelWalletDetail(walletId: Int64)
    case currencySettings
    case about
}

