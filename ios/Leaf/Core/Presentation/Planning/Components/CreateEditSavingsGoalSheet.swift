import SwiftUI

/// Sheet allowing creation or editing of a target-driven savings goal with icon and color customization.
public struct CreateEditSavingsGoalSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    public let existingGoal: SavingsGoal?
    public let currency: Currency
    public let onSave: (Int64, String, Amount, Amount?, Int64?, String?, String, String) async throws -> Void

    @State private var name: String = ""
    @State private var targetAmountInput: String = ""
    @State private var initialAmountInput: String = ""
    @State private var hasTargetDate: Bool = false
    @State private var targetDate: Date = Calendar.current.date(byAdding: .month, value: 6, to: Date()) ?? Date()
    @State private var note: String = ""
    @State private var selectedIcon: String = "savings"
    @State private var selectedColorHex: String = "#10B981"
    @State private var isSubmitting: Bool = false
    @State private var errorMessage: String? = nil

    private let availableIcons: [(id: String, systemName: String, label: String)] = [
        ("savings", "banknote.fill", "Savings"),
        ("laptop", "laptopcomputer", "Gadget"),
        ("car", "car.fill", "Vehicle"),
        ("home", "house.fill", "House"),
        ("flight", "airplane", "Travel"),
        ("gift", "gift.fill", "Gift"),
        ("heart", "heart.fill", "Health"),
        ("education", "book.fill", "Study"),
        ("ring", "sparkles", "Milestone")
    ]

    private let availableColors: [String] = [
        "#10B981", // Emerald
        "#3B82F6", // Blue
        "#8B5CF6", // Purple
        "#F59E0B", // Amber
        "#EC4899", // Pink
        "#06B6D4", // Cyan
        "#EF4444"  // Coral
    ]

    public init(
        existingGoal: SavingsGoal? = nil,
        currency: Currency = .default,
        onSave: @escaping (Int64, String, Amount, Amount?, Int64?, String?, String, String) async throws -> Void
    ) {
        self.existingGoal = existingGoal
        self.currency = currency
        self.onSave = onSave

        if let g = existingGoal {
            self._name = State(initialValue: g.name)
            self._targetAmountInput = State(initialValue: g.targetAmount.toInputString())
            self._note = State(initialValue: g.note ?? "")
            self._selectedIcon = State(initialValue: g.iconName)
            self._selectedColorHex = State(initialValue: g.colorHex)
            if let tDate = g.targetDate {
                self._hasTargetDate = State(initialValue: true)
                self._targetDate = State(initialValue: Date(timeIntervalSince1970: Double(tDate) / 1000.0))
            } else {
                self._hasTargetDate = State(initialValue: false)
            }
        }
    }

    private var parsedTargetAmount: Amount? {
        Amount.fromStringOrNull(targetAmountInput, currency: currency)
    }

    private var parsedInitialAmount: Amount? {
        Amount.fromStringOrNull(initialAmountInput, currency: currency)
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

                        // 1. Goal Name & Icon Swatch
                        SquircleCard(cornerRadius: 20) {
                            VStack(spacing: 16) {
                                HStack(spacing: 12) {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                                            .fill((Color(hex: selectedColorHex) ?? LeafTheme.brandEmerald).opacity(0.16))
                                            .frame(width: 44, height: 44)

                                        Image(systemName: systemIcon(for: selectedIcon))
                                            .font(.system(size: 20, weight: .bold))
                                            .foregroundStyle(Color(hex: selectedColorHex) ?? LeafTheme.brandEmerald)
                                    }

                                    TextField("Goal Name (e.g. MacBook Pro)", text: $name)
                                        .font(LeafTypography.titleSmall)
                                        .foregroundStyle(LeafTheme.textPrimary(for: colorScheme))
                                }

                                Divider().background(LeafTheme.cardBorder(for: colorScheme))

                                // Icon Picker Row
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("ICON")
                                        .font(LeafTypography.captionBold)
                                        .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
                                        .tracking(0.5)

                                    ScrollView(.horizontal, showsIndicators: false) {
                                        HStack(spacing: 12) {
                                            ForEach(availableIcons, id: \.id) { item in
                                                let isSelected = selectedIcon == item.id
                                                Button(action: {
                                                    selectedIcon = item.id
                                                }) {
                                                    ZStack {
                                                        Circle()
                                                            .fill(isSelected ? (Color(hex: selectedColorHex) ?? LeafTheme.brandEmerald) : (colorScheme == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.05)))
                                                            .frame(width: 38, height: 38)

                                                        Image(systemName: item.systemName)
                                                            .font(.system(size: 15, weight: .semibold))
                                                            .foregroundStyle(isSelected ? .white : LeafTheme.textPrimary(for: colorScheme))
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }

                                Divider().background(LeafTheme.cardBorder(for: colorScheme))

                                // Color Picker Row
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("COLOR")
                                        .font(LeafTypography.captionBold)
                                        .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
                                        .tracking(0.5)

                                    HStack(spacing: 12) {
                                        ForEach(availableColors, id: \.self) { hex in
                                            let isSelected = selectedColorHex == hex
                                            Button(action: {
                                                selectedColorHex = hex
                                            }) {
                                                ZStack {
                                                    Circle()
                                                        .fill(Color(hex: hex) ?? LeafTheme.brandEmerald)
                                                        .frame(width: 32, height: 32)

                                                    if isSelected {
                                                        Circle()
                                                            .strokeBorder(.white, lineWidth: 2.5)
                                                            .frame(width: 32, height: 32)
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                            .padding(16)
                        }
                        .padding(.horizontal)

                        // 2. Target Amount Card
                        SquircleCard(cornerRadius: 22) {
                            VStack(spacing: 8) {
                                Text("TARGET SAVINGS AMOUNT")
                                    .font(LeafTypography.captionBold)
                                    .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
                                    .tracking(0.5)

                                HStack(alignment: .firstTextBaseline, spacing: 4) {
                                    Text(currency.symbol)
                                        .font(.system(size: 32, weight: .bold, design: .rounded))
                                        .foregroundStyle(Color(hex: selectedColorHex) ?? LeafTheme.brandEmerald)

                                    TextField("0.00", text: $targetAmountInput)
                                        .font(.system(size: 38, weight: .bold, design: .rounded).monospacedDigit())
                                        .keyboardType(.decimalPad)
                                        .foregroundStyle(LeafTheme.textPrimary(for: colorScheme))
                                }
                                .padding(.horizontal, 16)
                            }
                            .padding(.vertical, 16)
                            .frame(maxWidth: .infinity)
                        }
                        .padding(.horizontal)

                        // 3. Initial Contribution (if new goal)
                        if existingGoal == nil {
                            SquircleCard(cornerRadius: 18) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Initial Saved Amount")
                                            .font(LeafTypography.bodyMedium)
                                            .foregroundStyle(LeafTheme.textPrimary(for: colorScheme))
                                        Text("Amount already saved (optional)")
                                            .font(LeafTypography.captionRegular)
                                            .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
                                    }

                                    Spacer()

                                    HStack(spacing: 4) {
                                        Text(currency.symbol)
                                            .font(LeafTypography.bodyBold)
                                            .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))

                                        TextField("0", text: $initialAmountInput)
                                            .font(.system(size: 16, weight: .bold, design: .rounded).monospacedDigit())
                                            .keyboardType(.decimalPad)
                                            .multilineTextAlignment(.trailing)
                                            .frame(width: 80)
                                    }
                                }
                                .padding(16)
                            }
                            .padding(.horizontal)
                        }

                        // 4. Target Date (Optional)
                        SquircleCard(cornerRadius: 18) {
                            VStack(spacing: 12) {
                                Toggle(isOn: $hasTargetDate) {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Set Target Date")
                                            .font(LeafTypography.bodyMedium)
                                            .foregroundStyle(LeafTheme.textPrimary(for: colorScheme))
                                        Text("Enables monthly required savings calculation")
                                            .font(LeafTypography.captionRegular)
                                            .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
                                    }
                                }
                                .tint(Color(hex: selectedColorHex) ?? LeafTheme.brandEmerald)

                                if hasTargetDate {
                                    Divider().background(LeafTheme.cardBorder(for: colorScheme))

                                    DatePicker(
                                        "Target Date",
                                        selection: $targetDate,
                                        in: Date()...,
                                        displayedComponents: [.date]
                                    )
                                    .font(LeafTypography.bodyMedium)
                                    .foregroundStyle(LeafTheme.textPrimary(for: colorScheme))
                                }
                            }
                            .padding(16)
                        }
                        .padding(.horizontal)

                        // 5. Note (Optional)
                        SquircleCard(cornerRadius: 18) {
                            HStack {
                                Image(systemName: "note.text")
                                    .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
                                TextField("Description / motivation (optional)", text: $note)
                                    .font(LeafTypography.bodyMedium)
                                    .foregroundStyle(LeafTheme.textPrimary(for: colorScheme))
                            }
                            .padding(16)
                        }
                        .padding(.horizontal)

                        // 6. Submit Button
                        Button(action: {
                            Task { await submit() }
                        }) {
                            HStack(spacing: 6) {
                                if isSubmitting {
                                    ProgressView().tint(.white)
                                } else {
                                    Image(systemName: "checkmark.circle.fill")
                                    Text(existingGoal != nil ? "Update Goal" : "Create Goal")
                                        .font(LeafTypography.headline)
                                }
                            }
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(Color(hex: selectedColorHex) ?? LeafTheme.brandEmerald)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        }
                        .disabled(isSubmitting)
                        .padding(.horizontal)
                        .padding(.top, 4)
                        .padding(.bottom, 24)
                    }
                    .padding(.top, 12)
                }
            }
            .navigationTitle(existingGoal != nil ? "Edit Goal" : "New Savings Goal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
                }
            }
        }
    }

    private func systemIcon(for id: String) -> String {
        availableIcons.first { $0.id == id }?.systemName ?? "target"
    }

    private func submit() async {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            errorMessage = "Please enter a valid goal name."
            return
        }

        guard let targetAmt = parsedTargetAmount, targetAmt.subunits > 0 else {
            errorMessage = "Target amount must be strictly greater than zero."
            return
        }

        let targetEpoch: Int64? = hasTargetDate ? Int64(targetDate.timeIntervalSince1970 * 1000) : nil
        let trimmedNote = note.trimmingCharacters(in: .whitespacesAndNewlines)

        isSubmitting = true
        errorMessage = nil

        do {
            try await onSave(
                existingGoal?.id ?? 0,
                trimmedName,
                targetAmt,
                parsedInitialAmount,
                targetEpoch,
                trimmedNote.isEmpty ? nil : trimmedNote,
                selectedIcon,
                selectedColorHex
            )
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }

        isSubmitting = false
    }
}

