import SwiftUI

/// Main native iOS view for managing Multi-Currency Travel Wallets.
/// Displays an overview of active and archived trip wallets, destination currency expenditures,
/// budget tracking, primary currency approximations, and creation of new travel wallets.
public struct TravelWalletsListView: View {
    @Environment(AppContainer.self) private var container
    @Environment(\.colorScheme) private var colorScheme

    @State private var viewModel: TravelWalletsViewModel?
    @State private var selectedFilter: WalletFilter = .active
    @State private var searchQuery: String = ""
    @State private var isCreateSheetPresented: Bool = false
    @State private var walletToEdit: TravelWallet? = nil
    @State private var walletToDelete: TravelWalletSummary? = nil
    @State private var showDeleteAlert: Bool = false

    public enum WalletFilter: String, CaseIterable, Identifiable {
        case active = "Active"
        case archived = "Archived"
        case all = "All"

        public var id: String { rawValue }
    }

    public init() {}

    public var body: some View {
        ZStack {
            LeafTheme.canvas(for: colorScheme).ignoresSafeArea()

            if let vm = viewModel {
                ScrollView {
                    VStack(spacing: 16) {
                        // 1. Hero Travel Banner
                        heroBannerCard

                        // 2. Filter Pills & Search
                        filterBar

                        // 3. Wallets List or Empty State
                        if filteredWallets(from: vm.walletSummaries).isEmpty {
                            emptyStateView
                        } else {
                            walletsList(from: filteredWallets(from: vm.walletSummaries))
                        }

                        Spacer(minLength: 32)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                }
                .refreshable {
                    await vm.loadData()
                }
            } else {
                ProgressView()
                    .tint(LeafTheme.brandEmerald)
            }
        }
        .navigationTitle("Travel Wallets")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    let generator = UIImpactFeedbackGenerator(style: .medium)
                    generator.impactOccurred()
                    isCreateSheetPresented = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(LeafTheme.brandEmerald)
                }
            }
        }
        .sheet(isPresented: $isCreateSheetPresented) {
            CreateEditTravelWalletSheet(existingWallet: nil) { name, curr, budget, note, color, icon in
                await viewModel?.saveWallet(
                    id: nil,
                    name: name,
                    currencyCode: curr,
                    budgetAmount: budget,
                    note: note,
                    colorHex: color,
                    iconName: icon
                ) ?? false
            }
        }
        .sheet(item: $walletToEdit) { wallet in
            CreateEditTravelWalletSheet(existingWallet: wallet) { name, curr, budget, note, color, icon in
                await viewModel?.saveWallet(
                    id: wallet.id,
                    name: name,
                    currencyCode: curr,
                    budgetAmount: budget,
                    note: note,
                    colorHex: color,
                    iconName: icon
                ) ?? false
            }
        }
        .alert("Delete Travel Wallet?", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) {
                walletToDelete = nil
            }
            Button("Delete", role: .destructive) {
                if let summary = walletToDelete {
                    let id = summary.wallet.id
                    Task {
                        await viewModel?.deleteWallet(id: id)
                    }
                }
            }
        } message: {
            Text("Deleting this wallet will unassign all its transactions while safely preserving your financial records and primary currency totals.")
        }
        .task {
            if viewModel == nil {
                let vm = TravelWalletsViewModel(
                    getTravelWalletsUseCase: container.getTravelWalletsUseCase,
                    saveTravelWalletUseCase: container.saveTravelWalletUseCase,
                    deleteTravelWalletUseCase: container.deleteTravelWalletUseCase,
                    preferencesRepository: container.preferencesRepository
                )
                self.viewModel = vm
                await vm.loadData()
            } else {
                await viewModel?.loadData()
            }
        }
    }

    // MARK: - Subviews

    @ViewBuilder
    private var heroBannerCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.18))
                        .frame(width: 44, height: 44)

                    Image(systemName: "airplane.departure")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Multi-Currency Trips")
                        .font(LeafTypography.titleMedium)
                        .foregroundStyle(.white)

                    Text("Spend in destination currencies")
                        .font(LeafTypography.caption)
                        .foregroundStyle(Color.white.opacity(0.85))
                }

                Spacer()

                Button {
                    isCreateSheetPresented = true
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "plus")
                            .font(.system(size: 11, weight: .bold))
                        Text("New Trip")
                            .font(LeafTypography.captionBold)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.white.opacity(0.22))
                    .foregroundStyle(.white)
                    .clipShape(Capsule())
                }
            }

            Text("Organize trip expenses in JPY, USD, EUR, AED, GBP and more. Tracks original foreign totals while converting to your primary currency without duplicating money.")
                .font(LeafTypography.caption)
                .foregroundStyle(Color.white.opacity(0.85))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(18)
        .background(LeafTheme.heroGradient(for: colorScheme))
        .cornerRadius(16)
        .shadow(color: LeafTheme.brandEmerald.opacity(0.2), radius: 8, x: 0, y: 3)
    }

    @ViewBuilder
    private var filterBar: some View {
        VStack(spacing: 10) {
            // Search field
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 14))
                    .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))

                TextField("Search trips or currencies...", text: $searchQuery)
                    .font(LeafTypography.bodyMedium)

                if !searchQuery.isEmpty {
                    Button {
                        searchQuery = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .background(LeafTheme.card(for: colorScheme))
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(LeafTheme.border(for: colorScheme), lineWidth: 1)
            )

            // Segment filter
            HStack(spacing: 8) {
                ForEach(WalletFilter.allCases) { filter in
                    Button {
                        selectedFilter = filter
                    } label: {
                        Text(filter.rawValue)
                            .font(LeafTypography.captionBold)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 6)
                            .background(
                                selectedFilter == filter
                                    ? LeafTheme.brandEmerald
                                    : LeafTheme.card(for: colorScheme)
                            )
                            .foregroundStyle(
                                selectedFilter == filter
                                    ? Color.white
                                    : LeafTheme.textPrimary(for: colorScheme)
                            )
                            .cornerRadius(16)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(
                                        selectedFilter == filter
                                            ? LeafTheme.brandEmerald
                                            : LeafTheme.border(for: colorScheme),
                                        lineWidth: 1
                                    )
                            )
                    }
                    .buttonStyle(.plain)
                }
                Spacer()
            }
        }
    }

    @ViewBuilder
    private func walletsList(from summaries: [TravelWalletSummary]) -> some View {
        LazyVStack(spacing: 14) {
            ForEach(summaries) { summary in
                NavigationLink {
                    TravelWalletDetailView(walletId: summary.wallet.id)
                } label: {
                    walletCardView(summary)
                }
                .buttonStyle(.plain)
                .contextMenu {
                    Button {
                        walletToEdit = summary.wallet
                    } label: {
                        Label("Edit Details", systemImage: "pencil")
                    }

                    Button {
                        Task {
                            await viewModel?.toggleArchive(wallet: summary.wallet)
                        }
                    } label: {
                        Label(
                            summary.wallet.isArchived ? "Unarchive Trip" : "Archive Trip",
                            systemImage: summary.wallet.isArchived ? "tray.and.arrow.up" : "archivebox"
                        )
                    }

                    Divider()

                    Button(role: .destructive) {
                        walletToDelete = summary
                        showDeleteAlert = true
                    } label: {
                        Label("Delete Wallet", systemImage: "trash")
                    }
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    Button(role: .destructive) {
                        walletToDelete = summary
                        showDeleteAlert = true
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }

                    Button {
                        Task {
                            await viewModel?.toggleArchive(wallet: summary.wallet)
                        }
                    } label: {
                        Label(
                            summary.wallet.isArchived ? "Unarchive" : "Archive",
                            systemImage: summary.wallet.isArchived ? "tray.and.arrow.up" : "archivebox"
                        )
                    }
                    .tint(.indigo)
                }
            }
        }
    }

    @ViewBuilder
    private func walletCardView(_ summary: TravelWalletSummary) -> some View {
        let w = summary.wallet
        let isOverBudget = summary.isOverBudget

        VStack(alignment: .leading, spacing: 14) {
            // Top row: Icon, Name, Currency Badge, Status
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(hex: w.colorHex).opacity(0.18))
                        .frame(width: 44, height: 44)

                    Image(systemName: w.iconName)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(Color(hex: w.colorHex))
                }

                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text(w.name)
                            .font(LeafTypography.titleMedium)
                            .foregroundStyle(LeafTheme.textPrimary(for: colorScheme))
                            .lineLimit(1)

                        if w.isArchived {
                            Text("ARCHIVED")
                                .font(.system(size: 9, weight: .bold))
                                .padding(.horizontal, 5)
                                .padding(.vertical, 2)
                                .background(Color.gray.opacity(0.15))
                                .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
                                .cornerRadius(4)
                        }
                    }

                    if let note = w.note, !note.isEmpty {
                        Text(note)
                            .font(LeafTypography.caption)
                            .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
                            .lineLimit(1)
                    } else {
                        Text("\(summary.transactionCount) transactions recorded")
                            .font(LeafTypography.caption)
                            .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
                    }
                }

                Spacer()

                // Currency Badge
                Text(w.currency.code)
                    .font(LeafTypography.captionBold)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(LeafTheme.brandEmerald.opacity(0.12))
                    .foregroundStyle(LeafTheme.brandEmerald)
                    .cornerRadius(8)
            }

            Divider()
                .background(LeafTheme.border(for: colorScheme))

            // Middle row: Foreign spent and Primary equivalent
            HStack(alignment: .lastTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("SPENT")
                        .font(LeafTypography.captionBold)
                        .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))

                    Text(summary.formattedWalletSpent)
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(LeafTheme.textPrimary(for: colorScheme))
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text("EQUIVALENT")
                        .font(LeafTypography.captionBold)
                        .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))

                    Text("~ \(summary.formattedPrimarySpent)")
                        .font(LeafTypography.bodyBold)
                        .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
                }
            }

            // Bottom row: Budget Progress (if budget configured)
            if let budget = w.budgetAmount {
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Budget: \(budget.formatted(currency: w.currency))")
                            .font(LeafTypography.caption)
                            .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))

                        Spacer()

                        if isOverBudget {
                            Text("Exceeded by \((summary.totalSpentInWalletCurrency - budget).formatted(currency: w.currency))")
                                .font(LeafTypography.captionBold)
                                .foregroundStyle(Color.red)
                        } else {
                            Text("\(Int(summary.budgetProgress * 100))% used")
                                .font(LeafTypography.captionBold)
                                .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
                        }
                    }

                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(LeafTheme.border(for: colorScheme))
                                .frame(height: 6)

                            Capsule()
                                .fill(isOverBudget ? Color.red : (summary.budgetProgress > 0.85 ? Color.orange : Color(hex: w.colorHex)))
                                .frame(width: min(geo.size.width * CGFloat(summary.budgetProgress), geo.size.width), height: 6)
                        }
                    }
                    .frame(height: 6)
                }
            }
        }
        .padding(16)
        .background(LeafTheme.card(for: colorScheme))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(LeafTheme.border(for: colorScheme), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.05), radius: 6, x: 0, y: 2)
    }

    @ViewBuilder
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(LeafTheme.brandEmerald.opacity(0.12))
                    .frame(width: 80, height: 80)

                Image(systemName: "globe.asia.australia.fill")
                    .font(.system(size: 38))
                    .foregroundStyle(LeafTheme.brandEmerald)
            }
            .padding(.top, 24)

            Text(searchQuery.isEmpty ? "No Travel Wallets" : "No Trips Found")
                .font(LeafTypography.titleLarge)
                .foregroundStyle(LeafTheme.textPrimary(for: colorScheme))

            Text(
                searchQuery.isEmpty
                    ? "Create a dedicated wallet for your next international journey (e.g. Japan Vacation, Dubai Trip, Euro Tour) to record foreign currency expenses without mixing currencies."
                    : "No trips matched \"\(searchQuery)\". Try searching by another trip title or currency."
            )
            .font(LeafTypography.bodyMedium)
            .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
            .multilineTextAlignment(.center)
            .padding(.horizontal, 24)

            Button {
                isCreateSheetPresented = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "plus")
                        .font(.system(size: 14, weight: .bold))
                    Text("Create Travel Wallet")
                        .font(LeafTypography.bodyBold)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(LeafTheme.brandEmerald)
                .foregroundStyle(.white)
                .clipShape(Capsule())
            }
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(LeafTheme.card(for: colorScheme))
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(LeafTheme.border(for: colorScheme), lineWidth: 1)
        )
    }

    private func filteredWallets(from summaries: [TravelWalletSummary]) -> [TravelWalletSummary] {
        summaries.filter { summary in
            let matchesFilter: Bool
            switch selectedFilter {
            case .active:
                matchesFilter = !summary.wallet.isArchived
            case .archived:
                matchesFilter = summary.wallet.isArchived
            case .all:
                matchesFilter = true
            }

            let trimmed = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty {
                return matchesFilter
            }

            let matchesSearch = summary.wallet.name.localizedCaseInsensitiveContains(trimmed) ||
                summary.wallet.currencyCode.localizedCaseInsensitiveContains(trimmed) ||
                (summary.wallet.note?.localizedCaseInsensitiveContains(trimmed) ?? false)

            return matchesFilter && matchesSearch
        }
    }
}

