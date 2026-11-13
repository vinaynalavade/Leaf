import SwiftUI

/// Standard fintech input field card for calculator parameters.
public struct CalculatorInputField: View {
    @Environment(\.colorScheme) private var colorScheme

    public let label: String
    public let placeholder: String
    @Binding public var text: String
    public var prefix: String?
    public var suffix: String?
    public var keyboardType: UIKeyboardType = .decimalPad
    public var helperText: String? = nil

    public init(
        label: String,
        placeholder: String = "0",
        text: Binding<String>,
        prefix: String? = nil,
        suffix: String? = nil,
        keyboardType: UIKeyboardType = .decimalPad,
        helperText: String? = nil
    ) {
        self.label = label
        self.placeholder = placeholder
        self._text = text
        self.prefix = prefix
        self.suffix = suffix
        self.keyboardType = keyboardType
        self.helperText = helperText
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label.uppercased())
                .font(LeafTypography.captionBold)
                .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))

            HStack(spacing: 8) {
                if let pre = prefix, !pre.isEmpty {
                    Text(pre)
                        .font(LeafTypography.bodyBold)
                        .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
                }

                TextField(placeholder, text: $text)
                    .font(Font.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundStyle(LeafTheme.textPrimary(for: colorScheme))
                    .keyboardType(keyboardType)

                if let suf = suffix, !suf.isEmpty {
                    Text(suf)
                        .font(LeafTypography.captionBold)
                        .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(LeafTheme.card(for: colorScheme))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(LeafTheme.border(for: colorScheme), lineWidth: 1)
            )

            if let help = helperText, !help.isEmpty {
                Text(help)
                    .font(Font.system(size: 11, weight: .regular))
                    .foregroundStyle(LeafTheme.textSecondary(for: colorScheme).opacity(0.8))
                    .padding(.horizontal, 4)
            }
        }
    }
}

