import SwiftUI

/// Native EMI & Loan repayment calculator screen with interactive reducing-balance schedule.
public struct EmiCalculatorView: View {
    @Environment(AppContainer.self) private var container
    @Environment(\.colorScheme) private var colorScheme
    @State private var viewModel: EmiCalculatorViewModel?

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
                            title: "Monthly EMI",
                            formattedAmount: formatAmount(vm.result.monthlyEmi),
                            subtitle: "Total loan repayment over \(vm.tenureString) \(vm.tenureUnit.displayName.lowercased())",
                            secondaryPills: [
                                ("Principal", formatAmount(vm.result.totalPrincipal)),
                                ("Total Interest", formatAmount(vm.result.totalInterest))
                            ]
                        )

                        // 2. Principal vs Interest Visual Ratio Bar
                        if vm.result.totalPayment > 0 {
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Text("PAYMENT BREAKDOWN")
                                        .font(LeafTypography.captionBold)
                                        .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
                                    Spacer()
                                    Text("\(Int(round(vm.result.principalRatio * 100)))% Principal  •  \(Int(round(vm.result.interestRatio * 100)))% Interest")
                                        .font(LeafTypography.caption)
                                        .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
                                }

                                GeometryReader { geo in
                                    HStack(spacing: 3) {
                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(LeafTheme.brandEmerald)
                                            .frame(width: max(4, geo.size.width * CGFloat(vm.result.principalRatio)))

                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(LeafTheme.expenseCoral)
                                            .frame(width: max(4, geo.size.width * CGFloat(vm.result.interestRatio)))
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
                            Text("LOAN DETAILS")
                                .font(LeafTypography.captionBold)
                                .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
                                .padding(.horizontal, 4)

                            CalculatorInputField(
                                label: "Loan Amount",
                                text: Binding(
                                    get: { vm.principalString },
                                    set: { vm.principalString = $0; vm.calculate() }
                                ),
                                prefix: currentCurrency.symbol
                            )

                            CalculatorInputField(
                                label: "Annual Interest Rate",
                                text: Binding(
                                    get: { vm.rateString },
                                    set: { vm.rateString = $0; vm.calculate() }
                                ),
                                suffix: "% p.a."
                            )

                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    CalculatorInputField(
                                        label: "Loan Tenure",
                                        text: Binding(
                                            get: { vm.tenureString },
                                            set: { vm.tenureString = $0; vm.calculate() }
                                        )
                                    )

                                    VStack(alignment: .leading, spacing: 6) {
                                        Text("UNIT")
                                            .font(LeafTypography.captionBold)
                                            .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))

                                        Picker("Tenure Unit", selection: Binding(
                                            get: { vm.tenureUnit },
                                            set: { vm.tenureUnit = $0; vm.calculate() }
                                        )) {
                                            ForEach(EmiTenureUnit.allCases) { unit in
                                                Text(unit.displayName).tag(unit)
                                            }
                                        }
                                        .pickerStyle(.segmented)
                                        .padding(.top, 4)
                                    }
                                    .frame(width: 140)
                                }

                                // Quick tenure presets (years)
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 8) {
                                        ForEach([5, 10, 15, 20, 25, 30], id: \.self) { yrs in
                                            Button {
                                                vm.setTenurePreset(yrs)
                                            } label: {
                                                Text("\(yrs) Years")
                                                    .font(LeafTypography.captionBold)
                                                    .padding(.horizontal, 12)
                                                    .padding(.vertical, 6)
                                                    .background(
                                                        vm.tenureUnit == .years && vm.tenureString == "\(yrs)"
                                                            ? LeafTheme.brandEmerald.opacity(0.15)
                                                            : LeafTheme.card(for: colorScheme)
                                                    )
                                                    .foregroundStyle(
                                                        vm.tenureUnit == .years && vm.tenureString == "\(yrs)"
                                                            ? LeafTheme.brandEmerald
                                                            : LeafTheme.textPrimary(for: colorScheme)
                                                    )
                                                    .cornerRadius(8)
                                                    .overlay(
                                                        RoundedRectangle(cornerRadius: 8)
                                                            .stroke(
                                                                vm.tenureUnit == .years && vm.tenureString == "\(yrs)"
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
                            }
                        }

                        // 4. Breakdown Summary Card
                        VStack(spacing: 10) {
                            CalculatorBreakdownRow(
                                label: "Principal Borrowed",
                                value: formatAmount(vm.result.totalPrincipal),
                                isBold: false
                            )

                            Divider()

                            CalculatorBreakdownRow(
                                label: "Total Interest Cost",
                                value: formatAmount(vm.result.totalInterest),
                                accentColor: LeafTheme.expenseCoral,
                                isBold: false
                            )

                            Divider()

                            CalculatorBreakdownRow(
                                label: "Total Amount Payable",
                                value: formatAmount(vm.result.totalPayment),
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

                        // 5. Button to view month-by-month amortisation schedule
                        if !vm.result.amortizationSchedule.isEmpty {
                            Button {
                                vm.isScheduleSheetPresented = true
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: "list.bullet.rectangle.fill")
                                        .font(.system(size: 15, weight: .semibold))

                                    Text("View Amortisation Schedule (\(vm.result.amortizationSchedule.count) Months)")
                                        .font(LeafTypography.bodyBold)
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 48)
                                .background(LeafTheme.card(for: colorScheme))
                                .foregroundStyle(LeafTheme.accent(for: colorScheme))
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(LeafTheme.accent(for: colorScheme), lineWidth: 1)
                                )
                            }
                            .buttonStyle(.plain)
                        }

                        // 6. Assumption & Methodology Disclosure
                        CalculatorAssumptionDisclosureCard(
                            title: "Loan & EMI Assumptions",
                            assumptions: [
                                "Reducing-balance amortisation: interest is calculated monthly on the outstanding loan balance.",
                                "Assumes a fixed annual interest rate and constant equated monthly installments throughout the tenure.",
                                "Schedule reconciles exact fractional cent rounding in the final payment installment.",
                                "Excludes loan processing fees, statutory stamp duty, mortgage insurance, and prepayment charges."
                            ]
                        )

                        Spacer(minLength: 32)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                }
                .sheet(isPresented: Binding(
                    get: { vm.isScheduleSheetPresented },
                    set: { vm.isScheduleSheetPresented = $0 }
                )) {
                    CalculatorAmortizationScheduleView(
                        schedule: vm.result.amortizationSchedule,
                        currency: currentCurrency
                    )
                }
            } else {
                ProgressView()
                    .tint(LeafTheme.accent(for: colorScheme))
            }
        }
        .navigationTitle("Loan / EMI Calculator")
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
                self.viewModel = EmiCalculatorViewModel(calculateEmiUseCase: container.calculateEmiUseCase)
            }
        }
    }
}

