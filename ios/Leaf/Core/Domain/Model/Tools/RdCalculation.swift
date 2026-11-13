import Foundation

/// Result of a Recurring Deposit (RD) calculation.
public struct RdResult: Hashable, Sendable {
    public let investedAmount: Double
    public let totalInterest: Double
    public let maturityAmount: Double
    public let tenureMonths: Int
    public let compoundingFrequency: CompoundingFrequency

    public init(
        investedAmount: Double,
        totalInterest: Double,
        maturityAmount: Double,
        tenureMonths: Int,
        compoundingFrequency: CompoundingFrequency
    ) {
        self.investedAmount = investedAmount
        self.totalInterest = totalInterest
        self.maturityAmount = maturityAmount
        self.tenureMonths = tenureMonths
        self.compoundingFrequency = compoundingFrequency
    }

    public static let zero = RdResult(
        investedAmount: 0.0,
        totalInterest: 0.0,
        maturityAmount: 0.0,
        tenureMonths: 0,
        compoundingFrequency: .quarterly
    )
}

