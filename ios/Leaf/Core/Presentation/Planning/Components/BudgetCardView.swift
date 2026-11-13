import SwiftUI

/// Component displaying an individual category or overall budget card
/// with Leaf's master 4-tier threshold indicator, progress bar, period type, and metrics.
public struct BudgetCardView: View {
    @Environment(\.colorScheme) private var colorScheme

    public let progress: BudgetProgress
    public let currency: Currency
    public let onTap: () -> Void

    public init(
        progress: BudgetProgress,
        currency: Currency = .default,
        onTap: @escaping () -> Void
    ) {
        self.progress = progress
        self.currency = currency
        self.onTap = onTap
    }

    public var body: some View {
        let statusColor = LeafTheme.budgetStatusColor(for: progress.status)
        let isOverall = progress.budget.isOverallBudget
        let category = progress.category

        Button(action: onTap) {
            SquircleCard(cornerRadius: 20) {
                VStack(spacing: 14) {
                    // Header Row: Category Badge + Title + Status Pill
                    HStack(spacing: 12) {
                        if let cat = category {
                            CategoryIconBadge(
                                iconName: cat.iconName,
                                colorHex: cat.colorHex,
                                size: 36
                            )
                        } else {
                            ZStack {
                                RoundedRectangle(cornerRadius: 11, style: .continuous)
                                    .fill(LeafTheme.accent(for: colorScheme).opacity(0.16))
                                    .frame(width: 36, height: 36)

                                Image(systemName: "chart.bar.fill")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundStyle(LeafTheme.accent(for: colorScheme))
                            }
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text(isOverall ? "Overall Budget" : (category?.name ?? "Category Budget"))
                                .font(LeafTypography.titleSmall)
                                .foregroundStyle(LeafTheme.textPrimary(for: colorScheme))
                                .lineLimit(1)

                            HStack(spacing: 4) {
                                Text(progress.budget.periodSummaryLabel)
                                    .font(LeafTypography.captionRegular)
                                    .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))

                                if progress.budget.isRecurring {
                                    Image(systemName: "arrow.triangle.2.circlepath")
                                        .font(.system(size: 9, weight: .bold))
                                        .foregroundStyle(LeafTheme.brandEmerald)
                                }
                            }
                        }

                        Spacer()

                        // 4-Tier Status Capsule
                        Text(progress.status.displayName)
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundStyle(statusColor)
                            .padding(.horizontal, 9)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(statusColor.opacity(0.12))
                            )
                    }

                    // Amounts Row
                    HStack(alignment: .firstTextBaseline) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("SPENT")
                                .font(LeafTypography.captionBold)
                                .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
                                .tracking(0.5)

                            Text(progress.usedAmount.formatted(currency: currency))
                                .font(.system(size: 20, weight: .bold, design: .rounded).monospacedDigit())
                                .foregroundStyle(LeafTheme.textPrimary(for: colorScheme))
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: 2) {
                            Text("LIMIT")
                                .font(LeafTypography.captionBold)
                                .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
                                .tracking(0.5)

                            Text(progress.budget.amount.formatted(currency: currency))
                                .font(.system(size: 15, weight: .semibold, design: .rounded).monospacedDigit())
                                .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
                        }
                    }

                    // Progress Bar
                    GeometryReader { geo in
                        let ratio = max(0.0, min(1.0, progress.percentageUsed / 100.0))
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill((colorScheme == .dark ? Color.white : Color.black).opacity(0.08))
                                .frame(height: 7)

                            Capsule()
                                .fill(statusColor)
                                .frame(width: max(4, geo.size.width * CGFloat(ratio)), height: 7)
                        }
                    }
                    .frame(height: 7)

                    // Footer Row: Remaining Amount & Percentage
                    HStack {
                        if progress.status == .overBudget {
                            let overspentSubunits = progress.usedAmount.subunits - progress.budget.amount.subunits
                            let overspent = Amount(subunits: overspentSubunits)
                            Text("\(overspent.formatted(currency: currency)) over limit")
                                .font(LeafTypography.captionBold)
                                .foregroundStyle(statusColor)
                        } else {
                            Text("\(progress.remainingAmount.formatted(currency: currency)) remaining")
                                .font(LeafTypography.captionRegular)
                                .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
                        }

                        Spacer()

                        Text(String(format: "%.0f%% utilized", progress.percentageUsed))
                            .font(LeafTypography.captionBold)
                            .foregroundStyle(statusColor)
                    }
                }
                .padding(16)
            }
        }
        .buttonStyle(.plain)
    }
}
