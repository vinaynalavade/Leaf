import SwiftUI

/// Reusable category icon badge component adhering to Leaf's continuous squircle design.
/// Automatically maps Android Material icon identifiers to native Apple SF Symbols.
public struct CategoryIconBadge: View {
    public let iconName: String
    public let colorHex: String
    public let size: CGFloat
    public let iconScale: CGFloat

    public init(
        iconName: String,
        colorHex: String,
        size: CGFloat = 40,
        iconScale: CGFloat = 0.5
    ) {
        self.iconName = iconName
        self.colorHex = colorHex
        self.size = size
        self.iconScale = iconScale
    }

    public var body: some View {
        let categoryColor = Color(hex: colorHex)
        let sfSymbol = CategoryIconBadge.sfSymbol(for: iconName)

        ZStack {
            RoundedRectangle(cornerRadius: size * 0.3, style: .continuous)
                .fill(categoryColor.opacity(0.16))

            Image(systemName: sfSymbol)
                .font(.system(size: size * iconScale, weight: .semibold))
                .foregroundStyle(categoryColor)
        }
        .frame(width: size, height: size)
    }

    /// Maps Android Material icon name to native SF Symbols.
    public static func sfSymbol(for iconName: String) -> String {
        switch iconName.lowercased() {
        case "restaurant": return "fork.knife"
        case "directions_car": return "car.fill"
        case "shopping_bag": return "bag.fill"
        case "receipt_long": return "doc.text.fill"
        case "movie": return "film.fill"
        case "medical_services": return "cross.case.fill"
        case "school": return "graduationcap.fill"
        case "spa": return "leaf.fill"
        case "home": return "house.fill"
        case "account_balance": return "building.columns.fill"
        case "subscriptions": return "play.rectangle.on.rectangle.fill"
        case "more_horiz": return "ellipsis"
        case "payments": return "banknote.fill"
        case "work": return "briefcase.fill"
        case "trending_up": return "chart.line.uptrend.xyaxis"
        case "real_estate_agent": return "key.fill"
        case "storefront": return "cart.fill"
        case "card_giftcard": return "gift.fill"
        case "replay": return "arrow.counterclockwise"
        case "attach_money": return "creditcard.fill"
        case "savings": return "archivebox.fill"
        case "group": return "person.2.fill"
        default: return "tag.fill"
        }
    }
}

