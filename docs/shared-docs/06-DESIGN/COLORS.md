# Leaf Design System: Complete Color Palette & Token Specifications

## 1. Executive Summary
The Leaf color architecture is engineered to provide visual calm, high typographic legibility, and unmistakable financial feedback. It avoids harsh, vibrating neon accents in favor of deep Obsidian tones, warm canvas neutrals, and luxurious emerald gradients.

---

## 2. Core Palette Tokens

### 2.1 Dark Mode Surfaces (Obsidian & Charcoal)
| Token Name | Hex Code | SwiftUI Native Token | Usage / Semantic Role |
| :--- | :--- | :--- | :--- |
| `Charcoal950` | `#0A0C0F` | `Color("ObsidianBackground")` | Deepest canvas background in Dark Mode. Replaces harsh pure black `#000000`. |
| `Charcoal900` | `#14171E` | `Color("ObsidianCardSurface")` | Primary card surface, sheet background, and navigation bar fill. |
| `Charcoal850` | `#1C202A` | `Color("ObsidianCardElevated")` | Secondary elevated surface, nested stat cards, and inactive pills. |
| `Charcoal800` | `#262C3A` | `Color("ObsidianOutline")` | Subtle card borders, dividers, and component outlines. |
| `Charcoal700` | `#353C4D` | `Color("ObsidianDivider")` | Active selection pill borders and table row separators. |

### 2.2 Light Mode Surfaces (Warm Canvas & Pure White)
| Token Name | Hex Code | SwiftUI Native Token | Usage / Semantic Role |
| :--- | :--- | :--- | :--- |
| `CanvasWarm` | `#F4F6F9` | `Color("LightBackground")` | Calm neutral canvas background. Soft on the eyes compared to stark `#FFFFFF`. |
| `CanvasSurface` | `#FFFFFF` | `Color("LightCardSurface")` | Primary elevated card surface in Light Mode. |
| `CanvasElevated` | `#F0F3F7` | `Color("LightCardElevated")` | Secondary nested surface, text field background, and stat well. |
| `PureWhite` | `#FFFFFF` | `Color.white` | Pure white for high-contrast glyphs and inverted buttons. |

### 2.3 Neutral Grayscale (Typography & Metadata)
| Token Name | Hex Code | Purpose / Context |
| :--- | :--- | :--- |
| `NeutralGray950` | `#0B0F17` | Deepest jet black for primary amounts and headings in Light Mode. |
| `NeutralGray900` | `#111827` | High-emphasis body text in Light Mode. |
| `NeutralGray700` | `#374151` | Medium-emphasis text in Light Mode. |
| `NeutralGray500` | `#64748B` | Slate Gray: Subtitles, metadata, timestamps, and secondary labels. |
| `NeutralGray400` | `#94A3B8` | Muted icons, disabled button text, and placeholder hints. |
| `NeutralGray300` | `#CBD5E1` | Subtle divider lines in Light Mode. |
| `NeutralGray200` | `#E2E8F0` | Card borders and input field borders in Light Mode. |
| `NeutralGray100` | `#F1F5F9` | Pill background, unselected category background in Light Mode. |

---

## 3. Brand Accent & Luxury Gradients

| Token Name | Hex Code | Purpose / Context |
| :--- | :--- | :--- |
| `BrandGreen` | `#028166` | Primary Leaf Brand Green (Used on Light Mode icons, FAB, primary buttons). |
| `BrandGreenDark` | `#014D3D` | Deep pressed state for green buttons; text color inside light containers. |
| `BrandGreenLight` | `#05B38C` | Primary Leaf Brand Green in Dark Mode (High-contrast emerald highlight). |
| `BrandGreenContainer` | `#E6F5F1` | Light Mode subtle tint container for active pills and badges. |
| `BrandGreenDarkContainer` | `#08261F` | Dark Mode subtle tint container for active pills and badges. |

### Gradient Specifications
```swift
// Emerald Luxury Hero Gradient (Used on primary Balance Hero Card)
let heroEmeraldGradient = LinearGradient(
    colors: [Color(hex: "#025442"), Color(hex: "#02785E"), Color(hex: "#039876")],
    startPoint: .topLeading,
    endPoint: .bottomTrailing
)

// Obsidian Luxury Hero Gradient (Used on dark hero cards and stealth mode)
let heroObsidianGradient = LinearGradient(
    colors: [Color(hex: "#0F131A"), Color(hex: "#171D27"), Color(hex: "#111F1B")],
    startPoint: .topLeading,
    endPoint: .bottomTrailing
)
```

---

## 4. Semantic Financial Colors

Financial indicators are color-coded to provide instant cognitive recognition:

| Semantic State | Light Mode Text/Icon | Light Mode Container | Dark Mode Text/Icon | Dark Mode Container |
| :--- | :--- | :--- | :--- | :--- |
| **INCOME** | `#059669` (Emerald Dark) | `#ECFDF5` | `#34D399` (Emerald Light) | `#064E3B` |
| **EXPENSE** | `#E11D48` (Rose Dark) | `#FFF1F2` | `#FB7185` (Rose Light) | `#4C0519` |
| **WARNING** | `#D97706` (Amber Dark) | `#FEF3C7` | `#FBBF24` (Amber Light) | `#451A03` |
| **INFO** | `#2563EB` (Blue Dark) | `#EFF6FF` | `#60A5FA` (Blue Light) | `#1E3A8A` |

---

## 5. Curated Category Swatch Palette (12 Colors)
Every category created in Leaf is assigned one of these 12 harmonious hex colors:

| Color Name | Hex Code | Semantic Association |
| :--- | :--- | :--- |
| Ruby Red | `#EF4444` | Food, Dining, Urgent Bills |
| Warm Orange | `#F97316` | Housing, Rent, Hardware |
| Amber Gold | `#F59E0B` | Transport, Fuel, Commute |
| Emerald Green | `#10B981` | Salary, Health, Medical |
| Mint Teal | `#14B8A6` | Personal Care, Wellness, Refunds |
| Cyan Blue | `#06B6D4` | Business Revenue, Utilities |
| Azure Blue | `#3B82F6` | Bills, Freelance, Tech |
| Indigo | `#6366F1` | Education, Books, Tuition |
| Violet Purple | `#8B5CF6` | Shopping, Fashion, Investments |
| Magenta Pink | `#EC4899` | Entertainment, Hobbies, Gifts |
| Slate Gray | `#64748B` | Other, General, Uncategorized |
| Crimson Deep | `#DC2626` | Loans, EMI, Taxes |

---

## 6. Accessibility & WCAG Compliance
- All text-to-background combinations meet or exceed **WCAG 2.1 AA** contrast ratio standards ($4.5:1$ for normal body text, $3.0:1$ for large titles and numbers).
- In Dark Mode, `#0A0C0F` paired with `#FFFFFF` provides an ultra-high contrast ratio of $> 18:1$.
- Financial amounts always pair color with directional signs (`+` or `-`) and descriptive labels so color-blind users are never confused.

