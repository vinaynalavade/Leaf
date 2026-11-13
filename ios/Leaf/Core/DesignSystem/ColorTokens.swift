import SwiftUI

extension Color {
    public init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

/// The official "Emerald & Obsidian" design tokens for Leaf.
public enum LeafTheme {

    // Raw Palette
    public static let canvasDark = Color(hex: "#0A0C0F")
    public static let cardDark = Color(hex: "#14171E")
    public static let cardElevatedDark = Color(hex: "#1C202A")
    public static let borderDark = Color(hex: "#262B36")

    public static let canvasLight = Color(hex: "#F4F6F9")
    public static let cardLight = Color(hex: "#FFFFFF")
    public static let cardElevatedLight = Color(hex: "#F0F3F7")
    public static let borderLight = Color(hex: "#E2E8F0")

    public static let brandEmerald = Color(hex: "#10B981")
    public static let accentDark = Color(hex: "#05B38C")
    public static let accentLight = Color(hex: "#028166")
    public static let incomeGreen = Color(hex: "#10B981")
    public static let expenseCoral = Color(hex: "#EF4444")
    public static let warningAmber = Color(hex: "#F59E0B")
    public static let warningGold = Color(hex: "#D97706")
    public static let amberAccent = Color(hex: "#F59E0B")
    public static let amberWarning = Color(hex: "#F59E0B")
    public static let crimsonRed = Color(hex: "#DC2626")
    public static let coralRose = Color(hex: "#F87171")
    public static let surfaceDark = Color(hex: "#1A1F2B")
    public static let surfaceLight = Color(hex: "#F1F5F9")
    public static let surface = Color(hex: "#F1F5F9")
    public static let infoBlue = Color(hex: "#3B82F6")
    public static let purpleAccent = Color(hex: "#8B5CF6")

    // Master Documentation Hero Gradients
    public static let heroEmeraldGradient = LinearGradient(
        colors: [Color(hex: "#025442"), Color(hex: "#02785E"), Color(hex: "#039876")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    public static let heroObsidianGradient = LinearGradient(
        colors: [Color(hex: "#0F131A"), Color(hex: "#171D27"), Color(hex: "#111F1B")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    public static func heroGradient(for colorScheme: ColorScheme) -> LinearGradient {
        colorScheme == .dark ? heroObsidianGradient : heroEmeraldGradient
    }

    // 4-Tier Budget Status Colors
    public static func budgetStatusColor(for status: BudgetStatus) -> Color {
        switch status {
        case .onTrack: return incomeGreen
        case .approachingLimit: return warningAmber
        case .limitReached: return warningGold
        case .overBudget: return crimsonRed
        }
    }

    // Dynamic Adapters
    public static func canvas(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? canvasDark : canvasLight
    }

    public static func card(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? cardDark : cardLight
    }

    public static func cardElevated(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? cardElevatedDark : cardElevatedLight
    }

    public static func cardBorder(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? borderDark : borderLight
    }

    public static func border(for colorScheme: ColorScheme) -> Color {
        cardBorder(for: colorScheme)
    }

    public static func subtleCard(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color(hex: "#1C202A") : Color(hex: "#F1F5F9")
    }

    public static func surface(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? surfaceDark : surfaceLight
    }

    public static func accent(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? accentDark : accentLight
    }

    public static func textPrimary(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color.white : Color(hex: "#0F172A")
    }

    public static func textSecondary(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color(hex: "#94A3B8") : Color(hex: "#64748B")
    }

    public static func textTertiary(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color(hex: "#64748B") : Color(hex: "#94A3B8")
    }
}

