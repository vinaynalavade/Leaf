import SwiftUI
import UIKit

/// Premium native iOS header for the Expenses screen.
/// Features month/year navigation with previous/next chevrons, search toggle, filter sheet trigger with badge, and quick Add Expense action.
public struct ExpensesMonthPickerHeaderView: View {
    @Environment(\.colorScheme) private var colorScheme

    public let periodText: String
    public let isSearchActive: Bool
    public let activeFilterCount: Int
    public let onPreviousMonth: () -> Void
    public let onNextMonth: () -> Void
    public let onToggleSearch: () -> Void
    public let onOpenFilter: () -> Void
    public let onScanReceipt: (() -> Void)?
    public let onAddExpense: () -> Void

    public init(
        periodText: String,
        isSearchActive: Bool,
        activeFilterCount: Int,
        onPreviousMonth: @escaping () -> Void,
        onNextMonth: @escaping () -> Void,
        onToggleSearch: @escaping () -> Void,
        onOpenFilter: @escaping () -> Void,
        onScanReceipt: (() -> Void)? = nil,
        onAddExpense: @escaping () -> Void
    ) {
        self.periodText = periodText
        self.isSearchActive = isSearchActive
        self.activeFilterCount = activeFilterCount
        self.onPreviousMonth = onPreviousMonth
        self.onNextMonth = onNextMonth
        self.onToggleSearch = onToggleSearch
        self.onOpenFilter = onOpenFilter
        self.onScanReceipt = onScanReceipt
        self.onAddExpense = onAddExpense
    }

    private func triggerHaptic() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.prepare()
        generator.impactOccurred()
    }

    public var body: some View {
        VStack(spacing: 12) {
            // Top Bar: Screen Title & Action Icons
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Expenses")
                        .font(LeafTypography.titleLarge)
                        .foregroundStyle(LeafTheme.textPrimary(for: colorScheme))

                    Text("Tracking & category breakdown")
                        .font(LeafTypography.captionRegular)
                        .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
                }

                Spacer()

                HStack(spacing: 8) {
                    // Search Toggle Button
                    Button(action: {
                        triggerHaptic()
                        onToggleSearch()
                    }) {
                        Image(systemName: isSearchActive ? "text.magnifyingglass" : "magnifyingglass")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(isSearchActive ? LeafTheme.brandEmerald : LeafTheme.textPrimary(for: colorScheme))
                            .frame(width: 36, height: 36)
                            .background(
                                Circle()
                                    .fill(colorScheme == .dark ? LeafTheme.cardDark : LeafTheme.cardLight)
                            )
                            .overlay(
                                Circle()
                                    .stroke(LeafTheme.cardBorder(for: colorScheme), lineWidth: 0.75)
                            )
                    }
                    .accessibilityLabel(isSearchActive ? "Close search" : "Search expenses")
                    .accessibilityHint("Toggles the expense search input field")

                    // Filter Button (with badge)
                    Button(action: {
                        triggerHaptic()
                        onOpenFilter()
                    }) {
                        ZStack(alignment: .topTrailing) {
                            Image(systemName: "line.3.horizontal.decrease.circle")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(activeFilterCount > 0 ? LeafTheme.brandEmerald : LeafTheme.textPrimary(for: colorScheme))
                                .frame(width: 36, height: 36)
                                .background(
                                    Circle()
                                        .fill(colorScheme == .dark ? LeafTheme.cardDark : LeafTheme.cardLight)
                                )
                                .overlay(
                                    Circle()
                                        .stroke(LeafTheme.cardBorder(for: colorScheme), lineWidth: 0.75)
                                )

                            if activeFilterCount > 0 {
                                Text("\(activeFilterCount)")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundStyle(.white)
                                    .frame(width: 16, height: 16)
                                    .background(LeafTheme.brandEmerald)
                                    .clipShape(Circle())
                                    .offset(x: 4, y: -4)
                            }
                        }
                    }
                    .accessibilityLabel(activeFilterCount > 0 ? "Filters applied: \(activeFilterCount)" : "Filter expenses")
                    .accessibilityHint("Opens filter options sheet")

                    // Scan Receipt Button
                    if let onScan = onScanReceipt {
                        Button(action: {
                            triggerHaptic()
                            onScan()
                        }) {
                            Image(systemName: "doc.text.viewfinder")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(LeafTheme.brandEmerald)
                                .frame(width: 36, height: 36)
                                .background(
                                    Circle()
                                        .fill(colorScheme == .dark ? LeafTheme.cardDark : LeafTheme.cardLight)
                                )
                                .overlay(
                                    Circle()
                                        .stroke(LeafTheme.cardBorder(for: colorScheme), lineWidth: 0.75)
                                )
                        }
                        .accessibilityLabel("Scan receipt")
                        .accessibilityHint("Opens camera to scan and auto-fill receipt")
                    }

                    // Add Expense Primary CTA (Fixed: 36x36 Circular SF Symbol button to prevent text clipping)
                    Button(action: {
                        triggerHaptic()
                        onAddExpense()
                    }) {
                        Image(systemName: "plus")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 36, height: 36)
                            .background(
                                Circle()
                                    .fill(LeafTheme.brandEmerald)
                            )
                            .shadow(color: LeafTheme.brandEmerald.opacity(0.3), radius: 3, x: 0, y: 2)
                    }
                    .accessibilityLabel("Add expense")
                    .accessibilityHint("Opens sheet to record a new transaction")
                }
            }
            .padding(.horizontal)

            // Month Navigation Bar
            HStack {
                Button(action: {
                    triggerHaptic()
                    onPreviousMonth()
                }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(LeafTheme.textPrimary(for: colorScheme))
                        .frame(width: 32, height: 32)
                        .background(
                            Circle()
                                .fill(colorScheme == .dark ? LeafTheme.cardDark : LeafTheme.cardLight)
                        )
                }
                .accessibilityLabel("Previous month")

                Spacer()

                HStack(spacing: 6) {
                    Image(systemName: "calendar")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(LeafTheme.brandEmerald)

                    Text(periodText)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(LeafTheme.textPrimary(for: colorScheme))
                }

                Spacer()

                Button(action: {
                    triggerHaptic()
                    onNextMonth()
                }) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(LeafTheme.textPrimary(for: colorScheme))
                        .frame(width: 32, height: 32)
                        .background(
                            Circle()
                                .fill(colorScheme == .dark ? LeafTheme.cardDark : LeafTheme.cardLight)
                        )
                }
                .accessibilityLabel("Next month")
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill((colorScheme == .dark ? LeafTheme.cardDark : LeafTheme.cardLight).opacity(0.6))
            )
            .padding(.horizontal)
        }
    }
}

