import SwiftUI
import UIKit

/// Horizontal row of 4 quick action capsule buttons directly beneath the Hero Balance card.
/// Provides instant access to logging transactions and navigating to key ledger workflows.
public struct QuickActionsRowView: View {
    @Environment(\.colorScheme) private var colorScheme

    public let onAddExpense: () -> Void
    public let onAddIncome: () -> Void
    public let onSplitBill: () -> Void
    public let onPlanning: () -> Void

    public init(
        onAddExpense: @escaping () -> Void,
        onAddIncome: @escaping () -> Void,
        onSplitBill: @escaping () -> Void,
        onPlanning: @escaping () -> Void
    ) {
        self.onAddExpense = onAddExpense
        self.onAddIncome = onAddIncome
        self.onSplitBill = onSplitBill
        self.onPlanning = onPlanning
    }

    private func triggerHaptic() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.prepare()
        generator.impactOccurred()
    }

    public var body: some View {
        HStack(spacing: 8) {
            quickActionButton(
                title: "Expense",
                icon: "plus.circle.fill",
                accentColor: LeafTheme.expenseCoral,
                action: onAddExpense
            )

            quickActionButton(
                title: "Income",
                icon: "plus.circle.fill",
                accentColor: LeafTheme.brandEmerald,
                action: onAddIncome
            )

            quickActionButton(
                title: "Split",
                icon: "person.2.fill",
                accentColor: LeafTheme.infoBlue,
                action: onSplitBill
            )

            quickActionButton(
                title: "Planning",
                icon: "target",
                accentColor: LeafTheme.purpleAccent,
                action: onPlanning
            )
        }
        .padding(.horizontal)
    }

    @ViewBuilder
    private func quickActionButton(
        title: String,
        icon: String,
        accentColor: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: {
            triggerHaptic()
            action()
        }) {
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(accentColor)

                Text(title)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(LeafTheme.textPrimary(for: colorScheme))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(colorScheme == .dark ? LeafTheme.cardDark : LeafTheme.cardLight)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(LeafTheme.cardBorder(for: colorScheme), lineWidth: 0.75)
            )
        }
        .buttonStyle(SquishButtonStyle())
    }
}

/// Custom button style giving gentle scale animation down to 96% upon press.
private struct SquishButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

