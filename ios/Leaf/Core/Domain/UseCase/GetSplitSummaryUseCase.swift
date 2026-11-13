import Foundation

/// UseCase evaluating overall split statistics, net owed amounts, and active balances across all split expenses.
public final class GetSplitSummaryUseCase: Sendable {

    private let splitRepository: SplitRepositoryProtocol

    public init(splitRepository: SplitRepositoryProtocol) {
        self.splitRepository = splitRepository
    }

    public func execute() async throws -> GroupBalanceSummary {
        let allExpenses = try await splitRepository.getAllSplitExpenses()
        return NetBalanceEngine.calculateNetBalances(expenses: allExpenses)
    }
}

