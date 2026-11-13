import Foundation

/// UseCase calculating Indian Goods & Services Tax (GST) allocations for intra-state and inter-state operations.
public final class CalculateGstUseCase: Sendable {

    public init() {}

    public func execute(
        amount: Double,
        gstRatePercent: Double,
        isInclusive: Bool,
        isInterState: Bool
    ) -> GstResult {
        FinancialCalculatorEngine.calculateGst(
            amount: amount,
            gstRatePercent: gstRatePercent,
            isInclusive: isInclusive,
            isInterState: isInterState
        )
    }
}

