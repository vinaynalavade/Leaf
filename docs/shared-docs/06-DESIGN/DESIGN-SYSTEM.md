# Leaf Design System: "Emerald & Obsidian" Architecture & HIG Adaptation

## 1. Executive Summary & Design Philosophy
Leaf's visual identity, known internally as **"Emerald & Obsidian"**, balances fintech authority with calm, mindful clarity. Rather than confronting users with overwhelming tables of numbers or gamified clutter, Leaf treats financial management as an oasis of focus and tranquility.

The design identity is built upon four aesthetic pillars:
1. **Calm Authority**: Deep Obsidian (`#0A0C0F` / `#14171E`) and Canvas Warm (`#F4F6F9`) backgrounds anchor the eye without visual vibration.
2. **Emerald Distinction**: Rich, deep emerald greens (`#028166` / `#05B38C`) serve as the primary brand signature and semantic indicators of savings and income.
3. **Continuous Curvature**: Surfaces feature continuous curvature (squircle geometry) with nested hierarchical radii to produce a soft, organic, tactile feel.
4. **Legibility & Breathing Room**: Generous 20 pt screen margins, distinct elevation layers, and tabular numerals ensure effortless reading at a glance.

---

## 2. Apple Human Interface Guidelines (HIG) Adaptation Strategy

The goal is **NOT** to port Android Material Design controls directly onto iOS. Instead, Leaf's product soul must be expressed through native iOS conventions:

| Design Dimension | Android Jetpack Compose Implementation | Native iOS SwiftUI / HIG Adaptation |
| :--- | :--- | :--- |
| **Navigation Model** | BottomNavigationBar with Scaffold, modal NavHost | Native `TabView` with translucent glass effect; hierarchical `NavigationStack` |
| **Modals & Sheets** | Compose `ModalBottomSheet` with draggable drag handle | Native SwiftUI `.sheet` with presentation detents (`.medium`, `.large`) and `.interactiveDismissDisabled` |
| **Action Sheets & Menus** | Compose `DropdownMenu` or custom dialogs | Native iOS `confirmationDialog` and `Menu` controls |
| **Material Icons** | Google Material Symbols (`restaurant`, `payments`, etc.) | Apple **SF Symbols** with hierarchical rendering mode (`fork.knife`, `banknote`, etc.) |
| **Haptic Feedback** | `LocalHapticFeedback.current.performHapticFeedback` | Core Haptics / `UIImpactFeedbackGenerator(.light / .medium)` & `UINotificationFeedbackGenerator` |
| **Visual Materials** | Solid color fills with surface tint overlays | Native Apple **Blur Materials** (`.ultraThinMaterial`, `.regularMaterial`) with vibrance |
| **Top App Bars** | Compose `TopAppBar` with centered titles | Native iOS large title navigation bars (`.navigationBarTitleDisplayMode(.large)`) collapsing on scroll |
| **Dialog Surfaces** | Compose `AlertDialog` with custom `DialogShape` | Native SwiftUI `.alert` or custom sheet overlays adhering to HIG alert styling |

---

## 3. Spacing System Scale
Leaf enforces a strict, mathematical spacing scale based on 4 pt and 8 pt grid multiples:

| Token Name | Value | Android Token | SwiftUI Token / Usage | Purpose / Context |
| :--- | :--- | :--- | :--- | :--- |
| `none` | `0 pt` | `Spacing.none` | `0` | Zero margin / padding |
| `xxs` | `2 pt` | `Spacing.xxs` | `2` | Micro adjustments, badge offsets |
| `xs` | `4 pt` | `Spacing.xs` | `4` | Spacing between icon and small label |
| `sm` | `8 pt` | `Spacing.sm` | `8` | Chip internal padding, tight list item gaps |
| `md` | `12 pt` | `Spacing.md` | `12` | Standard gap between form fields, subheaders |
| `lg` | `16 pt` | `Spacing.lg` | `16` | Standard card internal padding, list separators |
| `xl` | `20 pt` | `Spacing.xl` | `20` | **Standard Screen Edge Insets** & Card Padding |
| `xxl` | `24 pt` | `Spacing.xxl` | `24` | Major section headers, card-to-card spacing |
| `section` | `32 pt` | `Spacing.section` | `32` | Major grouping breaks, hero card bottom margins |
| `huge` | `48 pt` | `Spacing.huge` | `48` | Empty state illustrations, auth headers |

---

## 4. Corner Radius & Shape Hierarchy
Leaf utilizes continuous squircle corner curvature. The radii follow a strict containment hierarchy: outer containers have larger radii than nested inner elements:

```
Hero Card (28 pt)
  └── Inner Stat Pill (14 pt)
Card (20 pt)
  └── Inner Category Squircle (14 pt)
       └── Icon Glyph (Inner)
```

| Component | Radius Token | Value | Geometry Type |
| :--- | :--- | :--- | :--- |
| Hero Balance Card | `HeroCardShape` | `28 pt` | Continuous Squircle (`RoundedRectangle(cornerRadius: 28, style: .continuous)`) |
| Standard Content Cards | `CardShape` | `20 pt` | Continuous Squircle (`cornerRadius: 20`) |
| Nested Inner Cards / Stat Wells | `InnerCardShape` | `14 pt` | Continuous Squircle (`cornerRadius: 14`) |
| Primary Action Buttons | `ButtonShape` | `16 pt` | Rounded Rectangle (`cornerRadius: 16`) |
| Form Input Fields | `InputShape` | `16 pt` | Rounded Rectangle (`cornerRadius: 16`) |
| Category Squircle Icon Badge | `SquircleIconShape` | `14 pt` | Continuous Squircle (`cornerRadius: 14`) |
| Category / Filter Chips | `ChipShape` | `10 pt` | Rounded Rectangle (`cornerRadius: 10`) |
| Modal Bottom Sheets | `SheetShape` | Top `28 pt` | Top-rounded corners only |
| Modal Dialogs | `DialogShape` | `28 pt` | Continuous Squircle (`cornerRadius: 28`) |
| Circular / Pill Elements | `PillShape` | `50%` | Stadium Capsule (`Capsule()`) |

---

## 5. Elevation, Depth & Layering

### 5.1 Dark Mode Layering Strategy (No Harsh Dropshadows)
In Dark Mode, depth is communicated through **tonal surface elevation** rather than black drop shadows:
- **Level 0 (Base Canvas)**: Obsidian Night `#0A0C0F`
- **Level 1 (Cards & Groups)**: Charcoal `#14171E` (with subtle 1 pt outline in `#262C3A`)
- **Level 2 (Elevated Surfaces & Wells)**: Charcoal Elevated `#1C202A`
- **Level 3 (Modal Sheets & Popovers)**: Charcoal Floating `#202633` with top border highlight

### 5.2 Light Mode Layering Strategy
- **Level 0 (Base Canvas)**: Warm Neutral `#F4F6F9`
- **Level 1 (Cards)**: Pure White `#FFFFFF` with subtle border `#E2E8F0` and diffuse shadow:
  `box-shadow: 0px 4px 20px rgba(15, 23, 42, 0.04)`
- **Level 2 (Input Fields & Inactive Pills)**: Level 2 Canvas `#F1F5F9`

---

## 6. Motion & Transitions Specification
Leaf animations are calm, weighted, and natural:
- **Standard Spring**: `spring(response: 0.35, dampingRatio: 0.8)` for sheet transitions, dialog appearances, and button scale feedback.
- **Card Expansions**: Smooth crossfade with 250 ms ease-out curve.
- **Number Counters**: Tabular numbers animate smoothly using vertical ticker digit transitions or spring interpolation.

