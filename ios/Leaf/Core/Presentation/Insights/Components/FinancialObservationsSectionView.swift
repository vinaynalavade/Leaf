import SwiftUI

/// Horizontal carousel of intelligent rule-based observations and financial alerts.
public struct FinancialObservationsSectionView: View {
    @Environment(\.colorScheme) private var colorScheme

    public let observations: [FinancialObservation]
    public let onAction: (ObservationAction) -> Void

    public init(
        observations: [FinancialObservation],
        onAction: @escaping (ObservationAction) -> Void
    ) {
        self.observations = observations
        self.onAction = onAction
    }

    public var body: some View {
        if !observations.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 6) {
                    Image(systemName: "lightbulb.fill")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(LeafTheme.brandEmerald)

                    Text("OBSERVATIONS & ALERTS")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .tracking(1.0)
                        .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
                }
                .padding(.horizontal, 16)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(observations) { obs in
                            observationCard(obs)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 2)
                }
            }
        }
    }

    @ViewBuilder
    private func observationCard(_ obs: FinancialObservation) -> some View {
        Button(action: {
            if let action = obs.action {
                onAction(action)
            }
        }) {
            HStack(alignment: .top, spacing: 12) {
                // Sentiment Icon Badge
                ZStack {
                    Circle()
                        .fill(sentimentColor(obs.sentiment).opacity(0.16))
                        .frame(width: 36, height: 36)

                    Image(systemName: obs.iconName)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(sentimentColor(obs.sentiment))
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 4) {
                        Text(obs.title)
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundStyle(LeafTheme.textPrimary(for: colorScheme))
                            .lineLimit(1)

                        Spacer()

                        if obs.action != nil {
                            Image(systemName: "chevron.right")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
                        }
                    }

                    Text(obs.message)
                        .font(.system(size: 12, weight: .regular))
                        .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
                        .lineLimit(3)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(width: 280, alignment: .leading)
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(colorScheme == .dark ? LeafTheme.cardDark : LeafTheme.cardLight)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(LeafTheme.cardBorder(for: colorScheme), lineWidth: 0.8)
            )
        }
        .buttonStyle(.plain)
    }

    private func sentimentColor(_ sentiment: ObservationSentiment) -> Color {
        switch sentiment {
        case .positive: return LeafTheme.brandEmerald
        case .warning: return Color.orange
        case .critical: return LeafTheme.expenseCoral
        case .neutral: return LeafTheme.infoBlue
        }
    }
}

