import SwiftUI

/// Dedicated native iOS screen for reviewing and correcting OCR-extracted receipt values.
/// Displays the receipt preview, editable merchant, total amount, date, suggested category,
/// payment method, subtotal/tax details, and confidence badges.
public struct ReceiptReviewView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Bindable public var viewModel: ReceiptScannerViewModel
    public let onSaveComplete: () -> Void
    public let onCancel: () -> Void

    @State private var isImageExpanded: Bool = false
    @State private var isTaxSectionExpanded: Bool = false

    public init(
        viewModel: ReceiptScannerViewModel,
        onSaveComplete: @escaping () -> Void,
        onCancel: @escaping () -> Void
    ) {
        self.viewModel = viewModel
        self.onSaveComplete = onSaveComplete
        self.onCancel = onCancel
    }

    public var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 1. Error Banner if present
                if let error = viewModel.errorMessage {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(LeafTheme.expenseCoral)
                        Text(error)
                            .font(LeafTypography.captionRegular)
                            .foregroundStyle(LeafTheme.expenseCoral)
                    }
                    .padding(.horizontal)
                }

                // 2. Receipt Image Preview Card
                receiptImageCard

                // 3. Extracted Total Amount Hero Field
                amountSection

                // 4. Merchant Name Field
                merchantSection

                // 5. Category Selection
                categorySection

                // 6. Payment Method & Date
                metaSection

                // 7. Optional Subtotal & Tax Section
                subtotalAndTaxSection

                // 8. Note Field
                noteSection

                // 9. Primary Action Buttons
                actionButtonsSection

                Spacer(minLength: 32)
            }
            .padding(.top, 12)
        }
        .background(LeafTheme.canvas(for: colorScheme).ignoresSafeArea())
        .sheet(isPresented: $isImageExpanded) {
            expandedImageSheet
        }
    }

    // MARK: - 1. Receipt Image Card

    private var receiptImageCard: some View {
        SquircleCard(cornerRadius: 18) {
            HStack(spacing: 14) {
                if let image = viewModel.capturedImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 56, height: 56)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(LeafTheme.cardBorder(for: colorScheme), lineWidth: 0.75)
                        )
                } else {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(colorScheme == .dark ? Color.white.opacity(0.06) : Color.black.opacity(0.05))
                        .frame(width: 56, height: 56)
                        .overlay(
                            Image(systemName: "doc.text.viewfinder")
                                .font(.system(size: 24))
                                .foregroundStyle(LeafTheme.brandEmerald)
                        )
                }

                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text("Scanned Receipt")
                            .font(LeafTypography.headline)
                            .foregroundStyle(LeafTheme.textPrimary(for: colorScheme))

                        confidenceBadge(for: viewModel.ocrResult?.overallConfidence ?? .medium)
                    }

                    Text("On-device Apple Vision text recognition")
                        .font(LeafTypography.captionRegular)
                        .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
                }

                Spacer()

                Button(action: { isImageExpanded = true }) {
                    Image(systemName: "arrow.up.left.and.arrow.down.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(LeafTheme.brandEmerald)
                        .padding(8)
                        .background(
                            Circle()
                                .fill(LeafTheme.brandEmerald.opacity(0.12))
                        )
                }
            }
            .padding(14)
        }
        .padding(.horizontal)
    }

    // MARK: - 2. Amount Hero Section

    private var amountSection: some View {
        SquircleCard(cornerRadius: 22) {
            VStack(spacing: 8) {
                HStack {
                    Text("TOTAL AMOUNT")
                        .font(LeafTypography.captionBold)
                        .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
                        .tracking(0.5)

                    Spacer()

                    confidenceBadge(for: viewModel.amountConfidence)
                }

                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(viewModel.currency.symbol)
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(LeafTheme.expenseCoral)

                    TextField("0.00", text: $viewModel.amountInput)
                        .font(.system(size: 38, weight: .bold, design: .rounded).monospacedDigit())
                        .keyboardType(.decimalPad)
                        .foregroundStyle(LeafTheme.textPrimary(for: colorScheme))
                }
                .padding(.top, 2)
            }
            .padding(18)
            .frame(maxWidth: .infinity)
        }
        .padding(.horizontal)
    }

    // MARK: - 3. Merchant Section

    private var merchantSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("MERCHANT / STORE")
                    .font(LeafTypography.captionBold)
                    .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
                    .tracking(0.5)

                Spacer()

                confidenceBadge(for: viewModel.merchantConfidence)
            }
            .padding(.horizontal)

            HStack(spacing: 10) {
                Image(systemName: "storefront.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(LeafTheme.brandEmerald)

                TextField("e.g. Starbucks, Target, Shell", text: $viewModel.merchantInput)
                    .font(LeafTypography.bodyMedium)
                    .foregroundStyle(LeafTheme.textPrimary(for: colorScheme))
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(colorScheme == .dark ? LeafTheme.cardDark : LeafTheme.cardLight)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(
                        viewModel.merchantConfidence == .medium
                        ? LeafTheme.amberWarning.opacity(0.8)
                        : LeafTheme.cardBorder(for: colorScheme),
                        lineWidth: viewModel.merchantConfidence == .medium ? 1.5 : 0.75
                    )
            )
            .padding(.horizontal)
        }
    }

    // MARK: - 4. Category Section

    private var categorySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("CATEGORY")
                    .font(LeafTypography.captionBold)
                    .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
                    .tracking(0.5)

                Spacer()

                if viewModel.isCategorySuggested {
                    HStack(spacing: 4) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 10))
                        Text("Suggested")
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .foregroundStyle(LeafTheme.brandEmerald)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(
                        Capsule().fill(LeafTheme.brandEmerald.opacity(0.12))
                    )
                }
            }
            .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(viewModel.categories) { cat in
                        let isSelected = cat.id == viewModel.selectedCategoryId
                        Button(action: {
                            viewModel.selectedCategoryId = cat.id
                            viewModel.isCategorySuggested = false
                        }) {
                            HStack(spacing: 6) {
                                CategoryIconBadge(
                                    iconName: cat.iconName,
                                    colorHex: cat.colorHex,
                                    size: 24
                                )
                                Text(cat.name)
                                    .font(.system(size: 13, weight: .medium, design: .rounded))
                                    .foregroundStyle(
                                        isSelected
                                        ? LeafTheme.brandEmerald
                                        : LeafTheme.textPrimary(for: colorScheme)
                                    )
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(
                                        isSelected
                                        ? LeafTheme.brandEmerald.opacity(0.12)
                                        : (colorScheme == .dark ? LeafTheme.cardDark : LeafTheme.cardLight)
                                    )
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .stroke(
                                        isSelected
                                        ? LeafTheme.brandEmerald
                                        : LeafTheme.cardBorder(for: colorScheme),
                                        lineWidth: isSelected ? 1.5 : 0.75
                                    )
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    // MARK: - 5. Payment Method & Date Section

    private var metaSection: some View {
        SquircleCard(cornerRadius: 18) {
            VStack(spacing: 14) {
                // Payment Method
                HStack {
                    Text("Payment Method")
                        .font(LeafTypography.bodyMedium)
                        .foregroundStyle(LeafTheme.textPrimary(for: colorScheme))

                    Spacer()

                    Picker("Payment Method", selection: $viewModel.selectedPaymentMethod) {
                        Text("Cash").tag(PaymentMethod.cash)
                        Text("Account").tag(PaymentMethod.account)
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 160)
                }

                Divider()
                    .background(LeafTheme.cardBorder(for: colorScheme))

                // Date Picker
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Date")
                            .font(LeafTypography.bodyMedium)
                            .foregroundStyle(LeafTheme.textPrimary(for: colorScheme))

                        if viewModel.dateConfidence == .medium {
                            Text("Review detected date")
                                .font(LeafTypography.captionRegular)
                                .foregroundStyle(LeafTheme.amberWarning)
                        }
                    }

                    Spacer()

                    DatePicker(
                        "",
                        selection: $viewModel.selectedDate,
                        displayedComponents: [.date]
                    )
                    .labelsHidden()
                }
            }
            .padding(16)
        }
        .padding(.horizontal)
    }

    // MARK: - 6. Subtotal & Tax Section

    private var subtotalAndTaxSection: some View {
        SquircleCard(cornerRadius: 18) {
            VStack(spacing: 12) {
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isTaxSectionExpanded.toggle()
                    }
                }) {
                    HStack {
                        Image(systemName: "percent")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(LeafTheme.brandEmerald)

                        Text("Tax & Subtotal Breakdown")
                            .font(LeafTypography.subheadline)
                            .foregroundStyle(LeafTheme.textPrimary(for: colorScheme))

                        Spacer()

                        Image(systemName: isTaxSectionExpanded ? "chevron.up" : "chevron.down")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
                    }
                }
                .buttonStyle(.plain)

                if isTaxSectionExpanded {
                    VStack(spacing: 10) {
                        Divider()
                            .background(LeafTheme.cardBorder(for: colorScheme))

                        HStack {
                            Text("Subtotal")
                                .font(LeafTypography.captionRegular)
                                .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))

                            Spacer()

                            HStack(spacing: 4) {
                                Text(viewModel.currency.symbol)
                                    .font(LeafTypography.captionBold)
                                TextField("0.00", text: $viewModel.subtotalInput)
                                    .font(LeafTypography.captionBold)
                                    .keyboardType(.decimalPad)
                                    .multilineTextAlignment(.trailing)
                                    .frame(width: 80)
                            }
                        }

                        HStack {
                            Text("Tax (GST/VAT)")
                                .font(LeafTypography.captionRegular)
                                .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))

                            Spacer()

                            HStack(spacing: 4) {
                                Text(viewModel.currency.symbol)
                                    .font(LeafTypography.captionBold)
                                TextField("0.00", text: $viewModel.taxInput)
                                    .font(LeafTypography.captionBold)
                                    .keyboardType(.decimalPad)
                                    .multilineTextAlignment(.trailing)
                                    .frame(width: 80)
                            }
                        }
                    }
                    .padding(.top, 4)
                }
            }
            .padding(16)
        }
        .padding(.horizontal)
    }

    // MARK: - 7. Note Section

    private var noteSection: some View {
        SquircleCard(cornerRadius: 18) {
            HStack(spacing: 10) {
                Image(systemName: "note.text")
                    .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))

                TextField("Note (optional)", text: $viewModel.noteInput)
                    .font(LeafTypography.bodyMedium)
                    .foregroundStyle(LeafTheme.textPrimary(for: colorScheme))
            }
            .padding(14)
        }
        .padding(.horizontal)
    }

    // MARK: - 8. Action Buttons Section

    private var actionButtonsSection: some View {
        VStack(spacing: 12) {
            // Confirm & Save Expense (ONLY action that creates financial data)
            Button(action: {
                Task {
                    let success = await viewModel.confirmAndSaveExpense()
                    if success {
                        onSaveComplete()
                    }
                }
            }) {
                HStack(spacing: 8) {
                    if viewModel.isSubmitting {
                        ProgressView().tint(.white)
                    } else {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 16, weight: .bold))
                        Text("Save Expense")
                            .font(LeafTypography.headline)
                    }
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(
                    viewModel.amountInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    ? LeafTheme.brandEmerald.opacity(0.4)
                    : LeafTheme.brandEmerald
                )
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .disabled(viewModel.amountInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isSubmitting)

            // Secondary Buttons: Retake & Cancel
            HStack(spacing: 12) {
                Button(action: { viewModel.retake() }) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.clockwise")
                        Text("Retake Receipt")
                    }
                    .font(LeafTypography.subheadline)
                    .foregroundStyle(LeafTheme.textPrimary(for: colorScheme))
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(colorScheme == .dark ? LeafTheme.cardDark : LeafTheme.cardLight)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(LeafTheme.cardBorder(for: colorScheme), lineWidth: 0.75)
                    )
                }

                Button(action: onCancel) {
                    Text("Cancel")
                        .font(LeafTypography.subheadline)
                        .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(colorScheme == .dark ? LeafTheme.cardDark : LeafTheme.cardLight)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(LeafTheme.cardBorder(for: colorScheme), lineWidth: 0.75)
                        )
                }
            }
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }

    // MARK: - Confidence Pill Badge Helper

    @ViewBuilder
    private func confidenceBadge(for confidence: ReceiptConfidence) -> some View {
        switch confidence {
        case .high:
            HStack(spacing: 3) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 9))
                Text("Verified")
                    .font(.system(size: 10, weight: .bold))
            }
            .foregroundStyle(LeafTheme.brandEmerald)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(
                Capsule().fill(LeafTheme.brandEmerald.opacity(0.12))
            )

        case .medium:
            HStack(spacing: 3) {
                Image(systemName: "exclamationmark.circle.fill")
                    .font(.system(size: 9))
                Text("Review")
                    .font(.system(size: 10, weight: .bold))
            }
            .foregroundStyle(LeafTheme.amberWarning)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(
                Capsule().fill(LeafTheme.amberWarning.opacity(0.15))
            )

        case .low:
            HStack(spacing: 3) {
                Image(systemName: "questionmark.circle.fill")
                    .font(.system(size: 9))
                Text("Uncertain")
                    .font(.system(size: 10, weight: .bold))
            }
            .foregroundStyle(LeafTheme.textTertiary(for: colorScheme))
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(
                Capsule().fill(colorScheme == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.06))
            )
        }
    }

    // MARK: - Full Image Modal

    private var expandedImageSheet: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                if let image = viewModel.capturedImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .padding()
                }
            }
            .navigationTitle("Receipt Preview")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { isImageExpanded = false }
                        .foregroundStyle(.white)
                }
            }
        }
    }
}

