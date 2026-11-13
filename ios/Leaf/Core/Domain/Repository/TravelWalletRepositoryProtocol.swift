import Foundation

/// Repository protocol for managing Travel Wallets and retrieving wallet-scoped financial records.
public protocol TravelWalletRepositoryProtocol: Sendable {
    func getAllWallets() async throws -> [TravelWallet]
    func getWallet(id: Int64) async throws -> TravelWallet?
    func insertWallet(_ wallet: TravelWallet) async throws -> Int64
    func updateWallet(_ wallet: TravelWallet) async throws
    func deleteWallet(id: Int64) async throws
}

