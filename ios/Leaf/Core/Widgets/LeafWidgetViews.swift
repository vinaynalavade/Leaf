import SwiftUI
import WidgetKit
import AppIntents

private let leafEmerald = Color(red: 3.0 / 255.0, green: 152.0 / 255.0, blue: 118.0 / 255.0)
private let leafRed = Color(red: 250.0 / 255.0, green: 77.0 / 255.0, blue: 86.0 / 255.0)

// MARK: - App Intents for Interactive Widgets

@available(iOS 17.0, *)
public struct AddExpenseAppIntent: AppIntent {
    public static var title: LocalizedStringResource = "Add Expense"
    public static var description: IntentDescription = IntentDescription("Open Leaf to record a new expense")
    public static var openAppWhenRun: Bool = true

    public init() {}

    public func perform() async throws -> some IntentResult {
        return .result()
    }
}

@available(iOS 17.0, *)
public struct OpenSplitAppIntent: AppIntent {
    public static var title: LocalizedStringResource = "Open Split & Collect"
    public static var description: IntentDescription = IntentDescription("Open Leaf Split & Collect to settle bills")
    public static var openAppWhenRun: Bool = true

    public init() {}

    public func perform() async throws -> some IntentResult {
        return .result()
    }
}

@available(iOS 17.0, *)
public struct ToggleWidgetBalancePrivacyIntent: AppIntent {
    public static var title: LocalizedStringResource = "Toggle Balance Privacy"
    public static var description: IntentDescription = IntentDescription("Toggle visibility of sensitive amounts on widgets")
    public static var openAppWhenRun: Bool = false

    public init() {}

    public func perform() async throws -> some IntentResult {
        WidgetDataManager.shared.toggleBalanceVisibility()
        return .result()
    }
}

// MARK: - Small Widget (Balance & Monthly Spend)

public struct LeafSmallWidgetView: View {
    public let snapshot: WidgetFinancialSnapshot

    public init(snapshot: WidgetFinancialSnapshot) {
        self.snapshot = snapshot
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header with Leaf icon & Privacy Toggle
            HStack {
                HStack(spacing: 4) {
                    Image(systemName: "leaf.fill")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(leafEmerald)
                    Text("Leaf")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                }

                Spacer()

                Button(intent: ToggleWidgetBalancePrivacyIntent()) {
                    Image(systemName: snapshot.isBalanceVisible ? "eye.fill" : "eye.slash.fill")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .padding(4)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(snapshot.isBalanceVisible ? "Hide balance" : "Show balance")
            }

            Spacer()

            // Balance
            VStack(alignment: .leading, spacing: 2) {
                Text("TOTAL BALANCE")
                    .font(.system(size: 9, weight: .bold, design: .rounded))
                    .foregroundStyle(.secondary)
                    .tracking(0.5)

                Text(snapshot.formattedBalance)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }

            // Monthly Spend
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 3) {
                    Image(systemName: "arrow.up.forward.circle.fill")
                        .font(.system(size: 8))
                        .foregroundStyle(leafRed)
                    Text("Spent: \(snapshot.formattedExpense)")
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
        }
        .padding(12)
        .widgetURL(URL(string: "leaf://dashboard"))
    }
}

// MARK: - Medium Widget (Balance, Budget Progress & Quick Actions)

public struct LeafMediumWidgetView: View {
    public let snapshot: WidgetFinancialSnapshot

    public init(snapshot: WidgetFinancialSnapshot) {
        self.snapshot = snapshot
    }

    public var body: some View {
        VStack(spacing: 12) {
            // Top Row: Brand & Balance
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 5) {
                        Image(systemName: "leaf.fill")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(leafEmerald)
                        Text("LEAF BALANCE")
                            .font(.system(size: 9, weight: .bold, design: .rounded))
                            .foregroundStyle(.secondary)
                            .tracking(0.5)

                        Button(intent: ToggleWidgetBalancePrivacyIntent()) {
                            Image(systemName: snapshot.isBalanceVisible ? "eye.fill" : "eye.slash.fill")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(.secondary)
                                .padding(2)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(snapshot.isBalanceVisible ? "Hide balance" : "Show balance")
                    }

                    Text(snapshot.formattedBalance)
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                }

                Spacer()

                // Cashflow Wells
                HStack(spacing: 12) {
                    VStack(alignment: .trailing, spacing: 1) {
                        Text("Income")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundStyle(.secondary)
                        Text("+\(snapshot.formattedIncome)")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundStyle(leafEmerald)
                    }

                    VStack(alignment: .trailing, spacing: 1) {
                        Text("Spent")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundStyle(.secondary)
                        Text("-\(snapshot.formattedExpense)")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundStyle(leafRed)
                    }
                }
            }

            // Budget Progress Bar
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Budget remaining: \(snapshot.formattedBudgetRemaining)")
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)

                    Spacer()

                    Text("\(Int(min(snapshot.budgetProgressRatio, 1.0) * 100))%")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundStyle(snapshot.budgetProgressRatio > 0.9 ? (leafRed) : (leafEmerald))
                }

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 6)

                        Capsule()
                            .fill(snapshot.budgetProgressRatio > 0.9 ? (leafRed) : (leafEmerald))
                            .frame(width: max(6, geo.size.width * CGFloat(min(snapshot.budgetProgressRatio, 1.0))), height: 6)
                    }
                }
                .frame(height: 6)
            }

            // Quick Actions Deep Links
            HStack(spacing: 8) {
                Link(destination: URL(string: "leaf://add-expense")!) {
                    HStack(spacing: 4) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 10))
                        Text("Add Expense")
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 28)
                    .background(leafEmerald)
                    .clipShape(Capsule())
                }

                Link(destination: URL(string: "leaf://split")!) {
                    HStack(spacing: 4) {
                        Image(systemName: "person.2.fill")
                            .font(.system(size: 10))
                        Text("Split & Collect")
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                    }
                    .foregroundStyle(.primary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 28)
                    .background(Color.gray.opacity(0.15))
                    .clipShape(Capsule())
                }
            }
        }
        .padding(14)
    }
}

// MARK: - Large Widget (Complete Financial Snapshot & Quick Hub)

public struct LeafLargeWidgetView: View {
    public let snapshot: WidgetFinancialSnapshot

    public init(snapshot: WidgetFinancialSnapshot) {
        self.snapshot = snapshot
    }

    public var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "leaf.fill")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(leafEmerald)
                    Text("Leaf Financial")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                }

                Spacer()

                Text("Updated \(formattedTime(snapshot.lastUpdated))")
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
            }

            // Hero Balance Card
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("TOTAL BALANCE")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundStyle(.secondary)
                        .tracking(0.5)

                    Spacer()

                    Button(intent: ToggleWidgetBalancePrivacyIntent()) {
                        Image(systemName: snapshot.isBalanceVisible ? "eye.fill" : "eye.slash.fill")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.secondary)
                            .padding(4)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(snapshot.isBalanceVisible ? "Hide balance" : "Show balance")
                }

                Text(snapshot.formattedBalance)
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)

                HStack(spacing: 16) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.down.forward.circle.fill")
                            .foregroundStyle(leafEmerald)
                        Text("Income: +\(snapshot.formattedIncome)")
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .foregroundStyle(.secondary)
                    }

                    HStack(spacing: 4) {
                        Image(systemName: "arrow.up.forward.circle.fill")
                            .foregroundStyle(leafRed)
                        Text("Spent: -\(snapshot.formattedExpense)")
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .background(Color.gray.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

            // Budget Progress
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Monthly Budget Progress")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                    Spacer()
                    Text("\(snapshot.formattedExpense) / \(snapshot.formattedBudgetRemaining)")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                }

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 8)

                        Capsule()
                            .fill(snapshot.budgetProgressRatio > 0.9 ? (leafRed) : (leafEmerald))
                            .frame(width: max(8, geo.size.width * CGFloat(min(snapshot.budgetProgressRatio, 1.0))), height: 8)
                    }
                }
                .frame(height: 8)
            }

            Spacer()

            // Quick Hub Buttons
            HStack(spacing: 10) {
                Link(destination: URL(string: "leaf://add-expense")!) {
                    VStack(spacing: 4) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 18))
                        Text("Add Expense")
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(leafEmerald)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }

                Link(destination: URL(string: "leaf://split")!) {
                    VStack(spacing: 4) {
                        Image(systemName: "person.2.fill")
                            .font(.system(size: 18))
                        Text("Split Bill")
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                    }
                    .foregroundStyle(.primary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(Color.gray.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }

                Link(destination: URL(string: "leaf://planning")!) {
                    VStack(spacing: 4) {
                        Image(systemName: "target")
                            .font(.system(size: 18))
                        Text("Planning")
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                    }
                    .foregroundStyle(.primary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(Color.gray.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
            }
        }
        .padding(16)
    }

    private func formattedTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
