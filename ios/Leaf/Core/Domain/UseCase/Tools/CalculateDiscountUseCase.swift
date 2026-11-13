import Foundation

/// UseCase calculating retail discounts, effective combined discounts, and reverse price-to-percent conversions.
public final class CalculateDiscountUseCase: Sendable {

    public init() {}

    public func executeForward(
        originalPrice: Double,
        discountPercentage: Double,
        successiveDiscountPercentage: Double? = nil
    ) -> DiscountResult {
        FinancialCalculatorEngine.calculateDiscount(
            originalPrice: originalPrice,
            discountPercentage: discountPercentage,
            successiveDiscountPercentage: successiveDiscountPercentage
        )
    }

    public func executeReverse(
        originalPrice: Double,
        finalPrice: Double
    ) -> DiscountResult {
        FinancialCalculatorEngine.calculateReverseDiscount(
            originalPrice: originalPrice,
            finalPrice: finalPrice
        )
    }
}

