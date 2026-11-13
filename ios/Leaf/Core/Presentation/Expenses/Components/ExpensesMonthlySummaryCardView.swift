import SwiftUI

/// Premium summary card presenting total monthly expenses, daily average burn rate,
/// transaction count, and month-over-month percentage change.
public struct ExpensesMonthlySummaryCardView: View {
    @Environment(\.colorScheme) private var colorScheme

    public let summary: MonthlyExpenseSummary
    public let currency: Currency

    public init(
        summary: MonthlyExpenseSummary,
        currency: Currency = .default
    ) {
        self.summary = summary
        self.currency = currency
    }

    public var body: some View {
        SquircleCard(cornerRadius: 24) {
            VStack(spacing: 16) {
                // Top: Total Expense & Month-over-Month Delta
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("TOTAL SPENT THIS MONTH")
                            .font(LeafTypography.captionBold)
                            .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
                            .tracking(0.5)

                        Spacer()

                        // Month-over-Month Comparison Pill
                        if let delta = summary.percentageChangeVsPreviousMonth {
                            let isDecrease = delta < 0
                            let deltaAbs = abs(delta)
                            HStack(spacing: 4) {
                                Image(systemName: isDecrease ? "arrow.down.right" : "arrow.up.right")
                                    .font(.system(size: 10, weight: .bold))
                                Text(String(format: "%.1f%% vs last mo", deltaAbs))
                                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                            }
                            .foregroundStyle(isDecrease ? LeafTheme.brandEmerald : LeafTheme.expenseCoral)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill((isDecrease ? LeafTheme.brandEmerald : LeafTheme.expenseCoral).opacity(0.12))
                            )
                        } else {
                            Text("Initial month")
                                .font(.system(size: 11, weight: .medium, design: .rounded))
                                .foregroundStyle(LeafTheme.textTertiary(for: colorScheme))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    Capsule()
                                        .fill(Color.gray.opacity(0.1))
                                )
                        }
                    }

                    // Main Total Figure
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text("-")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundStyle(LeafTheme.expenseCoral)

                        Text(summary.totalExpense.formatted(currency: currency))
                            .font(.system(size: 34, weight: .bold, design: .rounded).monospacedDigit())
                            .foregroundStyle(LeafTheme.textPrimary(for: colorScheme))
                    }
                }

                Divider()
                    .background(LeafTheme.cardBorder(for: colorScheme))

                // Bottom Sub-Wells: Transaction Count & Daily Average
                HStack(spacing: 12) {
                    // Left Well: Transaction Count
                    HStack(spacing: 10) {
                        ZStack {
                            Circle()
                                .fill(LeafTheme.infoBlue.opacity(0.12))
                                .frame(width: 36, height: 36)
                            Image(systemName: "receipt")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(LeafTheme.infoBlue)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Activity")
                                .font(LeafTypography.captionRegular)
                                .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))

                            Text("\(summary.transactionCount) txns")
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                .foregroundStyle(LeafTheme.textPrimary(for: colorScheme))
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill((colorScheme == .dark ? Color.white : Color.black).opacity(0.03))
                    )

                    // Right Well: Daily Average
                    HStack(spacing: 10) {
                        ZStack {
                            Circle()
                                .fill(LeafTheme.purpleAccent.opacity(0.12))
                                .frame(width: 36, height: 36)
                            Image(systemName: "chart.line.uptrend.xyaxis")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(LeafTheme.purpleAccent)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Daily Avg")
                                .font(LeafTypography.captionRegular)
                                .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))

                            Text("\(summary.dailyAverage.formatted(currency: currency))/d")
                                .font(.system(size: 14, weight: .bold, design: .rounded).monospacedDigit())
                                .foregroundStyle(LeafTheme.textPrimary(for: colorScheme))
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill((colorScheme == .dark ? Color.white : Color.black).opacity(0.03))
                    )
                }
            }
            .padding(18)
        }
        .padding(.horizontal)
    }
}

