import Foundation

/// UseCase calculating Recurring Deposit installment compounding and maturity proceeds.
public final class CalculateRdUseCase: Sendable {

    public init() {}

    public func execute(
        monthlyDeposit: Double,
        annualRatePercent: Double,
        tenureMonths: Int,
        compoundingFrequency: CompoundingFrequency = .quarterly
    ) -> RdResult {
        FinancialCalculatorEngine.calculateRd(
            monthlyDeposit: monthlyDeposit,
            annualRatePercent: annualRatePercent,
            tenureMonths: tenureMonths,
            compoundingFrequency: compoundingFrequency
        )
    }
}

