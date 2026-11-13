import SwiftUI

/// Section displaying category-level spending breakdown with percentage progress bars.
/// Supports tapping any category to filter the transaction history by that category.
public struct ExpensesCategoryBreakdownView: View {
    @Environment(\.colorScheme) private var colorScheme

    public let breakdowns: [CategorySpending]
    public let selectedCategory: Category?
    public let currency: Currency
    public let onSelectCategory: (Category) -> Void
    public let onClearCategoryFilter: () -> Void

    public init(
        breakdowns: [CategorySpending],
        selectedCategory: Category? = nil,
        currency: Currency = .default,
        onSelectCategory: @escaping (Category) -> Void,
        onClearCategoryFilter: @escaping () -> Void
    ) {
        self.breakdowns = breakdowns
        self.selectedCategory = selectedCategory
        self.currency = currency
        self.onSelectCategory = onSelectCategory
        self.onClearCategoryFilter = onClearCategoryFilter
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section Header
            HStack {
                Text("SPENDING BREAKDOWN")
                    .font(LeafTypography.captionBold)
                    .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
                    .tracking(0.5)

                Spacer()

                if let selected = selectedCategory {
                    Button(action: onClearCategoryFilter) {
                        HStack(spacing: 4) {
                            Text("Clear: \(selected.name)")
                            Image(systemName: "xmark.circle.fill")
                        }
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundStyle(LeafTheme.brandEmerald)
                    }
                } else if !breakdowns.isEmpty {
                    Text("\(breakdowns.count) categories")
                        .font(LeafTypography.captionRegular)
                        .foregroundStyle(LeafTheme.textTertiary(for: colorScheme))
                }
            }
            .padding(.horizontal)

            if breakdowns.isEmpty {
                EmptyStateCard(
                    icon: "chart.pie",
                    title: "No Expenses Logged",
                    message: "There are no expenses recorded for this period yet."
                )
                .padding(.horizontal)
            } else {
                VStack(spacing: 8) {
                    ForEach(breakdowns) { spending in
                        let isSelected = selectedCategory?.id == spending.category.id
                        let catColor = Color(hex: spending.category.colorHex) ?? LeafTheme.brandEmerald

                        Button(action: { onSelectCategory(spending.category) }) {
                            SquircleCard(cornerRadius: 16) {
                                VStack(spacing: 8) {
                                    HStack(spacing: 12) {
                                        // Category Icon Badge
                                        CategoryIconBadge(
                                            iconName: spending.category.iconName,
                                            colorHex: spending.category.colorHex,
                                            size: 38
                                        )

                                        // Category Name & Transaction Count
                                        VStack(alignment: .leading, spacing: 2) {
                                            HStack(spacing: 6) {
                                                Text(spending.category.name)
                                                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                                                    .foregroundStyle(LeafTheme.textPrimary(for: colorScheme))

                                                if isSelected {
                                                    Image(systemName: "checkmark.circle.fill")
                                                        .font(.system(size: 12))
                                                        .foregroundStyle(LeafTheme.brandEmerald)
                                                }
                                            }

                                            Text("\(spending.transactionCount) \(spending.transactionCount == 1 ? "expense" : "expenses")")
                                                .font(LeafTypography.captionRegular)
                                                .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
                                        }

                                        Spacer()

                                        // Amount & Percentage Badge
                                        VStack(alignment: .trailing, spacing: 2) {
                                            Text(spending.totalAmount.formatted(currency: currency))
                                                .font(.system(size: 15, weight: .bold, design: .rounded).monospacedDigit())
                                                .foregroundStyle(LeafTheme.textPrimary(for: colorScheme))

                                            Text(String(format: "%.1f%%", spending.percentageOfTotal))
                                                .font(.system(size: 11, weight: .semibold, design: .rounded))
                                                .foregroundStyle(catColor)
                                        }
                                    }

                                    // Progress Bar
                                    GeometryReader { geo in
                                        ZStack(alignment: .leading) {
                                            Capsule()
                                                .fill((colorScheme == .dark ? Color.white : Color.black).opacity(0.06))
                                                .frame(height: 5)

                                            Capsule()
                                                .fill(catColor)
                                                .frame(width: max(4, geo.size.width * CGFloat(min(1.0, spending.percentageOfTotal / 100.0))), height: 5)
                                        }
                                    }
                                    .frame(height: 5)
                                }
                                .padding(12)
                            }
                            .overlay(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .stroke(isSelected ? LeafTheme.brandEmerald : Color.clear, lineWidth: 1.5)
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

