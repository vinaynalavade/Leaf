import SwiftUI

/// Executive hub presenting separate Cash and Account ledgers,
/// independent balance calculations, transaction histories, and transfer workflow.
public struct LedgersHubView: View {
    @Environment(AppContainer.self) private var container
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss

    public enum LedgerFilter: String, CaseIterable, Identifiable {
        case all = "All Ledgers"
        case cash = "Cash"
        case account = "Account"

        public var id: String { rawValue }
    }

    @State private var selectedFilter: LedgerFilter = .all
    @State private var cashBalance: Amount = .zero
    @State private var accountBalance: Amount = .zero
    @State private var cashInflow: Amount = .zero
    @State private var cashOutflow: Amount = .zero
    @State private var accountInflow: Amount = .zero
    @State private var accountOutflow: Amount = .zero
    @State private var cashTransactions: [Transaction] = []
    @State private var accountTransactions: [Transaction] = []
    @State private var allTransactions: [Transaction] = []
    @State private var currency: Currency = .default
    @State private var isLoading: Bool = true
    @State private var isTransferSheetPresented: Bool = false
    @State private var selectedTransactionForEdit: Transaction? = nil

    public init() {}

    private var combinedBalance: Amount {
        cashBalance + accountBalance
    }

    private var displayedTransactions: [Transaction] {
        switch selectedFilter {
        case .all: return allTransactions
        case .cash: return cashTransactions
        case .account: return accountTransactions
        }
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                LeafTheme.canvas(for: colorScheme).ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // 1. Combined Net Worth Header
                        SquircleCard(cornerRadius: 24) {
                            VStack(spacing: 8) {
                                Text("COMBINED LIQUID BALANCE")
                                    .font(LeafTypography.captionBold)
                                    .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
                                    .tracking(0.5)

                                Text(combinedBalance.format(currency: currency, includeSymbol: true))
                                    .font(.system(size: 34, weight: .bold, design: .rounded))
                                    .foregroundStyle(LeafTheme.brandEmerald)

                                Text("Strict single-source of truth without double counting")
                                    .font(LeafTypography.captionRegular)
                                    .foregroundStyle(LeafTheme.textTertiary(for: colorScheme))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                        }
                        .padding(.horizontal)
                        .padding(.top, 8)

                        // 2. Separate Ledger Cards Grid (Cash & Account)
                        HStack(spacing: 12) {
                            // Cash Ledger Card
                            ledgerSummaryCard(
                                title: "Cash Ledger",
                                icon: "banknote.fill",
                                color: LeafTheme.brandEmerald,
                                balance: cashBalance,
                                inflow: cashInflow,
                                outflow: cashOutflow,
                                txCount: cashTransactions.count
                            )

                            // Account Ledger Card
                            ledgerSummaryCard(
                                title: "Account Ledger",
                                icon: "creditcard.fill",
                                color: LeafTheme.accent(for: colorScheme),
                                balance: accountBalance,
                                inflow: accountInflow,
                                outflow: accountOutflow,
                                txCount: accountTransactions.count
                            )
                        }
                        .padding(.horizontal)

                        // 3. Transfer Funds CTA Button
                        Button(action: { isTransferSheetPresented = true }) {
                            HStack(spacing: 8) {
                                Image(systemName: "arrow.left.arrow.right")
                                    .font(.system(size: 15, weight: .bold))
                                Text("Transfer Between Ledgers")
                                    .font(LeafTypography.bodyBold)
                            }
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .background(LeafTheme.brandEmerald)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }
                        .padding(.horizontal)

                        // 4. Ledger Filter Segmented Picker
                        Picker("Ledger Filter", selection: $selectedFilter) {
                            ForEach(LedgerFilter.allCases) { filter in
                                Text(filter.rawValue).tag(filter)
                            }
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal)

                        // 5. Transaction History
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("\(selectedFilter.rawValue) Activity")
                                    .font(LeafTypography.headline)
                                    .foregroundStyle(LeafTheme.textPrimary(for: colorScheme))

                                Spacer()

                                Text("\(displayedTransactions.count) entries")
                                    .font(LeafTypography.captionRegular)
                                    .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
                            }
                            .padding(.horizontal)

                            if displayedTransactions.isEmpty {
                                SquircleCard(cornerRadius: 16) {
                                    VStack(spacing: 8) {
                                        Image(systemName: "tray")
                                            .font(.system(size: 28))
                                            .foregroundStyle(LeafTheme.textTertiary(for: colorScheme))
                                        Text("No transactions logged in this ledger yet.")
                                            .font(LeafTypography.body)
                                            .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(24)
                                }
                                .padding(.horizontal)
                            } else {
                                LazyVStack(spacing: 8) {
                                    ForEach(displayedTransactions) { tx in
                                        transactionRow(tx)
                                            .padding(.horizontal)
                                    }
                                }
                            }
                        }

                        Spacer(minLength: 32)
                    }
                }
                .refreshable {
                    await loadLedgerData()
                }
            }
            .navigationTitle("Cash & Account Ledgers")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(LeafTheme.accent(for: colorScheme))
                }
            }
            .task {
                await loadLedgerData()
            }
            .sheet(isPresented: $isTransferSheetPresented) {
                TransferFundsSheet(currency: currency, onTransferCompleted: {
                    Task { await loadLedgerData() }
                })
            }
        }
    }

    // MARK: - Components

    @ViewBuilder
    private func ledgerSummaryCard(
        title: String,
        icon: String,
        color: Color,
        balance: Amount,
        inflow: Amount,
        outflow: Amount,
        txCount: Int
    ) -> some View {
        SquircleCard(cornerRadius: 18) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 6) {
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(color)

                    Text(title)
                        .font(LeafTypography.captionBold)
                        .foregroundStyle(LeafTheme.textPrimary(for: colorScheme))
                        .lineLimit(1)
                }

                Text(balance.format(currency: currency, includeSymbol: true))
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(color)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                Divider()

                VStack(alignment: .leading, spacing: 3) {
                    HStack {
                        Text("Inflow:")
                            .font(.system(size: 10))
                            .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
                        Spacer()
                        Text("+\(inflow.format(currency: currency, includeSymbol: false))")
                            .font(.system(size: 10, weight: .semibold, design: .rounded))
                            .foregroundStyle(LeafTheme.brandEmerald)
                    }

                    HStack {
                        Text("Outflow:")
                            .font(.system(size: 10))
                            .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
                        Spacer()
                        Text("-\(outflow.format(currency: currency, includeSymbol: false))")
                            .font(.system(size: 10, weight: .semibold, design: .rounded))
                            .foregroundStyle(LeafTheme.expenseCoral)
                    }
                }
            }
            .padding(14)
        }
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private func transactionRow(_ tx: Transaction) -> some View {
        SquircleCard(cornerRadius: 14) {
            HStack(spacing: 12) {
                // Category Icon
                CategoryIconBadge(
                    iconName: tx.isInternalTransfer ? "arrow.left.arrow.right" : (tx.category?.iconName ?? "tag.fill"),
                    colorHex: tx.category?.colorHex ?? "#10B981",
                    size: 38
                )

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(tx.category?.name ?? "Transaction")
                            .font(LeafTypography.bodyBold)
                            .foregroundStyle(LeafTheme.textPrimary(for: colorScheme))

                        if tx.isInternalTransfer {
                            Text("TRANSFER")
                                .font(.system(size: 8, weight: .bold))
                                .foregroundStyle(LeafTheme.brandEmerald)
                                .padding(.horizontal, 4)
                                .padding(.vertical, 1)
                                .background(Capsule().fill(LeafTheme.brandEmerald.opacity(0.12)))
                        }
                    }

                    if let note = tx.note, !note.isEmpty {
                        Text(note)
                            .font(LeafTypography.captionRegular)
                            .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
                            .lineLimit(1)
                    } else {
                        Text(DateFormatter.localizedString(from: Date(timeIntervalSince1970: Double(tx.timestamp) / 1000.0), dateStyle: .short, timeStyle: .short))
                            .font(LeafTypography.captionRegular)
                            .foregroundStyle(LeafTheme.textTertiary(for: colorScheme))
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(tx.type == .income ? "+" : "-")\(tx.amount.format(currency: currency, includeSymbol: true))")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(tx.type == .income ? LeafTheme.brandEmerald : LeafTheme.expenseCoral)

                    Text(tx.paymentMethod.displayName)
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(LeafTheme.textTertiary(for: colorScheme))
                }
            }
            .padding(12)
        }
    }

    // MARK: - Data Loading

    private func loadLedgerData() async {
        isLoading = true
        let prefs = container.preferencesRepository.getUserPreferences()
        self.currency = prefs.currency

        let opening = Amount(subunits: prefs.openingBalanceSubunits)

        async let cashBalTask = container.transactionRepository.getBalance(for: .cash)
        async let acctBalTask = container.transactionRepository.getBalance(for: .account)
        async let cashInTask = container.transactionRepository.getInflow(for: .cash, startEpoch: 0, endEpoch: Int64.max)
        async let cashOutTask = container.transactionRepository.getOutflow(for: .cash, startEpoch: 0, endEpoch: Int64.max)
        async let acctInTask = container.transactionRepository.getInflow(for: .account, startEpoch: 0, endEpoch: Int64.max)
        async let acctOutTask = container.transactionRepository.getOutflow(for: .account, startEpoch: 0, endEpoch: Int64.max)
        async let cashTxTask = container.transactionRepository.getTransactions(for: .cash)
        async let acctTxTask = container.transactionRepository.getTransactions(for: .account)
        async let allTxTask = container.transactionRepository.getAllTransactions()

        if let (cBal, aBal, cIn, cOut, aIn, aOut, cTx, aTx, allTx) = try? await (
            cashBalTask, acctBalTask, cashInTask, cashOutTask, acctInTask, acctOutTask, cashTxTask, acctTxTask, allTxTask
        ) {
            self.cashBalance = cBal
            self.accountBalance = aBal + opening
            self.cashInflow = cIn
            self.cashOutflow = cOut
            self.accountInflow = aIn
            self.accountOutflow = aOut
            self.cashTransactions = cTx
            self.accountTransactions = aTx
            self.allTransactions = allTx
        }
        self.isLoading = false
    }
}
