import Foundation

/// UseCase performing atomic transactional restoration of financial records from a validated backup payload.
/// Coordinates database commits, statement file placement, progress callbacks, and post-restore occurrence scheduling.
public final class RestoreBackupUseCase: Sendable {

    private let backupService: BackupService
    private let generateDueOccurrencesUseCase: GenerateDueOccurrencesUseCase

    public init(
        backupService: BackupService,
        generateDueOccurrencesUseCase: GenerateDueOccurrencesUseCase
    ) {
        self.backupService = backupService
        self.generateDueOccurrencesUseCase = generateDueOccurrencesUseCase
    }

    public func execute(
        payload: LeafBackupPayload,
        progressHandler: (@Sendable (RestoreProgressState) -> Void)? = nil
    ) async throws {
        try await backupService.restoreBackup(payload: payload, progressHandler: progressHandler)

        // Reconcile recurring occurrences and pending local reminders after complete restoration
        try? await generateDueOccurrencesUseCase.execute()
    }
}
