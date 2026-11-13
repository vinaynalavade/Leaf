import Foundation

/// UseCase projecting Systematic Investment Plan (SIP) returns with optional step-up increments.
public final class CalculateSipUseCase: Sendable {

    public init() {}

    public func execute(
        monthlyInvestment: Double,
        annualReturnPercent: Double,
        durationYears: Int,
        stepUpPercentage: Double = 0.0
    ) -> SipResult {
        FinancialCalculatorEngine.calculateSip(
            monthlyInvestment: monthlyInvestment,
            annualReturnPercent: annualReturnPercent,
            durationYears: durationYears,
            stepUpPercentage: stepUpPercentage
        )
    }
}

