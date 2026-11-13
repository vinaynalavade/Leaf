import SwiftUI
import UIKit

/// Primary landing screen for the Split & Collect module.
/// Encapsulates financial overview, active balance stance, list of split expenses,
/// group-based organization, and deep navigation to itemized split detail and dedicated SplitGroup analytics.
public struct SplitLandingView: View {
    @Environment(AppContainer.self) private var container
    @Environment(\.colorScheme) private var colorScheme

    @State private var viewModel: SplitLandingViewModel?
    @State private var categories: [Category] = []
    @State private var isSearchActive: Bool = false
    @State private var searchText: String = ""

    public init() {}

    private func triggerHaptic() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.prepare()
        generator.impactOccurred()
    }

    public var body: some View {
        ZStack {
            LeafTheme.canvas(for: colorScheme).ignoresSafeArea()

            if let vm = viewModel {
                @Bindable var vm = vm
                ScrollView {
                    VStack(spacing: 20) {
                        // 1. Screen Header
                        headerView(vm)

                        // 2. Search Field if active
                        if isSearchActive {
                            searchBar(vm)
                        }

                        // 3. Tab Switcher: Expenses vs Groups
                        tabSegmentedControl(vm)

                        // 4. Tab Content
                        switch vm.selectedTab {
                        case .expenses:
                            expensesTabContent(vm)
                        case .groups:
                            groupsTabContent(vm)
                        }

                        Spacer(minLength: 32)
                    }
                    .padding(.top, 4)
                }
                .refreshable {
                    await vm.loadData()
                }
                // Sheet: Create New Split
                .sheet(isPresented: $vm.isCreateSheetPresented) {
                    CreateSplitSheet(
                        currency: vm.selectedCurrency,
                        categories: categories,
                        calculateSplitUseCase: container.calculateSplitUseCase,
                        onSave: { title, totalAmt, date, catId, payer, method, paymentSource, addToLedger, participants in
                            _ = try await container.createSplitExpenseUseCase.execute(
                                title: title,
                                totalAmount: totalAmt,
                                date: date,
                                categoryId: catId,
                                paidBy: payer,
                                splitMethod: method,
                                paymentMethod: paymentSource,
                                addToTransactions: addToLedger,
                                participants: participants
                            )
                            await vm.loadData()
                        }
                    )
                }
                // Sheet: Create New Group
                .sheet(isPresented: $vm.isCreateGroupSheetPresented) {
                    CreateGroupSheet(
                        onSave: { name, icon, color in
                            await vm.createGroup(name: name, iconName: icon, colorHex: color)
                        }
                    )
                }
                // Navigation Destination to SplitDetailView
                .navigationDestination(item: $vm.selectedSplitForDetail) { split in
                    SplitDetailView(
                        splitId: split.id,
                        splitRepository: container.splitRepository,
                        settleParticipantUseCase: container.settleParticipantUseCase,
                        deleteSplitExpenseUseCase: container.deleteSplitExpenseUseCase,
                        recordParticipantPaymentUseCase: container.recordParticipantPaymentUseCase,
                        reverseParticipantPaymentUseCase: container.reverseParticipantPaymentUseCase,
                        currency: vm.selectedCurrency,
                        onDataChanged: {
                            await vm.loadData()
                        }
                    )
                }
                // Navigation Destination to SplitGroupDetailView
                .navigationDestination(item: $vm.selectedGroupForDetail) { summary in
                    SplitGroupDetailView(groupId: summary.id)
                }
                // Delete confirmation alert for split expense
                .confirmationDialog(
                    "Delete Split?",
                    isPresented: Binding(
                        get: { vm.splitToDelete != nil },
                        set: { if !$0 { vm.splitToDelete = nil } }
                    ),
                    titleVisibility: .visible
                ) {
                    if let item = vm.splitToDelete {
                        Button("Delete Split", role: .destructive) {
                            Task { await vm.deleteSplit(id: item.id) }
                        }
                    }
                    Button("Cancel", role: .cancel) {
                        vm.splitToDelete = nil
                    }
                } message: {
                    Text("Are you sure you want to delete this split expense? Historical ledger entries will remain preserved.")
                }
                // Delete confirmation alert for split group
                .confirmationDialog(
                    "Delete Group?",
                    isPresented: Binding(
                        get: { vm.groupToDelete != nil },
                        set: { if !$0 { vm.groupToDelete = nil } }
                    ),
                    titleVisibility: .visible
                ) {
                    if let group = vm.groupToDelete {
                        Button("Delete Group", role: .destructive) {
                            Task { await vm.deleteGroup(id: group.id) }
                        }
                    }
                    Button("Cancel", role: .cancel) {
                        vm.groupToDelete = nil
                    }
                } message: {
                    Text("Are you sure you want to delete this group? Group expenses will remain saved but unassigned from the group.")
                }
            } else {
                ProgressView().tint(LeafTheme.brandEmerald)
            }
        }
        .navigationTitle("")
        .navigationBarHidden(true)
        .task {
            if viewModel == nil {
                let vm = SplitLandingViewModel(
                    splitRepository: container.splitRepository,
                    getSplitSummaryUseCase: container.getSplitSummaryUseCase,
                    deleteSplitExpenseUseCase: container.deleteSplitExpenseUseCase,
                    preferencesRepository: container.preferencesRepository,
                    getSplitGroupsUseCase: container.getSplitGroupsUseCase,
                    saveSplitGroupUseCase: container.saveSplitGroupUseCase,
                    deleteSplitGroupUseCase: container.deleteSplitGroupUseCase
                )
                self.viewModel = vm
                await vm.loadData()

                if let loadedCats = try? await container.categoryRepository.getAllCategories() {
                    self.categories = loadedCats
                }
            } else {
                await viewModel?.loadData()
            }
        }
    }

    // MARK: - Header View

    @ViewBuilder
    private func headerView(_ vm: SplitLandingViewModel) -> some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Split & Collect")
                    .font(LeafTypography.titleLarge)
                    .foregroundStyle(LeafTheme.textPrimary(for: colorScheme))

                Text("Shared expenses & group balances")
                    .font(LeafTypography.captionRegular)
                    .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
            }

            Spacer()

            HStack(spacing: 8) {
                // Search Toggle Button
                Button(action: {
                    triggerHaptic()
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        isSearchActive.toggle()
                        if !isSearchActive {
                            searchText = ""
                            vm.updateSearchQuery("")
                        }
                    }
                }) {
                    Image(systemName: isSearchActive ? "text.magnifyingglass" : "magnifyingglass")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(isSearchActive ? LeafTheme.brandEmerald : LeafTheme.textPrimary(for: colorScheme))
                        .frame(width: 36, height: 36)
                        .background(
                            Circle().fill(colorScheme == .dark ? LeafTheme.cardDark : LeafTheme.cardLight)
                        )
                        .overlay(
                            Circle().stroke(LeafTheme.cardBorder(for: colorScheme), lineWidth: 0.75)
                        )
                }

                // New Action Menu
                Menu {
                    Button {
                        triggerHaptic()
                        vm.isCreateSheetPresented = true
                    } label: {
                        Label("New Expense", systemImage: "plus.circle")
                    }

                    Button {
                        triggerHaptic()
                        vm.isCreateGroupSheetPresented = true
                    } label: {
                        Label("New Group", systemImage: "person.3")
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "plus")
                            .font(.system(size: 13, weight: .bold))
                        Text(vm.selectedTab == .groups ? "New Group" : "New Split")
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .frame(height: 36)
                    .background(LeafTheme.brandEmerald)
                    .clipShape(Capsule())
                }
            }
        }
        .padding(.horizontal)
    }

    // MARK: - Search Bar

    @ViewBuilder
    private func searchBar(_ vm: SplitLandingViewModel) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 14))
                .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))

            TextField(
                vm.selectedTab == .groups ? "Search groups..." : "Search splits, friends...",
                text: $searchText
            )
            .font(LeafTypography.bodyMedium)
            .foregroundStyle(LeafTheme.textPrimary(for: colorScheme))
            .onChange(of: searchText) { _, newText in
                vm.updateSearchQuery(newText)
            }

            if !searchText.isEmpty {
                Button(action: {
                    searchText = ""
                    vm.updateSearchQuery("")
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(colorScheme == .dark ? LeafTheme.cardDark : LeafTheme.cardLight)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(LeafTheme.cardBorder(for: colorScheme), lineWidth: 0.75)
        )
        .padding(.horizontal)
        .transition(.move(edge: .top).combined(with: .opacity))
    }

    // MARK: - Tab Segmented Control

    @ViewBuilder
    private func tabSegmentedControl(_ vm: SplitLandingViewModel) -> some View {
        HStack(spacing: 0) {
            ForEach(SplitLandingTab.allCases) { tab in
                let isSelected = vm.selectedTab == tab
                Button(action: {
                    triggerHaptic()
                    withAnimation(.easeInOut(duration: 0.2)) {
                        vm.setSelectedTab(tab)
                    }
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: tab == .expenses ? "list.bullet.rectangle" : "person.3.fill")
                            .font(.system(size: 13, weight: .semibold))

                        Text(tab.rawValue)
                            .font(LeafTypography.captionBold)

                        // Count badge
                        let count = tab == .expenses ? vm.allSplits.count : vm.groups.count
                        Text("\(count)")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundStyle(isSelected ? LeafTheme.brandEmerald : LeafTheme.textTertiary(for: colorScheme))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                Capsule()
                                    .fill(isSelected ? LeafTheme.brandEmerald.opacity(0.12) : LeafTheme.canvas(for: colorScheme))
                            )
                    }
                    .foregroundStyle(isSelected ? LeafTheme.brandEmerald : LeafTheme.textSecondary(for: colorScheme))
                    .frame(maxWidth: .infinity)
                    .frame(height: 38)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(isSelected ? (colorScheme == .dark ? LeafTheme.cardDark : LeafTheme.cardLight) : Color.clear)
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(colorScheme == .dark ? Color.white.opacity(0.06) : Color.black.opacity(0.05))
        )
        .padding(.horizontal)
    }

    // MARK: - Expenses Tab Content

    @ViewBuilder
    private func expensesTabContent(_ vm: SplitLandingViewModel) -> some View {
        VStack(spacing: 20) {
            // Financial Overview Summary Card
            SplitFinancialOverviewCardView(
                summary: vm.balanceSummary,
                currency: vm.selectedCurrency
            )

            // Filter Segmented Control (Active / All / Settled)
            filterSegmentedControl(vm)

            // Splits List / Empty State
            splitsListSection(vm)
        }
    }

    // MARK: - Filter Segmented Control

    @ViewBuilder
    private func filterSegmentedControl(_ vm: SplitLandingViewModel) -> some View {
        HStack {
            Picker("Filter", selection: Binding(
                get: { vm.selectedFilter },
                set: { vm.setFilter($0) }
            )) {
                ForEach(SplitFilterOption.allCases) { opt in
                    Text(opt.rawValue).tag(opt)
                }
            }
            .pickerStyle(.segmented)
        }
        .padding(.horizontal)
    }

    // MARK: - Splits List Section

    @ViewBuilder
    private func splitsListSection(_ vm: SplitLandingViewModel) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("EXPENSE HISTORY")
                    .font(LeafTypography.captionBold)
                    .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
                    .tracking(0.5)

                Spacer()

                if !vm.filteredSplits.isEmpty {
                    Text("\(vm.filteredSplits.count) \(vm.filteredSplits.count == 1 ? "split" : "splits")")
                        .font(LeafTypography.captionRegular)
                        .foregroundStyle(LeafTheme.textTertiary(for: colorScheme))
                }
            }
            .padding(.horizontal)

            if vm.filteredSplits.isEmpty {
                if !vm.searchQuery.isEmpty || vm.selectedFilter != .active {
                    EmptyStateCard(
                        icon: "magnifyingglass",
                        title: "No Matching Splits",
                        message: "Try searching with a different keyword or switching filters.",
                        actionTitle: "Reset Filters",
                        action: {
                            searchText = ""
                            vm.updateSearchQuery("")
                            vm.setFilter(.all)
                        }
                    )
                    .padding(.horizontal)
                } else {
                    EmptyStateCard(
                        icon: "person.2",
                        title: "No Split Expenses Yet",
                        message: "Split bills with friends, roommates, and travel buddies with automated debt settlement.",
                        actionTitle: "Create Your First Split",
                        action: {
                            triggerHaptic()
                            vm.isCreateSheetPresented = true
                        }
                    )
                    .padding(.horizontal)
                }
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(vm.filteredSplits) { item in
                        SplitExpenseCardView(
                            split: item,
                            currency: vm.selectedCurrency,
                            onTap: {
                                vm.selectedSplitForDetail = item
                            },
                            onEdit: {
                                vm.selectedSplitForDetail = item
                            },
                            onDelete: {
                                vm.splitToDelete = item
                            },
                            onSettle: {
                                vm.selectedSplitForDetail = item
                            }
                        )
                        .padding(.horizontal)
                    }
                }
            }
        }
    }

    // MARK: - Groups Tab Content

    @ViewBuilder
    private func groupsTabContent(_ vm: SplitLandingViewModel) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("SPLIT GROUPS")
                    .font(LeafTypography.captionBold)
                    .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
                    .tracking(0.5)

                Spacer()

                if !vm.filteredGroups.isEmpty {
                    Text("\(vm.filteredGroups.count) \(vm.filteredGroups.count == 1 ? "group" : "groups")")
                        .font(LeafTypography.captionRegular)
                        .foregroundStyle(LeafTheme.textTertiary(for: colorScheme))
                }
            }
            .padding(.horizontal)

            if vm.filteredGroups.isEmpty {
                if !vm.searchQuery.isEmpty {
                    EmptyStateCard(
                        icon: "magnifyingglass",
                        title: "No Matching Groups",
                        message: "Try searching with a different group name.",
                        actionTitle: "Clear Search",
                        action: {
                            searchText = ""
                            vm.updateSearchQuery("")
                        }
                    )
                    .padding(.horizontal)
                } else {
                    EmptyStateCard(
                        icon: "person.3",
                        title: "No Groups Created",
                        message: "Create split groups for trips, room expenses, or events to track dedicated spending analytics.",
                        actionTitle: "Create First Group",
                        action: {
                            triggerHaptic()
                            vm.isCreateGroupSheetPresented = true
                        }
                    )
                    .padding(.horizontal)
                }
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(vm.filteredGroups) { groupSummary in
                        groupRowCard(groupSummary, vm: vm)
                            .padding(.horizontal)
                    }
                }
            }
        }
    }

    // MARK: - Group Row Card

    @ViewBuilder
    private func groupRowCard(_ summary: SplitGroupSummary, vm: SplitLandingViewModel) -> some View {
        Button(action: {
            triggerHaptic()
            vm.selectedGroupForDetail = summary
        }) {
            HStack(spacing: 14) {
                // Group Icon Circle
                ZStack {
                    Circle()
                        .fill(Color(hex: summary.group.colorHex).opacity(0.18))
                        .frame(width: 48, height: 48)

                    Image(systemName: summary.group.iconName)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(Color(hex: summary.group.colorHex))
                }

                // Group Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(summary.group.name)
                        .font(LeafTypography.headline)
                        .foregroundStyle(LeafTheme.textPrimary(for: colorScheme))
                        .lineLimit(1)

                    HStack(spacing: 6) {
                        Text("\(summary.participantCount) \(summary.participantCount == 1 ? "member" : "members")")
                        Text("•")
                        Text("\(summary.expenseCount) \(summary.expenseCount == 1 ? "expense" : "expenses")")
                    }
                    .font(LeafTypography.captionRegular)
                    .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
                }

                Spacer()

                // Total Spending & Analytics Pill
                VStack(alignment: .trailing, spacing: 4) {
                    Text(summary.totalSpending.formatted(currency: vm.selectedCurrency))
                        .font(LeafTypography.headline)
                        .foregroundStyle(LeafTheme.textPrimary(for: colorScheme))

                    HStack(spacing: 3) {
                        Image(systemName: "chart.pie.fill")
                            .font(.system(size: 10))
                        Text("Analytics")
                            .font(.system(size: 11, weight: .semibold))
                        Image(systemName: "chevron.right")
                            .font(.system(size: 9, weight: .bold))
                    }
                    .foregroundStyle(LeafTheme.brandEmerald)
                }
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(colorScheme == .dark ? LeafTheme.cardDark : LeafTheme.cardLight)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(LeafTheme.cardBorder(for: colorScheme), lineWidth: 0.75)
            )
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button {
                vm.selectedGroupForDetail = summary
            } label: {
                Label("View Group Details", systemImage: "info.circle")
            }

            Button(role: .destructive) {
                vm.groupToDelete = summary
            } label: {
                Label("Delete Group", systemImage: "trash")
            }
        }
    }
}
