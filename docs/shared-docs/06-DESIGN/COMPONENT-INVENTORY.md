# Leaf Design System: Component Inventory & UI Catalog

## 1. Executive Summary
This document provides an exhaustive inventory of the core user interface components that comprise the Leaf design language. Each component is defined with its visual specification, state variants, Android Compose reference, and recommended SwiftUI implementation.

---

## 2. Core Financial Components

### 2.1 Balance Hero Card (`BalanceHeroCard`)
- **Role**: Marquee card at the top of the Dashboard displaying net liquid worth and cashflow.
- **Visuals**:
  - Dimensions: Full width with 20 pt screen margins, 28 pt continuous squircle radius.
  - Background: `HeroEmeraldGradient` (`#025442` to `#039876`) or `HeroObsidianGradient`.
  - Top Bar: "TOTAL BALANCE" overline label (11 pt semi-bold uppercase), Eye icon button (toggles balance obfuscation `••••••`).
  - Hero Figure: 38 pt bold tabular amount with currency symbol.
  - Bottom Well: 2-column stat card:
    - Left Column: "INCOME" with green up-arrow and amount.
    - Right Column: "EXPENSES" with red down-arrow and amount.
- **Android Reference**: `presentation/dashboard/components/BalanceHeroCard.kt`
- **SwiftUI Mapping**:
  ```swift
  struct BalanceHeroCard: View {
      let netBalance: Amount
      let monthlyIncome: Amount
      let monthlyExpense: Amount
      let isVisible: Bool
      let onToggleVisibility: () -> Void
  }
  ```

---

### 2.2 Category Squircle Icon Badge (`CategoryIcon`)
- **Role**: Visual identifier for categories across transactions, split bills, and analytics.
- **Visuals**:
  - Size: 40×40 pt (standard list) or 48×48 pt (dialogs).
  - Shape: 14 pt squircle (`RoundedCornerShape(14.dp)` / `.continuous`).
  - Container Background: Category hex color at 15% opacity (`color.opacity(0.15)`).
  - Center Glyph: Solid category color at 100% opacity (size 22×22 pt).
- **Android Reference**: `presentation/components/CategoryIcon.kt`
- **SwiftUI Mapping**:
  ```swift
  struct CategoryIconBadge: View {
      let iconName: String
      let colorHex: String
      var size: CGFloat = 40
  }
  ```

---

### 2.3 Transaction Row Item (`TransactionItemCard`)
- **Role**: Displays individual transactions in lists, search results, and recent activity.
- **Visuals**:
  - Leading: `CategoryIconBadge`.
  - Center:
    - Line 1: Transaction Title (15 pt medium).
    - Line 2: Category Name • Payment Method badge (`CASH` / `ACCOUNT`) • Relative Date/Time.
  - Trailing:
    - Formatted amount in 16 pt semi-bold tabular figures.
    - Colored in Rose (`#E11D48` / `#FB7185`) with `-` for expenses, or Emerald (`#059669` / `#34D399`) with `+` for income.
  - Interaction: Tap opens Edit sheet; swipe-to-delete reveals ruby delete action.
- **Android Reference**: `presentation/transactions/components/TransactionItemCard.kt`

---

### 2.4 Interactive Donut Chart (`CategoryDonutChart`)
- **Role**: Circular visualization of spending distribution by category.
- **Visuals**:
  - Canvas: Custom arc stroke rendering with 0.65 inner cutout radius.
  - Stroke Width: 24 pt.
  - Center Hole: Displays total spending amount (20 pt bold) and "Total Spent" label.
  - Tap Interaction: Tapping a segment highlights the category and displays its name, amount, and percentage in the center hole.
- **Android Reference**: `presentation/dashboard/components/CategoryDonutChart.kt`
- **SwiftUI Mapping**: Use SwiftUI `Charts` (`SectorMark`) on iOS 17+ or custom `Canvas` drawing for earlier iOS versions.

---

### 2.5 Quick Action Pills
- **Role**: Fast-entry shortcuts below the Hero Card.
- **Visuals**:
  - Horizontal row of four capsules (`Capsule()` / `PillShape`):
    - `+ Expense` (Ruby icon and subtle red tint container)
    - `+ Income` (Emerald icon and subtle green tint container)
    - `Split Bill` (Azure Blue icon and blue tint container)
    - `Analytics` (Violet icon and purple tint container)
  - Press Feedback: Scale down to 96% with spring haptic feedback.
- **Android Reference**: `presentation/dashboard/components/QuickActionPills.kt`

---

### 2.6 Budget Progress Bar (`BudgetProgressBar`)
- **Role**: Displays monthly category consumption against limits.
- **Visuals**:
  - Height: 8 pt track with 4 pt corner radius.
  - Track Background: Neutral Gray 200 (`#E2E8F0`) or Charcoal 800 (`#262C3A`).
  - Active Fill Bar: Dynamically colored based on threshold:
    - `< 75%`: Emerald Green (`#10B981`)
    - `75% - 99.9%`: Amber Gold (`#F59E0B`)
    - `100%`: Warning Amber (`#D97706`)
    - `> 100%`: Over-budget Crimson (`#DC2626`)
  - Subtext: "Spent ₹X.XX of ₹Y.YY (Z%)" and "₹W.WW remaining".

---

### 2.7 Settings & Option Tile (`SettingsTile`)
- **Role**: Reusable row in settings, accounts, and profile screens.
- **Visuals**:
  - Leading: Squircle icon with accent tint.
  - Center: Setting Title (15 pt medium) and optional explanatory Subtitle (12 pt gray).
  - Trailing: Current selection label (e.g. "INR (₹)"), Toggle Switch, or Chevron forward arrow.
- **Android Reference**: `presentation/settings/components/SettingsTiles.kt`

---

### 2.8 Empty State View (`EmptyStateView`)
- **Role**: Shown when lists, searches, or categories contain zero records.
- **Visuals**:
  - Central squircle container (64×64 pt) with soft emerald/slate glyph.
  - Title: 18 pt semi-bold centered headline.
  - Body: 14 pt muted body text explaining how to populate the view.
  - Call-to-Action: Optional primary pill button (e.g. "+ Add Transaction").

---

## 3. Modal Sheets & Dialog Containers

| Container | Visual Spec | Dismissal Behavior |
| :--- | :--- | :--- |
| **Transaction Entry Sheet** | Bottom sheet with top drag handle, max height 90% | Drag down or tap Cancel |
| **Split Entry Screen** | Full-screen modal with multi-step itemizer | Navigation back or Close button |
| **Add/Edit Category Dialog** | Centered modal (max width 440 pt, 28 pt radius) | Tap outside or tap Cancel |
| **PIN Lock Sheet** | Full-screen impenetrable overlay with number pad | Unlocks only on valid PIN or biometric success |

