import Foundation

/// Deletes a saved statement from the database and removes the physical export file from the device.
public final class DeleteStatementUseCase: Sendable {

    private let statementRepository: StatementRepositoryProtocol

    public init(statementRepository: StatementRepositoryProtocol) {
        self.statementRepository = statementRepository
    }

    public func execute(id: Int64) async throws {
        // 1. Locate statement record to find file path
        if let statement = try await statementRepository.getStatement(id: id) {
            let fileManager = FileManager.default
            if fileManager.fileExists(atPath: statement.filePath) {
                try? fileManager.removeItem(atPath: statement.filePath)
            }
        }

        // 2. Remove statement record from SQLite
        try await statementRepository.deleteStatement(id: id)
    }
}

