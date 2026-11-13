import Foundation

public protocol SplitRepositoryProtocol: Sendable {
    func getAllSplitExpenses() async throws -> [SplitExpense]
    func getSplitExpense(id: Int64) async throws -> SplitExpense?
    func insertSplitExpense(_ split: SplitExpense) async throws -> Int64
    func updateSplitExpense(_ split: SplitExpense) async throws
    func deleteSplitExpense(id: Int64) async throws
    func settleParticipant(participantId: Int64, settledAt: Int64, settlementTransactionId: Int64?) async throws
    func unsettleParticipant(participantId: Int64) async throws

    // Partial payments & payment history
    func recordPayment(
        splitExpenseId: Int64,
        participantId: Int64,
        amount: Amount,
        paymentMethod: PaymentMethod,
        date: Int64,
        note: String?,
        createOffsetTransaction: Bool
    ) async throws -> SplitPayment

    func reversePayment(paymentId: Int64) async throws
    func getPaymentsForParticipant(participantId: Int64) async throws -> [SplitPayment]
    func getPaymentsForSplit(splitExpenseId: Int64) async throws -> [SplitPayment]

    // Split Groups
    func getAllSplitGroups() async throws -> [SplitGroup]
    func getSplitGroup(id: Int64) async throws -> SplitGroup?
    func insertSplitGroup(_ group: SplitGroup) async throws -> Int64
    func updateSplitGroup(_ group: SplitGroup) async throws
    func deleteSplitGroup(id: Int64) async throws
    func getSplitExpensesForGroup(groupId: Int64) async throws -> [SplitExpense]
}
