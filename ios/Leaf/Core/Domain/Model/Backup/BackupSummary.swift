import Foundation

/// High-level inspection summary of a backup's contents, shown to the user before confirming restore.
public struct BackupSummary: Identifiable, Sendable {
    public var id: String { "\(createdAt.timeIntervalSince1970)" }

    public let formatVersion: Int
    public let appVersion: String
    public let createdAt: Date
    public let currencyCode: String
    public let fileSizeFormatted: String
    public let kdfIterations: Int
    public let encryptionAlgorithm: String

    public let transactionCount: Int
    public let categoryCount: Int
    public let budgetCount: Int
    public let savingsGoalCount: Int
    public let splitExpenseCount: Int
    public let recurringScheduleCount: Int
    public let statementCount: Int
    public let statementFileCount: Int
    public let missingStatementFileCount: Int

    public var totalRecordCount: Int {
        transactionCount + categoryCount + budgetCount + savingsGoalCount + splitExpenseCount + recurringScheduleCount + statementCount
    }

    public init(
        formatVersion: Int,
        appVersion: String,
        createdAt: Date,
        currencyCode: String,
        fileSizeFormatted: String,
        kdfIterations: Int = LeafBackupContainer.defaultIterations,
        encryptionAlgorithm: String = LeafBackupContainer.defaultEncryptionAlgorithm,
        transactionCount: Int,
        categoryCount: Int,
        budgetCount: Int,
        savingsGoalCount: Int,
        splitExpenseCount: Int,
        recurringScheduleCount: Int,
        statementCount: Int,
        statementFileCount: Int = 0,
        missingStatementFileCount: Int = 0
    ) {
        self.formatVersion = formatVersion
        self.appVersion = appVersion
        self.createdAt = createdAt
        self.currencyCode = currencyCode
        self.fileSizeFormatted = fileSizeFormatted
        self.kdfIterations = kdfIterations
        self.encryptionAlgorithm = encryptionAlgorithm
        self.transactionCount = transactionCount
        self.categoryCount = categoryCount
        self.budgetCount = budgetCount
        self.savingsGoalCount = savingsGoalCount
        self.splitExpenseCount = splitExpenseCount
        self.recurringScheduleCount = recurringScheduleCount
        self.statementCount = statementCount
        self.statementFileCount = statementFileCount
        self.missingStatementFileCount = missingStatementFileCount
    }
}
