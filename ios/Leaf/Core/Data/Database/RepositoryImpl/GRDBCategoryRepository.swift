import Foundation
import GRDB

public final class GRDBCategoryRepository: CategoryRepositoryProtocol, Sendable {

    private let database: AppDatabase

    public init(database: AppDatabase) {
        self.database = database
    }

    public func getAllCategories() async throws -> [Category] {
        try await database.writer.read { db in
            let records = try CategoryRecord.order(Column("id").asc).fetchAll(db)
            return records.map { record in
                Category(
                    id: record.id ?? 0,
                    name: record.name,
                    iconName: record.iconName,
                    colorHex: record.colorHex,
                    type: TransactionType(rawValue: record.type) ?? .expense,
                    isDefault: record.isDefault
                )
            }
        }
    }

    public func getCategory(id: Int64) async throws -> Category? {
        try await database.writer.read { db in
            guard let record = try CategoryRecord.fetchOne(db, key: id) else { return nil }
            return Category(
                id: record.id ?? 0,
                name: record.name,
                iconName: record.iconName,
                colorHex: record.colorHex,
                type: TransactionType(rawValue: record.type) ?? .expense,
                isDefault: record.isDefault
            )
        }
    }

    public func insertCategory(_ category: Category) async throws -> Int64 {
        try await database.writer.write { db in
            var record = CategoryRecord(
                name: category.name,
                iconName: category.iconName,
                colorHex: category.colorHex,
                type: category.type.rawValue,
                isDefault: category.isDefault
            )
            try record.insert(db)
            return record.id ?? 0
        }
    }

    public func updateCategory(_ category: Category) async throws {
        try await database.writer.write { db in
            let record = CategoryRecord(
                id: category.id,
                name: category.name,
                iconName: category.iconName,
                colorHex: category.colorHex,
                type: category.type.rawValue,
                isDefault: category.isDefault
            )
            try record.update(db)
        }
    }

    public func deleteCategory(id: Int64) async throws {
        try await database.writer.write { db in
            _ = try CategoryRecord.deleteOne(db, key: id)
        }
    }
}

