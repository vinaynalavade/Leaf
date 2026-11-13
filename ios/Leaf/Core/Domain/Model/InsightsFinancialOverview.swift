import Foundation

/// Comprehensive overview of operating cash flow, checking balance movement,
/// savings performance, and previous-period comparisons.
public struct InsightsFinancialOverview: Hashable, Sendable {

    // MARK: - 1. Operating Cash Flow (Earned Income - Ordinary Expenses)
    /// Ordinary earned income (strictly excludes internal transfers like savings withdrawals).
    public let earnedIncome: Amount

    /// Ordinary expenses (strictly excludes internal transfers like savings deposits).
    public let ordinaryExpenses: Amount

    /// Operating cash flow: earnedIncome - ordinaryExpenses.
    public let operatingCashFlow: Amount

    /// Unspent Income Rate: ((earnedIncome - ordinaryExpenses) / earnedIncome) * 100%.
    /// Represents the cash surplus rate retained before savings goal allocations.
    /// Handled safely with 0.0% if earnedIncome <= 0.
    public let unspentIncomeRate: Double

    // MARK: - 2. Checking Balance Movement (Total Inflows - Total Outflows)
    /// Total cash entering checking account (earned income + savings withdrawals).
    public let totalCheckingInflow: Amount

    /// Total cash leaving checking account (ordinary expenses + savings deposits).
    public let totalCheckingOutflow: Amount

    /// Net checking balance movement: totalCheckingInflow - totalCheckingOutflow.
    public let checkingBalanceMovement: Amount

    // MARK: - 3. Actual Savings Contribution Rate
    /// Net savings contributions: period deposits - period withdrawals.
    public let netSavingsContributions: Amount

    /// Actual Savings Rate: (netSavingsContributions / earnedIncome) * 100%.
    /// Handled safely with 0.0% if earnedIncome <= 0.
    public let actualSavingsRate: Double

    // MARK: - 4. Previous-Period Comparison Metrics
    public let previousEarnedIncome: Amount?
    public let previousOrdinaryExpenses: Amount?
    public let previousOperatingCashFlow: Amount?
    public let previousCheckingBalanceMovement: Amount?

    public let expenseChangePercentage: Double?
    public let incomeChangePercentage: Double?
    public let operatingCashFlowChangePercentage: Double?

    // MARK: - 5. Segregated Savings Summary
    public let savingsSummary: InsightsSavingsSummary

    public init(
        earnedIncome: Amount,
        ordinaryExpenses: Amount,
        operatingCashFlow: Amount,
        unspentIncomeRate: Double,
        totalCheckingInflow: Amount,
        totalCheckingOutflow: Amount,
        checkingBalanceMovement: Amount,
        netSavingsContributions: Amount,
        actualSavingsRate: Double,
        previousEarnedIncome: Amount? = nil,
        previousOrdinaryExpenses: Amount? = nil,
        previousOperatingCashFlow: Amount? = nil,
        previousCheckingBalanceMovement: Amount? = nil,
        expenseChangePercentage: Double? = nil,
        incomeChangePercentage: Double? = nil,
        operatingCashFlowChangePercentage: Double? = nil,
        savingsSummary: InsightsSavingsSummary = .empty
    ) {
        self.earnedIncome = earnedIncome
        self.ordinaryExpenses = ordinaryExpenses
        self.operatingCashFlow = operatingCashFlow
        self.unspentIncomeRate = unspentIncomeRate
        self.totalCheckingInflow = totalCheckingInflow
        self.totalCheckingOutflow = totalCheckingOutflow
        self.checkingBalanceMovement = checkingBalanceMovement
        self.netSavingsContributions = netSavingsContributions
        self.actualSavingsRate = actualSavingsRate
        self.previousEarnedIncome = previousEarnedIncome
        self.previousOrdinaryExpenses = previousOrdinaryExpenses
        self.previousOperatingCashFlow = previousOperatingCashFlow
        self.previousCheckingBalanceMovement = previousCheckingBalanceMovement
        self.expenseChangePercentage = expenseChangePercentage
        self.incomeChangePercentage = incomeChangePercentage
        self.operatingCashFlowChangePercentage = operatingCashFlowChangePercentage
        self.savingsSummary = savingsSummary
    }

    // MARK: - Backward Compatibility Accessors
    public var totalIncome: Amount { earnedIncome }
    public var totalExpense: Amount { ordinaryExpenses }
    public var netCashFlow: Amount { operatingCashFlow }
    public var netSavingsRate: Double { unspentIncomeRate }
    public var previousTotalIncome: Amount? { previousEarnedIncome }
    public var previousTotalExpense: Amount? { previousOrdinaryExpenses }
    public var previousNetCashFlow: Amount? { previousOperatingCashFlow }

    public static var empty: InsightsFinancialOverview {
        InsightsFinancialOverview(
            earnedIncome: .zero,
            ordinaryExpenses: .zero,
            operatingCashFlow: .zero,
            unspentIncomeRate: 0.0,
            totalCheckingInflow: .zero,
            totalCheckingOutflow: .zero,
            checkingBalanceMovement: .zero,
            netSavingsContributions: .zero,
            actualSavingsRate: 0.0,
            previousEarnedIncome: nil,
            previousOrdinaryExpenses: nil,
            previousOperatingCashFlow: nil,
            previousCheckingBalanceMovement: nil,
            expenseChangePercentage: nil,
            incomeChangePercentage: nil,
            operatingCashFlowChangePercentage: nil,
            savingsSummary: .empty
        )
    }
}

/// Savings goal metrics segregated from ordinary income/expenses.
public struct InsightsSavingsSummary: Hashable, Sendable {
    public let totalSavedAcrossActiveGoals: Amount
    public let activeGoalsCount: Int
    public let periodContributionsTotal: Amount
    public let periodWithdrawalsTotal: Amount
    public let netContributionsTotal: Amount
    public let goals: [SavingsGoalInsightItem]
    public let recentActivity: [SavingsActivityItem]

    public init(
        totalSavedAcrossActiveGoals: Amount,
        activeGoalsCount: Int,
        periodContributionsTotal: Amount,
        periodWithdrawalsTotal: Amount,
        netContributionsTotal: Amount,
        goals: [SavingsGoalInsightItem],
        recentActivity: [SavingsActivityItem] = []
    ) {
        self.totalSavedAcrossActiveGoals = totalSavedAcrossActiveGoals
        self.activeGoalsCount = activeGoalsCount
        self.periodContributionsTotal = periodContributionsTotal
        self.periodWithdrawalsTotal = periodWithdrawalsTotal
        self.netContributionsTotal = netContributionsTotal
        self.goals = goals
        self.recentActivity = recentActivity
    }

    public static var empty: InsightsSavingsSummary {
        InsightsSavingsSummary(
            totalSavedAcrossActiveGoals: .zero,
            activeGoalsCount: 0,
            periodContributionsTotal: .zero,
            periodWithdrawalsTotal: .zero,
            netContributionsTotal: .zero,
            goals: [],
            recentActivity: []
        )
    }
}

/// Individual savings goal performance and progress insight.
public struct SavingsGoalInsightItem: Identifiable, Hashable, Sendable {
    public var id: Int64 { goal.id }
    public let goal: SavingsGoal
    public let currentAmount: Amount
    public let targetAmount: Amount
    public let progressPercentage: Double
    public let periodContributionsCount: Int
    public let periodContributionsTotal: Amount
    public let periodWithdrawalsTotal: Amount
    public let netContributionsTotal: Amount

    public init(
        goal: SavingsGoal,
        currentAmount: Amount,
        targetAmount: Amount,
        progressPercentage: Double,
        periodContributionsCount: Int,
        periodContributionsTotal: Amount,
        periodWithdrawalsTotal: Amount,
        netContributionsTotal: Amount? = nil
    ) {
        self.goal = goal
        self.currentAmount = currentAmount
        self.targetAmount = targetAmount
        self.progressPercentage = progressPercentage
        self.periodContributionsCount = periodContributionsCount
        self.periodContributionsTotal = periodContributionsTotal
        self.periodWithdrawalsTotal = periodWithdrawalsTotal
        self.netContributionsTotal = netContributionsTotal ?? Amount(periodContributionsTotal.subunits - periodWithdrawalsTotal.subunits)
    }
}

/// Individual savings contribution or withdrawal event within the analyzed period.
public struct SavingsActivityItem: Identifiable, Hashable, Sendable {
    public let id: Int64
    public let goalId: Int64
    public let goalName: String
    public let goalColorHex: String
    public let amount: Amount // Positive value
    public let isWithdrawal: Bool
    public let note: String?
    public let timestamp: Int64
    public let paymentMethod: PaymentMethod

    public init(
        id: Int64,
        goalId: Int64,
        goalName: String,
        goalColorHex: String,
        amount: Amount,
        isWithdrawal: Bool,
        note: String?,
        timestamp: Int64,
        paymentMethod: PaymentMethod
    ) {
        self.id = id
        self.goalId = goalId
        self.goalName = goalName
        self.goalColorHex = goalColorHex
        self.amount = amount
        self.isWithdrawal = isWithdrawal
        self.note = note
        self.timestamp = timestamp
        self.paymentMethod = paymentMethod
    }

    public var formattedDate: String {
        let date = Date(timeIntervalSince1970: Double(timestamp) / 1000.0)
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, h:mm a"
        return formatter.string(from: date)
    }
}
