import Foundation

/// GST Calculation mode: Exclusive (adds GST on top) vs Inclusive (extracts GST from total).
public enum GstCalculationMode: String, CaseIterable, Identifiable, Sendable {
    case exclusive = "EXCLUSIVE"
    case inclusive = "INCLUSIVE"

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .exclusive: return "GST Exclusive (+GST)"
        case .inclusive: return "GST Inclusive (-GST)"
        }
    }
}

/// Transaction jurisdiction for GST tax apportionment (India).
public enum GstTransactionType: String, CaseIterable, Identifiable, Sendable {
    case intraState = "INTRA_STATE"
    case interState = "INTER_STATE"

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .intraState: return "Intra-State (CGST + SGST)"
        case .interState: return "Inter-State (IGST)"
        }
    }
}

/// Result of an Indian Goods and Services Tax (GST) computation.
public struct GstResult: Hashable, Sendable {
    public let taxableAmount: Double
    public let totalGst: Double
    public let cgstAmount: Double
    public let sgstAmount: Double
    public let igstAmount: Double
    public let finalAmount: Double
    public let gstRate: Double
    public let isInclusive: Bool
    public let isInterState: Bool

    public init(
        taxableAmount: Double,
        totalGst: Double,
        cgstAmount: Double,
        sgstAmount: Double,
        igstAmount: Double,
        finalAmount: Double,
        gstRate: Double,
        isInclusive: Bool,
        isInterState: Bool
    ) {
        self.taxableAmount = taxableAmount
        self.totalGst = totalGst
        self.cgstAmount = cgstAmount
        self.sgstAmount = sgstAmount
        self.igstAmount = igstAmount
        self.finalAmount = finalAmount
        self.gstRate = gstRate
        self.isInclusive = isInclusive
        self.isInterState = isInterState
    }

    public static let zero = GstResult(
        taxableAmount: 0.0,
        totalGst: 0.0,
        cgstAmount: 0.0,
        sgstAmount: 0.0,
        igstAmount: 0.0,
        finalAmount: 0.0,
        gstRate: 18.0,
        isInclusive: false,
        isInterState: false
    )
}

