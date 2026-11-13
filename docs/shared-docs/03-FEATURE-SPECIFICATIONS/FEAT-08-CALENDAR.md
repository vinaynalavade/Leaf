# FEATURE SPECIFICATION: FEAT-08 — FINANCIAL CALENDAR

## 1. Feature ID
`FEAT-08`

## 2. Feature Name
Interactive Daily Financial Calendar & Daily Ledger Drill-Down

## 3. Purpose
Visualizes income and expenditure distribution on a monthly calendar grid. Enables users to instantly identify high-spend days, view daily totals directly on date cells, and drill down into the complete transaction ledger for any selected day.

## 4. Current Implementation Status
**VERIFIED (IMPLEMENTED)** — Complete with custom calendar grid, date-range database queries, and daily transaction list.

## 5. User-Facing Functionality
- **Month Navigation**: Header with previous and next month chevrons and Month-Year title.
- **7-Column Calendar Grid**: Monday through Sunday week layout with proper month offset padding.
- **Daily Cell Indicators**:
  - Date number.
  - Expense badge: Small Rose red badge with formatted daily expense sum.
  - Income badge: Small Emerald green badge with formatted daily income sum.
  - Selected day highlight with circular emerald outline.
  - "Today" indicator highlight.
- **Selected Day Financial Summary**:
  - Date banner (e.g. "Wednesday, 28 October 2026").
  - Day's Total Income and Day's Total Expense pills.
- **Daily Transaction List**:
  - List of all transactions recorded on the selected date.
  - Tapping a transaction navigates to `TransactionDetailScreen`.
  - "+ Add for this Date" quick button pre-populating the selected date in the transaction creator.

## 6. Entry Points
- More options / Navigation menu -> "Calendar" (`Screen.Calendar`).
- Insights action button.

## 7. Screen Structure
```text
CalendarScreen
├── TopBar (Back Button, Title "Financial Calendar")
├── MonthNavigator ("< October 2026 >")
├── DayOfWeekHeader (Mon, Tue, Wed, Thu, Fri, Sat, Sun)
├── CalendarGrid (LazyVerticalGrid with 7 columns)
│   └── CalendarDayCell (Day number, Income badge, Expense badge, Selected state)
├── Divider
└── DailyTransactionsSection (Scrollable Column)
    ├── SelectedDateHeader ("28 Oct 2026", Daily Income pill, Daily Expense pill)
    └── DailyTransactionItems (Categorized rows or "No transactions on this day")
```

## 8. UI Components
- `CalendarScreen`: Root container.
- `CalendarGrid`: 7-column grid layout.
- `CalendarDayCell`: Individual date cell with badge rendering logic.
- `DailyTransactionList`: Bottom sheet or scrollable section below calendar.

## 9. User Interactions
- Tap date cell: Selects date and loads transactions for that day below the grid.
- Tap next/previous chevron: Navigates month and refreshes cell indicators.
- Tap transaction item: Opens transaction details.

## 10. Input Fields
None (selection-driven interaction).

## 11. Validation Rules
- Handles leap years (February 29) accurately using `java.time.Year.isLeap()`.
- Calendar grid pads leading and trailing days belonging to adjacent months.

## 12. Business Rules
- A transaction falls on day $D$ if its epoch timestamp is within the range:
  $$\text{startOfDay}(D) \le \text{timestamp} \le \text{endOfDay}(D)$$
  evaluated using the device's local `ZoneId`.
- Days with both income and expense display dual badges.

## 13. Calculation Logic
- Day grouping: Transactions fetched for the full month in a single query `getTransactionsBetween(startOfMonth, endOfMonth)` and grouped in memory by `LocalDate`.

## 14. Database Interactions
- `TransactionDao.getTransactionsBetween(startOfMonthEpoch, endOfMonthEpoch)`.

## 15. State Management
- `CalendarViewModel`: Manages `selectedYearMonth`, `selectedDate`, `monthTransactions`, `dailySummaryMap`.

## 16. Navigation
- Pushed from navigation menu; tapping a transaction navigates to `Screen.TransactionDetail/{id}`.

## 17. Error Handling
- Timezone changes and daylight saving shifts handled cleanly via modern date-time libraries.

## 18. Empty States
- On a selected date with 0 transactions: "No transactions recorded on this day. Tap + to add an expense or income."

## 19. Loading States
- Renders grid structure immediately; badges populate smoothly once transaction query emits.

## 20. Edge Cases
- Month beginning on Sunday / Monday: Grid correctly offsets first day of month.
- Multiple transactions on same day: Aggregated cleanly into single income and expense totals.

## 21. Dependencies
- `TransactionRepository`
- `DateTimeUtils`

## 22. Relevant Android Source Files
- `app/src/main/java/com/vinaynalavade/expensetracker/presentation/calendar/CalendarScreen.kt`
- `app/src/main/java/com/vinaynalavade/expensetracker/presentation/calendar/CalendarViewModel.kt`
- `app/src/main/java/com/vinaynalavade/expensetracker/core/utils/DateTimeUtils.kt`

## 23. Relevant Tests
- `app/src/test/java/com/vinaynalavade/expensetracker/FinancialCalculationTest.kt`

## 24. iOS Implementation Expectations
- Implement as `CalendarView.swift` using SwiftUI `LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7))`.
- Use Apple's `Calendar.current` and `DateComponents` for localized first-day-of-week handling (Sunday vs Monday according to user locale).

## 25. Acceptance Criteria
1. Daily expense badges match the sum of transactions for that day.
2. Selecting a date updates the daily transaction list below the grid.
3. Month switching correctly calculates days in month (28, 29, 30, 31).

