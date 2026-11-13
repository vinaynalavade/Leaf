import Foundation

/// UseCase evaluating loan repayments and full amortisation schedules.
public final class CalculateEmiUseCase: Sendable {

    public init() {}

    public func execute(
        principal: Double,
        annualRatePercent: Double,
        tenureValue: Double,
        tenureUnit: EmiTenureUnit
    ) -> EmiResult {
        FinancialCalculatorEngine.calculateEmi(
            principal: principal,
            annualRatePercent: annualRatePercent,
            tenureValue: tenureValue,
            tenureUnit: tenureUnit
        )
    }
}

