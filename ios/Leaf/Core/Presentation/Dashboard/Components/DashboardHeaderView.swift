import SwiftUI

/// Polished native iOS dashboard header displaying dynamic time-of-day greeting,
/// user profile identity, and active brand indicator.
public struct DashboardHeaderView: View {
    @Environment(\.colorScheme) private var colorScheme
    public let profileName: String?
    public let onProfileTap: (() -> Void)?

    public init(
        profileName: String? = nil,
        onProfileTap: (() -> Void)? = nil
    ) {
        self.profileName = profileName
        self.onProfileTap = onProfileTap
    }

    private var timeGreeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 4..<12: return "Good morning,"
        case 12..<17: return "Good afternoon,"
        case 17..<23: return "Good evening,"
        default: return "Good night,"
        }
    }

    public var body: some View {
        HStack(alignment: .center, spacing: 14) {
            Button(action: { onProfileTap?() }) {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(LeafTheme.brandEmerald.opacity(0.18))
                            .frame(width: 44, height: 44)

                        Image(systemName: "person.crop.circle.fill")
                            .font(.system(size: 26, weight: .semibold))
                            .foregroundStyle(LeafTheme.brandEmerald)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(timeGreeting)
                            .font(LeafTypography.caption)
                            .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))

                        Text(profileName?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false ? profileName! : "Welcome back")
                            .font(LeafTypography.titleMedium)
                            .foregroundStyle(LeafTheme.textPrimary(for: colorScheme))
                            .lineLimit(1)
                    }
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel("\(timeGreeting) \(profileName ?? "User") profile")

            Spacer()

            // Brand leaf badge
            HStack(spacing: 6) {
                Image("LeafLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 18, height: 18)

                Text("Leaf")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(LeafTheme.textPrimary(for: colorScheme))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(colorScheme == .dark ? LeafTheme.cardElevatedDark : LeafTheme.cardElevatedLight)
            )
            .overlay(
                Capsule()
                    .stroke(LeafTheme.cardBorder(for: colorScheme), lineWidth: 0.5)
            )
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Leaf Application")
        }
        .padding(.horizontal)
        .padding(.top, 4)
    }
}

