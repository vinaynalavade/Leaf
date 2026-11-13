import SwiftUI

/// Modal sheet for creating a new Travel Wallet or editing an existing one.
/// Manages destination currency selection, optional budget, custom styling and notes.
public struct CreateEditTravelWalletSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    public var existingWallet: TravelWallet?
    public let onSave: (String, String, Amount?, String?, String, String) async -> Bool

    @State private var name: String = ""
    @State private var selectedCurrencyCode: String = "USD"
    @State private var budgetInput: String = ""
    @State private var note: String = ""
    @State private var selectedColorHex: String = "#10B981"
    @State private var selectedIcon: String = "airplane"
    @State private var isSubmitting: Bool = false
    @State private var errorMessage: String? = nil

    private let availableIcons = [
        "airplane", "globe", "suitcase.rolling.fill", "car.fill",
        "tram.fill", "beach.umbrella.fill", "map.fill", "building.columns.fill",
        "cart.fill", "sparkles"
    ]

    private let availableColors = [
        "#10B981", "#3B82F6", "#6366F1", "#8B5CF6",
        "#EC4899", "#F43F5E", "#F97316", "#F59E0B",
        "#14B8A6", "#06B6D4"
    ]

    public init(
        existingWallet: TravelWallet? = nil,
        onSave: @escaping (String, String, Amount?, String?, String, String) async -> Bool
    ) {
        self.existingWallet = existingWallet
        self.onSave = onSave
    }

    private var selectedCurrency: Currency {
        Currency.fromCode(selectedCurrencyCode)
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                LeafTheme.canvas(for: colorScheme).ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 22) {
                        // Error Banner
                        if let error = errorMessage {
                            HStack(spacing: 8) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundStyle(LeafTheme.expenseCoral)
                                Text(error)
                                    .font(LeafTypography.captionRegular)
                                    .foregroundStyle(LeafTheme.expenseCoral)
                            }
                            .padding(.horizontal)
                        }

                        // Preview Avatar Card
                        previewHeaderCard

                        // Name Field
                        nameSection

                        // Operating Currency Picker
                        currencyPickerSection

                        // Optional Budget Field
                        budgetSection

                        // Icon Picker
                        iconPickerSection

                        // Color Palette
                        colorPickerSection

                        // Note Field
                        noteSection

                        // Save CTA
                        Button(action: { Task { await handleSave() } }) {
                            HStack(spacing: 8) {
                                if isSubmitting {
                                    ProgressView().tint(.white)
                                } else {
                                    Image(systemName: existingWallet != nil ? "checkmark" : "plus")
                                    Text(existingWallet != nil ? "Update Wallet" : "Create Wallet")
                                        .font(LeafTypography.headline)
                                }
                            }
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(
                                name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                                ? LeafTheme.brandEmerald.opacity(0.4)
                                : LeafTheme.brandEmerald
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        }
                        .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSubmitting)
                        .padding(.horizontal)
                        .padding(.bottom, 24)
                    }
                    .padding(.top, 14)
                }
            }
            .navigationTitle(existingWallet != nil ? "Edit Travel Wallet" : "New Travel Wallet")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
                }
            }
            .onAppear {
                if let w = existingWallet {
                    self.name = w.name
                    self.selectedCurrencyCode = w.currencyCode
                    self.note = w.note ?? ""
                    self.selectedColorHex = w.colorHex
                    self.selectedIcon = w.iconName
                    if let budget = w.budgetAmount {
                        self.budgetInput = budget.toInputString(currency: w.currency)
                    }
                }
            }
        }
    }

    // MARK: - Preview Header Card

    private var previewHeaderCard: some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(Color(hex: selectedColorHex).opacity(0.18))
                    .frame(width: 68, height: 68)

                Image(systemName: selectedIcon)
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(Color(hex: selectedColorHex))
            }

            Text(name.isEmpty ? "Travel Wallet Preview" : name)
                .font(LeafTypography.headline)
                .foregroundStyle(LeafTheme.textPrimary(for: colorScheme))

            HStack(spacing: 4) {
                Text(selectedCurrency.code)
                    .font(LeafTypography.captionBold)
                Text("•")
                Text(selectedCurrency.name)
                    .font(LeafTypography.captionRegular)
            }
            .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(colorScheme == .dark ? LeafTheme.cardDark : LeafTheme.cardLight)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(LeafTheme.cardBorder(for: colorScheme), lineWidth: 0.75)
        )
        .padding(.horizontal)
    }

    // MARK: - Name Section

    private var nameSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("WALLET NAME")
                .font(LeafTypography.captionBold)
                .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
                .tracking(0.5)

            TextField("e.g. Dubai Trip, Europe Summer, Tokyo Tour", text: $name)
                .font(LeafTypography.bodyMedium)
                .foregroundStyle(LeafTheme.textPrimary(for: colorScheme))
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(colorScheme == .dark ? LeafTheme.cardDark : LeafTheme.cardLight)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(LeafTheme.cardBorder(for: colorScheme), lineWidth: 0.75)
                )
        }
        .padding(.horizontal)
    }

    // MARK: - Currency Picker Section

    private var currencyPickerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("DESTINATION CURRENCY")
                .font(LeafTypography.captionBold)
                .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
                .tracking(0.5)

            Menu {
                ForEach(Currency.supportedCurrencies) { curr in
                    Button(action: { selectedCurrencyCode = curr.code }) {
                        HStack {
                            Text("\(curr.code) (\(curr.symbol)) — \(curr.name)")
                            if curr.code == selectedCurrencyCode {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                HStack {
                    Text(selectedCurrency.symbol)
                        .font(LeafTypography.headline)
                        .foregroundStyle(LeafTheme.brandEmerald)
                        .frame(width: 32)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(selectedCurrency.code) — \(selectedCurrency.name)")
                            .font(LeafTypography.bodyMedium)
                            .foregroundStyle(LeafTheme.textPrimary(for: colorScheme))
                    }

                    Spacer()

                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 13))
                        .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
                }
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(colorScheme == .dark ? LeafTheme.cardDark : LeafTheme.cardLight)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(LeafTheme.cardBorder(for: colorScheme), lineWidth: 0.75)
                )
            }
        }
        .padding(.horizontal)
    }

    // MARK: - Budget Section

    private var budgetSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("PLANNED TRIP BUDGET (OPTIONAL)")
                .font(LeafTypography.captionBold)
                .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
                .tracking(0.5)

            HStack {
                Text(selectedCurrency.symbol)
                    .font(LeafTypography.headline)
                    .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))

                TextField("0.00", text: $budgetInput)
                    .font(LeafTypography.bodyMedium)
                    .keyboardType(.decimalPad)
                    .foregroundStyle(LeafTheme.textPrimary(for: colorScheme))
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(colorScheme == .dark ? LeafTheme.cardDark : LeafTheme.cardLight)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(LeafTheme.cardBorder(for: colorScheme), lineWidth: 0.75)
            )
        }
        .padding(.horizontal)
    }

    // MARK: - Icon Picker Section

    private var iconPickerSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("CHOOSE ICON")
                .font(LeafTypography.captionBold)
                .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
                .tracking(0.5)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 5), spacing: 12) {
                ForEach(availableIcons, id: \.self) { icon in
                    let isSelected = selectedIcon == icon
                    Button(action: { selectedIcon = icon }) {
                        ZStack {
                            Circle()
                                .fill(
                                    isSelected
                                    ? Color(hex: selectedColorHex).opacity(0.2)
                                    : (colorScheme == .dark ? LeafTheme.cardDark : LeafTheme.cardLight)
                                )
                                .frame(height: 48)

                            Image(systemName: icon)
                                .font(.system(size: 18, weight: isSelected ? .bold : .medium))
                                .foregroundStyle(
                                    isSelected
                                    ? Color(hex: selectedColorHex)
                                    : LeafTheme.textPrimary(for: colorScheme)
                                )
                        }
                        .overlay(
                            Circle()
                                .stroke(
                                    isSelected ? Color(hex: selectedColorHex) : LeafTheme.cardBorder(for: colorScheme),
                                    lineWidth: isSelected ? 2 : 0.75
                                )
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.horizontal)
    }

    // MARK: - Color Picker Section

    private var colorPickerSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("THEME COLOR")
                .font(LeafTypography.captionBold)
                .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
                .tracking(0.5)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(availableColors, id: \.self) { hex in
                        let isSelected = selectedColorHex.uppercased() == hex.uppercased()
                        Button(action: { selectedColorHex = hex }) {
                            ZStack {
                                Circle()
                                    .fill(Color(hex: hex))
                                    .frame(width: 38, height: 38)

                                if isSelected {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundStyle(.white)
                                }
                            }
                            .overlay(
                                Circle()
                                    .stroke(
                                        isSelected ? LeafTheme.textPrimary(for: colorScheme) : Color.clear,
                                        lineWidth: 2.5
                                    )
                                    .padding(-2)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .padding(.horizontal)
    }

    // MARK: - Note Section

    private var noteSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("NOTES / DATES (OPTIONAL)")
                .font(LeafTypography.captionBold)
                .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
                .tracking(0.5)

            TextField("e.g. Travel dates: Nov 15 - Nov 25", text: $note)
                .font(LeafTypography.bodyMedium)
                .foregroundStyle(LeafTheme.textPrimary(for: colorScheme))
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(colorScheme == .dark ? LeafTheme.cardDark : LeafTheme.cardLight)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(LeafTheme.cardBorder(for: colorScheme), lineWidth: 0.75)
                )
        }
        .padding(.horizontal)
    }

    // MARK: - Save Handler

    private func handleSave() async {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            errorMessage = "Please enter a wallet name."
            return
        }

        var parsedBudget: Amount? = nil
        let cleanBudgetStr = budgetInput.trimmingCharacters(in: .whitespacesAndNewlines)
        if !cleanBudgetStr.isEmpty {
            parsedBudget = Amount.fromStringOrNull(cleanBudgetStr, currency: selectedCurrency)
        }

        isSubmitting = true
        errorMessage = nil

        let success = await onSave(
            trimmed,
            selectedCurrencyCode,
            parsedBudget,
            note.isEmpty ? nil : note,
            selectedColorHex,
            selectedIcon
        )

        if success {
            dismiss()
        }
        isSubmitting = false
    }
}

