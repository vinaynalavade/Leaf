import Foundation

public protocol TransactionRepositoryProtocol: Sendable {
    func getAllTransactions() async throws -> [Transaction]
    func getTransaction(id: Int64) async throws -> Transaction?
    func getTransactionsBetween(startEpoch: Int64, endEpoch: Int64) async throws -> [Transaction]
    func getTransactionsForWallet(walletId: Int64) async throws -> [Transaction]
    func getTransactionsByCurrency(currencyCode: String) async throws -> [Transaction]
    func insertTransaction(_ transaction: Transaction) async throws -> Int64
    func updateTransaction(_ transaction: Transaction) async throws
    func deleteTransaction(id: Int64) async throws

    /// Net liquid checking account balance change.
    func getNetBalance() async throws -> Amount

    /// Ordinary expenses only (strictly excludes internal transfers like savings deposits).
    func getTotalExpense(startEpoch: Int64, endEpoch: Int64) async throws -> Amount

    /// Ordinary earned income only (strictly excludes internal transfers like savings withdrawals).
    func getTotalIncome(startEpoch: Int64, endEpoch: Int64) async throws -> Amount

    /// Total cash entering checking account (includes ordinary income and savings withdrawals).
    func getTotalInflow(startEpoch: Int64, endEpoch: Int64) async throws -> Amount

    /// Total cash leaving checking account (includes ordinary expenses and savings deposits).
    func getTotalOutflow(startEpoch: Int64, endEpoch: Int64) async throws -> Amount

    // MARK: - Independent Ledger Management (Cash & Account)
    func getBalance(for paymentMethod: PaymentMethod) async throws -> Amount
    func getInflow(for paymentMethod: PaymentMethod, startEpoch: Int64, endEpoch: Int64) async throws -> Amount
    func getOutflow(for paymentMethod: PaymentMethod, startEpoch: Int64, endEpoch: Int64) async throws -> Amount
    func getTransactions(for paymentMethod: PaymentMethod) async throws -> [Transaction]
    func transferBetweenLedgers(from source: PaymentMethod, to destination: PaymentMethod, amount: Amount, note: String?, timestamp: Int64) async throws -> (outflowId: Int64, inflowId: Int64)
    func reverseTransfer(transactionId: Int64) async throws -> (outflowId: Int64, inflowId: Int64)
}

public extension TransactionRepositoryProtocol {
    func getTotalIncome(startEpoch: Int64, endEpoch: Int64, excludeInternalTransfers: Bool) async throws -> Amount {
        try await getTotalIncome(startEpoch: startEpoch, endEpoch: endEpoch)
    }
}
