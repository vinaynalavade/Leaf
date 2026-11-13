import Foundation
import SwiftUI

/// State coordinator for the Indian GST (Goods & Services Tax) calculator.
@Observable
public final class GstCalculatorViewModel {

    private let calculateGstUseCase: CalculateGstUseCase

    public var amountString: String = "10000"
    public var selectedRate: Double = 18.0
    public var customRateString: String = ""
    public var isCustomRate: Bool = false
    public var mode: GstCalculationMode = .exclusive
    public var transactionType: GstTransactionType = .intraState

    public var result: GstResult = .zero

    public init(calculateGstUseCase: CalculateGstUseCase) {
        self.calculateGstUseCase = calculateGstUseCase
        self.calculate()
    }

    public func calculate() {
        let amt = Double(amountString.replacingOccurrences(of: ",", with: "")) ?? 0.0
        let rate: Double
        if isCustomRate {
            rate = Double(customRateString) ?? 0.0
        } else {
            rate = selectedRate
        }

        self.result = calculateGstUseCase.execute(
            amount: amt,
            gstRatePercent: rate,
            isInclusive: mode == .inclusive,
            isInterState: transactionType == .interState
        )
    }

    public func reset() {
        self.amountString = "10000"
        self.selectedRate = 18.0
        self.isCustomRate = false
        self.customRateString = ""
        self.mode = .exclusive
        self.transactionType = .intraState
        calculate()
    }

    public func selectRatePreset(_ rate: Double) {
        self.isCustomRate = false
        self.selectedRate = rate
        calculate()
    }
}

