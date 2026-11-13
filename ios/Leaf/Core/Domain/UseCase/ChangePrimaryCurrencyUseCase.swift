import Foundation

/// UseCase safely transitioning the user's primary application currency.
/// Adheres to fintech accounting rules: preserves all original transaction amounts and currencies,
/// and recalculates primary-currency equivalents using exchange rates relative to the new primary currency.
public final class ChangePrimaryCurrencyUseCase: Sendable {

    private let transactionRepository: TransactionRepositoryProtocol
    private let exchangeRateRepository: ExchangeRateRepositoryProtocol
    private let preferencesRepository: UserPreferencesRepositoryProtocol

    public init(
        transactionRepository: TransactionRepositoryProtocol,
        exchangeRateRepository: ExchangeRateRepositoryProtocol,
        preferencesRepository: UserPreferencesRepositoryProtocol
    ) {
        self.transactionRepository = transactionRepository
        self.exchangeRateRepository = exchangeRateRepository
        self.preferencesRepository = preferencesRepository
    }

    public func execute(newCurrencyCode: String) async throws {
        let cleanNewCode = newCurrencyCode.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        let newCurrency = Currency.fromCode(cleanNewCode)

        let allTransactions = try await transactionRepository.getAllTransactions()

        for tx in allTransactions {
            let txCurrency = Currency.fromCode(tx.currencyCode)

            let updatedAmount: Amount
            let updatedRate: Double
            let updatedSource: String

            if tx.currencyCode.caseInsensitiveCompare(cleanNewCode) == .orderedSame {
                // Transaction was already in the new primary currency
                updatedAmount = tx.originalAmount
                updatedRate = 1.0
                updatedSource = "PRIMARY"
            } else {
                // Look up exchange rate to the new primary currency
                let rateObj = try? await exchangeRateRepository.getExchangeRate(from: tx.currencyCode, to: cleanNewCode)
                let rate = rateObj?.rate ?? CurrencyConverter.estimatedRate(from: tx.currencyCode, to: cleanNewCode)

                updatedAmount = CurrencyConverter.convert(
                    amount: tx.originalAmount,
                    from: txCurrency,
                    to: newCurrency,
                    rate: rate
                )
                updatedRate = rate
                updatedSource = "RECALCULATED"
            }

            let updatedTransaction = Transaction(
                id: tx.id,
                amount: updatedAmount,
                type: tx.type,
                categoryId: tx.categoryId,
                category: tx.category,
                paymentMethod: tx.paymentMethod,
                note: tx.note,
                timestamp: tx.timestamp,
                createdAt: tx.createdAt,
                updatedAt: Int64(Date().timeIntervalSince1970 * 1000),
                isInternalTransfer: tx.isInternalTransfer,
                recurringTransactionId: tx.recurringTransactionId,
                receiptImagePath: tx.receiptImagePath,
                originalAmount: tx.originalAmount,
                currencyCode: tx.currencyCode,
                exchangeRate: updatedRate,
                exchangeRateDate: Int64(Date().timeIntervalSince1970 * 1000),
                exchangeRateSource: updatedSource,
                travelWalletId: tx.travelWalletId
            )

            try await transactionRepository.updateTransaction(updatedTransaction)
        }

        // Update stored primary currency code in preferences
        preferencesRepository.setCurrencyCode(cleanNewCode)
    }
}

