import Foundation
import SwiftUI

/// State coordinator for the Recurring Deposit (RD) calculator screen.
@Observable
public final class RdCalculatorViewModel {

    private let calculateRdUseCase: CalculateRdUseCase

    public var monthlyDepositString: String = "5000"
    public var interestRateString: String = "6.8"
    public var tenureMonthsString: String = "24" // 2 years default
    public var compoundingFrequency: CompoundingFrequency = .quarterly

    public var result: RdResult = .zero

    public init(calculateRdUseCase: CalculateRdUseCase) {
        self.calculateRdUseCase = calculateRdUseCase
        self.calculate()
    }

    public func calculate() {
        let deposit = Double(monthlyDepositString.replacingOccurrences(of: ",", with: "")) ?? 0.0
        let rate = Double(interestRateString) ?? 0.0
        let months = Int(tenureMonthsString) ?? 0

        self.result = calculateRdUseCase.execute(
            monthlyDeposit: deposit,
            annualRatePercent: rate,
            tenureMonths: months,
            compoundingFrequency: compoundingFrequency
        )
    }

    public func reset() {
        self.monthlyDepositString = "5000"
        self.interestRateString = "6.8"
        self.tenureMonthsString = "24"
        self.compoundingFrequency = .quarterly
        calculate()
    }

    public func setMonthsPreset(_ months: Int) {
        self.tenureMonthsString = "\(months)"
        calculate()
    }
}

