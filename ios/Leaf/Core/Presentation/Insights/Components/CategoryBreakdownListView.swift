import SwiftUI

/// Ranked category breakdown list with visual share bars, transaction counts,
/// period-over-period comparisons, and interactive tap-to-drill-down.
public struct CategoryBreakdownListView: View {
    @Environment(\.colorScheme) private var colorScheme

    public let categories: [CategoryAnalysisItem]
    public let currency: Currency
    public let onSelectCategory: (CategoryAnalysisItem) -> Void

    public init(
        categories: [CategoryAnalysisItem],
        currency: Currency,
        onSelectCategory: @escaping (CategoryAnalysisItem) -> Void
    ) {
        self.categories = categories
        self.currency = currency
        self.onSelectCategory = onSelectCategory
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("CATEGORY RANKING")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .tracking(1.0)
                    .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))

                Spacer()

                Text("Ranked by spend")
                    .font(LeafTypography.caption)
                    .foregroundStyle(LeafTheme.textTertiary(for: colorScheme))
            }
            .padding(.horizontal, 16)

            if categories.isEmpty {
                SquircleCard {
                    Text("No category transactions for this period")
                        .font(LeafTypography.subheadline)
                        .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(24)
                }
                .padding(.horizontal, 16)
            } else {
                VStack(spacing: 8) {
                    ForEach(categories) { item in
                        categoryRow(item)
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }

    @ViewBuilder
    private func categoryRow(_ item: CategoryAnalysisItem) -> some View {
        Button(action: { onSelectCategory(item) }) {
            SquircleCard {
                VStack(spacing: 10) {
                    HStack(alignment: .center, spacing: 12) {
                        // Category Icon Badge
                        CategoryIconBadge(
                            iconName: item.category.iconName,
                            colorHex: item.category.colorHex,
                            size: 40
                        )

                        VStack(alignment: .leading, spacing: 3) {
                            HStack(spacing: 6) {
                                Text(item.category.name)
                                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                                    .foregroundStyle(LeafTheme.textPrimary(for: colorScheme))

                                Text("• \(item.transactionCount) tx")
                                    .font(LeafTypography.caption)
                                    .foregroundStyle(LeafTheme.textTertiary(for: colorScheme))
                            }

                            // Spending share bar
                            GeometryReader { proxy in
                                ZStack(alignment: .leading) {
                                    Capsule()
                                        .fill(LeafTheme.cardBorder(for: colorScheme))
                                        .frame(height: 5)

                                    Capsule()
                                        .fill(Color(hex: item.category.colorHex))
                                        .frame(width: max(4, proxy.size.width * CGFloat(item.percentageOfTotal / 100.0)), height: 5)
                                }
                            }
                            .frame(height: 5)
                        }

                        Spacer()

                        // Amount and % / comparison badges
                        VStack(alignment: .trailing, spacing: 3) {
                            Text(item.amount.formatted(with: currency))
                                .font(.system(size: 15, weight: .bold, design: .rounded))
                                .foregroundStyle(LeafTheme.textPrimary(for: colorScheme))

                            HStack(spacing: 4) {
                                Text(String(format: "%.1f%%", item.percentageOfTotal))
                                    .font(.system(size: 11, weight: .bold, design: .rounded))
                                    .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))

                                if let change = item.changePercentageVsPrevious {
                                    let isIncrease = change > 0
                                    HStack(spacing: 2) {
                                        Image(systemName: isIncrease ? "arrow.up" : "arrow.down")
                                            .font(.system(size: 8, weight: .bold))
                                        Text(String(format: "%.0f%%", abs(change)))
                                            .font(.system(size: 10, weight: .semibold, design: .rounded))
                                    }
                                    .padding(.horizontal, 5)
                                    .padding(.vertical, 2)
                                    .background(
                                        Capsule()
                                            .fill((isIncrease ? LeafTheme.expenseCoral : LeafTheme.brandEmerald).opacity(0.12))
                                    )
                                    .foregroundStyle(isIncrease ? LeafTheme.expenseCoral : LeafTheme.brandEmerald)
                                }
                            }
                        }

                        Image(systemName: "chevron.right")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(LeafTheme.textTertiary(for: colorScheme))
                    }
                }
                .padding(12)
            }
        }
        .buttonStyle(.plain)
    }
}

