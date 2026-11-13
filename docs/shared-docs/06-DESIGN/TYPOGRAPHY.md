# Leaf Design System: Typography Scale & Font Architecture

## 1. Executive Summary
In a personal finance app, typography is the core user interface. Numbers must be scannable, visually grounded, and aligned. 

Leaf's typographic system is optimized for **numerical legibility**, **hierarchical clarity**, and **cross-platform harmony**. On iOS, it seamlessly maps to Apple's system font **SF Pro** and **SF Pro Rounded** while enforcing tabular figure alignments (`tnum`) across all monetary tables.

---

## 2. Type Scale Mapping & Token Specifications

| Token Name | Size (pt/sp) | Weight | Line Height | Letter Spacing | Android Material 3 | iOS HIG SF Pro Mapping |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| `displayLarge` | `38 pt` | Bold (700) | `44 pt` | `-1.0 pt` | `displayLarge` | `.system(size: 38, weight: .bold, design: .rounded)` |
| `displayMedium` | `32 pt` | Bold (700) | `38 pt` | `-0.6 pt` | `displayMedium` | `.system(size: 32, weight: .bold, design: .rounded)` |
| `displaySmall` | `26 pt` | Bold (700) | `32 pt` | `-0.4 pt` | `displaySmall` | `.system(size: 26, weight: .bold, design: .rounded)` |
| `headlineLarge` | `22 pt` | Bold (700) | `28 pt` | `-0.2 pt` | `headlineLarge` | `.system(size: 22, weight: .bold, design: .default)` |
| `headlineMedium`| `20 pt` | SemiBold (600) | `26 pt` | `-0.1 pt` | `headlineMedium` | `.system(size: 20, weight: .semibold, design: .default)` |
| `headlineSmall` | `18 pt` | SemiBold (600) | `24 pt` | `0.0 pt` | `headlineSmall` | `.system(size: 18, weight: .semibold, design: .default)` |
| `titleLarge` | `18 pt` | SemiBold (600) | `24 pt` | `0.0 pt` | `titleLarge` | `.headline` (`size: 17, weight: .semibold`) |
| `titleMedium` | `16 pt` | SemiBold (600) | `22 pt` | `0.0 pt` | `titleMedium` | `.system(size: 16, weight: .semibold)` |
| `titleSmall` | `14 pt` | Medium (500) | `20 pt` | `0.0 pt` | `titleSmall` | `.subheadline` (`weight: .medium`) |
| `bodyLarge` | `15 pt` | Medium (500) | `22 pt` | `0.0 pt` | `bodyLarge` | `.body` (`size: 15, weight: .regular`) |
| `bodyMedium` | `14 pt` | Normal (400) | `20 pt` | `0.0 pt` | `bodyMedium` | `.callout` (`size: 14, weight: .regular`) |
| `bodySmall` | `12 pt` | Normal (400) | `16 pt` | `0.0 pt` | `bodySmall` | `.footnote` (`size: 12, weight: .regular`) |
| `labelLarge` | `14 pt` | SemiBold (600) | `20 pt` | `0.0 pt` | `labelLarge` | `.callout` (`weight: .semibold`) |
| `labelMedium` | `12 pt` | Medium (500) | `16 pt` | `0.0 pt` | `labelMedium` | `.caption1` (`weight: .medium`) |
| `labelSmall` | `11 pt` | SemiBold (600) | `14 pt` | `+0.2 pt` | `labelSmall` | `.caption2` (`weight: .semibold, uppercase`) |

---

## 3. Financial Number Rendering Rules

### 3.1 Tabular Figures (`monospacedDigit`)
In financial lists, statements, and cards, proportional numbers cause decimal points and currency symbols to jitter as values update.
- **Rule**: Every single monetary amount displayed in Leaf must use **monospaced digits**:
  ```swift
  Text(amount.format(currency))
      .font(.system(size: 18, weight: .semibold, design: .rounded))
      .monospacedDigit()
  ```

### 3.2 SF Pro Rounded for Monetary Hero Amounts
Primary balance figures and calculator keypads utilize **SF Pro Rounded** to introduce warmth and friendly approachability without compromising financial structure.
- **Usage**: Hero Card Net Balance, Today's Spend Widget, Calculator Display.

### 3.3 Negative Number Formatting
- Prepend `-` before the currency symbol: `-₹1,250.00`, never `₹-1,250.00` or `(₹1,250.00)`.
- Highlight negative numbers in Dark Rose (`#FB7185`) or Light Rose (`#E11D48`).

---

## 4. Typographic Roles by Screen Element

| Screen Element | Type Token | Weight | Color Role |
| :--- | :--- | :--- | :--- |
| **Hero Balance Number** | `displayLarge` (38 pt) | Bold | Pure White or Deep Jet Black |
| **Card Header Title** | `headlineSmall` (18 pt) | SemiBold | Primary Text (`onSurface`) |
| **Transaction Title** | `bodyLarge` (15 pt) | Medium | Primary Text |
| **Transaction Category Subtitle** | `bodySmall` (12 pt) | Normal | Neutral Gray 500 (`#64748B`) |
| **Transaction Amount** | `titleMedium` (16 pt) | SemiBold | Semantic Income/Expense Color |
| **Section Overline Header** | `labelSmall` (11 pt) | SemiBold (Uppercase) | Neutral Gray 500 (`#64748B`) |
| **Form Input Large Amount** | `displayMedium` (32 pt)| Bold | Primary Text |
| **Filter / Category Chip** | `labelMedium` (12 pt) | Medium | On Container Tint |

---

## 5. Dynamic Type & Accessibility Scaling
- On iOS, all text elements must observe Apple's **Dynamic Type** settings.
- Layouts must utilize flexible containers (`ViewThatFits`, `VStack`, scroll views) to ensure text does not clip when users increase system accessibility font sizes.

