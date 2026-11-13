import SwiftUI

/// Dedicated analytics dashboard strictly scoped to an individual SplitGroup.
/// Visualizes category distribution, spending velocity over time, participant averages, and itemized group expense history.
public struct SplitGroupAnalyticsView: View {
    @Environment(AppContainer.self) private var container
    @Environment(\.colorScheme) private var colorScheme

    @State private var viewModel: SplitGroupAnalyticsViewModel

    public init(groupId: Int64, container: AppContainer) {
        let vm = SplitGroupAnalyticsViewModel(
            groupId: groupId,
            getSplitGroupAnalyticsUseCase: container.getSplitGroupAnalyticsUseCase,
            preferencesRepository: container.preferencesRepository
        )
        _viewModel = State(initialValue: vm)
    }

    public var body: some View {
        ZStack {
            LeafTheme.canvas(for: colorScheme).ignoresSafeArea()

            if let analytics = viewModel.analytics {
                ScrollView {
                    VStack(spacing: 20) {
                        // 1. Date Filter Pills
                        dateFilterBar

                        // Active Category Filter Chip
                        if let selectedId = viewModel.selectedCategoryId,
                           let cat = analytics.categoryBreakdown.first(where: { $0.categoryId == selectedId }) {
                            activeCategoryFilterChip(cat)
                        }

                        // 2. Financial Overview Card
                        financialOverviewSection(analytics)

                        // 3. Category Distribution Card
                        categoryDistributionSection(analytics)

                        // 4. Spending Timeline Card
                        spendingTimelineSection(analytics)

                        // 5. Group Expense History
                        groupExpenseHistorySection(analytics)

                        Spacer(minLength: 32)
                    }
                    .padding(.top, 12)
                }
                .refreshable {
                    await viewModel.loadData()
                }
            } else if viewModel.isLoading {
                ProgressView()
                    .tint(LeafTheme.brandEmerald)
            } else if let error = viewModel.errorMessage {
                EmptyStateCard(
                    icon: "exclamationmark.triangle",
                    title: "Analytics Unavailable",
                    message: error
                )
            }
        }
        .navigationTitle(viewModel.analytics?.group.name ?? "Group Analytics")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadData()
        }
        .sheet(isPresented: $viewModel.isCustomDatePickerPresented) {
            customDateRangeSheet
        }
        .navigationDestination(item: $viewModel.selectedSplitForDetail) { split in
            SplitDetailView(
                splitId: split.id,
                splitRepository: container.splitRepository,
                settleParticipantUseCase: container.settleParticipantUseCase,
                deleteSplitExpenseUseCase: container.deleteSplitExpenseUseCase,
                recordParticipantPaymentUseCase: container.recordParticipantPaymentUseCase,
                reverseParticipantPaymentUseCase: container.reverseParticipantPaymentUseCase,
                currency: viewModel.currency,
                onDataChanged: {
                    await viewModel.loadData()
                }
            )
        }
    }

    // MARK: - Date Filter Bar

    @ViewBuilder
    private var dateFilterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(SplitGroupDateFilter.allCases) { filter in
                    Button {
                        viewModel.setDateFilter(filter)
                    } label: {
                        Text(filter.rawValue)
                            .font(.system(size: 13, weight: viewModel.selectedDateFilter == filter ? .bold : .medium))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(viewModel.selectedDateFilter == filter ? LeafTheme.brandEmerald : LeafTheme.card(for: colorScheme))
                            .foregroundStyle(viewModel.selectedDateFilter == filter ? Color.white : LeafTheme.textSecondary(for: colorScheme))
                            .cornerRadius(20)
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(viewModel.selectedDateFilter == filter ? Color.clear : LeafTheme.border(for: colorScheme), lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
        }
    }

    @ViewBuilder
    private func activeCategoryFilterChip(_ cat: SplitGroupCategorySpending) -> some View {
        HStack(spacing: 8) {
            Circle()
                .fill(Color(hex: cat.categoryColorHex))
                .frame(width: 8, height: 8)

            Text("Filtered: \(cat.categoryName)")
                .font(LeafTypography.captionBold)
                .foregroundStyle(LeafTheme.textPrimary(for: colorScheme))

            Spacer()

            Button {
                viewModel.clearCategoryFilter()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(LeafTheme.card(for: colorScheme))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(hex: cat.categoryColorHex), lineWidth: 1)
        )
        .padding(.horizontal, 16)
    }

    // MARK: - Section A: Financial Overview

    @ViewBuilder
    private func financialOverviewSection(_ analytics: SplitGroupAnalytics) -> some View {
        VStack(spacing: 12) {
            // Hero Total Spending Card
            SquircleCard(cornerRadius: 18) {
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("TOTAL GROUP SPENDING")
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                .tracking(1.0)
                                .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))

                            Text(analytics.totalSpending.formatted(with: viewModel.currency))
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundStyle(LeafTheme.textPrimary(for: colorScheme))
                        }

                        Spacer()

                        ZStack {
                            Circle()
                                .fill(Color(hex: analytics.group.colorHex).opacity(0.15))
                                .frame(width: 48, height: 48)

                            Image(systemName: analytics.group.iconName)
                                .font(.system(size: 22))
                                .foregroundStyle(Color(hex: analytics.group.colorHex))
                        }
                    }

                    Divider()

                    // 4-Metric Grid
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        metricItem(
                            title: "Expenses",
                            value: "\(analytics.expenseCount)",
                            icon: "doc.text.fill",
                            color: Color.blue
                        )
                        metricItem(
                            title: "Participants",
                            value: "\(analytics.participantCount)",
                            icon: "person.2.fill",
                            color: Color.purple
                        )
                        metricItem(
                            title: "Avg / Participant",
                            value: analytics.averagePerParticipant.formatted(with: viewModel.currency),
                            icon: "person.crop.circle.badge.clock.fill",
                            color: LeafTheme.brandEmerald
                        )
                        metricItem(
                            title: "Highest Expense",
                            value: analytics.highestExpense?.totalAmount.formatted(with: viewModel.currency) ?? "—",
                            icon: "arrow.up.circle.fill",
                            color: LeafTheme.expenseCoral
                        )
                    }
                }
                .padding(18)
            }

            // Most Expensive Category Banner
            if let topCat = analytics.mostExpensiveCategory, topCat.totalAmount.subunits > 0 {
                SquircleCard(cornerRadius: 14) {
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(Color(hex: topCat.categoryColorHex).opacity(0.15))
                                .frame(width: 38, height: 38)
                            Image(systemName: topCat.categoryIcon)
                                .font(.system(size: 16))
                                .foregroundStyle(Color(hex: topCat.categoryColorHex))
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Top Spending Category")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
                            Text(topCat.categoryName)
                                .font(LeafTypography.bodyBold)
                                .foregroundStyle(LeafTheme.textPrimary(for: colorScheme))
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: 2) {
                            Text(topCat.totalAmount.formatted(with: viewModel.currency))
                                .font(.system(size: 15, weight: .bold, design: .rounded))
                                .foregroundStyle(LeafTheme.textPrimary(for: colorScheme))
                            Text(String(format: "%.0f%% of total", topCat.percentage))
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(LeafTheme.brandEmerald)
                        }
                    }
                    .padding(14)
                }
            }
        }
        .padding(.horizontal, 16)
    }

    @ViewBuilder
    private func metricItem(title: String, value: String, icon: String, color: Color) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(color)

            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
                Text(value)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(LeafTheme.textPrimary(for: colorScheme))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            Spacer(minLength: 0)
        }
    }

    // MARK: - Section B: Category Distribution

    @ViewBuilder
    private func categoryDistributionSection(_ analytics: SplitGroupAnalytics) -> some View {
        SquircleCard(cornerRadius: 18) {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("CATEGORY DISTRIBUTION")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .tracking(1.0)
                        .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))

                    Spacer()

                    Text("\(analytics.categoryBreakdown.count) Categories")
                        .font(LeafTypography.caption)
                        .foregroundStyle(LeafTheme.textTertiary(for: colorScheme))
                }

                // Donut Chart
                SplitGroupCategoryChart(
                    categories: analytics.categoryBreakdown,
                    totalSpending: analytics.totalSpending,
                    currency: viewModel.currency,
                    selectedCategoryId: viewModel.selectedCategoryId,
                    onSelectCategory: { catId in
                        viewModel.toggleCategoryFilter(catId)
                    }
                )

                if !analytics.categoryBreakdown.isEmpty {
                    Divider()

                    // Category List with Progress Bars
                    VStack(spacing: 12) {
                        ForEach(analytics.categoryBreakdown) { cat in
                            Button {
                                viewModel.toggleCategoryFilter(cat.categoryId)
                            } label: {
                                VStack(spacing: 6) {
                                    HStack {
                                        Circle()
                                            .fill(Color(hex: cat.categoryColorHex))
                                            .frame(width: 10, height: 10)

                                        Text(cat.categoryName)
                                            .font(LeafTypography.bodyMedium)
                                            .foregroundStyle(LeafTheme.textPrimary(for: colorScheme))

                                        if viewModel.selectedCategoryId == cat.categoryId {
                                            Image(systemName: "checkmark.circle.fill")
                                                .font(.system(size: 12))
                                                .foregroundStyle(LeafTheme.brandEmerald)
                                        }

                                        Spacer()

                                        Text(cat.totalAmount.formatted(with: viewModel.currency))
                                            .font(.system(size: 14, weight: .bold, design: .rounded))
                                            .foregroundStyle(LeafTheme.textPrimary(for: colorScheme))

                                        Text(String(format: "%.0f%%", cat.percentage))
                                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                                            .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
                                            .frame(width: 36, alignment: .trailing)
                                    }

                                    // Progress Bar
                                    GeometryReader { geo in
                                        ZStack(alignment: .leading) {
                                            RoundedRectangle(cornerRadius: 3)
                                                .fill(Color.gray.opacity(0.15))
                                                .frame(height: 5)

                                            RoundedRectangle(cornerRadius: 3)
                                                .fill(Color(hex: cat.categoryColorHex))
                                                .frame(width: max(4, geo.size.width * CGFloat(cat.percentage / 100.0)), height: 5)
                                        }
                                    }
                                    .frame(height: 5)
                                }
                                .padding(.vertical, 2)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .padding(18)
        }
        .padding(.horizontal, 16)
    }

    // MARK: - Section C: Spending Timeline

    @ViewBuilder
    private func spendingTimelineSection(_ analytics: SplitGroupAnalytics) -> some View {
        SquircleCard(cornerRadius: 18) {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("SPENDING TIMELINE")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .tracking(1.0)
                            .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))

                        if let peakDate = analytics.highestSpendingDate, analytics.highestSpendingAmount.subunits > 0 {
                            let formatter = DateFormatter()
                            let _ = formatter.dateFormat = "d MMM yyyy"
                            Text("Peak: \(analytics.highestSpendingAmount.formatted(with: viewModel.currency)) on \(formatter.string(from: peakDate))")
                                .font(.system(size: 11))
                                .foregroundStyle(LeafTheme.brandEmerald)
                        }
                    }

                    Spacer()
                }

                SplitGroupSpendingTimelineChart(
                    timelinePoints: analytics.timelinePoints,
                    currency: viewModel.currency
                )
            }
            .padding(18)
        }
        .padding(.horizontal, 16)
    }

    // MARK: - Section D: Group Expense History

    @ViewBuilder
    private func groupExpenseHistorySection(_ analytics: SplitGroupAnalytics) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("EXPENSE HISTORY")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .tracking(1.0)
                    .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))

                Spacer()

                Text("\(analytics.expenses.count) items")
                    .font(LeafTypography.caption)
                    .foregroundStyle(LeafTheme.textTertiary(for: colorScheme))
            }
            .padding(.horizontal, 16)

            if !analytics.expenses.isEmpty {
                VStack(spacing: 8) {
                    ForEach(analytics.expenses) { expense in
                        Button {
                            viewModel.selectedSplitForDetail = expense
                        } label: {
                            SquircleCard(cornerRadius: 14) {
                                HStack(spacing: 12) {
                                    ZStack {
                                        Circle()
                                            .fill(LeafTheme.brandEmerald.opacity(0.12))
                                            .frame(width: 40, height: 40)
                                        Image(systemName: "receipt.fill")
                                            .font(.system(size: 16))
                                            .foregroundStyle(LeafTheme.brandEmerald)
                                    }

                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(expense.title)
                                            .font(LeafTypography.bodyBold)
                                            .foregroundStyle(LeafTheme.textPrimary(for: colorScheme))
                                            .lineLimit(1)

                                        HStack(spacing: 6) {
                                            Text(DateFormatter.localizedString(from: Date(timeIntervalSince1970: Double(expense.date) / 1000.0), dateStyle: .short, timeStyle: .none))
                                                .font(.system(size: 11))
                                                .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))

                                            Text("•")
                                                .font(.system(size: 10))
                                                .foregroundStyle(LeafTheme.textTertiary(for: colorScheme))

                                            Text("Paid by \(expense.paidBy)")
                                                .font(.system(size: 11))
                                                .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))

                                            Text("•")
                                                .font(.system(size: 10))
                                                .foregroundStyle(LeafTheme.textTertiary(for: colorScheme))

                                            Text("\(expense.participants.count) people")
                                                .font(.system(size: 11))
                                                .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
                                        }
                                    }

                                    Spacer()

                                    Text(expense.totalAmount.formatted(with: viewModel.currency))
                                        .font(.system(size: 15, weight: .bold, design: .rounded))
                                        .foregroundStyle(LeafTheme.textPrimary(for: colorScheme))

                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundStyle(LeafTheme.textTertiary(for: colorScheme))
                                }
                                .padding(14)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16)
            } else {
                SquircleCard(cornerRadius: 14) {
                    VStack(spacing: 8) {
                        Image(systemName: "tray")
                            .font(.system(size: 28))
                            .foregroundStyle(LeafTheme.textTertiary(for: colorScheme))
                        Text("No expenses matching the selected filter")
                            .font(LeafTypography.caption)
                            .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(24)
                }
                .padding(.horizontal, 16)
            }
        }
    }

    // MARK: - Custom Date Range Sheet

    @ViewBuilder
    private var customDateRangeSheet: some View {
        NavigationStack {
            Form {
                DatePicker("Start Date", selection: $viewModel.customStartDate, displayedComponents: .date)
                DatePicker("End Date", selection: $viewModel.customEndDate, displayedComponents: .date)
            }
            .navigationTitle("Custom Date Range")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        viewModel.isCustomDatePickerPresented = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Apply") {
                        viewModel.applyCustomDateRange(
                            start: viewModel.customStartDate,
                            end: viewModel.customEndDate
                        )
                        viewModel.isCustomDatePickerPresented = false
                    }
                    .font(LeafTypography.bodyBold)
                    .foregroundStyle(LeafTheme.brandEmerald)
                }
            }
        }
        .presentationDetents([.height(280)])
    }
}

