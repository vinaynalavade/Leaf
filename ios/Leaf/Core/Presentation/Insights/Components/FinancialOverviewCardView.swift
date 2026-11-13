import SwiftUI

/// Luxury fintech card clearly separating Operating Cash Flow from Checking Balance Movement,
/// presenting distinct Unspent Income Rate and Goal Savings Contribution Rate metrics.
public struct FinancialOverviewCardView: View {
    @Environment(\.colorScheme) private var colorScheme

    public let overview: InsightsFinancialOverview
    public let currency: Currency

    public init(overview: InsightsFinancialOverview, currency: Currency) {
        self.overview = overview
        self.currency = currency
    }

    public var body: some View {
        SquircleCard {
            VStack(alignment: .leading, spacing: 18) {
                // MARK: - 1. Operating Cash Flow (Primary Metric)
                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 6) {
                            Text("OPERATING CASH FLOW")
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                .tracking(1.2)
                                .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))

                            Text("• Ordinary")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundStyle(LeafTheme.textTertiary(for: colorScheme))
                        }

                        HStack(alignment: .center, spacing: 8) {
                            Text(overview.operatingCashFlow.formatted(with: currency))
                                .font(LeafTypography.balanceHero)
                                .foregroundStyle(
                                    overview.operatingCashFlow.subunits >= 0
                                        ? LeafTheme.brandEmerald
                                        : LeafTheme.expenseCoral
                                )

                            if let prevOperating = overview.previousOperatingCashFlow {
                                let deltaSubunits = overview.operatingCashFlow.subunits - prevOperating.subunits
                                let isPositive = deltaSubunits >= 0
                                HStack(spacing: 3) {
                                    Image(systemName: isPositive ? "arrow.up.right" : "arrow.down.right")
                                        .font(.system(size: 10, weight: .bold))
                                    Text(Amount(abs(deltaSubunits)).formatted(with: currency))
                                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                                }
                                .padding(.horizontal, 7)
                                .padding(.vertical, 3)
                                .background(
                                    Capsule()
                                        .fill((isPositive ? LeafTheme.brandEmerald : LeafTheme.expenseCoral).opacity(0.14))
                                )
                                .foregroundStyle(isPositive ? LeafTheme.brandEmerald : LeafTheme.expenseCoral)
                            }
                        }

                        Text("Earned income minus ordinary expenses (excludes internal transfers)")
                            .font(.system(size: 10, weight: .regular))
                            .foregroundStyle(LeafTheme.textTertiary(for: colorScheme))
                    }

                    Spacer()
                }

                Divider()
                    .overlay(LeafTheme.cardBorder(for: colorScheme))

                // MARK: - 2. Operating Cash Flow Components (Income vs Ordinary Spend)
                HStack(spacing: 12) {
                    cashflowWell(
                        title: "EARNED INCOME",
                        subtitle: "Excludes withdrawals",
                        amount: overview.earnedIncome,
                        icon: "arrow.up.circle.fill",
                        tintColor: LeafTheme.brandEmerald,
                        changePercentage: overview.incomeChangePercentage
                    )

                    cashflowWell(
                        title: "ORDINARY SPEND",
                        subtitle: "Excludes deposits",
                        amount: overview.ordinaryExpenses,
                        icon: "arrow.down.circle.fill",
                        tintColor: LeafTheme.expenseCoral,
                        changePercentage: overview.expenseChangePercentage
                    )
                }

                // MARK: - 3. Distinct Rates: Unspent Income Rate vs Actual Savings Rate
                HStack(spacing: 10) {
                    // Left: Unspent Income Rate
                    rateBadgeCard(
                        title: "UNSPENT INCOME RATE",
                        rate: overview.unspentIncomeRate,
                        description: "Income retained after expenses",
                        tintColor: overview.unspentIncomeRate >= 20 ? LeafTheme.brandEmerald : LeafTheme.textPrimary(for: colorScheme)
                    )

                    // Right: Actual Goal Savings Rate
                    rateBadgeCard(
                        title: "GOAL SAVINGS RATE",
                        rate: overview.actualSavingsRate,
                        description: "Net deposits into goals",
                        tintColor: overview.actualSavingsRate > 0 ? LeafTheme.infoBlue : LeafTheme.textSecondary(for: colorScheme)
                    )
                }

                Divider()
                    .overlay(LeafTheme.cardBorder(for: colorScheme))

                // MARK: - 4. Checking Balance Movement Section
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        HStack(spacing: 5) {
                            Image(systemName: "creditcard.and.123")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(LeafTheme.infoBlue)

                            Text("CHECKING BALANCE MOVEMENT")
                                .font(.system(size: 10, weight: .bold, design: .rounded))
                                .tracking(0.8)
                                .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
                        }

                        Spacer()

                        Text(overview.checkingBalanceMovement.formatted(with: currency))
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundStyle(
                                overview.checkingBalanceMovement.subunits >= 0
                                    ? LeafTheme.brandEmerald
                                    : LeafTheme.expenseCoral
                            )
                    }

                    HStack(spacing: 16) {
                        Text("Inflow: +\(overview.totalCheckingInflow.formatted(with: currency))")
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundStyle(LeafTheme.brandEmerald)

                        Text("Outflow: -\(overview.totalCheckingOutflow.formatted(with: currency))")
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundStyle(LeafTheme.expenseCoral)

                        Spacer()

                        if overview.savingsSummary.periodContributionsTotal.subunits > 0 || overview.savingsSummary.periodWithdrawalsTotal.subunits > 0 {
                            Text("(Includes savings transfers)")
                                .font(.system(size: 10, weight: .regular))
                                .foregroundStyle(LeafTheme.textTertiary(for: colorScheme))
                        }
                    }
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(colorScheme == .dark ? LeafTheme.surfaceDark : LeafTheme.surfaceLight)
                )

                // MARK: - 5. Segregated Savings Goals Callout
                if overview.savingsSummary.periodContributionsTotal.subunits > 0 || overview.savingsSummary.totalSavedAcrossActiveGoals.subunits > 0 {
                    HStack(spacing: 10) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(LeafTheme.brandEmerald)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Savings Goals Activity (Segregated from Ordinary Spend)")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))

                            Text("Net Goal Deposits: +\(overview.netSavingsContributions.formatted(with: currency)) (\(overview.savingsSummary.totalSavedAcrossActiveGoals.formatted(with: currency)) total across active goals)")
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                .foregroundStyle(LeafTheme.textPrimary(for: colorScheme))
                        }

                        Spacer()
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(LeafTheme.brandEmerald.opacity(0.08))
                    )
                }
            }
            .padding(16)
        }
    }

    // MARK: - Sub-Components

    @ViewBuilder
    private func cashflowWell(
        title: String,
        subtitle: String,
        amount: Amount,
        icon: String,
        tintColor: Color,
        changePercentage: Double?
    ) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(tintColor)

                Text(title)
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .tracking(0.6)
                    .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
            }

            Text(amount.formatted(with: currency))
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(LeafTheme.textPrimary(for: colorScheme))
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Text(subtitle)
                .font(.system(size: 9, weight: .regular))
                .foregroundStyle(LeafTheme.textTertiary(for: colorScheme))

            if let pct = changePercentage {
                let isIncrease = pct > 0
                let displayText = String(format: "%@%.1f%% vs prev", isIncrease ? "+" : "", pct)

                Text(displayText)
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .foregroundStyle(
                        tintColor == LeafTheme.expenseCoral
                            ? (isIncrease ? LeafTheme.expenseCoral : LeafTheme.brandEmerald)
                            : (isIncrease ? LeafTheme.brandEmerald : LeafTheme.expenseCoral)
                    )
            } else {
                Text("No prior data")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(LeafTheme.textTertiary(for: colorScheme))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(colorScheme == .dark ? LeafTheme.surfaceDark : LeafTheme.surfaceLight)
        )
    }

    @ViewBuilder
    private func rateBadgeCard(
        title: String,
        rate: Double,
        description: String,
        tintColor: Color
    ) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.system(size: 9, weight: .bold, design: .rounded))
                .tracking(0.6)
                .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))

            Text(String(format: "%.1f%%", max(0.0, rate)))
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(tintColor)

            Text(description)
                .font(.system(size: 9, weight: .regular))
                .foregroundStyle(LeafTheme.textTertiary(for: colorScheme))
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(colorScheme == .dark ? LeafTheme.surfaceDark : LeafTheme.surfaceLight)
        )
    }
}
