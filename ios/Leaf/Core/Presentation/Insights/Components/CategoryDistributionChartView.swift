import SwiftUI
import Charts

/// Native iOS 17 donut chart using SectorMark (cutout ratio 0.65)
/// with center total spend label and ranked category breakdown legend.
public struct CategoryDistributionChartView: View {
    @Environment(\.colorScheme) private var colorScheme

    public let categories: [CategoryAnalysisItem]
    public let totalExpense: Amount
    public let currency: Currency
    public let onSelectCategory: (CategoryAnalysisItem) -> Void

    public init(
        categories: [CategoryAnalysisItem],
        totalExpense: Amount,
        currency: Currency,
        onSelectCategory: @escaping (CategoryAnalysisItem) -> Void
    ) {
        self.categories = categories
        self.totalExpense = totalExpense
        self.currency = currency
        self.onSelectCategory = onSelectCategory
    }

    private var displayCategories: [CategoryAnalysisItem] {
        Array(categories.prefix(6))
    }

    public var body: some View {
        SquircleCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("CATEGORY DISTRIBUTION")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .tracking(1.0)
                        .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))

                    Spacer()

                    Text("\(categories.count) Categories")
                        .font(LeafTypography.caption)
                        .foregroundStyle(LeafTheme.textTertiary(for: colorScheme))
                }

                if !categories.isEmpty && totalExpense.subunits > 0 {
                    HStack(spacing: 20) {
                        // Donut Chart with Center Label
                        ZStack {
                            Chart(displayCategories) { item in
                                SectorMark(
                                    angle: .value("Spending", item.amount.subunits),
                                    innerRadius: .ratio(0.65),
                                    angularInset: 1.5
                                )
                                .cornerRadius(4)
                                .foregroundStyle(Color(hex: item.category.colorHex))
                            }
                            .frame(width: 150, height: 150)

                            // Center Cutout Content
                            VStack(spacing: 2) {
                                Text("TOTAL")
                                    .font(.system(size: 9, weight: .bold, design: .rounded))
                                    .tracking(0.8)
                                    .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))

                                Text(totalExpense.formatted(with: currency))
                                    .font(.system(size: 14, weight: .bold, design: .rounded))
                                    .foregroundStyle(LeafTheme.textPrimary(for: colorScheme))
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.7)
                                    .frame(maxWidth: 90)
                            }
                        }

                        // Top Categories Legend Stack
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(displayCategories.prefix(4)) { item in
                                Button(action: { onSelectCategory(item) }) {
                                    HStack(spacing: 8) {
                                        Circle()
                                            .fill(Color(hex: item.category.colorHex))
                                            .frame(width: 9, height: 9)

                                        Text(item.category.name)
                                            .font(.system(size: 12, weight: .medium))
                                            .foregroundStyle(LeafTheme.textPrimary(for: colorScheme))
                                            .lineLimit(1)

                                        Spacer()

                                        Text(String(format: "%.0f%%", item.percentageOfTotal))
                                            .font(.system(size: 12, weight: .bold, design: .rounded))
                                            .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
                                    }
                                }
                                .buttonStyle(.plain)
                            }

                            if categories.count > 4 {
                                let otherCount = categories.count - 4
                                Text("+\(otherCount) more in list")
                                    .font(LeafTypography.caption)
                                    .foregroundStyle(LeafTheme.textTertiary(for: colorScheme))
                                    .padding(.top, 2)
                            }
                        }
                    }
                } else {
                    VStack(spacing: 8) {
                        Image(systemName: "chart.pie")
                            .font(.system(size: 32))
                            .foregroundStyle(LeafTheme.textTertiary(for: colorScheme))

                        Text("No category spending data")
                            .font(LeafTypography.subheadline)
                            .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
                    }
                    .frame(maxWidth: .infinity, minHeight: 140)
                }
            }
            .padding(16)
        }
    }
}

