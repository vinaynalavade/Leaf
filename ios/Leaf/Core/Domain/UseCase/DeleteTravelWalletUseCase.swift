import Foundation

/// UseCase safely deleting a travel wallet without losing financial transactions.
public final class DeleteTravelWalletUseCase: Sendable {

    private let walletRepository: TravelWalletRepositoryProtocol

    public init(walletRepository: TravelWalletRepositoryProtocol) {
        self.walletRepository = walletRepository
    }

    public func execute(id: Int64) async throws {
        try await walletRepository.deleteWallet(id: id)
    }
}

