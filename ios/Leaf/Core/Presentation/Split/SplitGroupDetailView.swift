import SwiftUI

/// Dedicated detail view for an individual SplitGroup.
/// Hosts group expenses, participant position, expense creation within the group,
/// and provides the primary entry point to Split Group Expense Analytics.
public struct SplitGroupDetailView: View {
    @Environment(AppContainer.self) private var container
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss

    public let groupId: Int64

    @State private var group: SplitGroup? = nil
    @State private var expenses: [SplitExpense] = []
    @State private var categories: [Category] = []
    @State private var currency: Currency = .default
    @State private var isLoading: Bool = true
    @State private var errorMessage: String? = nil

    // Sheets & Navigation
    @State private var isAddExpenseSheetPresented: Bool = false
    @State private var selectedSplitForDetail: SplitExpense? = nil
    @State private var isEditGroupPresented: Bool = false
    @State private var showDeleteConfirmation: Bool = false

    public init(groupId: Int64) {
        self.groupId = groupId
    }

    private var totalGroupSpending: Amount {
        let subunits = expenses.reduce(Int64(0)) { $0 + $1.totalAmount.subunits }
        return Amount(subunits: subunits)
    }

    private var uniqueParticipantsCount: Int {
        var names = Set<String>()
        for exp in expenses {
            for p in exp.participants {
                let trimmed = p.name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                if !trimmed.isEmpty { names.insert(trimmed) }
            }
        }
        return max(1, names.count)
    }

    public var body: some View {
        ZStack {
            LeafTheme.canvas(for: colorScheme).ignoresSafeArea()

            if let item = group {
                ScrollView {
                    VStack(spacing: 20) {
                        // 1. Group Header Hero Card
                        groupHeaderCard(item)

                        // 2. PROMINENT GROUP ANALYTICS BANNER / ENTRY POINT
                        groupAnalyticsEntryCard(item)

                        // 3. Group Expenses List
                        groupExpensesSection

                        Spacer(minLength: 32)
                    }
                    .padding(.top, 8)
                }
                .refreshable {
                    await loadGroupData()
                }
            } else if isLoading {
                ProgressView().tint(LeafTheme.brandEmerald)
            } else {
                EmptyStateCard(
                    icon: "exclamationmark.triangle",
                    title: "Group Not Found",
                    message: "The requested split group could not be found."
                )
            }
        }
        .navigationTitle(group?.name ?? "Group Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        isEditGroupPresented = true
                    } label: {
                        Label("Edit Group", systemImage: "pencil")
                    }

                    Button(role: .destructive) {
                        showDeleteConfirmation = true
                    } label: {
                        Label("Delete Group", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.system(size: 17))
                        .foregroundStyle(LeafTheme.textPrimary(for: colorScheme))
                }
            }
        }
        .task {
            await loadGroupData()
        }
        .sheet(isPresented: $isAddExpenseSheetPresented) {
            CreateSplitSheet(
                currency: currency,
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
                        groupId: groupId,
                        participants: participants
                    )
                    await loadGroupData()
                }
            )
        }
        .sheet(isPresented: $isEditGroupPresented) {
            if let currentGroup = group {
                CreateGroupSheet(
                    existingGroup: currentGroup,
                    onSave: { updatedName, updatedIcon, updatedColor in
                        try await container.saveSplitGroupUseCase.execute(
                            id: currentGroup.id,
                            name: updatedName,
                            iconName: updatedIcon,
                            colorHex: updatedColor
                        )
                        await loadGroupData()
                    }
                )
            }
        }
        .navigationDestination(item: $selectedSplitForDetail) { split in
            SplitDetailView(
                splitId: split.id,
                splitRepository: container.splitRepository,
                settleParticipantUseCase: container.settleParticipantUseCase,
                deleteSplitExpenseUseCase: container.deleteSplitExpenseUseCase,
                recordParticipantPaymentUseCase: container.recordParticipantPaymentUseCase,
                reverseParticipantPaymentUseCase: container.reverseParticipantPaymentUseCase,
                currency: currency,
                onDataChanged: {
                    await loadGroupData()
                }
            )
        }
        .confirmationDialog(
            "Delete Group?",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete Group", role: .destructive) {
                Task {
                    try? await container.deleteSplitGroupUseCase.execute(id: groupId)
                    dismiss()
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Deleting this group will unassign its expenses. The expenses themselves will remain preserved in Split & Collect.")
        }
    }

    // MARK: - Group Header Hero Card

    @ViewBuilder
    private func groupHeaderCard(_ group: SplitGroup) -> some View {
        SquircleCard(cornerRadius: 18) {
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(Color(hex: group.colorHex).opacity(0.18))
                            .frame(width: 52, height: 52)
                        Image(systemName: group.iconName)
                            .font(.system(size: 24))
                            .foregroundStyle(Color(hex: group.colorHex))
                    }

                    VStack(alignment: .leading, spacing: 3) {
                        Text(group.name)
                            .font(LeafTypography.titleMedium)
                            .foregroundStyle(LeafTheme.textPrimary(for: colorScheme))

                        Text("Created \(DateFormatter.localizedString(from: Date(timeIntervalSince1970: Double(group.createdAt) / 1000.0), dateStyle: .medium, timeStyle: .none))")
                            .font(LeafTypography.caption)
                            .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
                    }

                    Spacer()
                }

                Divider()

                HStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("TOTAL GROUP EXPENSES")
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .tracking(0.8)
                            .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
                        Text(totalGroupSpending.formatted(with: currency))
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundStyle(LeafTheme.textPrimary(for: colorScheme))
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 2) {
                        Text("ACTIVITY")
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .tracking(0.8)
                            .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
                        Text("\(expenses.count) expenses • \(uniqueParticipantsCount) members")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(LeafTheme.brandEmerald)
                    }
                }
            }
            .padding(18)
        }
        .padding(.horizontal, 16)
    }

    // MARK: - Prominent Group Analytics Entry Card

    @ViewBuilder
    private func groupAnalyticsEntryCard(_ group: SplitGroup) -> some View {
        NavigationLink {
            SplitGroupAnalyticsView(groupId: group.id, container: container)
        } label: {
            SquircleCard(cornerRadius: 16) {
                HStack(spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [LeafTheme.brandEmerald, LeafTheme.brandEmerald.opacity(0.75)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 46, height: 46)

                        Image(systemName: "chart.pie.fill")
                            .font(.system(size: 22))
                            .foregroundStyle(Color.white)
                    }

                    VStack(alignment: .leading, spacing: 3) {
                        HStack(spacing: 6) {
                            Text("Group Analytics")
                                .font(LeafTypography.bodyBold)
                                .foregroundStyle(LeafTheme.textPrimary(for: colorScheme))

                            Text("INSIGHTS")
                                .font(.system(size: 9, weight: .bold, design: .rounded))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(LeafTheme.brandEmerald.opacity(0.15))
                                .foregroundStyle(LeafTheme.brandEmerald)
                                .cornerRadius(6)
                        }

                        Text("Where money went: category distribution & spending timeline")
                            .font(LeafTypography.caption)
                            .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
                            .lineLimit(1)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(LeafTheme.brandEmerald)
                }
                .padding(16)
            }
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 16)
    }

    // MARK: - Group Expenses Section

    @ViewBuilder
    private var groupExpensesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("GROUP EXPENSES")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .tracking(1.0)
                    .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))

                Spacer()

                Button {
                    isAddExpenseSheetPresented = true
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "plus")
                            .font(.system(size: 11, weight: .bold))
                        Text("Add Expense")
                            .font(LeafTypography.captionBold)
                    }
                    .foregroundStyle(LeafTheme.brandEmerald)
                }
            }
            .padding(.horizontal, 16)

            if !expenses.isEmpty {
                VStack(spacing: 10) {
                    ForEach(expenses) { expense in
                        Button {
                            selectedSplitForDetail = expense
                        } label: {
                            SquircleCard(cornerRadius: 14) {
                                HStack(spacing: 12) {
                                    ZStack {
                                        Circle()
                                            .fill(LeafTheme.brandEmerald.opacity(0.12))
                                            .frame(width: 42, height: 42)
                                        Image(systemName: "receipt")
                                            .font(.system(size: 17))
                                            .foregroundStyle(LeafTheme.brandEmerald)
                                    }

                                    VStack(alignment: .leading, spacing: 2) {
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
                                        }
                                    }

                                    Spacer()

                                    Text(expense.totalAmount.formatted(with: currency))
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
                    VStack(spacing: 12) {
                        Image(systemName: "tray")
                            .font(.system(size: 32))
                            .foregroundStyle(LeafTheme.textTertiary(for: colorScheme))

                        Text("No expenses in this group yet")
                            .font(LeafTypography.bodyBold)
                            .foregroundStyle(LeafTheme.textPrimary(for: colorScheme))

                        Text("Add group expenses like trips, dinners, or shared bills to track balances and see category analytics.")
                            .font(LeafTypography.caption)
                            .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 16)

                        Button {
                            isAddExpenseSheetPresented = true
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "plus")
                                Text("Add First Group Expense")
                            }
                            .font(LeafTypography.captionBold)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(LeafTheme.brandEmerald)
                            .foregroundStyle(Color.white)
                            .cornerRadius(10)
                        }
                        .padding(.top, 4)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(24)
                }
                .padding(.horizontal, 16)
            }
        }
    }

    // MARK: - Data Loading

    private func loadGroupData() async {
        isLoading = true
        errorMessage = nil

        do {
            let prefs = try await container.preferencesRepository.getUserPreferences()
            self.currency = Currency.fromCode(prefs.currencyCode)

            self.group = try await container.splitRepository.getSplitGroup(id: groupId)
            self.expenses = try await container.splitRepository.getSplitExpensesForGroup(groupId: groupId)
            self.categories = try await container.categoryRepository.getAllCategories()
        } catch {
            self.errorMessage = "Failed to load group: \(error.localizedDescription)"
        }

        isLoading = false
    }
}

