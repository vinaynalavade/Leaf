import SwiftUI

/// Native Recurring Deposit (RD) calculator screen with periodic installment compounding.
public struct RdCalculatorView: View {
    @Environment(AppContainer.self) private var container
    @Environment(\.colorScheme) private var colorScheme
    @State private var viewModel: RdCalculatorViewModel?

    public init() {}

    private var currentCurrency: Currency {
        container.preferencesRepository.getUserPreferences().currency
    }

    private func formatAmount(_ value: Double) -> String {
        let subunits = Int64(round(value * Double(currentCurrency.subunitFactor)))
        return Amount(subunits: subunits).formatted(with: currentCurrency)
    }

    public var body: some View {
        ZStack {
            LeafTheme.canvas(for: colorScheme).ignoresSafeArea()

            if let vm = viewModel {
                ScrollView {
                    VStack(spacing: 20) {
                        // 1. Result Hero Card
                        CalculatorResultHeroCard(
                            title: "Maturity Corpus",
                            formattedAmount: formatAmount(vm.result.maturityAmount),
                            subtitle: "Total payout after \(vm.tenureMonthsString) monthly deposits",
                            accentGradient: LinearGradient(
                                colors: [Color(hex: "#5B21B6"), Color(hex: "#7C3AED"), Color(hex: "#8B5CF6")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            secondaryPills: [
                                ("Deposited", formatAmount(vm.result.investedAmount)),
                                ("Interest", formatAmount(vm.result.totalInterest))
                            ]
                        )

                        // 2. Inputs Section
                        VStack(alignment: .leading, spacing: 14) {
                            Text("RECURRING DEPOSIT DETAILS")
                                .font(LeafTypography.captionBold)
                                .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
                                .padding(.horizontal, 4)

                            CalculatorInputField(
                                label: "Monthly Deposit",
                                text: Binding(
                                    get: { vm.monthlyDepositString },
                                    set: { vm.monthlyDepositString = $0; vm.calculate() }
                                ),
                                prefix: currentCurrency.symbol
                            )

                            CalculatorInputField(
                                label: "Annual Interest Rate",
                                text: Binding(
                                    get: { vm.interestRateString },
                                    set: { vm.interestRateString = $0; vm.calculate() }
                                ),
                                suffix: "% p.a."
                            )

                            VStack(alignment: .leading, spacing: 8) {
                                CalculatorInputField(
                                    label: "Tenure",
                                    text: Binding(
                                        get: { vm.tenureMonthsString },
                                        set: { vm.tenureMonthsString = $0; vm.calculate() }
                                    ),
                                    suffix: "Months"
                                )

                                HStack(spacing: 8) {
                                    ForEach([6, 12, 24, 36, 60], id: \.self) { months in
                                        Button {
                                            vm.setMonthsPreset(months)
                                        } label: {
                                            Text(months >= 12 ? "\(months / 12)Y (\(months)M)" : "\(months)M")
                                                .font(LeafTypography.captionBold)
                                                .padding(.horizontal, 10)
                                                .padding(.vertical, 6)
                                                .background(
                                                    vm.tenureMonthsString == "\(months)"
                                                        ? LeafTheme.purpleAccent.opacity(0.15)
                                                        : LeafTheme.card(for: colorScheme)
                                                )
                                                .foregroundStyle(
                                                    vm.tenureMonthsString == "\(months)"
                                                        ? LeafTheme.purpleAccent
                                                        : LeafTheme.textPrimary(for: colorScheme)
                                                )
                                                .cornerRadius(8)
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 8)
                                                        .stroke(
                                                            vm.tenureMonthsString == "\(months)"
                                                                ? LeafTheme.purpleAccent
                                                                : LeafTheme.border(for: colorScheme),
                                                            lineWidth: 1
                                                        )
                                                )
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }

                            // Compounding Frequency Picker
                            VStack(alignment: .leading, spacing: 6) {
                                Text("COMPOUNDING CONVENTION")
                                    .font(LeafTypography.captionBold)
                                    .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))

                                Picker("Compounding Frequency", selection: Binding(
                                    get: { vm.compoundingFrequency },
                                    set: { vm.compoundingFrequency = $0; vm.calculate() }
                                )) {
                                    ForEach(CompoundingFrequency.allCases) { freq in
                                        Text(freq.displayName).tag(freq)
                                    }
                                }
                                .pickerStyle(.menu)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 10)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(LeafTheme.card(for: colorScheme))
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(LeafTheme.border(for: colorScheme), lineWidth: 1)
                                )
                            }
                        }

                        // 3. Breakdown Summary Card
                        VStack(spacing: 10) {
                            CalculatorBreakdownRow(
                                label: "Total Deposited",
                                value: formatAmount(vm.result.investedAmount),
                                subtitle: "\(vm.tenureMonthsString) monthly installments",
                                isBold: false
                            )

                            Divider()

                            CalculatorBreakdownRow(
                                label: "Total Interest Earned",
                                value: formatAmount(vm.result.totalInterest),
                                accentColor: LeafTheme.purpleAccent,
                                isBold: false
                            )

                            Divider()

                            CalculatorBreakdownRow(
                                label: "Total Maturity Value",
                                value: formatAmount(vm.result.maturityAmount),
                                accentColor: LeafTheme.purpleAccent,
                                isBold: true
                            )
                        }
                        .padding(16)
                        .background(LeafTheme.card(for: colorScheme))
                        .cornerRadius(14)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(LeafTheme.border(for: colorScheme), lineWidth: 1)
                        )

                        // 4. Assumption & Methodology Disclosure Card
                        CalculatorAssumptionDisclosureCard(
                            title: "Recurring Deposit Assumptions",
                            assumptions: [
                                "Compounding Convention: In accordance with Indian Banks' Association (IBA) code, interest compounds quarterly by default.",
                                "Individual duration: Each monthly installment compounds for its specific remaining tenure (n - m + 1 months) until maturity.",
                                "Selected compounding frequency directly adjusts the compounding rate base and period exponent.",
                                "Total deposited principal and total interest earned strictly reconcile to the final maturity corpus."
                            ],
                            disclaimer: "Maturity calculation is an estimate based on uniform 30-day monthly intervals. Bank payouts may vary depending on actual calendar day counts (actual/365 convention) and statutory TDS deductions."
                        )

                        Spacer(minLength: 32)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                }
            } else {
                ProgressView()
                    .tint(LeafTheme.accent(for: colorScheme))
            }
        }
        .navigationTitle("Recurring Deposit (RD)")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Reset") {
                    viewModel?.reset()
                }
                .font(LeafTypography.captionBold)
                .foregroundStyle(LeafTheme.accent(for: colorScheme))
            }
        }
        .task {
            if viewModel == nil {
                self.viewModel = RdCalculatorViewModel(calculateRdUseCase: container.calculateRdUseCase)
            }
        }
    }
}

