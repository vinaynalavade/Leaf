import Foundation

/// Fetches all generated financial statements from SQLite, ordered with most recent first.
public final class GetStatementsUseCase: Sendable {

    private let statementRepository: StatementRepositoryProtocol

    public init(statementRepository: StatementRepositoryProtocol) {
        self.statementRepository = statementRepository
    }

    public func execute() async throws -> [SavedStatement] {
        try await statementRepository.getAllStatements()
    }
}

