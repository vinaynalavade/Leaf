import Foundation
import SwiftUI

/// Observable view model coordinating the presentation state, filters, and analytical calculations for a SplitGroup.
@Observable
public final class SplitGroupAnalyticsViewModel: @unchecked Sendable {

    public let groupId: Int64
    private let getSplitGroupAnalyticsUseCase: GetSplitGroupAnalyticsUseCase
    private let preferencesRepository: UserPreferencesRepositoryProtocol

    public var analytics: SplitGroupAnalytics? = nil
    public var selectedDateFilter: SplitGroupDateFilter = .allTime
    public var selectedCategoryId: Int64? = nil

    public var customStartDate: Date = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()
    public var customEndDate: Date = Date()
    public var isCustomDatePickerPresented: Bool = false

    public var selectedSplitForDetail: SplitExpense? = nil
    public var currency: Currency = .default
    public var isLoading: Bool = false
    public var errorMessage: String? = nil

    public init(
        groupId: Int64,
        getSplitGroupAnalyticsUseCase: GetSplitGroupAnalyticsUseCase,
        preferencesRepository: UserPreferencesRepositoryProtocol
    ) {
        self.groupId = groupId
        self.getSplitGroupAnalyticsUseCase = getSplitGroupAnalyticsUseCase
        self.preferencesRepository = preferencesRepository
    }

    @MainActor
    public func loadData() async {
        isLoading = true
        errorMessage = nil

        do {
            let prefs = try await preferencesRepository.getUserPreferences()
            self.currency = Currency.fromCode(prefs.currencyCode)

            self.analytics = try await getSplitGroupAnalyticsUseCase.execute(
                groupId: groupId,
                dateFilter: selectedDateFilter,
                customStartDate: selectedDateFilter == .custom ? customStartDate : nil,
                customEndDate: selectedDateFilter == .custom ? customEndDate : nil,
                selectedCategoryId: selectedCategoryId
            )
        } catch {
            self.errorMessage = "Failed to load group analytics: \(error.localizedDescription)"
        }

        isLoading = false
    }

    @MainActor
    public func setDateFilter(_ filter: SplitGroupDateFilter) {
        self.selectedDateFilter = filter
        if filter == .custom {
            self.isCustomDatePickerPresented = true
        } else {
            Task { await loadData() }
        }
    }

    @MainActor
    public func toggleCategoryFilter(_ categoryId: Int64) {
        if selectedCategoryId == categoryId {
            selectedCategoryId = nil
        } else {
            selectedCategoryId = categoryId
        }
        Task { await loadData() }
    }

    @MainActor
    public func clearCategoryFilter() {
        selectedCategoryId = nil
        Task { await loadData() }
    }

    @MainActor
    public func applyCustomDateRange(start: Date, end: Date) {
        self.customStartDate = start
        self.customEndDate = end
        self.selectedDateFilter = .custom
        Task { await loadData() }
    }
}

