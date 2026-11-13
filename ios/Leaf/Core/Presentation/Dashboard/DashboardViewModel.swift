import Foundation
import SwiftUI

/// Reactive Presentation state and business coordinator for Leaf's native iOS Dashboard.
@Observable
public final class DashboardViewModel: @unchecked Sendable {

    // MARK: - Published State
    public var summary: FinancialSummary = .empty
    public var monthlyIncome: Amount = .zero
    public var monthlyExpense: Amount = .zero
    public var cashBalance: Amount = .zero
    public var accountBalance: Amount = .zero
    public var featuredBudget: BudgetProgress? = nil
    public var activeGoals: [SavingsGoal] = []
    public var savingsSummary: SavingsGoalsSummary = .empty
    public var upcomingBillsSummary: UpcomingBillsSummary = .zero
    public var recentTransactions: [Transaction] = []
    public var isBalanceVisible: Bool = true
    public var selectedCurrency: Currency = .default
    public var profileName: String? = nil
    public var isLoading: Bool = false
    public var errorMessage: String? = nil

    // MARK: - Use Cases & Repositories
    private let getFinancialSummaryUseCase: GetFinancialSummaryUseCase
    private let getBudgetProgressUseCase: GetBudgetProgressUseCase
    private let getTransactionsUseCase: GetTransactionsUseCase
    private let deleteTransactionUseCase: DeleteTransactionUseCase
    private let getSavingsGoalsUseCase: GetSavingsGoalsUseCase?
    private let getUpcomingBillsUseCase: GetUpcomingBillsUseCase?
    private let markBillAsPaidUseCase: MarkBillAsPaidUseCase?
    private let preferencesRepository: UserPreferencesRepositoryProtocol

    public init(
        getFinancialSummaryUseCase: GetFinancialSummaryUseCase,
        getBudgetProgressUseCase: GetBudgetProgressUseCase,
        getTransactionsUseCase: GetTransactionsUseCase,
        deleteTransactionUseCase: DeleteTransactionUseCase,
        getSavingsGoalsUseCase: GetSavingsGoalsUseCase? = nil,
        getUpcomingBillsUseCase: GetUpcomingBillsUseCase? = nil,
        markBillAsPaidUseCase: MarkBillAsPaidUseCase? = nil,
        preferencesRepository: UserPreferencesRepositoryProtocol
    ) {
        self.getFinancialSummaryUseCase = getFinancialSummaryUseCase
        self.getBudgetProgressUseCase = getBudgetProgressUseCase
        self.getTransactionsUseCase = getTransactionsUseCase
        self.deleteTransactionUseCase = deleteTransactionUseCase
        self.getSavingsGoalsUseCase = getSavingsGoalsUseCase
        self.getUpcomingBillsUseCase = getUpcomingBillsUseCase
        self.markBillAsPaidUseCase = markBillAsPaidUseCase
        self.preferencesRepository = preferencesRepository

        // Initial sync of local preferences
        let prefs = preferencesRepository.getUserPreferences()
        self.isBalanceVisible = prefs.isBalanceVisible
        self.selectedCurrency = Currency.fromCode(prefs.currencyCode)
        self.profileName = prefs.profileName
    }

    /// Loads all dashboard data asynchronously with concurrency coordination.
    @MainActor
    public func loadData() async {
        isLoading = true
        errorMessage = nil

        let prefs = preferencesRepository.getUserPreferences()
        self.isBalanceVisible = prefs.isBalanceVisible
        self.selectedCurrency = Currency.fromCode(prefs.currencyCode)
        self.profileName = prefs.profileName

        let calendar = Calendar.current
        let now = Date()
        let currentYear = calendar.component(.year, from: now)
        let currentMonth = calendar.component(.month, from: now)

        do {
            async let summaryTask = getFinancialSummaryUseCase.execute()
            async let monthlyCashflowTask = getFinancialSummaryUseCase.executeForMonth(year: currentYear, month: currentMonth)
            async let budgetTask = getBudgetProgressUseCase.getFeaturedBudget(year: currentYear, month: currentMonth)
            async let recentTask = getTransactionsUseCase.getRecent(limit: 5)
            async let goalsTask = getSavingsGoalsUseCase?.getActiveGoals()
            async let goalsSummaryTask = getSavingsGoalsUseCase?.getSummary()
            async let billsTask = getUpcomingBillsUseCase?.execute(limit: 5)

            let (sum, cashflow, budget, recent) = try await (summaryTask, monthlyCashflowTask, budgetTask, recentTask)
            let (goals, gSummary, bills) = try await (goalsTask ?? [], goalsSummaryTask ?? .empty, billsTask ?? .zero)

            self.summary = sum
            self.monthlyIncome = cashflow.income
            self.monthlyExpense = cashflow.expense
            self.featuredBudget = budget
            self.recentTransactions = recent
            self.activeGoals = goals
            self.savingsSummary = gSummary
            self.upcomingBillsSummary = bills

            if let (cBal, aBal) = try? await getFinancialSummaryUseCase.executeForLedgers() {
                self.cashBalance = cBal
                self.accountBalance = aBal
            }

            self.isLoading = false

            // Synchronize snapshot to App Group storage for Home Screen Widgets
            let budgetLimit = budget?.budget.amount.subunits ?? 0
            let budgetSpent = budget?.usedAmount.subunits ?? 0
            let rawRatio = budget?.percentageUsed ?? 0.0
            let budgetRatio = rawRatio > 1.0 ? rawRatio / 100.0 : rawRatio
            let snapshot = WidgetFinancialSnapshot(
                currentBalanceSubunits: sum.currentBalance.subunits,
                monthlyIncomeSubunits: cashflow.income.subunits,
                monthlyExpenseSubunits: cashflow.expense.subunits,
                currencyCode: selectedCurrency.code,
                budgetLimitSubunits: budgetLimit,
                budgetSpentSubunits: budgetSpent,
                budgetProgressRatio: budgetRatio,
                lastUpdated: Date()
            )
            WidgetDataManager.shared.saveSnapshot(snapshot)
        } catch {
            self.errorMessage = error.localizedDescription
            self.isLoading = false
        }
    }

    /// Flips the privacy visibility state and persists the preference.
    public func toggleBalanceVisibility() {
        let newVisibility = !isBalanceVisible
        isBalanceVisible = newVisibility
        preferencesRepository.setBalanceVisible(newVisibility)
        WidgetDataManager.shared.setBalanceVisible(newVisibility)
    }

    /// Deletes a transaction from the ledger and immediately reloads dashboard data.
    @MainActor
    public func deleteTransaction(id: Int64) async {
        do {
            try await deleteTransactionUseCase.execute(id: id)
            await loadData()
        } catch {
            self.errorMessage = "Failed to delete transaction: \(error.localizedDescription)"
        }
    }

    /// Marks a bill occurrence as paid from the dashboard and immediately updates balances.
    @MainActor
    public func payBill(occurrenceId: Int64) async {
        do {
            _ = try await markBillAsPaidUseCase?.execute(occurrenceId: occurrenceId)
            await loadData()
        } catch {
            self.errorMessage = "Failed to mark bill as paid: \(error.localizedDescription)"
        }
    }
}

