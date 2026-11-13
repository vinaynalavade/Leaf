import SwiftUI

/// Specialized card displaying a subscription service with billing frequency and monthly cost normalization.
public struct SubscriptionCardView: View {
    @Environment(\.colorScheme) private var colorScheme

    public let subscription: RecurringTransaction
    public let currency: Currency
    public let onTap: () -> Void

    public init(
        subscription: RecurringTransaction,
        currency: Currency,
        onTap: @escaping () -> Void
    ) {
        self.subscription = subscription
        self.currency = currency
        self.onTap = onTap
    }

    private var nextRenewalString: String {
        guard let epoch = subscription.nextOccurrenceDate else { return "No renewal scheduled" }
        let cal = Calendar.current
        let renewalDate = Date(timeIntervalSince1970: Double(epoch) / 1000.0)
        let diff = cal.dateComponents([.day], from: cal.startOfDay(for: Date()), to: cal.startOfDay(for: renewalDate)).day ?? 0

        if diff < 0 {
            return "Overdue"
        } else if diff == 0 {
            return "Renews today"
        } else if diff == 1 {
            return "Renews tomorrow"
        } else {
            return "Renews in \(diff) days"
        }
    }

    public var body: some View {
        Button(action: onTap) {
            SquircleCard(cornerRadius: 16) {
                HStack(spacing: 12) {
                    CategoryIconBadge(
                        iconName: subscription.category?.iconName ?? "play.rectangle.fill",
                        colorHex: subscription.category?.colorHex ?? "#8B5CF6",
                        size: 42
                    )

                    VStack(alignment: .leading, spacing: 3) {
                        Text(subscription.title)
                            .font(LeafTypography.bodyBold)
                            .foregroundStyle(LeafTheme.textPrimary(for: colorScheme))
                            .lineLimit(1)

                        HStack(spacing: 6) {
                            Text(subscription.frequency.displayName)
                                .font(LeafTypography.caption)
                                .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))

                            Text("•")
                                .font(LeafTypography.caption)
                                .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))

                            Text(nextRenewalString)
                                .font(LeafTypography.captionBold)
                                .foregroundStyle(LeafTheme.purpleAccent)
                        }
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 2) {
                        Text(subscription.amount.formatted(currency: currency))
                            .font(LeafTypography.bodyBold)
                            .foregroundStyle(LeafTheme.textPrimary(for: colorScheme))

                        Text("~\(subscription.estimatedMonthlyAmount.formatted(currency: currency))/mo")
                            .font(LeafTypography.captionRegular)
                            .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
                    }
                }
                .padding(14)
            }
        }
        .buttonStyle(.plain)
    }
}

