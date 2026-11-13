import Foundation

/// Repository protocol for creating, updating, archiving, contributing to, and withdrawing from savings goals.
public protocol SavingsGoalRepositoryProtocol: Sendable {
    func getActiveGoals() async throws -> [SavingsGoal]
    func getArchivedGoals() async throws -> [SavingsGoal]
    func getAllGoals() async throws -> [SavingsGoal]
    func getGoal(id: Int64) async throws -> SavingsGoal?
    func insertGoal(_ goal: SavingsGoal, initialContribution: Amount?) async throws -> Int64
    func updateGoal(_ goal: SavingsGoal) async throws
    func deleteGoal(id: Int64) async throws
    func setGoalArchived(id: Int64, isArchived: Bool) async throws

    func addContribution(
        goalId: Int64,
        amount: Amount,
        note: String?,
        timestamp: Int64,
        createTransaction: Bool,
        paymentMethod: PaymentMethod
    ) async throws -> SavingsGoalContribution

    func addWithdrawal(
        goalId: Int64,
        amount: Amount,
        note: String?,
        timestamp: Int64,
        returnToAccount: Bool,
        paymentMethod: PaymentMethod
    ) async throws -> SavingsGoalContribution

    func deleteContribution(id: Int64) async throws
    func getContributions(goalId: Int64) async throws -> [SavingsGoalContribution]
}
