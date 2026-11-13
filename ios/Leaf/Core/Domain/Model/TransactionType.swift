import Foundation

public enum TransactionType: String, Codable, CaseIterable, Sendable {
    case expense = "EXPENSE"
    case income = "INCOME"

    public var displayName: String {
        switch self {
        case .expense: return "Expense"
        case .income: return "Income"
        }
    }
}

