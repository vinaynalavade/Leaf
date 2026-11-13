import SwiftUI

/// Native Goods & Services Tax (GST) calculator screen tailored for Indian tax compliance rules.
public struct GstCalculatorView: View {
    @Environment(AppContainer.self) private var container
    @Environment(\.colorScheme) private var colorScheme
    @State private var viewModel: GstCalculatorViewModel?

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
                        // 1. Mode & Jurisdiction Pickers
                        VStack(spacing: 10) {
                            Picker("Mode", selection: Binding(
                                get: { vm.mode },
                                set: { vm.mode = $0; vm.calculate() }
                            )) {
                                ForEach(GstCalculationMode.allCases) { mode in
                                    Text(mode.displayName).tag(mode)
                                }
                            }
                            .pickerStyle(.segmented)

                            Picker("Jurisdiction", selection: Binding(
                                get: { vm.transactionType },
                                set: { vm.transactionType = $0; vm.calculate() }
                            )) {
                                ForEach(GstTransactionType.allCases) { type in
                                    Text(type.displayName).tag(type)
                                }
                            }
                            .pickerStyle(.segmented)
                        }
                        .padding(.horizontal, 4)

                        // 2. Result Hero Card
                        CalculatorResultHeroCard(
                            title: vm.mode == .exclusive ? "Final Amount Payable" : "Net Taxable Amount",
                            formattedAmount: formatAmount(vm.mode == .exclusive ? vm.result.finalAmount : vm.result.taxableAmount),
                            subtitle: "\(String(format: "%.1f%%", vm.result.gstRate)) GST \(vm.mode == .exclusive ? "added to base price" : "extracted from total")",
                            accentGradient: LinearGradient(
                                colors: [Color(hex: "#B91C1C"), Color(hex: "#DC2626"), Color(hex: "#EF4444")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            secondaryPills: [
                                ("Taxable Value", formatAmount(vm.result.taxableAmount)),
                                ("Total GST", formatAmount(vm.result.totalGst))
                            ]
                        )

                        // 3. Inputs Section
                        VStack(alignment: .leading, spacing: 14) {
                            Text("AMOUNT & TAX SLAB")
                                .font(LeafTypography.captionBold)
                                .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
                                .padding(.horizontal, 4)

                            CalculatorInputField(
                                label: vm.mode == .exclusive ? "Taxable Net Amount" : "Gross Total Amount (Inclusive)",
                                text: Binding(
                                    get: { vm.amountString },
                                    set: { vm.amountString = $0; vm.calculate() }
                                ),
                                prefix: currentCurrency.symbol
                            )

                            // GST Rate Presets
                            VStack(alignment: .leading, spacing: 8) {
                                Text("GST RATE PERCENTAGE")
                                    .font(LeafTypography.captionBold)
                                    .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))

                                HStack(spacing: 8) {
                                    ForEach([0.0, 5.0, 12.0, 18.0, 28.0], id: \.self) { rate in
                                        Button {
                                            vm.selectRatePreset(rate)
                                        } label: {
                                            Text(String(format: "%.0f%%", rate))
                                                .font(LeafTypography.captionBold)
                                                .frame(maxWidth: .infinity)
                                                .padding(.vertical, 8)
                                                .background(
                                                    !vm.isCustomRate && vm.selectedRate == rate
                                                        ? LeafTheme.expenseCoral.opacity(0.18)
                                                        : LeafTheme.card(for: colorScheme)
                                                )
                                                .foregroundStyle(
                                                    !vm.isCustomRate && vm.selectedRate == rate
                                                        ? LeafTheme.expenseCoral
                                                        : LeafTheme.textPrimary(for: colorScheme)
                                                )
                                                .cornerRadius(8)
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 8)
                                                        .stroke(
                                                            !vm.isCustomRate && vm.selectedRate == rate
                                                                ? LeafTheme.expenseCoral
                                                                : LeafTheme.border(for: colorScheme),
                                                            lineWidth: 1
                                                        )
                                                )
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }

                                Toggle(isOn: Binding(
                                    get: { vm.isCustomRate },
                                    set: { vm.isCustomRate = $0; vm.calculate() }
                                )) {
                                    Text("Custom GST Rate")
                                        .font(LeafTypography.bodyMedium)
                                        .foregroundStyle(LeafTheme.textPrimary(for: colorScheme))
                                }
                                .tint(LeafTheme.expenseCoral)
                                .padding(.top, 4)

                                if vm.isCustomRate {
                                    CalculatorInputField(
                                        label: "Custom Rate %",
                                        text: Binding(
                                            get: { vm.customRateString },
                                            set: { vm.customRateString = $0; vm.calculate() }
                                        ),
                                        suffix: "%"
                                    )
                                }
                            }
                        }

                        // 4. Detailed Tax Apportionment Card
                        VStack(spacing: 10) {
                            CalculatorBreakdownRow(
                                label: "Original Taxable Value",
                                value: formatAmount(vm.result.taxableAmount),
                                isBold: false
                            )

                            Divider()

                            if vm.transactionType == .intraState {
                                CalculatorBreakdownRow(
                                    label: "CGST (Central GST)",
                                    value: formatAmount(vm.result.cgstAmount),
                                    subtitle: "\(String(format: "%.1f%%", vm.result.gstRate / 2.0)) tax component",
                                    accentColor: LeafTheme.expenseCoral,
                                    isBold: false
                                )

                                Divider()

                                CalculatorBreakdownRow(
                                    label: "SGST (State GST)",
                                    value: formatAmount(vm.result.sgstAmount),
                                    subtitle: "\(String(format: "%.1f%%", vm.result.gstRate / 2.0)) tax component",
                                    accentColor: LeafTheme.expenseCoral,
                                    isBold: false
                                )

                                Divider()
                            } else {
                                CalculatorBreakdownRow(
                                    label: "IGST (Integrated GST)",
                                    value: formatAmount(vm.result.igstAmount),
                                    subtitle: "\(String(format: "%.1f%%", vm.result.gstRate)) full interstate tax",
                                    accentColor: LeafTheme.expenseCoral,
                                    isBold: false
                                )

                                Divider()
                            }

                            CalculatorBreakdownRow(
                                label: "Total GST Amount",
                                value: formatAmount(vm.result.totalGst),
                                accentColor: LeafTheme.expenseCoral,
                                isBold: true
                            )

                            Divider()

                            CalculatorBreakdownRow(
                                label: "Final Amount Payable",
                                value: formatAmount(vm.result.finalAmount),
                                accentColor: LeafTheme.textPrimary(for: colorScheme),
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
                            title: "GST Rules & Apportionment",
                            assumptions: [
                                "Intra-State supply: total GST is split equally between Central GST (CGST, 50%) and State GST (SGST, 50%).",
                                "Inter-State supply: full tax liability is allocated to Integrated GST (IGST, 100%).",
                                "Exclusive mode adds GST to base taxable value; Inclusive mode reverse-extracts pre-tax base value and embedded tax.",
                                "CGST and SGST components strictly reconcile with Total GST down to the exact cent/paisa."
                            ],
                            disclaimer: "GST calculations are provided for commercial estimation purposes and do not substitute for statutory chartered tax accounting or formal tax filing advice."
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
        .navigationTitle("GST Calculator")
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
                self.viewModel = GstCalculatorViewModel(calculateGstUseCase: container.calculateGstUseCase)
            }
        }
    }
}

