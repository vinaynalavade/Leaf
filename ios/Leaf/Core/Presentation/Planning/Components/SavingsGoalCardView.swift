import SwiftUI

/// Component displaying a target-driven savings goal card with circular progress,
/// milestone status, target date countdown, and quick contribution/withdrawal actions.
public struct SavingsGoalCardView: View {
    @Environment(\.colorScheme) private var colorScheme

    public let goal: SavingsGoal
    public let currency: Currency
    public let onTap: () -> Void
    public let onAddContribution: () -> Void
    public let onWithdraw: (() -> Void)?

    public init(
        goal: SavingsGoal,
        currency: Currency = .default,
        onTap: @escaping () -> Void,
        onAddContribution: @escaping () -> Void,
        onWithdraw: (() -> Void)? = nil
    ) {
        self.goal = goal
        self.currency = currency
        self.onTap = onTap
        self.onAddContribution = onAddContribution
        self.onWithdraw = onWithdraw
    }

    private var goalColor: Color {
        Color(hex: goal.colorHex) ?? LeafTheme.brandEmerald
    }

    public var body: some View {
        Button(action: onTap) {
            SquircleCard(cornerRadius: 20) {
                VStack(spacing: 14) {
                    // Header Row: Goal Icon Badge + Title + Status Pill
                    HStack(spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(goalColor.opacity(0.16))
                                .frame(width: 40, height: 40)

                            Image(systemName: iconSystemName(for: goal.iconName))
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(goalColor)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text(goal.name)
                                .font(LeafTypography.titleSmall)
                                .foregroundStyle(LeafTheme.textPrimary(for: colorScheme))
                                .lineLimit(1)

                            if let note = goal.note, !note.isEmpty {
                                Text(note)
                                    .font(LeafTypography.captionRegular)
                                    .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
                                    .lineLimit(1)
                            } else {
                                Text(goal.isCompleted ? "Goal Reached!" : "\(Int(goal.progressPercentage))% completed")
                                    .font(LeafTypography.captionRegular)
                                    .foregroundStyle(goal.isCompleted ? LeafTheme.brandEmerald : LeafTheme.textSecondary(for: colorScheme))
                            }
                        }

                        Spacer()

                        // Status Badge
                        if goal.isCompleted {
                            HStack(spacing: 4) {
                                Image(systemName: "checkmark.seal.fill")
                                Text("Completed")
                            }
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundStyle(LeafTheme.brandEmerald)
                            .padding(.horizontal, 9)
                            .padding(.vertical, 4)
                            .background(
                                Capsule().fill(LeafTheme.brandEmerald.opacity(0.12))
                            )
                        } else if let days = goal.daysRemaining {
                            Text(days > 0 ? "\(days)d left" : "Overdue")
                                .font(.system(size: 11, weight: .semibold, design: .rounded))
                                .foregroundStyle(days > 0 ? LeafTheme.textSecondary(for: colorScheme) : LeafTheme.coralRose)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    Capsule().fill((colorScheme == .dark ? Color.white : Color.black).opacity(0.06))
                                )
                        }
                    }

                    // Amounts Row
                    HStack(alignment: .firstTextBaseline) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("SAVED")
                                .font(LeafTypography.captionBold)
                                .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
                                .tracking(0.5)

                            Text(goal.currentSavedAmount.formatted(currency: currency))
                                .font(.system(size: 20, weight: .bold, design: .rounded).monospacedDigit())
                                .foregroundStyle(goal.isCompleted ? LeafTheme.brandEmerald : LeafTheme.textPrimary(for: colorScheme))
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: 2) {
                            Text("TARGET")
                                .font(LeafTypography.captionBold)
                                .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
                                .tracking(0.5)

                            Text(goal.targetAmount.formatted(currency: currency))
                                .font(.system(size: 15, weight: .semibold, design: .rounded).monospacedDigit())
                                .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
                        }
                    }

                    // Progress Bar
                    GeometryReader { geo in
                        let ratio = max(0.0, min(1.0, goal.progressPercentage / 100.0))
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill((colorScheme == .dark ? Color.white : Color.black).opacity(0.08))
                                .frame(height: 7)

                            Capsule()
                                .fill(goalColor)
                                .frame(width: max(7, geo.size.width * CGFloat(ratio)), height: 7)
                        }
                    }
                    .frame(height: 7)

                    // Footer Row: Deficit / Required monthly savings + Quick Action Buttons
                    HStack {
                        if !goal.isCompleted {
                            if let monthly = goal.requiredMonthlySavings {
                                Text("\(monthly.formatted(currency: currency))/mo needed")
                                    .font(LeafTypography.captionRegular)
                                    .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
                            } else {
                                Text("\(goal.remainingAmount.formatted(currency: currency)) to go")
                                    .font(LeafTypography.captionRegular)
                                    .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
                            }
                        } else {
                            Text("Target achieved")
                                .font(LeafTypography.captionRegular)
                                .foregroundStyle(LeafTheme.brandEmerald)
                        }

                        Spacer()

                        HStack(spacing: 6) {
                            // Quick Withdraw Button (if funds available and handler provided)
                            if let withdrawAction = onWithdraw, goal.currentSavedAmount.subunits > 0 {
                                Button(action: {
                                    let generator = UIImpactFeedbackGenerator(style: .light)
                                    generator.impactOccurred()
                                    withdrawAction()
                                }) {
                                    HStack(spacing: 3) {
                                        Image(systemName: "arrow.up.right")
                                        Text("Withdraw")
                                    }
                                    .font(.system(size: 11, weight: .bold, design: .rounded))
                                    .foregroundStyle(LeafTheme.warningAmber)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 5)
                                    .background(LeafTheme.warningAmber.opacity(0.12))
                                    .clipShape(Capsule())
                                }
                            }

                            // Quick Deposit Button
                            Button(action: {
                                let generator = UIImpactFeedbackGenerator(style: .light)
                                generator.impactOccurred()
                                onAddContribution()
                            }) {
                                HStack(spacing: 3) {
                                    Image(systemName: "plus")
                                    Text("Deposit")
                                }
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(goalColor)
                                .clipShape(Capsule())
                            }
                        }
                    }
                }
                .padding(16)
            }
        }
        .buttonStyle(.plain)
    }

    private func iconSystemName(for name: String) -> String {
        switch name.lowercased() {
        case "savings", "piggy", "bank": return "banknote.fill"
        case "car", "vehicle": return "car.fill"
        case "home", "house": return "house.fill"
        case "flight", "travel", "vacation": return "airplane"
        case "gadget", "laptop", "tech": return "laptopcomputer"
        case "education", "study": return "graduationcap.fill"
        case "emergency", "shield": return "cross.case.fill"
        default: return "star.fill"
        }
    }
}
