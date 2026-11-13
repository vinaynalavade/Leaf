import SwiftUI

/// Polished native iOS sheet for adding or editing an Expense transaction.
/// Fully supports multi-currency travel spending: entry in 11 global currencies,
/// live exchange rate display and inline editing, converted primary-currency equivalent preview,
/// optional travel wallet assignment, and Apple Vision on-device receipt scanning.
public struct AddEditExpenseSheet: View {
    @Environment(AppContainer.self) private var container
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    public typealias FullSaveHandler = (
        _ primaryAmount: Amount,
        _ categoryId: Int64,
        _ paymentMethod: PaymentMethod,
        _ note: String?,
        _ timestamp: Int64,
        _ receiptImagePath: String?,
        _ originalAmount: Amount,
        _ currencyCode: String,
        _ exchangeRate: Double,
        _ travelWalletId: Int64?
    ) async throws -> Void

    public let transaction: Transaction?
    public let currency: Currency
    public let categories: [Category]
    public let initialTravelWalletId: Int64?
    public let onSaveFull: FullSaveHandler?
    public let onSaveSimple: ((Amount, Int64, PaymentMethod, String?, Int64, String?) async throws -> Void)?
    public let onDelete: ((Int64) async -> Void)?

    // MARK: - State
    @State private var amountInput: String = ""
    @State private var selectedCategoryId: Int64 = 1
    @State private var selectedPaymentMethod: PaymentMethod = .cash
    @State private var note: String = ""
    @State private var selectedDate: Date = Date()
    @State private var receiptImagePath: String? = nil

    // Multi-Currency & Travel Wallet State
    @State private var primaryCurrency: Currency = .default
    @State private var selectedCurrency: Currency = .default
    @State private var exchangeRate: Double = 1.0
    @State private var selectedWalletId: Int64? = nil
    @State private var availableWallets: [TravelWallet] = []
    @State private var isEditingRateSheetPresented: Bool = false
    @State private var customRateInput: String = ""
    @State private var showCustomRateInline: Bool = false

    // Presentation & Errors
    @State private var isSubmitting: Bool = false
    @State private var errorMessage: String? = nil
    @State private var showDeleteConfirmation: Bool = false
    @State private var isScanReceiptPresented: Bool = false
    @State private var previewReceiptImage: UIImage? = nil

    // Standard Initializer (Phase 1-8 compatibility)
    public init(
        transaction: Transaction? = nil,
        currency: Currency = .default,
        categories: [Category],
        onSave: @escaping (Amount, Int64, PaymentMethod, String?, Int64) async throws -> Void,
        onDelete: ((Int64) async -> Void)? = nil
    ) {
        self.transaction = transaction
        self.currency = currency
        self.categories = categories.filter { $0.type == .expense }
        self.initialTravelWalletId = transaction?.travelWalletId
        self.onSaveFull = nil
        self.onSaveSimple = { amt, catId, method, note, timestamp, _ in
            try await onSave(amt, catId, method, note, timestamp)
        }
        self.onDelete = onDelete
        self._selectedCurrency = State(initialValue: transaction?.originalCurrency ?? currency)
    }

    // Receipt Initializer (Phase 11 compatibility)
    public init(
        transaction: Transaction? = nil,
        currency: Currency = .default,
        categories: [Category],
        onSaveWithReceipt: @escaping (Amount, Int64, PaymentMethod, String?, Int64, String?) async throws -> Void,
        onDelete: ((Int64) async -> Void)? = nil
    ) {
        self.transaction = transaction
        self.currency = currency
        self.categories = categories.filter { $0.type == .expense }
        self.initialTravelWalletId = transaction?.travelWalletId
        self.onSaveFull = nil
        self.onSaveSimple = onSaveWithReceipt
        self.onDelete = onDelete
        self._selectedCurrency = State(initialValue: transaction?.originalCurrency ?? currency)
    }

    // Multi-Currency Full Initializer (Phase 12)
    public init(
        transaction: Transaction? = nil,
        currency: Currency = .default,
        categories: [Category],
        initialTravelWalletId: Int64? = nil,
        onSaveWithCurrency: @escaping FullSaveHandler,
        onDelete: ((Int64) async -> Void)? = nil
    ) {
        self.transaction = transaction
        self.currency = currency
        self.categories = categories.filter { $0.type == .expense }
        self.initialTravelWalletId = initialTravelWalletId ?? transaction?.travelWalletId
        self.onSaveFull = onSaveWithCurrency
        self.onSaveSimple = nil
        self.onDelete = onDelete
        self._selectedCurrency = State(initialValue: transaction?.originalCurrency ?? currency)
    }

    private var isEditMode: Bool {
        transaction != nil
    }

    private var isForeignCurrency: Bool {
        selectedCurrency.code.uppercased() != primaryCurrency.code.uppercased()
    }

    private var enteredAmount: Amount? {
        Amount.fromStringOrNull(amountInput, currency: selectedCurrency)
    }

    private var calculatedPrimaryAmount: Amount {
        guard let entered = enteredAmount else { return Amount(subunits: 0) }
        if !isForeignCurrency {
            return entered
        }
        return CurrencyConverter.convert(
            amount: entered,
            from: selectedCurrency,
            to: primaryCurrency,
            rate: exchangeRate
        )
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                LeafTheme.canvas(for: colorScheme).ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // Error Banner if present
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

                        // 1. Scan Receipt Action Banner (in creation mode)
                        if !isEditMode {
                            scanReceiptBanner
                        }

                        // 2. Attached Receipt Card (in edit mode if receipt exists)
                        if isEditMode, let path = receiptImagePath,
                           let image = ReceiptStorageService.shared.loadReceiptImage(path: path) {
                            attachedReceiptCard(image: image)
                        }

                        // 3. Amount & Currency Selector Hero Field
                        amountHeroCard

                        // 4. Foreign Exchange Details & Primary Preview (when foreign)
                        if isForeignCurrency {
                            foreignExchangeInfoCard
                        }

                        // 5. Travel Wallet Assignment (Optional)
                        if !availableWallets.isEmpty {
                            travelWalletSelectorCard
                        }

                        // 6. Category Selector Chips
                        VStack(alignment: .leading, spacing: 10) {
                            Text("CATEGORY")
                                .font(LeafTypography.captionBold)
                                .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
                                .padding(.horizontal)
                                .tracking(0.5)

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 10) {
                                    ForEach(categories) { cat in
                                        let isSelected = cat.id == selectedCategoryId
                                        Button(action: { selectedCategoryId = cat.id }) {
                                            HStack(spacing: 6) {
                                                CategoryIconBadge(
                                                    iconName: cat.iconName,
                                                    colorHex: cat.colorHex,
                                                    size: 24
                                                )
                                                Text(cat.name)
                                                    .font(.system(size: 13, weight: .medium, design: .rounded))
                                                    .foregroundStyle(isSelected ? LeafTheme.brandEmerald : LeafTheme.textPrimary(for: colorScheme))
                                            }
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 8)
                                            .background(
                                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                                    .fill(isSelected ? LeafTheme.brandEmerald.opacity(0.12) : (colorScheme == .dark ? LeafTheme.cardDark : LeafTheme.cardLight))
                                            )
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                                    .stroke(isSelected ? LeafTheme.brandEmerald : LeafTheme.cardBorder(for: colorScheme), lineWidth: 1)
                                            )
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }

                        // 7. Payment Method & Date Picker
                        SquircleCard(cornerRadius: 18) {
                            VStack(spacing: 16) {
                                HStack {
                                    Text("Payment Method")
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

                                Divider()
                                    .background(LeafTheme.cardBorder(for: colorScheme))

                                DatePicker(
                                    "Date & Time",
                                    selection: $selectedDate,
                                    displayedComponents: [.date, .hourAndMinute]
                                )
                                .font(LeafTypography.bodyMedium)
                                .foregroundStyle(LeafTheme.textPrimary(for: colorScheme))
                            }
                            .padding(16)
                        }
                        .padding(.horizontal)

                        // 8. Note Field
                        SquircleCard(cornerRadius: 18) {
                            HStack {
                                Image(systemName: "note.text")
                                    .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))

                                TextField("Note (e.g. Sushi dinner in Shibuya)", text: $note)
                                    .font(LeafTypography.bodyMedium)
                                    .foregroundStyle(LeafTheme.textPrimary(for: colorScheme))
                            }
                            .padding(16)
                        }
                        .padding(.horizontal)

                        // 9. Delete Button (in edit mode only)
                        if isEditMode, let tx = transaction, onDelete != nil {
                            Button(role: .destructive, action: { showDeleteConfirmation = true }) {
                                HStack(spacing: 6) {
                                    Image(systemName: "trash")
                                    Text("Delete Expense")
                                }
                                .font(LeafTypography.headline)
                                .foregroundStyle(LeafTheme.expenseCoral)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .fill(LeafTheme.expenseCoral.opacity(0.1))
                                )
                            }
                            .padding(.horizontal)
                            .padding(.top, 8)
                            .confirmationDialog(
                                "Delete Expense?",
                                isPresented: $showDeleteConfirmation,
                                titleVisibility: .visible
                            ) {
                                Button("Delete Expense", role: .destructive) {
                                    Task {
                                        await onDelete?(tx.id)
                                        dismiss()
                                    }
                                }
                                Button("Cancel", role: .cancel) {}
                            } message: {
                                Text("Are you sure you want to delete this expense? This action cannot be undone.")
                            }
                        }

                        Spacer(minLength: 24)
                    }
                    .padding(.top, 12)
                }
            }
            .navigationTitle(isEditMode ? "Edit Expense" : "New Expense")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(isEditMode ? "Update" : "Save") {
                        Task { await submit() }
                    }
                    .foregroundStyle(LeafTheme.brandEmerald)
                    .fontWeight(.bold)
                    .disabled(isSubmitting)
                }
            }
            .sheet(isPresented: $isScanReceiptPresented) {
                ReceiptScannerSheet(
                    processReceiptImageUseCase: container.processReceiptImageUseCase,
                    addTransactionUseCase: container.addTransactionUseCase,
                    currency: selectedCurrency,
                    categories: categories,
                    onSaveComplete: {
                        dismiss()
                    }
                )
            }
            .sheet(item: Binding<IdentifiableImage?>(
                get: { previewReceiptImage.map { IdentifiableImage(image: $0) } },
                set: { previewReceiptImage = $0?.image }
            )) { wrapper in
                NavigationStack {
                    ZStack {
                        Color.black.ignoresSafeArea()
                        Image(uiImage: wrapper.image)
                            .resizable()
                            .scaledToFit()
                            .padding()
                    }
                    .navigationTitle("Attached Receipt")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Done") { previewReceiptImage = nil }
                                .foregroundStyle(.white)
                        }
                    }
                }
            }
            .task {
                await setupInitialData()
            }
        }
    }

    // MARK: - Subviews

    @ViewBuilder
    private var amountHeroCard: some View {
        SquircleCard(cornerRadius: 22) {
            VStack(spacing: 8) {
                HStack {
                    Text("AMOUNT")
                        .font(LeafTypography.captionBold)
                        .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
                        .tracking(0.5)

                    Spacer()

                    // Currency Selector Menu
                    Menu {
                        Section("Primary Currency") {
                            Button {
                                switchCurrency(to: primaryCurrency)
                            } label: {
                                HStack {
                                    Text("\(primaryCurrency.symbol)  \(primaryCurrency.code) (Primary)")
                                    if selectedCurrency.code == primaryCurrency.code {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }

                        Section("Foreign Currencies") {
                            ForEach(Currency.supportedCurrencies.filter { $0.code != primaryCurrency.code }) { curr in
                                Button {
                                    switchCurrency(to: curr)
                                } label: {
                                    HStack {
                                        Text("\(curr.symbol)  \(curr.name) (\(curr.code))")
                                        if selectedCurrency.code == curr.code {
                                            Image(systemName: "checkmark")
                                        }
                                    }
                                }
                            }
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Text(selectedCurrency.code)
                                .font(LeafTypography.captionBold)
                            Image(systemName: "chevron.up.chevron.down")
                                .font(.system(size: 10, weight: .bold))
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(
                            isForeignCurrency
                                ? LeafTheme.brandEmerald.opacity(0.18)
                                : LeafTheme.surface(for: colorScheme)
                        )
                        .foregroundStyle(
                            isForeignCurrency
                                ? LeafTheme.brandEmerald
                                : LeafTheme.textPrimary(for: colorScheme)
                        )
                        .clipShape(Capsule())
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 4)

                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(selectedCurrency.symbol)
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(LeafTheme.expenseCoral)

                    TextField("0.00", text: $amountInput)
                        .font(.system(size: 40, weight: .bold, design: .rounded).monospacedDigit())
                        .keyboardType(.decimalPad)
                        .foregroundStyle(LeafTheme.textPrimary(for: colorScheme))
                }
                .padding(.horizontal, 16)

                // Quick Amount Increments
                HStack(spacing: 8) {
                    quickIncrementButton(amount: 50)
                    quickIncrementButton(amount: 100)
                    quickIncrementButton(amount: 500)
                    quickIncrementButton(amount: 1000)
                }
                .padding(.top, 4)
            }
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity)
        }
        .padding(.horizontal)
    }

    @ViewBuilder
    private var foreignExchangeInfoCard: some View {
        SquircleCard(cornerRadius: 18) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Image(systemName: "arrow.triangle.swap")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(LeafTheme.brandEmerald)

                    Text("EXCHANGE RATE & CONVERSION")
                        .font(LeafTypography.captionBold)
                        .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))

                    Spacer()

                    Button {
                        customRateInput = String(format: "%.4f", exchangeRate)
                        showCustomRateInline.toggle()
                    } label: {
                        HStack(spacing: 3) {
                            Image(systemName: "pencil")
                                .font(.system(size: 10, weight: .bold))
                            Text(showCustomRateInline ? "Close" : "Edit Rate")
                                .font(.system(size: 11, weight: .semibold))
                        }
                        .foregroundStyle(LeafTheme.brandEmerald)
                    }
                }

                HStack(alignment: .center) {
                    Text("1 \(selectedCurrency.code) = \(String(format: "%.4f", exchangeRate)) \(primaryCurrency.code)")
                        .font(LeafTypography.bodyBold)
                        .foregroundStyle(LeafTheme.textPrimary(for: colorScheme))

                    Spacer()

                    Text("≈ \(calculatedPrimaryAmount.formatted(currency: primaryCurrency))")
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundStyle(LeafTheme.brandEmerald)
                }

                if showCustomRateInline {
                    HStack(spacing: 8) {
                        Text("Custom Rate:")
                            .font(LeafTypography.caption)
                            .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))

                        TextField("Rate", text: $customRateInput)
                            .font(LeafTypography.captionBold)
                            .keyboardType(.decimalPad)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 100)

                        Button("Apply") {
                            if let r = Double(customRateInput.replacingOccurrences(of: ",", with: ".")), r > 0 {
                                exchangeRate = r
                                showCustomRateInline = false
                            }
                        }
                        .font(LeafTypography.captionBold)
                        .foregroundStyle(LeafTheme.brandEmerald)
                    }
                    .padding(.top, 4)
                }
            }
            .padding(14)
        }
        .padding(.horizontal)
    }

    @ViewBuilder
    private var travelWalletSelectorCard: some View {
        SquircleCard(cornerRadius: 18) {
            HStack(spacing: 12) {
                Image(systemName: "airplane.departure")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(LeafTheme.brandEmerald)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Travel Wallet / Trip")
                        .font(LeafTypography.bodyMedium)
                        .foregroundStyle(LeafTheme.textPrimary(for: colorScheme))

                    if let wid = selectedWalletId, let matched = availableWallets.first(where: { $0.id == wid }) {
                        Text("\(matched.name) (\(matched.currencyCode))")
                            .font(LeafTypography.captionBold)
                            .foregroundStyle(LeafTheme.brandEmerald)
                    } else {
                        Text("None (General Expense)")
                            .font(LeafTypography.caption)
                            .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
                    }
                }

                Spacer()

                Menu {
                    Button("None (General Expense)") {
                        selectedWalletId = nil
                    }

                    Divider()

                    ForEach(availableWallets) { wallet in
                        Button {
                            selectedWalletId = wallet.id
                            // Switch currency to wallet currency automatically
                            switchCurrency(to: wallet.currency)
                        } label: {
                            HStack {
                                Text("\(wallet.name) (\(wallet.currencyCode))")
                                if selectedWalletId == wallet.id {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(selectedWalletId != nil ? "Change" : "Assign")
                            .font(LeafTypography.captionBold)
                        Image(systemName: "chevron.up.chevron.down")
                            .font(.system(size: 10, weight: .bold))
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(LeafTheme.surface(for: colorScheme))
                    .foregroundStyle(LeafTheme.brandEmerald)
                    .clipShape(Capsule())
                }
            }
            .padding(14)
        }
        .padding(.horizontal)
    }

    @ViewBuilder
    private var scanReceiptBanner: some View {
        Button(action: { isScanReceiptPresented = true }) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(LeafTheme.brandEmerald.opacity(0.14))
                        .frame(width: 42, height: 42)

                    Image(systemName: "doc.text.viewfinder")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(LeafTheme.brandEmerald)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Scan Receipt with Camera")
                        .font(LeafTypography.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(LeafTheme.textPrimary(for: colorScheme))

                    Text("Auto-detect store, total & date on-device")
                        .font(LeafTypography.captionRegular)
                        .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
                }

                Spacer()

                HStack(spacing: 4) {
                    Text("Scan")
                        .font(LeafTypography.captionBold)
                        .foregroundStyle(LeafTheme.brandEmerald)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(LeafTheme.brandEmerald)
                }
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(colorScheme == .dark ? LeafTheme.cardDark : LeafTheme.cardLight)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(LeafTheme.brandEmerald.opacity(0.4), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .padding(.horizontal)
    }

    @ViewBuilder
    private func attachedReceiptCard(image: UIImage) -> some View {
        SquircleCard(cornerRadius: 18) {
            HStack(spacing: 12) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 48, height: 48)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(LeafTheme.cardBorder(for: colorScheme), lineWidth: 0.75)
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text("Attached Receipt")
                        .font(LeafTypography.subheadline)
                        .foregroundStyle(LeafTheme.textPrimary(for: colorScheme))

                    Text("Saved securely on-device")
                        .font(LeafTypography.captionRegular)
                        .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
                }

                Spacer()

                Button("View") {
                    previewReceiptImage = image
                }
                .font(LeafTypography.captionBold)
                .foregroundStyle(LeafTheme.brandEmerald)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    Capsule().fill(LeafTheme.brandEmerald.opacity(0.12))
                )
            }
            .padding(14)
        }
        .padding(.horizontal)
    }

    @ViewBuilder
    private func quickIncrementButton(amount: Int) -> some View {
        Button(action: {
            let current = Double(amountInput.replacingOccurrences(of: ",", with: ".")) ?? 0.0
            let updated = current + Double(amount)
            if selectedCurrency.decimalDigits == 0 {
                amountInput = "\(Int(updated))"
            } else {
                amountInput = String(format: "%.2f", updated)
            }
        }) {
            Text("+\(amount)")
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundStyle(LeafTheme.brandEmerald)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(LeafTheme.brandEmerald.opacity(0.12))
                )
        }
    }

    // MARK: - Actions & Loading

    private func setupInitialData() async {
        let prefs = container.preferencesRepository.getUserPreferences()
        self.primaryCurrency = Currency.fromCode(prefs.currencyCode)

        // Load active travel wallets
        if let wallets = try? await container.travelWalletRepository.getAllWallets() {
            self.availableWallets = wallets.filter { !$0.isArchived }
        }

        if let tx = transaction {
            self.selectedCurrency = tx.originalCurrency
            self.selectedWalletId = tx.travelWalletId
            self.exchangeRate = tx.exchangeRate
            self.amountInput = tx.originalAmount.toInputString(currency: tx.originalCurrency)
            self.selectedCategoryId = tx.categoryId
            self.selectedPaymentMethod = tx.paymentMethod
            self.note = tx.note ?? ""
            self.selectedDate = Date(timeIntervalSince1970: Double(tx.timestamp) / 1000.0)
            self.receiptImagePath = tx.receiptImagePath
        } else {
            let prefs = container.preferencesRepository.getUserPreferences()
            self.selectedPaymentMethod = prefs.defaultTransactionSource
            let initialCat = categories.first(where: { $0.type == .expense })?.id ?? 1
            self.selectedCategoryId = initialCat
            self.selectedWalletId = initialTravelWalletId

            if let wid = initialTravelWalletId, let matched = availableWallets.first(where: { $0.id == wid }) {
                self.selectedCurrency = matched.currency
            } else {
                self.selectedCurrency = primaryCurrency
            }
            await fetchRateForCurrentCurrency()
        }
    }

    private func switchCurrency(to newCurrency: Currency) {
        self.selectedCurrency = newCurrency
        Task {
            await fetchRateForCurrentCurrency()
        }
    }

    private func fetchRateForCurrentCurrency() async {
        if selectedCurrency.code.uppercased() == primaryCurrency.code.uppercased() {
            self.exchangeRate = 1.0
            return
        }

        let rateObj = try? await container.exchangeRateRepository.getExchangeRate(
            from: selectedCurrency.code,
            to: primaryCurrency.code
        )
        self.exchangeRate = rateObj?.rate ?? CurrencyConverter.estimatedRate(
            from: selectedCurrency.code,
            to: primaryCurrency.code
        )
    }

    private func submit() async {
        guard let entered = enteredAmount, entered.subunits > 0 else {
            errorMessage = "Please enter an amount greater than zero."
            return
        }

        guard selectedCategoryId > 0 else {
            errorMessage = "Please choose a valid category."
            return
        }

        isSubmitting = true
        errorMessage = nil

        do {
            let timestamp = Int64(selectedDate.timeIntervalSince1970 * 1000)
            let trimmedNote = note.trimmingCharacters(in: .whitespacesAndNewlines)
            let finalNote = trimmedNote.isEmpty ? nil : trimmedNote

            let primaryAmt = calculatedPrimaryAmount
            let origAmt = entered
            let currCode = selectedCurrency.code
            let rate = exchangeRate
            let walletId = selectedWalletId

            if let saveFull = onSaveFull {
                try await saveFull(
                    primaryAmt,
                    selectedCategoryId,
                    selectedPaymentMethod,
                    finalNote,
                    timestamp,
                    receiptImagePath,
                    origAmt,
                    currCode,
                    rate,
                    walletId
                )
            } else if let saveSimple = onSaveSimple {
                try await saveSimple(
                    primaryAmt,
                    selectedCategoryId,
                    selectedPaymentMethod,
                    finalNote,
                    timestamp,
                    receiptImagePath
                )
            }

            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }

        isSubmitting = false
    }
}

/// Identifiable wrapper for presenting UIImage in a sheet.
private struct IdentifiableImage: Identifiable {
    let id = UUID()
    let image: UIImage
}
