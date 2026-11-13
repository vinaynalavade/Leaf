import Foundation
import SwiftUI

/// State coordinator for the retail Discount Calculator screen.
@Observable
public final class DiscountCalculatorViewModel {

    private let calculateDiscountUseCase: CalculateDiscountUseCase

    public var mode: DiscountCalculationMode = .forward

    // Forward inputs
    public var originalPriceString: String = "1500"
    public var discountPercentString: String = "20"
    public var isSuccessiveDiscountEnabled: Bool = false
    public var successiveDiscountPercentString: String = "10"

    // Reverse inputs
    public var reverseOriginalPriceString: String = "2000"
    public var reverseFinalPriceString: String = "1500"

    public var result: DiscountResult = .zero

    public init(calculateDiscountUseCase: CalculateDiscountUseCase) {
        self.calculateDiscountUseCase = calculateDiscountUseCase
        self.calculate()
    }

    public func calculate() {
        switch mode {
        case .forward:
            let original = Double(originalPriceString.replacingOccurrences(of: ",", with: "")) ?? 0.0
            let discount = Double(discountPercentString) ?? 0.0
            let succ = isSuccessiveDiscountEnabled ? (Double(successiveDiscountPercentString) ?? 0.0) : nil

            self.result = calculateDiscountUseCase.executeForward(
                originalPrice: original,
                discountPercentage: discount,
                successiveDiscountPercentage: succ
            )

        case .reverse:
            let original = Double(reverseOriginalPriceString.replacingOccurrences(of: ",", with: "")) ?? 0.0
            let finalPrice = Double(reverseFinalPriceString.replacingOccurrences(of: ",", with: "")) ?? 0.0

            self.result = calculateDiscountUseCase.executeReverse(
                originalPrice: original,
                finalPrice: finalPrice
            )
        }
    }

    public func reset() {
        self.originalPriceString = "1500"
        self.discountPercentString = "20"
        self.isSuccessiveDiscountEnabled = false
        self.successiveDiscountPercentString = "10"
        self.reverseOriginalPriceString = "2000"
        self.reverseFinalPriceString = "1500"
        calculate()
    }

    public func setDiscountPreset(_ pct: Double) {
        self.discountPercentString = String(format: "%.0f", pct)
        calculate()
    }
}

