import SwiftUI

/// Dedicated native iOS detail view for a specific Travel Wallet.
/// Displays expenditures in the foreign destination currency alongside primary currency equivalents,
/// budget tracking, category spending distributions, and an integrated ledger of wallet transactions.
public struct TravelWalletDetailView: View {
    @Environment(AppContainer.self) private var container
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss

    public let walletId: Int64

    @State private var summary: TravelWalletSummary? = nil
    @State private var transactions: [Transaction] = []
    @State private var categories: [Category] = []
    @State private var primaryCurrency: Currency = .default
    @State private var isLoading: Bool = true
    @State private var errorMessage: String? = nil

    // Sheets & Dialogs
    @State private var isAddExpenseSheetPresented: Bool = false
    @State private var isEditSheetPresented: Bool = false
    @State private var showDeleteConfirmation: Bool = false
    @State private var transactionToEdit: Transaction? = nil

    public init(walletId: Int64) {
        self.walletId = walletId
    }

    public var body: some View {
        ZStack {
            LeafTheme.canvas(for: colorScheme).ignoresSafeArea()

            if let s = summary {
                ScrollView {
                    VStack(spacing: 20) {
                        // 1. Hero Card
                        walletHeroCard(s)

                        // 2. Add Expense Quick CTA Banner
                        addExpenseBanner(s)

                        // 3. Category Breakdown (if any expenses)
                        if !s.categorySpendings.isEmpty {
                            categoryBreakdownSection(s)
                        }

                        // 4. Wallet Transactions Ledger
                        transactionsSection(s)

                        Spacer(minLength: 32)
                    }
                    .padding(.top, 8)
                }
                .refreshable {
                    await loadData()
                }
            } else if isLoading {
                ProgressView().tint(LeafTheme.brandEmerald)
            } else {
                EmptyStateCard(
                    icon: "airplane.circle",
                    title: "Wallet Not Found",
                    message: "The requested travel wallet could not be loaded."
                )
            }
        }
        .navigationTitle(summary?.wallet.name ?? "Travel Wallet")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        isEditSheetPresented = true
                    } label: {
                        Label("Edit Wallet", systemImage: "pencil")
                    }

                    Button {
                        Task {
                            if let w = summary?.wallet {
                                _ = try? await container.saveTravelWalletUseCase.execute(
                                    id: w.id,
                                    name: w.name,
                                    currencyCode: w.currencyCode,
                                    budgetAmount: w.budgetAmount,
                                    note: w.note,
                                    colorHex: w.colorHex,
                                    iconName: w.iconName,
                                    isArchived: !w.isArchived
                                )
                                await loadData()
                            }
                        }
                    } label: {
                        Label(
                            summary?.wallet.isArchived == true ? "Unarchive Wallet" : "Archive Wallet",
                            systemImage: "archivebox"
                        )
                    }

                    Button(role: .destructive) {
                        showDeleteConfirmation = true
                    } label: {
                        Label("Delete Wallet", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.system(size: 17))
                        .foregroundStyle(LeafTheme.textPrimary(for: colorScheme))
                }
            }
        }
        .task {
            await loadData()
        }
        // Sheet: Add Expense to this Wallet
        .sheet(isPresented: $isAddExpenseSheetPresented) {
            if let s = summary {
                AddEditExpenseSheet(
                    transaction: nil,
                    currency: s.wallet.currency,
                    categories: categories,
                    onSaveWithReceipt: { amt, catId, method, note, timestamp, receiptPath in
                        // Look up rate between wallet currency and primary currency
                        let rateObj = try? await container.exchangeRateRepository.getExchangeRate(
                            from: s.wallet.currencyCode,
                            to: primaryCurrency.code
                        )
                        let rate = rateObj?.rate ?? CurrencyConverter.estimatedRate(
                            from: s.wallet.currencyCode,
                            to: primaryCurrency.code
                        )
                        let primaryAmt = CurrencyConverter.convert(
                            amount: amt,
                            from: s.wallet.currency,
                            to: primaryCurrency,
                            rate: rate
                        )

                        _ = try await container.addTransactionUseCase.execute(
                            amount: primaryAmt,
                            type: .expense,
                            categoryId: catId,
                            paymentMethod: method,
                            note: note,
                            timestamp: timestamp,
                            receiptImagePath: receiptPath,
                            originalAmount: amt,
                            currencyCode: s.wallet.currencyCode,
                            exchangeRate: rate,
                            exchangeRateDate: timestamp,
                            exchangeRateSource: "WALLET_RATE",
                            travelWalletId: walletId
                        )
                        await loadData()
                    }
                )
            }
        }
        // Sheet: Edit Wallet Configuration
        .sheet(isPresented: $isEditSheetPresented) {
            if let w = summary?.wallet {
                CreateEditTravelWalletSheet(
                    existingWallet: w,
                    onSave: { name, curr, budget, note, color, icon in
                        _ = try? await container.saveTravelWalletUseCase.execute(
                            id: w.id,
                            name: name,
                            currencyCode: curr,
                            budgetAmount: budget,
                            note: note,
                            colorHex: color,
                            iconName: icon,
                            isArchived: w.isArchived
                        )
                        await loadData()
                        return true
                    }
                )
            }
        }
        // Confirmation dialog for wallet deletion
        .confirmationDialog(
            "Delete Travel Wallet?",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete Wallet", role: .destructive) {
                Task {
                    try? await container.deleteTravelWalletUseCase.execute(id: walletId)
                    dismiss()
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to delete this wallet? Its historical financial transactions will be preserved safely.")
        }
    }

    // MARK: - 1. Wallet Hero Card

    private func walletHeroCard(_ s: TravelWalletSummary) -> some View {
        SquircleCard(cornerRadius: 22) {
            VStack(spacing: 16) {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Color(hex: s.wallet.colorHex).opacity(0.18))
                            .frame(width: 52, height: 52)

                        Image(systemName: s.wallet.iconName)
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundStyle(Color(hex: s.wallet.colorHex))
                    }

                    VStack(alignment: .leading, spacing: 3) {
                        Text(s.wallet.name)
                            .font(LeafTypography.titleMedium)
                            .foregroundStyle(LeafTheme.textPrimary(for: colorScheme))

                        HStack(spacing: 6) {
                            Text(s.wallet.currencyCode)
                                .font(LeafTypography.captionBold)
                                .foregroundStyle(LeafTheme.brandEmerald)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Capsule().fill(LeafTheme.brandEmerald.opacity(0.12)))

                            if let note = s.wallet.note, !note.isEmpty {
                                Text(note)
                                    .font(LeafTypography.captionRegular)
                                    .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
                                    .lineLimit(1)
                            }
                        }
                    }

                    Spacer()
                }

                Divider()
                    .background(LeafTheme.cardBorder(for: colorScheme))

                // Spending Numbers
                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("TOTAL SPENT (\(s.wallet.currencyCode))")
                            .font(LeafTypography.captionBold)
                            .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
                            .tracking(0.5)

                        Text(s.totalSpentInWalletCurrency.format(currency: s.wallet.currency))
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundStyle(LeafTheme.textPrimary(for: colorScheme))
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 4) {
                        Text("PRIMARY EQUIVALENT")
                            .font(LeafTypography.captionBold)
                            .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
                            .tracking(0.5)

                        Text("~ \(s.totalSpentInPrimaryCurrency.format(currency: primaryCurrency))")
                            .font(LeafTypography.headline)
                            .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
                    }
                }

                // Budget Bar (if budget is set)
                if let budget = s.wallet.budgetAmount, budget.subunits > 0 {
                    let progress = s.budgetProgressRatio ?? 0.0
                    VStack(spacing: 6) {
                        HStack {
                            Text("Budget Progress")
                                .font(LeafTypography.captionRegular)
                                .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
                            Spacer()
                            Text("\(Int(min(progress, 1.0) * 100))% of \(budget.format(currency: s.wallet.currency))")
                                .font(LeafTypography.captionBold)
                                .foregroundStyle(progress > 1.0 ? LeafTheme.expenseCoral : LeafTheme.brandEmerald)
                        }

                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule()
                                    .fill(colorScheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(0.08))
                                    .frame(height: 8)

                                Capsule()
                                    .fill(progress > 1.0 ? LeafTheme.expenseCoral : LeafTheme.brandEmerald)
                                    .frame(width: min(geo.size.width * CGFloat(progress), geo.size.width), height: 8)
                            }
                        }
                        .frame(height: 8)
                    }
                }
            }
            .padding(18)
        }
        .padding(.horizontal)
    }

    // MARK: - 2. Add Expense Banner

    private func addExpenseBanner(_ s: TravelWalletSummary) -> some View {
        Button(action: { isAddExpenseSheetPresented = true }) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(LeafTheme.brandEmerald.opacity(0.14))
                        .frame(width: 40, height: 40)

                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(LeafTheme.brandEmerald)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Add Expense in \(s.wallet.currencyCode)")
                        .font(LeafTypography.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(LeafTheme.textPrimary(for: colorScheme))

                    Text("Auto-converts to \(primaryCurrency.code) at stored rate snapshot")
                        .font(LeafTypography.captionRegular)
                        .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(LeafTheme.textTertiary(for: colorScheme))
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(colorScheme == .dark ? LeafTheme.cardDark : LeafTheme.cardLight)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(LeafTheme.brandEmerald.opacity(0.35), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .padding(.horizontal)
    }

    // MARK: - 3. Category Breakdown

    private func categoryBreakdownSection(_ s: TravelWalletSummary) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("SPENDING BY CATEGORY")
                .font(LeafTypography.captionBold)
                .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
                .tracking(0.5)
                .padding(.horizontal)

            SquircleCard(cornerRadius: 18) {
                VStack(spacing: 12) {
                    ForEach(s.categorySpendings) { item in
                        HStack(spacing: 10) {
                            CategoryIconBadge(
                                iconName: item.category.iconName,
                                colorHex: item.category.colorHex,
                                size: 28
                            )

                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.category.name)
                                    .font(LeafTypography.bodyMedium)
                                    .foregroundStyle(LeafTheme.textPrimary(for: colorScheme))

                                Text(String(format: "%.1f%% of trip spending", item.percentage))
                                    .font(LeafTypography.captionRegular)
                                    .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
                            }

                            Spacer()

                            Text(item.amount.format(currency: s.wallet.currency))
                                .font(LeafTypography.headline)
                                .foregroundStyle(LeafTheme.textPrimary(for: colorScheme))
                        }
                    }
                }
                .padding(16)
            }
            .padding(.horizontal)
        }
    }

    // MARK: - 4. Transactions Section

    private func transactionsSection(_ s: TravelWalletSummary) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("WALLET TRANSACTIONS")
                    .font(LeafTypography.captionBold)
                    .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
                    .tracking(0.5)

                Spacer()

                Text("\(transactions.count) \(transactions.count == 1 ? "expense" : "expenses")")
                    .font(LeafTypography.captionRegular)
                    .foregroundStyle(LeafTheme.textTertiary(for: colorScheme))
            }
            .padding(.horizontal)

            if transactions.isEmpty {
                EmptyStateCard(
                    icon: "creditcard",
                    title: "No Expenses Logged",
                    message: "Tap '+ Add Expense in \(s.wallet.currencyCode)' to log your first travel expense."
                )
                .padding(.horizontal)
            } else {
                LazyVStack(spacing: 10) {
                    ForEach(transactions) { tx in
                        walletTransactionRow(tx, walletCurrency: s.wallet.currency)
                            .padding(.horizontal)
                    }
                }
            }
        }
    }

    private func walletTransactionRow(_ tx: Transaction, walletCurrency: Currency) -> some View {
        HStack(spacing: 12) {
            if let cat = tx.category {
                CategoryIconBadge(iconName: cat.iconName, colorHex: cat.colorHex, size: 36)
            } else {
                Circle()
                    .fill(Color.gray.opacity(0.15))
                    .frame(width: 36, height: 36)
                    .overlay(Image(systemName: "tag").font(.system(size: 14)))
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(tx.note?.isEmpty == false ? tx.note! : (tx.category?.name ?? "Expense"))
                    .font(LeafTypography.bodyMedium)
                    .foregroundStyle(LeafTheme.textPrimary(for: colorScheme))
                    .lineLimit(1)

                Text(Date(timeIntervalSince1970: Double(tx.timestamp) / 1000.0).formatted(date: .abbreviated, time: .shortened))
                    .font(LeafTypography.captionRegular)
                    .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                // Original amount in wallet currency
                Text(tx.originalAmount.format(currency: walletCurrency))
                    .font(LeafTypography.headline)
                    .foregroundStyle(LeafTheme.expenseCoral)

                // Converted primary equivalent
                if !tx.isPrimaryCurrency(primaryCode: primaryCurrency.code) {
                    Text("~ \(tx.amount.format(currency: primaryCurrency))")
                        .font(LeafTypography.captionRegular)
                        .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
                }
            }
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

    // MARK: - Data Loading

    @MainActor
    private func loadData() async {
        isLoading = true
        errorMessage = nil

        do {
            let prefs = container.preferencesRepository.getUserPreferences()
            self.primaryCurrency = Currency.fromCode(prefs.currencyCode)
            self.categories = try await container.categoryRepository.getAllCategories()
            self.summary = try await container.getTravelWalletsUseCase.getWalletSummary(id: walletId)
            self.transactions = try await container.transactionRepository.getTransactionsForWallet(walletId: walletId)
        } catch {
            self.errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}

