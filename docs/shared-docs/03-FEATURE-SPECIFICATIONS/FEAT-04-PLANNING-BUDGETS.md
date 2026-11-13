# FEATURE SPECIFICATION: FEAT-04 — MONTHLY BUDGETS & THRESHOLD TRACKING

## 1. Feature ID
`FEAT-04`

## 2. Feature Name
Monthly Budget Planning, Category Budgets & Warning Thresholds

## 3. Purpose
Enables users to establish monthly spending limits either globally (Overall Budget) or per individual expense category. Provides real-time month-to-date tracking with dynamic visual progress indicators, percentage calculations, remaining allowance metrics, and tiered warning alerts.

## 4. Current Implementation Status
**VERIFIED (IMPLEMENTED)** — Complete with reactive database queries, category relation models, and automated tests.

## 5. User-Facing Functionality
- **Overall Monthly Budget**: Set a total spending ceiling for any calendar month.
- **Category-Specific Budgets**: Set dedicated spending limits on individual categories (e.g., Dining ₹8,000, Shopping ₹5,000).
- **Month Selector**: Previous (`<`) and Next (`>`) month navigation with year-month display.
- **Live Progress Bars**: Visual progress bar indicating percentage of budget consumed.
- **Dynamic Status Pills**:
  - `ON_TRACK` (< 75%): Emerald Green pill.
  - `APPROACHING_LIMIT` (75% to < 100%): Amber Warning pill with alert icon.
  - `LIMIT_REACHED` (100%): Amber Alert pill.
  - `OVER_BUDGET` (> 100%): Rose Red Danger pill showing exact amount exceeded.
- **Remaining Allowance**: Real-time display of unspent allowance (clamped to ₹0.00 if over budget).
- **Dashboard Notification Banner**: High-priority alert banner on the main dashboard whenever an active budget exceeds 75% or 100%.

## 6. Entry Points
- Bottom navigation item "Planning" (`Screen.Planning`), "Budgets" tab.
- Dashboard warning banner click ("Approaching monthly budget limit").
- In-app notification click when a budget threshold is crossed.

## 7. Screen Structure
```text
PlanningScreen -> Budgets Tab
├── MonthNavigatorHeader ("< October 2026 >")
├── OverallBudgetHeroCard
│   ├── Title "Overall Budget", Total Limit, Edit/Delete Menu
│   ├── Horizontal LinearProgressIndicator (Color transitions: Green -> Amber -> Red)
│   └── Spent Amount vs Remaining Amount Row
├── CategoryBudgetsHeader ("Category Budgets", "+ Add Budget" Button)
└── CategoryBudgetsLazyColumn
    └── CategoryBudgetCard
        ├── Category Icon, Category Name, Status Badge
        ├── LinearProgressIndicator
        └── Spent Amount vs Budgeted Amount
```

## 8. UI Components
- `BudgetCard`: Elevated surface card with rounded corners (20dp).
- `LinearProgressIndicator`: Animated progress bar with color interpolation based on status.
- `AddEditBudgetDialog`: Modal dialog to select category (or "Overall Budget"), enter amount, and save.
- `MonthNavigator`: Month switching bar.

## 9. User Interactions
- Tap "+ Add Budget": Opens `AddEditBudgetDialog`.
- Select Category: Dropdown or dialog list (choosing "Overall Budget" sets `categoryId = null`).
- Enter Amount: Numeric keypad with live formatting.
- Tap Save: Inserts or updates budget for selected month/year.
- Tap Budget Card: Opens edit dialog.
- Long-press or menu tap: Prompts to delete budget with confirmation.

## 10. Input Fields
| Field Name | Type | Validation / Constraints | Mandatory |
| :--- | :--- | :--- | :--- |
| **Category** | Long? (`categoryId`) | Null for Overall, valid ID for Category budget | No (Null = Overall) |
| **Amount** | Decimal / Subunits | $> 0$, integer subunits $\le 10^{14}$ | Yes |
| **Month** | Integer | 1 .. 12 | Yes |
| **Year** | Integer | Valid 4-digit year (e.g. 2026) | Yes |

## 11. Validation Rules
- Cannot save budget with amount $\le 0$.
- One budget per category per month/year (updating replaces existing limit).
- Overall budget is unique per month/year.

## 12. Business Rules
- Expenses recorded in the given month count against the budget.
- Savings goal contributions logged under "Savings & Goals" are ordinary expense transactions and count against the overall budget unless filtered.
- Income transactions do not offset the budget (budget tracks gross spending, not net savings).
- Thresholds:
  - $\text{Percentage} < 75\% \implies \text{ON\_TRACK}$
  - $75\% \le \text{Percentage} < 100\% \implies \text{APPROACHING\_LIMIT}$
  - $\text{Percentage} == 100\% \implies \text{LIMIT\_REACHED}$
  - $\text{Percentage} > 100\% \implies \text{OVER\_BUDGET}$

## 13. Calculation Logic
$$\text{Used Subunits} = \sum_{\text{tx} \in \text{MonthExpenses}} \text{tx.amount.subunits} \quad (\text{filtered by category if not Overall})$$
$$\text{Remaining Subunits} = \max(0L, \text{Budget Subunits} - \text{Used Subunits})$$
$$\text{Percentage Used} = \left(\frac{\text{Used Subunits}}{\text{Budget Subunits}}\right) \times 100\%$$
Threshold 75% calculated safely using integer arithmetic:
$$\text{threshold75} = (\text{Budget Subunits} \times 75L) / 100L$$

## 14. Database Interactions
- Table: `budgets`.
- `BudgetDao.getBudgetsForMonth(year, month)`: Flow combining `BudgetEntity` with optional `CategoryEntity`.
- `BudgetDao.insertBudget(entity)`.
- `BudgetDao.deleteBudgetById(id)`.

## 15. State Management
- `PlanningViewModel`: Exposes `budgetsState: StateFlow<List<BudgetProgress>>` reactive to transaction additions/deletions.

## 16. Navigation
- Planning tab accessible from bottom bar.
- Edit/Add dialogs presented inline.

## 17. Error Handling
- Database constraint violations handled cleanly without crashes.
- Input validation prevents submitting non-numeric or negative values.

## 18. Empty States
- When no budgets are configured for the month: Displays "No budgets set for [Month]. Tap + Add Budget to take control of your spending."

## 19. Loading States
- Month transitions animate smoothly with shimmer/fade transitions.

## 20. Edge Cases
- Spending exceeds budget by large margin (e.g. 300%): Progress bar fills to 100% without graphical overflow; text displays "Over by ₹X,XXX".
- Zero budget amount: Handled safely, percentage defaults to 0% to avoid division by zero.

## 21. Dependencies
- `BudgetRepository`
- `TransactionRepository`
- `GetBudgetProgressUseCase`

## 22. Relevant Android Source Files
- `app/src/main/java/com/vinaynalavade\expensetracker/domain/usecase/GetBudgetProgressUseCase.kt`
- `app/src/main/java/com/vinaynalavade/expensetracker/presentation/planning/PlanningScreen.kt`
- `app/src/main/java/com/vinaynalavade/expensetracker/presentation/planning/PlanningViewModel.kt`
- `app/src/main/java/com/vinaynalavade/expensetracker/data/local/dao/BudgetDao.kt`

## 23. Relevant Tests
- `app/src/test/java/com/vinaynalavade/expensetracker/BudgetCalculationTest.kt`

## 24. iOS Implementation Expectations
- Implement as `BudgetProgressCardView.swift` within `PlanningView.swift`.
- Use SwiftUI `ProgressView(value: percentage, total: 100)` with custom `.progressViewStyle`.
- Implement month picker with `HStack` and SF Symbols `chevron.left` / `chevron.right`.

## 25. Acceptance Criteria
1. When spending crosses 75% of limit, status updates to `APPROACHING_LIMIT` and color shifts to amber.
2. When spending exceeds 100%, status changes to `OVER_BUDGET` in red and remaining balance displays 0.
3. Adding a new transaction immediately updates the corresponding category and overall budget progress bars.

