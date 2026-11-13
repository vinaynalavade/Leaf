import SwiftUI

/// Section displaying current and historical budget performance, utilisation bars,
/// and warning/exceeded status indicators backed by actual database records.
public struct BudgetUtilisationSectionView: View {
    @Environment(\.colorScheme) private var colorScheme

    public let budgets: [BudgetInsightItem]
    public let currency: Currency
    public let onBudgetTap: (BudgetInsightItem) -> Void

    public init(
        budgets: [BudgetInsightItem],
        currency: Currency,
        onBudgetTap: @escaping (BudgetInsightItem) -> Void
    ) {
        self.budgets = budgets
        self.currency = currency
        self.onBudgetTap = onBudgetTap
    }

    private var activeBudgets: [BudgetInsightItem] {
        budgets.filter { !$0.isHistorical }
    }

    private var historicalBudgets: [BudgetInsightItem] {
        budgets.filter { $0.isHistorical }
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // MARK: - Current / Active Budgets Section
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("ACTIVE BUDGET HEALTH")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .tracking(1.0)
                        .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))

                    Spacer()

                    Text("\(activeBudgets.count) Active")
                        .font(LeafTypography.caption)
                        .foregroundStyle(LeafTheme.textTertiary(for: colorScheme))
                }
                .padding(.horizontal, 16)

                if activeBudgets.isEmpty && historicalBudgets.isEmpty {
                    SquircleCard {
                        VStack(spacing: 8) {
                            Image(systemName: "target")
                                .font(.system(size: 28))
                                .foregroundStyle(LeafTheme.textTertiary(for: colorScheme))
                            Text("No budgets recorded for this period")
                                .font(LeafTypography.subheadline)
                                .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(24)
                    }
                    .padding(.horizontal, 16)
                } else if !activeBudgets.isEmpty {
                    VStack(spacing: 8) {
                        ForEach(activeBudgets) { item in
                            budgetCard(item)
                        }
                    }
                    .padding(.horizontal, 16)
                }
            }

            // MARK: - Historical Budget Performance Section
            if !historicalBudgets.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        HStack(spacing: 5) {
                            Image(systemName: "clock.arrow.circlepath")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(LeafTheme.infoBlue)

                            Text("HISTORICAL BUDGET PERFORMANCE")
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                .tracking(1.0)
                                .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
                        }

                        Spacer()

                        Text("\(historicalBudgets.count) Past Records")
                            .font(LeafTypography.caption)
                            .foregroundStyle(LeafTheme.textTertiary(for: colorScheme))
                    }
                    .padding(.horizontal, 16)

                    VStack(spacing: 8) {
                        ForEach(historicalBudgets) { item in
                            budgetCard(item)
                        }
                    }
                    .padding(.horizontal, 16)
                }
            }
        }
    }

    @ViewBuilder
    private func budgetCard(_ item: BudgetInsightItem) -> some View {
        Button(action: { onBudgetTap(item) }) {
            SquircleCard {
                VStack(spacing: 12) {
                    HStack(alignment: .center) {
                        // Category Icon or Generic Target
                        if let cat = item.category {
                            CategoryIconBadge(
                                iconName: cat.iconName,
                                colorHex: cat.colorHex,
                                size: 36
                            )
                        } else {
                            ZStack {
                                Circle()
                                    .fill(LeafTheme.brandEmerald.opacity(0.16))
                                    .frame(width: 36, height: 36)
                                Image(systemName: "target")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundStyle(LeafTheme.brandEmerald)
                            }
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            HStack(spacing: 6) {
                                Text(item.category?.name ?? "Total Budget")
                                    .font(.system(size: 14, weight: .bold, design: .rounded))
                                    .foregroundStyle(LeafTheme.textPrimary(for: colorScheme))

                                if !item.periodLabel.isEmpty {
                                    Text("• \(item.periodLabel)")
                                        .font(LeafTypography.caption)
                                        .foregroundStyle(LeafTheme.textTertiary(for: colorScheme))
                                }
                            }

                            Text("\(item.spentAmount.formatted(with: currency)) of \(item.limitAmount.formatted(with: currency))")
                                .font(LeafTypography.caption)
                                .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
                        }

                        Spacer()

                        // Status Badge
                        statusBadge(item)
                    }

                    // Multi-Tier Progress Bar
                    GeometryReader { proxy in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(LeafTheme.cardBorder(for: colorScheme))
                                .frame(height: 7)

                            Capsule()
                                .fill(progressBarColor(item.status))
                                .frame(width: max(6, min(proxy.size.width, proxy.size.width * CGFloat(item.utilisationPercentage / 100.0))), height: 7)
                        }
                    }
                    .frame(height: 7)

                    HStack {
                        Text("\(String(format: "%.0f%%", item.utilisationPercentage)) used")
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))

                        Spacer()

                        if item.status == .overBudget {
                            let overspent = Amount(item.spentAmount.subunits - item.limitAmount.subunits)
                            Text("\(overspent.formatted(with: currency)) over limit")
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                .foregroundStyle(LeafTheme.expenseCoral)
                        } else {
                            Text("\(item.remainingAmount.formatted(with: currency)) remaining")
                                .font(.system(size: 11, weight: .semibold, design: .rounded))
                                .foregroundStyle(LeafTheme.brandEmerald)
                        }
                    }
                }
                .padding(14)
            }
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func statusBadge(_ item: BudgetInsightItem) -> some View {
        let (title, bg, fg): (String, Color, Color) = {
            switch item.status {
            case .overBudget:
                return ("Exceeded", LeafTheme.expenseCoral.opacity(0.14), LeafTheme.expenseCoral)
            case .limitReached:
                return ("Limit Reached", Color.orange.opacity(0.14), Color.orange)
            case .approachingLimit:
                return ("Nearing Limit", Color.orange.opacity(0.14), Color.orange)
            case .onTrack:
                return (item.isHistorical ? "Within Limit" : "On Track", LeafTheme.brandEmerald.opacity(0.14), LeafTheme.brandEmerald)
            }
        }()

        Text(title)
            .font(.system(size: 10, weight: .bold, design: .rounded))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Capsule().fill(bg))
            .foregroundStyle(fg)
    }

    private func progressBarColor(_ status: BudgetStatus) -> Color {
        switch status {
        case .overBudget: return LeafTheme.expenseCoral
        case .limitReached: return Color.orange
        case .approachingLimit: return Color.orange
        case .onTrack: return LeafTheme.brandEmerald
        }
    }
}
