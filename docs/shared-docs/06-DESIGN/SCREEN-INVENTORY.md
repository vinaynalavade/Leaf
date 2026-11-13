# Leaf Design System: Exhaustive Screen & Navigation Inventory

## 1. Executive Summary
This document provides an exhaustive inventory of all **33 distinct screens, sheets, and dialogs** that constitute the Leaf application. Each screen is documented with its technical route, corresponding Android ViewModel/Component, presentation role, and native iOS implementation mapping.

---

## 2. Complete Screen Catalog

| Screen Name | Route / Path | Android Source File | Role & Primary Features | Native iOS SwiftUI Mapping |
| :--- | :--- | :--- | :--- | :--- |
| **Welcome Screen** | `welcome` | `WelcomeScreen.kt` | First-run onboarding; Google Sign-In with Drive scope vs Offline Bypass; brand pillars showcase. | `WelcomeView.swift` |
| **App Tour Screen** | `tour` | `AppTourScreen.kt` | 5-step visual educational carousel with illustrated step cards, animated page dots, skip/next. | `AppTourView.swift` (`TabView`) |
| **Dashboard Screen** | `dashboard` | `DashboardScreen.kt` | Main financial hub; Hero balance card, quick actions, donut charts, recent activity. | `DashboardView.swift` |
| **Transactions Ledger** | `transactions` | `TransactionListScreen.kt` | Complete chronological transaction list; search filter, sorting, swipe-to-delete. | `TransactionsListView.swift` |
| **Add/Edit Transaction** | `add_transaction` | `AddEditTransactionSheet.kt` | Bottom sheet for fast expense/income entry; amount, category picker, cash/account toggle, date. | `AddEditTransactionSheet.swift` |
| **Transaction Details** | `transaction_detail` | `TransactionDetailDialog.kt` | Full receipt view with category icon, timestamp, notes, and delete/edit buttons. | `TransactionDetailSheet.swift` |
| **Split & Collect Landing**| `split_landing` | `SplitLandingScreen.kt` | Shared bills hub; net debt banner ("You are owed / You owe"), active bills, group tabs. | `SplitLandingView.swift` |
| **Create Split Bill** | `create_split` | `CreateSplitScreen.kt` | Multi-step bill splitting; payer selection, equal vs custom vs itemized, WhatsApp share toggle. | `CreateSplitView.swift` |
| **Split Bill Details** | `split_detail` | `SplitDetailScreen.kt` | Detailed bill breakdown, participant shares, settlement checkboxes, UPI QR code modal. | `SplitDetailView.swift` |
| **Edit Split Bill** | `edit_split` | `EditSplitScreen.kt` | Edit existing shared bill items, participants, and allocations. | `EditSplitView.swift` |
| **Split Groups Manager** | `split_groups` | `SplitGroupScreen.kt` | Create and manage split groups (e.g. "Flatmates", "Trip") with custom icons and colors. | `SplitGroupsView.swift` |
| **Planning Hub** | `planning` | `PlanningScreen.kt` | Host tab for monthly Budgets and Savings Goals sub-views. | `PlanningView.swift` |
| **Budgets View** | `budgets` | `BudgetListScreen.kt` | Monthly category expenditure limits with 4-tier threshold colored progress bars. | `BudgetsView.swift` |
| **Add/Edit Budget** | `add_budget` | `AddEditBudgetDialog.kt` | Modal to create or adjust category or overall monthly spending limits. | `AddEditBudgetSheet.swift` |
| **Savings Goals View** | `savings_goals` | `SavingsGoalListScreen.kt` | Savings milestone cards, progress bars, active vs archived goal sections. | `SavingsGoalsView.swift` |
| **Add/Edit Savings Goal** | `add_savings_goal` | `AddEditGoalDialog.kt` | Target amount, goal title, target date, icon, and color selector. | `AddEditGoalSheet.swift` |
| **Savings Goal Detail** | `savings_detail` | `SavingsGoalDetailScreen.kt` | Goal progress ring, remaining days, contribution history list, deposit button. | `SavingsGoalDetailView.swift` |
| **Add Goal Contribution** | `add_contribution` | `AddContributionDialog.kt` | Record deposit or withdrawal with optional link to general ledger transaction. | `AddContributionSheet.swift` |
| **Analytics & Insights** | `insights` | `AnalyticsScreen.kt` | Spending vs income bar charts, cashflow savings rate, top spending categories. | `InsightsView.swift` (SwiftUI Charts) |
| **Monthly Ledger & PDF** | `monthly_ledger` | `MonthlyLedgerScreen.kt` | Continuous monthly opening/closing statement with bank-grade PDF export button. | `MonthlyLedgerView.swift` |
| **In-App PDF Viewer** | `pdf_viewer` | `PdfViewerScreen.kt` | Full-screen interactive PDF statement preview with native system share sheet. | `PDFKitView.swift` (`PDFView`) |
| **Interactive Calendar** | `calendar` | `CalendarScreen.kt` | Monthly calendar grid with daily spend badges and selected date transaction list. | `CalendarView.swift` |
| **Recurring Rules** | `recurring` | `RecurringListScreen.kt` | Manage auto-generating recurring templates and subscriptions. | `RecurringListView.swift` |
| **Add/Edit Recurring** | `add_recurring` | `AddEditRecurringScreen.kt` | Recurrence frequency (daily/weekly/monthly/yearly), day selector, advance alert offset. | `AddEditRecurringView.swift` |
| **Financial Reminders** | `reminders` | `ReminderListScreen.kt` | Upcoming bill and EMI reminders, mark-as-paid actions, snooze button. | `RemindersListView.swift` |
| **Add/Edit Reminder** | `add_reminder` | `AddEditReminderScreen.kt` | Title, amount, due date, notification hour/minute, advance alert days. | `AddEditReminderSheet.swift` |
| **Financial Calculators**| `calculators` | `CalculatorScreen.kt` | Tool hub: EMI loan calculator, SIP wealth planner, FD/RD, GST, and Discount tools. | `CalculatorsHubView.swift` |
| **Settings & Preferences**| `settings` | `SettingsScreen.kt` | Grouped preference cards: Theme, Currency, Opening balance, Security, Backup, Language. | `SettingsView.swift` |
| **App Lock Vault** | `app_lock` | `AppLockScreen.kt` | Full-screen PIN security barrier with numeric keypad and biometric prompt. | `AppLockView.swift` |
| **PIN Setup & Reset** | `setup_pin` | `PinSetupScreen.kt` | 4-digit PIN creation and verification flow with 16-byte cryptographic salt. | `PinSetupView.swift` |
| **Category Customizer** | `categories` | `CategoryListScreen.kt` | Manage custom categories; live preview dialog with 22 icons and 12 colors. | `CategoriesManagerView.swift` |
| **Backup & Cloud Sync** | `backup_restore` | `BackupRestoreScreen.kt` | Local JSON export/import, CSV export, Google Drive sync management. | `BackupRestoreView.swift` |
| **Quick Add Window** | `quick_add` | `QuickAddTransactionActivity`| Floating transparent rapid-entry window launched from widgets or shortcuts. | `QuickAddModalView.swift` |

---

## 3. Top-Level Tab Hierarchy
Leaf organizes its primary features into **5 bottom navigation tabs**:
1. **Dashboard** (`Tab 0`): Glanceable balances, quick actions, recent activity.
2. **Transactions** (`Tab 1`): Searchable, filterable full ledger.
3. **Split** (`Tab 2`): Shared bills, net debts, groups.
4. **Planning** (`Tab 3`): Budgets and Savings Goals.
5. **Insights** (`Tab 4`): Charts, analytics, and monthly ledger statements.

Secondary features (Calendar, Calculators, Reminders, Recurring, Categories, Settings) are accessed via top bar icons or dashboard navigation cards.

