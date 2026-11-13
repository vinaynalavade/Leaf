import Foundation
import GRDB

public final class GRDBTravelWalletRepository: TravelWalletRepositoryProtocol, Sendable {

    private let database: AppDatabase

    public init(database: AppDatabase) {
        self.database = database
    }

    public func getAllWallets() async throws -> [TravelWallet] {
        try await database.writer.read { db in
            let records = try TravelWalletRecord
                .order(Column("is_archived").asc, Column("created_at").desc)
                .fetchAll(db)
            return records.map { Self.recordToDomain($0) }
        }
    }

    public func getWallet(id: Int64) async throws -> TravelWallet? {
        try await database.writer.read { db in
            guard let record = try TravelWalletRecord.fetchOne(db, key: id) else {
                return nil
            }
            return Self.recordToDomain(record)
        }
    }

    public func insertWallet(_ wallet: TravelWallet) async throws -> Int64 {
        try await database.writer.write { db in
            var record = TravelWalletRecord(
                name: wallet.name,
                currencyCode: wallet.currencyCode.uppercased(),
                budgetAmountSubunits: wallet.budgetAmount?.subunits,
                note: wallet.note,
                colorHex: wallet.colorHex,
                iconName: wallet.iconName,
                isArchived: wallet.isArchived,
                createdAt: wallet.createdAt,
                updatedAt: wallet.updatedAt
            )
            try record.insert(db)
            return record.id ?? 0
        }
    }

    public func updateWallet(_ wallet: TravelWallet) async throws {
        try await database.writer.write { db in
            let now = Int64(Date().timeIntervalSince1970 * 1000)
            var record = TravelWalletRecord(
                id: wallet.id,
                name: wallet.name,
                currencyCode: wallet.currencyCode.uppercased(),
                budgetAmountSubunits: wallet.budgetAmount?.subunits,
                note: wallet.note,
                colorHex: wallet.colorHex,
                iconName: wallet.iconName,
                isArchived: wallet.isArchived,
                createdAt: wallet.createdAt,
                updatedAt: now
            )
            try record.update(db)
        }
    }

    public func deleteWallet(id: Int64) async throws {
        try await database.writer.write { db in
            // Unassign all transactions linked to this wallet safely
            try db.execute(
                sql: "UPDATE transactions SET travel_wallet_id = NULL WHERE travel_wallet_id = ?",
                arguments: [id]
            )
            _ = try TravelWalletRecord.deleteOne(db, key: id)
        }
    }

    private static func recordToDomain(_ r: TravelWalletRecord) -> TravelWallet {
        let budget = r.budgetAmountSubunits.map { Amount(subunits: $0) }
        return TravelWallet(
            id: r.id ?? 0,
            name: r.name,
            currencyCode: r.currencyCode,
            budgetAmount: budget,
            note: r.note,
            colorHex: r.colorHex,
            iconName: r.iconName,
            isArchived: r.isArchived,
            createdAt: r.createdAt,
            updatedAt: r.updatedAt
        )
    }
}

