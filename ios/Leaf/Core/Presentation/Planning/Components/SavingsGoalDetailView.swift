import SwiftUI

/// Dedicated detail view for a savings goal featuring circular progress visualization,
/// milestone status, required monthly savings schedule, deposit/withdrawal action triggers,
/// and complete visual transaction history with reversal support.
public struct SavingsGoalDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    public let initialGoal: SavingsGoal
    public let currency: Currency
    public let savingsGoalRepository: SavingsGoalRepositoryProtocol
    public let saveSavingsGoalUseCase: SaveSavingsGoalUseCase
    public let deleteSavingsGoalUseCase: DeleteSavingsGoalUseCase
    public let setSavingsGoalArchivedUseCase: SetSavingsGoalArchivedUseCase
    public let recordSavingsContributionUseCase: RecordSavingsContributionUseCase
    public let reverseSavingsContributionUseCase: ReverseSavingsContributionUseCase
    public let recordSavingsWithdrawalUseCase: RecordSavingsWithdrawalUseCase
    public let onDataChanged: () async -> Void

    @State private var goal: SavingsGoal
    @State private var isAddContributionSheetPresented: Bool = false
    @State private var isAddWithdrawalSheetPresented: Bool = false
    @State private var isEditSheetPresented: Bool = false
    @State private var showDeleteDialog: Bool = false
    @State private var itemToReverse: SavingsGoalContribution? = nil

    public init(
        goal: SavingsGoal,
        currency: Currency = .default,
        savingsGoalRepository: SavingsGoalRepositoryProtocol,
        saveSavingsGoalUseCase: SaveSavingsGoalUseCase,
        deleteSavingsGoalUseCase: DeleteSavingsGoalUseCase,
        setSavingsGoalArchivedUseCase: SetSavingsGoalArchivedUseCase,
        recordSavingsContributionUseCase: RecordSavingsContributionUseCase,
        reverseSavingsContributionUseCase: ReverseSavingsContributionUseCase,
        recordSavingsWithdrawalUseCase: RecordSavingsWithdrawalUseCase,
        onDataChanged: @escaping () async -> Void
    ) {
        self.initialGoal = goal
        self._goal = State(initialValue: goal)
        self.currency = currency
        self.savingsGoalRepository = savingsGoalRepository
        self.saveSavingsGoalUseCase = saveSavingsGoalUseCase
        self.deleteSavingsGoalUseCase = deleteSavingsGoalUseCase
        self.setSavingsGoalArchivedUseCase = setSavingsGoalArchivedUseCase
        self.recordSavingsContributionUseCase = recordSavingsContributionUseCase
        self.reverseSavingsContributionUseCase = reverseSavingsContributionUseCase
        self.recordSavingsWithdrawalUseCase = recordSavingsWithdrawalUseCase
        self.onDataChanged = onDataChanged
    }

    private var goalColor: Color {
        Color(hex: goal.colorHex) ?? LeafTheme.brandEmerald
    }

    private var hasAvailableFunds: Bool {
        goal.currentSavedAmount.subunits > 0
    }

    public var body: some View {
        ZStack {
            LeafTheme.canvas(for: colorScheme).ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    // 1. Hero Circular Gauge Card
                    heroCard

                    // 2. Schedule & Deficit Well (if target date configured)
                    if goal.targetDate != nil || goal.note != nil {
                        scheduleAndNoteCard
                    }

                    // 3. Dual Action Buttons: Deposit & Withdraw
                    actionButtonsRow

                    // 4. Complete Transaction History List
                    transactionHistorySection

                    Spacer(minLength: 32)
                }
                .padding(.top, 8)
            }
            .refreshable {
                await reloadGoal()
                await onDataChanged()
            }
        }
        .navigationTitle(goal.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button(action: { isEditSheetPresented = true }) {
                        Label("Edit Goal", systemImage: "pencil")
                    }

                    Button(action: {
                        Task {
                            try? await setSavingsGoalArchivedUseCase.execute(id: goal.id, isArchived: !goal.isArchived)
                            await reloadGoal()
                            await onDataChanged()
                        }
                    }) {
                        Label(
                            goal.isArchived ? "Unarchive Goal" : "Archive Goal",
                            systemImage: goal.isArchived ? "tray.and.arrow.up" : "archivebox"
                        )
                    }

                    Button(role: .destructive, action: { showDeleteDialog = true }) {
                        Label("Delete Goal", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.system(size: 16))
                        .foregroundStyle(LeafTheme.textPrimary(for: colorScheme))
                }
            }
        }
        .confirmationDialog(
            "Delete Savings Goal?",
            isPresented: $showDeleteDialog,
            titleVisibility: .visible
        ) {
            Button("Delete Goal", role: .destructive) {
                Task {
                    try? await deleteSavingsGoalUseCase.execute(id: goal.id)
                    await onDataChanged()
                    dismiss()
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to delete '\(goal.name)'? All associated contributions and withdrawals will be removed.")
        }
        .confirmationDialog(
            itemToReverse?.isWithdrawal == true ? "Reverse Withdrawal?" : "Reverse Contribution?",
            isPresented: Binding(
                get: { itemToReverse != nil },
                set: { if !$0 { itemToReverse = nil } }
            ),
            titleVisibility: .visible
        ) {
            if let item = itemToReverse {
                let actionText = item.isWithdrawal
                    ? "Reverse Withdrawal (\(item.displayAmount.formatted(currency: currency)))"
                    : "Reverse Deposit (\(item.displayAmount.formatted(currency: currency)))"

                Button(actionText, role: .destructive) {
                    Task {
                        try? await reverseSavingsContributionUseCase.execute(contributionId: item.id)
                        await reloadGoal()
                        await onDataChanged()
                    }
                }
            }
            Button("Cancel", role: .cancel) {
                itemToReverse = nil
            }
        } message: {
            if itemToReverse?.isWithdrawal == true {
                Text("Reversing this withdrawal will restore the funds back to your savings goal and remove the linked checking account inflow.")
            } else {
                Text("Reversing this deposit will deduct it from your savings total and restore any linked checking balance.")
            }
        }
        .sheet(isPresented: $isAddContributionSheetPresented) {
            AddSavingsContributionSheet(
                goal: goal,
                currency: currency,
                onRecordContribution: { amount, note, timestamp, createTx, method in
                    _ = try await recordSavingsContributionUseCase.execute(
                        goalId: goal.id,
                        amount: amount,
                        note: note,
                        timestamp: timestamp,
                        createTransaction: createTx,
                        paymentMethod: method
                    )
                    await reloadGoal()
                    await onDataChanged()
                }
            )
        }
        .sheet(isPresented: $isAddWithdrawalSheetPresented) {
            AddSavingsWithdrawalSheet(
                goal: goal,
                currency: currency,
                onRecordWithdrawal: { amount, note, timestamp, returnToAccount, method in
                    _ = try await recordSavingsWithdrawalUseCase.execute(
                        goalId: goal.id,
                        amount: amount,
                        note: note,
                        timestamp: timestamp,
                        returnToAccount: returnToAccount,
                        paymentMethod: method
                    )
                    await reloadGoal()
                    await onDataChanged()
                }
            )
        }
        .sheet(isPresented: $isEditSheetPresented) {
            CreateEditSavingsGoalSheet(
                existingGoal: goal,
                currency: currency,
                onSave: { id, name, target, initial, targetDate, note, icon, color in
                    try await saveSavingsGoalUseCase.execute(
                        id: id,
                        name: name,
                        targetAmount: target,
                        initialSavedAmount: initial,
                        targetDate: targetDate,
                        note: note,
                        iconName: icon,
                        colorHex: color
                    )
                    await reloadGoal()
                    await onDataChanged()
                }
            )
        }
    }

    // MARK: - 1. Hero Card

    private var heroCard: some View {
        SquircleCard(cornerRadius: 24) {
            VStack(spacing: 20) {
                // Header with Badge & Status
                HStack {
                    ZStack {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(goalColor.opacity(0.16))
                            .frame(width: 48, height: 48)

                        Image(systemName: systemIcon(for: goal.iconName))
                            .font(.system(size: 22, weight: .bold))
                            .foregroundStyle(goalColor)
                    }

                    VStack(alignment: .leading, spacing: 3) {
                        Text(goal.name)
                            .font(LeafTypography.titleMedium)
                            .foregroundStyle(LeafTheme.textPrimary(for: colorScheme))

                        if goal.isCompleted {
                            Text("Goal Achieved!")
                                .font(LeafTypography.captionBold)
                                .foregroundStyle(LeafTheme.brandEmerald)
                        } else {
                            Text("\(goal.remainingAmount.formatted(currency: currency)) remaining to reach goal")
                                .font(LeafTypography.captionRegular)
                                .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
                        }
                    }

                    Spacer()

                    if goal.isArchived {
                        Text("Archived")
                            .font(LeafTypography.captionBold)
                            .foregroundStyle(LeafTheme.textTertiary(for: colorScheme))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(LeafTheme.subtleCard(for: colorScheme))
                            .clipShape(Capsule())
                    }
                }

                // Circular Progress Gauge
                ZStack {
                    Circle()
                        .stroke((colorScheme == .dark ? Color.white : Color.black).opacity(0.08), lineWidth: 14)
                        .frame(width: 160, height: 160)

                    Circle()
                        .trim(from: 0, to: CGFloat(min(1.0, goal.progressPercentage / 100.0)))
                        .stroke(
                            AngularGradient(
                                colors: [goalColor.opacity(0.7), goalColor],
                                center: .center
                            ),
                            style: StrokeStyle(lineWidth: 14, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                        .frame(width: 160, height: 160)
                        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: goal.progressPercentage)

                    VStack(spacing: 4) {
                        Text(String(format: "%.0f%%", goal.progressPercentage))
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundStyle(LeafTheme.textPrimary(for: colorScheme))

                        Text("SAVED")
                            .font(LeafTypography.captionBold)
                            .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
                            .tracking(0.5)
                    }
                }
                .padding(.vertical, 8)

                // Current vs Target Metrics
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("CURRENT SAVED")
                            .font(LeafTypography.captionBold)
                            .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
                            .tracking(0.5)

                        Text(goal.currentSavedAmount.formatted(currency: currency))
                            .font(.system(size: 18, weight: .bold, design: .rounded).monospacedDigit())
                            .foregroundStyle(goalColor)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    Divider().frame(height: 36)

                    VStack(alignment: .trailing, spacing: 2) {
                        Text("TARGET AMOUNT")
                            .font(LeafTypography.captionBold)
                            .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
                            .tracking(0.5)

                        Text(goal.targetAmount.formatted(currency: currency))
                            .font(.system(size: 18, weight: .bold, design: .rounded).monospacedDigit())
                            .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
                    }
                    .frame(maxWidth: .infinity, alignment: .trailing)
                }
                .padding(.horizontal, 8)
            }
            .padding(18)
        }
        .padding(.horizontal)
    }

    // MARK: - 2. Schedule & Note Card

    private var scheduleAndNoteCard: some View {
        SquircleCard(cornerRadius: 18) {
            VStack(spacing: 12) {
                if let tDate = goal.targetDate {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Target Date")
                                .font(LeafTypography.captionRegular)
                                .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))

                            Text(formatDate(tDate))
                                .font(LeafTypography.bodyBold)
                                .foregroundStyle(LeafTheme.textPrimary(for: colorScheme))
                        }

                        Spacer()

                        if let monthly = goal.requiredMonthlySavings {
                            VStack(alignment: .trailing, spacing: 2) {
                                Text("Suggested Pace")
                                    .font(LeafTypography.captionRegular)
                                    .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))

                                Text("\(monthly.formatted(currency: currency)) / month")
                                    .font(.system(size: 14, weight: .bold, design: .rounded).monospacedDigit())
                                    .foregroundStyle(goalColor)
                            }
                        }
                    }
                }

                if let note = goal.note, !note.isEmpty {
                    if goal.targetDate != nil {
                        Divider().background(LeafTheme.cardBorder(for: colorScheme))
                    }

                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "quote.opening")
                            .font(.system(size: 12))
                            .foregroundStyle(LeafTheme.textTertiary(for: colorScheme))

                        Text(note)
                            .font(LeafTypography.bodySmall)
                            .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
            .padding(16)
        }
        .padding(.horizontal)
    }

    // MARK: - 3. Action Buttons Row

    private var actionButtonsRow: some View {
        HStack(spacing: 12) {
            // Deposit Button
            Button(action: {
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.impactOccurred()
                isAddContributionSheetPresented = true
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "plus.circle.fill")
                    Text("Deposit")
                        .font(LeafTypography.headline)
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(goalColor)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .shadow(color: goalColor.opacity(0.3), radius: 8, y: 3)
            }

            // Withdraw Button
            Button(action: {
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.impactOccurred()
                isAddWithdrawalSheetPresented = true
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.up.right.circle.fill")
                    Text("Withdraw")
                        .font(LeafTypography.headline)
                }
                .foregroundStyle(hasAvailableFunds ? LeafTheme.warningAmber : LeafTheme.textTertiary(for: colorScheme))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(hasAvailableFunds ? LeafTheme.warningAmber.opacity(0.12) : LeafTheme.subtleCard(for: colorScheme))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(hasAvailableFunds ? LeafTheme.warningAmber.opacity(0.3) : LeafTheme.cardBorder(for: colorScheme), lineWidth: 1)
                )
            }
            .disabled(!hasAvailableFunds)
        }
        .padding(.horizontal)
    }

    // MARK: - 4. Transaction History Section

    private var transactionHistorySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("TRANSACTION HISTORY")
                    .font(LeafTypography.captionBold)
                    .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
                    .tracking(0.5)

                Spacer()

                let depositsCount = goal.contributions.filter { !$0.isWithdrawal }.count
                let withdrawalsCount = goal.contributions.filter { $0.isWithdrawal }.count
                Text("\(depositsCount) in, \(withdrawalsCount) out")
                    .font(LeafTypography.captionRegular)
                    .foregroundStyle(LeafTheme.textTertiary(for: colorScheme))
            }
            .padding(.horizontal)

            if goal.contributions.isEmpty {
                SquircleCard(cornerRadius: 18) {
                    VStack(spacing: 8) {
                        Image(systemName: "tray")
                            .font(.system(size: 28))
                            .foregroundStyle(LeafTheme.textTertiary(for: colorScheme))
                        Text("No deposits or withdrawals recorded yet")
                            .font(LeafTypography.bodySmall)
                            .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
                    }
                    .padding(.vertical, 24)
                    .frame(maxWidth: .infinity)
                }
                .padding(.horizontal)
            } else {
                SquircleCard(cornerRadius: 20) {
                    VStack(spacing: 0) {
                        ForEach(Array(goal.contributions.enumerated()), id: \.element.id) { idx, item in
                            if idx > 0 {
                                Divider()
                                    .padding(.leading, 52)
                                    .background(LeafTheme.cardBorder(for: colorScheme))
                            }

                            transactionRow(item)
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    private func transactionRow(_ item: SavingsGoalContribution) -> some View {
        let isWithdrawal = item.isWithdrawal
        let iconName = isWithdrawal ? "arrow.up.right" : "arrow.down.left"
        let iconTint = isWithdrawal ? LeafTheme.warningAmber : goalColor
        let amountPrefix = isWithdrawal ? "-" : "+"
        let amountTint = isWithdrawal ? LeafTheme.warningAmber : LeafTheme.brandEmerald

        return HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(iconTint.opacity(0.12))
                    .frame(width: 36, height: 36)

                Image(systemName: iconName)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(iconTint)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(item.note?.isEmpty == false ? item.note! : (isWithdrawal ? "Savings Withdrawal" : "Savings Deposit"))
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(LeafTheme.textPrimary(for: colorScheme))
                    .lineLimit(1)

                HStack(spacing: 4) {
                    Text(formatDate(item.timestamp))
                        .font(LeafTypography.captionRegular)
                        .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))

                    if item.transactionId != nil {
                        Text(isWithdrawal ? "• Returned to Checking" : "• Checking Deducted")
                            .font(LeafTypography.captionRegular)
                            .foregroundStyle(iconTint)
                    }
                }
            }

            Spacer()

            Text("\(amountPrefix) \(item.displayAmount.formatted(currency: currency))")
                .font(.system(size: 15, weight: .bold, design: .rounded).monospacedDigit())
                .foregroundStyle(amountTint)

            // Reversal Trigger Button
            Button(action: {
                itemToReverse = item
            }) {
                Image(systemName: "arrow.counterclockwise.circle")
                    .font(.system(size: 16))
                    .foregroundStyle(LeafTheme.textTertiary(for: colorScheme))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .contextMenu {
            Button(role: .destructive, action: { itemToReverse = item }) {
                Label(
                    isWithdrawal ? "Reverse Withdrawal" : "Reverse Deposit",
                    systemImage: "arrow.counterclockwise"
                )
            }
        }
    }

    private func formatDate(_ epochMs: Int64) -> String {
        let date = Date(timeIntervalSince1970: TimeInterval(epochMs) / 1000)
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM yyyy, h:mm a"
        return formatter.string(from: date)
    }

    private func systemIcon(for iconName: String) -> String {
        switch iconName.lowercased() {
        case "car", "directions_car": return "car.fill"
        case "home", "house": return "house.fill"
        case "flight", "airplane": return "airplane"
        case "laptop", "computer": return "laptopcomputer"
        case "gift", "card_giftcard": return "gift.fill"
        case "education", "school": return "graduationcap.fill"
        case "shield", "medical_services": return "cross.case.fill"
        default: return "star.fill"
        }
    }

    private func reloadGoal() async {
        if let updated = try? await savingsGoalRepository.getGoal(id: goal.id) {
            goal = updated
        }
    }
}
