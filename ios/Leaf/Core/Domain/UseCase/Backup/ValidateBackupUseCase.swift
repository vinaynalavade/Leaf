import Foundation

/// UseCase that reads, decrypts, and verifies a `.leafbackup` file without mutating the database,
/// returning an inspection summary of record counts and metadata.
public final class ValidateBackupUseCase: Sendable {

    private let backupService: BackupService

    public init(backupService: BackupService) {
        self.backupService = backupService
    }

    public func execute(
        fileURL: URL,
        password: String,
        progressHandler: (@Sendable (RestoreProgressState) -> Void)? = nil
    ) async throws -> (payload: LeafBackupPayload, summary: BackupSummary) {
        return try await backupService.validateBackup(fileURL: fileURL, password: password, progressHandler: progressHandler)
    }
}
