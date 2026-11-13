import Foundation

/// Repository protocol for storing, querying, and updating exchange rates.
public protocol ExchangeRateRepositoryProtocol: Sendable {
    func getExchangeRate(from baseCode: String, to targetCode: String) async throws -> ExchangeRate?
    func getAllExchangeRates() async throws -> [ExchangeRate]
    func getRatesForTargetCurrency(_ targetCode: String) async throws -> [ExchangeRate]
    func insertOrUpdateRate(_ rate: ExchangeRate) async throws
    func deleteRate(id: Int64) async throws
}

