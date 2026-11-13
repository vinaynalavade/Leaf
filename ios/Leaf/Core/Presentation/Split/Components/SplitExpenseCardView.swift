import SwiftUI

/// Card representing a single split expense entry in the Split & Collect list.
public struct SplitExpenseCardView: View {
    @Environment(\.colorScheme) private var colorScheme

    public let split: SplitExpense
    public let currency: Currency
    public let onTap: () -> Void
    public let onEdit: () -> Void
    public let onDelete: () -> Void
    public let onSettle: (() -> Void)?

    public init(
        split: SplitExpense,
        currency: Currency = .default,
        onTap: @escaping () -> Void,
        onEdit: @escaping () -> Void,
        onDelete: @escaping () -> Void,
        onSettle: (() -> Void)? = nil
    ) {
        self.split = split
        self.currency = currency
        self.onTap = onTap
        self.onEdit = onEdit
        self.onDelete = onDelete
        self.onSettle = onSettle
    }

    private var settledCount: Int {
        split.participants.filter { $0.settlementStatus == .settled }.count
    }

    private var totalParticipants: Int {
        split.participants.count
    }

    private var isAllSettled: Bool {
        totalParticipants > 0 && settledCount == totalParticipants
    }

    private var formattedDate: String {
        let date = Date(timeIntervalSince1970: Double(split.date) / 1000.0)
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM yyyy"
        return formatter.string(from: date)
    }

    private var isCurrentUserPayer: Bool {
        let trimmed = split.paidBy.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.caseInsensitiveCompare("Me") == .orderedSame || trimmed.caseInsensitiveCompare("You") == .orderedSame {
            return true
        }
        return split.participants.first { $0.name.caseInsensitiveCompare(trimmed) == .orderedSame }?.isCurrentUser == true
    }

    private var myParticipant: SplitParticipant? {
        split.participants.first { $0.isCurrentUser }
    }

    public var body: some View {
        Button(action: onTap) {
            SquircleCard(cornerRadius: 18) {
                VStack(spacing: 12) {
                    // Top: Title, Date, and Total Amount
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(split.title)
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundStyle(LeafTheme.textPrimary(for: colorScheme))
                                .lineLimit(1)

                            HStack(spacing: 6) {
                                Text(formattedDate)
                                    .font(LeafTypography.captionRegular)
                                    .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))

                                Text("•")
                                    .foregroundStyle(LeafTheme.textTertiary(for: colorScheme))

                                Text("\(totalParticipants) people")
                                    .font(LeafTypography.captionRegular)
                                    .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
                            }
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: 2) {
                            let billCurrency = Currency.fromCode(split.currencyCode)
                            Text(split.totalAmount.formatted(currency: billCurrency))
                                .font(.system(size: 17, weight: .bold, design: .rounded).monospacedDigit())
                                .foregroundStyle(LeafTheme.textPrimary(for: colorScheme))

                            if split.currencyCode.uppercased() != currency.code.uppercased() {
                                Text("≈ \(split.primaryTotalAmount.formatted(currency: currency))")
                                    .font(LeafTypography.caption)
                                    .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
                            } else {
                                Text("Total Bill")
                                    .font(LeafTypography.captionRegular)
                                    .foregroundStyle(LeafTheme.textTertiary(for: colorScheme))
                            }
                        }
                    }

                    // Middle: Financial Position / Debtor-Creditor stance
                    HStack(spacing: 8) {
                        if isCurrentUserPayer {
                            let uncollectedSubunits = split.participants
                                .filter { !$0.isCurrentUser && $0.settlementStatus != .settled }
                                .reduce(Int64(0)) { $0 + $1.remainingAmount.subunits }

                            if uncollectedSubunits > 0 {
                                HStack(spacing: 4) {
                                    Image(systemName: "arrow.down.left.circle.fill")
                                        .font(.system(size: 11))
                                    Text("Owed to you: +\(Amount(subunits: uncollectedSubunits).formatted(currency: currency))")
                                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                                }
                                .foregroundStyle(LeafTheme.brandEmerald)
                            } else {
                                HStack(spacing: 4) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 11))
                                    Text("Fully Collected")
                                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                                }
                                .foregroundStyle(LeafTheme.brandEmerald)
                            }
                        } else if let myPart = myParticipant {
                            if myPart.settlementStatus == .settled {
                                HStack(spacing: 4) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 11))
                                    Text("Your share settled")
                                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                                }
                                .foregroundStyle(LeafTheme.brandEmerald)
                            } else {
                                HStack(spacing: 4) {
                                    Image(systemName: "arrow.up.right.circle.fill")
                                        .font(.system(size: 11))
                                    Text("You owe: \(myPart.remainingAmount.formatted(currency: currency))")
                                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                                }
                                .foregroundStyle(LeafTheme.expenseCoral)
                            }
                        } else {
                            Text("Paid by \(split.paidBy)")
                                .font(.system(size: 12, weight: .medium, design: .rounded))
                                .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
                        }

                        Spacer()

                        // If not all settled, show quick Settle Up CTA
                        if !isAllSettled {
                            Button(action: {
                                if let onSettle = onSettle {
                                    onSettle()
                                } else {
                                    onTap()
                                }
                            }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "creditcard.fill")
                                        .font(.system(size: 10))
                                    Text("Settle Up")
                                        .font(.system(size: 11, weight: .bold, design: .rounded))
                                }
                                .foregroundStyle(.white)
                                .padding(.horizontal, 9)
                                .padding(.vertical, 4)
                                .background(LeafTheme.brandEmerald)
                                .clipShape(Capsule())
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill((colorScheme == .dark ? Color.white : Color.black).opacity(0.03))
                    )

                    // Bottom: Payer badge and Settlement Progress Pill
                    HStack {
                        // Payer Badge
                        HStack(spacing: 4) {
                            Image(systemName: "creditcard")
                                .font(.system(size: 10))
                            Text("Paid by \(split.paidBy)")
                                .font(.system(size: 11, weight: .medium, design: .rounded))
                        }
                        .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(
                            Capsule()
                                .fill((colorScheme == .dark ? Color.white : Color.black).opacity(0.04))
                        )

                        Spacer()

                        // Settlement Status Pill
                        HStack(spacing: 4) {
                            Image(systemName: isAllSettled ? "checkmark.circle.fill" : "clock.fill")
                                .font(.system(size: 10))
                            Text(isAllSettled ? "All Settled" : "\(settledCount)/\(totalParticipants) Settled")
                                .font(.system(size: 11, weight: .semibold, design: .rounded))
                        }
                        .foregroundStyle(isAllSettled ? LeafTheme.brandEmerald : LeafTheme.amberAccent)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill((isAllSettled ? LeafTheme.brandEmerald : LeafTheme.amberAccent).opacity(0.12))
                        )
                    }
                }
                .padding(14)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityElement(children: .contain)
        .accessibilityLabel("\(split.title), total bill \(split.totalAmount.formatted(currency: currency)), paid by \(split.paidBy). \(isAllSettled ? "Fully settled" : "\(settledCount) of \(totalParticipants) settled").")
        .accessibilityHint("Double tap to view breakdown and record settlements.")
        .contextMenu {
            Button(action: onEdit) {
                Label("Edit Split", systemImage: "pencil")
            }

            if !isAllSettled {
                Button(action: {
                    if let onSettle = onSettle {
                        onSettle()
                    } else {
                        onTap()
                    }
                }) {
                    Label("Settle Up", systemImage: "creditcard")
                }
            }

            Button(role: .destructive, action: onDelete) {
                Label("Delete Split", systemImage: "trash")
            }
        }
    }
}
