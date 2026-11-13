import Foundation

/// Calculation direction for the discount calculator.
public enum DiscountCalculationMode: String, CaseIterable, Identifiable, Sendable {
    case forward = "FORWARD"
    case reverse = "REVERSE"

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .forward: return "Standard Discount"
        case .reverse: return "Reverse (Price to %)"
        }
    }
}

/// Result of a retail discount calculation.
public struct DiscountResult: Hashable, Sendable {
    public let originalPrice: Double
    public let discountPercentage: Double
    public let discountAmount: Double
    public let finalPrice: Double
    public let savingsPercentage: Double
    public let successiveDiscountPercentage: Double?
    public let effectiveDiscountPercentage: Double

    public init(
        originalPrice: Double,
        discountPercentage: Double,
        discountAmount: Double,
        finalPrice: Double,
        savingsPercentage: Double,
        successiveDiscountPercentage: Double? = nil,
        effectiveDiscountPercentage: Double
    ) {
        self.originalPrice = originalPrice
        self.discountPercentage = discountPercentage
        self.discountAmount = discountAmount
        self.finalPrice = finalPrice
        self.savingsPercentage = savingsPercentage
        self.successiveDiscountPercentage = successiveDiscountPercentage
        self.effectiveDiscountPercentage = effectiveDiscountPercentage
    }

    public static let zero = DiscountResult(
        originalPrice: 0.0,
        discountPercentage: 0.0,
        discountAmount: 0.0,
        finalPrice: 0.0,
        savingsPercentage: 0.0,
        successiveDiscountPercentage: nil,
        effectiveDiscountPercentage: 0.0
    )
}

