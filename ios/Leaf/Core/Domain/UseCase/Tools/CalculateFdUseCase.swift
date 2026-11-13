import Foundation

/// UseCase calculating Fixed Deposit interest returns and maturity values.
public final class CalculateFdUseCase: Sendable {

    public init() {}

    public func execute(
        principal: Double,
        annualRatePercent: Double,
        tenureMonths: Int,
        compoundingFrequency: CompoundingFrequency = .quarterly
    ) -> FdResult {
        FinancialCalculatorEngine.calculateFd(
            principal: principal,
            annualRatePercent: annualRatePercent,
            tenureMonths: tenureMonths,
            compoundingFrequency: compoundingFrequency
        )
    }
}

