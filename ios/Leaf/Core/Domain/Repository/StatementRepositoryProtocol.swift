import Foundation

/// Repository protocol for managing persisted statement metadata and file tracking.
public protocol StatementRepositoryProtocol: Sendable {
    func getAllStatements() async throws -> [SavedStatement]
    func getStatement(id: Int64) async throws -> SavedStatement?
    func insertStatement(_ statement: SavedStatement) async throws -> Int64
    func updateStatement(_ statement: SavedStatement) async throws
    func deleteStatement(id: Int64) async throws
}

