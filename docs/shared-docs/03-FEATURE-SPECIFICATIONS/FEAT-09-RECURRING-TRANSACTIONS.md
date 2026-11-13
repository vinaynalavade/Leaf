# FEATURE SPECIFICATION: FEAT-09 — RECURRING TRANSACTIONS & AUTO-GENERATION

## 1. Feature ID
`FEAT-09`

## 2. Feature Name
Recurring Schedules, Salary Inflows & Automated Due Transaction Generator

## 3. Purpose
Automates the lifecycle of recurring financial events such as salaries, monthly subscriptions, rent, insurance, and loan payments. Employs a deterministic due occurrence engine with month-end date pinning to automatically generate transactions on schedule without duplicate processing.

## 4. Current Implementation Status
**VERIFIED (IMPLEMENTED)** — Complete with separate Room entity, frequency models, automated background processor, and unit tests.

## 5. User-Facing Functionality
- **Recurring Transactions Screen (`RecurringTransactionsScreen`)**:
  - List of active and paused recurring templates with recurrence badge ("Monthly on day 1", "Weekly on Monday", "Daily", "Yearly").
  - Switch toggle to enable/disable templates instantly.
  - Category icon, title, payment source, and formatted amount.
  - "+ Add Recurring" action button.
- **Add / Edit Recurring Transaction Screen**:
  - Title (e.g. "Monthly Salary", "Netflix", "House Rent").
  - Amount, Type (Income vs Expense), Category, Payment Method (Cash vs Account).
  - Recurrence Frequency Selector: `DAILY`, `WEEKLY`, `MONTHLY`, `YEARLY`.
  - Day of Month Selector (1..31) for Monthly/Yearly.
  - Day of Week Selector (Monday..Sunday) for Weekly.
  - Start Date and optional End Date.
  - "Auto-Generate Transactions" toggle (automatically inserts into ledger when due).
  - "Reminder Days Before" advance notification setting (e.g. 1 day before).

## 6. Entry Points
- More options menu -> "Recurring Transactions" (`Screen.RecurringTransactions`).
- Screen route: `Screen.RecurringTransactions`.

## 7. Screen Structure
```text
RecurringTransactionsScreen
├── TopBar (Back Button, Title "Recurring Transactions", "+ Add" Action)
└── LazyColumn
    └── RecurringTransactionCard
        ├── Category Icon, Title, Frequency Pill ("Monthly on 1st")
        ├── Enable / Disable Switch Toggle
        └── Amount, Payment Source, Next Due Date
```

## 8. UI Components
- `RecurringTransactionCard`: Card displaying recurrence metadata and toggle.
- `FrequencySelector`: Segmented or dropdown selector for frequency options.
- `DayOfMonthPicker`: Interactive selector (1..31) with smart month-end label ("Clamps to 28/29/30 on shorter months").

## 9. User Interactions
- Tap toggle: Enables/disables recurring rule immediately in database.
- Tap card: Opens edit screen.
- Long-press / swipe: Triggers delete confirmation.
- Automatic background trigger: Generates transaction silently without user intervention.

## 10. Input Fields
| Field Name | Type | Validation / Constraints | Mandatory |
| :--- | :--- | :--- | :--- |
| **Title** | String | Non-blank, max 60 chars | Yes |
| **Amount** | Subunits | $> 0$, integer subunits $\le 10^{14}$ | Yes |
| **Type** | Enum (`TransactionType`) | `EXPENSE` or `INCOME` | Yes |
| **Category** | Long (`categoryId`) | Valid category ID | Yes |
| **Payment Method** | Enum (`PaymentMethod`) | `CASH` or `ACCOUNT` | Yes |
| **Frequency** | Enum (`RecurrenceFrequency`)| `DAILY`, `WEEKLY`, `MONTHLY`, `YEARLY`| Yes |
| **Day of Month** | Integer | 1 .. 31 (clamped on shorter months) | For Monthly/Yearly |
| **Day of Week** | Integer | 1 .. 7 (Monday = 1) | For Weekly |
| **Start Date** | Long (Epoch) | Valid date | Yes |
| **End Date** | Long? (Epoch) | Must be $\ge$ Start Date if set | No |
| **Auto-Generate** | Boolean | Default: true | Yes |

## 11. Validation Rules
- Cannot create schedule with end date prior to start date.
- Amount must be strictly greater than 0.

## 12. Business Rules
- **Month-End Date Pinning (`DateTimeUtils.getScheduledDayOfMonth`):**
  If a recurring transaction is scheduled for day 31, in a 30-day month (April, June, September, November) it must trigger on the 30th. In February, it must trigger on the 28th (or 29th on leap years). When the next 31-day month arrives, it must automatically revert to day 31 without losing its configured day.
- **Duplicate-Proof Generation:**
  The engine updates `lastGeneratedDate` to the current timestamp upon generating a transaction. A transaction is only generated if no occurrence was already created for the active cycle:
  - Daily: `today > lastGeneratedDate`.
  - Weekly: Occurrence generated once within the active Monday-Sunday week.
  - Monthly: `currentYearMonth > YearMonth.from(lastGeneratedDate)`.
  - Yearly: `today.year > lastGeneratedDate.year`.
- **End Date Boundary:** If `endDate != null` and `today > endDate`, the recurrence is retired and triggers no further generations.

## 13. Calculation Logic
- Evaluated inside `RecurringTransactionRepositoryImpl#checkIfDue(recurring, today)`.
- Clamped day calculation:
  $$\text{effectiveDay} = \min(\text{configuredDay}, \text{targetMonth.lengthOfMonth}())$$

## 14. Database Interactions
- Table: `recurring_transactions`.
- On generation: Inserts new record into `transactions` table, then updates `lastGeneratedDate` in `recurring_transactions`.

## 15. State Management
- `RecurringViewModel`: Exposes `uiState: StateFlow<List<RecurringTransaction>>`.
- Background worker / receiver invokes `ProcessDueRecurringTransactionsUseCase`.

## 16. Navigation
- Pushed from navigation menu; tapping item navigates to Edit screen.

## 17. Error Handling
- Exceptions during generation are caught and logged, allowing other recurring items to proceed uninterrupted.

## 18. Empty States
- When no recurring items exist: "No recurring transactions set up. Automate your monthly salary, rent, and subscriptions."

## 19. Loading States
- Renders placeholder rows during initial database query.

## 20. Edge Cases
- App opened after 3 months of device inactivity: Engine generates the pending occurrence for the current cycle and updates `lastGeneratedDate` (does not flood the user with 90 historical daily transactions).
- Leap year: Correctly clamps February 29th occurrences to 28th on non-leap years and 29th on leap years.

## 21. Dependencies
- `RecurringTransactionRepository`
- `TransactionRepository`
- `ProcessDueRecurringTransactionsUseCase`

## 22. Relevant Android Source Files
- `app/src/main/java/com/vinaynalavade/expensetracker/data/repository/RecurringTransactionRepositoryImpl.kt`
- `app/src/main/java/com/vinaynalavade/expensetracker/domain/usecase/ProcessDueRecurringTransactionsUseCase.kt`
- `app/src/main/java/com/vinaynalavade/expensetracker/presentation/recurring/RecurringTransactionsScreen.kt`

## 23. Relevant Tests
- `app/src/test/java/com/vinaynalavade/expensetracker/RecurringEmiDayOfMonthTest.kt`

## 24. iOS Implementation Expectations
- Implement as `RecurringTransactionsView.swift`.
- Background processing handled via `BGAppRefreshTask` registered with `BGTaskScheduler`.
- App launch / foreground trigger (`scenePhase == .active`) checks for due occurrences immediately.

## 25. Acceptance Criteria
1. Recurring monthly items scheduled on day 31 trigger on day 28/29 in February without changing the rule.
2. Auto-generation creates exactly one transaction per cycle with title, amount, category, and source.
3. Disabling a recurring rule stops all future automated transaction generations.

