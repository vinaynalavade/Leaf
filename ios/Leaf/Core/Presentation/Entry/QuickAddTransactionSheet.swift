import SwiftUI

/// Fast modal sheet designed for logging an Expense or Income transaction in under 3 seconds.
/// Adheres to User Journey 1 from the master documentation.
public struct QuickAddTransactionSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    public let initialType: TransactionType
    public let currency: Currency
    public let categories: [Category]
    public let onSave: (Amount, TransactionType, Int64, PaymentMethod, String?, Int64) async throws -> Void

    @State private var selectedType: TransactionType
    @State private var amountInput: String = ""
    @State private var selectedCategoryId: Int64 = 1
    @State private var selectedPaymentMethod: PaymentMethod = .cash
    @State private var note: String = ""
    @State private var transactionDate: Date = Date()
    @State private var isSubmitting: Bool = false
    @State private var errorMessage: String? = nil

    public init(
        initialType: TransactionType = .expense,
        currency: Currency = .default,
        categories: [Category],
        onSave: @escaping (Amount, TransactionType, Int64, PaymentMethod, String?, Int64) async throws -> Void
    ) {
        self.initialType = initialType
        self.currency = currency
        self.categories = categories
        self.onSave = onSave
        self._selectedType = State(initialValue: initialType)
    }

    private var filteredCategories: [Category] {
        categories.filter { $0.type == selectedType }
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                LeafTheme.canvas(for: colorScheme).ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // Type Segmented Picker (Expense vs Income)
                        Picker("Transaction Type", selection: $selectedType) {
                            Text("Expense").tag(TransactionType.expense)
                            Text("Income").tag(TransactionType.income)
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal)
                        .onChange(of: selectedType) { _, newType in
                            // Auto-select first matching category
                            if let first = categories.first(where: { $0.type == newType }) {
                                selectedCategoryId = first.id
                            }
                            let prefs = UserPreferencesRepository().getUserPreferences()
                            selectedPaymentMethod = (newType == .income) ? prefs.defaultIncomeSource : prefs.defaultTransactionSource
                        }

                        // Massive Numeric Input Field
                        SquircleCard(cornerRadius: 22) {
                            VStack(spacing: 8) {
                                Text("AMOUNT")
                                    .font(LeafTypography.captionBold)
                                    .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))

                                HStack(alignment: .firstTextBaseline, spacing: 4) {
                                    Text(currency.symbol)
                                        .font(.system(size: 32, weight: .bold, design: .rounded))
                                        .foregroundStyle(selectedType == .income ? LeafTheme.brandEmerald : LeafTheme.expenseCoral)

                                    TextField("0.00", text: $amountInput)
                                        .font(.system(size: 40, weight: .bold, design: .rounded).monospacedDigit())
                                        .keyboardType(.decimalPad)
                                        .multilineTextAlignment(.leading)
                                        .foregroundStyle(LeafTheme.textPrimary(for: colorScheme))
                                }
                                .padding(.horizontal, 16)
                            }
                            .padding(.vertical, 20)
                            .frame(maxWidth: .infinity)
                        }
                        .padding(.horizontal)

                        // Category Selector Chips
                        VStack(alignment: .leading, spacing: 10) {
                            Text("CATEGORY")
                                .font(LeafTypography.captionBold)
                                .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
                                .padding(.horizontal)

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 10) {
                                    ForEach(filteredCategories) { cat in
                                        let isSelected = cat.id == selectedCategoryId
                                        Button(action: { selectedCategoryId = cat.id }) {
                                            HStack(spacing: 6) {
                                                CategoryIconBadge(
                                                    iconName: cat.iconName,
                                                    colorHex: cat.colorHex,
                                                    size: 26,
                                                    iconScale: 0.55
                                                )

                                                Text(cat.name)
                                                    .font(LeafTypography.captionBold)
                                                    .foregroundStyle(isSelected ? .white : LeafTheme.textPrimary(for: colorScheme))
                                            }
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 8)
                                            .background(
                                                Capsule()
                                                    .fill(isSelected ? LeafTheme.accent(for: colorScheme) : (colorScheme == .dark ? LeafTheme.cardElevatedDark : LeafTheme.cardElevatedLight))
                                            )
                                            .overlay(
                                                Capsule()
                                                    .stroke(isSelected ? Color.clear : LeafTheme.cardBorder(for: colorScheme), lineWidth: 0.75)
                                            )
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }

                        // Payment Method & Note Fields
                        SquircleCard(cornerRadius: 18) {
                            VStack(spacing: 14) {
                                // Payment Method Picker
                                HStack {
                                    Text("Payment Method")
                                        .font(LeafTypography.body)
                                        .foregroundStyle(LeafTheme.textPrimary(for: colorScheme))

                                    Spacer()

                                    Picker("Payment Method", selection: $selectedPaymentMethod) {
                                        ForEach(PaymentMethod.allCases, id: \.self) { method in
                                            Text(method.displayName).tag(method)
                                        }
                                    }
                                    .pickerStyle(.segmented)
                                    .frame(width: 170)
                                }

                                Divider()

                                // Note input
                                HStack {
                                    Image(systemName: "pencil")
                                        .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))

                                    TextField("Add a note (optional)", text: $note)
                                        .font(LeafTypography.body)
                                        .foregroundStyle(LeafTheme.textPrimary(for: colorScheme))
                                }

                                Divider()

                                // Date Picker
                                HStack {
                                    Image(systemName: "calendar")
                                        .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))

                                    DatePicker(
                                        "Date",
                                        selection: $transactionDate,
                                        displayedComponents: [.date]
                                    )
                                    .font(LeafTypography.body)
                                }
                            }
                            .padding(16)
                        }
                        .padding(.horizontal)

                        if let error = errorMessage {
                            Text(error)
                                .font(LeafTypography.caption)
                                .foregroundStyle(LeafTheme.crimsonRed)
                                .padding(.horizontal)
                        }

                        // Save Button
                        Button(action: saveTransaction) {
                            HStack {
                                if isSubmitting {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 16, weight: .bold))

                                    Text("Save Transaction")
                                        .font(LeafTypography.bodyBold)
                                }
                            }
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill(LeafTheme.accent(for: colorScheme))
                            )
                        }
                        .disabled(isSubmitting)
                        .padding(.horizontal)
                        .padding(.bottom, 24)
                    }
                    .padding(.top, 12)
                }
            }
            .navigationTitle(selectedType == .income ? "Add Income" : "Add Expense")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(LeafTheme.accent(for: colorScheme))
                }
            }
            .onAppear {
                let prefs = UserPreferencesRepository().getUserPreferences()
                self.selectedPaymentMethod = (selectedType == .income) ? prefs.defaultIncomeSource : prefs.defaultTransactionSource
                if let match = categories.first(where: { $0.type == selectedType }) {
                    selectedCategoryId = match.id
                }
            }
        }
    }

    private func saveTransaction() {
        guard let parsedAmount = Amount.fromStringOrNull(amountInput, currency: currency),
              parsedAmount.subunits > 0 else {
            errorMessage = "Please enter a valid amount greater than zero."
            return
        }

        isSubmitting = true
        errorMessage = nil

        Task {
            do {
                let epoch = Int64(transactionDate.timeIntervalSince1970 * 1000)
                try await onSave(
                    parsedAmount,
                    selectedType,
                    selectedCategoryId,
                    selectedPaymentMethod,
                    note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : note,
                    epoch
                )
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
                isSubmitting = false
            }
        }
    }
}

