import SwiftUI
import Charts

/// Native iOS 17 Swift Charts donut chart rendering category-wise distribution of group spending.
/// Features a cutout center displaying the total group expenditure and interactive category selection.
public struct SplitGroupCategoryChart: View {
    @Environment(\.colorScheme) private var colorScheme

    public let categories: [SplitGroupCategorySpending]
    public let totalSpending: Amount
    public let currency: Currency
    public let selectedCategoryId: Int64?
    public let onSelectCategory: (Int64) -> Void

    public init(
        categories: [SplitGroupCategorySpending],
        totalSpending: Amount,
        currency: Currency,
        selectedCategoryId: Int64? = nil,
        onSelectCategory: @escaping (Int64) -> Void
    ) {
        self.categories = categories
        self.totalSpending = totalSpending
        self.currency = currency
        self.selectedCategoryId = selectedCategoryId
        self.onSelectCategory = onSelectCategory
    }

    private var topCategories: [SplitGroupCategorySpending] {
        Array(categories.prefix(8))
    }

    public var body: some View {
        VStack(spacing: 16) {
            if !categories.isEmpty && totalSpending.subunits > 0 {
                ZStack {
                    Chart(topCategories) { item in
                        SectorMark(
                            angle: .value("Spending", item.totalAmount.subunits),
                            innerRadius: .ratio(0.65),
                            angularInset: 1.5
                        )
                        .cornerRadius(4)
                        .foregroundStyle(Color(hex: item.categoryColorHex))
                        .opacity(selectedCategoryId == nil || selectedCategoryId == item.categoryId ? 1.0 : 0.35)
                    }
                    .frame(width: 170, height: 170)

                    // Center Cutout Label
                    VStack(spacing: 2) {
                        Text(selectedCategoryId != nil ? "SELECTED" : "GROUP TOTAL")
                            .font(.system(size: 9, weight: .bold, design: .rounded))
                            .tracking(0.8)
                            .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))

                        if let selectedId = selectedCategoryId,
                           let selectedItem = categories.first(where: { $0.categoryId == selectedId }) {
                            Text(selectedItem.totalAmount.formatted(with: currency))
                                .font(.system(size: 15, weight: .bold, design: .rounded))
                                .foregroundStyle(LeafTheme.textPrimary(for: colorScheme))
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                                .frame(maxWidth: 100)

                            Text(String(format: "%.1f%%", selectedItem.percentage))
                                .font(.system(size: 10, weight: .bold, design: .rounded))
                                .foregroundStyle(Color(hex: selectedItem.categoryColorHex))
                        } else {
                            Text(totalSpending.formatted(with: currency))
                                .font(.system(size: 15, weight: .bold, design: .rounded))
                                .foregroundStyle(LeafTheme.textPrimary(for: colorScheme))
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                                .frame(maxWidth: 100)
                        }
                    }
                }
            } else {
                VStack(spacing: 6) {
                    Image(systemName: "chart.pie")
                        .font(.system(size: 32))
                        .foregroundStyle(LeafTheme.textTertiary(for: colorScheme))
                    Text("No category expenses in this period")
                        .font(LeafTypography.caption)
                        .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
                }
                .frame(maxWidth: .infinity, minHeight: 140)
            }
        }
    }
}

