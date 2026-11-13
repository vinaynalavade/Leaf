import Foundation
import SwiftUI

/// State coordinator for the Loan / EMI Calculator screen.
@Observable
public final class EmiCalculatorViewModel {

    private let calculateEmiUseCase: CalculateEmiUseCase

    public var principalString: String = "1000000"
    public var rateString: String = "8.5"
    public var tenureString: String = "20"
    public var tenureUnit: EmiTenureUnit = .years
    public var isScheduleSheetPresented: Bool = false

    public var result: EmiResult = .zero

    public init(calculateEmiUseCase: CalculateEmiUseCase) {
        self.calculateEmiUseCase = calculateEmiUseCase
        self.calculate()
    }

    public func calculate() {
        let principal = Double(principalString.replacingOccurrences(of: ",", with: "")) ?? 0.0
        let rate = Double(rateString) ?? 0.0
        let tenure = Double(tenureString) ?? 0.0

        self.result = calculateEmiUseCase.execute(
            principal: principal,
            annualRatePercent: rate,
            tenureValue: tenure,
            tenureUnit: tenureUnit
        )
    }

    public func reset() {
        self.principalString = "1000000"
        self.rateString = "8.5"
        self.tenureString = "20"
        self.tenureUnit = .years
        calculate()
    }

    public func setTenurePreset(_ years: Int) {
        self.tenureUnit = .years
        self.tenureString = "\(years)"
        calculate()
    }
}

