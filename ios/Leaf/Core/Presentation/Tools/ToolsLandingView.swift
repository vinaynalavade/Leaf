import SwiftUI

/// Main native iOS landing screen for the Leaf Financial Tools & Calculators suite.
/// Features categorization, live search, recent calculator tracking, and instant navigation
/// to all 6 fintech calculation engines (EMI, SIP, FD, RD, Discount, GST).
public struct ToolsLandingView: View {
    @Environment(\.colorScheme) private var colorScheme
    @State private var viewModel = ToolsLandingViewModel()

    public init() {}

    private let columns = [
        GridItem(.adaptive(minimum: 160, maximum: 200), spacing: 14)
    ]

    public var body: some View {
        ZStack {
            LeafTheme.canvas(for: colorScheme).ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    // 1. Hero Overview Card
                    heroHeaderCard

                    // 1.5 Travel Wallets Quick Access
                    travelWalletsBanner

                    // 2. Category Filter Pills
                    categoryFilterRow

                    // 3. Recent Activity Section (if any)
                    if !viewModel.recentToolTypes.isEmpty && viewModel.searchQuery.isEmpty && viewModel.selectedCategory == .all {
                        recentToolsSection
                    }

                    // 4. Calculators Grid
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("AVAILABLE CALCULATORS (\(viewModel.filteredTools.count))")
                                .font(LeafTypography.captionBold)
                                .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
                            Spacer()
                        }
                        .padding(.horizontal, 4)

                        LazyVGrid(columns: columns, spacing: 14) {
                            ForEach(viewModel.filteredTools) { tool in
                                NavigationLink(value: tool) {
                                    CalculatorCardView(tool: tool) {
                                        viewModel.selectTool(tool)
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
            }
        }
        .navigationTitle("Financial Tools")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $viewModel.searchQuery, prompt: "Search calculators (e.g. EMI, SIP, GST)...")
        .navigationDestination(for: FinancialToolType.self) { tool in
            destinationView(for: tool)
        }
    }

    // MARK: - Subviews

    @ViewBuilder
    private var heroHeaderCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.18))
                        .frame(width: 44, height: 44)

                    Image(systemName: "function")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Financial Utilities")
                        .font(LeafTypography.titleMedium)
                        .foregroundStyle(.white)

                    Text("Offline mathematical engines")
                        .font(LeafTypography.caption)
                        .foregroundStyle(Color.white.opacity(0.85))
                }

                Spacer()
            }

            Text("Accurate calculation suites for loan amortisation, SIP wealth growth, term deposits, retail discounts, and statutory GST apportionment.")
                .font(LeafTypography.caption)
                .foregroundStyle(Color.white.opacity(0.85))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(18)
        .background(LeafTheme.heroGradient(for: colorScheme))
        .cornerRadius(16)
        .shadow(color: LeafTheme.brandEmerald.opacity(0.2), radius: 10, x: 0, y: 4)
    }

    @ViewBuilder
    private var travelWalletsBanner: some View {
        NavigationLink {
            TravelWalletsListView()
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(LeafTheme.brandEmerald.opacity(0.12))
                        .frame(width: 42, height: 42)

                    Image(systemName: "airplane.departure")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(LeafTheme.brandEmerald)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Multi-Currency Travel Wallets")
                        .font(LeafTypography.bodyBold)
                        .foregroundStyle(LeafTheme.textPrimary(for: colorScheme))

                    Text("Track trip expenses in foreign currencies")
                        .font(LeafTypography.caption)
                        .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
            }
            .padding(14)
            .background(LeafTheme.card(for: colorScheme))
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(LeafTheme.border(for: colorScheme), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var categoryFilterRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(FinancialToolCategory.allCases) { cat in
                    Button {
                        viewModel.selectedCategory = cat
                    } label: {
                        Text(cat.displayName)
                            .font(LeafTypography.captionBold)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(
                                viewModel.selectedCategory == cat
                                    ? LeafTheme.brandEmerald
                                    : LeafTheme.card(for: colorScheme)
                            )
                            .foregroundStyle(
                                viewModel.selectedCategory == cat
                                    ? Color.white
                                    : LeafTheme.textPrimary(for: colorScheme)
                            )
                            .cornerRadius(20)
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(
                                        viewModel.selectedCategory == cat
                                            ? LeafTheme.brandEmerald
                                            : LeafTheme.border(for: colorScheme),
                                        lineWidth: 1
                                    )
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 2)
        }
    }

    @ViewBuilder
    private var recentToolsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("RECENTLY USED")
                .font(LeafTypography.captionBold)
                .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
                .padding(.horizontal, 4)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(viewModel.recentToolTypes) { tool in
                        NavigationLink(value: tool) {
                            HStack(spacing: 10) {
                                Image(systemName: tool.iconName)
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundStyle(LeafTheme.brandEmerald)

                                Text(tool.shortTitle)
                                    .font(LeafTypography.bodyBold)
                                    .foregroundStyle(LeafTheme.textPrimary(for: colorScheme))
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(LeafTheme.card(for: colorScheme))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(LeafTheme.border(for: colorScheme), lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 2)
            }
        }
    }

    @ViewBuilder
    private func destinationView(for tool: FinancialToolType) -> some View {
        switch tool {
        case .emi:
            EmiCalculatorView()
        case .sip:
            SipCalculatorView()
        case .fd:
            FdCalculatorView()
        case .rd:
            RdCalculatorView()
        case .discount:
            DiscountCalculatorView()
        case .gst:
            GstCalculatorView()
        }
    }
}

