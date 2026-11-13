import SwiftUI

/// Complete native iOS sheet for creating a new SplitExpense with participants and splitting algorithms.
public struct CreateSplitSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    public let currency: Currency
    public let categories: [Category]
    public let calculateSplitUseCase: CalculateSplitUseCase
    public let onSave: (String, Amount, Int64, Int64, String, String, PaymentMethod, Bool, [SplitParticipant]) async throws -> Void

    // MARK: - Form State
    @State private var title: String = ""
    @State private var amountInput: String = ""
    @State private var selectedDate: Date = Date()
    @State private var selectedCategoryId: Int64 = 1
    @State private var selectedPaymentMethod: PaymentMethod = .cash
    @State private var addToTransactions: Bool = true
    @State private var payerName: String = "Me"

    // Participant State
    @State private var participantNames: [String] = ["Me"]
    @State private var newParticipantName: String = ""

    // Splitting Method State
    public enum SplitMethodSelection: String, CaseIterable, Identifiable {
        case equal = "Equal"
        case customAmount = "Custom Amount"
        case percentage = "Percentage"

        public var id: String { rawValue }
    }

    @State private var selectedMethod: SplitMethodSelection = .equal
    @State private var customAmounts: [String: String] = [:]      // participantName -> string input
    @State private var customPercentages: [String: String] = [:]  // participantName -> string input

    @State private var isSubmitting: Bool = false
    @State private var errorMessage: String? = nil

    public init(
        currency: Currency = .default,
        categories: [Category],
        calculateSplitUseCase: CalculateSplitUseCase,
        onSave: @escaping (String, Amount, Int64, Int64, String, String, PaymentMethod, Bool, [SplitParticipant]) async throws -> Void
    ) {
        self.currency = currency
        self.categories = categories.filter { $0.type == .expense }
        self.calculateSplitUseCase = calculateSplitUseCase
        self.onSave = onSave
        if let first = categories.first(where: { $0.type == .expense }) {
            self._selectedCategoryId = State(initialValue: first.id)
        }
    }

    private var parsedTotalAmount: Amount {
        Amount.fromStringOrNull(amountInput, currency: currency) ?? .zero
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                LeafTheme.canvas(for: colorScheme).ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // Error message banner
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

                        // 1. Basic Info Section
                        basicInfoSection

                        // 2. Participants Section
                        participantsSection

                        // 3. Splitting Method Section
                        splittingMethodSection

                        // 4. Ledger Integration Toggle
                        ledgerIntegrationSection

                        // 5. Submit Button
                        Button(action: { Task { await submit() } }) {
                            HStack(spacing: 6) {
                                if isSubmitting {
                                    ProgressView().tint(.white)
                                } else {
                                    Image(systemName: "person.2.fill")
                                    Text("Create Split")
                                        .font(LeafTypography.headline)
                                }
                            }
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(LeafTheme.brandEmerald)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        }
                        .disabled(isSubmitting)
                        .padding(.horizontal)
                        .padding(.bottom, 24)
                    }
                    .padding(.top, 12)
                }
            }
            .navigationTitle("New Split")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
                }
            }
        }
    }

    // MARK: - Section 1: Basic Info

    private var basicInfoSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("EXPENSE DETAILS")
                .font(LeafTypography.captionBold)
                .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
                .padding(.horizontal)
                .tracking(0.5)

            SquircleCard(cornerRadius: 20) {
                VStack(spacing: 16) {
                    // Title Input
                    HStack {
                        Image(systemName: "tag.fill")
                            .foregroundStyle(LeafTheme.brandEmerald)
                        TextField("Expense Title (e.g. Dinner, Trip)", text: $title)
                            .font(LeafTypography.bodyMedium)
                            .foregroundStyle(LeafTheme.textPrimary(for: colorScheme))
                    }

                    Divider().background(LeafTheme.cardBorder(for: colorScheme))

                    // Amount Input
                    VStack(alignment: .leading, spacing: 4) {
                        Text("TOTAL BILL")
                            .font(LeafTypography.captionBold)
                            .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))

                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            Text(currency.symbol)
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundStyle(LeafTheme.brandEmerald)

                            TextField("0.00", text: $amountInput)
                                .font(.system(size: 34, weight: .bold, design: .rounded).monospacedDigit())
                                .keyboardType(.decimalPad)
                                .foregroundStyle(LeafTheme.textPrimary(for: colorScheme))
                        }
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

                    // Payment Method Picker
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

            // Category Chips
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(categories) { cat in
                        let isSelected = cat.id == selectedCategoryId
                        Button(action: { selectedCategoryId = cat.id }) {
                            HStack(spacing: 6) {
                                CategoryIconBadge(
                                    iconName: cat.iconName,
                                    colorHex: cat.colorHex,
                                    size: 22
                                )
                                Text(cat.name)
                                    .font(.system(size: 12, weight: .medium, design: .rounded))
                                    .foregroundStyle(isSelected ? LeafTheme.brandEmerald : LeafTheme.textPrimary(for: colorScheme))
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 7)
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
                .padding(.horizontal)
            }
        }
    }

    // MARK: - Section 2: Participants

    private var participantsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("PARTICIPANTS (\(participantNames.count))")
                .font(LeafTypography.captionBold)
                .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
                .padding(.horizontal)
                .tracking(0.5)

            SquircleCard(cornerRadius: 20) {
                VStack(spacing: 12) {
                    // Add participant field
                    HStack(spacing: 8) {
                        Image(systemName: "person.badge.plus")
                            .foregroundStyle(LeafTheme.brandEmerald)

                        TextField("Friend's name", text: $newParticipantName)
                            .font(LeafTypography.bodyMedium)
                            .foregroundStyle(LeafTheme.textPrimary(for: colorScheme))

                        Button(action: addParticipant) {
                            Text("Add")
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(LeafTheme.brandEmerald)
                                .clipShape(Capsule())
                        }
                        .disabled(newParticipantName.trimmingCharacters(in: .whitespaces).isEmpty)
                    }

                    Divider().background(LeafTheme.cardBorder(for: colorScheme))

                    // Payer Selector
                    HStack {
                        Text("Paid by")
                            .font(LeafTypography.bodyMedium)
                            .foregroundStyle(LeafTheme.textPrimary(for: colorScheme))
                        Spacer()
                        Picker("Paid by", selection: $payerName) {
                            ForEach(participantNames, id: \.self) { name in
                                Text(name).tag(name)
                            }
                        }
                        .tint(LeafTheme.brandEmerald)
                    }

                    Divider().background(LeafTheme.cardBorder(for: colorScheme))

                    // Participants List Chips
                    FlowLayout(spacing: 8) {
                        ForEach(participantNames, id: \.self) { name in
                            HStack(spacing: 6) {
                                Image(systemName: name == "Me" ? "person.crop.circle.fill" : "person.fill")
                                    .font(.system(size: 11))

                                Text(name)
                                    .font(.system(size: 13, weight: .medium, design: .rounded))

                                if name != "Me" {
                                    Button(action: { removeParticipant(name) }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .font(.system(size: 13))
                                            .foregroundStyle(LeafTheme.textTertiary(for: colorScheme))
                                    }
                                }
                            }
                            .foregroundStyle(name == payerName ? LeafTheme.brandEmerald : LeafTheme.textPrimary(for: colorScheme))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .fill((name == payerName ? LeafTheme.brandEmerald : Color.gray).opacity(0.12))
                            )
                        }
                    }
                }
                .padding(16)
            }
            .padding(.horizontal)
        }
    }

    // MARK: - Section 3: Splitting Method

    private var splittingMethodSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("SPLIT METHOD")
                .font(LeafTypography.captionBold)
                .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
                .padding(.horizontal)
                .tracking(0.5)

            SquircleCard(cornerRadius: 20) {
                VStack(spacing: 16) {
                    Picker("Method", selection: $selectedMethod) {
                        ForEach(SplitMethodSelection.allCases) { method in
                            Text(method.rawValue).tag(method)
                        }
                    }
                    .pickerStyle(.segmented)

                    Divider().background(LeafTheme.cardBorder(for: colorScheme))

                    // Method-Specific Allocation UI
                    switch selectedMethod {
                    case .equal:
                        equalSplitPreview
                    case .customAmount:
                        customAmountAllocation
                    case .percentage:
                        percentageAllocation
                    }
                }
                .padding(16)
            }
            .padding(.horizontal)
        }
    }

    @ViewBuilder
    private var equalSplitPreview: some View {
        let shares = calculateSplitUseCase.executeEqualSplit(
            totalAmount: parsedTotalAmount,
            participants: participantNames,
            payerName: payerName
        )

        VStack(spacing: 8) {
            ForEach(shares) { p in
                HStack {
                    Text(p.name)
                        .font(LeafTypography.bodyMedium)
                        .foregroundStyle(LeafTheme.textPrimary(for: colorScheme))

                    Spacer()

                    Text(p.amount.formatted(currency: currency))
                        .font(.system(size: 15, weight: .bold, design: .rounded).monospacedDigit())
                        .foregroundStyle(LeafTheme.textPrimary(for: colorScheme))
                }
            }
        }
    }

    @ViewBuilder
    private var customAmountAllocation: some View {
        VStack(spacing: 10) {
            ForEach(participantNames, id: \.self) { name in
                HStack {
                    Text(name)
                        .font(LeafTypography.bodyMedium)
                        .foregroundStyle(LeafTheme.textPrimary(for: colorScheme))

                    Spacer()

                    HStack(spacing: 2) {
                        Text(currency.symbol)
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))

                        TextField("0.00", text: Binding(
                            get: { customAmounts[name] ?? "" },
                            set: { customAmounts[name] = $0 }
                        ))
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .font(.system(size: 14, weight: .semibold, design: .rounded).monospacedDigit())
                        .frame(width: 80)
                        .padding(6)
                        .background(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill((colorScheme == .dark ? Color.white : Color.black).opacity(0.04))
                        )
                    }
                }
            }

            let totalAllocatedSubunits = participantNames.reduce(Int64(0)) { sum, name in
                let amt = Amount.fromStringOrNull(customAmounts[name] ?? "", currency: currency) ?? .zero
                return sum + amt.subunits
            }
            let diff = parsedTotalAmount.subunits - totalAllocatedSubunits

            HStack {
                if diff == 0 && parsedTotalAmount.subunits > 0 {
                    Image(systemName: "checkmark.circle.fill").foregroundStyle(LeafTheme.brandEmerald)
                    Text("Exact match (100% allocated)").font(LeafTypography.captionBold).foregroundStyle(LeafTheme.brandEmerald)
                } else if diff > 0 {
                    Image(systemName: "exclamationmark.circle").foregroundStyle(LeafTheme.amberAccent)
                    Text("Remaining to assign: " + Amount(subunits: diff).formatted(currency: currency))
                        .font(LeafTypography.captionRegular).foregroundStyle(LeafTheme.amberAccent)
                } else {
                    Image(systemName: "xmark.circle.fill").foregroundStyle(LeafTheme.expenseCoral)
                    Text("Overallocated by: " + Amount(subunits: -diff).formatted(currency: currency))
                        .font(LeafTypography.captionRegular).foregroundStyle(LeafTheme.expenseCoral)
                }
                Spacer()
            }
            .padding(.top, 4)
        }
    }

    @ViewBuilder
    private var percentageAllocation: some View {
        VStack(spacing: 10) {
            ForEach(participantNames, id: \.self) { name in
                HStack {
                    Text(name)
                        .font(LeafTypography.bodyMedium)
                        .foregroundStyle(LeafTheme.textPrimary(for: colorScheme))

                    Spacer()

                    HStack(spacing: 2) {
                        TextField("0", text: Binding(
                            get: { customPercentages[name] ?? "" },
                            set: { customPercentages[name] = $0 }
                        ))
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .font(.system(size: 14, weight: .semibold, design: .rounded).monospacedDigit())
                        .frame(width: 50)
                        .padding(6)
                        .background(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill((colorScheme == .dark ? Color.white : Color.black).opacity(0.04))
                        )

                        Text("%")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
                    }
                }
            }

            let totalPct = participantNames.reduce(0.0) { sum, name in
                sum + (Double(customPercentages[name]?.replacingOccurrences(of: ",", with: ".") ?? "") ?? 0.0)
            }
            let pctDiff = 100.0 - totalPct

            HStack {
                if abs(pctDiff) < 0.01 {
                    Image(systemName: "checkmark.circle.fill").foregroundStyle(LeafTheme.brandEmerald)
                    Text("Exact match (100%)").font(LeafTypography.captionBold).foregroundStyle(LeafTheme.brandEmerald)
                } else {
                    Image(systemName: "exclamationmark.circle").foregroundStyle(LeafTheme.amberAccent)
                    Text(String(format: "Total: %.1f%% (must equal 100%%)", totalPct))
                        .font(LeafTypography.captionRegular).foregroundStyle(LeafTheme.amberAccent)
                }
                Spacer()
            }
            .padding(.top, 4)
        }
    }

    // MARK: - Section 4: Ledger Integration

    private var ledgerIntegrationSection: some View {
        SquircleCard(cornerRadius: 18) {
            Toggle(isOn: $addToTransactions) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Add to Personal Ledger")
                        .font(LeafTypography.bodyMedium)
                        .foregroundStyle(LeafTheme.textPrimary(for: colorScheme))
                    Text("Records this expense in your personal transactions")
                        .font(LeafTypography.captionRegular)
                        .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
                }
            }
            .tint(LeafTheme.brandEmerald)
            .padding(14)
        }
        .padding(.horizontal)
    }

    // MARK: - Actions

    private func addParticipant() {
        let trimmed = newParticipantName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        if !participantNames.contains(where: { $0.caseInsensitiveCompare(trimmed) == .orderedSame }) {
            participantNames.append(trimmed)
            newParticipantName = ""
        } else {
            errorMessage = "Participant '\(trimmed)' is already added."
        }
    }

    private func removeParticipant(_ name: String) {
        guard name != "Me" else { return }
        participantNames.removeAll { $0 == name }
        if payerName == name {
            payerName = "Me"
        }
    }

    private func submit() async {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else {
            errorMessage = "Please enter an expense title."
            return
        }

        let totalAmt = parsedTotalAmount
        guard totalAmt.subunits > 0 else {
            errorMessage = "Total bill amount must be greater than zero."
            return
        }

        guard participantNames.count >= 2 else {
            errorMessage = "Please add at least one other participant."
            return
        }

        let participants: [SplitParticipant]
        let methodCode: String

        switch selectedMethod {
        case .equal:
            methodCode = "EQUAL"
            participants = calculateSplitUseCase.executeEqualSplit(
                totalAmount: totalAmt,
                participants: participantNames,
                payerName: payerName
            )

        case .customAmount:
            methodCode = "CUSTOM_EXACT"
            var list: [(name: String, amount: Amount)] = []
            var totalAllocated: Int64 = 0

            for name in participantNames {
                let amt = Amount.fromStringOrNull(customAmounts[name] ?? "", currency: currency) ?? .zero
                totalAllocated += amt.subunits
                list.append((name: name, amount: amt))
            }

            if totalAllocated != totalAmt.subunits {
                errorMessage = "Allocated shares must exactly equal total bill (\(totalAmt.formatted(currency: currency)))."
                return
            }

            participants = calculateSplitUseCase.executeExactCustomSplit(
                totalAmount: totalAmt,
                participants: list,
                payerName: payerName
            )

        case .percentage:
            methodCode = "PERCENTAGE"
            var pctList: [(name: String, percentage: Double)] = []
            var totalPct = 0.0

            for name in participantNames {
                let pct = Double(customPercentages[name]?.replacingOccurrences(of: ",", with: ".") ?? "") ?? 0.0
                totalPct += pct
                pctList.append((name: name, percentage: pct))
            }

            if abs(totalPct - 100.0) > 0.01 {
                errorMessage = "Percentages must sum to exactly 100%."
                return
            }

            participants = calculateSplitUseCase.executePercentageSplit(
                totalAmount: totalAmt,
                participants: pctList,
                payerName: payerName
            )
        }

        isSubmitting = true
        errorMessage = nil

        do {
            let timestamp = Int64(selectedDate.timeIntervalSince1970 * 1000)
            try await onSave(
                trimmedTitle,
                totalAmt,
                timestamp,
                selectedCategoryId,
                payerName,
                methodCode,
                selectedPaymentMethod,
                addToTransactions,
                participants
            )
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }

        isSubmitting = false
    }
}

/// Simple flow layout helper for participant tags.
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? 0
        var height: CGFloat = 0
        var x: CGFloat = 0
        var y: CGFloat = 0
        var maxHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > width && x > 0 {
                x = 0
                y += maxHeight + spacing
                maxHeight = 0
            }
            maxHeight = max(maxHeight, size.height)
            x += size.width + spacing
        }
        height = y + maxHeight
        return CGSize(width: width, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var maxHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX && x > bounds.minX {
                x = bounds.minX
                y += maxHeight + spacing
                maxHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            maxHeight = max(maxHeight, size.height)
            x += size.width + spacing
        }
    }
}

