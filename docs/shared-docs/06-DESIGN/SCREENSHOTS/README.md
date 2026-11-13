# Leaf Visual Assets & Screen Capture Guide

## 1. Executive Summary
This directory serves as the visual reference repository for Leaf. When building the native iOS application, the engineering team must preserve the aesthetic fidelity, typography, continuous corner curvature, and color contrast of the Android version.

---

## 2. Core Visual Brand Assets

| Asset Name | Android Resource | Description & Semantic Role | iOS Asset Catalog Target |
| :--- | :--- | :--- | :--- |
| **Leaf App Icon** | `mipmap/ic_launcher` | The primary application icon: Emerald leaf glyph inside a dark obsidian container. | `AppIcon.appiconset` |
| **Brand Logo** | `drawable/ic_leaf_logo.png` | High-resolution transparent PNG of the Leaf brand glyph for onboarding and splash. | `LeafBrandLogo.imageset` |
| **Notification Icon** | `drawable/ic_stat_leaf.xml` | Monochromatic vector glyph used in Android status bar push notifications. | SF Symbol `leaf.fill` |
| **Launcher Shortcuts** | `ic_shortcut_expense.xml`<br>`ic_shortcut_income.xml`<br>`ic_shortcut_transactions.xml` | Vector icons used in launcher quick-action context menus. | SF Symbols: `plus.circle.fill`, `arrow.down.circle.fill`, `list.bullet.rectangle` |

---

## 3. High-Priority Screen Capture Verification List
When running visual verification between Android and iOS, capture and compare the following key screens:

1. **Dashboard (Light & Dark)**:
   - Verify that the Hero Balance Card gradient is smooth without color banding.
   - Verify that the category donut chart cutout ratio is exactly 0.65.
2. **Transactions Ledger**:
   - Verify that category squircle icons use 15% opacity background fills.
   - Verify that numbers use monospaced digits (`monospacedDigit()`).
3. **Split Bill Creation (Split 2.0)**:
   - Verify that the itemized consumer allocation pill selection updates totals reactively.
4. **Monthly Ledger & Bank Statement**:
   - Verify that continuous opening and closing balances match to the exact paisa/cent.
5. **App Lock Vault**:
   - Verify that the 4-digit PIN indicator dots and numeric keypad provide tactile haptic feedback.

---

## 4. UI Asset Reproduction Standards
- **Vector Assets**: All icons must be rendered using vector assets (SF Symbols on iOS, Vector Drawables on Android) to ensure crisp rendering on 3x Retina displays.
- **Continuous Corners**: Never use simple circular radii where squircles are specified; always apply continuous curvature (`.continuous`).

