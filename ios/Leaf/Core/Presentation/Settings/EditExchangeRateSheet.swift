import SwiftUI

/// Modal sheet for entering or updating a manual exchange rate between two currencies.
public struct EditExchangeRateSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @Environment(AppContainer.self) private var container

    public let baseCurrencyCode: String
    public let targetCurrencyCode: String
    public let currentRate: Double
    public let onSave: () -> Void

    @State private var rateInput: String = ""
    @State private var errorMessage: String? = nil
    @State private var isSaving: Bool = false

    public init(
        baseCurrencyCode: String,
        targetCurrencyCode: String,
        currentRate: Double,
        onSave: @escaping () -> Void
    ) {
        self.baseCurrencyCode = baseCurrencyCode
        self.targetCurrencyCode = targetCurrencyCode
        self.currentRate = currentRate
        self.onSave = onSave
    }

    private var parsedRate: Double? {
        Double(rateInput.replacingOccurrences(of: ",", with: "."))
    }

    private var invertedRate: Double? {
        guard let r = parsedRate, r > 0 else { return nil }
        return 1.0 / r
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                LeafTheme.canvas(for: colorScheme).ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // Rate Preview Card
                        VStack(spacing: 12) {
                            Text("EXCHANGE RATE PAIR")
                                .font(LeafTypography.captionBold)
                                .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))

                            HStack(spacing: 16) {
                                currencyPill(code: baseCurrencyCode)

                                Image(systemName: "arrow.right")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundStyle(LeafTheme.brandEmerald)

                                currencyPill(code: targetCurrencyCode)
                            }

                            Divider()
                                .background(LeafTheme.border(for: colorScheme))

                            if let r = parsedRate, r > 0 {
                                Text("1 \(baseCurrencyCode) = \(String(format: "%.4f", r)) \(targetCurrencyCode)")
                                    .font(LeafTypography.titleMedium)
                                    .foregroundStyle(LeafTheme.brandEmerald)

                                if let inv = invertedRate {
                                    Text("1 \(targetCurrencyCode) ≈ \(String(format: "%.4f", inv)) \(baseCurrencyCode)")
                                        .font(LeafTypography.caption)
                                        .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
                                }
                            } else {
                                Text("Enter a valid positive exchange rate")
                                    .font(LeafTypography.caption)
                                    .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
                            }
                        }
                        .padding(18)
                        .background(LeafTheme.card(for: colorScheme))
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(LeafTheme.border(for: colorScheme), lineWidth: 1)
                        )

                        // Input Card
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Rate Value")
                                .font(LeafTypography.captionBold)
                                .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))

                            HStack {
                                Text("1 \(baseCurrencyCode) =")
                                    .font(LeafTypography.bodyBold)
                                    .foregroundStyle(LeafTheme.textPrimary(for: colorScheme))

                                TextField("0.00", text: $rateInput)
                                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                                    .keyboardType(.decimalPad)
                                    .multilineTextAlignment(.trailing)

                                Text(targetCurrencyCode)
                                    .font(LeafTypography.bodyBold)
                                    .foregroundStyle(LeafTheme.brandEmerald)
                            }
                            .padding(14)
                            .background(LeafTheme.surface(for: colorScheme))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(LeafTheme.border(for: colorScheme), lineWidth: 1)
                            )

                            Text("Used to calculate primary-currency equivalents when entering foreign expenses or viewing travel wallets.")
                                .font(LeafTypography.caption)
                                .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
                        }
                        .padding(16)
                        .background(LeafTheme.card(for: colorScheme))
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(LeafTheme.border(for: colorScheme), lineWidth: 1)
                        )

                        if let error = errorMessage {
                            Text(error)
                                .font(LeafTypography.caption)
                                .foregroundStyle(Color.red)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 4)
                        }

                        // Save Button
                        Button {
                            saveRate()
                        } label: {
                            HStack {
                                Spacer()
                                if isSaving {
                                    ProgressView().tint(.white)
                                } else {
                                    Text("Save Exchange Rate")
                                        .font(LeafTypography.titleMedium)
                                        .foregroundStyle(.white)
                                }
                                Spacer()
                            }
                            .padding(.vertical, 14)
                            .background(parsedRate != nil && (parsedRate ?? 0) > 0 ? LeafTheme.brandEmerald : Color.gray.opacity(0.4))
                            .clipShape(Capsule())
                        }
                        .disabled(parsedRate == nil || (parsedRate ?? 0) <= 0 || isSaving)
                    }
                    .padding(16)
                }
            }
            .navigationTitle("Edit Exchange Rate")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                self.rateInput = String(format: "%.4f", currentRate)
            }
        }
    }

    @ViewBuilder
    private func currencyPill(code: String) -> some View {
        let curr = Currency.fromCode(code)
        HStack(spacing: 6) {
            Text(curr.symbol)
                .font(LeafTypography.captionBold)
                .foregroundStyle(LeafTheme.brandEmerald)
            Text(curr.code)
                .font(LeafTypography.captionBold)
                .foregroundStyle(LeafTheme.textPrimary(for: colorScheme))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(LeafTheme.surface(for: colorScheme))
        .cornerRadius(8)
    }

    private func saveRate() {
        guard let rate = parsedRate, rate > 0 else {
            errorMessage = "Please enter a valid rate greater than zero."
            return
        }

        isSaving = true
        errorMessage = nil

        Task {
            do {
                try await container.saveExchangeRateUseCase.execute(
                    baseCode: baseCurrencyCode,
                    targetCode: targetCurrencyCode,
                    rate: rate
                )
                await MainActor.run {
                    onSave()
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isSaving = false
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}

