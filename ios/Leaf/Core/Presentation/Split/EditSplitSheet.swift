import SwiftUI

/// Sheet allowing editing of a split expense's title, date, category, and payment method.
public struct EditSplitSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    public let split: SplitExpense
    public let currency: Currency
    public let onSave: (SplitExpense) async throws -> Void

    @State private var title: String
    @State private var selectedDate: Date
    @State private var selectedPaymentMethod: PaymentMethod
    @State private var isSubmitting: Bool = false
    @State private var errorMessage: String? = nil

    public init(
        split: SplitExpense,
        currency: Currency = .default,
        onSave: @escaping (SplitExpense) async throws -> Void
    ) {
        self.split = split
        self.currency = currency
        self.onSave = onSave
        self._title = State(initialValue: split.title)
        self._selectedDate = State(initialValue: Date(timeIntervalSince1970: Double(split.date) / 1000.0))
        self._selectedPaymentMethod = State(initialValue: split.paymentMethod)
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                LeafTheme.canvas(for: colorScheme).ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        if let error = errorMessage {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundStyle(LeafTheme.expenseCoral)
                                Text(error)
                                    .font(LeafTypography.captionRegular)
                                    .foregroundStyle(LeafTheme.expenseCoral)
                            }
                            .padding(.horizontal)
                        }

                        SquircleCard(cornerRadius: 20) {
                            VStack(spacing: 16) {
                                // Title Field
                                HStack {
                                    Image(systemName: "tag.fill")
                                        .foregroundStyle(LeafTheme.brandEmerald)
                                    TextField("Expense Title", text: $title)
                                        .font(LeafTypography.bodyMedium)
                                        .foregroundStyle(LeafTheme.textPrimary(for: colorScheme))
                                }

                                Divider().background(LeafTheme.cardBorder(for: colorScheme))

                                // Date Picker
                                DatePicker(
                                    "Date",
                                    selection: $selectedDate,
                                    displayedComponents: [.date]
                                )
                                .font(LeafTypography.bodyMedium)
                                .foregroundStyle(LeafTheme.textPrimary(for: colorScheme))

                                Divider().background(LeafTheme.cardBorder(for: colorScheme))

                                // Payment Method
                                HStack {
                                    Text("Payment Source")
                                        .font(LeafTypography.bodyMedium)
                                        .foregroundStyle(LeafTheme.textPrimary(for: colorScheme))
                                    Spacer()
                                    Picker("Payment Method", selection: $selectedPaymentMethod) {
                                        Text("Cash").tag(PaymentMethod.cash)
                                        Text("Account").tag(PaymentMethod.account)
                                    }
                                    .pickerStyle(.segmented)
                                    .frame(width: 160)
                                }
                            }
                            .padding(16)
                        }
                        .padding(.horizontal)

                        // Info pill
                        HStack(spacing: 6) {
                            Image(systemName: "info.circle")
                                .font(.system(size: 11))
                            Text("Participant shares and settlements remain preserved.")
                                .font(LeafTypography.captionRegular)
                        }
                        .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
                        .padding(.horizontal)
                    }
                    .padding(.top, 16)
                }
            }
            .navigationTitle("Edit Split")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task { await save() }
                    }
                    .foregroundStyle(LeafTheme.brandEmerald)
                    .fontWeight(.bold)
                    .disabled(isSubmitting)
                }
            }
        }
    }

    private func save() async {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            errorMessage = "Please enter an expense title."
            return
        }

        isSubmitting = true
        errorMessage = nil

        let updated = SplitExpense(
            id: split.id,
            title: trimmed,
            totalAmount: split.totalAmount,
            date: Int64(selectedDate.timeIntervalSince1970 * 1000),
            categoryId: split.categoryId,
            paidBy: split.paidBy,
            splitMethod: split.splitMethod,
            qrImagePath: split.qrImagePath,
            addToTransactions: split.addToTransactions,
            expenseTransactionId: split.expenseTransactionId,
            paymentMethod: selectedPaymentMethod,
            groupId: split.groupId,
            itemsJson: split.itemsJson,
            participants: split.participants,
            createdAt: split.createdAt,
            updatedAt: Int64(Date().timeIntervalSince1970 * 1000)
        )

        do {
            try await onSave(updated)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }

        isSubmitting = false
    }
}

