import Foundation

/// Complete, validated financial statement dataset ready for PDF rendering or CSV serialization.
public struct FinancialStatementData: Hashable, Sendable {
    public let title: String
    public let period: StatementPeriod
    public let dateInterval: DateInterval
    public let generatedAt: Date
    public let currency: Currency

    // Account Balances
    public let openingBalance: Amount
    public let closingBalance: Amount

    // Operating Cash Flow (strictly ordinary)
    public let earnedIncome: Amount
    public let ordinaryExpenses: Amount
    public let operatingCashFlow: Amount
    public let unspentIncomeRate: Double

    // Checking Balance Movement (cash flow through checking account)
    public let totalCheckingInflow: Amount
    public let totalCheckingOutflow: Amount
    public let checkingBalanceMovement: Amount

    // Savings Activity (strictly segregated from ordinary flows)
    public let netSavingsContributions: Amount
    public let actualSavingsRate: Double
    public let savingsSummary: InsightsSavingsSummary

    // Detailed Itemizations
    public let categoryBreakdown: [CategoryAnalysisItem]
    public let incomeBreakdown: [CategoryAnalysisItem]
    public let transactions: [Transaction]
    public let budgetSummaries: [BudgetInsightItem]
    public let detailedSavings: [DetailedSavingsItem]

    public var transactionCount: Int {
        transactions.count
    }

    public var highestExpenseCategory: CategoryAnalysisItem? {
        categoryBreakdown.first
    }

    public init(
        title: String,
        period: StatementPeriod,
        dateInterval: DateInterval,
        generatedAt: Date = Date(),
        currency: Currency,
        openingBalance: Amount,
        closingBalance: Amount,
        earnedIncome: Amount,
        ordinaryExpenses: Amount,
        operatingCashFlow: Amount,
        unspentIncomeRate: Double,
        totalCheckingInflow: Amount,
        totalCheckingOutflow: Amount,
        checkingBalanceMovement: Amount,
        netSavingsContributions: Amount,
        actualSavingsRate: Double,
        savingsSummary: InsightsSavingsSummary,
        categoryBreakdown: [CategoryAnalysisItem],
        incomeBreakdown: [CategoryAnalysisItem],
        transactions: [Transaction],
        budgetSummaries: [BudgetInsightItem],
        detailedSavings: [DetailedSavingsItem] = []
    ) {
        self.title = title
        self.period = period
        self.dateInterval = dateInterval
        self.generatedAt = generatedAt
        self.currency = currency
        self.openingBalance = openingBalance
        self.closingBalance = closingBalance
        self.earnedIncome = earnedIncome
        self.ordinaryExpenses = ordinaryExpenses
        self.operatingCashFlow = operatingCashFlow
        self.unspentIncomeRate = unspentIncomeRate
        self.totalCheckingInflow = totalCheckingInflow
        self.totalCheckingOutflow = totalCheckingOutflow
        self.checkingBalanceMovement = checkingBalanceMovement
        self.netSavingsContributions = netSavingsContributions
        self.actualSavingsRate = actualSavingsRate
        self.savingsSummary = savingsSummary
        self.categoryBreakdown = categoryBreakdown
        self.incomeBreakdown = incomeBreakdown
        self.transactions = transactions
        self.budgetSummaries = budgetSummaries
        self.detailedSavings = detailedSavings
    }
}

/// An individual savings contribution (deposit) or withdrawal record for detailed statement reporting.
public struct DetailedSavingsItem: Identifiable, Hashable, Sendable {
    public let id: Int64
    public let goalId: Int64
    public let goalTitle: String
    public let amount: Amount
    public let isWithdrawal: Bool
    public let date: Date
    public let note: String?

    public init(
        id: Int64,
        goalId: Int64,
        goalTitle: String,
        amount: Amount,
        isWithdrawal: Bool,
        date: Date,
        note: String? = nil
    ) {
        self.id = id
        self.goalId = goalId
        self.goalTitle = goalTitle
        self.amount = amount
        self.isWithdrawal = isWithdrawal
        self.date = date
        self.note = note
    }
}

