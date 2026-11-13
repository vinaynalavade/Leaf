import SwiftUI

/// Dedicated detail view for an individual budget showing real-time utilization,
/// 4-tier status indicator, period summary, and all associated expense transactions.
public struct BudgetDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    public let initialProgress: BudgetProgress
    public let currency: Currency
    public let categories: [Category]
    public let transactionRepository: TransactionRepositoryProtocol
    public let saveBudgetUseCase: SaveBudgetUseCase
    public let deleteBudgetUseCase: DeleteBudgetUseCase
    public let onDataChanged: () async -> Void

    @State private var progress: BudgetProgress
    @State private var associatedTransactions: [Transaction] = []
    @State private var isLoadingTransactions: Bool = true
    @State private var isEditSheetPresented: Bool = false
    @State private var showDeleteDialog: Bool = false

    public init(
        progress: BudgetProgress,
        currency: Currency = .default,
        categories: [Category],
        transactionRepository: TransactionRepositoryProtocol,
        saveBudgetUseCase: SaveBudgetUseCase,
        deleteBudgetUseCase: DeleteBudgetUseCase,
        onDataChanged: @escaping () async -> Void
    ) {
        self.initialProgress = progress
        self._progress = State(initialValue: progress)
        self.currency = currency
        self.categories = categories
        self.transactionRepository = transactionRepository
        self.saveBudgetUseCase = saveBudgetUseCase
        self.deleteBudgetUseCase = deleteBudgetUseCase
        self.onDataChanged = onDataChanged
    }

    private var statusColor: Color {
        LeafTheme.budgetStatusColor(for: progress.status)
    }

    public var body: some View {
        ZStack {
            LeafTheme.canvas(for: colorScheme).ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    // 1. Hero Progress Card
                    heroCard

                    // 2. Metrics Well
                    metricsSection

                    // 3. Associated Transactions
                    associatedTransactionsSection

                    Spacer(minLength: 32)
                }
                .padding(.top, 8)
            }
            .refreshable {
                await loadAssociatedTransactions()
                await onDataChanged()
            }
        }
        .navigationTitle(progress.category?.name ?? "Overall Budget")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button(action: { isEditSheetPresented = true }) {
                        Label("Edit Budget", systemImage: "pencil")
                    }

                    Button(role: .destructive, action: { showDeleteDialog = true }) {
                        Label("Delete Budget", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.system(size: 16))
                        .foregroundStyle(LeafTheme.textPrimary(for: colorScheme))
                }
            }
        }
        .confirmationDialog(
            "Delete Budget?",
            isPresented: $showDeleteDialog,
            titleVisibility: .visible
        ) {
            Button("Delete Budget", role: .destructive) {
                Task {
                    try? await deleteBudgetUseCase.execute(id: progress.budget.id)
                    await onDataChanged()
                    dismiss()
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to delete this budget? All historical expense transactions will remain intact.")
        }
        .sheet(isPresented: $isEditSheetPresented) {
            CreateEditBudgetSheet(
                existingBudget: progress.budget,
                categories: categories,
                defaultYear: progress.budget.year,
                defaultMonth: progress.budget.month,
                currency: currency,
                onSave: { id, catId, amount, month, year, pType, sEpoch, eEpoch, isRecur in
                    try await saveBudgetUseCase.execute(
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
                    await onDataChanged()
                    await loadAssociatedTransactions()
                }
            )
        }
        .task {
            await loadAssociatedTransactions()
        }
    }

    // MARK: - 1. Hero Card

    private var heroCard: some View {
        SquircleCard(cornerRadius: 22) {
            VStack(spacing: 16) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 6) {
                            Text(progress.budget.periodSummaryLabel)
                                .font(LeafTypography.captionBold)
                                .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))

                            if progress.budget.isRecurring {
                                Image(systemName: "arrow.triangle.2.circlepath")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundStyle(LeafTheme.brandEmerald)
                            }
                        }

                        Text(progress.usedAmount.formatted(currency: currency))
                            .font(.system(size: 34, weight: .bold, design: .rounded).monospacedDigit())
                            .foregroundStyle(LeafTheme.textPrimary(for: colorScheme))

                        Text("of \(progress.budget.amount.formatted(currency: currency)) limit (\(progress.budget.periodType.displayName))")
                            .font(LeafTypography.bodySmall)
                            .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
                    }

                    Spacer()

                    // Status Pill
                    Text(progress.status.displayName)
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(statusColor)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(
                            Capsule().fill(statusColor.opacity(0.14))
                        )
                }

                // Custom Thick Progress Bar
                GeometryReader { geo in
                    let ratio = max(0.0, min(1.0, progress.percentageUsed / 100.0))
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill((colorScheme == .dark ? Color.white : Color.black).opacity(0.08))
                            .frame(height: 10)

                        Capsule()
                            .fill(statusColor)
                            .frame(width: max(6, geo.size.width * CGFloat(ratio)), height: 10)
                    }
                }
                .frame(height: 10)

                HStack {
                    Text(String(format: "%.1f%% of budget used", progress.percentageUsed))
                        .font(LeafTypography.captionBold)
                        .foregroundStyle(statusColor)

                    Spacer()

                    if progress.status == .overBudget {
                        let overspent = Amount(subunits: progress.usedAmount.subunits - progress.budget.amount.subunits)
                        Text("\(overspent.formatted(currency: currency)) over")
                            .font(LeafTypography.captionBold)
                            .foregroundStyle(statusColor)
                    } else {
                        Text("\(progress.remainingAmount.formatted(currency: currency)) left")
                            .font(LeafTypography.captionRegular)
                            .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
                    }
                }
            }
            .padding(18)
        }
        .padding(.horizontal)
    }

    // MARK: - 2. Metrics Well

    private var metricsSection: some View {
        HStack(spacing: 12) {
            SquircleCard(cornerRadius: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("REMAINING")
                        .font(LeafTypography.captionBold)
                        .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
                        .tracking(0.5)

                    Text(progress.remainingAmount.formatted(currency: currency))
                        .font(.system(size: 18, weight: .bold, design: .rounded).monospacedDigit())
                        .foregroundStyle(progress.status == .overBudget ? LeafTheme.coralRose : LeafTheme.brandEmerald)
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            SquircleCard(cornerRadius: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("TRANSACTIONS")
                        .font(LeafTypography.captionBold)
                        .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
                        .tracking(0.5)

                    Text("\(associatedTransactions.count)")
                        .font(.system(size: 18, weight: .bold, design: .rounded).monospacedDigit())
                        .foregroundStyle(LeafTheme.textPrimary(for: colorScheme))
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(.horizontal)
    }

    // MARK: - 3. Associated Transactions Section

    private var associatedTransactionsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("ASSOCIATED EXPENSES")
                .font(LeafTypography.captionBold)
                .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
                .tracking(0.5)
                .padding(.horizontal)

            if isLoadingTransactions {
                SquircleCard(cornerRadius: 18) {
                    ProgressView()
                        .tint(LeafTheme.brandEmerald)
                        .padding(.vertical, 32)
                        .frame(maxWidth: .infinity)
                }
                .padding(.horizontal)
            } else if associatedTransactions.isEmpty {
                SquircleCard(cornerRadius: 18) {
                    VStack(spacing: 8) {
                        Image(systemName: "checkmark.circle")
                            .font(.system(size: 32))
                            .foregroundStyle(LeafTheme.brandEmerald)
                        Text("No spending recorded for this period")
                            .font(LeafTypography.bodySmall)
                            .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
                    }
                    .padding(.vertical, 32)
                    .frame(maxWidth: .infinity)
                }
                .padding(.horizontal)
            } else {
                SquircleCard(cornerRadius: 18) {
                    VStack(spacing: 0) {
                        ForEach(Array(associatedTransactions.enumerated()), id: \.element.id) { idx, tx in
                            if idx > 0 {
                                Divider()
                                    .padding(.leading, 52)
                                    .background(LeafTheme.cardBorder(for: colorScheme))
                            }

                            transactionRow(tx)
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    private func transactionRow(_ tx: Transaction) -> some View {
        HStack(spacing: 12) {
            CategoryIconBadge(
                iconName: tx.category?.iconName ?? "tag",
                colorHex: tx.category?.colorHex ?? "#EF4444",
                size: 36
            )

            VStack(alignment: .leading, spacing: 2) {
                Text(tx.note?.isEmpty == false ? tx.note! : (tx.category?.name ?? "Expense"))
                    .font(LeafTypography.bodyBold)
                    .foregroundStyle(LeafTheme.textPrimary(for: colorScheme))
                    .lineLimit(1)

                Text(formatDate(tx.timestamp))
                    .font(LeafTypography.captionRegular)
                    .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
            }

            Spacer()

            Text("- \(tx.amount.formatted(currency: currency))")
                .font(.system(size: 15, weight: .bold, design: .rounded).monospacedDigit())
                .foregroundStyle(LeafTheme.coralRose)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }

    private func formatDate(_ epochMs: Int64) -> String {
        let date = Date(timeIntervalSince1970: TimeInterval(epochMs) / 1000)
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM, h:mm a"
        return formatter.string(from: date)
    }

    private func loadAssociatedTransactions() async {
        isLoadingTransactions = true
        let (startEpoch, endEpoch) = progress.budget.dateRange()

        let transactions = (try? await transactionRepository.getTransactionsBetween(
            startEpoch: startEpoch,
            endEpoch: endEpoch
        )) ?? []

        let filtered = transactions.filter { tx in
            tx.type == .expense && !tx.isInternalTransfer && (progress.budget.isOverallBudget || tx.categoryId == progress.budget.categoryId)
        }

        associatedTransactions = filtered.sorted { $0.timestamp > $1.timestamp }
        isLoadingTransactions = false
    }
}
