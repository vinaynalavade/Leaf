import Foundation

/// UseCase responsible for validating and persisting updates to an existing transaction.
public final class UpdateTransactionUseCase: Sendable {

    private let transactionRepository: TransactionRepositoryProtocol
    private let categoryRepository: CategoryRepositoryProtocol

    public init(
        transactionRepository: TransactionRepositoryProtocol,
        categoryRepository: CategoryRepositoryProtocol
    ) {
        self.transactionRepository = transactionRepository
        self.categoryRepository = categoryRepository
    }

    public enum UpdateTransactionError: LocalizedError {
        case invalidAmount
        case invalidCategory
        case categoryNotFound
        case transactionNotFound

        public var errorDescription: String? {
            switch self {
            case .invalidAmount: return "Amount must be strictly greater than zero."
            case .invalidCategory: return "Please select a valid category."
            case .categoryNotFound: return "Selected category does not exist."
            case .transactionNotFound: return "Transaction not found."
            }
        }
    }

    public func execute(
        id: Int64,
        amount: Amount,
        type: TransactionType,
        categoryId: Int64,
        paymentMethod: PaymentMethod = .cash,
        note: String? = nil,
        timestamp: Int64,
        receiptImagePath: String? = nil,
        originalAmount: Amount? = nil,
        currencyCode: String? = nil,
        exchangeRate: Double? = nil,
        exchangeRateDate: Int64? = nil,
        exchangeRateSource: String? = nil,
        travelWalletId: Int64? = nil
    ) async throws {
        if amount.subunits <= 0 && (originalAmount?.subunits ?? 0) <= 0 {
            throw UpdateTransactionError.invalidAmount
        }

        if categoryId <= 0 {
            throw UpdateTransactionError.invalidCategory
        }

        guard let _ = try await categoryRepository.getCategory(id: categoryId) else {
            throw UpdateTransactionError.categoryNotFound
        }

        guard let existing = try await transactionRepository.getTransaction(id: id) else {
            throw UpdateTransactionError.transactionNotFound
        }

        let finalReceiptPath = receiptImagePath ?? existing.receiptImagePath
        let finalOriginalAmount = originalAmount ?? existing.originalAmount
        let finalCurrencyCode = currencyCode ?? existing.currencyCode
        let finalExchangeRate = exchangeRate ?? existing.exchangeRate
        let finalRateDate = exchangeRateDate ?? existing.exchangeRateDate
        let finalRateSource = exchangeRateSource ?? existing.exchangeRateSource
        let finalWalletId = travelWalletId ?? existing.travelWalletId

        let updated = Transaction(
            id: id,
            amount: amount,
            type: type,
            categoryId: categoryId,
            paymentMethod: paymentMethod,
            note: note?.trimmingCharacters(in: .whitespacesAndNewlines),
            timestamp: timestamp,
            createdAt: existing.createdAt,
            updatedAt: Int64(Date().timeIntervalSince1970 * 1000),
            isInternalTransfer: existing.isInternalTransfer,
            recurringTransactionId: existing.recurringTransactionId,
            receiptImagePath: finalReceiptPath,
            originalAmount: finalOriginalAmount,
            currencyCode: finalCurrencyCode,
            exchangeRate: finalExchangeRate,
            exchangeRateDate: finalRateDate,
            exchangeRateSource: finalRateSource,
            travelWalletId: finalWalletId
        )

        try await transactionRepository.updateTransaction(updated)
    }
}

