import SwiftUI

/// Sheet allowing creation or editing of an overall or category-specific budget across
/// Monthly, Weekly, Yearly, or Custom date periods with recurrence support.
public struct CreateEditBudgetSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    public let existingBudget: Budget?
    public let categories: [Category]
    public let defaultYear: Int
    public let defaultMonth: Int
    public let currency: Currency
    public let onSave: (Int64, Int64?, Amount, Int, Int, BudgetPeriodType, Int64?, Int64?, Bool) async throws -> Void

    public enum BudgetScope: String, CaseIterable, Identifiable {
        case overall = "Overall Budget"
        case category = "Category Budget"

        public var id: String { rawValue }
    }

    @State private var budgetScope: BudgetScope = .overall
    @State private var selectedCategoryId: Int64? = nil
    @State private var amountInput: String = ""
    @State private var selectedPeriodType: BudgetPeriodType = .monthly
    @State private var selectedMonth: Int
    @State private var selectedYear: Int
    @State private var startDate: Date = Date()
    @State private var endDate: Date = Calendar.current.date(byAdding: .day, value: 30, to: Date()) ?? Date()
    @State private var isRecurring: Bool = true
    @State private var isSubmitting: Bool = false
    @State private var errorMessage: String? = nil

    public init(
        existingBudget: Budget? = nil,
        categories: [Category],
        defaultYear: Int,
        defaultMonth: Int,
        currency: Currency = .default,
        onSave: @escaping (Int64, Int64?, Amount, Int, Int, BudgetPeriodType, Int64?, Int64?, Bool) async throws -> Void
    ) {
        self.existingBudget = existingBudget
        self.categories = categories.filter { $0.type == .expense }
        self.defaultYear = defaultYear
        self.defaultMonth = defaultMonth
        self.currency = currency
        self.onSave = onSave

        if let b = existingBudget {
            self._budgetScope = State(initialValue: b.isOverallBudget ? .overall : .category)
            self._selectedCategoryId = State(initialValue: b.categoryId)
            self._amountInput = State(initialValue: b.amount.toInputString())
            self._selectedPeriodType = State(initialValue: b.periodType)
            self._selectedMonth = State(initialValue: b.month)
            self._selectedYear = State(initialValue: b.year)
            self._isRecurring = State(initialValue: b.isRecurring)
            if let s = b.startDate {
                self._startDate = State(initialValue: Date(timeIntervalSince1970: TimeInterval(s) / 1000))
            }
            if let e = b.endDate {
                self._endDate = State(initialValue: Date(timeIntervalSince1970: TimeInterval(e) / 1000))
            }
        } else {
            self._budgetScope = State(initialValue: .overall)
            self._selectedCategoryId = State(initialValue: categories.first?.id)
            self._amountInput = State(initialValue: "")
            self._selectedPeriodType = State(initialValue: .monthly)
            self._selectedMonth = State(initialValue: defaultMonth)
            self._selectedYear = State(initialValue: defaultYear)
            self._isRecurring = State(initialValue: false)
        }
    }

    private var parsedAmount: Amount? {
        Amount.fromStringOrNull(amountInput, currency: currency)
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                LeafTheme.canvas(for: colorScheme).ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // Scope Picker
                        scopePickerCard

                        // Period Type & Dates Configuration
                        periodConfigCard

                        // Category Selector (if category scope)
                        if budgetScope == .category {
                            categorySelectorCard
                        }

                        // Amount Input Card
                        amountInputCard

                        // Recurrence Toggle
                        recurrenceCard

                        if let error = errorMessage {
                            Text(error)
                                .font(LeafTypography.captionBold)
                                .foregroundStyle(LeafTheme.coralRose)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal)
                        }
                    }
                    .padding(.vertical, 16)
                }
            }
            .navigationTitle(existingBudget == nil ? "Set New Budget" : "Edit Budget")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(action: saveBudget) {
                        if isSubmitting {
                            ProgressView().tint(LeafTheme.brandEmerald)
                        } else {
                            Text(existingBudget == nil ? "Create" : "Save")
                                .font(LeafTypography.bodyBold)
                                .foregroundStyle(LeafTheme.brandEmerald)
                        }
                    }
                    .disabled(parsedAmount == nil || (parsedAmount?.subunits ?? 0) <= 0 || isSubmitting)
                }
            }
        }
    }

    // MARK: - Subviews

    private var scopePickerCard: some View {
        SquircleCard(cornerRadius: 18) {
            VStack(alignment: .leading, spacing: 10) {
                Text("BUDGET SCOPE")
                    .font(LeafTypography.captionBold)
                    .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))

                Picker("Scope", selection: $budgetScope) {
                    ForEach(BudgetScope.allCases) { scope in
                        Text(scope.rawValue).tag(scope)
                    }
                }
                .pickerStyle(.segmented)
            }
            .padding(16)
        }
        .padding(.horizontal)
    }

    private var periodConfigCard: some View {
        SquircleCard(cornerRadius: 18) {
            VStack(alignment: .leading, spacing: 14) {
                Text("BUDGET PERIOD")
                    .font(LeafTypography.captionBold)
                    .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))

                Picker("Period Type", selection: $selectedPeriodType) {
                    ForEach(BudgetPeriodType.allCases, id: \.self) { type in
                        Label(type.displayName, systemImage: type.iconName).tag(type)
                    }
                }
                .pickerStyle(.segmented)

                Divider().background(LeafTheme.cardBorder(for: colorScheme))

                switch selectedPeriodType {
                case .monthly:
                    HStack(spacing: 12) {
                        Picker("Month", selection: $selectedMonth) {
                            ForEach(1...12, id: \.self) { m in
                                Text(Calendar.current.monthSymbols[m - 1]).tag(m)
                            }
                        }
                        .pickerStyle(.menu)
                        .tint(LeafTheme.brandEmerald)

                        Spacer()

                        Picker("Year", selection: $selectedYear) {
                            ForEach(2020...2030, id: \.self) { y in
                                Text(String(y)).tag(y)
                            }
                        }
                        .pickerStyle(.menu)
                        .tint(LeafTheme.brandEmerald)
                    }

                case .weekly:
                    VStack(alignment: .leading, spacing: 6) {
                        DatePicker("Starting Week", selection: $startDate, displayedComponents: .date)
                            .tint(LeafTheme.brandEmerald)
                        Text("Calculates spend across the 7-day week starting on this date.")
                            .font(LeafTypography.captionRegular)
                            .foregroundStyle(LeafTheme.textTertiary(for: colorScheme))
                    }

                case .yearly:
                    HStack {
                        Text("Year")
                            .font(LeafTypography.bodyMedium)
                            .foregroundStyle(LeafTheme.textPrimary(for: colorScheme))
                        Spacer()
                        Picker("Year", selection: $selectedYear) {
                            ForEach(2020...2030, id: \.self) { y in
                                Text(String(y)).tag(y)
                            }
                        }
                        .pickerStyle(.menu)
                        .tint(LeafTheme.brandEmerald)
                    }

                case .custom:
                    VStack(spacing: 10) {
                        DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                            .tint(LeafTheme.brandEmerald)
                        DatePicker("End Date", selection: $endDate, in: startDate..., displayedComponents: .date)
                            .tint(LeafTheme.brandEmerald)
                    }
                }
            }
            .padding(16)
        }
        .padding(.horizontal)
    }

    private var categorySelectorCard: some View {
        SquircleCard(cornerRadius: 18) {
            VStack(alignment: .leading, spacing: 12) {
                Text("SELECT CATEGORY")
                    .font(LeafTypography.captionBold)
                    .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(categories) { cat in
                            let isSelected = selectedCategoryId == cat.id
                            Button(action: { selectedCategoryId = cat.id }) {
                                HStack(spacing: 6) {
                                    CategoryIconBadge(
                                        iconName: cat.iconName,
                                        colorHex: cat.colorHex,
                                        size: 26
                                    )
                                    Text(cat.name)
                                        .font(LeafTypography.bodySmall)
                                        .foregroundStyle(isSelected ? .white : LeafTheme.textPrimary(for: colorScheme))
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(isSelected ? LeafTheme.brandEmerald : LeafTheme.subtleCard(for: colorScheme))
                                .clipShape(Capsule())
                                .overlay(
                                    Capsule()
                                        .stroke(isSelected ? Color.clear : LeafTheme.cardBorder(for: colorScheme), lineWidth: 1)
                                )
                            }
                        }
                    }
                }
            }
            .padding(16)
        }
        .padding(.horizontal)
    }

    private var amountInputCard: some View {
        SquircleCard(cornerRadius: 18) {
            VStack(alignment: .leading, spacing: 10) {
                Text("BUDGET LIMIT")
                    .font(LeafTypography.captionBold)
                    .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))

                HStack {
                    Text(currency.symbol)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(LeafTheme.brandEmerald)

                    TextField("0.00", text: $amountInput)
                        .keyboardType(.decimalPad)
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(LeafTheme.textPrimary(for: colorScheme))
                }

                // Quick increments
                HStack(spacing: 8) {
                    ForEach([1000, 5000, 10000, 25000], id: \.self) { addVal in
                        Button(action: {
                            let curr = parsedAmount?.subunits ?? 0
                            let next = Amount(subunits: curr + Int64(addVal * 100))
                            amountInput = next.toInputString()
                        }) {
                            Text("+\(addVal)")
                                .font(LeafTypography.captionBold)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(LeafTheme.subtleCard(for: colorScheme))
                                .foregroundStyle(LeafTheme.textPrimary(for: colorScheme))
                                .clipShape(Capsule())
                        }
                    }
                }
            }
            .padding(16)
        }
        .padding(.horizontal)
    }

    private var recurrenceCard: some View {
        SquircleCard(cornerRadius: 18) {
            Toggle(isOn: $isRecurring) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Recurring Budget")
                        .font(LeafTypography.bodyBold)
                        .foregroundStyle(LeafTheme.textPrimary(for: colorScheme))
                    Text("Renews automatically at the start of each period")
                        .font(LeafTypography.captionRegular)
                        .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
                }
            }
            .tint(LeafTheme.brandEmerald)
            .padding(16)
        }
        .padding(.horizontal)
    }

    private func saveBudget() {
        guard let amount = parsedAmount, amount.subunits > 0 else {
            errorMessage = "Please enter a valid amount."
            return
        }

        isSubmitting = true
        errorMessage = nil

        let catId: Int64? = (budgetScope == .category) ? selectedCategoryId : nil
        let sEpoch: Int64?
        let eEpoch: Int64?

        switch selectedPeriodType {
        case .monthly:
            sEpoch = nil
            eEpoch = nil
        case .weekly:
            sEpoch = Int64(startDate.timeIntervalSince1970 * 1000)
            let weekEnd = Calendar.current.date(byAdding: DateComponents(day: 6, hour: 23, minute: 59, second: 59), to: startDate) ?? startDate
            eEpoch = Int64(weekEnd.timeIntervalSince1970 * 1000)
        case .yearly:
            sEpoch = nil
            eEpoch = nil
        case .custom:
            sEpoch = Int64(startDate.timeIntervalSince1970 * 1000)
            let endOfDay = Calendar.current.date(bySettingHour: 23, minute: 59, second: 59, of: endDate) ?? endDate
            eEpoch = Int64(endOfDay.timeIntervalSince1970 * 1000)
        }

        Task {
            do {
                try await onSave(
                    existingBudget?.id ?? 0,
                    catId,
                    amount,
                    selectedMonth,
                    selectedYear,
                    selectedPeriodType,
                    sEpoch,
                    eEpoch,
                    isRecurring
                )
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
                isSubmitting = false
            }
        }
    }
}
