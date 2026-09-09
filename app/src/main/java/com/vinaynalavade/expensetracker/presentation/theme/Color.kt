package com.vinaynalavade.expensetracker.presentation.theme

import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Immutable
import androidx.compose.runtime.staticCompositionLocalOf
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color

// ==========================================================================
// Leaf Luxury Core Palette (Fintech & Design Reference Quality)
// ==========================================================================

// Deep Obsidian & Charcoal (Authoritative Luxury Surfaces, Controls, FABs)
val Charcoal950 = Color(0xFF0A0C0F) // Deep Obsidian Night Background
val Charcoal900 = Color(0xFF14171E) // Primary Luxury Dark Surface / Card
val Charcoal850 = Color(0xFF1C202A) // Secondary Elevated Surface in Dark
val Charcoal800 = Color(0xFF262C3A) // Subtle Dark Outlines & Separators
val Charcoal700 = Color(0xFF353C4D) // Active Dark Chip Fill & Dividers

// Pure White & Warm Neutral Canvas (Light Mode)
val PureWhite = Color(0xFFFFFFFF)
val CanvasWarm = Color(0xFFF4F6F9)   // Refined, calm neutral canvas background
val CanvasSurface = Color(0xFFFFFFFF) // Pure white card surface
val CanvasElevated = Color(0xFFF0F3F7) // Soft tonal secondary surface

// Neutral Grays (Hierarchy for Secondary Elements, Text, Dividers)
val NeutralGray950 = Color(0xFF0B0F17) // Deep jet black for primary amounts
val NeutralGray900 = Color(0xFF111827)
val NeutralGray800 = Color(0xFF1F2937)
val NeutralGray700 = Color(0xFF374151)
val NeutralGray600 = Color(0xFF4B5563)
val NeutralGray500 = Color(0xFF64748B) // Slate Gray - Subtitles & Metadata
val NeutralGray400 = Color(0xFF94A3B8) // Muted Icons & Disabled States
val NeutralGray300 = Color(0xFFCBD5E1) // Subtle Dividers
val NeutralGray200 = Color(0xFFE2E8F0) // Card Outlines & Borders
val NeutralGray100 = Color(0xFFF1F5F9) // Level 2 Surface / Inactive Pill Background
val NeutralGray50 = Color(0xFFF8FAFC)

// ==========================================================================
// Leaf Brand Accent & Luxury Gradients
// ==========================================================================
val BrandGreen = Color(0xFF028166)          // Primary Brand Leaf Green
val BrandGreenDark = Color(0xFF014D3D)      // Deep Pressed Green
val BrandGreenLight = Color(0xFF05B38C)     // Dark Theme Accent Highlight
val BrandGreenContainer = Color(0xFFE6F5F1) // Light Mode Subtle Tint Container
val BrandGreenOnContainer = Color(0xFF014D3D)
val BrandGreenDarkContainer = Color(0xFF08261F)
val BrandGreenDarkOnContainer = Color(0xFFA7F3D0)

// Hero Card Gradients (Inspired by Reference Designs)
val HeroEmeraldGradient = Brush.linearGradient(
    colors = listOf(
        Color(0xFF025442),
        Color(0xFF02785E),
        Color(0xFF039876)
    )
)

val HeroObsidianGradient = Brush.linearGradient(
    colors = listOf(
        Color(0xFF0F131A),
        Color(0xFF171D27),
        Color(0xFF111F1B)
    )
)

val HeroDarkCardGradient = Brush.linearGradient(
    colors = listOf(
        Color(0xFF161A22),
        Color(0xFF202633),
        Color(0xFF182320)
    )
)

val AccentPurpleGradient = Brush.linearGradient(
    colors = listOf(Color(0xFF6366F1), Color(0xFF8B5CF6))
)

val AccentOrangeGradient = Brush.linearGradient(
    colors = listOf(Color(0xFFEA580C), Color(0xFFF97316))
)

// ==========================================================================
// Financial Semantic Colors (Emerald Income, Rose Expense, Amber Warning, Blue Info)
// ==========================================================================
val IncomeEmerald = Color(0xFF10B981)
val IncomeEmeraldDark = Color(0xFF059669)
val IncomeEmeraldLight = Color(0xFF34D399)
val IncomeContainerLight = Color(0xFFECFDF5)
val IncomeOnContainerLight = Color(0xFF065F46)
val IncomeContainerDark = Color(0xFF064E3B)
val IncomeOnContainerDark = Color(0xFFA7F3D0)

val ExpenseRose = Color(0xFFF43F5E)
val ExpenseRoseDark = Color(0xFFE11D48)
val ExpenseRoseLight = Color(0xFFFB7185)
val ExpenseContainerLight = Color(0xFFFFF1F2)
val ExpenseOnContainerLight = Color(0xFF9F1239)
val ExpenseContainerDark = Color(0xFF4C0519)
val ExpenseOnContainerDark = Color(0xFFFECDD3)

val WarningAmber = Color(0xFFD97706)
val WarningAmberLight = Color(0xFFFBBF24)
val WarningContainerLight = Color(0xFFFEF3C7)
val WarningContainerDark = Color(0xFF451A03)

val InfoBlue = Color(0xFF2563EB)
val InfoBlueLight = Color(0xFF60A5FA)
val InfoContainerLight = Color(0xFFEFF6FF)
val InfoContainerDark = Color(0xFF1E3A8A)

// Vibrant Category Colors for Charts & Tags
val CategoryColors = listOf(
    Color(0xFF8B5CF6), // Violet Purple
    Color(0xFFF97316), // Warm Orange
    Color(0xFF06B6D4), // Cyan Teal
    Color(0xFF10B981), // Emerald Green
    Color(0xFFEC4899), // Pink Magenta
    Color(0xFF3B82F6), // Azure Blue
    Color(0xFFEAB308), // Yellow Gold
    Color(0xFF64748B)  // Slate
)

/**
 * Dedicated semantic colors for financial operations across Light and Dark themes.
 */
@Immutable
data class FinancialColors(
    val income: Color,
    val incomeContainer: Color,
    val onIncomeContainer: Color,
    val expense: Color,
    val expenseContainer: Color,
    val onExpenseContainer: Color,
    val warning: Color = WarningAmber,
    val warningContainer: Color = WarningContainerLight,
    val info: Color = InfoBlue,
    val infoContainer: Color = InfoContainerLight
)

val LightFinancialColors = FinancialColors(
    income = IncomeEmeraldDark,
    incomeContainer = IncomeContainerLight,
    onIncomeContainer = IncomeOnContainerLight,
    expense = ExpenseRoseDark,
    expenseContainer = ExpenseContainerLight,
    onExpenseContainer = ExpenseOnContainerLight,
    warning = WarningAmber,
    warningContainer = WarningContainerLight,
    info = InfoBlue,
    infoContainer = InfoContainerLight
)

val DarkFinancialColors = FinancialColors(
    income = IncomeEmeraldLight,
    incomeContainer = IncomeContainerDark,
    onIncomeContainer = IncomeOnContainerDark,
    expense = ExpenseRoseLight,
    expenseContainer = ExpenseContainerDark,
    onExpenseContainer = ExpenseOnContainerDark,
    warning = WarningAmberLight,
    warningContainer = WarningContainerDark,
    info = InfoBlueLight,
    infoContainer = InfoContainerDark
)

val LocalFinancialColors = staticCompositionLocalOf { LightFinancialColors }

// Material 3 Light Color Scheme
val LightColorScheme = lightColorScheme(
    primary = NeutralGray950,
    onPrimary = PureWhite,
    primaryContainer = NeutralGray100,
    onPrimaryContainer = NeutralGray950,
    secondary = BrandGreen,
    onSecondary = PureWhite,
    secondaryContainer = BrandGreenContainer,
    onSecondaryContainer = BrandGreenOnContainer,
    tertiary = IncomeEmeraldDark,
    onTertiary = PureWhite,
    tertiaryContainer = IncomeContainerLight,
    onTertiaryContainer = IncomeOnContainerLight,
    error = ExpenseRoseDark,
    onError = PureWhite,
    errorContainer = ExpenseContainerLight,
    onErrorContainer = ExpenseOnContainerLight,
    background = CanvasWarm,
    onBackground = NeutralGray950,
    surface = CanvasSurface,
    onSurface = NeutralGray950,
    surfaceVariant = CanvasElevated,
    onSurfaceVariant = NeutralGray500,
    outline = NeutralGray200,
    outlineVariant = NeutralGray300,
    inverseSurface = NeutralGray950,
    inverseOnSurface = CanvasWarm,
    inversePrimary = PureWhite
)

// Material 3 Dark Color Scheme
val DarkColorScheme = darkColorScheme(
    primary = PureWhite,
    onPrimary = Charcoal950,
    primaryContainer = Charcoal850,
    onPrimaryContainer = PureWhite,
    secondary = BrandGreenLight,
    onSecondary = Charcoal950,
    secondaryContainer = BrandGreenDarkContainer,
    onSecondaryContainer = BrandGreenDarkOnContainer,
    tertiary = IncomeEmeraldLight,
    onTertiary = Charcoal950,
    tertiaryContainer = IncomeContainerDark,
    onTertiaryContainer = IncomeOnContainerDark,
    error = ExpenseRoseLight,
    onError = Charcoal950,
    errorContainer = ExpenseContainerDark,
    onErrorContainer = ExpenseOnContainerDark,
    background = Charcoal950,
    onBackground = PureWhite,
    surface = Charcoal900,
    onSurface = PureWhite,
    surfaceVariant = Charcoal850,
    onSurfaceVariant = NeutralGray400,
    outline = Charcoal800,
    outlineVariant = Charcoal700,
    inverseSurface = PureWhite,
    inverseOnSurface = Charcoal950,
    inversePrimary = Charcoal950
)

