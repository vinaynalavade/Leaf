import SwiftUI

/// Native SIP investment calculator screen supporting compounding and annual step-up increments.
public struct SipCalculatorView: View {
    @Environment(AppContainer.self) private var container
    @Environment(\.colorScheme) private var colorScheme
    @State private var viewModel: SipCalculatorViewModel?

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
                        // 1. Primary Result Hero Card
                        CalculatorResultHeroCard(
                            title: "Estimated Final Corpus",
                            formattedAmount: formatAmount(vm.result.totalCorpus),
                            subtitle: "Projected wealth after \(vm.durationYearsString) years of systematic investing",
                            secondaryPills: [
                                ("Invested", formatAmount(vm.result.totalInvested)),
                                ("Wealth Gained", formatAmount(vm.result.estimatedReturns))
                            ]
                        )

                        // 2. Ratio Breakdown Bar
                        if vm.result.totalCorpus > 0 {
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Text("CORPUS COMPOSITION")
                                        .font(LeafTypography.captionBold)
                                        .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
                                    Spacer()
                                    let invPct = Int(round((1.0 - vm.result.returnsRatio) * 100))
                                    let retPct = Int(round(vm.result.returnsRatio * 100))
                                    Text("\(invPct)% Invested  •  \(retPct)% Returns")
                                        .font(LeafTypography.caption)
                                        .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
                                }

                                GeometryReader { geo in
                                    HStack(spacing: 3) {
                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(LeafTheme.infoBlue)
                                            .frame(width: max(4, geo.size.width * CGFloat(1.0 - vm.result.returnsRatio)))

                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(LeafTheme.brandEmerald)
                                            .frame(width: max(4, geo.size.width * CGFloat(vm.result.returnsRatio)))
                                    }
                                }
                                .frame(height: 10)
                            }
                            .padding(14)
                            .background(LeafTheme.card(for: colorScheme))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(LeafTheme.border(for: colorScheme), lineWidth: 1)
                            )
                        }

                        // 3. Inputs Section
                        VStack(alignment: .leading, spacing: 14) {
                            Text("INVESTMENT PLAN")
                                .font(LeafTypography.captionBold)
                                .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
                                .padding(.horizontal, 4)

                            CalculatorInputField(
                                label: "Monthly Investment",
                                text: Binding(
                                    get: { vm.monthlyInvestmentString },
                                    set: { vm.monthlyInvestmentString = $0; vm.calculate() }
                                ),
                                prefix: currentCurrency.symbol
                            )

                            VStack(alignment: .leading, spacing: 8) {
                                CalculatorInputField(
                                    label: "Expected Annual Return",
                                    text: Binding(
                                        get: { vm.annualReturnString },
                                        set: { vm.annualReturnString = $0; vm.calculate() }
                                    ),
                                    suffix: "% p.a."
                                )

                                // Quick return rate chips
                                HStack(spacing: 8) {
                                    ForEach([8.0, 10.0, 12.0, 15.0], id: \.self) { rate in
                                        Button {
                                            vm.setReturnPreset(rate)
                                        } label: {
                                            Text(String(format: "%.0f%%", rate))
                                                .font(LeafTypography.captionBold)
                                                .padding(.horizontal, 12)
                                                .padding(.vertical, 6)
                                                .background(
                                                    vm.annualReturnString == String(format: "%.1f", rate)
                                                        ? LeafTheme.brandEmerald.opacity(0.15)
                                                        : LeafTheme.card(for: colorScheme)
                                                )
                                                .foregroundStyle(
                                                    vm.annualReturnString == String(format: "%.1f", rate)
                                                        ? LeafTheme.brandEmerald
                                                        : LeafTheme.textPrimary(for: colorScheme)
                                                )
                                                .cornerRadius(8)
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 8)
                                                        .stroke(
                                                            vm.annualReturnString == String(format: "%.1f", rate)
                                                                ? LeafTheme.brandEmerald
                                                                : LeafTheme.border(for: colorScheme),
                                                            lineWidth: 1
                                                        )
                                                )
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }

                            VStack(alignment: .leading, spacing: 8) {
                                CalculatorInputField(
                                    label: "Time Horizon",
                                    text: Binding(
                                        get: { vm.durationYearsString },
                                        set: { vm.durationYearsString = $0; vm.calculate() }
                                    ),
                                    suffix: "Years"
                                )

                                // Quick duration chips
                                HStack(spacing: 8) {
                                    ForEach([3, 5, 10, 15, 20], id: \.self) { yrs in
                                        Button {
                                            vm.setDurationPreset(yrs)
                                        } label: {
                                            Text("\(yrs)Y")
                                                .font(LeafTypography.captionBold)
                                                .padding(.horizontal, 12)
                                                .padding(.vertical, 6)
                                                .background(
                                                    vm.durationYearsString == "\(yrs)"
                                                        ? LeafTheme.brandEmerald.opacity(0.15)
                                                        : LeafTheme.card(for: colorScheme)
                                                )
                                                .foregroundStyle(
                                                    vm.durationYearsString == "\(yrs)"
                                                        ? LeafTheme.brandEmerald
                                                        : LeafTheme.textPrimary(for: colorScheme)
                                                )
                                                .cornerRadius(8)
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 8)
                                                        .stroke(
                                                            vm.durationYearsString == "\(yrs)"
                                                                ? LeafTheme.brandEmerald
                                                                : LeafTheme.border(for: colorScheme),
                                                            lineWidth: 1
                                                        )
                                                )
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }

                            // Step-Up SIP Section
                            VStack(alignment: .leading, spacing: 10) {
                                Toggle(isOn: Binding(
                                    get: { vm.isStepUpEnabled },
                                    set: { vm.isStepUpEnabled = $0; vm.calculate() }
                                )) {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Annual Step-Up")
                                            .font(LeafTypography.bodyBold)
                                            .foregroundStyle(LeafTheme.textPrimary(for: colorScheme))
                                        Text("Increase contribution by a percentage each year")
                                            .font(LeafTypography.caption)
                                            .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
                                    }
                                }
                                .tint(LeafTheme.brandEmerald)

                                if vm.isStepUpEnabled {
                                    CalculatorInputField(
                                        label: "Yearly Step-Up Rate",
                                        text: Binding(
                                            get: { vm.stepUpPercentageString },
                                            set: { vm.stepUpPercentageString = $0; vm.calculate() }
                                        ),
                                        suffix: "% per year",
                                        helperText: "Applies compounding increase to monthly deposit annually."
                                    )
                                }
                            }
                            .padding(14)
                            .background(LeafTheme.card(for: colorScheme))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(LeafTheme.border(for: colorScheme), lineWidth: 1)
                            )
                        }

                        // 4. Breakdown Summary Card
                        VStack(spacing: 10) {
                            CalculatorBreakdownRow(
                                label: "Total Invested",
                                value: formatAmount(vm.result.totalInvested),
                                isBold: false
                            )

                            Divider()

                            CalculatorBreakdownRow(
                                label: "Estimated Wealth Gained",
                                value: formatAmount(vm.result.estimatedReturns),
                                accentColor: LeafTheme.brandEmerald,
                                isBold: false
                            )

                            Divider()

                            CalculatorBreakdownRow(
                                label: "Projected Maturity Corpus",
                                value: formatAmount(vm.result.totalCorpus),
                                accentColor: LeafTheme.brandEmerald,
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

                        // 5. Assumption & Methodology Disclosure Card
                        CalculatorAssumptionDisclosureCard(
                            title: "SIP Assumptions & Projections",
                            assumptions: [
                                "Monthly annuity-due compounding: contributions are assumed at the beginning of each monthly period.",
                                "Expected annual return is converted into an equivalent monthly compounding rate.",
                                "Step-up contributions (if enabled) scale monthly deposits at the beginning of each investment year.",
                                "Total invested amount and estimated returns strictly reconcile to the final projected corpus."
                            ],
                            disclaimer: "Projections are mathematical simulations and not guaranteed returns. Mutual fund and equity investments are subject to market risks, NAV volatility, capital gains taxes, and fund expense ratios."
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
        .navigationTitle("SIP Calculator")
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
                self.viewModel = SipCalculatorViewModel(calculateSipUseCase: container.calculateSipUseCase)
            }
        }
    }
}

