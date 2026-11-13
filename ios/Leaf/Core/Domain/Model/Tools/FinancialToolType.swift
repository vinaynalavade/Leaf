import Foundation
import SwiftUI

/// Defines the category grouping for the Financial Tools landing hub.
public enum FinancialToolCategory: String, CaseIterable, Identifiable, Sendable {
    case all = "ALL"
    case loans = "LOANS"
    case investments = "INVESTMENTS"
    case commerce = "COMMERCE"

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .all: return "All Tools"
        case .loans: return "Loans & Credit"
        case .investments: return "Wealth & Savings"
        case .commerce: return "Tax & Retail"
        }
    }
}

/// Enumerates the six core financial calculators in the Leaf Tools suite.
public enum FinancialToolType: String, CaseIterable, Identifiable, Sendable {
    case emi = "EMI"
    case sip = "SIP"
    case fd = "FD"
    case rd = "RD"
    case discount = "DISCOUNT"
    case gst = "GST"

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .emi: return "Loan / EMI Calculator"
        case .sip: return "SIP Calculator"
        case .fd: return "Fixed Deposit (FD)"
        case .rd: return "Recurring Deposit (RD)"
        case .discount: return "Discount Calculator"
        case .gst: return "GST Calculator"
        }
    }

    public var shortTitle: String {
        switch self {
        case .emi: return "EMI"
        case .sip: return "SIP"
        case .fd: return "Fixed Deposit"
        case .rd: return "Recurring Deposit"
        case .discount: return "Discount"
        case .gst: return "GST"
        }
    }

    public var subtitle: String {
        switch self {
        case .emi: return "Monthly loan instalments & interest schedule"
        case .sip: return "Systematic investment returns with step-up"
        case .fd: return "Term deposit interest with flexible compounding"
        case .rd: return "Monthly savings tranches & maturity corpus"
        case .discount: return "Retail savings, margin & reverse discounts"
        case .gst: return "Goods & Services Tax (Intra/Inter state)"
        }
    }

    public var iconName: String {
        switch self {
        case .emi: return "banknote.fill"
        case .sip: return "chart.line.uptrend.xyaxis"
        case .fd: return "lock.shield.fill"
        case .rd: return "repeat.circle.fill"
        case .discount: return "percent"
        case .gst: return "doc.text.below.ecg.fill"
        }
    }

    public var category: FinancialToolCategory {
        switch self {
        case .emi: return .loans
        case .sip, .fd, .rd: return .investments
        case .discount, .gst: return .commerce
        }
    }
}

