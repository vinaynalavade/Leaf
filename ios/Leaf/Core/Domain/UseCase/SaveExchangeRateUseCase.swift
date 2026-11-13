import Foundation

/// UseCase validating and persisting manual exchange rates entered by the user.
public final class SaveExchangeRateUseCase: Sendable {

    private let exchangeRateRepository: ExchangeRateRepositoryProtocol

    public init(exchangeRateRepository: ExchangeRateRepositoryProtocol) {
        self.exchangeRateRepository = exchangeRateRepository
    }

    public enum SaveRateError: LocalizedError {
        case invalidRate
        case identicalCurrencies

        public var errorDescription: String? {
            switch self {
            case .invalidRate:
                return "Exchange rate must be strictly greater than zero."
            case .identicalCurrencies:
                return "Base and target currencies cannot be the same."
            }
        }
    }

    public func execute(
        baseCode: String,
        targetCode: String,
        rate: Double
    ) async throws {
        let cleanBase = baseCode.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        let cleanTarget = targetCode.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()

        guard cleanBase != cleanTarget else {
            throw SaveRateError.identicalCurrencies
        }

        guard rate > 0.0 else {
            throw SaveRateError.invalidRate
        }

        let model = ExchangeRate(
            baseCurrencyCode: cleanBase,
            targetCurrencyCode: cleanTarget,
            rate: rate,
            effectiveDate: Int64(Date().timeIntervalSince1970 * 1000),
            source: "MANUAL"
        )

        try await exchangeRateRepository.insertOrUpdateRate(model)
    }
}

