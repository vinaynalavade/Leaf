import SwiftUI

/// Section view presenting the featured monthly budget progress or an inviting empty state prompt.
/// Renders the master documentation's 4-tier threshold indicator with continuous progress animation.
public struct DashboardBudgetSectionView: View {
    @Environment(\.colorScheme) private var colorScheme

    public let budgetProgress: BudgetProgress?
    public let currency: Currency
    public let isBalanceVisible: Bool
    public let onBudgetTap: () -> Void

    public init(
        budgetProgress: BudgetProgress?,
        currency: Currency = .default,
        isBalanceVisible: Bool = true,
        onBudgetTap: @escaping () -> Void
    ) {
        self.budgetProgress = budgetProgress
        self.currency = currency
        self.isBalanceVisible = isBalanceVisible
        self.onBudgetTap = onBudgetTap
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("MONTHLY BUDGET")
                    .font(LeafTypography.captionBold)
                    .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))

                Spacer()

                Button(action: onBudgetTap) {
                    HStack(spacing: 4) {
                        Text(budgetProgress != nil ? "Manage" : "Set Up")
                            .font(LeafTypography.captionBold)
                            .foregroundStyle(LeafTheme.accent(for: colorScheme))

                        Image(systemName: "chevron.right")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(LeafTheme.accent(for: colorScheme))
                    }
                }
            }
            .padding(.horizontal)

            if let progress = budgetProgress {
                activeBudgetCard(progress)
            } else {
                emptyBudgetCard
            }
        }
    }

    @ViewBuilder
    private func activeBudgetCard(_ progress: BudgetProgress) -> some View {
        let statusColor = LeafTheme.budgetStatusColor(for: progress.status)
        let isOver = progress.status == .overBudget

        Button(action: onBudgetTap) {
            SquircleCard(cornerRadius: 20) {
                VStack(spacing: 14) {
                    // Title Row: Category / Overall Badge + Status Pill
                    HStack(spacing: 12) {
                        if let category = progress.category {
                            CategoryIconBadge(
                                iconName: category.iconName,
                                colorHex: category.colorHex,
                                size: 38
                            )
                        } else {
                            ZStack {
                                RoundedRectangle(cornerRadius: 11, style: .continuous)
                                    .fill(LeafTheme.accent(for: colorScheme).opacity(0.16))
                                    .frame(width: 38, height: 38)

                                Image(systemName: "chart.bar.fill")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundStyle(LeafTheme.accent(for: colorScheme))
                            }
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text(progress.category?.name ?? "Overall Monthly Budget")
                                .font(LeafTypography.titleSmall)
                                .foregroundStyle(LeafTheme.textPrimary(for: colorScheme))

                            Text(String(format: "%.0f%% used", progress.percentageUsed))
                                .font(LeafTypography.captionBold)
                                .foregroundStyle(statusColor)
                        }

                        Spacer()

                        // Status badge capsule
                        Text(progress.status.displayName)
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(statusColor)
                            .padding(.horizontal, 9)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(statusColor.opacity(0.12))
                            )
                    }

                    // 4-Tier Color Progress Bar
                    GeometryReader { geometry in
                        let clampedFraction = min(1.0, max(0.0, progress.percentageUsed / 100.0))
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(LeafTheme.cardBorder(for: colorScheme))
                                .frame(height: 7)

                            Capsule()
                                .fill(statusColor)
                                .frame(width: geometry.size.width * CGFloat(clampedFraction), height: 7)
                                .animation(.easeOut(duration: 0.5), value: clampedFraction)
                        }
                    }
                    .frame(height: 7)

                    // Figures Breakdown: Spent vs Remaining
                    HStack {
                        HStack(spacing: 4) {
                            Text("Spent:")
                                .font(LeafTypography.caption)
                                .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))

                            Text(isBalanceVisible ? progress.usedAmount.format(currency: currency) : "\(currency.symbol)••••••")
                                .font(LeafTypography.captionBold)
                                .foregroundStyle(LeafTheme.textPrimary(for: colorScheme))
                        }

                        Spacer()

                        HStack(spacing: 4) {
                            Text(isOver ? "Exceeded:" : "Remaining:")
                                .font(LeafTypography.caption)
                                .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))

                            let displayAmount = isOver
                                ? Amount(subunits: progress.usedAmount.subunits - progress.budget.amount.subunits)
                                : progress.remainingAmount

                            Text(isBalanceVisible ? displayAmount.format(currency: currency) : "\(currency.symbol)••••••")
                                .font(LeafTypography.captionBold)
                                .foregroundStyle(statusColor)
                        }
                    }
                }
                .padding(18)
            }
        }
        .buttonStyle(.plain)
        .padding(.horizontal)
    }

    private var emptyBudgetCard: some View {
        Button(action: onBudgetTap) {
            SquircleCard(cornerRadius: 20) {
                HStack(spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(LeafTheme.brandEmerald.opacity(0.14))
                            .frame(width: 44, height: 44)

                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundStyle(LeafTheme.brandEmerald)
                    }

                    VStack(alignment: .leading, spacing: 3) {
                        Text("Set Monthly Budget")
                            .font(LeafTypography.titleSmall)
                            .foregroundStyle(LeafTheme.textPrimary(for: colorScheme))

                        Text("Take control and prevent overspending")
                            .font(LeafTypography.caption)
                            .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(LeafTheme.textSecondary(for: colorScheme).opacity(0.6))
                }
                .padding(18)
            }
        }
        .buttonStyle(.plain)
        .padding(.horizontal)
    }
}

