import SwiftUI

/// Native retail discount calculator screen supporting forward, successive, and reverse percentage calculations.
public struct DiscountCalculatorView: View {
    @Environment(AppContainer.self) private var container
    @Environment(\.colorScheme) private var colorScheme
    @State private var viewModel: DiscountCalculatorViewModel?

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
                        // Mode Switcher
                        Picker("Calculation Mode", selection: Binding(
                            get: { vm.mode },
                            set: { vm.mode = $0; vm.calculate() }
                        )) {
                            ForEach(DiscountCalculationMode.allCases) { mode in
                                Text(mode.displayName).tag(mode)
                            }
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal, 4)

                        // 1. Result Hero Card
                        if vm.mode == .forward {
                            CalculatorResultHeroCard(
                                title: "Final Selling Price",
                                formattedAmount: formatAmount(vm.result.finalPrice),
                                subtitle: "Effective discount of \(String(format: "%.1f%%", vm.result.effectiveDiscountPercentage)) applied",
                                accentGradient: LinearGradient(
                                    colors: [Color(hex: "#B45309"), Color(hex: "#D97706"), Color(hex: "#F59E0B")],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                               ),
                                secondaryPills: [
                                    ("You Save", formatAmount(vm.result.discountAmount)),
                                    ("Original Price", formatAmount(vm.result.originalPrice))
                                ]
                            )
                        } else {
                            CalculatorResultHeroCard(
                                title: "Discount Applied",
                                formattedAmount: String(format: "%.1f%% OFF", vm.result.discountPercentage),
                                subtitle: "You save \(formatAmount(vm.result.discountAmount)) off the original price",
                                accentGradient: LinearGradient(
                                    colors: [Color(hex: "#B45309"), Color(hex: "#D97706"), Color(hex: "#F59E0B")],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                secondaryPills: [
                                    ("Total Savings", formatAmount(vm.result.discountAmount)),
                                    ("Final Price", formatAmount(vm.result.finalPrice))
                                ]
                            )
                        }

                        // 2. Inputs Section
                        if vm.mode == .forward {
                            forwardInputsSection(vm)
                        } else {
                            reverseInputsSection(vm)
                        }

                        // 3. Breakdown Summary Card
                        VStack(spacing: 10) {
                            CalculatorBreakdownRow(
                                label: "Original Listing Price",
                                value: formatAmount(vm.result.originalPrice),
                                isBold: false
                            )

                            Divider()

                            if let succ = vm.result.successiveDiscountPercentage, succ > 0 {
                                CalculatorBreakdownRow(
                                    label: "First Discount",
                                    value: String(format: "%.1f%%", vm.result.discountPercentage),
                                    isBold: false
                                )

                                Divider()

                                CalculatorBreakdownRow(
                                    label: "Additional Successive Discount",
                                    value: String(format: "%.1f%%", succ),
                                    isBold: false
                                )

                                Divider()

                                CalculatorBreakdownRow(
                                    label: "Effective Combined Discount",
                                    value: String(format: "%.1f%%", vm.result.effectiveDiscountPercentage),
                                    accentColor: LeafTheme.warningGold,
                                    isBold: true
                                )

                                Divider()
                            } else {
                                CalculatorBreakdownRow(
                                    label: "Discount Percentage",
                                    value: String(format: "%.1f%%", vm.result.discountPercentage),
                                    accentColor: LeafTheme.warningGold,
                                    isBold: false
                                )

                                Divider()
                            }

                            CalculatorBreakdownRow(
                                label: "Total Amount Saved",
                                value: formatAmount(vm.result.discountAmount),
                                accentColor: LeafTheme.brandEmerald,
                                isBold: false
                            )

                            Divider()

                            CalculatorBreakdownRow(
                                label: "Final Price Payable",
                                value: formatAmount(vm.result.finalPrice),
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

                        // 4. Assumption & Methodology Disclosure Card
                        CalculatorAssumptionDisclosureCard(
                            title: "Discount Calculation Assumptions",
                            assumptions: [
                                "Standard forward discount: computes monetary savings and final price directly from original listing price.",
                                "Successive discounts: applied sequentially — the second discount applies to the discounted intermediate price, not the original price.",
                                "Reverse mode: derives implied percentage savings from original price and final negotiated price.",
                                "Final selling price plus total savings strictly equals original listing price."
                            ]
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
        .navigationTitle("Discount Calculator")
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
                self.viewModel = DiscountCalculatorViewModel(calculateDiscountUseCase: container.calculateDiscountUseCase)
            }
        }
    }

    // MARK: - Forward Inputs

    @ViewBuilder
    private func forwardInputsSection(_ vm: DiscountCalculatorViewModel) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("PRICE & DISCOUNT")
                .font(LeafTypography.captionBold)
                .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
                .padding(.horizontal, 4)

            CalculatorInputField(
                label: "Original Price",
                text: Binding(
                    get: { vm.originalPriceString },
                    set: { vm.originalPriceString = $0; vm.calculate() }
                ),
                prefix: currentCurrency.symbol
            )

            VStack(alignment: .leading, spacing: 8) {
                CalculatorInputField(
                    label: "Discount",
                    text: Binding(
                        get: { vm.discountPercentString },
                        set: { vm.discountPercentString = $0; vm.calculate() }
                    ),
                    suffix: "%"
                )

                // Quick percentage chips
                HStack(spacing: 8) {
                    ForEach([10.0, 15.0, 20.0, 25.0, 30.0, 50.0], id: \.self) { pct in
                        Button {
                            vm.setDiscountPreset(pct)
                        } label: {
                            Text(String(format: "%.0f%%", pct))
                                .font(LeafTypography.captionBold)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(
                                    vm.discountPercentString == String(format: "%.0f", pct)
                                        ? LeafTheme.warningGold.opacity(0.15)
                                        : LeafTheme.card(for: colorScheme)
                                )
                                .foregroundStyle(
                                    vm.discountPercentString == String(format: "%.0f", pct)
                                        ? LeafTheme.warningGold
                                        : LeafTheme.textPrimary(for: colorScheme)
                                )
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(
                                            vm.discountPercentString == String(format: "%.0f", pct)
                                                ? LeafTheme.warningGold
                                                : LeafTheme.border(for: colorScheme),
                                            lineWidth: 1
                                        )
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            // Successive Discount Section
            VStack(alignment: .leading, spacing: 10) {
                Toggle(isOn: Binding(
                    get: { vm.isSuccessiveDiscountEnabled },
                    set: { vm.isSuccessiveDiscountEnabled = $0; vm.calculate() }
                )) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Successive Discount")
                            .font(LeafTypography.bodyBold)
                            .foregroundStyle(LeafTheme.textPrimary(for: colorScheme))
                        Text("e.g. Additional 10% off after primary 20%")
                            .font(LeafTypography.caption)
                            .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
                    }
                }
                .tint(LeafTheme.warningGold)

                if vm.isSuccessiveDiscountEnabled {
                    CalculatorInputField(
                        label: "Additional Discount Rate",
                        text: Binding(
                            get: { vm.successiveDiscountPercentString },
                            set: { vm.successiveDiscountPercentString = $0; vm.calculate() }
                        ),
                        suffix: "%",
                        helperText: "Calculates combined effective discount formula: 1 - (1 - d1)(1 - d2)."
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
    }

    // MARK: - Reverse Inputs

    @ViewBuilder
    private func reverseInputsSection(_ vm: DiscountCalculatorViewModel) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("REVERSE PRICE COMPARISON")
                .font(LeafTypography.captionBold)
                .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
                .padding(.horizontal, 4)

            CalculatorInputField(
                label: "Original Price (MRP)",
                text: Binding(
                    get: { vm.reverseOriginalPriceString },
                    set: { vm.reverseOriginalPriceString = $0; vm.calculate() }
                ),
                prefix: currentCurrency.symbol
            )

            CalculatorInputField(
                label: "Final Selling Price",
                text: Binding(
                    get: { vm.reverseFinalPriceString },
                    set: { vm.reverseFinalPriceString = $0; vm.calculate() }
                ),
                prefix: currentCurrency.symbol,
                helperText: "Enter the discounted price paid to determine the exact savings percentage."
            )
        }
    }
}

