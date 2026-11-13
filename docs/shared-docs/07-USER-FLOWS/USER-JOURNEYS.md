# Leaf User Flows: Primary User Journeys & Step-by-Step Walkthroughs

## 1. Executive Summary
This document charts the end-to-end user journeys for the primary real-world use cases supported by Leaf. Each journey outlines user motivations, system reactions, UI state transitions, and validation checkpoints.

---

## 2. Journey 1: First-Time User Onboarding & Calibration

- **User Motivation**: A new user wants a clean, private expense tracker without creating yet another cloud account or sharing their bank credentials.
- **Walkthrough Steps**:
  1. **Launch**: User opens Leaf for the first time. The `WelcomeScreen` appears with Leaf branding and privacy pillars (Offline First, Zero Trackers).
  2. **Auth Decision**:
     - User taps *"Continue Without Account"* to prioritize local-first privacy.
     - Alternatively, user taps *"Sign in with Google"* to link Google Drive for automatic cloud backup.
  3. **Interactive Tour**: User is guided through the 5-step visual tour (`AppTourScreen`):
     - Step 1: Mindful financial philosophy.
     - Step 2: Balance hero card overview.
     - Step 3: Fast transaction logging and payment methods (Cash/Account).
     - Step 4: Visual analytics and category donut charts.
     - Step 5: Privacy, app lock, and data control.
  4. **Tour Conclusion**: User taps *"Get Started"*. Preference `isAppTourCompleted` is set to `true`.
  5. **Landing & Opening Balance**: User lands on the Dashboard. Net balance displays `₹0.00`. User taps Settings to calibrate their current bank balance into the base opening balance.

---

## 3. Journey 2: 3-Second Daily Expense Logging (The Habit Loop)

- **User Motivation**: User buys a coffee for ₹180 at a café and wants to record it immediately with zero friction.
- **Walkthrough Steps**:
  1. **Entry Trigger**:
     - Option A: Long-press app icon and select *"Add Expense"* shortcut.
     - Option B: Tap `+ Expense` pill on the Home Screen Widget.
     - Option C: Tap `+ Expense` quick-action button on the Dashboard.
  2. **Input Interaction**:
     - `AddEditTransactionSheet` slides up from the bottom.
     - Numeric input is automatically focused. User enters `180`.
     - User taps the `"Food & Dining"` category chip.
     - Payment method defaults to `CASH` or `ACCOUNT` based on user preference.
     - (Optional) User types a quick note: `"Cold brew"`.
  3. **Confirmation**:
     - User taps `"Save"`.
     - Transaction is inserted into SQLite in $< 5$ ms.
     - Net balance card decreases by ₹180 with smooth counter animation.
     - Category donut chart updates reactively.
     - Sheet dismisses with light haptic feedback. Total time elapsed: $< 3$ seconds.

---

## 4. Journey 3: Dinner Bill Splitting & UPI Repayment Collection (Split 2.0)

- **User Motivation**: User pays ₹3,200 for a group dinner with 3 friends (Rahul, Priya, Amit) and wants to collect repayments accurately without manual math.
- **Walkthrough Steps**:
  1. **Navigation**: User navigates to the *"Split"* tab and taps `+ New Split`.
  2. **Bill Setup**:
     - User enters bill title: `"Dinner at Olive"`.
     - Enters total bill amount: `₹3,200.00`.
     - Confirms payer: `"Me"`.
     - Adds participants: `Rahul`, `Priya`, `Amit`. (Total 4 people including Me).
  3. **Split Method Selection**:
     - User selects `Equal Split`.
     - System calculates: $3200 / 4 = ₹800.00$ each. Remainder = 0 paise.
     - User toggles *"Add my share to expenses"*.
  4. **Save & Ledger Integration**:
     - User saves the bill.
     - An `EXPENSE` transaction of ₹800 is automatically added to the user's personal ledger under "Food & Dining".
     - Outstanding debts of ₹800 each are recorded for Rahul, Priya, and Amit.
  5. **WhatsApp Sharing & QR Collection**:
     - User taps `"Share on WhatsApp"`. Leaf pre-populates a breakdown message with amounts and UPI payment instructions.
     - Rahul pays immediately via UPI. User opens `SplitDetailScreen`, expands Rahul's card, and checks `"Mark as Settled"`.
     - System prompts: Creates a linked `INCOME` transaction of ₹800 titled *"Settlement: Rahul (Dinner at Olive)"*.
     - Net debt updates from ₹2,400 to ₹1,600.

---

## 5. Journey 4: Monthly Financial Audit & Bank-Grade PDF Export

- **User Motivation**: At the end of the month, user wants to review total spending, verify cashflow health, and export a formal statement for tax or archival purposes.
- **Walkthrough Steps**:
  1. **Navigation**: User navigates to the *"Insights"* tab and selects `"Monthly Ledger"`.
  2. **Audit Review**:
     - User reviews the continuous opening balance, total monthly income, total monthly expense, and closing balance.
     - Examines daily cashflow line items and category distributions.
  3. **PDF Generation**:
     - User taps `"Export PDF Statement"`.
     - Vector PDF engine renders a high-resolution, multi-page bank-grade statement with metadata, summary cards, and itemized transaction tables.
  4. **Preview & Share**:
     - Statement opens in `PdfViewerScreen`.
     - User verifies formatting and taps the system share button to save to Files or email to their accountant.

---

## 6. Journey 5: Setting & Tracking a Savings Goal Milestone

- **User Motivation**: User wants to save ₹1,50,000 for a vacation to Japan in 10 months.
- **Walkthrough Steps**:
  1. **Creation**:
     - User navigates to *"Planning"* -> *"Savings Goals"* tab and taps `+ New Goal`.
     - Enters name: `"Japan Trip"`, target: `₹1,50,000.00`, target date: 10 months out, icon: `flight`, color: `#3B82F6`.
  2. **Deficit Calculation**:
     - System calculates required monthly savings rate: $\lceil 150000 / 10 \rceil = ₹15,000.00$ per month.
  3. **Monthly Contribution**:
     - On payday, user opens the goal and taps `+ Add Contribution`.
     - Inputs `₹15,000.00` with note `"November salary deposit"`.
     - User selects option to record linked Expense transaction from checking account.
     - Goal progress ring animates to `10.0%` (₹15,000 of ₹1,50,000 saved).

