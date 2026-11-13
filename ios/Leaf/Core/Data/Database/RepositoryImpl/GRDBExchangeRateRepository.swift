import Foundation
import GRDB

public final class GRDBExchangeRateRepository: ExchangeRateRepositoryProtocol, Sendable {

    private let database: AppDatabase

    public init(database: AppDatabase) {
        self.database = database
    }

    public func getExchangeRate(from baseCode: String, to targetCode: String) async throws -> ExchangeRate? {
        try await database.writer.read { db in
            guard let record = try ExchangeRateRecord
                .filter(Column("base_currency_code") == baseCode.uppercased() && Column("target_currency_code") == targetCode.uppercased())
                .order(Column("effective_date").desc)
                .fetchOne(db) else {
                return nil
            }
            return Self.recordToDomain(record)
        }
    }

    public func getAllExchangeRates() async throws -> [ExchangeRate] {
        try await database.writer.read { db in
            let records = try ExchangeRateRecord
                .order(Column("target_currency_code"), Column("base_currency_code"))
                .fetchAll(db)
            return records.map { Self.recordToDomain($0) }
        }
    }

    public func getRatesForTargetCurrency(_ targetCode: String) async throws -> [ExchangeRate] {
        try await database.writer.read { db in
            let records = try ExchangeRateRecord
                .filter(Column("target_currency_code") == targetCode.uppercased())
                .order(Column("base_currency_code"))
                .fetchAll(db)
            return records.map { Self.recordToDomain($0) }
        }
    }

    public func insertOrUpdateRate(_ rate: ExchangeRate) async throws {
        try await database.writer.write { db in
            // If an existing rate for this pair exists, update it, otherwise insert
            if var existing = try ExchangeRateRecord
                .filter(Column("base_currency_code") == rate.baseCurrencyCode.uppercased() && Column("target_currency_code") == rate.targetCurrencyCode.uppercased())
                .fetchOne(db) {
                existing.rate = rate.rate
                existing.effectiveDate = rate.effectiveDate
                existing.source = rate.source
                try existing.update(db)
            } else {
                var record = ExchangeRateRecord(
                    baseCurrencyCode: rate.baseCurrencyCode.uppercased(),
                    targetCurrencyCode: rate.targetCurrencyCode.uppercased(),
                    rate: rate.rate,
                    effectiveDate: rate.effectiveDate,
                    source: rate.source,
                    createdAt: rate.createdAt
                )
                try record.insert(db)
            }
        }
    }

    public func deleteRate(id: Int64) async throws {
        try await database.writer.write { db in
            _ = try ExchangeRateRecord.deleteOne(db, key: id)
        }
    }

    private static func recordToDomain(_ r: ExchangeRateRecord) -> ExchangeRate {
        ExchangeRate(
            id: r.id,
            baseCurrencyCode: r.baseCurrencyCode,
            targetCurrencyCode: r.targetCurrencyCode,
            rate: r.rate,
            effectiveDate: r.effectiveDate,
            source: r.source,
            createdAt: r.createdAt
        )
    }
}

