import SwiftUI

/// Reusable card displaying an active, paused, or cancelled recurring schedule.
public struct RecurringScheduleCardView: View {
    @Environment(\.colorScheme) private var colorScheme

    public let schedule: RecurringTransaction
    public let currency: Currency
    public let onTogglePause: () -> Void
    public let onTap: () -> Void

    public init(
        schedule: RecurringTransaction,
        currency: Currency,
        onTogglePause: @escaping () -> Void,
        onTap: @escaping () -> Void
    ) {
        self.schedule = schedule
        self.currency = currency
        self.onTogglePause = onTogglePause
        self.onTap = onTap
    }

    private var nextDateString: String {
        guard let epoch = schedule.nextOccurrenceDate else { return "None scheduled" }
        let date = Date(timeIntervalSince1970: Double(epoch) / 1000.0)
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }

    private var statusColor: Color {
        switch schedule.status {
        case .active: return LeafTheme.brandEmerald
        case .paused: return LeafTheme.warningGold
        case .cancelled: return LeafTheme.textSecondary(for: colorScheme)
        }
    }

    public var body: some View {
        Button(action: onTap) {
            SquircleCard(cornerRadius: 16) {
                HStack(spacing: 12) {
                    CategoryIconBadge(
                        iconName: schedule.category?.iconName ?? "arrow.triangle.2.circlepath",
                        colorHex: schedule.category?.colorHex ?? "#10B981",
                        size: 42
                    )

                    VStack(alignment: .leading, spacing: 3) {
                        HStack(spacing: 6) {
                            Text(schedule.title)
                                .font(LeafTypography.bodyBold)
                                .foregroundStyle(LeafTheme.textPrimary(for: colorScheme))
                                .lineLimit(1)

                            if schedule.isSubscription {
                                Text("SUB")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundStyle(LeafTheme.purpleAccent)
                                    .padding(.horizontal, 4)
                                    .padding(.vertical, 1)
                                    .background(LeafTheme.purpleAccent.opacity(0.12))
                                    .cornerRadius(4)
                            }
                        }

                        HStack(spacing: 6) {
                            Text(schedule.frequency.displayName)
                                .font(LeafTypography.caption)
                                .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))

                            Text("•")
                                .font(LeafTypography.caption)
                                .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))

                            Text("Next: \(nextDateString)")
                                .font(LeafTypography.caption)
                                .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
                        }
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 4) {
                        Text(schedule.amount.formatted(currency: currency))
                            .font(LeafTypography.bodyBold)
                            .foregroundStyle(schedule.type == .expense ? LeafTheme.textPrimary(for: colorScheme) : LeafTheme.brandEmerald)

                        HStack(spacing: 4) {
                            Text(schedule.status.displayName)
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(statusColor)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(statusColor.opacity(0.12))
                                .cornerRadius(6)

                            if schedule.status != .cancelled {
                                Button(action: onTogglePause) {
                                    Image(systemName: schedule.status == .active ? "pause.circle" : "play.circle.fill")
                                        .font(.system(size: 16))
                                        .foregroundStyle(schedule.status == .active ? LeafTheme.textSecondary(for: colorScheme) : LeafTheme.brandEmerald)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                .padding(14)
            }
        }
        .buttonStyle(.plain)
    }
}

