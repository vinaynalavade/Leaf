import SwiftUI

/// Premium summary card presenting net split position, amounts owed/owing, and active splits count.
public struct SplitFinancialOverviewCardView: View {
    @Environment(\.colorScheme) private var colorScheme

    public let summary: GroupBalanceSummary
    public let currency: Currency

    public init(
        summary: GroupBalanceSummary,
        currency: Currency = .default
    ) {
        self.summary = summary
        self.currency = currency
    }

    public var body: some View {
        SquircleCard(cornerRadius: 24) {
            VStack(spacing: 16) {
                // Top: Primary Net Balance Indicator
                VStack(alignment: .leading, spacing: 6) {
                    Text("SPLIT & COLLECT POSITION")
                        .font(LeafTypography.captionBold)
                        .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
                        .tracking(0.5)

                    let owedSubunits = summary.netOwedToCurrentUser.subunits
                    let oweSubunits = summary.netCurrentUserOwes.subunits
                    let netDiff = owedSubunits - oweSubunits

                    if netDiff > 0 {
                        HStack(alignment: .firstTextBaseline, spacing: 6) {
                            Text("+ " + Amount(subunits: netDiff).formatted(currency: currency))
                                .font(.system(size: 32, weight: .bold, design: .rounded).monospacedDigit())
                                .foregroundStyle(LeafTheme.brandEmerald)

                            Text("owed to you")
                                .font(LeafTypography.captionRegular)
                                .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
                        }
                    } else if netDiff < 0 {
                        HStack(alignment: .firstTextBaseline, spacing: 6) {
                            Text("- " + Amount(subunits: -netDiff).formatted(currency: currency))
                                .font(.system(size: 32, weight: .bold, design: .rounded).monospacedDigit())
                                .foregroundStyle(LeafTheme.expenseCoral)

                            Text("you owe")
                                .font(LeafTypography.captionRegular)
                                .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
                        }
                    } else {
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(LeafTheme.brandEmerald)
                            Text("All settled up")
                                .font(.system(size: 26, weight: .bold, design: .rounded))
                                .foregroundStyle(LeafTheme.textPrimary(for: colorScheme))
                        }
                    }
                }

                Divider()
                    .background(LeafTheme.cardBorder(for: colorScheme))

                // Bottom Sub-Wells
                HStack(spacing: 10) {
                    // Sub-well 1: Others Owe You
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.down.left")
                                .font(.system(size: 10, weight: .bold))
                            Text("Owed to You")
                                .font(LeafTypography.captionRegular)
                        }
                        .foregroundStyle(LeafTheme.brandEmerald)

                        Text(summary.netOwedToCurrentUser.formatted(currency: currency))
                            .font(.system(size: 14, weight: .bold, design: .rounded).monospacedDigit())
                            .foregroundStyle(LeafTheme.textPrimary(for: colorScheme))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(10)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill((colorScheme == .dark ? Color.white : Color.black).opacity(0.03))
                    )

                    // Sub-well 2: You Owe
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.up.right")
                                .font(.system(size: 10, weight: .bold))
                            Text("You Owe")
                                .font(LeafTypography.captionRegular)
                        }
                        .foregroundStyle(LeafTheme.expenseCoral)

                        Text(summary.netCurrentUserOwes.formatted(currency: currency))
                            .font(.system(size: 14, weight: .bold, design: .rounded).monospacedDigit())
                            .foregroundStyle(LeafTheme.textPrimary(for: colorScheme))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(10)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill((colorScheme == .dark ? Color.white : Color.black).opacity(0.03))
                    )

                    // Sub-well 3: Active Splits
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 4) {
                            Image(systemName: "person.2")
                                .font(.system(size: 10, weight: .bold))
                            Text("Active")
                                .font(LeafTypography.captionRegular)
                        }
                        .foregroundStyle(LeafTheme.infoBlue)

                        Text("\(summary.activeSplitsCount) splits")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundStyle(LeafTheme.textPrimary(for: colorScheme))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(10)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill((colorScheme == .dark ? Color.white : Color.black).opacity(0.03))
                    )
                }
            }
            .padding(18)
        }
        .padding(.horizontal)
    }
}

