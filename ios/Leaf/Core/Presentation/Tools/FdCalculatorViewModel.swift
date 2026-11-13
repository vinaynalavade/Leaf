import Foundation
import SwiftUI

/// State coordinator for the Fixed Deposit (FD) calculator screen.
@Observable
public final class FdCalculatorViewModel {

    private let calculateFdUseCase: CalculateFdUseCase

    public var principalString: String = "100000"
    public var interestRateString: String = "7.0"
    public var tenureYearsString: String = "3"
    public var compoundingFrequency: CompoundingFrequency = .quarterly

    public var result: FdResult = .zero

    public init(calculateFdUseCase: CalculateFdUseCase) {
        self.calculateFdUseCase = calculateFdUseCase
        self.calculate()
    }

    public func calculate() {
        let principal = Double(principalString.replacingOccurrences(of: ",", with: "")) ?? 0.0
        let rate = Double(interestRateString) ?? 0.0
        let tenureYears = Double(tenureYearsString) ?? 0.0
        let totalMonths = Int(round(tenureYears * 12.0))

        self.result = calculateFdUseCase.execute(
            principal: principal,
            annualRatePercent: rate,
            tenureMonths: totalMonths,
            compoundingFrequency: compoundingFrequency
        )
    }

    public func reset() {
        self.principalString = "100000"
        self.interestRateString = "7.0"
        self.tenureYearsString = "3"
        self.compoundingFrequency = .quarterly
        calculate()
    }

    public func setTenurePreset(_ years: Int) {
        self.tenureYearsString = "\(years)"
        calculate()
    }
}

