import SwiftUI

/// Neutral privacy shield overlay view displayed whenever the application is `.inactive` or `.background`.
/// Obscures sensitive financial numbers, charts, and transaction ledgers from iOS multitasking
/// app switcher snapshots and notification shade reveals.
public struct PrivacyShieldView: View {
    @Environment(\.colorScheme) private var colorScheme

    public init() {}

    public var body: some View {
        ZStack {
            LeafTheme.canvas(for: colorScheme)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                // Neutral Leaf Brand Shield
                ZStack {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(LeafTheme.brandEmerald.opacity(0.12))
                        .frame(width: 88, height: 88)

                    Image(systemName: "leaf.fill")
                        .font(.system(size: 44))
                        .foregroundStyle(LeafTheme.brandEmerald)
                }

                VStack(spacing: 8) {
                    Text("Leaf")
                        .font(LeafTypography.titleLarge)
                        .foregroundStyle(LeafTheme.textPrimary(for: colorScheme))

                    HStack(spacing: 6) {
                        Image(systemName: "lock.shield.fill")
                            .font(.system(size: 13))
                            .foregroundStyle(LeafTheme.brandEmerald)

                        Text("Financial Privacy Protected")
                            .font(LeafTypography.captionBold)
                            .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
                    }
                }

                Spacer()

                // Subtitle footer
                Text("On-device hardware encryption active")
                    .font(LeafTypography.caption)
                    .foregroundStyle(LeafTheme.textSecondary(for: colorScheme).opacity(0.7))
                    .padding(.bottom, 24)
            }
        }
    }
}

