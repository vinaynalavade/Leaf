import Foundation

/// UseCase responsible for completely and irreversibly erasing all user financial records,
/// resetting category seeds, and wiping temporary backup files.
public final class DeleteAllFinancialDataUseCase: Sendable {

    private let backupService: BackupService
    private let keychainService: KeychainService

    public init(
        backupService: BackupService,
        keychainService: KeychainService = .shared
    ) {
        self.backupService = backupService
        self.keychainService = keychainService
    }

    public func execute() async throws {
        try await backupService.deleteAllFinancialData()
        keychainService.deleteAll()
    }
}

