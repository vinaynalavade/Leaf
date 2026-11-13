import SwiftUI
import Charts

public enum SpendingChartMode: String, CaseIterable, Identifiable {
    case spendingCurve = "Spending Curve"
    case incomeVsExpense = "Income vs Expense"

    public var id: String { rawValue }
}

/// Interactive Swift Charts visualization rendering spending velocity and income comparisons.
public struct SpendingTrendsChartView: View {
    @Environment(\.colorScheme) private var colorScheme

    public let trendPoints: [SpendingTrendPoint]
    public let currency: Currency
    public let averageExpense: Amount

    @State private var chartMode: SpendingChartMode = .spendingCurve
    @State private var selectedPoint: SpendingTrendPoint? = nil

    public init(
        trendPoints: [SpendingTrendPoint],
        currency: Currency,
        averageExpense: Amount
    ) {
        self.trendPoints = trendPoints
        self.currency = currency
        self.averageExpense = averageExpense
    }

    private var hasData: Bool {
        trendPoints.contains { $0.expenseSubunits > 0 || $0.incomeSubunits > 0 }
    }

    private var averageExpenseDouble: Double {
        Double(averageExpense.subunits) / 100.0
    }

    public var body: some View {
        SquircleCard {
            VStack(alignment: .leading, spacing: 16) {
                // Top Header + Mode Picker
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("SPENDING VELOCITY")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .tracking(1.0)
                            .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))

                        if let selected = selectedPoint {
                            HStack(spacing: 6) {
                                Text(selected.label)
                                    .font(LeafTypography.caption)
                                    .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))

                                Text(selected.expenseAmount.formatted(with: currency))
                                    .font(.system(size: 15, weight: .bold, design: .rounded))
                                    .foregroundStyle(LeafTheme.expenseCoral)
                            }
                        } else {
                            Text("Avg: \(averageExpense.formatted(with: currency))")
                                .font(LeafTypography.caption)
                                .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
                        }
                    }

                    Spacer()

                    // Chart Mode Picker
                    Picker("Chart Mode", selection: $chartMode) {
                        ForEach(SpendingChartMode.allCases) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(maxWidth: 210)
                }

                if hasData {
                    chartContent
                        .frame(height: 220)
                } else {
                    VStack(spacing: 8) {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .font(.system(size: 32))
                            .foregroundStyle(LeafTheme.textTertiary(for: colorScheme))
                        Text("No transactions in this period")
                            .font(LeafTypography.subheadline)
                            .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
                    }
                    .frame(maxWidth: .infinity, minHeight: 180)
                }
            }
            .padding(16)
        }
    }

    @ViewBuilder
    private var chartContent: some View {
        switch chartMode {
        case .spendingCurve:
            Chart {
                // Gradient Area Fill
                ForEach(trendPoints) { point in
                    AreaMark(
                        x: .value("Date", point.label),
                        y: .value("Spending", point.expenseValue)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                LeafTheme.expenseCoral.opacity(0.35),
                                LeafTheme.expenseCoral.opacity(0.02)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .interpolationMethod(.monotone)

                    // Line Mark
                    LineMark(
                        x: .value("Date", point.label),
                        y: .value("Spending", point.expenseValue)
                    )
                    .foregroundStyle(LeafTheme.expenseCoral)
                    .lineStyle(StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
                    .interpolationMethod(.monotone)

                    // Point Marks
                    PointMark(
                        x: .value("Date", point.label),
                        y: .value("Spending", point.expenseValue)
                    )
                    .foregroundStyle(LeafTheme.expenseCoral)
                    .symbolSize(trendPoints.count <= 14 ? 30 : 10)
                }

                // Average Spending Reference Rule
                if averageExpenseDouble > 0 {
                    RuleMark(y: .value("Average", averageExpenseDouble))
                        .lineStyle(StrokeStyle(lineWidth: 1.2, dash: [5, 4]))
                        .foregroundStyle(LeafTheme.brandEmerald.opacity(0.7))
                        .annotation(position: .top, alignment: .trailing) {
                            Text("Avg")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(LeafTheme.brandEmerald)
                                .padding(.horizontal, 4)
                        }
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4, 4]))
                        .foregroundStyle(LeafTheme.cardBorder(for: colorScheme))
                    AxisValueLabel {
                        if let doubleValue = value.as(Double.self) {
                            Text(formatCompact(doubleValue))
                                .font(.system(size: 10, weight: .medium, design: .rounded))
                                .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
                        }
                    }
                }
            }
            .chartXAxis {
                AxisMarks { value in
                    AxisValueLabel {
                        if let label = value.as(String.self) {
                            Text(label)
                                .font(.system(size: 9, weight: .medium, design: .rounded))
                                .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
                        }
                    }
                }
            }

        case .incomeVsExpense:
            Chart {
                ForEach(trendPoints) { point in
                    BarMark(
                        x: .value("Date", point.label),
                        y: .value("Amount", point.incomeValue)
                    )
                    .foregroundStyle(LeafTheme.brandEmerald)
                    .position(by: .value("Type", "Income"))
                    .cornerRadius(4)

                    BarMark(
                        x: .value("Date", point.label),
                        y: .value("Amount", point.expenseValue)
                    )
                    .foregroundStyle(LeafTheme.expenseCoral)
                    .position(by: .value("Type", "Expense"))
                    .cornerRadius(4)
                }
            }
            .chartForegroundStyleScale([
                "Income": LeafTheme.brandEmerald,
                "Expense": LeafTheme.expenseCoral
            ])
            .chartLegend(position: .top, alignment: .trailing)
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4, 4]))
                        .foregroundStyle(LeafTheme.cardBorder(for: colorScheme))
                    AxisValueLabel {
                        if let doubleVal = value.as(Double.self) {
                            Text(formatCompact(doubleVal))
                                .font(.system(size: 10, weight: .medium, design: .rounded))
                                .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
                        }
                    }
                }
            }
            .chartXAxis {
                AxisMarks { value in
                    AxisValueLabel {
                        if let label = value.as(String.self) {
                            Text(label)
                                .font(.system(size: 9, weight: .medium, design: .rounded))
                                .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
                        }
                    }
                }
            }
        }
    }

    private func formatCompact(_ val: Double) -> String {
        if val >= 1_000_000 {
            return String(format: "%.1fM", val / 1_000_000.0)
        } else if val >= 1_000 {
            return String(format: "%.0fK", val / 1_000.0)
        } else {
            return String(format: "%.0f", val)
        }
    }
}

