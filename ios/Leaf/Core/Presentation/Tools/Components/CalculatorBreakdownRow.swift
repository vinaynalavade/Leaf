import SwiftUI

/// Itemized detail row for financial calculations.
public struct CalculatorBreakdownRow: View {
    @Environment(\.colorScheme) private var colorScheme

    public let label: String
    public let value: String
    public var subtitle: String? = nil
    public var accentColor: Color? = nil
    public var isBold: Bool = false

    public init(
        label: String,
        value: String,
        subtitle: String? = nil,
        accentColor: Color? = nil,
        isBold: Bool = false
    ) {
        self.label = label
        self.value = value
        self.subtitle = subtitle
        self.accentColor = accentColor
        self.isBold = isBold
    }

    public var body: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(isBold ? LeafTypography.bodyBold : LeafTypography.bodyMedium)
                    .foregroundStyle(LeafTheme.textPrimary(for: colorScheme))

                if let sub = subtitle, !sub.isEmpty {
                    Text(sub)
                        .font(LeafTypography.caption)
                        .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
                }
            }

            Spacer()

            Text(value)
                .font(Font.system(size: isBold ? 16 : 14, weight: isBold ? .bold : .semibold, design: .rounded))
                .foregroundStyle(accentColor ?? LeafTheme.textPrimary(for: colorScheme))
        }
        .padding(.vertical, 4)
    }
}

