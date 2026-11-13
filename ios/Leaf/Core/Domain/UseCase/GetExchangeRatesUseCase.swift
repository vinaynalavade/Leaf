import Foundation

/// UseCase retrieving exchange rates for the user's primary currency or all supported pairs.
public final class GetExchangeRatesUseCase: Sendable {

    private let exchangeRateRepository: ExchangeRateRepositoryProtocol
    private let preferencesRepository: UserPreferencesRepositoryProtocol

    public init(
        exchangeRateRepository: ExchangeRateRepositoryProtocol,
        preferencesRepository: UserPreferencesRepositoryProtocol
    ) {
        self.exchangeRateRepository = exchangeRateRepository
        self.preferencesRepository = preferencesRepository
    }

    public func execute(targetCurrencyCode: String? = nil) async throws -> [ExchangeRate] {
        let prefs = preferencesRepository.getUserPreferences()
        let target = (targetCurrencyCode ?? prefs.currencyCode).uppercased()

        var rates = try await exchangeRateRepository.getRatesForTargetCurrency(target)

        // If target rates are empty for a pair, supply fallback calibrated rates
        let supported = Currency.supportedCurrencies.filter { $0.code.uppercased() != target }
        for curr in supported {
            if !rates.contains(where: { $0.baseCurrencyCode == curr.code }) {
                let estimated = CurrencyConverter.estimatedRate(from: curr.code, to: target)
                let fallback = ExchangeRate(
                    baseCurrencyCode: curr.code,
                    targetCurrencyCode: target,
                    rate: estimated,
                    source: "CACHED"
                )
                rates.append(fallback)
            }
        }

        return rates.sorted { $0.baseCurrencyCode < $1.baseCurrencyCode }
    }
}

