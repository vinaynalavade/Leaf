import SwiftUI

/// Native Fixed Deposit (FD) calculator screen with flexible compounding frequency selection.
public struct FdCalculatorView: View {
    @Environment(AppContainer.self) private var container
    @Environment(\.colorScheme) private var colorScheme
    @State private var viewModel: FdCalculatorViewModel?

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
                            title: "Maturity Amount",
                            formattedAmount: formatAmount(vm.result.maturityAmount),
                            subtitle: "Total payout after \(vm.tenureYearsString) years with \(vm.compoundingFrequency.displayName.lowercased()) compounding",
                            accentGradient: LinearGradient(
                                colors: [Color(hex: "#1E3A8A"), Color(hex: "#2563EB"), Color(hex: "#3B82F6")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            secondaryPills: [
                                ("Principal", formatAmount(vm.result.investedAmount)),
                                ("Interest Earned", formatAmount(vm.result.totalInterest))
                            ]
                        )

                        // 2. Inputs Section
                        VStack(alignment: .leading, spacing: 14) {
                            Text("DEPOSIT DETAILS")
                                .font(LeafTypography.captionBold)
                                .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
                                .padding(.horizontal, 4)

                            CalculatorInputField(
                                label: "Principal Deposit",
                                text: Binding(
                                    get: { vm.principalString },
                                    set: { vm.principalString = $0; vm.calculate() }
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
                                        get: { vm.tenureYearsString },
                                        set: { vm.tenureYearsString = $0; vm.calculate() }
                                    ),
                                    suffix: "Years"
                                )

                                HStack(spacing: 8) {
                                    ForEach([1, 2, 3, 5, 10], id: \.self) { yrs in
                                        Button {
                                            vm.setTenurePreset(yrs)
                                        } label: {
                                            Text("\(yrs)Y")
                                                .font(LeafTypography.captionBold)
                                                .padding(.horizontal, 12)
                                                .padding(.vertical, 6)
                                                .background(
                                                    vm.tenureYearsString == "\(yrs)"
                                                        ? LeafTheme.infoBlue.opacity(0.15)
                                                        : LeafTheme.card(for: colorScheme)
                                                )
                                                .foregroundStyle(
                                                    vm.tenureYearsString == "\(yrs)"
                                                        ? LeafTheme.infoBlue
                                                        : LeafTheme.textPrimary(for: colorScheme)
                                                )
                                                .cornerRadius(8)
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 8)
                                                        .stroke(
                                                            vm.tenureYearsString == "\(yrs)"
                                                                ? LeafTheme.infoBlue
                                                                : LeafTheme.border(for: colorScheme),
                                                            lineWidth: 1
                                                        )
                                                )
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }

                            // Compounding Frequency Selector
                            VStack(alignment: .leading, spacing: 6) {
                                Text("COMPOUNDING FREQUENCY")
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
                                label: "Principal Deposited",
                                value: formatAmount(vm.result.investedAmount),
                                isBold: false
                            )

                            Divider()

                            CalculatorBreakdownRow(
                                label: "Total Interest Earned",
                                value: formatAmount(vm.result.totalInterest),
                                accentColor: LeafTheme.infoBlue,
                                isBold: false
                            )

                            Divider()

                            CalculatorBreakdownRow(
                                label: "Effective Annual Rate (EAR)",
                                value: String(format: "%.2f%%", vm.result.effectiveAnnualRate),
                                subtitle: "Compounded \(vm.compoundingFrequency.displayName.lowercased())",
                                isBold: false
                            )

                            Divider()

                            CalculatorBreakdownRow(
                                label: "Total Maturity Value",
                                value: formatAmount(vm.result.maturityAmount),
                                accentColor: LeafTheme.infoBlue,
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
                            title: "Term Deposit Assumptions",
                            assumptions: [
                                "Compounding follows the selected frequency (Quarterly standard per commercial banking practice, Monthly, Half-Yearly, Annually).",
                                "Effective Annual Rate (EAR) reflects the true annualized yield generated by intra-year compounding.",
                                "Assumes full tenure reinvestment with no interim interest payouts or premature withdrawals.",
                                "Principal deposited and total interest earned strictly reconcile to total maturity value."
                            ],
                            disclaimer: "Actual bank maturity payouts may vary slightly due to bank-specific day-count conventions (actual/365 vs 30/360) and applicable Tax Deducted at Source (TDS)."
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
        .navigationTitle("Fixed Deposit (FD)")
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
                self.viewModel = FdCalculatorViewModel(calculateFdUseCase: container.calculateFdUseCase)
            }
        }
    }
}

