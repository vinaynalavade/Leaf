import SwiftUI

/// Sheet allowing the user to record a manual or ledger-linked deposit towards a savings goal.
public struct AddSavingsContributionSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    public let goal: SavingsGoal
    public let currency: Currency
    public let onRecordContribution: (Amount, String?, Int64, Bool, PaymentMethod) async throws -> Void

    @State private var amountInput: String = ""
    @State private var contributionDate: Date = Date()
    @State private var note: String = ""
    @State private var createLedgerTransaction: Bool = false
    @State private var paymentMethod: PaymentMethod = .account
    @State private var isSubmitting: Bool = false
    @State private var errorMessage: String? = nil

    public init(
        goal: SavingsGoal,
        currency: Currency = .default,
        onRecordContribution: @escaping (Amount, String?, Int64, Bool, PaymentMethod) async throws -> Void
    ) {
        self.goal = goal
        self.currency = currency
        self.onRecordContribution = onRecordContribution
    }

    private var goalColor: Color {
        Color(hex: goal.colorHex) ?? LeafTheme.brandEmerald
    }

    private var parsedAmount: Amount? {
        Amount.fromStringOrNull(amountInput, currency: currency)
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                LeafTheme.canvas(for: colorScheme).ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        if let error = errorMessage {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundStyle(LeafTheme.expenseCoral)
                                Text(error)
                                    .font(LeafTypography.captionRegular)
                                    .foregroundStyle(LeafTheme.expenseCoral)
                            }
                            .padding(.horizontal)
                        }

                        // 1. Goal Status Card
                        SquircleCard(cornerRadius: 20) {
                            HStack(spacing: 12) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(goal.name)
                                        .font(LeafTypography.titleSmall)
                                        .foregroundStyle(LeafTheme.textPrimary(for: colorScheme))
                                    Text("Remaining to save")
                                        .font(LeafTypography.captionRegular)
                                        .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
                                }

                                Spacer()

                                Text(goal.remainingAmount.formatted(currency: currency))
                                    .font(.system(size: 20, weight: .bold, design: .rounded).monospacedDigit())
                                    .foregroundStyle(goalColor)
                            }
                            .padding(16)
                        }
                        .padding(.horizontal)

                        // 2. Contribution Amount Input Card
                        SquircleCard(cornerRadius: 22) {
                            VStack(spacing: 8) {
                                Text("CONTRIBUTION AMOUNT")
                                    .font(LeafTypography.captionBold)
                                    .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
                                    .tracking(0.5)

                                HStack(alignment: .firstTextBaseline, spacing: 4) {
                                    Text(currency.symbol)
                                        .font(.system(size: 32, weight: .bold, design: .rounded))
                                        .foregroundStyle(goalColor)

                                    TextField("0.00", text: $amountInput)
                                        .font(.system(size: 38, weight: .bold, design: .rounded).monospacedDigit())
                                        .keyboardType(.decimalPad)
                                        .foregroundStyle(LeafTheme.textPrimary(for: colorScheme))
                                }
                                .padding(.horizontal, 16)

                                // Quick Amount Pills
                                HStack(spacing: 8) {
                                    if goal.remainingAmount.subunits > 0 {
                                        Button(action: {
                                            amountInput = goal.remainingAmount.toInputString()
                                        }) {
                                            Text("Save Full")
                                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                                .foregroundStyle(goalColor)
                                                .padding(.horizontal, 10)
                                                .padding(.vertical, 4)
                                                .background(
                                                    Capsule().fill(goalColor.opacity(0.12))
                                                )
                                        }
                                    }

                                    quickAddButton(amount: 500)
                                    quickAddButton(amount: 1000)
                                    quickAddButton(amount: 5000)
                                }
                                .padding(.top, 4)
                            }
                            .padding(.vertical, 16)
                            .frame(maxWidth: .infinity)
                        }
                        .padding(.horizontal)

                        // 3. Ledger Deduction Toggle & Payment Source
                        SquircleCard(cornerRadius: 18) {
                            VStack(spacing: 14) {
                                Toggle(isOn: $createLedgerTransaction) {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Deduct from Checking Account")
                                            .font(LeafTypography.bodyMedium)
                                            .foregroundStyle(LeafTheme.textPrimary(for: colorScheme))
                                        Text("Creates an expense entry in your personal ledger")
                                            .font(LeafTypography.captionRegular)
                                            .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
                                    }
                                }
                                .tint(goalColor)

                                if createLedgerTransaction {
                                    Divider().background(LeafTheme.cardBorder(for: colorScheme))

                                    HStack {
                                        Text("Payment Source")
                                            .font(LeafTypography.bodyMedium)
                                            .foregroundStyle(LeafTheme.textPrimary(for: colorScheme))
                                        Spacer()
                                        Picker("Payment Method", selection: $paymentMethod) {
                                            Text("Account / UPI").tag(PaymentMethod.account)
                                            Text("Cash").tag(PaymentMethod.cash)
                                        }
                                        .pickerStyle(.segmented)
                                        .frame(width: 170)
                                    }
                                }
                            }
                            .padding(16)
                        }
                        .padding(.horizontal)

                        // 4. Date & Note
                        SquircleCard(cornerRadius: 18) {
                            VStack(spacing: 14) {
                                DatePicker(
                                    "Contribution Date",
                                    selection: $contributionDate,
                                    displayedComponents: [.date, .hourAndMinute]
                                )
                                .font(LeafTypography.bodyMedium)
                                .foregroundStyle(LeafTheme.textPrimary(for: colorScheme))

                                Divider().background(LeafTheme.cardBorder(for: colorScheme))

                                HStack {
                                    Image(systemName: "note.text")
                                        .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
                                    TextField("Note (optional, e.g. Bonus, Salary save)", text: $note)
                                        .font(LeafTypography.bodyMedium)
                                        .foregroundStyle(LeafTheme.textPrimary(for: colorScheme))
                                }
                            }
                            .padding(16)
                        }
                        .padding(.horizontal)

                        // 5. Submit Button
                        Button(action: {
                            let generator = UIImpactFeedbackGenerator(style: .medium)
                            generator.impactOccurred()
                            Task { await submit() }
                        }) {
                            HStack(spacing: 6) {
                                if isSubmitting {
                                    ProgressView().tint(.white)
                                } else {
                                    Image(systemName: "plus.circle.fill")
                                    Text("Record Contribution")
                                        .font(LeafTypography.headline)
                                }
                            }
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(goalColor)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        }
                        .disabled(isSubmitting)
                        .padding(.horizontal)
                        .padding(.top, 4)
                        .padding(.bottom, 24)
                    }
                    .padding(.top, 12)
                }
            }
            .navigationTitle("Deposit to Goal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
                }
            }
        }
    }

    @ViewBuilder
    private func quickAddButton(amount: Int) -> some View {
        Button(action: {
            let current = Double(amountInput.replacingOccurrences(of: ",", with: ".")) ?? 0.0
            let updated = current + Double(amount)
            amountInput = String(format: "%.0f", updated)
        }) {
            Text("+\(amount)")
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundStyle(goalColor)
                .padding(.horizontal, 9)
                .padding(.vertical, 4)
                .background(
                    Capsule().fill(goalColor.opacity(0.12))
                )
        }
    }

    private func submit() async {
        guard let amt = parsedAmount, amt.subunits > 0 else {
            errorMessage = "Please enter an amount greater than zero."
            return
        }

        isSubmitting = true
        errorMessage = nil

        do {
            let timestamp = Int64(contributionDate.timeIntervalSince1970 * 1000)
            let trimmedNote = note.trimmingCharacters(in: .whitespacesAndNewlines)
            try await onRecordContribution(
                amt,
                trimmedNote.isEmpty ? nil : trimmedNote,
                timestamp,
                createLedgerTransaction,
                paymentMethod
            )
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }

        isSubmitting = false
    }
}

