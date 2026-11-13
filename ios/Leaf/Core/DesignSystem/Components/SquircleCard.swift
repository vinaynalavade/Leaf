import SwiftUI

public struct SquircleCard<Content: View>: View {
    @Environment(\.colorScheme) private var colorScheme
    private let cornerRadius: CGFloat
    private let isElevated: Bool
    private let content: Content

    public init(
        cornerRadius: CGFloat = 16,
        isElevated: Bool = false,
        @ViewBuilder content: () -> Content
    ) {
        self.cornerRadius = cornerRadius
        self.isElevated = isElevated
        self.content = content()
    }

    public var body: some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(isElevated ? LeafTheme.cardElevated(for: colorScheme) : LeafTheme.card(for: colorScheme))
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(LeafTheme.cardBorder(for: colorScheme), lineWidth: 1)
            )
    }
}

