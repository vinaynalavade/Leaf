import SwiftUI

/// Dedicated bottom sheet allowing multi-criteria filtering across date ranges, categories, payment methods, and amount boundaries.
public struct ExpensesFilterSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    public let categories: [Category]
    public let initialFilter: TransactionFilter
    public let currency: Currency
    public let onApply: (TransactionFilter) -> Void

    @State private var workingFilter: TransactionFilter
    @State private var minAmountInput: String = ""
    @State private var maxAmountInput: String = ""

    public init(
        categories: [Category],
        initialFilter: TransactionFilter,
        currency: Currency = .default,
        onApply: @escaping (TransactionFilter) -> Void
    ) {
        self.categories = categories.filter { $0.type == .expense }
        self.initialFilter = initialFilter
        self.currency = currency
        self.onApply = onApply
        self._workingFilter = State(initialValue: initialFilter)

        if let min = initialFilter.minAmountSubunits {
            self._minAmountInput = State(initialValue: Amount(subunits: min).toInputString())
        }
        if let max = initialFilter.maxAmountSubunits {
            self._maxAmountInput = State(initialValue: Amount(subunits: max).toInputString())
        }
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                LeafTheme.canvas(for: colorScheme).ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // 1. Date Range Section
                        filterSection(title: "DATE RANGE") {
                            VStack(spacing: 12) {
                                Picker("Date Range", selection: $workingFilter.dateRange) {
                                    ForEach(TransactionFilter.DateRangeOption.allCases) { opt in
                                        Text(opt.rawValue).tag(opt)
                                    }
                                }
                                .pickerStyle(.segmented)

                                if workingFilter.dateRange == .custom {
                                    VStack(spacing: 8) {
                                        DatePicker(
                                            "Start Date",
                                            selection: Binding(
                                                get: { workingFilter.customStartDate ?? Date() },
                                                set: { workingFilter.customStartDate = $0 }
                                            ),
                                            displayedComponents: [.date]
                                        )

                                        DatePicker(
                                            "End Date",
                                            selection: Binding(
                                                get: { workingFilter.customEndDate ?? Date() },
                                                set: { workingFilter.customEndDate = $0 }
                                            ),
                                            displayedComponents: [.date]
                                        )
                                    }
                                    .padding(.top, 4)
                                }
                            }
                        }

                        // 2. Category Selection (Multi-select)
                        filterSection(title: "CATEGORIES") {
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: 8)], spacing: 8) {
                                ForEach(categories) { cat in
                                    let isSelected = workingFilter.selectedCategoryIds.contains(cat.id)
                                    Button(action: {
                                        if isSelected {
                                            workingFilter.selectedCategoryIds.remove(cat.id)
                                        } else {
                                            workingFilter.selectedCategoryIds.insert(cat.id)
                                        }
                                    }) {
                                        HStack(spacing: 6) {
                                            CategoryIconBadge(
                                                iconName: cat.iconName,
                                                colorHex: cat.colorHex,
                                                size: 22
                                            )
                                            Text(cat.name)
                                                .font(.system(size: 12, weight: .medium, design: .rounded))
                                                .foregroundStyle(isSelected ? LeafTheme.brandEmerald : LeafTheme.textPrimary(for: colorScheme))
                                                .lineLimit(1)
                                        }
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 8)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .background(
                                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                                .fill(isSelected ? LeafTheme.brandEmerald.opacity(0.12) : (colorScheme == .dark ? LeafTheme.cardDark : LeafTheme.cardLight))
                                        )
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                                .stroke(isSelected ? LeafTheme.brandEmerald : LeafTheme.cardBorder(for: colorScheme), lineWidth: 1)
                                        )
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                        }

                        // 3. Payment Method Section
                        filterSection(title: "PAYMENT METHOD") {
                            HStack(spacing: 8) {
                                paymentMethodButton(title: "All", method: nil)
                                paymentMethodButton(title: "Cash", method: .cash)
                                paymentMethodButton(title: "Account", method: .account)
                            }
                        }

                        // 4. Amount Range Section
                        filterSection(title: "AMOUNT RANGE (\(currency.symbol))") {
                            HStack(spacing: 12) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Min")
                                        .font(LeafTypography.captionRegular)
                                        .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
                                    TextField("0.00", text: $minAmountInput)
                                        .keyboardType(.decimalPad)
                                        .padding(10)
                                        .background(
                                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                                .fill(colorScheme == .dark ? LeafTheme.cardDark : LeafTheme.cardLight)
                                        )
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                                .stroke(LeafTheme.cardBorder(for: colorScheme), lineWidth: 0.75)
                                        )
                                }

                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Max")
                                        .font(LeafTypography.captionRegular)
                                        .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
                                    TextField("Any", text: $maxAmountInput)
                                        .keyboardType(.decimalPad)
                                        .padding(10)
                                        .background(
                                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                                .fill(colorScheme == .dark ? LeafTheme.cardDark : LeafTheme.cardLight)
                                        )
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                                .stroke(LeafTheme.cardBorder(for: colorScheme), lineWidth: 0.75)
                                        )
                                }
                            }
                        }

                        // Apply Button CTA
                        Button(action: applyAndDismiss) {
                            Text("Apply Filters")
                                .font(LeafTypography.headline)
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 52)
                                .background(LeafTheme.brandEmerald)
                                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        }
                        .padding(.top, 12)
                    }
                    .padding()
                }
            }
            .navigationTitle("Filter Expenses")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Reset") {
                        workingFilter.clear()
                        minAmountInput = ""
                        maxAmountInput = ""
                    }
                    .foregroundStyle(LeafTheme.expenseCoral)
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        applyAndDismiss()
                    }
                    .foregroundStyle(LeafTheme.brandEmerald)
                    .fontWeight(.bold)
                }
            }
        }
    }

    @ViewBuilder
    private func filterSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(LeafTypography.captionBold)
                .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
                .tracking(0.5)

            SquircleCard(cornerRadius: 18) {
                content()
                    .padding(14)
            }
        }
    }

    @ViewBuilder
    private func paymentMethodButton(title: String, method: PaymentMethod?) -> some View {
        let isSelected = workingFilter.paymentMethod == method
        Button(action: { workingFilter.paymentMethod = method }) {
            Text(title)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(isSelected ? .white : LeafTheme.textPrimary(for: colorScheme))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(isSelected ? LeafTheme.brandEmerald : (colorScheme == .dark ? Color.white.opacity(0.04) : Color.black.opacity(0.04)))
                )
        }
    }

    private func applyAndDismiss() {
        if let minAmt = Amount.fromStringOrNull(minAmountInput, currency: currency) {
            workingFilter.minAmountSubunits = minAmt.subunits
        } else {
            workingFilter.minAmountSubunits = nil
        }

        if let maxAmt = Amount.fromStringOrNull(maxAmountInput, currency: currency) {
            workingFilter.maxAmountSubunits = maxAmt.subunits
        } else {
            workingFilter.maxAmountSubunits = nil
        }

        onApply(workingFilter)
        dismiss()
    }
}

