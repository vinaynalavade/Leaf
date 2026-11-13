import SwiftUI

/// Compact Dashboard section showing imminent upcoming and overdue bill payments.
public struct DashboardUpcomingBillsSectionView: View {
    @Environment(\.colorScheme) private var colorScheme

    public let summary: UpcomingBillsSummary
    public let currency: Currency
    public let isBalanceVisible: Bool
    public let onPayBill: (Int64) -> Void
    public let onSeeAll: () -> Void

    public init(
        summary: UpcomingBillsSummary,
        currency: Currency,
        isBalanceVisible: Bool = true,
        onPayBill: @escaping (Int64) -> Void,
        onSeeAll: @escaping () -> Void
    ) {
        self.summary = summary
        self.currency = currency
        self.isBalanceVisible = isBalanceVisible
        self.onPayBill = onPayBill
        self.onSeeAll = onSeeAll
    }

    private var displayBills: [RecurringTransactionOccurrence] {
        Array(summary.bills.filter { $0.status.isUnsettled }.prefix(2))
    }

    public var body: some View {
        if !displayBills.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("UPCOMING BILLS")
                        .font(LeafTypography.captionBold)
                        .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))

                    if summary.overdueCount > 0 {
                        Text("\(summary.overdueCount) OVERDUE")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(LeafTheme.expenseCoral)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(LeafTheme.expenseCoral.opacity(0.12))
                            .cornerRadius(4)
                    }

                    Spacer()

                    Button(action: onSeeAll) {
                        HStack(spacing: 4) {
                            Text("View All")
                                .font(LeafTypography.captionBold)
                                .foregroundStyle(LeafTheme.brandEmerald)
                            Image(systemName: "chevron.right")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(LeafTheme.brandEmerald)
                        }
                    }
                }
                .padding(.horizontal)

                VStack(spacing: 8) {
                    ForEach(displayBills) { bill in
                        NavigationLink {
                            RecurringHubView()
                        } label: {
                            SquircleCard(cornerRadius: 14) {
                                HStack(spacing: 12) {
                                    CategoryIconBadge(
                                        iconName: bill.category?.iconName ?? "doc.text.fill",
                                        colorHex: bill.category?.colorHex ?? "#10B981",
                                        size: 38
                                    )

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(bill.title)
                                            .font(LeafTypography.bodyBold)
                                            .foregroundStyle(LeafTheme.textPrimary(for: colorScheme))
                                            .lineLimit(1)

                                        HStack(spacing: 4) {
                                            Text(bill.status.displayName)
                                                .font(LeafTypography.captionBold)
                                                .foregroundStyle(bill.status == .overdue ? LeafTheme.expenseCoral : (bill.status == .due ? LeafTheme.warningGold : LeafTheme.infoBlue))

                                            Text("•")
                                                .font(LeafTypography.caption)
                                                .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))

                                            let date = Date(timeIntervalSince1970: Double(bill.dueDate) / 1000.0)
                                            Text(date, style: .date)
                                                .font(LeafTypography.caption)
                                                .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
                                        }
                                    }

                                    Spacer()

                                    VStack(alignment: .trailing, spacing: 4) {
                                        Text(isBalanceVisible ? bill.amount.formatted(currency: currency) : "\(currency.symbol)••••••")
                                            .font(LeafTypography.bodyBold)
                                            .foregroundStyle(LeafTheme.textPrimary(for: colorScheme))

                                        Button {
                                            onPayBill(bill.id)
                                        } label: {
                                            Text("Pay")
                                                .font(.system(size: 11, weight: .bold))
                                                .padding(.horizontal, 10)
                                                .padding(.vertical, 4)
                                                .background(LeafTheme.brandEmerald)
                                                .foregroundStyle(Color.white)
                                                .cornerRadius(6)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                                .padding(12)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

