import SwiftUI
import UIKit

/// Sheet allowing recording a custom partial or full payment against a participant's outstanding balance.
public struct RecordPaymentSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    public let participant: SplitParticipant
    public let splitTitle: String
    public let paidByName: String
    public let isCurrentUserPayer: Bool
    public let currency: Currency
    public let onRecordPayment: (Amount, PaymentMethod, Int64, String?) async throws -> Void

    @State private var amountInput: String
    @State private var selectedPaymentMethod: PaymentMethod = .account
    @State private var paymentDate: Date = Date()
    @State private var note: String = ""
    @State private var isSubmitting: Bool = false
    @State private var errorMessage: String? = nil

    public init(
        participant: SplitParticipant,
        splitTitle: String,
        paidByName: String = "",
        isCurrentUserPayer: Bool = true,
        currency: Currency = .default,
        onRecordPayment: @escaping (Amount, PaymentMethod, Int64, String?) async throws -> Void
    ) {
        self.participant = participant
        self.splitTitle = splitTitle
        self.paidByName = paidByName
        self.isCurrentUserPayer = isCurrentUserPayer
        self.currency = currency
        self.onRecordPayment = onRecordPayment
        // Default to remaining balance
        self._amountInput = State(initialValue: participant.remainingAmount.toInputString())
    }

    private var isDebtorMe: Bool {
        participant.isCurrentUser ||
        participant.name.caseInsensitiveCompare("Me") == .orderedSame ||
        participant.name.caseInsensitiveCompare("You") == .orderedSame
    }

    private var sheetNavigationTitle: String {
        if isDebtorMe {
            return paidByName.isEmpty ? "Pay Share" : "Pay \(paidByName)"
        } else if isCurrentUserPayer {
            return "Receive from \(participant.name)"
        } else {
            return "Record Settlement"
        }
    }

    private var statusCardHeaderTitle: String {
        if isDebtorMe {
            return paidByName.isEmpty ? "Paying Share" : "Paying to \(paidByName)"
        } else if isCurrentUserPayer {
            return "Received from \(participant.name)"
        } else {
            return "\(participant.name) → \(paidByName)"
        }
    }

    private var submitButtonText: String {
        if isDebtorMe {
            return paidByName.isEmpty ? "Record Payment" : "Record Payment to \(paidByName)"
        } else if isCurrentUserPayer {
            return "Record Payment from \(participant.name)"
        } else {
            return "Record Payment"
        }
    }

    private var parsedAmount: Amount? {
        Amount.fromStringOrNull(amountInput, currency: currency)
    }

    private func triggerHaptic() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()
        generator.impactOccurred()
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

                        // 1. Participant Balance Status Card
                        SquircleCard(cornerRadius: 20) {
                            VStack(spacing: 12) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(statusCardHeaderTitle)
                                            .font(LeafTypography.titleMedium)
                                            .foregroundStyle(LeafTheme.textPrimary(for: colorScheme))
                                        Text(splitTitle)
                                            .font(LeafTypography.captionRegular)
                                            .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
                                    }
                                    Spacer()
                                    VStack(alignment: .trailing, spacing: 2) {
                                        Text(isDebtorMe ? "Your Balance Due" : "Balance Due")
                                            .font(LeafTypography.captionRegular)
                                            .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
                                        Text(participant.remainingAmount.formatted(currency: currency))
                                            .font(.system(size: 17, weight: .bold, design: .rounded).monospacedDigit())
                                            .foregroundStyle(LeafTheme.expenseCoral)
                                    }
                                }

                                Divider().background(LeafTheme.cardBorder(for: colorScheme))

                                HStack(spacing: 12) {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Total Share")
                                            .font(LeafTypography.captionRegular)
                                            .foregroundStyle(LeafTheme.textTertiary(for: colorScheme))
                                        Text(participant.amount.formatted(currency: currency))
                                            .font(.system(size: 13, weight: .semibold, design: .rounded).monospacedDigit())
                                            .foregroundStyle(LeafTheme.textPrimary(for: colorScheme))
                                    }
                                    Spacer()
                                    VStack(alignment: .trailing, spacing: 2) {
                                        Text("Already Paid")
                                            .font(LeafTypography.captionRegular)
                                            .foregroundStyle(LeafTheme.textTertiary(for: colorScheme))
                                        Text(participant.paidAmount.formatted(currency: currency))
                                            .font(.system(size: 13, weight: .semibold, design: .rounded).monospacedDigit())
                                            .foregroundStyle(LeafTheme.brandEmerald)
                                    }
                                }
                            }
                            .padding(16)
                        }
                        .padding(.horizontal)

                        // 2. Payment Amount Input
                        SquircleCard(cornerRadius: 22) {
                            VStack(spacing: 8) {
                                Text("PAYMENT AMOUNT")
                                    .font(LeafTypography.captionBold)
                                    .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
                                    .tracking(0.5)

                                HStack(alignment: .firstTextBaseline, spacing: 4) {
                                    Text(currency.symbol)
                                        .font(.system(size: 32, weight: .bold, design: .rounded))
                                        .foregroundStyle(LeafTheme.brandEmerald)

                                    TextField("0.00", text: $amountInput)
                                        .font(.system(size: 38, weight: .bold, design: .rounded).monospacedDigit())
                                        .keyboardType(.decimalPad)
                                        .foregroundStyle(LeafTheme.textPrimary(for: colorScheme))
                                }
                                .padding(.horizontal, 16)

                                // Quick Amount Pills
                                HStack(spacing: 8) {
                                    Button(action: {
                                        amountInput = participant.remainingAmount.toInputString()
                                    }) {
                                        Text("Pay In Full")
                                            .font(.system(size: 11, weight: .bold, design: .rounded))
                                            .foregroundStyle(LeafTheme.brandEmerald)
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 4)
                                            .background(
                                                Capsule().fill(LeafTheme.brandEmerald.opacity(0.12))
                                            )
                                    }

                                    quickAddButton(amount: 100)
                                    quickAddButton(amount: 500)
                                    quickAddButton(amount: 1000)
                                }
                                .padding(.top, 4)
                            }
                            .padding(.vertical, 16)
                            .frame(maxWidth: .infinity)
                        }
                        .padding(.horizontal)

                        // 3. Payment Method & Date
                        SquircleCard(cornerRadius: 18) {
                            VStack(spacing: 16) {
                                HStack {
                                    Text("Payment Source")
                                        .font(LeafTypography.bodyMedium)
                                        .foregroundStyle(LeafTheme.textPrimary(for: colorScheme))
                                    Spacer()
                                    Picker("Payment Method", selection: $selectedPaymentMethod) {
                                        Text("Account / UPI").tag(PaymentMethod.account)
                                        Text("Cash").tag(PaymentMethod.cash)
                                    }
                                    .pickerStyle(.segmented)
                                    .frame(width: 170)
                                }

                                Divider().background(LeafTheme.cardBorder(for: colorScheme))

                                DatePicker(
                                    "Payment Date",
                                    selection: $paymentDate,
                                    displayedComponents: [.date, .hourAndMinute]
                                )
                                .font(LeafTypography.bodyMedium)
                                .foregroundStyle(LeafTheme.textPrimary(for: colorScheme))
                            }
                            .padding(16)
                        }
                        .padding(.horizontal)

                        // 4. Note (optional)
                        SquircleCard(cornerRadius: 18) {
                            HStack {
                                Image(systemName: "note.text")
                                    .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
                                TextField("Note (e.g. GPay, Installment 1)", text: $note)
                                    .font(LeafTypography.bodyMedium)
                                    .foregroundStyle(LeafTheme.textPrimary(for: colorScheme))
                            }
                            .padding(16)
                        }
                        .padding(.horizontal)

                        // 5. Submit Button
                        Button(action: {
                            triggerHaptic()
                            Task { await submit() }
                        }) {
                            HStack(spacing: 6) {
                                if isSubmitting {
                                    ProgressView().tint(.white)
                                } else {
                                    Image(systemName: "checkmark.circle.fill")
                                    Text(submitButtonText)
                                        .font(LeafTypography.headline)
                                }
                            }
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(LeafTheme.brandEmerald)
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
            .navigationTitle(sheetNavigationTitle)
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
            let maxAmt = Double(participant.remainingAmount.subunits) / 100.0
            amountInput = String(format: "%.2f", min(updated, maxAmt))
        }) {
            Text("+\(amount)")
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundStyle(LeafTheme.brandEmerald)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    Capsule().fill(LeafTheme.brandEmerald.opacity(0.12))
                )
        }
    }

    private func submit() async {
        guard let amt = parsedAmount, amt.subunits > 0 else {
            errorMessage = "Please enter an amount greater than zero."
            return
        }

        if amt.subunits > participant.remainingAmount.subunits {
            errorMessage = "Payment cannot exceed remaining balance of \(participant.remainingAmount.formatted(currency: currency))."
            return
        }

        isSubmitting = true
        errorMessage = nil

        do {
            let timestamp = Int64(paymentDate.timeIntervalSince1970 * 1000)
            let trimmedNote = note.trimmingCharacters(in: .whitespacesAndNewlines)
            try await onRecordPayment(
                amt,
                selectedPaymentMethod,
                timestamp,
                trimmedNote.isEmpty ? nil : trimmedNote
            )
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }

        isSubmitting = false
    }
}

