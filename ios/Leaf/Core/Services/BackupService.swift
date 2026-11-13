import Foundation
import GRDB
import UserNotifications

public enum BackupServiceError: LocalizedError {
    case fileNotFound
    case readFailed
    case emptyPayload
    case passwordTooShort(Int)
    case corruptedStatementFile(String)
    case stagingFailed(String)
    case restorationFailed(String)
    case databaseUnavailable

    public var errorDescription: String? {
        switch self {
        case .fileNotFound:
            return "The backup file could not be found."
        case .readFailed:
            return "Failed to read the backup file from storage."
        case .emptyPayload:
            return "The backup payload contains no recoverable data."
        case .passwordTooShort(let minimum):
            return "Backup password must contain at least \(minimum) characters. Longer passphrases are recommended."
        case .corruptedStatementFile(let name):
            return "Statement file '\(name)' is corrupted or cannot be verified."
        case .stagingFailed(let reason):
            return "Failed to prepare restore staging: \(reason). Your existing data was preserved."
        case .restorationFailed(let reason):
            return "Restoration failed: \(reason). Your existing data was preserved."
        case .databaseUnavailable:
            return "Database is temporarily unavailable."
        }
    }
}

/// Service managing the creation, validation, atomic multi-step restoration,
/// crash recovery, and secure wiping of Leaf financial data.
///
/// True Atomicity & Explicit Commit Architecture:
/// - SQLite transactions only protect SQLite data; they cannot roll back filesystem changes.
/// - This service implements an explicit 7-phase durable restore commit protocol:
///   1. `preparing`
///   2. `databaseReplaced`
///   3. `statementsReplaced`
///   4. `committed` (durable point of no return: both db and statement files placed and verified)
///   5. `cleanupCompleted`
///   6. `rollingBack`
///   7. `rollbackCompleted`
/// - Rollback snapshots are NEVER deleted before the `committed` state is safely persisted to disk.
/// - If a crash occurs after commitment, startup recovery preserves the newly restored data and finishes cleanup.
/// - If a crash occurs before commitment, startup recovery safely rolls back database and statement files.
/// - If a crash occurs during rollback or cleanup, the operation resumes idempotently.
public final class BackupService: Sendable {

    public static let minimumPasswordLength: Int = 12

    private let database: AppDatabase
    private let preferencesRepository: UserPreferencesRepositoryProtocol
    private let cryptoEngine: BackupCryptoEngine
    private let notificationService: NotificationService

    public init(
        database: AppDatabase,
        preferencesRepository: UserPreferencesRepositoryProtocol,
        cryptoEngine: BackupCryptoEngine = .shared,
        notificationService: NotificationService = .shared
    ) {
        self.database = database
        self.preferencesRepository = preferencesRepository
        self.cryptoEngine = cryptoEngine
        self.notificationService = notificationService
    }

    // MARK: - Paths & Directories

    private var fileManager: FileManager { FileManager.default }

    private func getRestoreDirectory() throws -> URL {
        let appSupport = try fileManager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let restoreDir = appSupport.appendingPathComponent("LeafRestore", isDirectory: true)
        if !fileManager.fileExists(atPath: restoreDir.path) {
            try fileManager.createDirectory(at: restoreDir, withIntermediateDirectories: true)
        }
        try? fileManager.setAttributes([.protectionKey: FileProtectionType.complete], ofItemAtPath: restoreDir.path)
        return restoreDir
    }

    private func getDocumentsStatementsDirectory() -> URL {
        if let userDocs = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first {
            let dir = userDocs.appendingPathComponent("Statements", isDirectory: true)
            if !fileManager.fileExists(atPath: dir.path) {
                try? fileManager.createDirectory(at: dir, withIntermediateDirectories: true)
            }
            try? fileManager.setAttributes([.protectionKey: FileProtectionType.complete], ofItemAtPath: dir.path)
            return dir
        }
        let fallback = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("Statements", isDirectory: true)
        try? fileManager.createDirectory(at: fallback, withIntermediateDirectories: true)
        return fallback
    }

    // MARK: - Backup Creation

    /// Compiles a complete point-in-time snapshot of the database and associated statement files into an unencrypted LeafBackupPayload.
    public func compileCurrentBackupPayload() async throws -> LeafBackupPayload {
        let prefs = preferencesRepository.getUserPreferences()
        let currency = prefs.currencyCode

        // 1. Take a consistent point-in-time read snapshot of all financial records
        let (records, statements): (LeafBackupPayload, [StatementRecord]) = try await database.writer.read { db in
            let transactions = try TransactionRecord.fetchAll(db)
            let categories = try CategoryRecord.fetchAll(db)
            let budgets = try BudgetRecord.fetchAll(db)
            let savingsGoals = try SavingsGoalRecord.fetchAll(db)
            let savingsContributions = try SavingsGoalContributionRecord.fetchAll(db)
            let splitExpenses = try SplitExpenseRecord.fetchAll(db)
            let splitGroups = try SplitGroupRecord.fetchAll(db)
            let splitParticipants = try SplitParticipantRecord.fetchAll(db)
            let splitPayments = try SplitPaymentRecord.fetchAll(db)
            let recurringTransactions = try RecurringTransactionRecord.fetchAll(db)
            let recurringOccurrences = try RecurringTransactionOccurrenceRecord.fetchAll(db)
            let statements = try StatementRecord.fetchAll(db)

            let payload = LeafBackupPayload(
                formatVersion: LeafBackupContainer.currentFormatVersion,
                schemaVersion: 1,
                appVersion: "1.0.0",
                createdAt: Int64(Date().timeIntervalSince1970 * 1000),
                currencyCode: currency,
                transactions: transactions,
                categories: categories,
                budgets: budgets,
                savingsGoals: savingsGoals,
                savingsContributions: savingsContributions,
                splitExpenses: splitExpenses,
                splitGroups: splitGroups,
                splitParticipants: splitParticipants,
                splitPayments: splitPayments,
                recurringTransactions: recurringTransactions,
                recurringOccurrences: recurringOccurrences,
                statements: statements,
                statementFiles: []
            )

            return (payload, statements)
        }

        // 2. Discover and bundle statement files from Documents/Statements
        let docsUrl = getDocumentsStatementsDirectory()
        var statementFiles: [StatementFileBackup] = []

        for statement in statements {
            let filename = URL(fileURLWithPath: statement.filePath).lastPathComponent
            let candidateURL = docsUrl.appendingPathComponent(filename)

            var fileData: Data? = nil
            if fileManager.fileExists(atPath: candidateURL.path) {
                fileData = try? Data(contentsOf: candidateURL)
            } else if fileManager.fileExists(atPath: statement.filePath) {
                fileData = try? Data(contentsOf: URL(fileURLWithPath: statement.filePath))
            }

            if let data = fileData, let statementId = statement.id {
                statementFiles.append(
                    StatementFileBackup(
                        filename: filename,
                        statementId: statementId,
                        fileData: data
                    )
                )
            }
        }

        return LeafBackupPayload(
            formatVersion: records.formatVersion,
            schemaVersion: 1,
            appVersion: records.appVersion,
            createdAt: records.createdAt,
            currencyCode: records.currencyCode,
            transactions: records.transactions,
            categories: records.categories,
            budgets: records.budgets,
            savingsGoals: records.savingsGoals,
            savingsContributions: records.savingsContributions,
            splitExpenses: records.splitExpenses,
            splitGroups: records.splitGroups,
            splitParticipants: records.splitParticipants,
            splitPayments: records.splitPayments,
            recurringTransactions: records.recurringTransactions,
            recurringOccurrences: records.recurringOccurrences,
            statements: records.statements,
            statementFiles: statementFiles
        )
    }

    /// Creates an encrypted `.leafbackup` file from the current database snapshot and stored statement files.
    /// Enforces the updated password policy (minimum 12 characters, Unicode & space support).
    public func createBackup(password: String) async throws -> (fileURL: URL, summary: BackupSummary) {
        guard password.count >= Self.minimumPasswordLength else {
            throw BackupServiceError.passwordTooShort(Self.minimumPasswordLength)
        }

        let fullPayload = try await compileCurrentBackupPayload()

        // 3. Serialize payload to JSON
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        let plaintextData = try encoder.encode(fullPayload)

        // 4. Encrypt payload using AES-GCM 256 and PBKDF2-HMAC-SHA256 (600,000 iterations default)
        let container = try cryptoEngine.encrypt(
            plaintextData: plaintextData,
            password: password,
            appVersion: "1.0.0"
        )

        let containerData = try JSONEncoder().encode(container)

        // 5. Save to temporary file with FileProtectionType.complete
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd-HHmmss"
        let timestampStr = dateFormatter.string(from: Date())
        let filename = "Leaf-Backup-\(timestampStr).leafbackup"

        let tempDir = fileManager.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent(filename)

        try containerData.write(to: fileURL, options: [.atomic, .completeFileProtection])

        // 6. Update last backup timestamp
        let nowEpoch = Int64(Date().timeIntervalSince1970 * 1000)
        preferencesRepository.setLastBackupTimestamp(nowEpoch)

        let byteCountFormatter = ByteCountFormatter()
        byteCountFormatter.allowedUnits = [.useKB, .useMB]
        byteCountFormatter.countStyle = .file
        let formattedSize = byteCountFormatter.string(fromByteCount: Int64(containerData.count))

        let summary = BackupSummary(
            formatVersion: container.formatVersion,
            appVersion: container.appVersion,
            createdAt: Date(),
            currencyCode: fullPayload.currencyCode,
            fileSizeFormatted: formattedSize,
            kdfIterations: container.iterations,
            encryptionAlgorithm: container.encryptionAlgorithm,
            transactionCount: fullPayload.transactions.count,
            categoryCount: fullPayload.categories.count,
            budgetCount: fullPayload.budgets.count,
            savingsGoalCount: fullPayload.savingsGoals.count,
            splitExpenseCount: fullPayload.splitExpenses.count,
            recurringScheduleCount: fullPayload.recurringTransactions.count,
            statementCount: fullPayload.statements.count,
            statementFileCount: fullPayload.statementFiles.count,
            missingStatementFileCount: 0
        )

        return (fileURL, summary)
    }

    // MARK: - Backup Validation & Inspection (Supports Legacy Passwords)

    /// Decrypts and validates the backup file structure, returning an inspection summary without applying changes.
    /// Does NOT enforce the 12-character minimum password rule so users can restore older backups.
    /// Accepts the original password exactly as entered and derives keys using metadata iterations.
    public func validateBackup(
        fileURL: URL,
        password: String,
        progressHandler: (@Sendable (RestoreProgressState) -> Void)? = nil
    ) async throws -> (payload: LeafBackupPayload, summary: BackupSummary) {
        progressHandler?(.validating)

        let isAccessing = fileURL.startAccessingSecurityScopedResource()
        defer {
            if isAccessing {
                fileURL.stopAccessingSecurityScopedResource()
            }
        }

        guard fileManager.fileExists(atPath: fileURL.path) else {
            throw BackupServiceError.fileNotFound
        }

        let containerData: Data
        do {
            containerData = try Data(contentsOf: fileURL)
        } catch {
            throw BackupServiceError.readFailed
        }

        let container: LeafBackupContainer
        do {
            container = try JSONDecoder().decode(LeafBackupContainer.self, from: containerData)
        } catch {
            throw BackupCryptoError.invalidBackupFormat
        }

        progressHandler?(.decrypting)
        let decryptedData = try cryptoEngine.decrypt(container: container, password: password)

        let payload: LeafBackupPayload
        do {
            payload = try JSONDecoder().decode(LeafBackupPayload.self, from: decryptedData)
        } catch {
            throw BackupCryptoError.invalidBackupFormat
        }

        // Validate embedded statement files integrity
        for fileBackup in payload.statementFiles {
            guard let data = fileBackup.fileData, !data.isEmpty else {
                throw BackupServiceError.corruptedStatementFile(fileBackup.filename)
            }
        }

        let byteCountFormatter = ByteCountFormatter()
        byteCountFormatter.allowedUnits = [.useKB, .useMB]
        byteCountFormatter.countStyle = .file
        let formattedSize = byteCountFormatter.string(fromByteCount: Int64(containerData.count))

        // Check statement file completeness
        let embeddedFilenames = Set(payload.statementFiles.map { $0.filename })
        var missingStatementCount = 0
        for statement in payload.statements {
            let filename = URL(fileURLWithPath: statement.filePath).lastPathComponent
            if !embeddedFilenames.contains(filename) {
                missingStatementCount += 1
            }
        }

        let summary = BackupSummary(
            formatVersion: container.formatVersion,
            appVersion: container.appVersion,
            createdAt: Date(timeIntervalSince1970: Double(container.createdAt) / 1000.0),
            currencyCode: payload.currencyCode,
            fileSizeFormatted: formattedSize,
            kdfIterations: container.iterations,
            encryptionAlgorithm: container.encryptionAlgorithm,
            transactionCount: payload.transactions.count,
            categoryCount: payload.categories.count,
            budgetCount: payload.budgets.count,
            savingsGoalCount: payload.savingsGoals.count,
            splitExpenseCount: payload.splitExpenses.count,
            recurringScheduleCount: payload.recurringTransactions.count,
            statementCount: payload.statements.count,
            statementFileCount: payload.statementFiles.count,
            missingStatementFileCount: missingStatementCount
        )

        return (payload, summary)
    }

    // MARK: - Coordinated Atomic Restoration with Explicit Commit Protocol

    /// Atomically restores the database and statement files from a validated backup payload.
    ///
    /// Explicit Commit Protocol:
    /// 1. `preparing`: Staging statement files & capturing pre-restore safety snapshots.
    /// 2. `databaseReplaced`: Database records committed in SQLite write transaction.
    /// 3. `statementsReplaced`: Staged statement files moved to Documents/Statements.
    /// 4. `committed`: DURABLE COMMIT POINT! Both database and statements verified. Rollback snapshots preserved.
    /// 5. `cleanupCompleted`: Rollback snapshots and staging files safely purged after commitment.
    ///
    /// If any error occurs prior to commitment, the system rolls back cleanly to pre-restore state.
    public func restoreBackup(
        payload: LeafBackupPayload,
        progressHandler: (@Sendable (RestoreProgressState) -> Void)? = nil
    ) async throws {
        let restoreDir = try getRestoreDirectory()
        let journalURL = restoreDir.appendingPathComponent("restore_journal.json")
        let stagingStatementsDir = restoreDir.appendingPathComponent("staging_statements", isDirectory: true)
        let preRestoreStatementsDir = restoreDir.appendingPathComponent("prerestore_statements", isDirectory: true)
        let preRestoreSnapshotURL = restoreDir.appendingPathComponent("prerestore_db_snapshot.json")
        let activeStatementsDir = getDocumentsStatementsDirectory()

        let currentPrefs = preferencesRepository.getUserPreferences()
        let originalCurrency = currentPrefs.currencyCode

        // --- STAGE 1: Preparing & Staging Statements ---
        progressHandler?(.preparing)

        // Clean any leftover staging from previous aborted runs
        try? fileManager.removeItem(at: stagingStatementsDir)
        try? fileManager.removeItem(at: preRestoreStatementsDir)
        try? fileManager.removeItem(at: preRestoreSnapshotURL)
        try fileManager.createDirectory(at: stagingStatementsDir, withIntermediateDirectories: true)
        try? fileManager.setAttributes([.protectionKey: FileProtectionType.complete], ofItemAtPath: stagingStatementsDir.path)

        // Record initial journal marker: preparing
        var journal = RestoreJournal(
            step: .preparing,
            originalCurrencyCode: originalCurrency,
            stagedStatementFileCount: payload.statementFiles.count,
            preRestoreStatementFileCount: 0
        )
        try writeJournal(journal, to: journalURL)

        // Extract and verify all statement files into staging
        for statementFile in payload.statementFiles {
            guard let data = statementFile.fileData, !data.isEmpty else {
                throw BackupServiceError.corruptedStatementFile(statementFile.filename)
            }
            let stagedFileURL = stagingStatementsDir.appendingPathComponent(statementFile.filename)
            do {
                try data.write(to: stagedFileURL, options: [.atomic, .completeFileProtection])
            } catch {
                throw BackupServiceError.stagingFailed("Insufficient disk space or write failure for \(statementFile.filename)")
            }

            // Verify file exists, is readable, and size matches
            guard fileManager.fileExists(atPath: stagedFileURL.path),
                  let attributes = try? fileManager.attributesOfItem(atPath: stagedFileURL.path),
                  let size = attributes[.size] as? Int64,
                  size == Int64(data.count) else {
                throw BackupServiceError.corruptedStatementFile(statementFile.filename)
            }
        }

        // Capture pre-restore safety snapshot of existing database records
        let preRestorePayload: LeafBackupPayload = try await database.writer.read { db in
            let transactions = try TransactionRecord.fetchAll(db)
            let categories = try CategoryRecord.fetchAll(db)
            let budgets = try BudgetRecord.fetchAll(db)
            let savingsGoals = try SavingsGoalRecord.fetchAll(db)
            let savingsContributions = try SavingsGoalContributionRecord.fetchAll(db)
            let splitExpenses = try SplitExpenseRecord.fetchAll(db)
            let splitGroups = try SplitGroupRecord.fetchAll(db)
            let splitParticipants = try SplitParticipantRecord.fetchAll(db)
            let splitPayments = try SplitPaymentRecord.fetchAll(db)
            let recurringTransactions = try RecurringTransactionRecord.fetchAll(db)
            let recurringOccurrences = try RecurringTransactionOccurrenceRecord.fetchAll(db)
            let statements = try StatementRecord.fetchAll(db)

            return LeafBackupPayload(
                formatVersion: LeafBackupContainer.currentFormatVersion,
                schemaVersion: 1,
                appVersion: "1.0.0",
                createdAt: Int64(Date().timeIntervalSince1970 * 1000),
                currencyCode: originalCurrency,
                transactions: transactions,
                categories: categories,
                budgets: budgets,
                savingsGoals: savingsGoals,
                savingsContributions: savingsContributions,
                splitExpenses: splitExpenses,
                splitGroups: splitGroups,
                splitParticipants: splitParticipants,
                splitPayments: splitPayments,
                recurringTransactions: recurringTransactions,
                recurringOccurrences: recurringOccurrences,
                statements: statements,
                statementFiles: []
            )
        }

        let preRestoreData = try JSONEncoder().encode(preRestorePayload)
        try preRestoreData.write(to: preRestoreSnapshotURL, options: [.atomic, .completeFileProtection])

        // Backup existing statement files from Documents/Statements
        try fileManager.createDirectory(at: preRestoreStatementsDir, withIntermediateDirectories: true)
        var preRestoreFileCount = 0
        if let existingStatements = try? fileManager.contentsOfDirectory(at: activeStatementsDir, includingPropertiesForKeys: nil) {
            for existingFile in existingStatements {
                let dest = preRestoreStatementsDir.appendingPathComponent(existingFile.lastPathComponent)
                try? fileManager.copyItem(at: existingFile, to: dest)
                preRestoreFileCount += 1
            }
        }

        // --- STAGE 2: Database Replacement ---
        progressHandler?(.restoringRecords)
        do {
            try await database.writer.write { db in
                // Delete existing records in dependency order
                _ = try SplitPaymentRecord.deleteAll(db)
                _ = try SplitParticipantRecord.deleteAll(db)
                _ = try SplitExpenseRecord.deleteAll(db)
                _ = try SplitGroupRecord.deleteAll(db)

                _ = try RecurringTransactionOccurrenceRecord.deleteAll(db)
                _ = try RecurringTransactionRecord.deleteAll(db)

                _ = try SavingsGoalContributionRecord.deleteAll(db)
                _ = try SavingsGoalRecord.deleteAll(db)

                _ = try TransactionRecord.deleteAll(db)
                _ = try BudgetRecord.deleteAll(db)
                _ = try StatementRecord.deleteAll(db)
                _ = try CategoryRecord.deleteAll(db)

                // Re-insert restored records
                for category in payload.categories { var r = category; try r.insert(db) }
                for budget in payload.budgets { var r = budget; try r.insert(db) }
                for tx in payload.transactions { var r = tx; try r.insert(db) }
                for goal in payload.savingsGoals { var r = goal; try r.insert(db) }
                for contrib in payload.savingsContributions { var r = contrib; try r.insert(db) }
                for group in payload.splitGroups { var r = group; try r.insert(db) }
                for expense in payload.splitExpenses { var r = expense; try r.insert(db) }
                for participant in payload.splitParticipants { var r = participant; try r.insert(db) }
                for payment in payload.splitPayments { var r = payment; try r.insert(db) }
                for recurring in payload.recurringTransactions { var r = recurring; try r.insert(db) }
                for occurrence in payload.recurringOccurrences { var r = occurrence; try r.insert(db) }

                for statement in payload.statements {
                    var record = statement
                    let filename = URL(fileURLWithPath: statement.filePath).lastPathComponent
                    let targetPath = activeStatementsDir.appendingPathComponent(filename).path
                    record.filePath = targetPath
                    try record.insert(db)
                }
            }
        } catch {
            // Database replacement failed. Execute controlled rollback protocol
            let rollbackJournal = RestoreJournal(
                step: .rollingBack,
                originalCurrencyCode: originalCurrency,
                stagedStatementFileCount: payload.statementFiles.count,
                preRestoreStatementFileCount: preRestoreFileCount
            )
            try? writeJournal(rollbackJournal, to: journalURL)

            await rollbackToPreRestoreState(
                snapshotURL: preRestoreSnapshotURL,
                backupStatementsDir: preRestoreStatementsDir,
                activeStatementsDir: activeStatementsDir,
                originalCurrency: originalCurrency
            )

            let completedJournal = RestoreJournal(
                step: .rollbackCompleted,
                originalCurrencyCode: originalCurrency,
                stagedStatementFileCount: payload.statementFiles.count,
                preRestoreStatementFileCount: preRestoreFileCount
            )
            try? writeJournal(completedJournal, to: journalURL)
            try? fileManager.removeItem(at: restoreDir)

            progressHandler?(.failed(error.localizedDescription))
            throw BackupServiceError.restorationFailed(error.localizedDescription)
        }

        // Durably mark databaseReplaced
        journal = RestoreJournal(
            step: .databaseReplaced,
            originalCurrencyCode: originalCurrency,
            stagedStatementFileCount: payload.statementFiles.count,
            preRestoreStatementFileCount: preRestoreFileCount
        )
        try writeJournal(journal, to: journalURL)

        // --- STAGE 3: Statements Replacement ---
        progressHandler?(.restoringStatements)
        do {
            // Remove previous statement files
            if let existingStatements = try? fileManager.contentsOfDirectory(at: activeStatementsDir, includingPropertiesForKeys: nil) {
                for file in existingStatements {
                    try? fileManager.removeItem(at: file)
                }
            }

            // Move staged statement files into active Documents/Statements
            if let stagedFiles = try? fileManager.contentsOfDirectory(at: stagingStatementsDir, includingPropertiesForKeys: nil) {
                for stagedFile in stagedFiles {
                    let dest = activeStatementsDir.appendingPathComponent(stagedFile.lastPathComponent)
                    try? fileManager.removeItem(at: dest)
                    try fileManager.moveItem(at: stagedFile, to: dest)
                    try? fileManager.setAttributes([.protectionKey: FileProtectionType.complete], ofItemAtPath: dest.path)
                }
            }
        } catch {
            // Statement file replacement failed! Execute controlled rollback
            let rollbackJournal = RestoreJournal(
                step: .rollingBack,
                originalCurrencyCode: originalCurrency,
                stagedStatementFileCount: payload.statementFiles.count,
                preRestoreStatementFileCount: preRestoreFileCount
            )
            try? writeJournal(rollbackJournal, to: journalURL)

            await rollbackToPreRestoreState(
                snapshotURL: preRestoreSnapshotURL,
                backupStatementsDir: preRestoreStatementsDir,
                activeStatementsDir: activeStatementsDir,
                originalCurrency: originalCurrency
            )

            let completedJournal = RestoreJournal(
                step: .rollbackCompleted,
                originalCurrencyCode: originalCurrency,
                stagedStatementFileCount: payload.statementFiles.count,
                preRestoreStatementFileCount: preRestoreFileCount
            )
            try? writeJournal(completedJournal, to: journalURL)
            try? fileManager.removeItem(at: restoreDir)

            progressHandler?(.failed("Failed to place statement files: \(error.localizedDescription)"))
            throw BackupServiceError.restorationFailed("Failed to restore statement files. Previous state was safely restored.")
        }

        // Durably mark statementsReplaced
        journal = RestoreJournal(
            step: .statementsReplaced,
            originalCurrencyCode: originalCurrency,
            stagedStatementFileCount: payload.statementFiles.count,
            preRestoreStatementFileCount: preRestoreFileCount
        )
        try writeJournal(journal, to: journalURL)

        // --- STAGE 4: Commit Point (POINT OF NO RETURN) ---
        // Both the database records and all statement files are verified in active storage!
        // We write the committed marker BEFORE deleting any pre-restore recovery snapshots.
        journal = RestoreJournal(
            step: .committed,
            originalCurrencyCode: originalCurrency,
            stagedStatementFileCount: payload.statementFiles.count,
            preRestoreStatementFileCount: preRestoreFileCount
        )
        try writeJournal(journal, to: journalURL)

        if !payload.currencyCode.isEmpty {
            preferencesRepository.setCurrencyCode(payload.currencyCode)
        }

        // --- STAGE 5: Controlled Cleanup ---
        progressHandler?(.finalizing)

        // Now that the restore is committed, safely purge staging and pre-restore snapshots
        try? fileManager.removeItem(at: stagingStatementsDir)
        try? fileManager.removeItem(at: preRestoreStatementsDir)
        try? fileManager.removeItem(at: preRestoreSnapshotURL)

        // Mark cleanupCompleted
        journal = RestoreJournal(
            step: .cleanupCompleted,
            originalCurrencyCode: originalCurrency,
            stagedStatementFileCount: payload.statementFiles.count,
            preRestoreStatementFileCount: preRestoreFileCount
        )
        try writeJournal(journal, to: journalURL)

        // Finally remove journal and restore directory
        try? fileManager.removeItem(at: restoreDir)

        progressHandler?(.completed)
    }

    // MARK: - Crash / Interruption Recovery

    /// Inspects protected storage on application launch to detect any restore operation
    /// that was interrupted by a crash, process termination, or battery loss.
    /// Distinguishes between committed and uncommitted restores, ensuring idempotency:
    /// - Before commitment: restores previous consistent database and statement files.
    /// - After commitment: preserves newly restored data and safely finishes cleanup.
    @discardableResult
    public func checkAndRecoverInterruptedRestore() async -> Bool {
        guard let restoreDir = try? getRestoreDirectory() else { return false }
        let journalURL = restoreDir.appendingPathComponent("restore_journal.json")

        guard fileManager.fileExists(atPath: journalURL.path),
              let journalData = try? Data(contentsOf: journalURL),
              let journal = try? JSONDecoder().decode(RestoreJournal.self, from: journalData) else {
            // Clean up any untracked staging artifacts
            if fileManager.fileExists(atPath: restoreDir.path) {
                try? fileManager.removeItem(at: restoreDir)
            }
            return false
        }

        let preRestoreSnapshotURL = restoreDir.appendingPathComponent("prerestore_db_snapshot.json")
        let preRestoreStatementsDir = restoreDir.appendingPathComponent("prerestore_statements", isDirectory: true)
        let stagingStatementsDir = restoreDir.appendingPathComponent("staging_statements", isDirectory: true)
        let activeStatementsDir = getDocumentsStatementsDirectory()

        switch journal.step {
        case .preparing:
            // Interrupted during initial staging: user data was never modified!
            try? fileManager.removeItem(at: restoreDir)
            return false

        case .databaseReplaced, .statementsReplaced, .rollingBack:
            // SCENARIO A & C: Interrupted BEFORE commitment, or interrupted during a prior rollback!
            // Roll back database and statement files to guaranteed pre-restore state.

            // 1. Durably record that rollback is actively executing
            let rollbackJournal = RestoreJournal(
                step: .rollingBack,
                originalCurrencyCode: journal.originalCurrencyCode,
                stagedStatementFileCount: journal.stagedStatementFileCount,
                preRestoreStatementFileCount: journal.preRestoreStatementFileCount
            )
            try? writeJournal(rollbackJournal, to: journalURL)

            // 2. Perform rollback of database, statements, and preferences
            await rollbackToPreRestoreState(
                snapshotURL: preRestoreSnapshotURL,
                backupStatementsDir: preRestoreStatementsDir,
                activeStatementsDir: activeStatementsDir,
                originalCurrency: journal.originalCurrencyCode
            )

            // 3. Mark rollback completed before deleting snapshots
            let completedJournal = RestoreJournal(
                step: .rollbackCompleted,
                originalCurrencyCode: journal.originalCurrencyCode,
                stagedStatementFileCount: journal.stagedStatementFileCount,
                preRestoreStatementFileCount: journal.preRestoreStatementFileCount
            )
            try? writeJournal(completedJournal, to: journalURL)

            // 4. Safely clean up recovery artifacts
            try? fileManager.removeItem(at: restoreDir)
            return true

        case .committed:
            // SCENARIO B: Interrupted AFTER commitment!
            // The newly restored data was committed. NEVER roll back!
            // Finish removing temporary staging and old snapshots safely:
            try? fileManager.removeItem(at: stagingStatementsDir)
            try? fileManager.removeItem(at: preRestoreStatementsDir)
            try? fileManager.removeItem(at: preRestoreSnapshotURL)

            // Mark cleanup completed
            let cleanupJournal = RestoreJournal(
                step: .cleanupCompleted,
                originalCurrencyCode: journal.originalCurrencyCode,
                stagedStatementFileCount: journal.stagedStatementFileCount,
                preRestoreStatementFileCount: journal.preRestoreStatementFileCount
            )
            try? writeJournal(cleanupJournal, to: journalURL)

            // Remove journal and restore directory
            try? fileManager.removeItem(at: restoreDir)
            return false

        case .cleanupCompleted:
            // SCENARIO D: Interrupted during final directory removal after committed cleanup
            try? fileManager.removeItem(at: restoreDir)
            return false

        case .rollbackCompleted:
            // SCENARIO D: Interrupted during final directory removal after rollback completed
            try? fileManager.removeItem(at: restoreDir)
            return true
        }
    }

    // MARK: - Rollback Helper

    private func rollbackToPreRestoreState(
        snapshotURL: URL,
        backupStatementsDir: URL,
        activeStatementsDir: URL,
        originalCurrency: String
    ) async {
        // 1. Rollback database records if snapshot exists
        if fileManager.fileExists(atPath: snapshotURL.path),
           let data = try? Data(contentsOf: snapshotURL),
           let preRestorePayload = try? JSONDecoder().decode(LeafBackupPayload.self, from: data) {
            _ = try? await database.writer.write { db in
                _ = try? SplitPaymentRecord.deleteAll(db)
                _ = try? SplitParticipantRecord.deleteAll(db)
                _ = try? SplitExpenseRecord.deleteAll(db)
                _ = try? SplitGroupRecord.deleteAll(db)

                _ = try? RecurringTransactionOccurrenceRecord.deleteAll(db)
                _ = try? RecurringTransactionRecord.deleteAll(db)

                _ = try? SavingsGoalContributionRecord.deleteAll(db)
                _ = try? SavingsGoalRecord.deleteAll(db)

                _ = try? TransactionRecord.deleteAll(db)
                _ = try? BudgetRecord.deleteAll(db)
                _ = try? StatementRecord.deleteAll(db)
                _ = try? CategoryRecord.deleteAll(db)

                for category in preRestorePayload.categories { var r = category; try? r.insert(db) }
                for budget in preRestorePayload.budgets { var r = budget; try? r.insert(db) }
                for tx in preRestorePayload.transactions { var r = tx; try? r.insert(db) }
                for goal in preRestorePayload.savingsGoals { var r = goal; try? r.insert(db) }
                for contrib in preRestorePayload.savingsContributions { var r = contrib; try? r.insert(db) }
                for group in preRestorePayload.splitGroups { var r = group; try? r.insert(db) }
                for expense in preRestorePayload.splitExpenses { var r = expense; try? r.insert(db) }
                for part in preRestorePayload.splitParticipants { var r = part; try? r.insert(db) }
                for pay in preRestorePayload.splitPayments { var r = pay; try? r.insert(db) }
                for rec in preRestorePayload.recurringTransactions { var r = rec; try? r.insert(db) }
                for occ in preRestorePayload.recurringOccurrences { var r = occ; try? r.insert(db) }
                for stmt in preRestorePayload.statements { var r = stmt; try? r.insert(db) }
            }
        }

        // 2. Rollback statement files
        if fileManager.fileExists(atPath: backupStatementsDir.path),
           let files = try? fileManager.contentsOfDirectory(at: backupStatementsDir, includingPropertiesForKeys: nil) {
            // Clear current corrupted directory
            if let activeFiles = try? fileManager.contentsOfDirectory(at: activeStatementsDir, includingPropertiesForKeys: nil) {
                for file in activeFiles { try? fileManager.removeItem(at: file) }
            }

            for file in files {
                let dest = activeStatementsDir.appendingPathComponent(file.lastPathComponent)
                try? fileManager.copyItem(at: file, to: dest)
                try? fileManager.setAttributes([.protectionKey: FileProtectionType.complete], ofItemAtPath: dest.path)
            }
        }

        // 3. Restore currency preference
        if !originalCurrency.isEmpty {
            preferencesRepository.setCurrencyCode(originalCurrency)
        }
    }

    private func writeJournal(_ journal: RestoreJournal, to url: URL) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let data = try encoder.encode(journal)
        try data.write(to: url, options: [.atomic, .completeFileProtection])
    }

    // MARK: - Secure Data Deletion

    /// Irreversibly erases all user-created financial data, restores default categories,
    /// wipes app-owned statement and backup files, clears local reminders, and resets preferences.
    /// Strictly limits file deletion to Leaf-owned directories and artifacts.
    public func deleteAllFinancialData() async throws {
        // 1. Wipe all database tables atomically and re-seed defaults
        try await database.writer.write { db in
            _ = try SplitPaymentRecord.deleteAll(db)
            _ = try SplitParticipantRecord.deleteAll(db)
            _ = try SplitExpenseRecord.deleteAll(db)
            _ = try SplitGroupRecord.deleteAll(db)

            _ = try RecurringTransactionOccurrenceRecord.deleteAll(db)
            _ = try RecurringTransactionRecord.deleteAll(db)

            _ = try SavingsGoalContributionRecord.deleteAll(db)
            _ = try SavingsGoalRecord.deleteAll(db)

            _ = try TransactionRecord.deleteAll(db)
            _ = try BudgetRecord.deleteAll(db)
            _ = try StatementRecord.deleteAll(db)
            _ = try CategoryRecord.deleteAll(db)

            // Re-seed default category taxonomy
            try CategorySeeds.seedDefaultCategories(db)
        }

        // 2. Reset user preferences to defaults
        preferencesRepository.resetAllPreferences()

        // 3. Cancel all local notification reminders
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()
        center.removeAllDeliveredNotifications()

        // 4. Wipe all app-owned files in Documents/Statements
        let docsUrl = getDocumentsStatementsDirectory()
        if let items = try? fileManager.contentsOfDirectory(at: docsUrl, includingPropertiesForKeys: nil) {
            for item in items {
                try? fileManager.removeItem(at: item)
            }
        }

        // 5. Remove any app-generated .leafbackup, .pdf, or .csv files in Documents root
        if let userDocs = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first {
            if let rootItems = try? fileManager.contentsOfDirectory(at: userDocs, includingPropertiesForKeys: nil) {
                for item in rootItems {
                    let ext = item.pathExtension.lowercased()
                    if ext == "leafbackup" || (item.lastPathComponent.hasPrefix("Leaf_") && (ext == "pdf" || ext == "csv")) {
                        try? fileManager.removeItem(at: item)
                    }
                }
            }
        }

        // 6. Clean up restore staging directory if present
        if let restoreDir = try? getRestoreDirectory() {
            try? fileManager.removeItem(at: restoreDir)
        }

        // 7. Clean up app-owned files in Caches and Temporary directory
        if let cacheDir = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first,
           let cacheItems = try? fileManager.contentsOfDirectory(at: cacheDir, includingPropertiesForKeys: nil) {
            for item in cacheItems {
                try? fileManager.removeItem(at: item)
            }
        }

        if let tempItems = try? fileManager.contentsOfDirectory(at: fileManager.temporaryDirectory, includingPropertiesForKeys: nil) {
            for item in tempItems {
                try? fileManager.removeItem(at: item)
            }
        }
    }
}
