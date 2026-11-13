import Foundation
import SwiftUI

public enum PlanningSection: String, CaseIterable, Identifiable, Sendable {
    case budgets = "Budgets"
    case savingsGoals = "Savings Goals"

    public var id: String { rawValue }
}

@Observable
public final class PlanningViewModel: @unchecked Sendable {

    // MARK: - Published State
    public var selectedSection: PlanningSection = .budgets
    public var selectedYear: Int
    public var selectedMonth: Int
    public var selectedPeriodFilter: BudgetPeriodType? = nil

    public var budgetProgressList: [BudgetProgress] = []
    public var activeGoals: [SavingsGoal] = []
    public var archivedGoals: [SavingsGoal] = []
    public var savingsSummary: SavingsGoalsSummary = .empty

    public var currency: Currency = .default
    public var isLoading: Bool = false
    public var errorMessage: String? = nil

    // Sheets & Dialogs
    public var isCreateBudgetSheetPresented: Bool = false
    public var isCreateGoalSheetPresented: Bool = false
    public var selectedBudgetForDetail: BudgetProgress? = nil
    public var selectedGoalForDetail: SavingsGoal? = nil
    public var selectedGoalForContribution: SavingsGoal? = nil
    public var selectedGoalForWithdrawal: SavingsGoal? = nil

    // MARK: - Dependencies
    public let getBudgetProgressUseCase: GetBudgetProgressUseCase
    public let saveBudgetUseCase: SaveBudgetUseCase
    public let deleteBudgetUseCase: DeleteBudgetUseCase
    public let getSavingsGoalsUseCase: GetSavingsGoalsUseCase
    public let saveSavingsGoalUseCase: SaveSavingsGoalUseCase
    public let deleteSavingsGoalUseCase: DeleteSavingsGoalUseCase
    public let setSavingsGoalArchivedUseCase: SetSavingsGoalArchivedUseCase
    public let recordSavingsContributionUseCase: RecordSavingsContributionUseCase
    public let reverseSavingsContributionUseCase: ReverseSavingsContributionUseCase
    public let recordSavingsWithdrawalUseCase: RecordSavingsWithdrawalUseCase
    public let reverseSavingsWithdrawalUseCase: ReverseSavingsWithdrawalUseCase
    public let preferencesRepository: UserPreferencesRepositoryProtocol

    public init(
        getBudgetProgressUseCase: GetBudgetProgressUseCase,
        saveBudgetUseCase: SaveBudgetUseCase,
        deleteBudgetUseCase: DeleteBudgetUseCase,
        getSavingsGoalsUseCase: GetSavingsGoalsUseCase,
        saveSavingsGoalUseCase: SaveSavingsGoalUseCase,
        deleteSavingsGoalUseCase: DeleteSavingsGoalUseCase,
        setSavingsGoalArchivedUseCase: SetSavingsGoalArchivedUseCase,
        recordSavingsContributionUseCase: RecordSavingsContributionUseCase,
        reverseSavingsContributionUseCase: ReverseSavingsContributionUseCase,
        recordSavingsWithdrawalUseCase: RecordSavingsWithdrawalUseCase,
        reverseSavingsWithdrawalUseCase: ReverseSavingsWithdrawalUseCase,
        preferencesRepository: UserPreferencesRepositoryProtocol
    ) {
        self.getBudgetProgressUseCase = getBudgetProgressUseCase
        self.saveBudgetUseCase = saveBudgetUseCase
        self.deleteBudgetUseCase = deleteBudgetUseCase
        self.getSavingsGoalsUseCase = getSavingsGoalsUseCase
        self.saveSavingsGoalUseCase = saveSavingsGoalUseCase
        self.deleteSavingsGoalUseCase = deleteSavingsGoalUseCase
        self.setSavingsGoalArchivedUseCase = setSavingsGoalArchivedUseCase
        self.recordSavingsContributionUseCase = recordSavingsContributionUseCase
        self.reverseSavingsContributionUseCase = reverseSavingsContributionUseCase
        self.recordSavingsWithdrawalUseCase = recordSavingsWithdrawalUseCase
        self.reverseSavingsWithdrawalUseCase = reverseSavingsWithdrawalUseCase
        self.preferencesRepository = preferencesRepository

        let now = Date()
        let cal = Calendar.current
        self.selectedYear = cal.component(.year, from: now)
        self.selectedMonth = cal.component(.month, from: now)

        let prefs = preferencesRepository.getUserPreferences()
        self.currency = Currency.fromCode(prefs.currencyCode)
    }

    // MARK: - Filtered Budgets

    public var displayedBudgets: [BudgetProgress] {
        guard let filter = selectedPeriodFilter else {
            return budgetProgressList
        }
        return budgetProgressList.filter { $0.budget.periodType == filter }
    }

    // MARK: - Computed Budget Overview Metrics

    public var totalAllocatedBudget: Amount {
        if let overall = displayedBudgets.first(where: { $0.budget.isOverallBudget }) {
            return overall.budget.amount
        }
        let total = displayedBudgets.reduce(Int64(0)) { $0 + $1.budget.amount.subunits }
        return Amount(subunits: total)
    }

    public var totalBudgetSpent: Amount {
        if let overall = displayedBudgets.first(where: { $0.budget.isOverallBudget }) {
            return overall.usedAmount
        }
        let total = displayedBudgets.reduce(Int64(0)) { $0 + $1.usedAmount.subunits }
        return Amount(subunits: total)
    }

    public var totalBudgetRemaining: Amount {
        Amount(subunits: max(0, totalAllocatedBudget.subunits - totalBudgetSpent.subunits))
    }

    public var overallBudgetPercentage: Double {
        guard totalAllocatedBudget.subunits > 0 else { return 0.0 }
        let fraction = Double(totalBudgetSpent.subunits) / Double(totalAllocatedBudget.subunits)
        return fraction * 100.0
    }

    public var overallBudgetStatus: BudgetStatus {
        let budgetSubunits = totalAllocatedBudget.subunits
        guard budgetSubunits > 0 else { return .onTrack }

        let usedSubunits = totalBudgetSpent.subunits
        let threshold75 = (budgetSubunits * 75) / 100

        if usedSubunits < threshold75 {
            return .onTrack
        } else if usedSubunits < budgetSubunits {
            return .approachingLimit
        } else if usedSubunits == budgetSubunits {
            return .limitReached
        } else {
            return .overBudget
        }
    }

    public var formattedPeriodTitle: String {
        var comps = DateComponents()
        comps.year = selectedYear
        comps.month = selectedMonth
        comps.day = 1
        let date = Calendar.current.date(from: comps) ?? Date()

        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: date)
    }

    // MARK: - Actions

    @MainActor
    public func loadData() async {
        isLoading = true
        errorMessage = nil

        let prefs = preferencesRepository.getUserPreferences()
        self.currency = Currency.fromCode(prefs.currencyCode)

        do {
            async let budgetTask = getBudgetProgressUseCase.execute(year: selectedYear, month: selectedMonth)
            async let activeGoalsTask = getSavingsGoalsUseCase.getActiveGoals()
            async let archivedGoalsTask = getSavingsGoalsUseCase.getArchivedGoals()
            async let summaryTask = getSavingsGoalsUseCase.getSummary()

            let (budgets, active, archived, summary) = try await (budgetTask, activeGoalsTask, archivedGoalsTask, summaryTask)

            self.budgetProgressList = budgets
            self.activeGoals = active
            self.archivedGoals = archived
            self.savingsSummary = summary
            self.isLoading = false
        } catch {
            self.errorMessage = error.localizedDescription
            self.isLoading = false
        }
    }

    public func goToPreviousMonth() {
        if selectedMonth == 1 {
            selectedMonth = 12
            selectedYear -= 1
        } else {
            selectedMonth -= 1
        }
        Task { await loadData() }
    }

    public func goToNextMonth() {
        if selectedMonth == 12 {
            selectedMonth = 1
            selectedYear += 1
        } else {
            selectedMonth += 1
        }
        Task { await loadData() }
    }

    public func goToCurrentMonth() {
        let cal = Calendar.current
        let now = Date()
        selectedYear = cal.component(.year, from: now)
        selectedMonth = cal.component(.month, from: now)
        Task { await loadData() }
    }

    @MainActor
    public func deleteBudget(id: Int64) async {
        do {
            try await deleteBudgetUseCase.execute(id: id)
            await loadData()
        } catch {
            errorMessage = "Failed to delete budget: \(error.localizedDescription)"
        }
    }

    @MainActor
    public func deleteGoal(id: Int64) async {
        do {
            try await deleteSavingsGoalUseCase.execute(id: id)
            await loadData()
        } catch {
            errorMessage = "Failed to delete goal: \(error.localizedDescription)"
        }
    }

    @MainActor
    public func toggleGoalArchived(id: Int64, isArchived: Bool) async {
        do {
            try await setSavingsGoalArchivedUseCase.execute(id: id, isArchived: isArchived)
            await loadData()
        } catch {
            errorMessage = "Failed to update goal: \(error.localizedDescription)"
        }
    }

    @MainActor
    public func recordContribution(
        goalId: Int64,
        amount: Amount,
        note: String?,
        timestamp: Int64,
        createTransaction: Bool,
        paymentMethod: PaymentMethod
    ) async {
        do {
            try await recordSavingsContributionUseCase.execute(
                goalId: goalId,
                amount: amount,
                note: note,
                timestamp: timestamp,
                createTransaction: createTransaction,
                paymentMethod: paymentMethod
            )
            await loadData()
        } catch {
            errorMessage = "Contribution failed: \(error.localizedDescription)"
        }
    }

    @MainActor
    public func recordWithdrawal(
        goalId: Int64,
        amount: Amount,
        note: String?,
        timestamp: Int64,
        returnToAccount: Bool,
        paymentMethod: PaymentMethod
    ) async {
        do {
            try await recordSavingsWithdrawalUseCase.execute(
                goalId: goalId,
                amount: amount,
                note: note,
                timestamp: timestamp,
                returnToAccount: returnToAccount,
                paymentMethod: paymentMethod
            )
            await loadData()
        } catch {
            errorMessage = "Withdrawal failed: \(error.localizedDescription)"
        }
    }

    @MainActor
    public func reverseContribution(id: Int64) async {
        do {
            try await reverseSavingsContributionUseCase.execute(contributionId: id)
            await loadData()
        } catch {
            errorMessage = "Reversal failed: \(error.localizedDescription)"
        }
    }
}
