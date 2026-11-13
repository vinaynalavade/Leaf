import SwiftUI

/// Central hub for recurring transactions, bill reminders, and subscriptions.
public struct RecurringHubView: View {
    @Environment(AppContainer.self) private var container
    @Environment(\.colorScheme) private var colorScheme

    @State private var viewModel: RecurringHubViewModel?
    @State private var categories: [Category] = []
    @State private var selectedOccurrenceForSnooze: RecurringTransactionOccurrence?
    @State private var selectedScheduleIdForDetail: Int64?

    public init() {}

    private var currentCurrency: Currency {
        container.preferencesRepository.getUserPreferences().currency
    }

    public var body: some View {
        ZStack {
            LeafTheme.canvas(for: colorScheme).ignoresSafeArea()

            if let vm = viewModel {
                ScrollView {
                    VStack(spacing: 16) {
                        // 1. Top Section Segmented Control
                        SquircleCard(cornerRadius: 16) {
                            Picker("Section", selection: Binding(
                                get: { vm.selectedSection },
                                set: { vm.selectedSection = $0 }
                            )) {
                                ForEach(RecurringHubSection.allCases) { section in
                                    Text(section.rawValue).tag(section)
                                }
                            }
                            .pickerStyle(.segmented)
                            .padding(6)
                        }
                        .padding(.horizontal)

                        // 2. Active Section Content
                        switch vm.selectedSection {
                        case .upcomingBills:
                            upcomingBillsSection(vm)
                        case .allSchedules:
                            allSchedulesSection(vm)
                        case .subscriptions:
                            subscriptionsSection(vm)
                        }

                        Spacer(minLength: 32)
                    }
                    .padding(.top, 10)
                }
                .refreshable {
                    await vm.loadData()
                }
            } else {
                ProgressView()
                    .tint(LeafTheme.brandEmerald)
            }
        }
        .navigationTitle("Recurring & Bills")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    viewModel?.isCreateSheetPresented = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(LeafTheme.brandEmerald)
                }
            }
        }
        .task {
            if viewModel == nil {
                let vm = RecurringHubViewModel(
                    getRecurringTransactionsUseCase: container.getRecurringTransactionsUseCase,
                    getUpcomingBillsUseCase: container.getUpcomingBillsUseCase,
                    getSubscriptionSummaryUseCase: container.getSubscriptionSummaryUseCase,
                    markBillAsPaidUseCase: container.markBillAsPaidUseCase,
                    skipBillOccurrenceUseCase: container.skipBillOccurrenceUseCase,
                    snoozeBillReminderUseCase: container.snoozeBillReminderUseCase,
                    pauseRecurringTransactionUseCase: container.pauseRecurringTransactionUseCase,
                    resumeRecurringTransactionUseCase: container.resumeRecurringTransactionUseCase,
                    deleteRecurringTransactionUseCase: container.deleteRecurringTransactionUseCase,
                    generateDueOccurrencesUseCase: container.generateDueOccurrencesUseCase
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
        .sheet(isPresented: Binding(
            get: { viewModel?.isCreateSheetPresented ?? false },
            set: { if let vm = viewModel { vm.isCreateSheetPresented = $0 } }
        )) {
            if let vm = viewModel {
                CreateEditRecurringSheet(
                    categories: categories,
                    currency: currentCurrency,
                    onSave: { id, title, amount, type, catId, method, note, freq, interval, dayMonth, dayWeek, start, end, auto, reminder, isSub, _ in
                        _ = try await container.createRecurringTransactionUseCase.execute(
                            title: title,
                            amount: amount,
                            type: type,
                            categoryId: catId,
                            paymentMethod: method,
                            note: note,
                            frequency: freq,
                            recurrenceInterval: interval,
                            dayOfMonth: dayMonth,
                            dayOfWeek: dayWeek,
                            startDate: start,
                            endDate: end,
                            isAutoGenerated: auto,
                            reminderDaysBefore: reminder,
                            isSubscription: isSub
                        )
                        try? await container.generateDueOccurrencesUseCase.execute()
                        await vm.loadData()
                    }
                )
            }
        }
        .sheet(item: $selectedOccurrenceForSnooze) { occ in
            SnoozeReminderSheet(occurrenceTitle: occ.title) { days in
                Task {
                    await viewModel?.snoozeOccurrence(occurrenceId: occ.id, days: days)
                }
            }
        }
        .navigationDestination(item: $selectedScheduleIdForDetail) { scheduleId in
            RecurringDetailView(scheduleId: scheduleId)
        }
    }

    // MARK: - Section 1: Upcoming Bills & Reminders

    @ViewBuilder
    private func upcomingBillsSection(_ vm: RecurringHubViewModel) -> some View {
        VStack(spacing: 16) {
            // Bills Overview Hero Card
            SquircleCard(cornerRadius: 18) {
                VStack(spacing: 14) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("UPCOMING OBLIGATIONS")
                                .font(LeafTypography.captionBold)
                                .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))

                            Text(vm.upcomingBillsSummary.totalUpcomingAmount.formatted(currency: currentCurrency))
                                .font(LeafTypography.titleLarge)
                                .foregroundStyle(LeafTheme.textPrimary(for: colorScheme))
                        }

                        Spacer()

                        if vm.upcomingBillsSummary.overdueCount > 0 {
                            VStack(alignment: .trailing, spacing: 2) {
                                Text("\(vm.upcomingBillsSummary.overdueCount) Overdue")
                                    .font(LeafTypography.captionBold)
                                    .foregroundStyle(LeafTheme.expenseCoral)

                                Text(vm.upcomingBillsSummary.totalOverdueAmount.formatted(currency: currentCurrency))
                                    .font(LeafTypography.headline)
                                    .foregroundStyle(LeafTheme.expenseCoral)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(LeafTheme.expenseCoral.opacity(0.12))
                            .cornerRadius(10)
                        }
                    }

                    HStack(spacing: 8) {
                        metricBadge(label: "Due Today", count: vm.upcomingBillsSummary.dueTodayCount, color: LeafTheme.warningGold)
                        metricBadge(label: "Upcoming", count: vm.upcomingBillsSummary.upcomingCount, color: LeafTheme.infoBlue)
                    }
                }
                .padding(16)
            }
            .padding(.horizontal)

            // Notification Permission Callout
            if vm.notificationStatus == .notDetermined {
                SquircleCard(cornerRadius: 14) {
                    HStack(spacing: 12) {
                        Image(systemName: "bell.badge.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(LeafTheme.brandEmerald)

                        VStack(alignment: .leading, spacing: 3) {
                            Text("Enable Bill Reminders")
                                .font(LeafTypography.bodyBold)
                                .foregroundStyle(LeafTheme.textPrimary(for: colorScheme))
                            Text("Receive timely alerts before bills are due so you never miss an obligation.")
                                .font(LeafTypography.caption)
                                .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
                        }

                        Spacer()

                        Button("Enable") {
                            Task {
                                await vm.requestNotificationPermission()
                            }
                        }
                        .font(LeafTypography.captionBold)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(LeafTheme.brandEmerald)
                        .foregroundStyle(Color.white)
                        .cornerRadius(8)
                    }
                    .padding(14)
                }
                .padding(.horizontal)
            } else if vm.notificationStatus == .denied {
                SquircleCard(cornerRadius: 14) {
                    HStack(spacing: 12) {
                        Image(systemName: "bell.slash.fill")
                            .font(.system(size: 18))
                            .foregroundStyle(LeafTheme.warningGold)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Bill Reminders Disabled")
                                .font(LeafTypography.captionBold)
                                .foregroundStyle(LeafTheme.textPrimary(for: colorScheme))
                            Text("Schedules function normally, but local alerts cannot fire without permission.")
                                .font(LeafTypography.caption)
                                .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
                        }

                        Spacer()

                        Button("Settings") {
                            if let url = URL(string: UIApplication.openSettingsURLString) {
                                UIApplication.shared.open(url)
                            }
                        }
                        .font(LeafTypography.captionBold)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(LeafTheme.card(for: colorScheme))
                        .foregroundStyle(LeafTheme.textPrimary(for: colorScheme))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(LeafTheme.border(for: colorScheme), lineWidth: 1)
                        )
                    }
                    .padding(12)
                }
                .padding(.horizontal)
            }

            // Filter Chips
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(BillsFilter.allCases) { filter in
                        Button {
                            vm.billsFilter = filter
                        } label: {
                            Text(filter.rawValue)
                                .font(LeafTypography.captionBold)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(
                                    vm.billsFilter == filter
                                        ? LeafTheme.brandEmerald.opacity(0.15)
                                        : LeafTheme.card(for: colorScheme)
                                )
                                .foregroundStyle(
                                    vm.billsFilter == filter
                                        ? LeafTheme.brandEmerald
                                        : LeafTheme.textPrimary(for: colorScheme)
                                )
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(
                                            vm.billsFilter == filter
                                                ? LeafTheme.brandEmerald
                                                : LeafTheme.border(for: colorScheme),
                                            lineWidth: 1
                                        )
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal)
            }

            // Bills List
            let bills = vm.filteredBills
            if bills.isEmpty {
                EmptyStateCard(
                    title: "No Bills Found",
                    subtitle: "No scheduled bill occurrences matching '\(vm.billsFilter.rawValue)'.",
                    iconName: "checkmark.seal.fill"
                )
                .padding(.horizontal)
                .padding(.top, 20)
            } else {
                LazyVStack(spacing: 10) {
                    ForEach(bills) { occ in
                        UpcomingBillCardView(
                            occurrence: occ,
                            currency: currentCurrency,
                            onMarkAsPaid: {
                                Task { await vm.markAsPaid(occurrenceId: occ.id) }
                            },
                            onSkip: {
                                Task { await vm.skipOccurrence(occurrenceId: occ.id) }
                            },
                            onSnooze: {
                                selectedOccurrenceForSnooze = occ
                            },
                            onTap: {
                                selectedScheduleIdForDetail = occ.recurringTransactionId
                            }
                        )
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    // MARK: - Section 2: All Recurring Schedules

    @ViewBuilder
    private func allSchedulesSection(_ vm: RecurringHubViewModel) -> some View {
        VStack(spacing: 12) {
            if vm.allSchedules.isEmpty {
                EmptyStateCard(
                    title: "No Recurring Schedules",
                    subtitle: "Schedule salary income, rent, utilities, loan EMIs, or subscriptions.",
                    iconName: "arrow.triangle.2.circlepath",
                    actionTitle: "Create Schedule",
                    onAction: { vm.isCreateSheetPresented = true }
                )
                .padding(.horizontal)
                .padding(.top, 20)
            } else {
                LazyVStack(spacing: 10) {
                    ForEach(vm.allSchedules) { schedule in
                        RecurringScheduleCardView(
                            schedule: schedule,
                            currency: currentCurrency,
                            onTogglePause: {
                                Task { await vm.togglePause(schedule: schedule) }
                            },
                            onTap: {
                                selectedScheduleIdForDetail = schedule.id
                            }
                        )
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    // MARK: - Section 3: Subscriptions

    @ViewBuilder
    private func subscriptionsSection(_ vm: RecurringHubViewModel) -> some View {
        VStack(spacing: 16) {
            // Subscription Metrics Hero
            SquircleCard(cornerRadius: 18) {
                VStack(spacing: 14) {
                    HStack {
                        VStack(alignment: .leading, spacing: 3) {
                            Text("MONTHLY SUBSCRIPTION SPEND")
                                .font(LeafTypography.captionBold)
                                .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))

                            Text(vm.subscriptionSummary.totalMonthlyAmount.formatted(currency: currentCurrency))
                                .font(LeafTypography.titleLarge)
                                .foregroundStyle(LeafTheme.textPrimary(for: colorScheme))
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: 3) {
                            Text("ANNUAL ESTIMATE")
                                .font(LeafTypography.captionBold)
                                .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))

                            Text(vm.subscriptionSummary.totalAnnualAmount.formatted(currency: currentCurrency))
                                .font(LeafTypography.headline)
                                .foregroundStyle(LeafTheme.purpleAccent)
                        }
                    }

                    HStack(spacing: 8) {
                        metricBadge(label: "Active Services", count: vm.subscriptionSummary.activeCount, color: LeafTheme.brandEmerald)
                        metricBadge(label: "Paused", count: vm.subscriptionSummary.pausedCount, color: LeafTheme.warningGold)
                    }
                }
                .padding(16)
            }
            .padding(.horizontal)

            if vm.subscriptionSummary.subscriptions.isEmpty {
                EmptyStateCard(
                    title: "No Subscriptions Tracked",
                    subtitle: "Track streaming platforms, memberships, cloud storage, and SaaS plans.",
                    iconName: "play.rectangle.fill",
                    actionTitle: "Add Subscription",
                    onAction: { vm.isCreateSheetPresented = true }
                )
                .padding(.horizontal)
                .padding(.top, 20)
            } else {
                LazyVStack(spacing: 10) {
                    ForEach(vm.subscriptionSummary.subscriptions) { sub in
                        SubscriptionCardView(
                            subscription: sub,
                            currency: currentCurrency,
                            onTap: {
                                selectedScheduleIdForDetail = sub.id
                            }
                        )
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    @ViewBuilder
    private func metricBadge(label: String, count: Int, color: Color) -> some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)

            Text("\(count) \(label)")
                .font(LeafTypography.captionBold)
                .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(LeafTheme.card(for: colorScheme))
        .cornerRadius(8)
    }
}

