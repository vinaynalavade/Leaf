import Foundation

/// The decrypted financial data payload containing a complete point-in-time snapshot of the user's database
/// and associated statement document files.
public struct LeafBackupPayload: Codable, Sendable {
    public static let currentSchemaVersion: Int = 1

    public let formatVersion: Int
    public let schemaVersion: Int
    public let appVersion: String
    public let createdAt: Int64
    public let currencyCode: String

    // Core Financial Records
    public let transactions: [TransactionRecord]
    public let categories: [CategoryRecord]
    public let budgets: [BudgetRecord]
    public let savingsGoals: [SavingsGoalRecord]
    public let savingsContributions: [SavingsGoalContributionRecord]
    public let splitExpenses: [SplitExpenseRecord]
    public let splitGroups: [SplitGroupRecord]
    public let splitParticipants: [SplitParticipantRecord]
    public let splitPayments: [SplitPaymentRecord]
    public let recurringTransactions: [RecurringTransactionRecord]
    public let recurringOccurrences: [RecurringTransactionOccurrenceRecord]
    public let statements: [StatementRecord]
    public let statementFiles: [StatementFileBackup]

    enum CodingKeys: String, CodingKey {
        case formatVersion
        case schemaVersion
        case appVersion
        case createdAt
        case currencyCode
        case transactions
        case categories
        case budgets
        case savingsGoals
        case savingsContributions
        case splitExpenses
        case splitGroups
        case splitParticipants
        case splitPayments
        case recurringTransactions
        case recurringOccurrences
        case statements
        case statementFiles
    }

    public init(
        formatVersion: Int = 1,
        schemaVersion: Int = currentSchemaVersion,
        appVersion: String,
        createdAt: Int64 = Int64(Date().timeIntervalSince1970 * 1000),
        currencyCode: String,
        transactions: [TransactionRecord],
        categories: [CategoryRecord],
        budgets: [BudgetRecord],
        savingsGoals: [SavingsGoalRecord],
        savingsContributions: [SavingsGoalContributionRecord],
        splitExpenses: [SplitExpenseRecord],
        splitGroups: [SplitGroupRecord],
        splitParticipants: [SplitParticipantRecord],
        splitPayments: [SplitPaymentRecord],
        recurringTransactions: [RecurringTransactionRecord],
        recurringOccurrences: [RecurringTransactionOccurrenceRecord],
        statements: [StatementRecord],
        statementFiles: [StatementFileBackup] = []
    ) {
        self.formatVersion = formatVersion
        self.schemaVersion = schemaVersion
        self.appVersion = appVersion
        self.createdAt = createdAt
        self.currencyCode = currencyCode
        self.transactions = transactions
        self.categories = categories
        self.budgets = budgets
        self.savingsGoals = savingsGoals
        self.savingsContributions = savingsContributions
        self.splitExpenses = splitExpenses
        self.splitGroups = splitGroups
        self.splitParticipants = splitParticipants
        self.splitPayments = splitPayments
        self.recurringTransactions = recurringTransactions
        self.recurringOccurrences = recurringOccurrences
        self.statements = statements
        self.statementFiles = statementFiles
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.formatVersion = try container.decode(Int.self, forKey: .formatVersion)
        self.schemaVersion = try container.decodeIfPresent(Int.self, forKey: .schemaVersion) ?? Self.currentSchemaVersion
        self.appVersion = try container.decode(String.self, forKey: .appVersion)
        self.createdAt = try container.decode(Int64.self, forKey: .createdAt)
        self.currencyCode = try container.decode(String.self, forKey: .currencyCode)
        self.transactions = try container.decode([TransactionRecord].self, forKey: .transactions)
        self.categories = try container.decode([CategoryRecord].self, forKey: .categories)
        self.budgets = try container.decode([BudgetRecord].self, forKey: .budgets)
        self.savingsGoals = try container.decode([SavingsGoalRecord].self, forKey: .savingsGoals)
        self.savingsContributions = try container.decode([SavingsGoalContributionRecord].self, forKey: .savingsContributions)
        self.splitExpenses = try container.decode([SplitExpenseRecord].self, forKey: .splitExpenses)
        self.splitGroups = try container.decode([SplitGroupRecord].self, forKey: .splitGroups)
        self.splitParticipants = try container.decode([SplitParticipantRecord].self, forKey: .splitParticipants)
        self.splitPayments = try container.decode([SplitPaymentRecord].self, forKey: .splitPayments)
        self.recurringTransactions = try container.decode([RecurringTransactionRecord].self, forKey: .recurringTransactions)
        self.recurringOccurrences = try container.decode([RecurringTransactionOccurrenceRecord].self, forKey: .recurringOccurrences)
        self.statements = try container.decode([StatementRecord].self, forKey: .statements)
        self.statementFiles = try container.decodeIfPresent([StatementFileBackup].self, forKey: .statementFiles) ?? []
    }
}
