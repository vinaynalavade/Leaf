import SwiftUI

/// Fast modal sheet for transferring funds between Cash and Account ledgers.
/// Creates a linked internal transfer pair with zero net effect on income/expense metrics.
public struct TransferFundsSheet: View {
    @Environment(AppContainer.self) private var container
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    public let currency: Currency
    public let onTransferCompleted: () -> Void

    @State private var sourceLedger: PaymentMethod = .cash
    @State private var destinationLedger: PaymentMethod = .account
    @State private var amountInput: String = ""
    @State private var note: String = ""
    @State private var transferDate: Date = Date()
    @State private var isSubmitting: Bool = false
    @State private var errorMessage: String? = nil

    public init(currency: Currency = .default, onTransferCompleted: @escaping () -> Void = {}) {
        self.currency = currency
        self.onTransferCompleted = onTransferCompleted
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                LeafTheme.canvas(for: colorScheme).ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // Direction Indicator Card
                        SquircleCard(cornerRadius: 20) {
                            HStack(spacing: 16) {
                                // Source Ledger
                                VStack(spacing: 6) {
                                    Text("FROM")
                                        .font(LeafTypography.captionBold)
                                        .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))

                                    ledgerPill(sourceLedger, isSource: true)
                                }
                                .frame(maxWidth: .infinity)

                                // Arrow
                                Button(action: swapDirection) {
                                    Image(systemName: "arrow.left.arrow.right.circle.fill")
                                        .font(.system(size: 26))
                                        .foregroundStyle(LeafTheme.brandEmerald)
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel("Swap transfer direction")

                                // Destination Ledger
                                VStack(spacing: 6) {
                                    Text("TO")
                                        .font(LeafTypography.captionBold)
                                        .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))

                                    ledgerPill(destinationLedger, isSource: false)
                                }
                                .frame(maxWidth: .infinity)
                            }
                            .padding(16)
                        }
                        .padding(.horizontal)
                        .padding(.top, 8)

                        // Amount Input Card
                        SquircleCard(cornerRadius: 22) {
                            VStack(spacing: 8) {
                                Text("TRANSFER AMOUNT")
                                    .font(LeafTypography.captionBold)
                                    .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))

                                HStack(alignment: .firstTextBaseline, spacing: 4) {
                                    Text(currency.symbol)
                                        .font(.system(size: 32, weight: .bold, design: .rounded))
                                        .foregroundStyle(LeafTheme.brandEmerald)

                                    TextField("0", text: $amountInput)
                                        .font(.system(size: 44, weight: .bold, design: .rounded))
                                        .keyboardType(.decimalPad)
                                        .multilineTextAlignment(.leading)
                                        .foregroundStyle(LeafTheme.textPrimary(for: colorScheme))
                                }
                                .padding(.horizontal, 16)
                            }
                            .padding(.vertical, 16)
                        }
                        .padding(.horizontal)

                        // Note and Date
                        SquircleCard(cornerRadius: 18) {
                            VStack(spacing: 14) {
                                HStack {
                                    Image(systemName: "text.bubble.fill")
                                        .foregroundStyle(LeafTheme.brandEmerald)
                                        .frame(width: 24)
                                    TextField("Note (e.g. ATM withdrawal, deposit)", text: $note)
                                        .font(LeafTypography.body)
                                }

                                Divider()

                                HStack {
                                    Image(systemName: "calendar")
                                        .foregroundStyle(LeafTheme.brandEmerald)
                                        .frame(width: 24)
                                    DatePicker("Date", selection: $transferDate, displayedComponents: [.date, .hourAndMinute])
                                        .font(LeafTypography.body)
                                }
                            }
                            .padding(16)
                        }
                        .padding(.horizontal)

                        if let err = errorMessage {
                            Text(err)
                                .font(LeafTypography.captionRegular)
                                .foregroundStyle(LeafTheme.expenseCoral)
                                .padding(.horizontal)
                        }

                        // Submit Button
                        Button(action: executeTransfer) {
                            HStack {
                                if isSubmitting {
                                    ProgressView().tint(.white)
                                } else {
                                    Image(systemName: "arrow.right.circle.fill")
                                        .font(.system(size: 16, weight: .bold))
                                    Text("Execute Transfer")
                                        .font(LeafTypography.bodyBold)
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
                        .padding(.top, 8)
                    }
                }
            }
            .navigationTitle("Transfer Funds")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(LeafTheme.accent(for: colorScheme))
                }
            }
        }
    }

    @ViewBuilder
    private func ledgerPill(_ method: PaymentMethod, isSource: Bool) -> some View {
        HStack(spacing: 6) {
            Image(systemName: method == .cash ? "banknote.fill" : "creditcard.fill")
                .font(.system(size: 13, weight: .semibold))
            Text(method.displayName)
                .font(.system(size: 14, weight: .bold, design: .rounded))
        }
        .foregroundStyle(isSource ? LeafTheme.brandEmerald : LeafTheme.accent(for: colorScheme))
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(isSource ? LeafTheme.brandEmerald.opacity(0.14) : LeafTheme.accent(for: colorScheme).opacity(0.14))
        )
    }

    private func swapDirection() {
        let temp = sourceLedger
        sourceLedger = destinationLedger
        destinationLedger = temp
    }

    private func executeTransfer() {
        guard let amount = Amount.fromStringOrNull(amountInput, currency: currency),
              amount.subunits > 0 else {
            errorMessage = "Please enter an amount greater than zero."
            return
        }

        isSubmitting = true
        errorMessage = nil

        Task {
            do {
                let epoch = Int64(transferDate.timeIntervalSince1970 * 1000)
                _ = try await container.transactionRepository.transferBetweenLedgers(
                    from: sourceLedger,
                    to: destinationLedger,
                    amount: amount,
                    note: note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : note,
                    timestamp: epoch
                )
                onTransferCompleted()
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
                isSubmitting = false
            }
        }
    }
}
