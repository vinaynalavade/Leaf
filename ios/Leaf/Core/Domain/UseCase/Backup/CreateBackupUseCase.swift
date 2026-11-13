import Foundation

/// UseCase responsible for preparing a consistent database snapshot, encrypting it with AES-GCM 256,
/// and saving it to an exported `.leafbackup` file.
/// Enforces the updated password policy (minimum 12 characters, Unicode & space passphrase support).
public final class CreateBackupUseCase: Sendable {

    private let backupService: BackupService

    public init(backupService: BackupService) {
        self.backupService = backupService
    }

    public func execute(password: String) async throws -> (fileURL: URL, summary: BackupSummary) {
        guard password.count >= BackupService.minimumPasswordLength else {
            throw BackupServiceError.passwordTooShort(BackupService.minimumPasswordLength)
        }

        return try await backupService.createBackup(password: password)
    }
}
