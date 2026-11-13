import SwiftUI
import UIKit

/// Detail screen displaying complete participant breakdown, user financial position,
/// interactive partial & full settlements, persistent payment history, WhatsApp sharing, and dynamic UPI QR preview.
public struct SplitDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    public let splitId: Int64
    public let splitRepository: SplitRepositoryProtocol
    public let settleParticipantUseCase: SettleParticipantUseCase
    public let deleteSplitExpenseUseCase: DeleteSplitExpenseUseCase
    public let recordParticipantPaymentUseCase: RecordParticipantPaymentUseCase
    public let reverseParticipantPaymentUseCase: ReverseParticipantPaymentUseCase
    public let currency: Currency
    public let onDataChanged: () async -> Void

    @State private var split: SplitExpense? = nil
    @State private var splitPayments: [SplitPayment] = []
    @State private var isLoading: Bool = true
    @State private var errorMessage: String? = nil

    // Sheets & Dialogs
    @State private var showDeleteDialog: Bool = false
    @State private var isEditSheetPresented: Bool = false
    @State private var selectedParticipantForPayment: SplitParticipant? = nil
    @State private var showParticipantPickerForSettle: Bool = false
    @State private var paymentToReverse: SplitPayment? = nil
    @State private var showQrSheet: Bool = false

    public init(
        splitId: Int64,
        splitRepository: SplitRepositoryProtocol,
        settleParticipantUseCase: SettleParticipantUseCase,
        deleteSplitExpenseUseCase: DeleteSplitExpenseUseCase,
        recordParticipantPaymentUseCase: RecordParticipantPaymentUseCase,
        reverseParticipantPaymentUseCase: ReverseParticipantPaymentUseCase,
        currency: Currency = .default,
        onDataChanged: @escaping () async -> Void
    ) {
        self.splitId = splitId
        self.splitRepository = splitRepository
        self.settleParticipantUseCase = settleParticipantUseCase
        self.deleteSplitExpenseUseCase = deleteSplitExpenseUseCase
        self.recordParticipantPaymentUseCase = recordParticipantPaymentUseCase
        self.reverseParticipantPaymentUseCase = reverseParticipantPaymentUseCase
        self.currency = currency
        self.onDataChanged = onDataChanged
    }

    private func triggerHaptic() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()
        generator.impactOccurred()
    }

    public var body: some View {
        ZStack {
            LeafTheme.canvas(for: colorScheme).ignoresSafeArea()

            if let item = split {
                ScrollView {
                    VStack(spacing: 20) {
                        // 1. Overview Hero Card
                        overviewCard(item)

                        // 2. Prominent Settle Up Action Card
                        heroSettleUpSection(item)

                        // 3. Current User Financial Position
                        userPositionCard(item)

                        // 4. Participant Breakdown List (Partial & Full Payments)
                        participantsBreakdownSection(item)

                        // 5. Persistent Payment History
                        paymentHistorySection(item)

                        // 6. Quick Sharing & QR Actions
                        actionsSection(item)

                        Spacer(minLength: 32)
                    }
                    .padding(.top, 8)
                }
                .refreshable {
                    await loadSplit()
                }
            } else if isLoading {
                ProgressView().tint(LeafTheme.brandEmerald)
            } else {
                EmptyStateCard(
                    icon: "exclamationmark.triangle",
                    title: "Split Not Found",
                    message: "The requested split expense could not be loaded."
                )
            }
        }
        .navigationTitle(split?.title ?? "Split Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button(action: { isEditSheetPresented = true }) {
                        Label("Edit Split", systemImage: "pencil")
                    }

                    Button(role: .destructive, action: { showDeleteDialog = true }) {
                        Label("Delete Split", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.system(size: 16))
                        .foregroundStyle(LeafTheme.textPrimary(for: colorScheme))
                }
            }
        }
        // Delete split confirmation
        .confirmationDialog(
            "Delete Split?",
            isPresented: $showDeleteDialog,
            titleVisibility: .visible
        ) {
            Button("Delete Split", role: .destructive) {
                Task {
                    try? await deleteSplitExpenseUseCase.execute(id: splitId)
                    await onDataChanged()
                    dismiss()
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to delete this split expense? Historical ledger entries will remain preserved.")
        }
        // Reverse payment confirmation
        .confirmationDialog(
            "Reverse Payment?",
            isPresented: Binding(
                get: { paymentToReverse != nil },
                set: { if !$0 { paymentToReverse = nil } }
            ),
            titleVisibility: .visible
        ) {
            if let payment = paymentToReverse {
                Button("Reverse Payment (\(payment.amount.formatted(currency: currency)))", role: .destructive) {
                    Task {
                        try? await reverseParticipantPaymentUseCase.execute(paymentId: payment.id)
                        await loadSplit()
                        await onDataChanged()
                    }
                }
            }
            Button("Cancel", role: .cancel) {
                paymentToReverse = nil
            }
        } message: {
            Text("Reversing this payment will restore the participant's balance and remove any linked personal ledger transaction.")
        }
        // Settle up participant selector confirmation (for payer)
        .confirmationDialog(
            "Record Settlement",
            isPresented: $showParticipantPickerForSettle,
            titleVisibility: .visible
        ) {
            if let item = split {
                let pending = item.participants.filter { !$0.isCurrentUser && $0.settlementStatus != .settled }
                ForEach(pending) { p in
                    Button("\(p.name) (\(p.remainingAmount.formatted(currency: currency)) remaining)") {
                        selectedParticipantForPayment = p
                    }
                }
                Button("Cancel", role: .cancel) {}
            }
        } message: {
            Text("Select which participant paid their share.")
        }
        // Record payment sheet
        .sheet(item: $selectedParticipantForPayment) { p in
            if let item = split {
                RecordPaymentSheet(
                    participant: p,
                    splitTitle: item.title,
                    paidByName: item.paidBy,
                    isCurrentUserPayer: isPayerCurrentUser(item),
                    currency: currency,
                    onRecordPayment: { amount, method, timestamp, note in
                        try await recordParticipantPaymentUseCase.execute(
                            splitExpenseId: item.id,
                            participant: p,
                            amount: amount,
                            paymentMethod: method,
                            date: timestamp,
                            note: note,
                            createOffsetTransaction: item.addToTransactions
                        )
                        await loadSplit()
                        await onDataChanged()
                    }
                )
            }
        }
        // Edit split metadata sheet
        .sheet(isPresented: $isEditSheetPresented) {
            if let item = split {
                EditSplitSheet(
                    split: item,
                    currency: currency,
                    onSave: { updatedSplit in
                        try await splitRepository.updateSplitExpense(updatedSplit)
                        await loadSplit()
                        await onDataChanged()
                    }
                )
            }
        }
        // QR Sheet
        .sheet(isPresented: $showQrSheet) {
            if let item = split {
                upiQrPreviewSheet(item)
            }
        }
        .task {
            await loadSplit()
        }
    }

    // MARK: - 1. Overview Hero Card

    @ViewBuilder
    private func overviewCard(_ item: SplitExpense) -> some View {
        let settledCount = item.participants.filter { $0.settlementStatus == .settled }.count
        let totalCount = item.participants.count
        let totalPaidSubunits = item.participants.reduce(Int64(0)) { $0 + $1.paidAmount.subunits }
        let progress = item.totalAmount.subunits > 0 ? Double(totalPaidSubunits) / Double(item.totalAmount.subunits) : 0.0

        SquircleCard(cornerRadius: 22) {
            VStack(spacing: 16) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("TOTAL BILL")
                            .font(LeafTypography.captionBold)
                            .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
                            .tracking(0.5)

                        Text(item.totalAmount.formatted(currency: currency))
                            .font(.system(size: 32, weight: .bold, design: .rounded).monospacedDigit())
                            .foregroundStyle(LeafTheme.textPrimary(for: colorScheme))
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 4) {
                        HStack(spacing: 4) {
                            Image(systemName: "creditcard")
                            Text("Paid by \(item.paidBy)")
                        }
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(LeafTheme.brandEmerald)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule().fill(LeafTheme.brandEmerald.opacity(0.12))
                        )

                        Text(formatDate(item.date))
                            .font(LeafTypography.captionRegular)
                            .foregroundStyle(LeafTheme.textTertiary(for: colorScheme))
                    }
                }

                // Progress Bar
                VStack(spacing: 6) {
                    HStack {
                        Text("Settlement Progress")
                            .font(LeafTypography.captionRegular)
                            .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
                        Spacer()
                        Text("\(settledCount) of \(totalCount) Settled (\(Int(progress * 100))%)")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundStyle(settledCount == totalCount ? LeafTheme.brandEmerald : LeafTheme.amberAccent)
                    }

                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill((colorScheme == .dark ? Color.white : Color.black).opacity(0.08))
                                .frame(height: 6)

                            Capsule()
                                .fill(settledCount == totalCount ? LeafTheme.brandEmerald : LeafTheme.amberAccent)
                                .frame(width: max(6, geo.size.width * CGFloat(progress)), height: 6)
                        }
                    }
                    .frame(height: 6)
                }
            }
            .padding(18)
        }
        .padding(.horizontal)
    }

    // MARK: - 1b. Prominent Settle Up Hero Banner

    @ViewBuilder
    private func heroSettleUpSection(_ item: SplitExpense) -> some View {
        let isPayer = isPayerCurrentUser(item)
        let myParticipant = item.participants.first { $0.isCurrentUser }
        let myRemaining = myParticipant?.remainingAmount ?? .zero
        let unsettledOthers = item.participants.filter { !$0.isCurrentUser && $0.settlementStatus != .settled }
        let totalUncollectedSubunits = unsettledOthers.reduce(Int64(0)) { $0 + $1.remainingAmount.subunits }
        let isAllSettled = item.participants.allSatisfy { $0.settlementStatus == .settled }

        SquircleCard(cornerRadius: 20) {
            VStack(spacing: 12) {
                if isAllSettled {
                    // Fully Settled Banner
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(LeafTheme.brandEmerald.opacity(0.15))
                                .frame(width: 44, height: 44)
                            Image(systemName: "checkmark.seal.fill")
                                .font(.system(size: 22))
                                .foregroundStyle(LeafTheme.brandEmerald)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text("All Settled Up")
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundStyle(LeafTheme.textPrimary(for: colorScheme))
                            Text("No pending payments remaining for this expense.")
                                .font(LeafTypography.captionRegular)
                                .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
                        }

                        Spacer()
                    }
                    .padding(14)
                } else if !isPayer && myRemaining.subunits > 0, let myPart = myParticipant {
                    // User Owes Money Banner
                    VStack(spacing: 12) {
                        HStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(LeafTheme.expenseCoral.opacity(0.15))
                                    .frame(width: 44, height: 44)
                                Image(systemName: "arrow.up.right.circle.fill")
                                    .font(.system(size: 22))
                                    .foregroundStyle(LeafTheme.expenseCoral)
                            }

                            VStack(alignment: .leading, spacing: 2) {
                                Text("SETTLEMENT DUE")
                                    .font(LeafTypography.captionBold)
                                    .foregroundStyle(LeafTheme.expenseCoral)
                                    .tracking(0.5)

                                Text("You owe \(item.paidBy) \(myRemaining.formatted(currency: currency))")
                                    .font(.system(size: 16, weight: .bold, design: .rounded))
                                    .foregroundStyle(LeafTheme.textPrimary(for: colorScheme))
                            }

                            Spacer()
                        }

                        Button(action: {
                            triggerHaptic()
                            selectedParticipantForPayment = myPart
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "creditcard.fill")
                                    .font(.system(size: 14, weight: .semibold))
                                Text("Settle Up Now (\(myRemaining.formatted(currency: currency)))")
                                    .font(.system(size: 15, weight: .bold, design: .rounded))
                            }
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 46)
                            .background(LeafTheme.brandEmerald)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }
                        .buttonStyle(PlainButtonStyle())
                        .accessibilityLabel("Settle up and pay remaining share")
                    }
                    .padding(16)
                } else if isPayer && totalUncollectedSubunits > 0 {
                    // User Is Payer and Owes are Outstanding
                    VStack(spacing: 12) {
                        HStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(LeafTheme.brandEmerald.opacity(0.15))
                                    .frame(width: 44, height: 44)
                                Image(systemName: "arrow.down.left.circle.fill")
                                    .font(.system(size: 22))
                                    .foregroundStyle(LeafTheme.brandEmerald)
                            }

                            VStack(alignment: .leading, spacing: 2) {
                                Text("COLLECT SETTLEMENTS")
                                    .font(LeafTypography.captionBold)
                                    .foregroundStyle(LeafTheme.brandEmerald)
                                    .tracking(0.5)

                                Text("\(unsettledOthers.count) pending • \(Amount(subunits: totalUncollectedSubunits).formatted(currency: currency)) to collect")
                                    .font(.system(size: 16, weight: .bold, design: .rounded))
                                    .foregroundStyle(LeafTheme.textPrimary(for: colorScheme))
                            }

                            Spacer()
                        }

                        Button(action: {
                            triggerHaptic()
                            if unsettledOthers.count == 1, let single = unsettledOthers.first {
                                selectedParticipantForPayment = single
                            } else {
                                showParticipantPickerForSettle = true
                            }
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 14, weight: .semibold))
                                Text("Record Settlement Received")
                                    .font(.system(size: 15, weight: .bold, design: .rounded))
                            }
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 46)
                            .background(LeafTheme.brandEmerald)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }
                        .buttonStyle(PlainButtonStyle())
                        .accessibilityLabel("Record a settlement payment received")
                    }
                    .padding(16)
                }
            }
        }
        .padding(.horizontal)
    }

    // MARK: - 2. Current User Position Card

    @ViewBuilder
    private func userPositionCard(_ item: SplitExpense) -> some View {
        let isPayer = isPayerCurrentUser(item)
        let myParticipant = item.participants.first { $0.isCurrentUser }
        let myShare = myParticipant?.amount ?? .zero

        let unpaidOthersSubunits = item.participants
            .filter { !$0.isCurrentUser && $0.settlementStatus != .settled }
            .reduce(Int64(0)) { $0 + $1.remainingAmount.subunits }

        SquircleCard(cornerRadius: 18) {
            HStack(spacing: 14) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Your Share")
                        .font(LeafTypography.captionRegular)
                        .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
                    Text(myShare.formatted(currency: currency))
                        .font(.system(size: 15, weight: .bold, design: .rounded).monospacedDigit())
                        .foregroundStyle(LeafTheme.textPrimary(for: colorScheme))
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Divider().background(LeafTheme.cardBorder(for: colorScheme))

                VStack(alignment: .leading, spacing: 3) {
                    if isPayer {
                        Text("Owed to you")
                            .font(LeafTypography.captionRegular)
                            .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
                        Text("+ " + Amount(subunits: unpaidOthersSubunits).formatted(currency: currency))
                            .font(.system(size: 15, weight: .bold, design: .rounded).monospacedDigit())
                            .foregroundStyle(unpaidOthersSubunits > 0 ? LeafTheme.brandEmerald : LeafTheme.textSecondary(for: colorScheme))
                    } else {
                        let isSettled = myParticipant?.settlementStatus == .settled
                        let remaining = myParticipant?.remainingAmount ?? .zero
                        Text(isSettled ? "Settled" : "You Owe")
                            .font(LeafTypography.captionRegular)
                            .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
                        Text(isSettled ? "Paid" : "- " + remaining.formatted(currency: currency))
                            .font(.system(size: 15, weight: .bold, design: .rounded).monospacedDigit())
                            .foregroundStyle(isSettled ? LeafTheme.brandEmerald : LeafTheme.expenseCoral)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(14)
        }
        .padding(.horizontal)
    }

    // MARK: - 3. Participants Breakdown Section

    @ViewBuilder
    private func participantsBreakdownSection(_ item: SplitExpense) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("PARTICIPANTS & SHARES")
                .font(LeafTypography.captionBold)
                .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
                .padding(.horizontal)
                .tracking(0.5)

            SquircleCard(cornerRadius: 20) {
                VStack(spacing: 0) {
                    ForEach(Array(item.participants.enumerated()), id: \.element.id) { idx, p in
                        if idx > 0 {
                            Divider()
                                .padding(.leading, 50)
                                .background(LeafTheme.cardBorder(for: colorScheme))
                        }

                        participantRow(p, split: item)
                    }
                }
            }
            .padding(.horizontal)
        }
    }

    @ViewBuilder
    private func participantRow(_ p: SplitParticipant, split: SplitExpense) -> some View {
        let isSettled = p.settlementStatus == .settled
        let isPartiallySettled = p.settlementStatus == .partiallySettled
        let isPayer = p.name.caseInsensitiveCompare(split.paidBy) == .orderedSame ||
                      (p.isCurrentUser && (split.paidBy.caseInsensitiveCompare("Me") == .orderedSame || split.paidBy.caseInsensitiveCompare("You") == .orderedSame))
        let isCurrentUserPayer = isPayerCurrentUser(split)
        let isDebtorMe = p.isCurrentUser ||
                         p.name.caseInsensitiveCompare("Me") == .orderedSame ||
                         p.name.caseInsensitiveCompare("You") == .orderedSame

        HStack(spacing: 12) {
            // Avatar
            ZStack {
                Circle()
                    .fill((isPayer ? LeafTheme.brandEmerald : (isSettled ? LeafTheme.brandEmerald : (isPartiallySettled ? LeafTheme.amberAccent : Color.gray))).opacity(0.12))
                    .frame(width: 36, height: 36)
                Image(systemName: isPayer ? "creditcard.fill" : (isSettled ? "checkmark" : (isPartiallySettled ? "clock.arrow.circlepath" : (p.isCurrentUser ? "person.fill" : "person"))))
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(isPayer ? LeafTheme.brandEmerald : (isSettled ? LeafTheme.brandEmerald : (isPartiallySettled ? LeafTheme.amberAccent : LeafTheme.textSecondary(for: colorScheme))))
            }

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text(p.name)
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundStyle(LeafTheme.textPrimary(for: colorScheme))

                    if p.isCurrentUser {
                        Text("You")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 1)
                            .background(LeafTheme.brandEmerald)
                            .clipShape(Capsule())
                    }
                }

                if isPayer {
                    Text("Paid entire bill")
                        .font(LeafTypography.captionRegular)
                        .foregroundStyle(LeafTheme.brandEmerald)
                } else if isSettled {
                    Text("Settled")
                        .font(LeafTypography.captionRegular)
                        .foregroundStyle(LeafTheme.brandEmerald)
                } else if isPartiallySettled {
                    Text("\(p.paidAmount.formatted(currency: currency)) paid • \(p.remainingAmount.formatted(currency: currency)) left")
                        .font(LeafTypography.captionRegular)
                        .foregroundStyle(LeafTheme.amberAccent)
                } else {
                    Text("Pending settlement")
                        .font(LeafTypography.captionRegular)
                        .foregroundStyle(LeafTheme.textTertiary(for: colorScheme))
                }
            }

            Spacer()

            // Amount & Payment Action Button
            VStack(alignment: .trailing, spacing: 4) {
                Text(p.amount.formatted(currency: currency))
                    .font(.system(size: 14, weight: .bold, design: .rounded).monospacedDigit())
                    .foregroundStyle(LeafTheme.textPrimary(for: colorScheme))

                if isPayer {
                    Text("Payer")
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundStyle(LeafTheme.brandEmerald)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(
                            Capsule().fill(LeafTheme.brandEmerald.opacity(0.12))
                        )
                } else if isSettled {
                    Text("Settled")
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundStyle(LeafTheme.brandEmerald)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(
                            Capsule().fill(LeafTheme.brandEmerald.opacity(0.12))
                        )
                } else {
                    Button(action: {
                        triggerHaptic()
                        selectedParticipantForPayment = p
                    }) {
                        HStack(spacing: 4) {
                            if isDebtorMe {
                                Image(systemName: "arrow.up.right.circle.fill")
                                Text("Pay Share")
                            } else if isCurrentUserPayer {
                                Image(systemName: "plus.circle.fill")
                                Text("Settle")
                            } else {
                                Image(systemName: "creditcard.fill")
                                Text("Settle")
                            }
                        }
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(LeafTheme.brandEmerald)
                        .clipShape(Capsule())
                    }
                    .accessibilityLabel("Settle balance for \(p.name)")
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }

    // MARK: - 4. Persistent Payment History Section

    @ViewBuilder
    private func paymentHistorySection(_ item: SplitExpense) -> some View {
        if !splitPayments.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("PAYMENT HISTORY")
                        .font(LeafTypography.captionBold)
                        .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
                        .tracking(0.5)

                    Spacer()

                    Text("\(splitPayments.count) \(splitPayments.count == 1 ? "payment" : "payments")")
                        .font(LeafTypography.captionRegular)
                        .foregroundStyle(LeafTheme.textTertiary(for: colorScheme))
                }
                .padding(.horizontal)

                SquircleCard(cornerRadius: 20) {
                    VStack(spacing: 0) {
                        ForEach(Array(splitPayments.enumerated()), id: \.element.id) { idx, pay in
                            if idx > 0 {
                                Divider()
                                    .padding(.leading, 50)
                                    .background(LeafTheme.cardBorder(for: colorScheme))
                            }

                            paymentHistoryRow(pay, split: item)
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    @ViewBuilder
    private func paymentHistoryRow(_ pay: SplitPayment, split: SplitExpense) -> some View {
        let participant = split.participants.first { $0.id == pay.participantId }
        let pName = participant?.name ?? "Participant"
        let isDebtorMe = participant?.isCurrentUser == true ||
                         pName.caseInsensitiveCompare("Me") == .orderedSame ||
                         pName.caseInsensitiveCompare("You") == .orderedSame
        let isRecipientMe = isPayerCurrentUser(split)
        let titleText = isDebtorMe ? "Paid to \(split.paidBy)"
            : isRecipientMe ? "Received from \(pName)"
            : "\(pName) paid \(split.paidBy)"
        let iconName = isDebtorMe ? "arrow.up.right"
            : isRecipientMe ? "arrow.down.left"
            : "arrow.right"
        let iconColor: Color = isDebtorMe ? LeafTheme.expenseCoral
            : isRecipientMe ? LeafTheme.brandEmerald
            : LeafTheme.textSecondary(for: colorScheme)
        let amountPrefix = isDebtorMe ? "- " : isRecipientMe ? "+ " : ""
        let amountColor: Color = isDebtorMe ? LeafTheme.expenseCoral
            : isRecipientMe ? LeafTheme.brandEmerald
            : LeafTheme.textPrimary(for: colorScheme)

        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.12))
                    .frame(width: 34, height: 34)
                Image(systemName: iconName)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(iconColor)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(titleText)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(LeafTheme.textPrimary(for: colorScheme))

                HStack(spacing: 4) {
                    Text(formatDate(pay.date))
                        .font(LeafTypography.captionRegular)
                        .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))

                    if let note = pay.note, !note.isEmpty {
                        Text("• \(note)")
                            .font(LeafTypography.captionRegular)
                            .foregroundStyle(LeafTheme.textTertiary(for: colorScheme))
                            .lineLimit(1)
                    }
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 3) {
                Text(amountPrefix + pay.amount.formatted(currency: currency))
                    .font(.system(size: 14, weight: .bold, design: .rounded).monospacedDigit())
                    .foregroundStyle(amountColor)

                Button(action: {
                    triggerHaptic()
                    paymentToReverse = pay
                }) {
                    Text("Reverse")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundStyle(LeafTheme.expenseCoral)
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }

    private func isPayerCurrentUser(_ split: SplitExpense) -> Bool {
        let trimmed = split.paidBy.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.caseInsensitiveCompare("Me") == .orderedSame || trimmed.caseInsensitiveCompare("You") == .orderedSame {
            return true
        }
        return split.participants.first { $0.name.caseInsensitiveCompare(trimmed) == .orderedSame }?.isCurrentUser == true
    }

    // MARK: - 5. Actions Section

    @ViewBuilder
    private func actionsSection(_ item: SplitExpense) -> some View {
        HStack(spacing: 12) {
            Button(action: {
                triggerHaptic()
                shareViaWhatsApp(item)
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "message.fill")
                    Text("WhatsApp")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(Color(hex: "#25D366") ?? LeafTheme.brandEmerald)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }

            Button(action: {
                triggerHaptic()
                showQrSheet = true
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "qrcode")
                    Text("UPI QR")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                }
                .foregroundStyle(LeafTheme.textPrimary(for: colorScheme))
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(colorScheme == .dark ? LeafTheme.cardDark : LeafTheme.cardLight)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(LeafTheme.cardBorder(for: colorScheme), lineWidth: 0.75)
                )
            }
        }
        .padding(.horizontal)
    }

    // MARK: - UPI QR Preview Sheet

    @ViewBuilder
    private func upiQrPreviewSheet(_ item: SplitExpense) -> some View {
        NavigationStack {
            ZStack {
                LeafTheme.canvas(for: colorScheme).ignoresSafeArea()

                VStack(spacing: 20) {
                    SquircleCard(cornerRadius: 24) {
                        VStack(spacing: 16) {
                            Text("UPI Payment Request")
                                .font(LeafTypography.titleMedium)
                                .foregroundStyle(LeafTheme.textPrimary(for: colorScheme))

                            ZStack {
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill(Color.white)
                                    .frame(width: 200, height: 200)

                                Image(systemName: "qrcode")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 170, height: 170)
                                    .foregroundStyle(Color.black)
                            }
                            .padding(.vertical, 8)

                            Text(item.title)
                                .font(LeafTypography.headline)
                                .foregroundStyle(LeafTheme.textPrimary(for: colorScheme))

                            Text("Total: " + item.totalAmount.formatted(currency: currency))
                                .font(.system(size: 18, weight: .bold, design: .rounded).monospacedDigit())
                                .foregroundStyle(LeafTheme.brandEmerald)

                            Text("Scan with Google Pay, PhonePe, or Paytm")
                                .font(LeafTypography.captionRegular)
                                .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
                        }
                        .padding(20)
                    }
                    .padding(.horizontal)

                    Spacer()
                }
                .padding(.top, 24)
            }
            .navigationTitle("Scan to Settle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { showQrSheet = false }
                        .foregroundStyle(LeafTheme.brandEmerald)
                        .fontWeight(.bold)
                }
            }
        }
    }

    // MARK: - Helpers

    private func loadSplit() async {
        isLoading = true
        do {
            self.split = try await splitRepository.getSplitExpense(id: splitId)
            self.splitPayments = try await splitRepository.getPaymentsForSplit(splitExpenseId: splitId)
        } catch {
            self.errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    private func shareViaWhatsApp(_ item: SplitExpense) {
        var msg = "💰 *Split: \(item.title)*\n"
        msg += "Total Bill: \(item.totalAmount.formatted(currency: currency))\n"
        msg += "Paid by: \(item.paidBy)\n\n"
        msg += "👥 *Participant Breakdown:*\n"

        for p in item.participants {
            let status: String
            if p.settlementStatus == .settled {
                status = "✅ Settled"
            } else if p.settlementStatus == .partiallySettled {
                status = "⏳ Partially Paid (\(p.remainingAmount.formatted(currency: currency)) left)"
            } else {
                status = "⏳ Pending (\(p.amount.formatted(currency: currency)))"
            }
            msg += "• \(p.name): \(status)\n"
        }

        msg += "\n_Sent via Leaf for iOS_"

        if let encoded = msg.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
           let url = URL(string: "whatsapp://send?text=\(encoded)"),
           UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        } else {
            UIPasteboard.general.string = msg
            let av = UIActivityViewController(activityItems: [msg], applicationActivities: nil)
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let root = windowScene.windows.first?.rootViewController {
                root.present(av, animated: true)
            }
        }
    }

    private func formatDate(_ timestamp: Int64) -> String {
        let date = Date(timeIntervalSince1970: Double(timestamp) / 1000.0)
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMMM yyyy"
        return formatter.string(from: date)
    }
}
