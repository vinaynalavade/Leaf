import SwiftUI
import WidgetKit

/// Comprehensive Widget Window and Showcase View equivalent to Android's widget experience.
/// Presents interactive live previews for Small, Medium, and Large widgets,
/// real-time privacy toggle testing, and step-by-step Home Screen installation instructions.
public struct WidgetShowcaseView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss

    public enum WidgetSizeSelection: String, CaseIterable, Identifiable {
        case small = "Small"
        case medium = "Medium"
        case large = "Large"

        public var id: String { rawValue }
        public var dimensionsText: String {
            switch self {
            case .small: return "2×2 Grid (Glanceable)"
            case .medium: return "4×2 Grid (Actions & Flow)"
            case .large: return "4×4 Grid (Financial Cockpit)"
            }
        }
    }

    @State private var selectedSize: WidgetSizeSelection = .medium
    @State private var snapshot: WidgetFinancialSnapshot = WidgetDataManager.shared.loadSnapshot()
    @State private var isBalanceVisible: Bool = WidgetDataManager.shared.isBalanceVisible()
    @State private var showReloadSuccess: Bool = false

    public init() {}

    public var body: some View {
        NavigationStack {
            ZStack {
                LeafTheme.canvas(for: colorScheme).ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // 1. Size Segmented Picker
                        Picker("Widget Size", selection: $selectedSize) {
                            ForEach(WidgetSizeSelection.allCases) { size in
                                Text(size.rawValue).tag(size)
                            }
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal)
                        .padding(.top, 8)

                        // 2. Live Interactive Widget Preview Canvas
                        VStack(spacing: 12) {
                            HStack {
                                Label("Live Preview", systemImage: "sparkles")
                                    .font(LeafTypography.captionBold)
                                    .foregroundStyle(LeafTheme.brandEmerald)

                                Spacer()

                                Text(selectedSize.dimensionsText)
                                    .font(LeafTypography.captionRegular)
                                    .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
                            }
                            .padding(.horizontal, 4)

                            // Preview Card Container
                            ZStack {
                                RoundedRectangle(cornerRadius: 24, style: .continuous)
                                    .fill(colorScheme == .dark ? Color(hex: "#1E293B") : Color.white)
                                    .shadow(
                                        color: colorScheme == .dark ? Color.black.opacity(0.4) : Color.black.opacity(0.08),
                                        radius: 12,
                                        x: 0,
                                        y: 6
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                                            .stroke(LeafTheme.border(for: colorScheme), lineWidth: 1)
                                    )

                                widgetPreviewContent
                                    .padding(4)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: previewHeightForSize(selectedSize))
                        }
                        .padding(.horizontal)

                        // 3. Quick Controls Bar (Privacy & Refresh)
                        HStack(spacing: 12) {
                            Button(action: togglePrivacy) {
                                HStack(spacing: 6) {
                                    Image(systemName: isBalanceVisible ? "eye.fill" : "eye.slash.fill")
                                        .font(.system(size: 14, weight: .semibold))
                                    Text(isBalanceVisible ? "Hide Balances" : "Show Balances")
                                        .font(LeafTypography.captionBold)
                                }
                                .foregroundStyle(LeafTheme.textPrimary(for: colorScheme))
                                .frame(maxWidth: .infinity)
                                .frame(height: 44)
                                .background(LeafTheme.card(for: colorScheme))
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .stroke(LeafTheme.border(for: colorScheme), lineWidth: 0.75)
                                )
                            }
                            .buttonStyle(.plain)

                            Button(action: refreshWidgets) {
                                HStack(spacing: 6) {
                                    Image(systemName: showReloadSuccess ? "checkmark.circle.fill" : "arrow.clockwise")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundStyle(showReloadSuccess ? LeafTheme.brandEmerald : LeafTheme.textPrimary(for: colorScheme))
                                    Text(showReloadSuccess ? "Synced!" : "Sync Widgets")
                                        .font(LeafTypography.captionBold)
                                        .foregroundStyle(showReloadSuccess ? LeafTheme.brandEmerald : LeafTheme.textPrimary(for: colorScheme))
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 44)
                                .background(LeafTheme.card(for: colorScheme))
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .stroke(LeafTheme.border(for: colorScheme), lineWidth: 0.75)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal)

                        // 4. Feature Capabilities for Selected Size
                        SquircleCard(cornerRadius: 18) {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("WIDGET HIGHLIGHTS")
                                    .font(LeafTypography.captionBold)
                                    .foregroundStyle(LeafTheme.brandEmerald)
                                    .tracking(0.5)

                                ForEach(featurePointsForSize(selectedSize), id: \.self) { point in
                                    HStack(alignment: .top, spacing: 8) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.system(size: 14))
                                            .foregroundStyle(LeafTheme.brandEmerald)
                                        Text(point)
                                            .font(LeafTypography.body)
                                            .foregroundStyle(LeafTheme.textPrimary(for: colorScheme))
                                    }
                                }
                            }
                            .padding(16)
                        }
                        .padding(.horizontal)

                        // 5. How to Add to iPhone Home Screen Guide
                        SquircleCard(cornerRadius: 18) {
                            VStack(alignment: .leading, spacing: 14) {
                                HStack(spacing: 8) {
                                    Image(systemName: "plus.app.fill")
                                        .font(.system(size: 18))
                                        .foregroundStyle(LeafTheme.brandEmerald)
                                    Text("How to Add to Home Screen")
                                        .font(LeafTypography.headline)
                                        .foregroundStyle(LeafTheme.textPrimary(for: colorScheme))
                                }

                                instructionStep(number: 1, text: "Go to your iPhone Home Screen and touch and hold any empty area until apps jiggle.")
                                instructionStep(number: 2, text: "Tap the + (Add) button in the upper corner of your screen.")
                                instructionStep(number: 3, text: "Scroll down and select Leaf from the list of available apps.")
                                instructionStep(number: 4, text: "Swipe to pick your preferred widget size (Small, Medium, or Large) and tap Add Widget.")
                                instructionStep(number: 5, text: "Drag the widget to your desired position and tap Done in the top-right corner.")
                            }
                            .padding(16)
                        }
                        .padding(.horizontal)

                        Spacer(minLength: 24)
                    }
                    .padding(.vertical, 8)
                }
            }
            .navigationTitle("Home Screen Widgets")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundStyle(LeafTheme.accent(for: colorScheme))
                }
            }
            .onAppear {
                reloadLocalSnapshot()
            }
        }
    }

    // MARK: - Subviews & Helpers

    @ViewBuilder
    private var widgetPreviewContent: some View {
        switch selectedSize {
        case .small:
            LeafSmallWidgetView(snapshot: snapshot)
        case .medium:
            LeafMediumWidgetView(snapshot: snapshot)
        case .large:
            LeafLargeWidgetView(snapshot: snapshot)
        }
    }

    private func previewHeightForSize(_ size: WidgetSizeSelection) -> CGFloat {
        switch size {
        case .small: return 160
        case .medium: return 175
        case .large: return 360
        }
    }

    private func featurePointsForSize(_ size: WidgetSizeSelection) -> [String] {
        switch size {
        case .small:
            return [
                "Glanceable Total Net Liquid Balance at a single glance.",
                "Today's and monthly spending burn-rate counter.",
                "Interactive eye icon to instantly mask or reveal sensitive balances directly from your Home Screen."
            ]
        case .medium:
            return [
                "Complete cashflow overview: Net Balance, Monthly Income, and Monthly Spending.",
                "Live monthly budget progress bar with real-time percentage tracking.",
                "1-Tap Instant Actions: Deep link directly into Add Expense or Split & Collect.",
                "Interactive eye icon for Home Screen privacy masking."
            ]
        case .large:
            return [
                "Full executive cockpit: Large hero balance, income, expenses, and budget progress.",
                "Timestamp showing when the widget data was last synchronized.",
                "3-Button Quick Launcher: Add Expense, Split Bill, and Planning & Goals.",
                "Instant Home Screen privacy toggle with persistent App Group state."
            ]
        }
    }

    @ViewBuilder
    private func instructionStep(number: Int, text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(number)")
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .frame(width: 22, height: 22)
                .background(Circle().fill(LeafTheme.brandEmerald))

            Text(text)
                .font(LeafTypography.captionRegular)
                .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func togglePrivacy() {
        WidgetDataManager.shared.toggleBalanceVisibility()
        reloadLocalSnapshot()
    }

    private func refreshWidgets() {
        WidgetDataManager.shared.reloadWidgets()
        reloadLocalSnapshot()
        showReloadSuccess = true
        Task {
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            showReloadSuccess = false
        }
    }

    private func reloadLocalSnapshot() {
        self.snapshot = WidgetDataManager.shared.loadSnapshot()
        self.isBalanceVisible = WidgetDataManager.shared.isBalanceVisible()
    }
}
