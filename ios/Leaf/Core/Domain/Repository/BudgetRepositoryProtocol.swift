import Foundation

/// Repository protocol for creating, querying, and updating monthly spending budgets.
public protocol BudgetRepositoryProtocol: Sendable {
    func getBudgetsForMonth(year: Int, month: Int) async throws -> [Budget]
    func getAllBudgets() async throws -> [Budget]
    func getBudget(id: Int64) async throws -> Budget?
    func insertBudget(_ budget: Budget) async throws -> Int64
    func updateBudget(_ budget: Budget) async throws
    func deleteBudget(id: Int64) async throws
}

