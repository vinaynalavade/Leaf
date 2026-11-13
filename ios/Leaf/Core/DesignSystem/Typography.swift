import SwiftUI

public enum LeafTypography {
    public static let amountHero = Font.system(size: 38, weight: .bold, design: .rounded).monospacedDigit()
    public static let amountLarge = Font.system(size: 36, weight: .bold, design: .rounded).monospacedDigit()
    public static let amountMedium = Font.system(size: 24, weight: .bold, design: .rounded).monospacedDigit()
    public static let amountSmall = Font.system(size: 17, weight: .semibold, design: .rounded).monospacedDigit()

    public static let titleLarge = Font.system(size: 22, weight: .bold, design: .default)
    public static let titleMedium = Font.system(size: 18, weight: .semibold, design: .default)
    public static let titleSmall = Font.system(size: 15, weight: .medium, design: .default)

    public static let body = Font.system(size: 15, weight: .regular, design: .default)
    public static let bodyBold = Font.system(size: 15, weight: .semibold, design: .default)

    public static let caption = Font.system(size: 12, weight: .regular, design: .default)
    public static let captionBold = Font.system(size: 12, weight: .semibold, design: .default)

    // Semantic aliases
    public static let balanceHero = amountHero
    public static let headline = titleLarge
    public static let subheadline = titleSmall
    public static let bodyMedium = body
    public static let captionRegular = caption
    public static let bodySmall = Font.system(size: 13, weight: .regular, design: .default)
    public static let bodySmallBold = Font.system(size: 13, weight: .semibold, design: .default)
}

extension View {
    public func leafAmountFont(_ size: CGFloat = 24, weight: Font.Weight = .bold) -> some View {
        self.font(.system(size: size, weight: weight, design: .rounded).monospacedDigit())
    }
}

