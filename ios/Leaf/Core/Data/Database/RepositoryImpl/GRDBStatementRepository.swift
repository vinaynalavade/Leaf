import Foundation
import GRDB

public final class GRDBStatementRepository: StatementRepositoryProtocol, @unchecked Sendable {
    private let database: AppDatabase

    public init(database: AppDatabase) {
        self.database = database
    }

    public func getAllStatements() async throws -> [SavedStatement] {
        try await database.reader.read { db in
            let records = try StatementRecord
                .order(Column("generated_at").desc)
                .fetchAll(db)
            return records.map { $0.toDomain() }
        }
    }

    public func getStatement(id: Int64) async throws -> SavedStatement? {
        try await database.reader.read { db in
            try StatementRecord.fetchOne(db, key: id)?.toDomain()
        }
    }

    public func insertStatement(_ statement: SavedStatement) async throws -> Int64 {
        try await database.writer.write { db in
            var record = StatementRecord(from: statement)
            try record.insert(db)
            return db.lastInsertedRowID
        }
    }

    public func updateStatement(_ statement: SavedStatement) async throws {
        try await database.writer.write { db in
            let record = StatementRecord(from: statement)
            try record.update(db)
        }
    }

    public func deleteStatement(id: Int64) async throws {
        try await database.writer.write { db in
            _ = try StatementRecord.deleteOne(db, key: id)
        }
    }
}

