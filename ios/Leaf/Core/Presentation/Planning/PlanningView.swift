import SwiftUI

/// The central Planning screen for Leaf iOS.
/// Houses the Budget Planner with multi-period support (Monthly, Weekly, Yearly, Custom),
/// 4-tier threshold alerts, and the Target-Driven Savings Goals module with deposit & withdrawal workflows.
public struct PlanningView: View {
    @Environment(AppContainer.self) private var container
    @Environment(\.colorScheme) private var colorScheme

    @State private var viewModel: PlanningViewModel?
    @State private var categories: [Category] = []

    public init() {}

    public var body: some View {
        ZStack {
            LeafTheme.canvas(for: colorScheme).ignoresSafeArea()

            if let vm = viewModel {
                ScrollView {
                    VStack(spacing: 20) {
                        // 1. Header & Segment Picker
                        planningHeader(vm)

                        // 2. Overview Card
                        if vm.selectedSection == .budgets {
                            budgetOverviewCard(vm)
                        } else {
                            savingsOverviewCard(vm)
                        }

                        // 3. Content List
                        if vm.selectedSection == .budgets {
                            budgetsListSection(vm)
                        } else {
                            savingsGoalsListSection(vm)
                        }

                        Spacer(minLength: 32)
                    }
                    .padding(.top, 8)
                }
                .refreshable {
                    await vm.loadData()
                }
            } else {
                ProgressView()
                    .tint(LeafTheme.brandEmerald)
            }
        }
        .navigationTitle("Planning")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                HStack(spacing: 8) {
                    NavigationLink {
                        ToolsLandingView()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "function")
                                .font(.system(size: 12, weight: .semibold))
                            Text("Calculators")
                                .font(LeafTypography.captionBold)
                        }
                        .foregroundStyle(LeafTheme.brandEmerald)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(
                            Capsule().fill(LeafTheme.brandEmerald.opacity(0.12))
                        )
                    }

                    NavigationLink {
                        TravelWalletsListView()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "airplane.departure")
                                .font(.system(size: 12, weight: .semibold))
                            Text("Trips")
                                .font(LeafTypography.captionBold)
                        }
                        .foregroundStyle(LeafTheme.brandEmerald)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(
                            Capsule().fill(LeafTheme.brandEmerald.opacity(0.12))
                        )
                    }
                }
            }

            ToolbarItem(placement: .topBarTrailing) {
                Button(action: {
                    guard let vm = viewModel else { return }
                    let generator = UIImpactFeedbackGenerator(style: .medium)
                    generator.impactOccurred()
                    if vm.selectedSection == .budgets {
                        vm.isCreateBudgetSheetPresented = true
                    } else {
                        vm.isCreateGoalSheetPresented = true
                    }
                }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(LeafTheme.brandEmerald)
                }
            }
        }
        // Create Budget Sheet
        .sheet(isPresented: Binding(
            get: { viewModel?.isCreateBudgetSheetPresented ?? false },
            set: { if let vm = viewModel { vm.isCreateBudgetSheetPresented = $0 } }
        )) {
            if let vm = viewModel {
                CreateEditBudgetSheet(
                    categories: categories,
                    defaultYear: vm.selectedYear,
                    defaultMonth: vm.selectedMonth,
                    currency: vm.currency,
                    onSave: { id, catId, amount, month, year, pType, sEpoch, eEpoch, isRecur in
                        try await container.saveBudgetUseCase.execute(
                            id: id,
                            categoryId: catId,
                            amount: amount,
                            month: month,
                            year: year,
                            periodType: pType,
                            startDate: sEpoch,
                            endDate: eEpoch,
                            isRecurring: isRecur
                        )
                        await vm.loadData()
                    }
                )
            }
        }
        // Create Savings Goal Sheet
        .sheet(isPresented: Binding(
            get: { viewModel?.isCreateGoalSheetPresented ?? false },
            set: { if let vm = viewModel { vm.isCreateGoalSheetPresented = $0 } }
        )) {
            if let vm = viewModel {
                CreateEditSavingsGoalSheet(
                    currency: vm.currency,
                    onSave: { id, name, target, initial, targetDate, note, icon, color in
                        try await container.saveSavingsGoalUseCase.execute(
                            id: id,
                            name: name,
                            targetAmount: target,
                            initialSavedAmount: initial,
                            targetDate: targetDate,
                            note: note,
                            iconName: icon,
                            colorHex: color
                        )
                        await vm.loadData()
                    }
                )
            }
        }
        // Quick Deposit Sheet from Card
        .sheet(item: Binding(
            get: { viewModel?.selectedGoalForContribution },
            set: { if let vm = viewModel { vm.selectedGoalForContribution = $0 } }
        )) { goal in
            if let vm = viewModel {
                AddSavingsContributionSheet(
                    goal: goal,
                    currency: vm.currency,
                    onRecordContribution: { amount, note, timestamp, createTx, method in
                        _ = try await container.recordSavingsContributionUseCase.execute(
                            goalId: goal.id,
                            amount: amount,
                            note: note,
                            timestamp: timestamp,
                            createTransaction: createTx,
                            paymentMethod: method
                        )
                        await vm.loadData()
                    }
                )
            }
        }
        // Quick Withdrawal Sheet from Card
        .sheet(item: Binding(
            get: { viewModel?.selectedGoalForWithdrawal },
            set: { if let vm = viewModel { vm.selectedGoalForWithdrawal = $0 } }
        )) { goal in
            if let vm = viewModel {
                AddSavingsWithdrawalSheet(
                    goal: goal,
                    currency: vm.currency,
                    onRecordWithdrawal: { amount, note, timestamp, returnToAccount, method in
                        _ = try await container.recordSavingsWithdrawalUseCase.execute(
                            goalId: goal.id,
                            amount: amount,
                            note: note,
                            timestamp: timestamp,
                            returnToAccount: returnToAccount,
                            paymentMethod: method
                        )
                        await vm.loadData()
                    }
                )
            }
        }
        .task {
            if viewModel == nil {
                let vm = PlanningViewModel(
                    getBudgetProgressUseCase: container.getBudgetProgressUseCase,
                    saveBudgetUseCase: container.saveBudgetUseCase,
                    deleteBudgetUseCase: container.deleteBudgetUseCase,
                    getSavingsGoalsUseCase: container.getSavingsGoalsUseCase,
                    saveSavingsGoalUseCase: container.saveSavingsGoalUseCase,
                    deleteSavingsGoalUseCase: container.deleteSavingsGoalUseCase,
                    setSavingsGoalArchivedUseCase: container.setSavingsGoalArchivedUseCase,
                    recordSavingsContributionUseCase: container.recordSavingsContributionUseCase,
                    reverseSavingsContributionUseCase: container.reverseSavingsContributionUseCase,
                    recordSavingsWithdrawalUseCase: container.recordSavingsWithdrawalUseCase,
                    reverseSavingsWithdrawalUseCase: container.reverseSavingsWithdrawalUseCase,
                    preferencesRepository: container.preferencesRepository
                )
                self.viewModel = vm
                await vm.loadData()

                if let loadedCategories = try? await container.categoryRepository.getAllCategories() {
                    self.categories = loadedCategories
                }
            } else {
                await viewModel?.loadData()
            }
        }
    }

    // MARK: - 1. Header & Segment Control

    @ViewBuilder
    private func planningHeader(_ vm: PlanningViewModel) -> some View {
        VStack(spacing: 12) {
            // Segmented Picker
            SquircleCard(cornerRadius: 18) {
                Picker("Planning Mode", selection: Bindable(vm).selectedSection) {
                    ForEach(PlanningSection.allCases) { section in
                        Text(section.rawValue).tag(section)
                    }
                }
                .pickerStyle(.segmented)
                .padding(8)
            }
            .padding(.horizontal)

            // Month Stepper & Period Filter (for Budgets)
            if vm.selectedSection == .budgets {
                VStack(spacing: 10) {
                    HStack {
                        Button(action: {
                            let generator = UIImpactFeedbackGenerator(style: .light)
                            generator.impactOccurred()
                            vm.goToPreviousMonth()
                        }) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(LeafTheme.textPrimary(for: colorScheme))
                                .frame(width: 36, height: 36)
                                .background(
                                    Circle().fill((colorScheme == .dark ? Color.white : Color.black).opacity(0.06))
                                )
                        }

                        Spacer()

                        Button(action: {
                            let generator = UIImpactFeedbackGenerator(style: .light)
                            generator.impactOccurred()
                            vm.goToCurrentMonth()
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: "calendar")
                                    .font(.system(size: 13, weight: .semibold))
                                Text(vm.formattedPeriodTitle)
                                    .font(LeafTypography.headline)
                            }
                            .foregroundStyle(LeafTheme.textPrimary(for: colorScheme))
                        }

                        Spacer()

                        Button(action: {
                            let generator = UIImpactFeedbackGenerator(style: .light)
                            generator.impactOccurred()
                            vm.goToNextMonth()
                        }) {
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(LeafTheme.textPrimary(for: colorScheme))
                                .frame(width: 36, height: 36)
                                .background(
                                    Circle().fill((colorScheme == .dark ? Color.white : Color.black).opacity(0.06))
                                )
                        }
                    }
                    .padding(.horizontal)

                    // Period Filter Bar
                    periodFilterRow(vm)
                }
            }
        }
    }

    @ViewBuilder
    private func periodFilterRow(_ vm: PlanningViewModel) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // "All" filter chip
                let isAll = vm.selectedPeriodFilter == nil
                Button(action: { vm.selectedPeriodFilter = nil }) {
                    Text("All Periods")
                        .font(LeafTypography.captionBold)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(isAll ? LeafTheme.brandEmerald : LeafTheme.subtleCard(for: colorScheme))
                        .foregroundStyle(isAll ? .white : LeafTheme.textSecondary(for: colorScheme))
                        .clipShape(Capsule())
                }

                ForEach(BudgetPeriodType.allCases, id: \.self) { pType in
                    let isSelected = vm.selectedPeriodFilter == pType
                    Button(action: { vm.selectedPeriodFilter = pType }) {
                        HStack(spacing: 4) {
                            Image(systemName: pType.iconName)
                                .font(.system(size: 10))
                            Text(pType.displayName)
                        }
                        .font(LeafTypography.captionBold)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(isSelected ? LeafTheme.brandEmerald : LeafTheme.subtleCard(for: colorScheme))
                        .foregroundStyle(isSelected ? .white : LeafTheme.textSecondary(for: colorScheme))
                        .clipShape(Capsule())
                    }
                }
            }
            .padding(.horizontal)
        }
    }

    // MARK: - 2. Budget Overview Card

    @ViewBuilder
    private func budgetOverviewCard(_ vm: PlanningViewModel) -> some View {
        let statusColor = LeafTheme.budgetStatusColor(for: vm.overallBudgetStatus)

        SquircleCard(cornerRadius: 22) {
            VStack(spacing: 16) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("TOTAL SPENT")
                            .font(LeafTypography.captionBold)
                            .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
                            .tracking(0.5)

                        Text(vm.totalBudgetSpent.formatted(currency: vm.currency))
                            .font(.system(size: 32, weight: .bold, design: .rounded).monospacedDigit())
                            .foregroundStyle(LeafTheme.textPrimary(for: colorScheme))
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 4) {
                        Text(vm.overallBudgetStatus.displayName)
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundStyle(statusColor)
                            .padding(.horizontal, 9)
                            .padding(.vertical, 4)
                            .background(
                                Capsule().fill(statusColor.opacity(0.12))
                            )

                        Text("Limit: \(vm.totalAllocatedBudget.formatted(currency: vm.currency))")
                            .font(LeafTypography.captionRegular)
                            .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
                    }
                }

                // Overall Progress Bar
                VStack(spacing: 6) {
                    HStack {
                        Text(String(format: "%.0f%% utilized", vm.overallBudgetPercentage))
                            .font(LeafTypography.captionRegular)
                            .foregroundStyle(statusColor)

                        Spacer()

                        Text("\(vm.totalBudgetRemaining.formatted(currency: vm.currency)) remaining")
                            .font(LeafTypography.captionRegular)
                            .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
                    }

                    GeometryReader { geo in
                        let ratio = max(0.0, min(1.0, vm.overallBudgetPercentage / 100.0))
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill((colorScheme == .dark ? Color.white : Color.black).opacity(0.08))
                                .frame(height: 7)

                            Capsule()
                                .fill(statusColor)
                                .frame(width: max(7, geo.size.width * CGFloat(ratio)), height: 7)
                        }
                    }
                    .frame(height: 7)
                }
            }
            .padding(18)
        }
        .padding(.horizontal)
    }

    // MARK: - 3. Savings Goals Overview Card

    @ViewBuilder
    private func savingsOverviewCard(_ vm: PlanningViewModel) -> some View {
        let summary = vm.savingsSummary

        SquircleCard(cornerRadius: 22) {
            VStack(spacing: 16) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("TOTAL SAVED")
                            .font(LeafTypography.captionBold)
                            .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
                            .tracking(0.5)

                        Text(summary.totalSavedAmount.formatted(currency: vm.currency))
                            .font(.system(size: 32, weight: .bold, design: .rounded).monospacedDigit())
                            .foregroundStyle(LeafTheme.textPrimary(for: colorScheme))
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 4) {
                        HStack(spacing: 4) {
                            Image(systemName: "target")
                            Text("\(summary.activeCount) Active \(summary.activeCount == 1 ? "Goal" : "Goals")")
                        }
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundStyle(LeafTheme.brandEmerald)
                        .padding(.horizontal, 9)
                        .padding(.vertical, 4)
                        .background(
                            Capsule().fill(LeafTheme.brandEmerald.opacity(0.12))
                        )

                        if summary.completedCount > 0 {
                            Text("\(summary.completedCount) Completed")
                                .font(LeafTypography.captionRegular)
                                .foregroundStyle(LeafTheme.brandEmerald)
                        }
                    }
                }

                // Progress Bar
                VStack(spacing: 6) {
                    HStack {
                        Text(String(format: "%.0f%% of total targets achieved", summary.overallProgressPercentage))
                            .font(LeafTypography.captionRegular)
                            .foregroundStyle(LeafTheme.brandEmerald)

                        Spacer()

                        Text("Target: \(summary.totalTargetAmount.formatted(currency: vm.currency))")
                            .font(LeafTypography.captionRegular)
                            .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
                    }

                    GeometryReader { geo in
                        let ratio = max(0.0, min(1.0, summary.overallProgressPercentage / 100.0))
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill((colorScheme == .dark ? Color.white : Color.black).opacity(0.08))
                                .frame(height: 7)

                            Capsule()
                                .fill(LeafTheme.brandEmerald)
                                .frame(width: max(7, geo.size.width * CGFloat(ratio)), height: 7)
                        }
                    }
                    .frame(height: 7)
                }
            }
            .padding(18)
        }
        .padding(.horizontal)
    }

    // MARK: - 4. Budgets List Section

    @ViewBuilder
    private func budgetsListSection(_ vm: PlanningViewModel) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("BUDGET ALLOCATIONS")
                    .font(LeafTypography.captionBold)
                    .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
                    .tracking(0.5)

                Spacer()

                Text("\(vm.displayedBudgets.count) configured")
                    .font(LeafTypography.captionRegular)
                    .foregroundStyle(LeafTheme.textTertiary(for: colorScheme))
            }
            .padding(.horizontal)

            // Planned Obligations Disclosure Note
            SquircleCard(cornerRadius: 14) {
                HStack(spacing: 12) {
                    Image(systemName: "arrow.triangle.2.circlepath.circle.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(LeafTheme.brandEmerald)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Planned Recurring Obligations")
                            .font(LeafTypography.captionBold)
                            .foregroundStyle(LeafTheme.textPrimary(for: colorScheme))

                        Text("Upcoming bills and recurring commitments do not consume budget progress until marked as paid.")
                            .font(LeafTypography.caption)
                            .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
                    }

                    Spacer()

                    NavigationLink {
                        RecurringHubView()
                    } label: {
                        Text("Manage")
                            .font(LeafTypography.captionBold)
                            .foregroundStyle(LeafTheme.brandEmerald)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(
                                Capsule().fill(LeafTheme.brandEmerald.opacity(0.12))
                            )
                    }
                }
                .padding(12)
            }
            .padding(.horizontal)

            if vm.displayedBudgets.isEmpty {
                emptyBudgetsView(vm)
            } else {
                ForEach(vm.displayedBudgets) { progress in
                    NavigationLink {
                        BudgetDetailView(
                            progress: progress,
                            currency: vm.currency,
                            categories: categories,
                            transactionRepository: container.transactionRepository,
                            saveBudgetUseCase: container.saveBudgetUseCase,
                            deleteBudgetUseCase: container.deleteBudgetUseCase,
                            onDataChanged: { await vm.loadData() }
                        )
                    } label: {
                        BudgetCardView(
                            progress: progress,
                            currency: vm.currency,
                            onTap: {}
                        )
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal)
                }
            }
        }
    }

    // MARK: - 5. Savings Goals List Section

    @ViewBuilder
    private func savingsGoalsListSection(_ vm: PlanningViewModel) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("SAVINGS GOALS")
                    .font(LeafTypography.captionBold)
                    .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
                    .tracking(0.5)

                Spacer()

                Text("\(vm.activeGoals.count) active")
                    .font(LeafTypography.captionRegular)
                    .foregroundStyle(LeafTheme.textTertiary(for: colorScheme))
            }
            .padding(.horizontal)

            if vm.activeGoals.isEmpty && vm.archivedGoals.isEmpty {
                emptyGoalsView(vm)
            } else {
                ForEach(vm.activeGoals) { goal in
                    NavigationLink {
                        SavingsGoalDetailView(
                            goal: goal,
                            currency: vm.currency,
                            savingsGoalRepository: container.savingsGoalRepository,
                            saveSavingsGoalUseCase: container.saveSavingsGoalUseCase,
                            deleteSavingsGoalUseCase: container.deleteSavingsGoalUseCase,
                            setSavingsGoalArchivedUseCase: container.setSavingsGoalArchivedUseCase,
                            recordSavingsContributionUseCase: container.recordSavingsContributionUseCase,
                            reverseSavingsContributionUseCase: container.reverseSavingsContributionUseCase,
                            recordSavingsWithdrawalUseCase: container.recordSavingsWithdrawalUseCase,
                            onDataChanged: { await vm.loadData() }
                        )
                    } label: {
                        SavingsGoalCardView(
                            goal: goal,
                            currency: vm.currency,
                            onTap: {},
                            onAddContribution: {
                                vm.selectedGoalForContribution = goal
                            },
                            onWithdraw: {
                                vm.selectedGoalForWithdrawal = goal
                            }
                        )
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal)
                }

                // Archived Goals Section
                if !vm.archivedGoals.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("ARCHIVED GOALS")
                            .font(LeafTypography.captionBold)
                            .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
                            .tracking(0.5)
                            .padding(.horizontal)
                            .padding(.top, 14)

                        ForEach(vm.archivedGoals) { goal in
                            NavigationLink {
                                SavingsGoalDetailView(
                                    goal: goal,
                                    currency: vm.currency,
                                    savingsGoalRepository: container.savingsGoalRepository,
                                    saveSavingsGoalUseCase: container.saveSavingsGoalUseCase,
                                    deleteSavingsGoalUseCase: container.deleteSavingsGoalUseCase,
                                    setSavingsGoalArchivedUseCase: container.setSavingsGoalArchivedUseCase,
                                    recordSavingsContributionUseCase: container.recordSavingsContributionUseCase,
                                    reverseSavingsContributionUseCase: container.reverseSavingsContributionUseCase,
                                    recordSavingsWithdrawalUseCase: container.recordSavingsWithdrawalUseCase,
                                    onDataChanged: { await vm.loadData() }
                                )
                            } label: {
                                SavingsGoalCardView(
                                    goal: goal,
                                    currency: vm.currency,
                                    onTap: {},
                                    onAddContribution: {
                                        vm.selectedGoalForContribution = goal
                                    },
                                    onWithdraw: {
                                        vm.selectedGoalForWithdrawal = goal
                                    }
                                )
                            }
                            .buttonStyle(.plain)
                            .padding(.horizontal)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Empty States

    @ViewBuilder
    private func emptyBudgetsView(_ vm: PlanningViewModel) -> some View {
        SquircleCard(cornerRadius: 20) {
            VStack(spacing: 12) {
                Image(systemName: "chart.bar.xaxis")
                    .font(.system(size: 38))
                    .foregroundStyle(LeafTheme.brandEmerald)

                Text("No Budgets for \(vm.formattedPeriodTitle)")
                    .font(LeafTypography.titleSmall)
                    .foregroundStyle(LeafTheme.textPrimary(for: colorScheme))

                Text("Set an overall monthly cap or category budgets to stay on track and prevent overspending.")
                    .font(LeafTypography.bodySmall)
                    .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                Button(action: {
                    vm.isCreateBudgetSheetPresented = true
                }) {
                    Text("Create Budget")
                        .font(LeafTypography.headline)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(LeafTheme.brandEmerald)
                        .clipShape(Capsule())
                }
                .padding(.top, 4)
            }
            .padding(.vertical, 24)
            .frame(maxWidth: .infinity)
        }
        .padding(.horizontal)
    }

    @ViewBuilder
    private func emptyGoalsView(_ vm: PlanningViewModel) -> some View {
        SquircleCard(cornerRadius: 20) {
            VStack(spacing: 12) {
                Image(systemName: "target")
                    .font(.system(size: 38))
                    .foregroundStyle(LeafTheme.brandEmerald)

                Text("No Savings Goals Yet")
                    .font(LeafTypography.titleSmall)
                    .foregroundStyle(LeafTheme.textPrimary(for: colorScheme))

                Text("Define a financial target with custom milestones, target dates, and progress tracking.")
                    .font(LeafTypography.bodySmall)
                    .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                Button(action: {
                    vm.isCreateGoalSheetPresented = true
                }) {
                    Text("Set a Goal")
                        .font(LeafTypography.headline)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(LeafTheme.brandEmerald)
                        .clipShape(Capsule())
                }
                .padding(.top, 4)
            }
            .padding(.vertical, 24)
            .frame(maxWidth: .infinity)
        }
        .padding(.horizontal)
    }
}
