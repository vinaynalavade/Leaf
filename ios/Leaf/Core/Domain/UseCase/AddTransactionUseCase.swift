import Foundation

public final class AddTransactionUseCase: Sendable {

    private let transactionRepository: TransactionRepositoryProtocol
    private let categoryRepository: CategoryRepositoryProtocol

    public init(
        transactionRepository: TransactionRepositoryProtocol,
        categoryRepository: CategoryRepositoryProtocol
    ) {
        self.transactionRepository = transactionRepository
        self.categoryRepository = categoryRepository
    }

    public enum AddTransactionError: LocalizedError {
        case invalidAmount
        case invalidCategory
        case categoryNotFound

        public var errorDescription: String? {
            switch self {
            case .invalidAmount: return "Amount must be strictly greater than zero."
            case .invalidCategory: return "Please select a valid category."
            case .categoryNotFound: return "Selected category does not exist."
            }
        }
    }

    public func execute(
        amount: Amount,
        type: TransactionType,
        categoryId: Int64,
        paymentMethod: PaymentMethod = .cash,
        note: String? = nil,
        timestamp: Int64 = Int64(Date().timeIntervalSince1970 * 1000),
        receiptImagePath: String? = nil,
        originalAmount: Amount? = nil,
        currencyCode: String = "INR",
        exchangeRate: Double = 1.0,
        exchangeRateDate: Int64? = nil,
        exchangeRateSource: String = "PRIMARY",
        travelWalletId: Int64? = nil
    ) async throws -> Int64 {
        if amount.subunits <= 0 && (originalAmount?.subunits ?? 0) <= 0 {
            throw AddTransactionError.invalidAmount
        }

        if categoryId <= 0 {
            throw AddTransactionError.invalidCategory
        }

        guard let _ = try await categoryRepository.getCategory(id: categoryId) else {
            throw AddTransactionError.categoryNotFound
        }

        let transaction = Transaction(
            amount: amount,
            type: type,
            categoryId: categoryId,
            paymentMethod: paymentMethod,
            note: note?.trimmingCharacters(in: .whitespacesAndNewlines),
            timestamp: timestamp,
            receiptImagePath: receiptImagePath,
            originalAmount: originalAmount ?? amount,
            currencyCode: currencyCode,
            exchangeRate: exchangeRate,
            exchangeRateDate: exchangeRateDate,
            exchangeRateSource: exchangeRateSource,
            travelWalletId: travelWalletId
        )

        return try await transactionRepository.insertTransaction(transaction)
    }
}

