import SwiftUI

/// Section view presenting the 5 most recent transactions with relative timestamps and clear financial polarity.
/// Displays an inviting empty state when the ledger contains no transactions.
public struct RecentTransactionsSectionView: View {
    @Environment(\.colorScheme) private var colorScheme

    public let transactions: [Transaction]
    public let currency: Currency
    public let isBalanceVisible: Bool
    public let onSeeAll: () -> Void
    public let onAddTransaction: () -> Void
    public let onDeleteTransaction: (Int64) -> Void

    public init(
        transactions: [Transaction],
        currency: Currency = .default,
        isBalanceVisible: Bool = true,
        onSeeAll: @escaping () -> Void,
        onAddTransaction: @escaping () -> Void,
        onDeleteTransaction: @escaping (Int64) -> Void
    ) {
        self.transactions = transactions
        self.currency = currency
        self.isBalanceVisible = isBalanceVisible
        self.onSeeAll = onSeeAll
        self.onAddTransaction = onAddTransaction
        self.onDeleteTransaction = onDeleteTransaction
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Section Header
            HStack {
                Text("RECENT ACTIVITY")
                    .font(LeafTypography.captionBold)
                    .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))

                Spacer()

                if !transactions.isEmpty {
                    Button(action: onSeeAll) {
                        HStack(spacing: 4) {
                            Text("See All")
                                .font(LeafTypography.captionBold)
                                .foregroundStyle(LeafTheme.accent(for: colorScheme))

                            Image(systemName: "chevron.right")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(LeafTheme.accent(for: colorScheme))
                        }
                    }
                }
            }
            .padding(.horizontal)

            if transactions.isEmpty {
                EmptyStateCard(
                    icon: "tray.fill",
                    title: "No Transactions Yet",
                    description: "Start logging your daily expenses and income to see your live financial activity here.",
                    actionTitle: "Log First Expense",
                    action: onAddTransaction
                )
                .padding(.horizontal)
            } else {
                SquircleCard(cornerRadius: 20) {
                    VStack(spacing: 0) {
                        ForEach(Array(transactions.enumerated()), id: \.element.id) { index, tx in
                            transactionRow(tx)

                            if index < transactions.count - 1 {
                                Divider()
                                    .padding(.leading, 64)
                                    .padding(.trailing, 16)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
                .padding(.horizontal)
            }
        }
    }

    @ViewBuilder
    private func transactionRow(_ tx: Transaction) -> some View {
        let isIncome = tx.type == .income
        let categoryName = tx.category?.name ?? "General"
        let iconName = tx.category?.iconName ?? "more_horiz"
        let colorHex = tx.category?.colorHex ?? "#10B981"
        let title = (tx.note?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false)
            ? tx.note!
            : categoryName

        HStack(spacing: 12) {
            CategoryIconBadge(
                iconName: iconName,
                colorHex: colorHex,
                size: 42
            )

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(title)
                        .font(LeafTypography.bodyBold)
                        .foregroundStyle(LeafTheme.textPrimary(for: colorScheme))
                        .lineLimit(1)

                    if tx.isInternalTransfer {
                        Text("Transfer")
                            .font(.system(size: 9, weight: .bold, design: .rounded))
                            .foregroundStyle(LeafTheme.brandEmerald)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(LeafTheme.brandEmerald.opacity(0.12))
                            .clipShape(Capsule())
                    }

                    if tx.recurringTransactionId != nil {
                        HStack(spacing: 2) {
                            Image(systemName: "arrow.triangle.2.circlepath")
                                .font(.system(size: 8, weight: .bold))
                            Text("Recurring")
                                .font(.system(size: 9, weight: .bold, design: .rounded))
                        }
                        .foregroundStyle(LeafTheme.purpleAccent)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(LeafTheme.purpleAccent.opacity(0.12))
                        .clipShape(Capsule())
                    }

                    if !tx.isPrimaryCurrency(primaryCode: currency.code) {
                        Text(tx.currencyCode)
                            .font(.system(size: 9, weight: .bold, design: .rounded))
                            .foregroundStyle(LeafTheme.brandEmerald)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(LeafTheme.brandEmerald.opacity(0.12))
                            .clipShape(Capsule())
                    }
                }

                HStack(spacing: 6) {
                    Text(categoryName)
                        .font(LeafTypography.caption)
                        .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))

                    Text("•")
                        .font(LeafTypography.caption)
                        .foregroundStyle(LeafTheme.textSecondary(for: colorScheme).opacity(0.5))

                    Text(formatRelativeDate(tx.timestamp))
                        .font(LeafTypography.caption)
                        .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                let prefix = isIncome ? "+" : "-"
                let amountColor: Color = {
                    if tx.isInternalTransfer {
                        return isIncome ? LeafTheme.brandEmerald : LeafTheme.textPrimary(for: colorScheme)
                    }
                    return isIncome ? LeafTheme.brandEmerald : LeafTheme.expenseCoral
                }()

                if isBalanceVisible {
                    Text("\(prefix)\(tx.amount.format(currency: currency, includeSymbol: true))")
                        .font(.system(size: 15, weight: .bold, design: .rounded).monospacedDigit())
                        .foregroundStyle(amountColor)
                } else {
                    Text("\(prefix)\(currency.symbol)••••••")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(amountColor)
                }

                if isBalanceVisible && !tx.isPrimaryCurrency(primaryCode: currency.code) {
                    Text(tx.originalAmount.formatted(currency: tx.originalCurrency))
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
                }

                Text(tx.isInternalTransfer ? (isIncome ? "Transfer In" : "Transfer Out") : tx.paymentMethod.displayName)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
        .contextMenu {
            Button(role: .destructive, action: { onDeleteTransaction(tx.id) }) {
                Label("Delete Transaction", systemImage: "trash")
            }
        }
    }

    private func formatRelativeDate(_ epochMillis: Int64) -> String {
        let date = Date(timeIntervalSince1970: Double(epochMillis) / 1000.0)
        let calendar = Calendar.current

        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d"
            return formatter.string(from: date)
        }
    }
}

