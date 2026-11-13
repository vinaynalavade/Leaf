import SwiftUI

/// Main native iOS landing screen for the Leaf Insights & Analytics module.
/// Provides deep visibility into spending velocity, earned income, category shares,
/// budget utilisation, and intelligent rule-based observations.
public struct InsightsView: View {
    @Environment(AppContainer.self) private var container
    @Environment(\.colorScheme) private var colorScheme

    @State private var viewModel: InsightsViewModel?
    @State private var isStatementsPresented: Bool = false
    @State private var isRecurringHubPresented: Bool = false

    public init() {}

    public var body: some View {
        ZStack {
            LeafTheme.canvas(for: colorScheme).ignoresSafeArea()

            if let vm = viewModel {
                VStack(spacing: 0) {
                    // 1. Navigation Header
                    headerBar(vm)

                    // 2. Horizontal Period Selector Pills
                    InsightsPeriodSelectorView(
                        selectedPeriod: vm.selectedPeriod,
                        onSelectPeriod: { period in
                            Task { await vm.selectPeriod(period) }
                        },
                        onCustomTap: {
                            vm.isCustomRangeSheetPresented = true
                        }
                    )
                    .padding(.bottom, 8)

                    // 3. Sub-Tab Segmented Switcher
                    subTabPicker(vm)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 10)

                    // 4. Content Area
                    if vm.isLoading && vm.summaryResult == nil {
                        Spacer()
                        ProgressView()
                            .tint(LeafTheme.accent(for: colorScheme))
                        Spacer()
                    } else {
                        ScrollView {
                            VStack(spacing: 18) {
                                switch vm.selectedSubTab {
                                case .overview:
                                    overviewTabContent(vm)
                                case .categories:
                                    categoriesTabContent(vm)
                                case .trends:
                                    trendsTabContent(vm)
                                case .budgets:
                                    budgetsTabContent(vm)
                                }

                                Spacer(minLength: 40)
                            }
                            .padding(.top, 4)
                        }
                        .refreshable {
                            await vm.loadData()
                        }
                    }
                }
                .sheet(isPresented: Binding(
                    get: { vm.isCustomRangeSheetPresented },
                    set: { vm.isCustomRangeSheetPresented = $0 }
                )) {
                    CustomDateRangeSheet(
                        onApply: { start, end in
                            Task { await vm.applyCustomDateRange(start: start, end: end) }
                        }
                    )
                }
                .sheet(item: Binding(
                    get: { vm.selectedCategoryForDrillDown },
                    set: { vm.selectedCategoryForDrillDown = $0 }
                )) { item in
                    CategoryDetailAnalyticsView(
                        item: item,
                        period: vm.selectedPeriod,
                        currency: vm.selectedCurrency
                    )
                }
                .sheet(isPresented: $isStatementsPresented) {
                    NavigationStack {
                        StatementsView()
                    }
                }
                .sheet(isPresented: $isRecurringHubPresented) {
                    NavigationStack {
                        RecurringHubView()
                    }
                }
            } else {
                ProgressView()
                    .tint(LeafTheme.accent(for: colorScheme))
            }
        }
        .navigationTitle("")
        .navigationBarHidden(true)
        .task {
            if viewModel == nil {
                let vm = InsightsViewModel(
                    getInsightsSummaryUseCase: container.getInsightsSummaryUseCase,
                    getCategoryAnalysisUseCase: container.getCategoryAnalysisUseCase,
                    getSpendingTrendsUseCase: container.getSpendingTrendsUseCase,
                    getBudgetInsightsUseCase: container.getBudgetInsightsUseCase,
                    getSavingsInsightsUseCase: container.getSavingsInsightsUseCase,
                    getFinancialObservationsUseCase: container.getFinancialObservationsUseCase,
                    preferencesRepository: container.preferencesRepository
                )
                self.viewModel = vm
                await vm.loadData()
            }
        }
    }

    // MARK: - Header Bar

    @ViewBuilder
    private func headerBar(_ vm: InsightsViewModel) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Insights & Analytics")
                    .font(LeafTypography.headline)
                    .foregroundStyle(LeafTheme.textPrimary(for: colorScheme))

                Text("Financial trends and health")
                    .font(LeafTypography.caption)
                    .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
            }

            Spacer()

            Button {
                isStatementsPresented = true
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "doc.text.fill")
                        .font(.system(size: 13, weight: .semibold))
                    Text("Statements")
                        .font(LeafTypography.captionBold)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(LeafTheme.card(for: colorScheme))
                .foregroundStyle(LeafTheme.accent(for: colorScheme))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(LeafTheme.border(for: colorScheme), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)

            if vm.isLoading {
                ProgressView()
                    .scaleEffect(0.8)
                    .tint(LeafTheme.accent(for: colorScheme))
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 8)
    }

    // MARK: - Sub-Tab Picker

    @ViewBuilder
    private func subTabPicker(_ vm: InsightsViewModel) -> some View {
        Picker("SubTab", selection: Binding(
            get: { vm.selectedSubTab },
            set: { vm.selectedSubTab = $0 }
        )) {
            ForEach(InsightsSubTab.allCases) { tab in
                Text(tab.rawValue).tag(tab)
            }
        }
        .pickerStyle(.segmented)
    }

    // MARK: - Tab 1: Overview

    @ViewBuilder
    private func overviewTabContent(_ vm: InsightsViewModel) -> some View {
        if let summary = vm.summaryResult {
            // 1. Financial Overview Luxury Card
            FinancialOverviewCardView(
                overview: summary.financialOverview,
                currency: vm.selectedCurrency
            )
            .padding(.horizontal, 16)

            // 2. Intelligent Rule-Based Observations Carousel
            FinancialObservationsSectionView(
                observations: vm.observations,
                onAction: { action in
                    vm.handleObservationAction(action)
                }
            )

            // 3. Key Metrics 2x2 Grid
            keyMetricsGrid(summary.statistics, currency: vm.selectedCurrency)
                .padding(.horizontal, 16)

            // 4. Spending Velocity Trend Chart
            SpendingTrendsChartView(
                trendPoints: vm.spendingTrends,
                currency: vm.selectedCurrency,
                averageExpense: summary.statistics.dailyAverageExpense
            )
            .padding(.horizontal, 16)

            // 5. Category Distribution Donut Chart
            CategoryDistributionChartView(
                categories: summary.categoryBreakdown,
                totalExpense: summary.financialOverview.totalExpense,
                currency: vm.selectedCurrency,
                onSelectCategory: { item in
                    vm.openCategoryDrillDown(item)
                }
            )
            .padding(.horizontal, 16)

            // 6. Active Budgets Preview
            if !vm.budgetInsights.isEmpty {
                BudgetUtilisationSectionView(
                    budgets: Array(vm.budgetInsights.prefix(3)),
                    currency: vm.selectedCurrency,
                    onBudgetTap: { _ in
                        vm.selectedSubTab = .budgets
                    }
                )
            }

            // 7. Fixed Overhead & Recurring Subscriptions Banner
            recurringCommitmentsBannerCard()
                .padding(.horizontal, 16)

            // 8. Official Statements & Export Banner
            statementsBannerCard()
                .padding(.horizontal, 16)
        }
    }

    @ViewBuilder
    private func recurringCommitmentsBannerCard() -> some View {
        Button {
            isRecurringHubPresented = true
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.indigo.opacity(0.12))
                        .frame(width: 42, height: 42)

                    Image(systemName: "repeat.circle.fill")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(Color.indigo)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Fixed Overhead & Subscriptions")
                        .font(LeafTypography.bodyBold)
                        .foregroundStyle(LeafTheme.textPrimary(for: colorScheme))

                    Text("Analyze recurring commitments, subscriptions & bill cycles")
                        .font(LeafTypography.caption)
                        .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
            }
            .padding(14)
            .background(LeafTheme.card(for: colorScheme))
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(LeafTheme.border(for: colorScheme), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func statementsBannerCard() -> some View {
        Button {
            isStatementsPresented = true
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(LeafTheme.brandEmerald.opacity(0.12))
                        .frame(width: 42, height: 42)

                    Image(systemName: "doc.text.fill")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(LeafTheme.brandEmerald)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Financial Statements & Export")
                        .font(LeafTypography.bodyBold)
                        .foregroundStyle(LeafTheme.textPrimary(for: colorScheme))

                    Text("Generate bank-grade PDF reports & CSV ledgers")
                        .font(LeafTypography.caption)
                        .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
            }
            .padding(14)
            .background(LeafTheme.card(for: colorScheme))
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(LeafTheme.border(for: colorScheme), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Tab 2: Categories

    @ViewBuilder
    private func categoriesTabContent(_ vm: InsightsViewModel) -> some View {
        if let summary = vm.summaryResult {
            CategoryDistributionChartView(
                categories: summary.categoryBreakdown,
                totalExpense: summary.financialOverview.totalExpense,
                currency: vm.selectedCurrency,
                onSelectCategory: { item in
                    vm.openCategoryDrillDown(item)
                }
            )
            .padding(.horizontal, 16)

            CategoryBreakdownListView(
                categories: summary.categoryBreakdown,
                currency: vm.selectedCurrency,
                onSelectCategory: { item in
                    vm.openCategoryDrillDown(item)
                }
            )
        }
    }

    // MARK: - Tab 3: Trends

    @ViewBuilder
    private func trendsTabContent(_ vm: InsightsViewModel) -> some View {
        if let summary = vm.summaryResult {
            // Granularity Switcher
            HStack(spacing: 8) {
                Text("GROUP BY")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .tracking(0.8)
                    .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))

                Spacer()

                granularityButton("Daily", granularity: .daily, vm: vm)
                granularityButton("Weekly", granularity: .weekly, vm: vm)
                granularityButton("Monthly", granularity: .monthly, vm: vm)
            }
            .padding(.horizontal, 16)

            SpendingTrendsChartView(
                trendPoints: vm.spendingTrends,
                currency: vm.selectedCurrency,
                averageExpense: summary.statistics.dailyAverageExpense
            )
            .padding(.horizontal, 16)

            // Period Statistics Highlights
            keyMetricsGrid(summary.statistics, currency: vm.selectedCurrency)
                .padding(.horizontal, 16)
        }
    }

    // MARK: - Tab 4: Budgets & Savings

    @ViewBuilder
    private func budgetsTabContent(_ vm: InsightsViewModel) -> some View {
        if let summary = vm.summaryResult {
            BudgetUtilisationSectionView(
                budgets: vm.budgetInsights,
                currency: vm.selectedCurrency,
                onBudgetTap: { item in
                    if let cat = item.category,
                       let catItem = summary.categoryBreakdown.first(where: { $0.category.id == cat.id }) {
                        vm.openCategoryDrillDown(catItem)
                    }
                }
            )

            SavingsGrowthSectionView(
                savingsSummary: summary.financialOverview.savingsSummary,
                currency: vm.selectedCurrency
            )
        }
    }

    // MARK: - Key Metrics Grid

    @ViewBuilder
    private func keyMetricsGrid(_ stats: SpendingStatistics, currency: Currency) -> some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                metricCard(
                    title: "DAILY AVERAGE",
                    value: stats.dailyAverageExpense.formatted(with: currency),
                    icon: "calendar",
                    accent: LeafTheme.brandEmerald,
                    changePercentage: stats.dailyAverageChangePercentage,
                    isExpenseMetric: true
                )

                metricCard(
                    title: "TOTAL TRANSACTIONS",
                    value: "\(stats.transactionCount) tx",
                    icon: "list.bullet.rectangle",
                    accent: LeafTheme.infoBlue,
                    changePercentage: stats.transactionCountChangePercentage,
                    isExpenseMetric: false
                )
            }

            HStack(spacing: 10) {
                if let topCat = stats.topCategory {
                    metricCard(
                        title: "TOP CATEGORY",
                        value: topCat.category.name,
                        subValue: topCat.amount.formatted(with: currency),
                        icon: "tag.fill",
                        accent: Color(hex: topCat.category.colorHex),
                        changePercentage: topCat.changePercentageVsPrevious,
                        isExpenseMetric: true
                    )
                } else {
                    metricCard(
                        title: "TOP CATEGORY",
                        value: "None",
                        icon: "tag.fill",
                        accent: LeafTheme.textTertiary(for: colorScheme),
                        changePercentage: nil,
                        isExpenseMetric: true
                    )
                }

                if let peakDay = stats.highestSpendingDay {
                    metricCard(
                        title: "PEAK DAY",
                        value: peakDay.formattedDate,
                        subValue: peakDay.amount.formatted(with: currency),
                        icon: "flame.fill",
                        accent: LeafTheme.expenseCoral,
                        changePercentage: nil,
                        isExpenseMetric: true
                    )
                } else {
                    metricCard(
                        title: "PEAK DAY",
                        value: "None",
                        icon: "flame.fill",
                        accent: LeafTheme.textTertiary(for: colorScheme),
                        changePercentage: nil,
                        isExpenseMetric: true
                    )
                }
            }
        }
    }

    @ViewBuilder
    private func metricCard(
        title: String,
        value: String,
        subValue: String? = nil,
        icon: String,
        accent: Color,
        changePercentage: Double?,
        isExpenseMetric: Bool
    ) -> some View {
        SquircleCard {
            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 6) {
                    Image(systemName: icon)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(accent)

                    Text(title)
                        .font(.system(size: 9, weight: .bold, design: .rounded))
                        .tracking(0.6)
                        .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))

                    Spacer()

                    if let change = changePercentage {
                        let isIncrease = change > 0
                        HStack(spacing: 2) {
                            Image(systemName: isIncrease ? "arrow.up" : "arrow.down")
                                .font(.system(size: 7, weight: .bold))
                            Text(String(format: "%.0f%%", abs(change)))
                                .font(.system(size: 9, weight: .bold, design: .rounded))
                        }
                        .padding(.horizontal, 4)
                        .padding(.vertical, 2)
                        .background(
                            Capsule().fill(
                                (isExpenseMetric ? (isIncrease ? LeafTheme.expenseCoral : LeafTheme.brandEmerald) : LeafTheme.infoBlue).opacity(0.12)
                            )
                        )
                        .foregroundStyle(
                            isExpenseMetric ? (isIncrease ? LeafTheme.expenseCoral : LeafTheme.brandEmerald) : LeafTheme.infoBlue
                        )
                    }
                }

                Text(value)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(LeafTheme.textPrimary(for: colorScheme))
                    .lineLimit(1)

                if let sub = subValue {
                    Text(sub)
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
        }
    }

    @ViewBuilder
    private func granularityButton(
        _ title: String,
        granularity: GetSpendingTrendsUseCase.TrendGranularity,
        vm: InsightsViewModel
    ) -> some View {
        Button(action: {
            Task { await vm.selectGranularity(granularity) }
        }) {
            Text(title)
                .font(.system(size: 11, weight: vm.selectedGranularity == granularity ? .bold : .medium))
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(vm.selectedGranularity == granularity ? LeafTheme.brandEmerald : LeafTheme.cardBorder(for: colorScheme))
                )
                .foregroundStyle(vm.selectedGranularity == granularity ? Color.white : LeafTheme.textPrimary(for: colorScheme))
        }
        .buttonStyle(.plain)
    }
}

