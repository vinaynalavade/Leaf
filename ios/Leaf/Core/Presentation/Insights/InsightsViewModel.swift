import Foundation
import SwiftUI

public enum InsightsSubTab: String, CaseIterable, Identifiable, Sendable {
    case overview = "Overview"
    case categories = "Categories"
    case trends = "Trends"
    case budgets = "Budgets"

    public var id: String { rawValue }
}

@Observable
public final class InsightsViewModel: @unchecked Sendable {
    // MARK: - Dependencies
    private let getInsightsSummaryUseCase: GetInsightsSummaryUseCase
    private let getCategoryAnalysisUseCase: GetCategoryAnalysisUseCase
    private let getSpendingTrendsUseCase: GetSpendingTrendsUseCase
    private let getBudgetInsightsUseCase: GetBudgetInsightsUseCase
    private let getSavingsInsightsUseCase: GetSavingsInsightsUseCase
    private let getFinancialObservationsUseCase: GetFinancialObservationsUseCase
    private let preferencesRepository: UserPreferencesRepositoryProtocol

    // MARK: - State Properties
    public var selectedPeriod: InsightsPeriod = .thisMonth
    public var selectedSubTab: InsightsSubTab = .overview
    public var selectedGranularity: GetSpendingTrendsUseCase.TrendGranularity? = nil

    public var summaryResult: InsightsSummaryResult?
    public var spendingTrends: [SpendingTrendPoint] = []
    public var budgetInsights: [BudgetInsightItem] = []
    public var observations: [FinancialObservation] = []
    public var selectedCurrency: Currency = .usd

    public var isLoading: Bool = false
    public var errorMessage: String? = nil

    // Custom Date Range Modal State
    public var isCustomRangeSheetPresented: Bool = false
    public var customStartDate: Date = Date()
    public var customEndDate: Date = Date()

    // Drill-Down States
    public var selectedCategoryForDrillDown: CategoryAnalysisItem? = nil

    public init(
        getInsightsSummaryUseCase: GetInsightsSummaryUseCase,
        getCategoryAnalysisUseCase: GetCategoryAnalysisUseCase,
        getSpendingTrendsUseCase: GetSpendingTrendsUseCase,
        getBudgetInsightsUseCase: GetBudgetInsightsUseCase,
        getSavingsInsightsUseCase: GetSavingsInsightsUseCase,
        getFinancialObservationsUseCase: GetFinancialObservationsUseCase,
        preferencesRepository: UserPreferencesRepositoryProtocol
    ) {
        self.getInsightsSummaryUseCase = getInsightsSummaryUseCase
        self.getCategoryAnalysisUseCase = getCategoryAnalysisUseCase
        self.getSpendingTrendsUseCase = getSpendingTrendsUseCase
        self.getBudgetInsightsUseCase = getBudgetInsightsUseCase
        self.getSavingsInsightsUseCase = getSavingsInsightsUseCase
        self.getFinancialObservationsUseCase = getFinancialObservationsUseCase
        self.preferencesRepository = preferencesRepository
    }

    // MARK: - Data Loading

    @MainActor
    public func loadData() async {
        isLoading = true
        errorMessage = nil

        do {
            let prefs = preferencesRepository.getUserPreferences()
            self.selectedCurrency = prefs.currency

            // 1. Fetch core financial overview and spending summary
            let summary = try await getInsightsSummaryUseCase.execute(period: selectedPeriod)
            self.summaryResult = summary

            // 2. Fetch spending trend points
            let trends = try await getSpendingTrendsUseCase.execute(
                period: selectedPeriod,
                forcedGranularity: selectedGranularity
            )
            self.spendingTrends = trends

            // 3. Fetch budget insights
            let budgets = try await getBudgetInsightsUseCase.execute(period: selectedPeriod)
            self.budgetInsights = budgets

            // 4. Generate intelligent rule-based observations
            let obs = getFinancialObservationsUseCase.execute(
                summaryResult: summary,
                budgets: budgets,
                currency: prefs.currency
            )
            self.observations = obs

            self.isLoading = false
        } catch {
            self.errorMessage = error.localizedDescription
            self.isLoading = false
        }
    }

    // MARK: - User Intent Handlers

    @MainActor
    public func selectPeriod(_ period: InsightsPeriod) async {
        guard period != selectedPeriod else { return }
        self.selectedPeriod = period
        await loadData()
    }

    @MainActor
    public func applyCustomDateRange(start: Date, end: Date) async {
        self.selectedPeriod = .custom(startDate: start, endDate: end)
        self.isCustomRangeSheetPresented = false
        await loadData()
    }

    @MainActor
    public func selectGranularity(_ granularity: GetSpendingTrendsUseCase.TrendGranularity) async {
        guard selectedGranularity != granularity else { return }
        self.selectedGranularity = granularity
        do {
            let trends = try await getSpendingTrendsUseCase.execute(
                period: selectedPeriod,
                forcedGranularity: granularity
            )
            self.spendingTrends = trends
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }

    public func openCategoryDrillDown(_ item: CategoryAnalysisItem) {
        self.selectedCategoryForDrillDown = item
    }

    public func closeCategoryDrillDown() {
        self.selectedCategoryForDrillDown = nil
    }

    public func handleObservationAction(_ action: ObservationAction) {
        switch action {
        case .category(let categoryId):
            if let item = summaryResult?.categoryBreakdown.first(where: { $0.category.id == categoryId }) {
                openCategoryDrillDown(item)
            }
        case .budgets:
            selectedSubTab = .budgets
        case .savingsGoal:
            // Could navigate to goal detail
            break
        case .date:
            selectedSubTab = .trends
        }
    }
}
