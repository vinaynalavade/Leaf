import Foundation

/// Result of a Fixed Deposit (FD) calculation.
public struct FdResult: Hashable, Sendable {
    public let investedAmount: Double
    public let totalInterest: Double
    public let maturityAmount: Double
    public let effectiveAnnualRate: Double
    public let compoundingFrequency: CompoundingFrequency

    public init(
        investedAmount: Double,
        totalInterest: Double,
        maturityAmount: Double,
        effectiveAnnualRate: Double,
        compoundingFrequency: CompoundingFrequency
    ) {
        self.investedAmount = investedAmount
        self.totalInterest = totalInterest
        self.maturityAmount = maturityAmount
        self.effectiveAnnualRate = effectiveAnnualRate
        self.compoundingFrequency = compoundingFrequency
    }

    public static let zero = FdResult(
        investedAmount: 0.0,
        totalInterest: 0.0,
        maturityAmount: 0.0,
        effectiveAnnualRate: 0.0,
        compoundingFrequency: .quarterly
    )
}

