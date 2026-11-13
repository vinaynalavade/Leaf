import SwiftUI

/// Section displaying segregated savings goals progress, total saved,
/// contributions, withdrawals, net contributions, and recent savings activity feed.
public struct SavingsGrowthSectionView: View {
    @Environment(\.colorScheme) private var colorScheme

    public let savingsSummary: InsightsSavingsSummary
    public let currency: Currency

    public init(savingsSummary: InsightsSavingsSummary, currency: Currency) {
        self.savingsSummary = savingsSummary
        self.currency = currency
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header
            HStack {
                Text("SAVINGS GOALS & ACTIVITY")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .tracking(1.0)
                    .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))

                Spacer()

                Text("Segregated from spend")
                    .font(LeafTypography.caption)
                    .foregroundStyle(LeafTheme.textTertiary(for: colorScheme))
            }
            .padding(.horizontal, 16)

            // Main Savings Overview Card
            SquircleCard {
                VStack(spacing: 16) {
                    // Total Saved Across Active Goals
                    HStack(alignment: .center) {
                        VStack(alignment: .leading, spacing: 3) {
                            Text("TOTAL SAVED ACROSS GOALS")
                                .font(.system(size: 10, weight: .bold, design: .rounded))
                                .tracking(0.8)
                                .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))

                            Text(savingsSummary.totalSavedAcrossActiveGoals.formatted(with: currency))
                                .font(.system(size: 22, weight: .bold, design: .rounded))
                                .foregroundStyle(LeafTheme.brandEmerald)
                        }

                        Spacer()

                        // Net Period Movement Badge
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("NET SAVINGS MOVEMENT")
                                .font(.system(size: 9, weight: .bold, design: .rounded))
                                .tracking(0.6)
                                .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))

                            let net = savingsSummary.netContributionsTotal
                            Text("\(net.subunits >= 0 ? "+" : "")\(net.formatted(with: currency))")
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                .foregroundStyle(net.subunits >= 0 ? LeafTheme.brandEmerald : LeafTheme.expenseCoral)
                        }
                    }

                    // 3-Well Breakdown: Contributions, Withdrawals, Net
                    HStack(spacing: 8) {
                        miniMetricPill(
                            title: "CONTRIBUTIONS",
                            value: "+\(savingsSummary.periodContributionsTotal.formatted(with: currency))",
                            color: LeafTheme.brandEmerald
                        )

                        miniMetricPill(
                            title: "WITHDRAWALS",
                            value: "-\(savingsSummary.periodWithdrawalsTotal.formatted(with: currency))",
                            color: LeafTheme.warningAmber
                        )

                        miniMetricPill(
                            title: "ACTIVE GOALS",
                            value: "\(savingsSummary.activeGoalsCount)",
                            color: LeafTheme.infoBlue
                        )
                    }

                    // Goals Progress Bars
                    if !savingsSummary.goals.isEmpty {
                        Divider()
                            .overlay(LeafTheme.cardBorder(for: colorScheme))

                        VStack(spacing: 12) {
                            ForEach(savingsSummary.goals) { item in
                                goalItemRow(item)
                            }
                        }
                    } else {
                        Text("No active savings goals found")
                            .font(LeafTypography.caption)
                            .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
                            .padding(.vertical, 8)
                    }
                }
                .padding(16)
            }
            .padding(.horizontal, 16)

            // Period Contribution & Withdrawal History Feed
            if !savingsSummary.recentActivity.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("PERIOD SAVINGS HISTORY")
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .tracking(0.8)
                            .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))

                        Spacer()

                        Text("\(savingsSummary.recentActivity.count) events")
                            .font(LeafTypography.caption)
                            .foregroundStyle(LeafTheme.textTertiary(for: colorScheme))
                    }
                    .padding(.horizontal, 16)

                    VStack(spacing: 6) {
                        ForEach(savingsSummary.recentActivity) { activity in
                            savingsActivityRow(activity)
                        }
                    }
                    .padding(.horizontal, 16)
                }
            }
        }
    }

    // MARK: - Sub-Views

    @ViewBuilder
    private func miniMetricPill(title: String, value: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.system(size: 8, weight: .bold, design: .rounded))
                .tracking(0.5)
                .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))

            Text(value)
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(color)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(colorScheme == .dark ? LeafTheme.surfaceDark : LeafTheme.surfaceLight)
        )
    }

    @ViewBuilder
    private func goalItemRow(_ item: SavingsGoalInsightItem) -> some View {
        VStack(spacing: 6) {
            HStack {
                HStack(spacing: 8) {
                    Circle()
                        .fill(Color(hex: item.goal.colorHex))
                        .frame(width: 8, height: 8)

                    Text(item.goal.name)
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(LeafTheme.textPrimary(for: colorScheme))
                }

                Spacer()

                Text("\(item.currentAmount.formatted(with: currency)) of \(item.targetAmount.formatted(with: currency))")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
            }

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(LeafTheme.cardBorder(for: colorScheme))
                        .frame(height: 6)

                    Capsule()
                        .fill(Color(hex: item.goal.colorHex))
                        .frame(width: max(4, min(proxy.size.width, proxy.size.width * CGFloat(item.progressPercentage / 100.0))), height: 6)
                }
            }
            .frame(height: 6)

            HStack {
                Text("\(String(format: "%.0f%%", item.progressPercentage)) funded")
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .foregroundStyle(LeafTheme.textTertiary(for: colorScheme))

                Spacer()

                if item.periodContributionsTotal.subunits > 0 || item.periodWithdrawalsTotal.subunits > 0 {
                    let net = item.netContributionsTotal
                    Text("Net: \(net.subunits >= 0 ? "+" : "")\(net.formatted(with: currency)) this period")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundStyle(net.subunits >= 0 ? LeafTheme.brandEmerald : LeafTheme.warningAmber)
                }
            }
        }
    }

    @ViewBuilder
    private func savingsActivityRow(_ activity: SavingsActivityItem) -> some View {
        SquircleCard {
            HStack(spacing: 10) {
                // Event Icon
                ZStack {
                    Circle()
                        .fill((activity.isWithdrawal ? LeafTheme.warningAmber : LeafTheme.brandEmerald).opacity(0.14))
                        .frame(width: 32, height: 32)

                    Image(systemName: activity.isWithdrawal ? "arrow.down.right" : "arrow.up.right")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(activity.isWithdrawal ? LeafTheme.warningAmber : LeafTheme.brandEmerald)
                }

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(activity.isWithdrawal ? "Withdrawal" : "Deposit")
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundStyle(LeafTheme.textPrimary(for: colorScheme))

                        Text("• \(activity.goalName)")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
                            .lineLimit(1)
                    }

                    HStack(spacing: 6) {
                        Text(activity.formattedDate)
                            .font(LeafTypography.caption)
                            .foregroundStyle(LeafTheme.textTertiary(for: colorScheme))

                        if let note = activity.note, !note.isEmpty {
                            Text("• \(note)")
                                .font(LeafTypography.caption)
                                .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
                                .lineLimit(1)
                        }
                    }
                }

                Spacer()

                Text("\(activity.isWithdrawal ? "-" : "+")\(activity.amount.formatted(with: currency))")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(activity.isWithdrawal ? LeafTheme.warningAmber : LeafTheme.brandEmerald)
            }
            .padding(10)
        }
    }
}
