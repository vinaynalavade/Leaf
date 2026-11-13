import Foundation

/// Coordinator service managing Google Drive cloud backups, metadata synchronization,
/// and safe atomic restoration into the local SQLite database.
public final class GoogleDriveBackupService: @unchecked Sendable {

    private let authService: GoogleAuthServiceProtocol
    private let driveRestService: GoogleDriveRestService
    private let backupService: BackupService
    private let restoreBackupUseCase: RestoreBackupUseCase
    private let preferencesRepository: UserPreferencesRepositoryProtocol

    public init(
        authService: GoogleAuthServiceProtocol = GoogleAuthService.shared,
        driveRestService: GoogleDriveRestService = GoogleDriveRestService(),
        backupService: BackupService,
        restoreBackupUseCase: RestoreBackupUseCase,
        preferencesRepository: UserPreferencesRepositoryProtocol
    ) {
        self.authService = authService
        self.driveRestService = driveRestService
        self.backupService = backupService
        self.restoreBackupUseCase = restoreBackupUseCase
        self.preferencesRepository = preferencesRepository
    }

    /// Fetches existing backup metadata from the user's hidden Google Drive appDataFolder.
    public func fetchRemoteBackupMetadata() async throws -> GoogleBackupMetadata? {
        let token = try await authService.getValidAccessToken()
        return try await driveRestService.findBackupFile(accessToken: token)
    }

    /// Exports a complete snapshot of all local financial data and uploads to Google Drive.
    public func performGoogleDriveBackup() async throws -> GoogleBackupMetadata {
        let token = try await authService.getValidAccessToken()

        // 1. Build authentic backup payload using standard BackupService logic
        // We use a fixed system key for seamless cloud sync or serialize LeafBackupPayload directly to JSON
        let payload = try await backupService.compileCurrentBackupPayload()

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted]
        let jsonData = try encoder.encode(payload)
        guard let jsonString = String(data: jsonData, encoding: .utf8) else {
            throw GoogleDriveError.invalidData
        }

        // 2. Query if existing backup file exists in appDataFolder
        let existingMeta = try await driveRestService.findBackupFile(accessToken: token)

        let resultMeta: GoogleBackupMetadata
        if let existing = existingMeta {
            // Update existing file
            resultMeta = try await driveRestService.updateBackupFile(
                accessToken: token,
                fileId: existing.fileId,
                jsonContent: jsonString
            )
        } else {
            // Create new backup file
            resultMeta = try await driveRestService.createBackupFile(
                accessToken: token,
                jsonContent: jsonString
            )
        }

        // 3. Update local preferences with timestamp
        preferencesRepository.setLastBackupTimestamp(resultMeta.modifiedTime)

        return resultMeta
    }

    /// Downloads the latest backup from Google Drive and restores it into the local database atomically.
    public func performGoogleDriveRestore() async throws -> BackupSummary {
        let token = try await authService.getValidAccessToken()

        guard let meta = try await driveRestService.findBackupFile(accessToken: token) else {
            throw GoogleDriveError.apiError("No existing backup file found in Google Drive.")
        }

        // 1. Download payload JSON
        let jsonContent = try await driveRestService.downloadBackupFile(accessToken: token, fileId: meta.fileId)
        guard let data = jsonContent.data(using: .utf8) else {
            throw GoogleDriveError.invalidData
        }

        // 2. Decode LeafBackupPayload
        let decoder = JSONDecoder()
        let payload = try decoder.decode(LeafBackupPayload.self, from: data)

        // 3. Perform atomic restoration
        try await restoreBackupUseCase.execute(payload: payload)

        return BackupSummary(
            formatVersion: payload.formatVersion,
            appVersion: payload.appVersion,
            createdAt: Date(timeIntervalSince1970: Double(payload.createdAt) / 1000.0),
            currencyCode: payload.currencyCode,
            fileSizeFormatted: "\(data.count / 1024) KB",
            kdfIterations: 0,
            encryptionAlgorithm: "Google Drive HTTPS",
            transactionCount: payload.transactions.count,
            categoryCount: payload.categories.count,
            budgetCount: payload.budgets.count,
            savingsGoalCount: payload.savingsGoals.count,
            splitExpenseCount: payload.splitExpenses.count,
            recurringScheduleCount: payload.recurringTransactions.count,
            statementCount: payload.statements.count,
            statementFileCount: payload.statementFiles.count,
            missingStatementFileCount: 0
        )
    }
}
