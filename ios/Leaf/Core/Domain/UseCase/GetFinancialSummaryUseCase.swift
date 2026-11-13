import Foundation

/// UseCase retrieving overall net balance and monthly cash flow metrics.
/// Accurately differentiates checking account liquid cash movements from ordinary earned income and expenses:
/// - Liquid checking balance includes all cash flows (earned income, ordinary expenses, savings deposits, and savings withdrawals).
/// - Income and Expense metrics strictly reflect ordinary economic transactions (excluding internal transfers).
public final class GetFinancialSummaryUseCase: Sendable {

    private let transactionRepository: TransactionRepositoryProtocol
    private let preferencesRepository: UserPreferencesRepositoryProtocol

    public init(
        transactionRepository: TransactionRepositoryProtocol,
        preferencesRepository: UserPreferencesRepositoryProtocol
    ) {
        self.transactionRepository = transactionRepository
        self.preferencesRepository = preferencesRepository
    }

    /// Fetches all-time aggregated financial summary including user's opening balance calibration.
    public func execute() async throws -> FinancialSummary {
        let prefs = preferencesRepository.getUserPreferences()
        let openingBalance = Amount(subunits: prefs.openingBalanceSubunits)

        // Liquid checking account cash movements (includes savings transfers)
        let totalInflow = try await transactionRepository.getTotalInflow(startEpoch: 0, endEpoch: Int64.max)
        let totalOutflow = try await transactionRepository.getTotalOutflow(startEpoch: 0, endEpoch: Int64.max)
        let currentBalance = openingBalance + (totalInflow - totalOutflow)

        // Strictly ordinary earned income and expenses (excluding internal transfers)
        let earnedIncome = try await transactionRepository.getTotalIncome(startEpoch: 0, endEpoch: Int64.max)
        let ordinaryExpense = try await transactionRepository.getTotalExpense(startEpoch: 0, endEpoch: Int64.max)
        let netChange = earnedIncome - ordinaryExpense

        let allTransactions = try await transactionRepository.getAllTransactions()

        return FinancialSummary(
            openingBalance: openingBalance,
            totalIncome: earnedIncome,
            totalExpense: ordinaryExpense,
            netChange: netChange,
            currentBalance: currentBalance,
            transactionCount: allTransactions.count
        )
    }

    /// Computes segregated Cash and Account ledger balances.
    /// Combined total strictly equals `currentBalance` without double counting.
    public func executeForLedgers() async throws -> (cashBalance: Amount, accountBalance: Amount) {
        let prefs = preferencesRepository.getUserPreferences()
        let opening = Amount(subunits: prefs.openingBalanceSubunits)
        let cash = try await transactionRepository.getBalance(for: .cash)
        let account = try await transactionRepository.getBalance(for: .account)
        return (cashBalance: cash, accountBalance: account + opening)
    }

    /// Fetches cash flow (ordinary earned income and ordinary expenses) for a specific calendar month and year.
    public func executeForMonth(year: Int, month: Int) async throws -> (income: Amount, expense: Amount) {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone.current

        var startComponents = DateComponents()
        startComponents.year = year
        startComponents.month = month
        startComponents.day = 1
        startComponents.hour = 0
        startComponents.minute = 0
        startComponents.second = 0

        guard let startDate = calendar.date(from: startComponents),
              let range = calendar.range(of: .day, in: .month, for: startDate) else {
            return (.zero, .zero)
        }

        var endComponents = DateComponents()
        endComponents.year = year
        endComponents.month = month
        endComponents.day = range.count
        endComponents.hour = 23
        endComponents.minute = 59
        endComponents.second = 59

        guard let endDate = calendar.date(from: endComponents) else {
            return (.zero, .zero)
        }

        let startEpoch = Int64(startDate.timeIntervalSince1970 * 1000)
        let endEpoch = Int64(endDate.timeIntervalSince1970 * 1000)

        let income = try await transactionRepository.getTotalIncome(startEpoch: startEpoch, endEpoch: endEpoch)
        let expense = try await transactionRepository.getTotalExpense(startEpoch: startEpoch, endEpoch: endEpoch)

        return (income, expense)
    }
}
