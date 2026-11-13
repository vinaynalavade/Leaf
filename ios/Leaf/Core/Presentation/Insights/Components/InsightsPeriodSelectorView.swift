import SwiftUI
import UIKit

/// Horizontal scrollable period selector pills with dynamic date range caption.
public struct InsightsPeriodSelectorView: View {
    @Environment(\.colorScheme) private var colorScheme

    public let selectedPeriod: InsightsPeriod
    public let onSelectPeriod: (InsightsPeriod) -> Void
    public let onCustomTap: () -> Void

    private let periods: [InsightsPeriod] = [
        .thisWeek,
        .thisMonth,
        .lastMonth,
        .last3Months,
        .last6Months,
        .thisYear
    ]

    public init(
        selectedPeriod: InsightsPeriod,
        onSelectPeriod: @escaping (InsightsPeriod) -> Void,
        onCustomTap: @escaping () -> Void
    ) {
        self.selectedPeriod = selectedPeriod
        self.onSelectPeriod = onSelectPeriod
        self.onCustomTap = onCustomTap
    }

    private func triggerHaptic() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.prepare()
        generator.impactOccurred()
    }

    public var body: some View {
        VStack(spacing: 8) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(periods, id: \.id) { period in
                        periodPill(
                            title: period.title,
                            isSelected: isPeriodSelected(period)
                        ) {
                            triggerHaptic()
                            onSelectPeriod(period)
                        }
                    }

                    // Custom Date Range Pill
                    let isCustom = isCustomSelected()
                    periodPill(
                        title: isCustom ? "Custom" : "Custom...",
                        isSelected: isCustom
                    ) {
                        triggerHaptic()
                        onCustomTap()
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 4)
            }

            // Current Period Subtitle Range Caption
            Text(selectedPeriod.formattedRange())
                .font(LeafTypography.caption)
                .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
                .padding(.horizontal, 16)
        }
    }

    private func isPeriodSelected(_ period: InsightsPeriod) -> Bool {
        switch (selectedPeriod, period) {
        case (.thisWeek, .thisWeek),
             (.thisMonth, .thisMonth),
             (.lastMonth, .lastMonth),
             (.last3Months, .last3Months),
             (.last6Months, .last6Months),
             (.thisYear, .thisYear):
            return true
        default:
            return false
        }
    }

    private func isCustomSelected() -> Bool {
        if case .custom = selectedPeriod {
            return true
        }
        return false
    }

    @ViewBuilder
    private func periodPill(
        title: String,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 13, weight: isSelected ? .bold : .medium, design: .rounded))
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(
                    Capsule(style: .continuous)
                        .fill(isSelected ? LeafTheme.brandEmerald : (colorScheme == .dark ? LeafTheme.cardDark : LeafTheme.cardLight))
                )
                .foregroundStyle(isSelected ? Color.white : LeafTheme.textPrimary(for: colorScheme))
                .overlay(
                    Capsule(style: .continuous)
                        .stroke(isSelected ? Color.clear : LeafTheme.cardBorder(for: colorScheme), lineWidth: 0.8)
                )
        }
        .buttonStyle(.plain)
    }
}

