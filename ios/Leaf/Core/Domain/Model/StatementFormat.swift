import Foundation

/// Supported export file formats for financial statements and transaction data.
public enum StatementFormat: String, CaseIterable, Identifiable, Codable, Sendable {
    case pdf = "PDF"
    case csvTransactions = "CSV_TRANSACTIONS"
    case csvCategorySummary = "CSV_CATEGORIES"
    case csvFinancialSummary = "CSV_SUMMARY"

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .pdf:
            return "PDF Statement"
        case .csvTransactions:
            return "Transactions (CSV)"
        case .csvCategorySummary:
            return "Category Summary (CSV)"
        case .csvFinancialSummary:
            return "Financial Overview (CSV)"
        }
    }

    public var subtitle: String {
        switch self {
        case .pdf:
            return "Bank-grade printable multi-page report"
        case .csvTransactions:
            return "Itemized tabular ledger for spreadsheets"
        case .csvCategorySummary:
            return "Ranked category spending breakdown"
        case .csvFinancialSummary:
            return "High-level metrics and cash flow totals"
        }
    }

    public var fileExtension: String {
        switch self {
        case .pdf: return "pdf"
        case .csvTransactions, .csvCategorySummary, .csvFinancialSummary: return "csv"
        }
    }

    public var mimeType: String {
        switch self {
        case .pdf: return "application/pdf"
        case .csvTransactions, .csvCategorySummary, .csvFinancialSummary: return "text/csv"
        }
    }

    public var systemIcon: String {
        switch self {
        case .pdf: return "doc.richtext.fill"
        case .csvTransactions: return "tablecells.badge.ellipsis"
        case .csvCategorySummary: return "chart.pie.fill"
        case .csvFinancialSummary: return "chart.bar.doc.horizontal"
        }
    }
}

