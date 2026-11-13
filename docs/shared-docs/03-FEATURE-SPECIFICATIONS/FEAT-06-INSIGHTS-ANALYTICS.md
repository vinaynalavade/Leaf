# FEATURE SPECIFICATION: FEAT-06 — INSIGHTS, ANALYTICS & MONTHLY LEDGER

## 1. Feature ID
`FEAT-06`

## 2. Feature Name
Insights, Spending Trends, Category Analytics & Monthly Continuity Ledger

## 3. Purpose
Comprehensive financial analytics suite providing users with clear visualizations of their spending distribution, income vs. expense ratios, category percentages, weekly and monthly spending trends, daily average expenditure, and continuous month-over-month ledger continuity with opening balance carry-forward.

## 4. Current Implementation Status
**VERIFIED (IMPLEMENTED)** — Complete with pure domain use cases, category analysis calculations, and automated tests.

## 5. User-Facing Functionality
- **Insights Screen (`InsightsScreen`)**:
  - Period Filter: "This Month", "Last Month", "Last 3 Months", "This Year".
  - Total Spend & Total Income Summary Cards.
  - Category Breakdown Donut / Progress Distribution: Ranked list of categories sorted by descending total spend with percentage badges and transaction counts.
  - Weekly / Monthly Spending Trends: Trend lines illustrating expenditure trajectories over time.
  - Payment Method Distribution: Ratio of Cash vs. Account spending.
- **Monthly Summary & Continuity Ledger Screen (`MonthlySummaryScreen`)**:
  - Month Selector (`< Month Year >`).
  - **Financial Continuity Summary**:
    - **Opening Balance**: Dynamically carries forward baseline balance plus all historical income minus all historical expenses prior to the 1st of the selected month.
    - **Total Income**: Sum of all income recorded within the month.
    - **Ordinary Expenses**: Sum of standard living expenses (excluding internal savings allocations).
    - **Savings Allocations**: Total funds directed into "Savings & Goals" during the month.
    - **Net Savings / Change**: Income minus Expenses.
    - **Closing Balance**: Opening Balance plus Net Change.
  - **Daily Average Spend**: Ordinary expenses divided by elapsed days in the month (e.g. current day of month for the active month, full month length for past months).
  - **Month-over-Month (MoM) Growth Comparison**: Percentage change in ordinary expenses compared to the preceding calendar month.

## 6. Entry Points
- Bottom navigation tab "Insights" (`Screen.Insights`).
- Dashboard monthly summary card tap.
- More options menu -> "Monthly Ledger".

## 7. Screen Structure
```text
InsightsScreen
├── PeriodSelectorChips ("This Month", "Last Month", "Last 3 Months", "Year")
├── FinancialOverviewCard (Total Income, Total Expense, Net Change)
├── CategoryAnalysisSection
│   ├── Section Title "Category Breakdown"
│   └── CategorySpendingRowItems (Ranked 1..N, Color pill, %, Amount, Tx count)
└── TrendsSection
    ├── Section Title "Spending Trends"
    └── TrendVisualizationCard (Daily / Weekly bars or line trajectory)
```

## 8. UI Components
- `PeriodSelector`: Horizontal scrollable filter chips.
- `CategoryBreakdownRow`: Visual bar with category icon, name, percentage pill, and formatted total.
- `MonthlyLedgerCard`: Comprehensive breakdown card detailing Opening Balance -> Income -> Expenses -> Savings -> Closing Balance.
- `DailyAverageStatPill`: Tonal card displaying daily average burn rate.
- `MoMGrowthIndicator`: Badge indicating percentage increase or decrease vs previous month.

## 9. User Interactions
- Tap period chip: Filters all analytics to selected timeframe.
- Tap category item: Drills down into all transactions for that specific category in the selected timeframe.
- Tap month selector arrows: Advances or steps back the monthly ledger calculation.

## 10. Input Fields
None (analytic visualization screen).

## 11. Validation Rules
- Daily average calculation: If days count is 0, denominator defaults to 1 to avoid division by zero.
- Category percentage calculation: If total expenses equal 0, category percentage is 0.0%.

## 12. Business Rules
- **Continuous Opening Balance Carry-Forward:**
  $$\text{Past Income} = \sum_{t < \text{startOfMonth}} \text{Income}(t)$$
  $$\text{Past Expense} = \sum_{t < \text{startOfMonth}} \text{Expense}(t)$$
  $$\text{Opening Balance}(\text{Month}) = \text{Base Opening Balance} + \text{Past Income} - \text{Past Expense}$$
  $$\text{Closing Balance}(\text{Month}) = \text{Opening Balance}(\text{Month}) + \text{Month Income} - \text{Month Expense}$$
- **Ordinary Expenses vs Savings Allocations:**
  Transactions under the category `"Savings & Goals"` are classified as `Savings Allocations` rather than ordinary burn, enabling users to evaluate true operational living expenses.
- **Daily Average Spending:**
  For the current active month, elapsed days $= \max(1, \text{today.dayOfMonth})$.
  For past months, elapsed days $= \text{month.lengthOfMonth}()$.
- **MoM Expense Growth Rate:**
  $$\text{MoM Growth \%} = \left(\frac{\text{Current Month Ordinary Expense} - \text{Previous Month Ordinary Expense}}{\text{Previous Month Ordinary Expense}}\right) \times 100\%$$
  (If previous month expense is 0, MoM is reported as null / not applicable).

## 13. Calculation Logic
- All aggregation operates on 64-bit integer subunits before single-pass division for percentages.
- Percentages rounded to 1 decimal place (`String.format("%.1f%%", pct)`).

## 14. Database Interactions
- `TransactionDao.getTransactions()`: Full ledger flow.
- `TransactionDao.getTransactionsBetween(startEpoch, endEpoch)`.

## 15. State Management
- `InsightsViewModel`: Exposes `InsightsUiState` with category analysis and trends.
- `MonthlySummaryViewModel`: Exposes `MonthlySummaryUiState` reactive to month selections.

## 16. Navigation
- Accessible via bottom bar.
- Selecting a category navigates to `Screen.Transactions` with pre-applied category filter.

## 17. Error Handling
- Empty transaction ledgers render calm empty-state graphics without arithmetic crashes.

## 18. Empty States
- When no expenses exist in the period: "No expenses recorded in this period. Your spending breakdown will appear here."

## 19. Loading States
- Renders shimmer placeholders while processing heavy historical aggregations.

## 20. Edge Cases
- All expenses in a single category: Percentage displays 100.0%.
- Negative net savings (expenses exceed income): Net Change rendered in `ExpenseRoseDark` with minus sign.

## 21. Dependencies
- `TransactionRepository`
- `CategoryRepository`
- `UserPreferencesRepository`
- `GetCategoryAnalysisUseCase`
- `GetMonthlyLedgerUseCase`
- `GetSpendingTrendsUseCase`

## 22. Relevant Android Source Files
- `app/src/main/java/com/vinaynalavade/expensetracker/domain/usecase/GetMonthlyLedgerUseCase.kt`
- `app/src/main/java/com/vinaynalavade/expensetracker/domain/usecase/GetCategoryAnalysisUseCase.kt`
- `app/src/main/java/com/vinaynalavade/expensetracker/domain/usecase/GetSpendingTrendsUseCase.kt`
- `app/src/main/java/com/vinaynalavade/expensetracker/presentation/insights/InsightsScreen.kt`
- `app/src/main/java/com/vinaynalavade/expensetracker/presentation/summary/MonthlySummaryScreen.kt`

## 23. Relevant Tests
- `app/src/test/java/com/vinaynalavade/expensetracker/FinancialCalculationTest.kt`
- `app/src/test/java/com/vinaynalavade/expensetracker/DashboardCategoryAnalysisTest.kt`
- `app/src/test/java/com/vinaynalavade/expensetracker/SpendingTrendsTest.kt`

## 24. iOS Implementation Expectations
- Implement using **Swift Charts** (`import Charts`):
  - `SectorMark` for Category Breakdown Donut chart.
  - `BarMark` and `LineMark` for Spending Trends.
- Implement `MonthlyLedgerView.swift` with SwiftUI expandable disclosure groups or list sections.

## 25. Acceptance Criteria
1. Opening balance carry-forward exactly matches the historical sum of previous months' net balances.
2. Category percentages sum to 100% (within 0.1% rounding tolerance).
3. Daily average spend uses the exact elapsed days count for the current month.
4. MoM comparison reflects the true percentage difference in ordinary living expenses.

