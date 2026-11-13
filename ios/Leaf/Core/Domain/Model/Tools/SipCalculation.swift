import Foundation

/// Milestone tracking cumulative invested amount and corpus growth by year.
public struct SipYearlyMilestone: Identifiable, Hashable, Sendable {
    public var id: Int { year }
    public let year: Int
    public let investedAmount: Double
    public let estimatedReturns: Double
    public let totalCorpus: Double

    public init(year: Int, investedAmount: Double, estimatedReturns: Double, totalCorpus: Double) {
        self.year = year
        self.investedAmount = investedAmount
        self.estimatedReturns = estimatedReturns
        self.totalCorpus = totalCorpus
    }
}

/// Result of a Systematic Investment Plan (SIP) calculation.
public struct SipResult: Hashable, Sendable {
    public let totalInvested: Double
    public let estimatedReturns: Double
    public let totalCorpus: Double
    public let returnsRatio: Double
    public let yearlyMilestones: [SipYearlyMilestone]

    public init(
        totalInvested: Double,
        estimatedReturns: Double,
        totalCorpus: Double,
        returnsRatio: Double,
        yearlyMilestones: [SipYearlyMilestone] = []
    ) {
        self.totalInvested = totalInvested
        self.estimatedReturns = estimatedReturns
        self.totalCorpus = totalCorpus
        self.returnsRatio = returnsRatio
        self.yearlyMilestones = yearlyMilestones
    }

    public static let zero = SipResult(
        totalInvested: 0.0,
        estimatedReturns: 0.0,
        totalCorpus: 0.0,
        returnsRatio: 0.0,
        yearlyMilestones: []
    )
}

