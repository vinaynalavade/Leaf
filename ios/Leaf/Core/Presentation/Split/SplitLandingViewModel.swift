import Foundation
import SwiftUI

public enum SplitFilterOption: String, CaseIterable, Identifiable, Sendable {
    case active = "Active"
    case all = "All"
    case settled = "Settled"

    public var id: String { rawValue }
}

public enum SplitLandingTab: String, CaseIterable, Identifiable, Sendable {
    case expenses = "Expenses"
    case groups = "Groups"

    public var id: String { rawValue }
}

/// Observable coordinator managing the Split & Collect landing screen state, group tabs, and list operations.
@Observable
public final class SplitLandingViewModel: @unchecked Sendable {

    // MARK: - Dependencies
    private let splitRepository: SplitRepositoryProtocol
    private let getSplitSummaryUseCase: GetSplitSummaryUseCase
    private let deleteSplitExpenseUseCase: DeleteSplitExpenseUseCase
    private let preferencesRepository: UserPreferencesRepositoryProtocol
    private let getSplitGroupsUseCase: GetSplitGroupsUseCase
    private let saveSplitGroupUseCase: SaveSplitGroupUseCase
    private let deleteSplitGroupUseCase: DeleteSplitGroupUseCase

    // MARK: - Presentation State
    public var selectedTab: SplitLandingTab = .expenses
    public var allSplits: [SplitExpense] = []
    public var filteredSplits: [SplitExpense] = []
    public var groups: [SplitGroupSummary] = []
    public var filteredGroups: [SplitGroupSummary] = []
    public var balanceSummary: GroupBalanceSummary = .empty
    public var selectedCurrency: Currency = .default
    public var selectedFilter: SplitFilterOption = .active
    public var searchQuery: String = ""

    public var isLoading: Bool = false
    public var errorMessage: String? = nil

    // MARK: - Navigation & Sheets
    public var isCreateSheetPresented: Bool = false
    public var isCreateGroupSheetPresented: Bool = false
    public var selectedSplitForDetail: SplitExpense? = nil
    public var selectedGroupForDetail: SplitGroupSummary? = nil
    public var selectedGroupIdForDetail: Int64? = nil
    public var splitToDelete: SplitExpense? = nil
    public var groupToDelete: SplitGroupSummary? = nil

    public init(
        splitRepository: SplitRepositoryProtocol,
        getSplitSummaryUseCase: GetSplitSummaryUseCase,
        deleteSplitExpenseUseCase: DeleteSplitExpenseUseCase,
        preferencesRepository: UserPreferencesRepositoryProtocol,
        getSplitGroupsUseCase: GetSplitGroupsUseCase,
        saveSplitGroupUseCase: SaveSplitGroupUseCase,
        deleteSplitGroupUseCase: DeleteSplitGroupUseCase
    ) {
        self.splitRepository = splitRepository
        self.getSplitSummaryUseCase = getSplitSummaryUseCase
        self.deleteSplitExpenseUseCase = deleteSplitExpenseUseCase
        self.preferencesRepository = preferencesRepository
        self.getSplitGroupsUseCase = getSplitGroupsUseCase
        self.saveSplitGroupUseCase = saveSplitGroupUseCase
        self.deleteSplitGroupUseCase = deleteSplitGroupUseCase
    }

    @MainActor
    public func loadData() async {
        isLoading = true
        errorMessage = nil

        do {
            let prefs = try await preferencesRepository.getUserPreferences()
            self.selectedCurrency = Currency.fromCode(prefs.currencyCode)

            self.allSplits = try await splitRepository.getAllSplitExpenses()
            self.balanceSummary = try await getSplitSummaryUseCase.execute()
            self.groups = try await getSplitGroupsUseCase.execute()
            applyFilter()
        } catch {
            self.errorMessage = "Failed to load split expenses: \(error.localizedDescription)"
        }

        isLoading = false
    }

    @MainActor
    public func setFilter(_ filter: SplitFilterOption) {
        self.selectedFilter = filter
        applyFilter()
    }

    @MainActor
    public func setSelectedTab(_ tab: SplitLandingTab) {
        self.selectedTab = tab
    }

    @MainActor
    public func updateSearchQuery(_ query: String) {
        self.searchQuery = query
        applyFilter()
    }

    @MainActor
    public func deleteSplit(id: Int64) async {
        do {
            try await deleteSplitExpenseUseCase.execute(id: id)
            self.splitToDelete = nil
            await loadData()
        } catch {
            self.errorMessage = "Failed to delete split: \(error.localizedDescription)"
        }
    }

    @MainActor
    public func createGroup(name: String, iconName: String, colorHex: String) async {
        do {
            _ = try await saveSplitGroupUseCase.execute(
                id: 0,
                name: name,
                iconName: iconName,
                colorHex: colorHex
            )
            self.isCreateGroupSheetPresented = false
            await loadData()
        } catch {
            self.errorMessage = "Failed to create group: \(error.localizedDescription)"
        }
    }

    @MainActor
    public func deleteGroup(id: Int64) async {
        do {
            try await deleteSplitGroupUseCase.execute(id: id)
            self.groupToDelete = nil
            await loadData()
        } catch {
            self.errorMessage = "Failed to delete group: \(error.localizedDescription)"
        }
    }

    private func applyFilter() {
        let trimmedQuery = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        // Filter splits
        self.filteredSplits = allSplits.filter { split in
            let isAllSettled = split.participants.allSatisfy { $0.settlementStatus == .settled }
            switch selectedFilter {
            case .active:
                if isAllSettled { return false }
            case .settled:
                if !isAllSettled { return false }
            case .all:
                break
            }

            if !trimmedQuery.isEmpty {
                let titleMatch = split.title.lowercased().contains(trimmedQuery)
                let participantMatch = split.participants.contains { $0.name.lowercased().contains(trimmedQuery) }
                let payerMatch = split.paidBy.lowercased().contains(trimmedQuery)
                if !titleMatch && !participantMatch && !payerMatch {
                    return false
                }
            }

            return true
        }

        // Filter groups
        if trimmedQuery.isEmpty {
            self.filteredGroups = groups
        } else {
            self.filteredGroups = groups.filter {
                $0.group.name.lowercased().contains(trimmedQuery)
            }
        }
    }
}
