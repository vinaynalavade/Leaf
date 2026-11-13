import SwiftUI

/// Search bar with real-time text input and dismissible active filter badge pills.
public struct ExpensesSearchBarView: View {
    @Environment(\.colorScheme) private var colorScheme

    @Binding public var searchText: String
    public let filter: TransactionFilter
    public let selectedCategory: Category?
    public let onClearSearch: () -> Void
    public let onClearCategory: () -> Void
    public let onClearAllFilters: () -> Void

    public init(
        searchText: Binding<String>,
        filter: TransactionFilter,
        selectedCategory: Category? = nil,
        onClearSearch: @escaping () -> Void,
        onClearCategory: @escaping () -> Void,
        onClearAllFilters: @escaping () -> Void
    ) {
        self._searchText = searchText
        self.filter = filter
        self.selectedCategory = selectedCategory
        self.onClearSearch = onClearSearch
        self.onClearCategory = onClearCategory
        self.onClearAllFilters = onClearAllFilters
    }

    public var body: some View {
        VStack(spacing: 8) {
            // Text Search Field
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))

                TextField("Search notes, categories, payment...", text: $searchText)
                    .font(LeafTypography.bodyMedium)
                    .foregroundStyle(LeafTheme.textPrimary(for: colorScheme))

                if !searchText.isEmpty {
                    Button(action: onClearSearch) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(colorScheme == .dark ? LeafTheme.cardDark : LeafTheme.cardLight)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(LeafTheme.cardBorder(for: colorScheme), lineWidth: 0.75)
            )
            .padding(.horizontal)

            // Active Filter Pills
            if filter.isActive || selectedCategory != nil {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        if let cat = selectedCategory {
                            filterChip(
                                label: "Category: \(cat.name)",
                                onRemove: onClearCategory
                            )
                        }

                        if let method = filter.paymentMethod {
                            filterChip(
                                label: "Method: \(method.rawValue.capitalized)",
                                onRemove: { /* will trigger through clear filters */ }
                            )
                        }

                        if filter.dateRange != .thisMonth {
                            filterChip(
                                label: "Range: \(filter.dateRange.rawValue)",
                                onRemove: { /* will trigger through clear filters */ }
                            )
                        }

                        if filter.minAmountSubunits != nil || filter.maxAmountSubunits != nil {
                            filterChip(
                                label: "Amount Filtered",
                                onRemove: { /* will trigger through clear filters */ }
                            )
                        }

                        Button(action: onClearAllFilters) {
                            Text("Reset All")
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                .foregroundStyle(LeafTheme.expenseCoral)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
    }

    @ViewBuilder
    private func filterChip(label: String, onRemove: @escaping () -> Void) -> some View {
        HStack(spacing: 4) {
            Text(label)
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundStyle(LeafTheme.brandEmerald)

            Button(action: onRemove) {
                Image(systemName: "xmark")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(LeafTheme.brandEmerald)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(LeafTheme.brandEmerald.opacity(0.12))
        )
    }
}

