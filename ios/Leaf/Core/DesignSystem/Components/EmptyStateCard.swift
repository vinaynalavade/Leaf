import SwiftUI

/// Reusable native iOS empty state component with gentle visual styling and call-to-action support.
public struct EmptyStateCard: View {
    @Environment(\.colorScheme) private var colorScheme

    public let icon: String
    public let title: String
    public let description: String
    public let actionTitle: String?
    public let action: (() -> Void)?

    public init(
        icon: String,
        title: String,
        description: String,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.icon = icon
        self.title = title
        self.description = description
        self.actionTitle = actionTitle
        self.action = action
    }

    public init(
        icon: String,
        title: String,
        message: String,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.icon = icon
        self.title = title
        self.description = message
        self.actionTitle = actionTitle
        self.action = action
    }

    public init(
        title: String,
        subtitle: String,
        iconName: String,
        actionTitle: String? = nil,
        onAction: (() -> Void)? = nil
    ) {
        self.icon = iconName
        self.title = title
        self.description = subtitle
        self.actionTitle = actionTitle
        self.action = onAction
    }

    public var body: some View {
        SquircleCard(cornerRadius: 18) {
            VStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(LeafTheme.accent(for: colorScheme).opacity(0.12))
                        .frame(width: 52, height: 52)

                    Image(systemName: icon)
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundStyle(LeafTheme.accent(for: colorScheme))
                }

                VStack(spacing: 6) {
                    Text(title)
                        .font(LeafTypography.titleSmall)
                        .foregroundStyle(LeafTheme.textPrimary(for: colorScheme))

                    Text(description)
                        .font(LeafTypography.caption)
                        .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 16)
                }

                if let actionTitle = actionTitle, let action = action {
                    Button(action: action) {
                        Text(actionTitle)
                            .font(LeafTypography.bodyBold)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 18)
                            .padding(.vertical, 8)
                            .background(
                                Capsule()
                                    .fill(LeafTheme.accent(for: colorScheme))
                            )
                    }
                    .padding(.top, 4)
                }
            }
            .padding(.vertical, 22)
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity)
        }
    }
}

