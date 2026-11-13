import SwiftUI

/// Card representation of an individual financial calculator for the Tools landing hub.
public struct CalculatorCardView: View {
    @Environment(\.colorScheme) private var colorScheme

    public let tool: FinancialToolType
    public let onSelect: () -> Void

    public init(tool: FinancialToolType, onSelect: @escaping () -> Void) {
        self.tool = tool
        self.onSelect = onSelect
    }

    private var accentColor: Color {
        switch tool {
        case .emi: return LeafTheme.brandEmerald
        case .sip: return LeafTheme.accentLight
        case .fd: return LeafTheme.infoBlue
        case .rd: return LeafTheme.purpleAccent
        case .discount: return LeafTheme.warningGold
        case .gst: return LeafTheme.expenseCoral
        }
    }

    public var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(accentColor.opacity(0.14))
                            .frame(width: 44, height: 44)

                        Image(systemName: tool.iconName)
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(accentColor)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(LeafTheme.textSecondary(for: colorScheme).opacity(0.6))
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(tool.shortTitle)
                        .font(LeafTypography.titleMedium)
                        .foregroundStyle(LeafTheme.textPrimary(for: colorScheme))

                    Text(tool.subtitle)
                        .font(LeafTypography.caption)
                        .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(LeafTheme.card(for: colorScheme))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(LeafTheme.border(for: colorScheme), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

