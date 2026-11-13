import Foundation
import SwiftUI

/// State coordinator for the SIP (Systematic Investment Plan) calculator.
@Observable
public final class SipCalculatorViewModel {

    private let calculateSipUseCase: CalculateSipUseCase

    public var monthlyInvestmentString: String = "10000"
    public var annualReturnString: String = "12.0"
    public var durationYearsString: String = "10"
    public var isStepUpEnabled: Bool = false
    public var stepUpPercentageString: String = "10.0"

    public var result: SipResult = .zero

    public init(calculateSipUseCase: CalculateSipUseCase) {
        self.calculateSipUseCase = calculateSipUseCase
        self.calculate()
    }

    public func calculate() {
        let monthly = Double(monthlyInvestmentString.replacingOccurrences(of: ",", with: "")) ?? 0.0
        let ret = Double(annualReturnString) ?? 0.0
        let duration = Int(durationYearsString) ?? 0
        let stepUp = isStepUpEnabled ? (Double(stepUpPercentageString) ?? 0.0) : 0.0

        self.result = calculateSipUseCase.execute(
            monthlyInvestment: monthly,
            annualReturnPercent: ret,
            durationYears: duration,
            stepUpPercentage: stepUp
        )
    }

    public func reset() {
        self.monthlyInvestmentString = "10000"
        self.annualReturnString = "12.0"
        self.durationYearsString = "10"
        self.isStepUpEnabled = false
        self.stepUpPercentageString = "10.0"
        calculate()
    }

    public func setDurationPreset(_ years: Int) {
        self.durationYearsString = "\(years)"
        calculate()
    }

    public func setReturnPreset(_ rate: Double) {
        self.annualReturnString = String(format: "%.1f", rate)
        calculate()
    }
}

