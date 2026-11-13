import SwiftUI

/// Section displaying transactions grouped by date ("Today", "Yesterday", "Date").
/// Supports swipe-to-delete, tap-to-edit, context menu actions, and empty states.
public struct ExpensesTransactionHistoryView: View {
    @Environment(\.colorScheme) private var colorScheme

    public let groupedTransactions: [DateGroupedTransactions]
    public let currency: Currency
    public let isFilterActive: Bool
    public let onEditTransaction: (Transaction) -> Void
    public let onRequestDelete: (Transaction) -> Void
    public let onAddExpense: () -> Void
    public let onClearFilters: () -> Void

    public init(
        groupedTransactions: [DateGroupedTransactions],
        currency: Currency = .default,
        isFilterActive: Bool = false,
        onEditTransaction: @escaping (Transaction) -> Void,
        onRequestDelete: @escaping (Transaction) -> Void,
        onAddExpense: @escaping () -> Void,
        onClearFilters: @escaping () -> Void
    ) {
        self.groupedTransactions = groupedTransactions
        self.currency = currency
        self.isFilterActive = isFilterActive
        self.onEditTransaction = onEditTransaction
        self.onRequestDelete = onRequestDelete
        self.onAddExpense = onAddExpense
        self.onClearFilters = onClearFilters
    }

    private func formatTime(_ timestamp: Int64) -> String {
        let date = Date(timeIntervalSince1970: Double(timestamp) / 1000.0)
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Section Header
            HStack {
                Text("TRANSACTION HISTORY")
                    .font(LeafTypography.captionBold)
                    .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
                    .tracking(0.5)

                Spacer()

                let totalTxnCount = groupedTransactions.reduce(0) { $0 + $1.transactions.count }
                if totalTxnCount > 0 {
                    Text("\(totalTxnCount) \(totalTxnCount == 1 ? "entry" : "entries")")
                        .font(LeafTypography.captionRegular)
                        .foregroundStyle(LeafTheme.textTertiary(for: colorScheme))
                }
            }
            .padding(.horizontal)

            if groupedTransactions.isEmpty {
                if isFilterActive {
                    EmptyStateCard(
                        icon: "line.3.horizontal.decrease.circle",
                        title: "No Matching Expenses",
                        message: "No expenses match your current search and filter settings.",
                        actionTitle: "Clear Filters",
                        action: onClearFilters
                    )
                    .padding(.horizontal)
                } else {
                    EmptyStateCard(
                        icon: "tray",
                        title: "No Expenses Logged",
                        message: "Start tracking your spending by adding an expense for this month.",
                        actionTitle: "Add Expense",
                        action: onAddExpense
                    )
                    .padding(.horizontal)
                }
            } else {
                LazyVStack(spacing: 16) {
                    ForEach(groupedTransactions) { group in
                        VStack(alignment: .leading, spacing: 8) {
                            // Date Group Header
                            HStack {
                                Text(group.dateHeader)
                                    .font(.system(size: 13, weight: .bold, design: .rounded))
                                    .foregroundStyle(LeafTheme.textPrimary(for: colorScheme))

                                Spacer()

                                Text("- " + group.dayTotal.formatted(currency: currency))
                                    .font(.system(size: 13, weight: .semibold, design: .rounded).monospacedDigit())
                                    .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
                            }
                            .padding(.horizontal)

                            // Transactions Card Group
                            SquircleCard(cornerRadius: 18) {
                                VStack(spacing: 0) {
                                    ForEach(Array(group.transactions.enumerated()), id: \.element.id) { index, tx in
                                        if index > 0 {
                                            Divider()
                                                .padding(.leading, 64)
                                                .background(LeafTheme.cardBorder(for: colorScheme))
                                        }

                                        transactionRow(tx)
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func transactionRow(_ tx: Transaction) -> some View {
        Button(action: { onEditTransaction(tx) }) {
            HStack(spacing: 12) {
                // Category Icon
                CategoryIconBadge(
                    iconName: tx.category?.iconName ?? "tag.fill",
                    colorHex: tx.category?.colorHex ?? "#10B981",
                    size: 40
                )

                // Title, Note, and Payment Badge
                VStack(alignment: .leading, spacing: 3) {
                    Text(tx.category?.name ?? "Expense")
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundStyle(LeafTheme.textPrimary(for: colorScheme))
                        .lineLimit(1)

                    if let note = tx.note, !note.isEmpty {
                        Text(note)
                            .font(LeafTypography.captionRegular)
                            .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
                            .lineLimit(1)
                    }

                    // Payment Method & Transfer Badge
                    HStack(spacing: 4) {
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

                        Image(systemName: tx.paymentMethod == .cash ? "banknote" : "creditcard")
                            .font(.system(size: 9))
                        Text(tx.paymentMethod.rawValue.capitalized)
                            .font(.system(size: 10, weight: .medium, design: .rounded))
                    }
                    .foregroundStyle(LeafTheme.textTertiary(for: colorScheme))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        Capsule()
                            .fill((colorScheme == .dark ? Color.white : Color.black).opacity(0.04))
                    )
                }

                Spacer()

                // Amount & Time
                VStack(alignment: .trailing, spacing: 3) {
                    let isIncome = tx.type == .income
                    let prefix = isIncome ? "+ " : "- "
                    let amountColor: Color = {
                        if tx.isInternalTransfer {
                            return isIncome ? LeafTheme.brandEmerald : LeafTheme.textPrimary(for: colorScheme)
                        }
                        return isIncome ? LeafTheme.brandEmerald : LeafTheme.expenseCoral
                    }()

                    Text(prefix + tx.amount.formatted(currency: currency))
                        .font(.system(size: 15, weight: .bold, design: .rounded).monospacedDigit())
                        .foregroundStyle(amountColor)

                    if !tx.isPrimaryCurrency(primaryCode: currency.code) {
                        Text(tx.originalAmount.formatted(currency: tx.originalCurrency))
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
                    }

                    Text(formatTime(tx.timestamp))
                        .font(.system(size: 11, weight: .regular, design: .rounded))
                        .foregroundStyle(LeafTheme.textTertiary(for: colorScheme))
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .contextMenu {
            Button(action: { onEditTransaction(tx) }) {
                Label(tx.isInternalTransfer ? "Edit Transaction" : "Edit Expense", systemImage: "pencil")
            }

            Button(role: .destructive, action: { onRequestDelete(tx) }) {
                Label(tx.isInternalTransfer ? "Delete Transaction" : "Delete Expense", systemImage: "trash")
            }
        }
    }
}

