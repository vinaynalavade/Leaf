import Foundation

/// Tenure unit for loan duration input.
public enum EmiTenureUnit: String, CaseIterable, Identifiable, Sendable {
    case years = "YEARS"
    case months = "MONTHS"

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .years: return "Years"
        case .months: return "Months"
        }
    }
}

/// An individual monthly breakdown entry in an EMI amortization schedule.
public struct EmiAmortizationMonth: Identifiable, Hashable, Sendable {
    public var id: Int { month }
    public let month: Int
    public let principalPayment: Double
    public let interestPayment: Double
    public let totalPayment: Double
    public let remainingBalance: Double

    public init(
        month: Int,
        principalPayment: Double,
        interestPayment: Double,
        totalPayment: Double,
        remainingBalance: Double
    ) {
        self.month = month
        self.principalPayment = principalPayment
        self.interestPayment = interestPayment
        self.totalPayment = totalPayment
        self.remainingBalance = remainingBalance
    }
}

/// Result of an Equated Monthly Installment (EMI) calculation.
public struct EmiResult: Hashable, Sendable {
    public let monthlyEmi: Double
    public let totalPrincipal: Double
    public let totalInterest: Double
    public let totalPayment: Double
    public let principalRatio: Double
    public let interestRatio: Double
    public let amortizationSchedule: [EmiAmortizationMonth]

    public init(
        monthlyEmi: Double,
        totalPrincipal: Double,
        totalInterest: Double,
        totalPayment: Double,
        principalRatio: Double,
        interestRatio: Double,
        amortizationSchedule: [EmiAmortizationMonth] = []
    ) {
        self.monthlyEmi = monthlyEmi
        self.totalPrincipal = totalPrincipal
        self.totalInterest = totalInterest
        self.totalPayment = totalPayment
        self.principalRatio = principalRatio
        self.interestRatio = interestRatio
        self.amortizationSchedule = amortizationSchedule
    }

    public static let zero = EmiResult(
        monthlyEmi: 0.0,
        totalPrincipal: 0.0,
        totalInterest: 0.0,
        totalPayment: 0.0,
        principalRatio: 1.0,
        interestRatio: 0.0,
        amortizationSchedule: []
    )
}

