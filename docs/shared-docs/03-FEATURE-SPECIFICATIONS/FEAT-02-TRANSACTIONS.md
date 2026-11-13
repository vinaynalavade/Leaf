# FEATURE SPECIFICATION: FEAT-02 — TRANSACTIONS & ENTRY

## 1. Feature ID
`FEAT-02`

## 2. Feature Name
Transaction Capture, Ledger, Filtering, Search & Quick Add

## 3. Purpose
Core financial record-keeping engine allowing users to record, categorize, view, edit, search, filter, and delete income and expense transactions with immediate input formatting, date/time precision, and persistent payment method tracking (Cash vs. Account).

## 4. Current Implementation Status
**VERIFIED (IMPLEMENTED)** — Complete with comprehensive unit tests and dedicated modal activity.

## 5. User-Facing Functionality
- **Transaction Entry Screen (`AddTransactionScreen`)**:
  - Prominent amount entry with automatic thousand-separator comma formatting.
  - Type switch between Expense (Rose red accent) and Income (Emerald green accent).
  - Categorized grid chips with custom icons and curated colors.
  - Financial Source Selector: Cash vs. Account.
  - Precision Date & Time Picker (Material 3 date picker dialog + 12/24-hour time picker).
  - Optional free-text note with in-field expression calculation.
- **Transactions Ledger Screen (`TransactionsScreen`)**:
  - Live search bar searching notes and category names.
  - Filter chips for Type (`ALL`, `EXPENSE`, `INCOME`) and Payment Method (`ALL`, `CASH`, `ACCOUNT`).
  - Date-grouped sticky headers ("Today", "Yesterday", "24 Oct 2026").
  - Transaction Row Item: Category icon, category name, note snippet, payment source badge, formatted amount.
- **Transaction Detail Screen (`TransactionDetailScreen`)**:
  - Full details view: Amount, Category, Type, Date, Time, Source, Note, and Created/Updated audit timestamps.
  - "Edit" action navigating to `Screen.EditTransaction`.
  - "Delete" action with confirmation dialog.
- **Quick Add Overlay (`QuickAddTransactionActivity` & `QuickAddBottomSheet`)**:
  - Translucent modal overlay with immediate numeric keyboard focus and pinned bottom action button that never occludes behind the IME.

## 6. Entry Points
- Bottom navigation item "Transactions" (`Screen.Transactions`).
- Dashboard Quick Action "+ Expense" (`Screen.AddExpense`).
- Dashboard Quick Action "+ Income" (`Screen.AddIncome`).
- Home-screen dynamic launcher shortcuts ("Add Expense", "Add Income").
- Home-screen Quick Add Widget (`QuickAddWidgetProvider`).
- In-app Floating Action Button (FAB).

## 7. Screen Structure
```text
AddTransactionScreen / EditTransactionScreen
├── TopAppBar (Title "Add Expense" / "Edit Transaction", Close button, Save Checkmark)
└── Column (Scrollable Form)
    ├── Type Segmented Bar (Expense vs Income)
    ├── Large Amount Input Field (Currency symbol + Live formatted text)
    ├── Category Selection Section (Label "CATEGORY", FlowRow of Category Chips, "+ Add Category")
    ├── Financial Source Selector (Segmented buttons: Cash vs Account)
    ├── Date & Time Pickers (Date button -> DatePickerDialog, Time button -> TimePickerDialog)
    └── Note Input Field (OutlinedTextField with clear button)
```

## 8. UI Components
- `AddTransactionScreen`: Form container.
- `AmountVisualTransformation`: Formats entered numbers into grouped comma strings without modifying raw state.
- `CategorySelectionGrid`: FlowRow of `CategoryChip` components.
- `PaymentMethodSelector`: Dual segmented buttons for `CASH` and `ACCOUNT`.
- `TransactionDateSelector`: Dual trigger buttons for date and time selection.
- `TransactionListItem`: Surface row with squircle icon, text columns, source badge, and color-coded amount.

## 9. User Interactions
- Tap amount field: Opens numeric decimal keyboard.
- Type numbers: Sanitized in real time to prevent multiple decimals or characters beyond currency decimal digits (default 2).
- Tap Category chip: Selects category, highlighted with animated border and background.
- Tap Payment Method: Toggles between Cash and Account; remembers user override.
- Tap Save: Validates input, saves transaction to Room, schedules widgets refresh, and closes screen.
- Swipe or tap Delete: Triggers deletion; shows bottom Snackbar: "Transaction deleted" with "UNDO" button.

## 10. Input Fields
| Field Name | Type | Constraints | Mandatory |
| :--- | :--- | :--- | :--- |
| **Amount** | String / Decimal | $> 0.00$, $\le 100,000,000,000,000$ subunits, max 2 decimals | Yes |
| **Type** | Enum (`TransactionType`) | `EXPENSE` or `INCOME` | Yes |
| **Category** | Object (`Category`) | Must match selected `TransactionType` | Yes |
| **Payment Method** | Enum (`PaymentMethod`) | `CASH` or `ACCOUNT` | Yes |
| **Date & Time** | Long (Epoch Milliseconds) | Valid epoch timestamp | Yes |
| **Note** | String | Optional, trimmed, max 255 chars | No |

## 11. Validation Rules
- `TransactionValidator.validateAmount()`: Non-blank, strictly positive, parsed to integer subunits, within max bounds.
- `TransactionValidator.validateCategory()`: Category cannot be null, and category type must match transaction type.

## 12. Business Rules
- Expenses reduce the net balance; income increases the net balance.
- Default payment method is pre-populated from `UserPreferences.defaultExpenseSource` or `defaultIncomeSource`.
- Deleting a transaction removes it from the ledger, but if undone via the snackbar within 4 seconds, the exact transaction is restored.
- If linked to a split expense settlement or savings goal contribution, transaction records retain audit traceability.

## 13. Calculation Logic
- Subunits: `val subunits = Amount.fromStringOrNull(input, currency)!!.subunits`.
- Formatting: `Amount(subunits).format(currency)` returns string like `₹1,250.00`.

## 14. Database Interactions
- `TransactionDao.insertTransaction(entity)`: Returns generated `id`.
- `TransactionDao.updateTransaction(entity)`.
- `TransactionDao.deleteTransactionById(id)`.
- `TransactionDao.getAllTransactionsWithCategory()`: Reactive Flow.

## 15. State Management
- `AddTransactionViewModel`: Exposes `AddTransactionUiState(amount, selectedCategory, paymentMethod, timestamp, note, isSaving, errorMessage)`.
- `TransactionsViewModel`: Exposes `TransactionsUiState(transactions, selectedFilter, selectedPaymentMethod, searchQuery, isLoading)`.

## 16. Navigation
- Back navigation returns to the caller without saving unsaved data.
- Successful save pops back or navigates to Dashboard.

## 17. Error Handling
- Validation errors display inline below the invalid field in red text (`MaterialTheme.colorScheme.error`).
- Database exceptions trigger an error snackbar without losing entered data.

## 18. Empty States
- Transactions list: When search returns no matches, displays "No transactions found matching '[query]'".
- When ledger is empty, displays "No transactions recorded yet".

## 19. Loading States
- Save button displays a circular spinner while persisting.
- Initial ledger load displays placeholder skeleton items.

## 20. Edge Cases
- Decimal input without leading zero (`.50`) -> Automatically parsed as `0.50` (50 subunits).
- Copy-pasting text with currency symbols (`₹1,500.00`) -> Cleaned and parsed accurately.
- Editing an existing transaction: Updates `updatedAt` epoch while preserving `createdAt`.

## 21. Dependencies
- `TransactionRepository`
- `CategoryRepository`
- `UserPreferencesRepository`
- `WidgetUpdateManager`

## 22. Relevant Android Source Files
- `app/src/main/java/com/vinaynalavade/expensetracker/presentation/entry/AddTransactionScreen.kt`
- `app/src/main/java/com/vinaynalavade/expensetracker/presentation/entry/AddTransactionViewModel.kt`
- `app/src/main/java/com/vinaynalavade/expensetracker/presentation/transactions/TransactionsScreen.kt`
- `app/src/main/java/com/vinaynalavade/expensetracker/presentation/transactions/TransactionsViewModel.kt`
- `app/src/main/java/com/vinaynalavade/expensetracker/QuickAddTransactionActivity.kt`

## 23. Relevant Tests
- `app/src/test/java/com/vinaynalavade/expensetracker/TransactionsFilterAndSearchTest.kt`
- `app/src/test/java/com/vinaynalavade/expensetracker/TransactionEntityMappingTest.kt`
- `app/src/test/java/com/vinaynalavade/expensetracker/PaymentMethodUiIntegrationTest.kt`

## 24. iOS Implementation Expectations
- Create `AddTransactionView.swift` and `TransactionsListView.swift`.
- Use SwiftUI `TextField` with custom decimal formatters and numeric keyboard.
- Use native `DatePicker` with graphical or wheel style for date and time selection.
- Implement swipe-to-delete with SwiftUI `.swipeActions(edge: .trailing)`.
- Quick Add sheet presented via `.sheet(isPresented: ...)`.

## 25. Acceptance Criteria
1. Entering `1234.56` creates a transaction with exactly `123456` subunits.
2. Filter chips dynamically filter the list instantly without database re-querying.
3. Search matches notes and category names case-insensitively.
4. Deleting a transaction and clicking "Undo" restores the item at its original position.

