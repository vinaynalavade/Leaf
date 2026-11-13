import SwiftUI

/// Comprehensive settings screen for Multi-Currency preferences and manual Exchange Rate management.
/// Allows setting the primary application currency (with transactional recalculation of primary equivalents),
/// viewing all 11 supported global currencies, and inspecting/editing exchange rates.
public struct CurrencySettingsView: View {
    @Environment(AppContainer.self) private var container
    @Environment(\.colorScheme) private var colorScheme

    @State private var primaryCurrency: Currency = .default
    @State private var exchangeRates: [ExchangeRate] = []
    @State private var isLoading: Bool = true
    @State private var isChangingCurrency: Bool = false
    @State private var selectedCurrencyToChange: Currency? = nil
    @State private var showCurrencyChangeAlert: Bool = false
    @State private var rateToEdit: ExchangeRate? = nil
    @State private var errorMessage: String? = nil
    @State private var successNotice: String? = nil

    public init() {}

    public var body: some View {
        ZStack {
            LeafTheme.canvas(for: colorScheme).ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    // 1. Primary Currency Hero Card
                    primaryCurrencyCard

                    // 2. Accounting Invariance Notice Card
                    accountingRuleCard

                    // 3. Active Exchange Rates Section
                    exchangeRatesSection

                    // 4. Supported Global Currencies Section
                    supportedCurrenciesSection

                    Spacer(minLength: 32)
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
            }
            .refreshable {
                await loadRates()
            }

            if isChangingCurrency {
                ZStack {
                    Color.black.opacity(0.4).ignoresSafeArea()
                    VStack(spacing: 12) {
                        ProgressView().tint(.white).scaleEffect(1.3)
                        Text("Recalculating Primary Equivalents...")
                            .font(LeafTypography.bodyBold)
                            .foregroundStyle(.white)
                        Text("Preserving all original transaction amounts.")
                            .font(LeafTypography.caption)
                            .foregroundStyle(Color.white.opacity(0.8))
                    }
                    .padding(24)
                    .background(LeafTheme.surface(for: colorScheme))
                    .cornerRadius(16)
                }
            }
        }
        .navigationTitle("Currency & Rates")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $rateToEdit) { rate in
            EditExchangeRateSheet(
                baseCurrencyCode: rate.baseCurrencyCode,
                targetCurrencyCode: rate.targetCurrencyCode,
                currentRate: rate.rate
            ) {
                Task {
                    await loadRates()
                }
            }
        }
        .alert("Change Primary Currency?", isPresented: $showCurrencyChangeAlert) {
            Button("Cancel", role: .cancel) {
                selectedCurrencyToChange = nil
            }
            Button("Confirm Change") {
                if let newCurr = selectedCurrencyToChange {
                    performCurrencyChange(to: newCurr)
                }
            }
        } message: {
            if let newCurr = selectedCurrencyToChange {
                Text("Your primary reporting currency will change to \(newCurr.name) (\(newCurr.code)). All original transaction amounts and currencies will remain completely intact. Their primary reporting equivalents will be updated.")
            } else {
                Text("Confirm changing primary currency?")
            }
        }
        .task {
            await loadRates()
        }
    }

    // MARK: - Subviews

    @ViewBuilder
    private var primaryCurrencyCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 44, height: 44)

                    Text(primaryCurrency.symbol)
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("PRIMARY REPORTING CURRENCY")
                        .font(LeafTypography.captionBold)
                        .foregroundStyle(Color.white.opacity(0.8))

                    Text("\(primaryCurrency.name) (\(primaryCurrency.code))")
                        .font(LeafTypography.titleMedium)
                        .foregroundStyle(.white)
                }

                Spacer()
            }

            Text("All totals on your Dashboard, Category Analytics, and Budgets are aggregated in this currency to prevent mixing raw amounts.")
                .font(LeafTypography.caption)
                .foregroundStyle(Color.white.opacity(0.85))

            Divider().background(Color.white.opacity(0.2))

            Menu {
                ForEach(Currency.supportedCurrencies) { curr in
                    Button {
                        if curr.code != primaryCurrency.code {
                            selectedCurrencyToChange = curr
                            showCurrencyChangeAlert = true
                        }
                    } label: {
                        HStack {
                            Text("\(curr.symbol)  \(curr.name) (\(curr.code))")
                            if curr.code == primaryCurrency.code {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                HStack {
                    Text("Change Primary Currency")
                        .font(LeafTypography.captionBold)
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 11, weight: .bold))
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Color.white.opacity(0.22))
                .foregroundStyle(.white)
                .clipShape(Capsule())
            }
        }
        .padding(18)
        .background(LeafTheme.heroGradient(for: colorScheme))
        .cornerRadius(16)
        .shadow(color: LeafTheme.brandEmerald.opacity(0.2), radius: 8, x: 0, y: 3)
    }

    @ViewBuilder
    private var accountingRuleCard: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "checkmark.shield.fill")
                .font(.system(size: 18))
                .foregroundStyle(LeafTheme.brandEmerald)

            VStack(alignment: .leading, spacing: 4) {
                Text("Authentic Accounting Guarantee")
                    .font(LeafTypography.bodyBold)
                    .foregroundStyle(LeafTheme.textPrimary(for: colorScheme))

                Text("Leaf never overwrites or discards original transaction amounts. A €50 meal in Paris is forever recorded as €50. Historical exchange rates are locked at creation time.")
                    .font(LeafTypography.caption)
                    .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(LeafTheme.card(for: colorScheme))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(LeafTheme.border(for: colorScheme), lineWidth: 1)
        )
    }

    @ViewBuilder
    private var exchangeRatesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("EXCHANGE RATES (TO \(primaryCurrency.code))")
                    .font(LeafTypography.captionBold)
                    .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))

                Spacer()

                Text("Tap to edit")
                    .font(LeafTypography.caption)
                    .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
            }
            .padding(.horizontal, 4)

            LazyVStack(spacing: 8) {
                ForEach(exchangeRates) { rate in
                    exchangeRateRow(rate)
                }
            }
        }
    }

    @ViewBuilder
    private func exchangeRateRow(_ rate: ExchangeRate) -> some View {
        Button {
            rateToEdit = rate
        } label: {
            HStack(spacing: 12) {
                let baseCurr = Currency.fromCode(rate.baseCurrencyCode)

                ZStack {
                    Circle()
                        .fill(LeafTheme.brandEmerald.opacity(0.12))
                        .frame(width: 36, height: 36)

                    Text(baseCurr.symbol)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(LeafTheme.brandEmerald)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("\(baseCurr.name) (\(rate.baseCurrencyCode))")
                        .font(LeafTypography.bodyBold)
                        .foregroundStyle(LeafTheme.textPrimary(for: colorScheme))

                    HStack(spacing: 6) {
                        Text("1 \(rate.baseCurrencyCode) = \(rate.formattedRate) \(rate.targetCurrencyCode)")
                            .font(LeafTypography.caption)
                            .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))

                        Text(rate.source)
                            .font(.system(size: 9, weight: .bold))
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(rate.source == "MANUAL" ? LeafTheme.brandEmerald.opacity(0.15) : Color.gray.opacity(0.12))
                            .foregroundStyle(rate.source == "MANUAL" ? LeafTheme.brandEmerald : LeafTheme.textSecondary(for: colorScheme))
                            .cornerRadius(4)
                    }
                }

                Spacer()

                Image(systemName: "pencil.circle")
                    .font(.system(size: 18))
                    .foregroundStyle(LeafTheme.brandEmerald)
            }
            .padding(14)
            .background(LeafTheme.card(for: colorScheme))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(LeafTheme.border(for: colorScheme), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var supportedCurrenciesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("ALL SUPPORTED CURRENCIES (\(Currency.supportedCurrencies.count))")
                .font(LeafTypography.captionBold)
                .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
                .padding(.horizontal, 4)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 10)], spacing: 10) {
                ForEach(Currency.supportedCurrencies) { curr in
                    HStack(spacing: 10) {
                        Text(curr.symbol)
                            .font(LeafTypography.bodyBold)
                            .foregroundStyle(LeafTheme.brandEmerald)
                            .frame(width: 24)

                        VStack(alignment: .leading, spacing: 1) {
                            Text(curr.code)
                                .font(LeafTypography.captionBold)
                                .foregroundStyle(LeafTheme.textPrimary(for: colorScheme))

                            Text(curr.name)
                                .font(.system(size: 10))
                                .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
                                .lineLimit(1)
                        }
                        Spacer()
                    }
                    .padding(10)
                    .background(LeafTheme.card(for: colorScheme))
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(LeafTheme.border(for: colorScheme), lineWidth: 1)
                    )
                }
            }
        }
    }

    // MARK: - Actions

    private func loadRates() async {
        isLoading = true
        let prefs = container.preferencesRepository.getUserPreferences()
        self.primaryCurrency = Currency.fromCode(prefs.currencyCode)

        do {
            let rates = try await container.getExchangeRatesUseCase.execute(targetCurrencyCode: primaryCurrency.code)
            await MainActor.run {
                self.exchangeRates = rates
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to load exchange rates: \(error.localizedDescription)"
                self.isLoading = false
            }
        }
    }

    private func performCurrencyChange(to newCurrency: Currency) {
        isChangingCurrency = true
        selectedCurrencyToChange = nil

        Task {
            do {
                try await container.changePrimaryCurrencyUseCase.execute(newCurrencyCode: newCurrency.code)
                await MainActor.run {
                    self.primaryCurrency = newCurrency
                    self.isChangingCurrency = false
                }
                await loadRates()
            } catch {
                await MainActor.run {
                    self.isChangingCurrency = false
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
}

