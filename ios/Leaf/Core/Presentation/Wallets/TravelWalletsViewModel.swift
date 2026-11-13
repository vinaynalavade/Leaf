import Foundation
import SwiftUI

/// Observable coordinator managing Travel Wallets presentation state, wallet summaries, and mutations.
@Observable
public final class TravelWalletsViewModel: @unchecked Sendable {

    // MARK: - Dependencies
    private let getTravelWalletsUseCase: GetTravelWalletsUseCase
    private let saveTravelWalletUseCase: SaveTravelWalletUseCase
    private let deleteTravelWalletUseCase: DeleteTravelWalletUseCase
    private let preferencesRepository: UserPreferencesRepositoryProtocol

    // MARK: - Presentation State
    public var walletSummaries: [TravelWalletSummary] = []
    public var primaryCurrency: Currency = .default
    public var isLoading: Bool = false
    public var errorMessage: String? = nil

    // Sheets & Dialogs
    public var isCreateSheetPresented: Bool = false
    public var walletToEdit: TravelWallet? = nil
    public var walletToDelete: TravelWalletSummary? = nil

    public init(
        getTravelWalletsUseCase: GetTravelWalletsUseCase,
        saveTravelWalletUseCase: SaveTravelWalletUseCase,
        deleteTravelWalletUseCase: DeleteTravelWalletUseCase,
        preferencesRepository: UserPreferencesRepositoryProtocol
    ) {
        self.getTravelWalletsUseCase = getTravelWalletsUseCase
        self.saveTravelWalletUseCase = saveTravelWalletUseCase
        self.deleteTravelWalletUseCase = deleteTravelWalletUseCase
        self.preferencesRepository = preferencesRepository
    }

    @MainActor
    public func loadData() async {
        isLoading = true
        errorMessage = nil

        do {
            let prefs = preferencesRepository.getUserPreferences()
            self.primaryCurrency = Currency.fromCode(prefs.currencyCode)
            self.walletSummaries = try await getTravelWalletsUseCase.execute()
        } catch {
            self.errorMessage = "Failed to load travel wallets: \(error.localizedDescription)"
        }

        isLoading = false
    }

    @MainActor
    public func saveWallet(
        id: Int64?,
        name: String,
        currencyCode: String,
        budgetAmount: Amount?,
        note: String?,
        colorHex: String,
        iconName: String
    ) async -> Bool {
        do {
            _ = try await saveTravelWalletUseCase.execute(
                id: id,
                name: name,
                currencyCode: currencyCode,
                budgetAmount: budgetAmount,
                note: note,
                colorHex: colorHex,
                iconName: iconName
            )
            await loadData()
            return true
        } catch {
            self.errorMessage = error.localizedDescription
            return false
        }
    }

    @MainActor
    public func deleteWallet(id: Int64) async {
        do {
            try await deleteTravelWalletUseCase.execute(id: id)
            self.walletToDelete = nil
            await loadData()
        } catch {
            self.errorMessage = "Failed to delete wallet: \(error.localizedDescription)"
        }
    }

    @MainActor
    public func toggleArchive(wallet: TravelWallet) async {
        _ = try? await saveTravelWalletUseCase.execute(
            id: wallet.id,
            name: wallet.name,
            currencyCode: wallet.currencyCode,
            budgetAmount: wallet.budgetAmount,
            note: wallet.note,
            colorHex: wallet.colorHex,
            iconName: wallet.iconName,
            isArchived: !wallet.isArchived
        )
        await loadData()
    }
}

