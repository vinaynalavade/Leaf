import SwiftUI

/// The primary financial anchor screen for Leaf iOS.
/// Renders the luxury Hero Balance card, instant quick actions, 4-tier budget progress indicator,
/// and live recent transactions ledger with native iOS interactions and pull-to-refresh.
public struct DashboardView: View {
    @Environment(AppContainer.self) private var container
    @Environment(\.colorScheme) private var colorScheme

    @Binding public var selectedTab: Int

    @State private var viewModel: DashboardViewModel?
    @State private var isAddExpenseSheetPresented: Bool = false
    @State private var isAddIncomeSheetPresented: Bool = false
    @State private var isSettingsSheetPresented: Bool = false
    @State private var isRecurringHubPresented: Bool = false
    @State private var isLedgersHubPresented: Bool = false
    @State private var categories: [Category] = []

    public init(selectedTab: Binding<Int> = .constant(0)) {
        self._selectedTab = selectedTab
    }

    public var body: some View {
        ZStack {
            LeafTheme.canvas(for: colorScheme).ignoresSafeArea()

            if let vm = viewModel {
                ScrollView {
                    VStack(spacing: 20) {
                        // 1. Personalized Header
                        DashboardHeaderView(
                            profileName: vm.profileName,
                            onProfileTap: { isSettingsSheetPresented = true }
                        )

                        // 2. Main Balance Hero Card with Cashflow Sub-Wells
                        BalanceHeroCardView(
                            currentBalance: vm.summary.currentBalance,
                            monthlyIncome: vm.monthlyIncome,
                            monthlyExpense: vm.monthlyExpense,
                            currency: vm.selectedCurrency,
                            isBalanceVisible: vm.isBalanceVisible,
                            cashBalance: vm.cashBalance,
                            accountBalance: vm.accountBalance,
                            onToggleVisibility: { vm.toggleBalanceVisibility() },
                            onLedgerTap: { isLedgersHubPresented = true }
                        )

                        // 3. Quick Action Buttons
                        QuickActionsRowView(
                            onAddExpense: { isAddExpenseSheetPresented = true },
                            onAddIncome: { isAddIncomeSheetPresented = true },
                            onSplitBill: { selectedTab = 2 }, // Navigate to Split & Collect
                            onPlanning: { selectedTab = 3 }   // Navigate to Planning
                        )

                        // 4. Monthly Budget Overview (4-Tier Progress Indicator)
                        DashboardBudgetSectionView(
                            budgetProgress: vm.featuredBudget,
                            currency: vm.selectedCurrency,
                            isBalanceVisible: vm.isBalanceVisible,
                            onBudgetTap: { selectedTab = 3 } // Navigate to Planning
                        )

                        // 4a. Upcoming Bills & Scheduled Obligations
                        DashboardUpcomingBillsSectionView(
                            summary: vm.upcomingBillsSummary,
                            currency: vm.selectedCurrency,
                            isBalanceVisible: vm.isBalanceVisible,
                            onPayBill: { occId in
                                Task { await vm.payBill(occurrenceId: occId) }
                            },
                            onSeeAll: {
                                isRecurringHubPresented = true
                            }
                        )

                        // 4b. Active Savings Goals Preview (if configured)
                        if !vm.activeGoals.isEmpty {
                            dashboardSavingsGoalsSection(vm)
                        }

                        // 4c. Financial Calculators & Tools Access Banner
                        dashboardToolsBanner()

                        // 5. Recent Activity Ledger
                        RecentTransactionsSectionView(
                            transactions: vm.recentTransactions,
                            currency: vm.selectedCurrency,
                            isBalanceVisible: vm.isBalanceVisible,
                            onSeeAll: { selectedTab = 1 }, // Navigate to Transactions
                            onAddTransaction: { isAddExpenseSheetPresented = true },
                            onDeleteTransaction: { id in
                                Task { await vm.deleteTransaction(id: id) }
                            }
                        )

                        Spacer(minLength: 32)
                    }
                    .padding(.top, 8)
                }
                .refreshable {
                    await vm.loadData()
                }
            } else {
                ProgressView()
                    .tint(LeafTheme.accent(for: colorScheme))
            }
        }
        .navigationTitle("")
        .navigationBarHidden(true)
        .navigationDestination(isPresented: $isRecurringHubPresented) {
            RecurringHubView()
        }
        .task {
            if viewModel == nil {
                let vm = DashboardViewModel(
                    getFinancialSummaryUseCase: container.getFinancialSummaryUseCase,
                    getBudgetProgressUseCase: container.getBudgetProgressUseCase,
                    getTransactionsUseCase: container.getTransactionsUseCase,
                    deleteTransactionUseCase: container.deleteTransactionUseCase,
                    getSavingsGoalsUseCase: container.getSavingsGoalsUseCase,
                    getUpcomingBillsUseCase: container.getUpcomingBillsUseCase,
                    markBillAsPaidUseCase: container.markBillAsPaidUseCase,
                    preferencesRepository: container.preferencesRepository
                )
                self.viewModel = vm
                await vm.loadData()

                // Cache categories for fast quick-add sheet presentation
                if let loadedCategories = try? await container.categoryRepository.getAllCategories() {
                    self.categories = loadedCategories
                }
            } else {
                await viewModel?.loadData()
            }
        }
        .onAppear {
            if let vm = viewModel {
                Task { await vm.loadData() }
            }
        }
        .sheet(isPresented: $isAddExpenseSheetPresented) {
            QuickAddTransactionSheet(
                initialType: .expense,
                currency: viewModel?.selectedCurrency ?? .default,
                categories: categories,
                onSave: { amount, type, categoryId, paymentMethod, note, timestamp in
                    _ = try await container.addTransactionUseCase.execute(
                        amount: amount,
                        type: type,
                        categoryId: categoryId,
                        paymentMethod: paymentMethod,
                        note: note,
                        timestamp: timestamp
                    )
                    await viewModel?.loadData()
                }
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $isAddIncomeSheetPresented) {
            QuickAddTransactionSheet(
                initialType: .income,
                currency: viewModel?.selectedCurrency ?? .default,
                categories: categories,
                onSave: { amount, type, categoryId, paymentMethod, note, timestamp in
                    _ = try await container.addTransactionUseCase.execute(
                        amount: amount,
                        type: type,
                        categoryId: categoryId,
                        paymentMethod: paymentMethod,
                        note: note,
                        timestamp: timestamp
                    )
                    await viewModel?.loadData()
                }
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $isSettingsSheetPresented) {
            SettingsSheet()
        }
        .sheet(isPresented: $isLedgersHubPresented) {
            LedgersHubView()
        }
    }

    @ViewBuilder
    private func dashboardSavingsGoalsSection(_ vm: DashboardViewModel) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("SAVINGS GOALS")
                    .font(LeafTypography.captionBold)
                    .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))

                Spacer()

                Button(action: { selectedTab = 3 }) {
                    HStack(spacing: 4) {
                        Text("View All")
                            .font(LeafTypography.captionBold)
                            .foregroundStyle(LeafTheme.brandEmerald)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(LeafTheme.brandEmerald)
                    }
                }
            }
            .padding(.horizontal)

            Button(action: { selectedTab = 3 }) {
                SquircleCard(cornerRadius: 20) {
                    HStack(spacing: 14) {
                        ZStack {
                            Circle()
                                .stroke((colorScheme == .dark ? Color.white : Color.black).opacity(0.08), lineWidth: 4.5)
                                .frame(width: 42, height: 42)

                            Circle()
                                .trim(from: 0.0, to: CGFloat(min(1.0, vm.savingsSummary.overallProgressPercentage / 100.0)))
                                .stroke(LeafTheme.brandEmerald, style: StrokeStyle(lineWidth: 4.5, lineCap: .round))
                                .rotationEffect(.degrees(-90))
                                .frame(width: 42, height: 42)

                            Image(systemName: "target")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundStyle(LeafTheme.brandEmerald)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(vm.savingsSummary.activeCount) Active Savings \(vm.savingsSummary.activeCount == 1 ? "Goal" : "Goals")")
                                .font(LeafTypography.titleSmall)
                                .foregroundStyle(LeafTheme.textPrimary(for: colorScheme))

                            if vm.isBalanceVisible {
                                Text("\(vm.savingsSummary.totalSavedAmount.formatted(currency: vm.selectedCurrency)) saved of \(vm.savingsSummary.totalTargetAmount.formatted(currency: vm.selectedCurrency))")
                                    .font(LeafTypography.captionRegular)
                                    .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
                            } else {
                                Text("\(vm.selectedCurrency.symbol)•••••• saved of \(vm.selectedCurrency.symbol)••••••")
                                    .font(LeafTypography.captionRegular)
                                    .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
                            }
                        }

                        Spacer()

                        Text(String(format: "%.0f%%", vm.savingsSummary.overallProgressPercentage))
                            .font(.system(size: 13, weight: .bold, design: .rounded).monospacedDigit())
                            .foregroundStyle(LeafTheme.brandEmerald)
                            .padding(.horizontal, 9)
                            .padding(.vertical, 4)
                            .background(
                                Capsule().fill(LeafTheme.brandEmerald.opacity(0.12))
                            )
                    }
                    .padding(14)
                }
            }
            .buttonStyle(.plain)
            .padding(.horizontal)
        }
    }

    @ViewBuilder
    private func dashboardToolsBanner() -> some View {
        VStack(spacing: 10) {
            NavigationLink {
                ToolsLandingView()
            } label: {
                HStack(spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(LeafTheme.brandEmerald.opacity(0.12))
                            .frame(width: 44, height: 44)

                        Image(systemName: "function")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(LeafTheme.brandEmerald)
                    }

                    VStack(alignment: .leading, spacing: 3) {
                        Text("Financial Tools & Calculators")
                            .font(LeafTypography.bodyBold)
                            .foregroundStyle(LeafTheme.textPrimary(for: colorScheme))

                        Text("EMI, SIP, Term Deposits, GST, & Discounts")
                            .font(LeafTypography.caption)
                            .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .semibold))
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

            NavigationLink {
                WidgetShowcaseView()
            } label: {
                HStack(spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(LeafTheme.brandEmerald.opacity(0.12))
                            .frame(width: 44, height: 44)

                        Image(systemName: "square.grid.2x2.fill")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(LeafTheme.brandEmerald)
                    }

                    VStack(alignment: .leading, spacing: 3) {
                        Text("Home Screen Widgets")
                            .font(LeafTypography.bodyBold)
                            .foregroundStyle(LeafTheme.textPrimary(for: colorScheme))

                        Text("Interactive previews, privacy toggles & installation guide")
                            .font(LeafTypography.caption)
                            .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .semibold))
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
        .padding(.horizontal)
    }
}

