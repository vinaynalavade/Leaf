# FEATURE SPECIFICATION: FEAT-01 — DASHBOARD & BALANCE OVERVIEW

## 1. Feature ID
`FEAT-01`

## 2. Feature Name
Dashboard, Balance Overview & Financial Summary

## 3. Purpose
The Dashboard serves as the command center of Leaf. It provides immediate, glanceable financial clarity by presenting the user's total net balance, income, expenses, upcoming payment obligations, active budget progress, quick actions, and recent transaction history.

## 4. Current Implementation Status
**VERIFIED (IMPLEMENTED)** — Fully functional in production Android app with unit test coverage.

## 5. User-Facing Functionality
- Prominent **Current Balance Card** with luxury Emerald gradient background.
- **Privacy Eye Toggle** to mask/unmask balance (`₹••••••` or exact figure) persistently.
- **Monthly Summary Cards**: Total Income (Emerald green pill with up arrow) and Total Expenses (Rose red pill with down arrow) for the current month.
- **Quick Action Bar**: One-tap direct access to "Add Expense", "Add Income", and "Split Bill".
- **Upcoming Obligations Alert**: Dynamic notification banner displaying any bill/EMI obligations due within 7 days.
- **Budget Warning Banner**: Displays alert if overall monthly spending exceeds 75% or 100% of defined budget.
- **Recent Activity Ledger**: Displays up to 10 most recent transactions with categorized squircle icons, dates ("Today", "Yesterday", or date), payment source pill (Cash / Account), and amounts.
- **Easter Egg Banners**: Midnight greeting ("Still keeping an eye on your money?") between 11 PM and 4 AM, and Zero Mode badge if spending is ₹0.00.

## 6. Entry Points
- Primary landing screen when opening the application (default tab in bottom navigation bar: `Screen.Dashboard`).
- Home-screen shortcut "Overview".
- App launch from home-screen widgets.

## 7. Screen Structure
```text
DashboardScreen
├── TopBar (Profile Avatar / Name, Currency symbol, Notifications Icon, Easter Egg trigger)
├── Pull-to-Refresh Container
│   └── LazyColumn (Vertical Scroll)
│       ├── Active Banners (Budget Warning, Upcoming Payments, Midnight Leaf)
│       ├── Balance Hero Card (Current Balance, Mask Toggle, Cash vs Account breakdown)
│       ├── Monthly Summary Row (Total Income Card, Total Expense Card)
│       ├── Quick Action Buttons Row (Add Expense, Add Income, Split Bill)
│       ├── Active Budgets & Goals Glance (Optional compact progress bars)
│       └── Recent Activity Header ("Recent Transactions" -> "View All" link)
│           └── Transaction List Items (up to 10 items)
└── BottomBar (Persistent 5-destination navigation bar with center action FAB)
```

## 8. UI Components
- `DashboardScreen`: Main container.
- `BalanceHeroCard`: Gradient surface with 28dp corner radius (`HeroEmeraldGradient` in light, `HeroObsidianGradient` in dark).
- `BalanceAmountDisplay`: Formatted currency string with masked state support.
- `StatPill`: Compact colored background pill displaying income or expense totals with directional indicators.
- `QuickActionButton`: Circular squircle icon button with label.
- `TransactionItem`: Standard row item displaying category squircle, title/note, source tag, timestamp, and colored amount.

## 9. User Interactions
- Tap eye icon: Toggles `isBalanceVisible` in DataStore preferences and updates widgets instantly.
- Tap "Add Expense": Navigates to `Screen.AddExpense`.
- Tap "Add Income": Navigates to `Screen.AddIncome`.
- Tap "Split Bill": Navigates to `Screen.Split`.
- Tap "View All" / Recent Transaction Item: Navigates to `Screen.Transactions` (or `Screen.TransactionDetail`).
- Tap profile avatar: Navigates to `Screen.Settings`.
- Pull down: Triggers refresh of transactions and cloud sync status.

## 10. Input Fields
None on Dashboard (view-only command center).

## 11. Validation Rules
- Current balance computation must never fail on empty database; defaults to `openingBalance` (or ₹0.00).
- Negative balances must be rendered with an explicit minus prefix (e.g. `-₹1,250.00`) in `ExpenseRoseDark`.

## 12. Business Rules
- Balance calculation includes starting balance:
  $$\text{Current Balance} = \text{Opening Balance} + \sum \text{Income Subunits} - \sum \text{Expense Subunits}$$
- Date filtering for monthly income/expense cards spans from the first second of the 1st day of the current calendar month to the final millisecond of the last day of the current month.
- Privacy mode masks all primary balance numbers on the dashboard and widget displays.

## 13. Calculation Logic
- Subunits: `Long` integer arithmetic.
- Income/Expense aggregation: Iterates through transactions in current month interval `startOfMonthEpoch..endOfMonthEpoch`.

## 14. Database Interactions
- `TransactionDao.getAllTransactionsWithCategory()`: Live reactive flow.
- `TransactionDao.getRecentTransactionsWithCategory(limit = 10)`.
- `BudgetDao.getBudgetsForMonth(year, month)`.
- `ReminderDao.getActiveReminders()`.

## 15. State Management
- `DashboardViewModel`: Exposes `uiState: StateFlow<DashboardUiState>`.
- Reactive combine of `TransactionRepository`, `UserPreferencesRepository`, `BudgetRepository`, `ReminderRepository`.

## 16. Navigation
- Outgoing destinations:
  - `Screen.AddExpense`
  - `Screen.AddIncome`
  - `Screen.Split`
  - `Screen.Transactions`
  - `Screen.TransactionDetail/{id}`
  - `Screen.Settings`
  - `Screen.Planning`

## 17. Error Handling
- Database read failures emit `DashboardUiState.Error(message)` with retry prompt.
- Coroutine exceptions are logged without crashing the activity.

## 18. Empty States
- When 0 transactions exist: Displays calm illustration "No transactions yet. Tap + below to add your first expense or income."

## 19. Loading States
- Initial load displays shimmering skeleton cards for Hero Balance and Recent Activity.

## 20. Edge Cases
- First app launch: Opening balance is ₹0, no transactions. Balance displays `₹0.00`.
- Large numbers: Balances up to ₹99,99,99,999.99 fit gracefully using auto-scaling typography.
- Negative net balance: Displays cleanly with minus sign and negative financial styling.

## 21. Dependencies
- `GetFinancialSummaryUseCase`
- `GetCategoryAnalysisUseCase`
- `GetBudgetProgressUseCase`
- `GetUpcomingPaymentsUseCase`
- `UserPreferencesRepository`

## 22. Relevant Android Source Files
- `app/src/main/java/com/vinaynalavade/expensetracker/presentation/dashboard/DashboardScreen.kt`
- `app/src/main/java/com/vinaynalavade/expensetracker/presentation/dashboard/DashboardViewModel.kt`
- `app/src/main/java/com/vinaynalavade/expensetracker/domain/usecase/GetFinancialSummaryUseCase.kt`

## 23. Relevant Tests
- `app/src/test/java/com/vinaynalavade/expensetracker/FinancialCalculationTest.kt`
- `app/src/test/java/com/vinaynalavade/expensetracker/DashboardCategoryAnalysisTest.kt`

## 24. iOS Implementation Expectations
- Implement as `DashboardView.swift` in SwiftUI using `ScrollView` and `LazyVStack`.
- Card gradients rendered with native SwiftUI `LinearGradient`.
- Privacy toggle integrated with `UserDefaults` / `@AppStorage` and synchronized with WidgetKit through `WidgetCenter.shared.reloadAllTimelines()`.
- Haptic feedback on tap using `UIImpactFeedbackGenerator(style: .light)`.

## 25. Acceptance Criteria
1. Opening balance plus net income/expense changes equals displayed balance to the exact paisa/cent.
2. Toggling the privacy eye hides/shows the balance instantly with smooth animation.
3. Recent transactions list updates in real time whenever a transaction is added or deleted.
4. Quick actions navigate directly to the correct destination with smooth transition.

