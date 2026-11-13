import Foundation

/// Domain model representing a target-driven savings goal with contributions and progress metrics.
public struct SavingsGoal: Identifiable, Hashable, Codable, Sendable {
    public let id: Int64
    public let name: String
    public let targetAmount: Amount
    public let targetDate: Int64?
    public let note: String?
    public let iconName: String
    public let colorHex: String
    public let isArchived: Bool
    public let contributions: [SavingsGoalContribution]
    public let createdAt: Int64
    public let updatedAt: Int64

    public init(
        id: Int64 = 0,
        name: String,
        targetAmount: Amount,
        targetDate: Int64? = nil,
        note: String? = nil,
        iconName: String = "savings",
        colorHex: String = "#10B981",
        isArchived: Bool = false,
        contributions: [SavingsGoalContribution] = [],
        createdAt: Int64 = Int64(Date().timeIntervalSince1970 * 1000),
        updatedAt: Int64 = Int64(Date().timeIntervalSince1970 * 1000)
    ) {
        self.id = id
        self.name = name
        self.targetAmount = targetAmount
        self.targetDate = targetDate
        self.note = note
        self.iconName = iconName
        self.colorHex = colorHex
        self.isArchived = isArchived
        self.contributions = contributions
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    /// Total amount saved so far derived from contributions.
    public var currentSavedAmount: Amount {
        let totalSubunits = contributions.reduce(Int64(0)) { $0 + $1.amount.subunits }
        return Amount(subunits: totalSubunits)
    }

    /// Remaining amount needed to reach the target amount.
    public var remainingAmount: Amount {
        Amount(subunits: max(0, targetAmount.subunits - currentSavedAmount.subunits))
    }

    /// Progress percentage from 0.0 to 100.0.
    public var progressPercentage: Double {
        guard targetAmount.subunits > 0 else { return 0.0 }
        let fraction = Double(currentSavedAmount.subunits) / Double(targetAmount.subunits)
        return min(100.0, max(0.0, fraction * 100.0))
    }

    /// Dynamically derived completion status.
    public var isCompleted: Bool {
        targetAmount.subunits > 0 && currentSavedAmount.subunits >= targetAmount.subunits
    }

    /// Days remaining until target date (nil if no target date).
    public var daysRemaining: Int? {
        guard let targetDate = targetDate else { return nil }
        let nowEpoch = Int64(Date().timeIntervalSince1970 * 1000)
        let diffMs = targetDate - nowEpoch
        let days = Int(ceil(Double(diffMs) / (1000.0 * 64800.0 + 1000.0 * 21600.0))) // 86400s in day
        return days
    }

    /// Required monthly savings based on calendar ceiling division: ceil(Deficit / MonthsRemaining).
    public var requiredMonthlySavings: Amount? {
        guard let targetDate = targetDate, !isCompleted else { return nil }
        let nowEpoch = Int64(Date().timeIntervalSince1970 * 1000)
        guard targetDate > nowEpoch else { return remainingAmount }

        let now = Date(timeIntervalSince1970: Double(nowEpoch) / 1000.0)
        let target = Date(timeIntervalSince1970: Double(targetDate) / 1000.0)
        let calendar = Calendar.current
        let components = calendar.dateComponents([.month], from: now, to: target)
        let monthsRemaining = max(1, components.month ?? 1)

        let deficit = remainingAmount.subunits
        guard deficit > 0 else { return .zero }

        // Ceiling integer division: (deficit + months - 1) / months
        let monthlySubunits = (deficit + Int64(monthsRemaining) - 1) / Int64(monthsRemaining)
        return Amount(subunits: monthlySubunits)
    }
}
