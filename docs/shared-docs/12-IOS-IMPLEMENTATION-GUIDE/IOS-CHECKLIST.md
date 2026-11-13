# Leaf Master iOS Implementation: Feature Verification Checklist

## 1. Executive Summary
This checklist provides an actionable verification inventory for the development team and QA engineers implementing Leaf for iOS. Every box must be checked before submitting a build for release.

---

## 2. Comprehensive Implementation Checklist

### 2.1 Core Foundations & Math
- [ ] `Amount` stores values strictly as `Int64` subunits.
- [ ] `Amount.fromStringOrNull()` parses strings without using floating-point conversions.
- [ ] 9 global currencies correctly scale by subunit factor (100 for INR/USD/EUR/etc., 1 for JPY).
- [ ] Negative amounts format with leading `-` before the currency symbol (e.g. `-₹500.00`).
- [ ] All monetary UI elements use `.monospacedDigit()`.
- [ ] `SplitCalculationEngine` allocates division remainder $R = \text{Total} \pmod N$ to the first $R$ participants.
- [ ] `FinancialCalculatorEngine` matches standard banking test vectors for EMI, SIP, FD, RD, GST, and Discount.
- [ ] `NetBalanceEngine` correctly simplifies pairwise directional debts across shared bills.
- [ ] `EasterEggEngine` detects Zero Mode, The ₹1 Test, Paisa Perfect, Midnight greeting, and Konami swipe sequence without altering balances.

### 2.2 Database & Persistence (GRDB SQLite)
- [ ] SQLite database initializes at Schema Version 10.
- [ ] Exact 10 tables created with identical columns, types, and defaults.
- [ ] 20 default categories (12 expense, 8 income) pre-seeded upon first database creation.
- [ ] Foreign key `ON DELETE RESTRICT` active on `transactions(category_id)` and `split_expenses(category_id)`.
- [ ] Foreign key `ON DELETE CASCADE` active on `split_participants(split_expense_id)` and `contributions(goal_id)`.
- [ ] Foreign key `ON DELETE SET NULL` active on `split_expenses(group_id)` and `budgets(category_id)`.
- [ ] SQLite connection configured with `PRAGMA foreign_keys = ON;` and `PRAGMA journal_mode = WAL;`.

### 2.3 Presentation & Navigation
- [ ] Persistent 5-tab bottom navigation bar (`Dashboard`, `Transactions`, `Split`, `Planning`, `Insights`).
- [ ] Hero Balance Card features smooth `HeroEmeraldGradient` and eye visibility toggle.
- [ ] Category Donut Chart renders with 0.65 inner cutout and reactive segment tap selection.
- [ ] Transaction Entry Sheet allows logging in $< 3$ seconds with automatic keyboard focus.
- [ ] Swipe-to-delete on transactions reveals native ruby action with haptic confirmation.
- [ ] Multi-criteria filter sheet filters transactions by type, category, date range, and payment method.
- [ ] All corners use continuous squircle curvature (`.continuous`).

### 2.4 Split & Collect 2.0
- [ ] Equal Split divides total bill evenly with zero penny loss.
- [ ] Custom Split enforces exact zero-sum validation before allowing save.
- [ ] Itemized Split supports individual items with consumer allocation and unallocated base distribution.
- [ ] WhatsApp Share pre-populates itemized breakdown text and UPI payment link.
- [ ] UPI QR modal generates crisp vector QR code via `CoreImage`.
- [ ] "Add to transactions" toggle creates linked `EXPENSE` transaction in general ledger.
- [ ] Settling a participant creates linked `INCOME` transaction in general ledger.
- [ ] Deleting a split expense preserves historical ledger transactions.

### 2.5 Planning, Budgets & Savings Goals
- [ ] Monthly category budgets dynamically color progress bars: Green (<75%), Amber (75-99%), Warning (100%), Red (>100%).
- [ ] Overall monthly budget cap tracks total spending across all categories.
- [ ] Savings Goals display circular/linear progress bars and active vs archived filters.
- [ ] Required monthly savings rate calculates with ceiling division: $\lceil \text{Deficit} / \text{MonthsRemaining} \rceil$.
- [ ] Goal contributions can link optionally to checking account expense transactions.

### 2.6 Insights, Statements & PDF
- [ ] Analytics view renders spending vs income grouped bars and net savings rate card.
- [ ] Monthly Ledger statement maintains continuous opening/closing balance parity.
- [ ] Vector PDF statement renders bank-grade multi-page document via `UIGraphicsPDFRenderer`.
- [ ] In-app PDF preview opens with native iOS system `ShareLink`.
- [ ] Calendar view renders monthly grid with daily spending pills and selected day transaction feed.

### 2.7 Security, Privacy & System Integration
- [ ] 4-digit PIN hash and 16-byte random salt stored securely in Apple Keychain.
- [ ] LocalAuthentication framework triggers Face ID / Touch ID with passcode fallback.
- [ ] 5 consecutive failed PIN attempts triggers 30-second rate-limiting lockout that persists across restarts.
- [ ] App Switcher recents snapshot blurs when entering background if privacy setting enabled.
- [ ] 9:00 PM evening reminder silently suppresses if user already logged a transaction today.
- [ ] WidgetKit extension provides Medium (Overview) and Small (Today's Spend) interactive widgets.
- [ ] Quick Actions on app icon deep link directly to "+ Expense", "+ Income", and "Transactions".
- [ ] Local JSON v2 export/import restores database with 0 subunits deviation.

