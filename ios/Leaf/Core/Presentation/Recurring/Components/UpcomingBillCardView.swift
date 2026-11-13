import SwiftUI

/// Reusable card displaying an upcoming or overdue bill occurrence with rapid payment and snooze actions.
public struct UpcomingBillCardView: View {
    @Environment(\.colorScheme) private var colorScheme

    public let occurrence: RecurringTransactionOccurrence
    public let currency: Currency
    public let onMarkAsPaid: () -> Void
    public let onSkip: () -> Void
    public let onSnooze: () -> Void
    public let onTap: () -> Void

    public init(
        occurrence: RecurringTransactionOccurrence,
        currency: Currency,
        onMarkAsPaid: @escaping () -> Void,
        onSkip: @escaping () -> Void,
        onSnooze: @escaping () -> Void,
        onTap: @escaping () -> Void
    ) {
        self.occurrence = occurrence
        self.currency = currency
        self.onMarkAsPaid = onMarkAsPaid
        self.onSkip = onSkip
        self.onSnooze = onSnooze
        self.onTap = onTap
    }

    private var statusColor: Color {
        switch occurrence.status {
        case .overdue: return LeafTheme.expenseCoral
        case .due: return LeafTheme.warningGold
        case .upcoming: return LeafTheme.infoBlue
        case .paid: return LeafTheme.brandEmerald
        case .skipped: return LeafTheme.textSecondary(for: colorScheme)
        }
    }

    private var dueDateString: String {
        let date = Date(timeIntervalSince1970: Double(occurrence.dueDate) / 1000.0)
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }

    private var relativeDueString: String {
        let cal = Calendar.current
        let dueDate = Date(timeIntervalSince1970: Double(occurrence.dueDate) / 1000.0)
        let startOfToday = cal.startOfDay(for: Date())
        let startOfDue = cal.startOfDay(for: dueDate)

        let diff = cal.dateComponents([.day], from: startOfToday, to: startOfDue).day ?? 0
        if diff < 0 {
            return "\(abs(diff))d overdue"
        } else if diff == 0 {
            return "Due today"
        } else if diff == 1 {
            return "Due tomorrow"
        } else {
            return "Due in \(diff)d"
        }
    }

    public var body: some View {
        Button(action: onTap) {
            SquircleCard(cornerRadius: 16) {
                VStack(spacing: 12) {
                    HStack(spacing: 12) {
                        // Category Icon Badge
                        CategoryIconBadge(
                            iconName: occurrence.category?.iconName ?? "doc.text.fill",
                            colorHex: occurrence.category?.colorHex ?? "#10B981",
                            size: 40
                        )

                        VStack(alignment: .leading, spacing: 2) {
                            HStack(spacing: 6) {
                                Text(occurrence.title)
                                    .font(LeafTypography.bodyBold)
                                    .foregroundStyle(LeafTheme.textPrimary(for: colorScheme))
                                    .lineLimit(1)

                                if occurrence.isSubscription {
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
                                Text(dueDateString)
                                    .font(LeafTypography.caption)
                                    .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))

                                Text("•")
                                    .font(LeafTypography.caption)
                                    .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))

                                Text(relativeDueString)
                                    .font(LeafTypography.captionBold)
                                    .foregroundStyle(statusColor)

                                if let snoozed = occurrence.snoozedUntil {
                                    let sDate = Date(timeIntervalSince1970: Double(snoozed) / 1000.0)
                                    HStack(spacing: 2) {
                                        Text("• Snoozed:")
                                        Text(sDate, style: .date)
                                    }
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundStyle(LeafTheme.warningGold)
                                }
                            }
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: 3) {
                            Text(occurrence.amount.formatted(currency: currency))
                                .font(LeafTypography.bodyBold)
                                .foregroundStyle(occurrence.type == .expense ? LeafTheme.textPrimary(for: colorScheme) : LeafTheme.brandEmerald)

                            Text(occurrence.status.displayName)
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(statusColor)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(statusColor.opacity(0.12))
                                .cornerRadius(6)
                        }
                    }

                    // Action Row for Unsettled Bills
                    if occurrence.status.isUnsettled {
                        Divider()

                        HStack(spacing: 8) {
                            Button {
                                onSnooze()
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: "bell.badge")
                                        .font(.system(size: 11))
                                    Text("Snooze")
                                        .font(LeafTypography.captionBold)
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(LeafTheme.card(for: colorScheme))
                                .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(LeafTheme.border(for: colorScheme), lineWidth: 1)
                                )
                            }
                            .buttonStyle(.plain)

                            Button {
                                onSkip()
                            } label: {
                                Text("Skip")
                                    .font(LeafTypography.captionBold)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(LeafTheme.card(for: colorScheme))
                                    .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
                                    .cornerRadius(8)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(LeafTheme.border(for: colorScheme), lineWidth: 1)
                                    )
                            }
                            .buttonStyle(.plain)

                            Spacer()

                            Button {
                                onMarkAsPaid()
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 12))
                                    Text("Mark as Paid")
                                        .font(LeafTypography.captionBold)
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(LeafTheme.brandEmerald)
                                .foregroundStyle(Color.white)
                                .cornerRadius(8)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(14)
            }
        }
        .buttonStyle(.plain)
    }
}

