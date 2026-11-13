import SwiftUI

/// Luxury Hero Balance Card presenting current liquid balance and integrated monthly cashflow wells.
/// Styled with 28 pt continuous squircle curvature and the master specification's Emerald & Obsidian gradients.
public struct BalanceHeroCardView: View {
    @Environment(\.colorScheme) private var colorScheme

    public let currentBalance: Amount
    public let monthlyIncome: Amount
    public let monthlyExpense: Amount
    public let currency: Currency
    public let isBalanceVisible: Bool
    public let cashBalance: Amount?
    public let accountBalance: Amount?
    public let onToggleVisibility: () -> Void
    public let onLedgerTap: (() -> Void)?

    public init(
        currentBalance: Amount,
        monthlyIncome: Amount,
        monthlyExpense: Amount,
        currency: Currency = .default,
        isBalanceVisible: Bool = true,
        cashBalance: Amount? = nil,
        accountBalance: Amount? = nil,
        onToggleVisibility: @escaping () -> Void,
        onLedgerTap: (() -> Void)? = nil
    ) {
        self.currentBalance = currentBalance
        self.monthlyIncome = monthlyIncome
        self.monthlyExpense = monthlyExpense
        self.currency = currency
        self.isBalanceVisible = isBalanceVisible
        self.cashBalance = cashBalance
        self.accountBalance = accountBalance
        self.onToggleVisibility = onToggleVisibility
        self.onLedgerTap = onLedgerTap
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            // Top Row: Label & Live Ledger Capsule
            HStack(alignment: .center) {
                Text("TOTAL BALANCE")
                    .font(.system(size: 11, weight: .bold))
                    .kerning(1.2)
                    .foregroundStyle(Color.white.opacity(0.85))

                Spacer()

                // Live Ledger indicator
                HStack(spacing: 5) {
                    Circle()
                        .fill(LeafTheme.brandEmerald)
                        .frame(width: 6, height: 6)

                    Text("Live Ledger")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(Color.white.opacity(0.95))
                }
                .padding(.horizontal, 9)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(Color.white.opacity(0.14))
                )
            }

            // Main Hero Balance Figure with Eye Icon beside it
            HStack(alignment: .center, spacing: 12) {
                if isBalanceVisible {
                    Text(currentBalance.format(currency: currency, includeSymbol: true))
                        .font(LeafTypography.amountHero)
                        .foregroundStyle(Color.white)
                        .minimumScaleFactor(0.7)
                        .lineLimit(1)
                } else {
                    Text("\(currency.symbol)••••••")
                        .font(LeafTypography.amountHero)
                        .foregroundStyle(Color.white)
                        .minimumScaleFactor(0.7)
                        .lineLimit(1)
                }

                Button(action: onToggleVisibility) {
                    Image(systemName: isBalanceVisible ? "eye.fill" : "eye.slash.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(Color.white.opacity(0.92))
                        .padding(8)
                        .background(
                            Circle()
                                .fill(Color.white.opacity(0.16))
                        )
                        .contentShape(Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(isBalanceVisible ? "Hide balance" : "Show balance")
            }

            // Cash & Account Ledger Breakdown Pills
            if let cash = cashBalance, let acct = accountBalance {
                Button(action: { onLedgerTap?() }) {
                    HStack(spacing: 8) {
                        HStack(spacing: 4) {
                            Image(systemName: "banknote.fill")
                                .font(.system(size: 9))
                                .foregroundStyle(Color.white.opacity(0.85))
                            Text("Cash: \(isBalanceVisible ? cash.format(currency: currency, includeSymbol: true) : "\(currency.symbol)••••")")
                                .font(.system(size: 11, weight: .semibold, design: .rounded))
                                .foregroundStyle(Color.white.opacity(0.95))
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Capsule().fill(Color.white.opacity(0.12)))

                        HStack(spacing: 4) {
                            Image(systemName: "creditcard.fill")
                                .font(.system(size: 9))
                                .foregroundStyle(Color.white.opacity(0.85))
                            Text("Account: \(isBalanceVisible ? acct.format(currency: currency, includeSymbol: true) : "\(currency.symbol)••••")")
                                .font(.system(size: 11, weight: .semibold, design: .rounded))
                                .foregroundStyle(Color.white.opacity(0.95))
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Capsule().fill(Color.white.opacity(0.12)))

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(Color.white.opacity(0.7))
                    }
                }
                .buttonStyle(.plain)
                .accessibilityLabel("View Cash and Account Ledgers")
            }

            // Cash-Flow Sub-Wells: Income & Expenses Capsules
            HStack(spacing: 12) {
                // Income Well
                cashflowWell(
                    title: "Income",
                    amount: monthlyIncome,
                    isIncome: true
                )

                // Expense Well
                cashflowWell(
                    title: "Expenses",
                    amount: monthlyExpense,
                    isIncome: false
                )
            }
        }
        .padding(22)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(LeafTheme.heroGradient(for: colorScheme))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(
                    colorScheme == .dark
                        ? Color.white.opacity(0.12)
                        : Color.white.opacity(0.22),
                    lineWidth: 1
                )
        )
        .shadow(
            color: colorScheme == .dark
                ? Color.black.opacity(0.4)
                : Color(hex: "#025442").opacity(0.25),
            radius: colorScheme == .dark ? 12 : 16,
            x: 0,
            y: 8
        )
        .padding(.horizontal)
    }

    @ViewBuilder
    private func cashflowWell(title: String, amount: Amount, isIncome: Bool) -> some View {
        let symbolColor = isIncome ? LeafTheme.brandEmerald : LeafTheme.expenseCoral
        let arrowIcon = isIncome ? "arrow.down.left" : "arrow.up.right"

        HStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(symbolColor.opacity(0.24))
                    .frame(width: 32, height: 32)

                Image(systemName: arrowIcon)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(symbolColor)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Color.white.opacity(0.78))

                if isBalanceVisible {
                    Text(amount.format(currency: currency, includeSymbol: true))
                        .font(.system(size: 14, weight: .bold, design: .rounded).monospacedDigit())
                        .foregroundStyle(Color.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                } else {
                    Text("\(currency.symbol)•••••")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.white)
                }
            }

            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.white.opacity(0.12))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.white.opacity(0.15), lineWidth: 0.5)
        )
        .frame(maxWidth: .infinity)
    }
}

