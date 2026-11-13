import Foundation

/// UseCase validating and persisting new or edited travel wallets.
public final class SaveTravelWalletUseCase: Sendable {

    private let walletRepository: TravelWalletRepositoryProtocol

    public init(walletRepository: TravelWalletRepositoryProtocol) {
        self.walletRepository = walletRepository
    }

    public enum SaveWalletError: LocalizedError {
        case emptyName
        case invalidCurrency

        public var errorDescription: String? {
            switch self {
            case .emptyName: return "Wallet name cannot be empty."
            case .invalidCurrency: return "Please select a valid currency."
            }
        }
    }

    public func execute(
        id: Int64? = nil,
        name: String,
        currencyCode: String,
        budgetAmount: Amount? = nil,
        note: String? = nil,
        colorHex: String = "#10B981",
        iconName: String = "airplane",
        isArchived: Bool = false
    ) async throws -> Int64 {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            throw SaveWalletError.emptyName
        }

        let cleanCurrency = currencyCode.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        guard !cleanCurrency.isEmpty else {
            throw SaveWalletError.invalidCurrency
        }

        let wallet = TravelWallet(
            id: id ?? 0,
            name: trimmedName,
            currencyCode: cleanCurrency,
            budgetAmount: budgetAmount,
            note: note?.trimmingCharacters(in: .whitespacesAndNewlines),
            colorHex: colorHex,
            iconName: iconName,
            isArchived: isArchived
        )

        if let existingId = id, existingId > 0 {
            try await walletRepository.updateWallet(wallet)
            return existingId
        } else {
            return try await walletRepository.insertWallet(wallet)
        }
    }
}

