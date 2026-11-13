import SwiftUI
import Charts

/// Swift Charts component visualizing group spending volume over daily or monthly intervals.
public struct SplitGroupSpendingTimelineChart: View {
    @Environment(\.colorScheme) private var colorScheme

    public let timelinePoints: [SplitGroupTimelinePoint]
    public let currency: Currency

    @State private var selectedPoint: SplitGroupTimelinePoint? = nil

    public init(
        timelinePoints: [SplitGroupTimelinePoint],
        currency: Currency
    ) {
        self.timelinePoints = timelinePoints
        self.currency = currency
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if !timelinePoints.isEmpty {
                // Interactive Selection Banner
                if let selected = selectedPoint {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(selected.dateLabel)
                                .font(LeafTypography.captionBold)
                                .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
                            Text("\(selected.expenseCount) expense\(selected.expenseCount == 1 ? "" : "s")")
                                .font(.system(size: 11))
                                .foregroundStyle(LeafTheme.textTertiary(for: colorScheme))
                        }
                        Spacer()
                        Text(selected.totalAmount.formatted(with: currency))
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundStyle(LeafTheme.brandEmerald)
                    }
                    .padding(.horizontal, 4)
                }

                Chart(timelinePoints) { point in
                    BarMark(
                        x: .value("Date", point.dateLabel),
                        y: .value("Amount", point.totalAmount.subunits)
                    )
                    .cornerRadius(4)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [LeafTheme.brandEmerald, LeafTheme.brandEmerald.opacity(0.65)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .opacity(selectedPoint == nil || selectedPoint?.id == point.id ? 1.0 : 0.4)
                }
                .chartYAxis {
                    AxisMarks(position: .leading) { (value: AxisValue) in
                        if let subunits = value.as(Int64.self) {
                            AxisValueLabel {
                                Text(Amount(subunits: subunits).formatted(with: currency))
                                    .font(.system(size: 10, design: .rounded))
                                    .foregroundStyle(LeafTheme.textTertiary(for: colorScheme))
                            }
                        }
                    }
                }
                .chartXAxis {
                    AxisMarks { (value: AxisValue) in
                        AxisValueLabel {
                            if let label = value.as(String.self) {
                                Text(label)
                                    .font(.system(size: 9, design: .rounded))
                                    .foregroundStyle(LeafTheme.textTertiary(for: colorScheme))
                            }
                        }
                    }
                }
                .frame(height: 180)
            } else {
                VStack(spacing: 8) {
                    Image(systemName: "chart.bar.xaxis")
                        .font(.system(size: 32))
                        .foregroundStyle(LeafTheme.textTertiary(for: colorScheme))
                    Text("No timeline activity in this period")
                        .font(LeafTypography.caption)
                        .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
                }
                .frame(maxWidth: .infinity, minHeight: 140)
            }
        }
    }
}

