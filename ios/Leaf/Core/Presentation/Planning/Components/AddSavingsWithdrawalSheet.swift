import SwiftUI

/// Sheet allowing the user to withdraw savings from an active goal.
/// Strictly enforces that withdrawal cannot exceed current available savings,
/// and allows optional automatic inflow integration into the personal cash ledger.
public struct AddSavingsWithdrawalSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    public let goal: SavingsGoal
    public let currency: Currency
    public let onRecordWithdrawal: (Amount, String?, Int64, Bool, PaymentMethod) async throws -> Void

    @State private var amountInput: String = ""
    @State private var withdrawalDate: Date = Date()
    @State private var note: String = ""
    @State private var returnToAccount: Bool = true
    @State private var paymentMethod: PaymentMethod = .account
    @State private var isSubmitting: Bool = false
    @State private var errorMessage: String? = nil

    public init(
        goal: SavingsGoal,
        currency: Currency = .default,
        onRecordWithdrawal: @escaping (Amount, String?, Int64, Bool, PaymentMethod) async throws -> Void
    ) {
        self.goal = goal
        self.currency = currency
        self.onRecordWithdrawal = onRecordWithdrawal
    }

    private var parsedAmount: Amount? {
        Amount.fromStringOrNull(amountInput, currency: currency)
    }

    private var isOverdrawing: Bool {
        guard let parsed = parsedAmount else { return false }
        return parsed.subunits > goal.currentSavedAmount.subunits
    }

    private var isValid: Bool {
        guard let parsed = parsedAmount, parsed.subunits > 0 else { return false }
        return !isOverdrawing
    }

    private var goalColor: Color {
        Color(hex: goal.colorHex) ?? LeafTheme.brandEmerald
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                LeafTheme.canvas(for: colorScheme).ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // 1. Goal & Available Balance Card
                        availableBalanceCard

                        // 2. Amount Input Card
                        amountInputCard

                        // 3. Date & Note Configuration Card
                        detailsCard

                        // 4. Return to Checking Ledger Toggle
                        ledgerIntegrationCard

                        if let error = errorMessage {
                            Text(error)
                                .font(LeafTypography.captionBold)
                                .foregroundStyle(LeafTheme.coralRose)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal)
                        }
                    }
                    .padding(.vertical, 16)
                }
            }
            .navigationTitle("Withdraw Savings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(action: submitWithdrawal) {
                        if isSubmitting {
                            ProgressView().tint(LeafTheme.warningAmber)
                        } else {
                            Text("Withdraw")
                                .font(LeafTypography.bodyBold)
                                .foregroundStyle(isValid ? LeafTheme.warningAmber : LeafTheme.textTertiary(for: colorScheme))
                        }
                    }
                    .disabled(!isValid || isSubmitting)
                }
            }
        }
    }

    // MARK: - Subviews

    private var availableBalanceCard: some View {
        SquircleCard(cornerRadius: 18) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(goalColor.opacity(0.14))
                        .frame(width: 44, height: 44)

                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(goalColor)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(goal.name)
                        .font(LeafTypography.bodyBold)
                        .foregroundStyle(LeafTheme.textPrimary(for: colorScheme))

                    Text("Available to Withdraw")
                        .font(LeafTypography.captionRegular)
                        .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
                }

                Spacer()

                Text(goal.currentSavedAmount.formatted(currency: currency))
                    .font(.system(size: 18, weight: .bold, design: .rounded).monospacedDigit())
                    .foregroundStyle(LeafTheme.textPrimary(for: colorScheme))
            }
            .padding(16)
        }
        .padding(.horizontal)
    }

    private var amountInputCard: some View {
        SquircleCard(cornerRadius: 18) {
            VStack(alignment: .leading, spacing: 12) {
                Text("WITHDRAWAL AMOUNT")
                    .font(LeafTypography.captionBold)
                    .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))

                HStack {
                    Text(currency.symbol)
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                        .foregroundStyle(isOverdrawing ? LeafTheme.coralRose : LeafTheme.warningAmber)

                    TextField("0.00", text: $amountInput)
                        .keyboardType(.decimalPad)
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(isOverdrawing ? LeafTheme.coralRose : LeafTheme.textPrimary(for: colorScheme))
                }

                if isOverdrawing {
                    HStack(spacing: 6) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 12))
                        Text("Exceeds available balance of \(goal.currentSavedAmount.formatted(currency: currency))")
                            .font(LeafTypography.captionRegular)
                    }
                    .foregroundStyle(LeafTheme.coralRose)
                }

                // Quick Percentage Chips
                HStack(spacing: 8) {
                    ForEach([0.25, 0.50, 0.75, 1.0], id: \.self) { fraction in
                        let chipLabel = fraction == 1.0 ? "All (100%)" : "\(Int(fraction * 100))%"
                        Button(action: {
                            let fractionSubunits = Int64(Double(goal.currentSavedAmount.subunits) * fraction)
                            let computed = Amount(subunits: fractionSubunits)
                            amountInput = computed.toInputString()
                        }) {
                            Text(chipLabel)
                                .font(LeafTypography.captionBold)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(LeafTheme.subtleCard(for: colorScheme))
                                .foregroundStyle(LeafTheme.textPrimary(for: colorScheme))
                                .clipShape(Capsule())
                        }
                    }
                }
            }
            .padding(16)
        }
        .padding(.horizontal)
    }

    private var detailsCard: some View {
        SquircleCard(cornerRadius: 18) {
            VStack(spacing: 12) {
                DatePicker(
                    "Withdrawal Date",
                    selection: $withdrawalDate,
                    in: ...Date(),
                    displayedComponents: .date
                )
                .tint(LeafTheme.brandEmerald)

                Divider().background(LeafTheme.cardBorder(for: colorScheme))

                HStack {
                    Image(systemName: "pencil")
                        .foregroundStyle(LeafTheme.textTertiary(for: colorScheme))
                    TextField("Note / Reason for withdrawal (optional)", text: $note)
                        .font(LeafTypography.bodySmall)
                }
            }
            .padding(16)
        }
        .padding(.horizontal)
    }

    private var ledgerIntegrationCard: some View {
        SquircleCard(cornerRadius: 18) {
            Toggle(isOn: $returnToAccount) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Return to Checking Account")
                        .font(LeafTypography.bodyBold)
                        .foregroundStyle(LeafTheme.textPrimary(for: colorScheme))
                    Text("Records an internal transfer inflow into your personal cash ledger")
                        .font(LeafTypography.captionRegular)
                        .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
                }
            }
            .tint(LeafTheme.brandEmerald)
            .padding(16)
        }
        .padding(.horizontal)
    }

    private func submitWithdrawal() {
        guard let amount = parsedAmount, amount.subunits > 0 else {
            errorMessage = "Please enter a valid amount."
            return
        }

        if isOverdrawing {
            errorMessage = "Withdrawal cannot exceed available savings balance."
            return
        }

        isSubmitting = true
        errorMessage = nil

        let timestamp = Int64(withdrawalDate.timeIntervalSince1970 * 1000)
        let noteText = note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : note.trimmingCharacters(in: .whitespacesAndNewlines)

        Task {
            do {
                try await onRecordWithdrawal(amount, noteText, timestamp, returnToAccount, paymentMethod)
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
                isSubmitting = false
            }
        }
    }
}

