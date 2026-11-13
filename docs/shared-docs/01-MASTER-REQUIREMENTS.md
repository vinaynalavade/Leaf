# 01 — MASTER REQUIREMENTS SPECIFICATION

## 1. Document Scope & Traceability Matrix

This document defines the binding master requirements for the Leaf personal finance ecosystem. Every requirement is derived directly from the verified Android production codebase (`com.vinaynalavade.expensetracker`), associated Room entities, use cases, ViewModels, and unit test suites.

### Requirement Classification Legend
- **REQ-F-xxx**: Functional Requirement
- **REQ-N-xxx**: Non-Functional Requirement
- **REQ-C-xxx**: Financial Calculation & Precision Requirement
- **REQ-D-xxx**: Database & Data Integrity Requirement
- **REQ-S-xxx**: Security & Privacy Requirement
- **REQ-P-xxx**: Platform & Ecosystem Requirement

---

## 2. Functional Requirements (REQ-F)

### 2.1 Core Ledger & Transactions
- **REQ-F-001 (Income & Expense Recording):** The application shall support capturing income and expense transactions with mandatory positive amount, category selection, transaction type (`INCOME`, `EXPENSE`), payment method (`CASH`, `ACCOUNT`), timestamp, and optional free-text note.
  - *Traceability:* `AddTransactionViewModel.kt`, `TransactionEntity.kt`, `TransactionValidator.kt`.
- **REQ-F-002 (Transaction Modification & Deletion):** Users shall be able to edit any existing transaction (preloading current values) or delete it. Deletion shall provide an immediate non-destructive Undo action via Snackbar/banner.
  - *Traceability:* `TransactionsViewModel.kt`, `TransactionDetailViewModel.kt`, `TransactionRepositoryImpl.kt`.
- **REQ-F-003 (Transaction Filtering & Search):** The transactions list shall support real-time full-text search across notes and category names, combined with filters for type (`ALL`, `EXPENSE`, `INCOME`), payment method (`ALL`, `CASH`, `ACCOUNT`), and chronological grouping (Month -> Day: "Today", "Yesterday", or formatted date).
  - *Traceability:* `TransactionsFilterAndSearchTest.kt`, `TransactionsViewModel.kt`.
- **REQ-F-004 (Opening Balance & Financial Continuity):** The application shall allow the user to specify a baseline opening balance. Month-over-month opening balance must continuously carry forward past income minus past expenses.
  - *Traceability:* `GetMonthlyLedgerUseCase.kt`, `FinancialCalculationTest.kt`, `UserPreferencesDataStore.kt`.
- **REQ-F-005 (Bank-Grade PDF Statement Generation):** The application shall generate on-device, multi-page vector PDF financial statements for any user-selected date range, featuring A4 layout, right-aligned monetary figures, running balance reconciliation, category attribution, and system share sheet handoff.
  - *Traceability:* `PdfUtils.kt`, `GenerateStatementUseCase.kt`, `StatementsViewModel.kt`.
- **REQ-F-006 (Interactive Financial Calendar):** The application shall provide a monthly calendar view displaying daily income and expense indicators with instant drill-down into daily transaction ledgers.
  - *Traceability:* `CalendarScreen.kt`, `CalendarViewModel.kt`.

### 2.2 Split & Collect Module (Split 2.0)
- **REQ-F-010 (Equal Split with Exact Paisa Reconciliation):** The application shall divide an expense among $N$ participants equally in integer subunits. Any remainder $R = (\text{Total Subunits} \pmod N)$ must be distributed deterministically by adding 1 subunit to the first $R$ participants.
  - *Traceability:* `SplitCalculationEngine.kt#calculateEqualSplit`, `SplitCalculationEngineTest.kt`.
- **REQ-F-011 (Itemized Custom Bill Splitting):** The application shall support itemized splitting where individual line items are assigned to subsets of participants, and unassigned bill amounts are distributed among designated base participants with exact subunit reconciliation.
  - *Traceability:* `SplitCalculationEngine.kt#calculateItemizedSplit`, `SplitDomainTest.kt`.
- **REQ-F-012 (Direct Custom Share Allocation):** The application shall support entering direct custom amounts per participant, enforcing real-time validation that the sum of shares equals the total bill.
  - *Traceability:* `SplitCalculationEngine.kt#validateCustomSplit`.
- **REQ-F-013 (Directional Net Balance Calculation):** The application shall compute pairwise debt cancellation across split expenses within groups or overall, tracking who owes whom and net amounts owed to/by the current user.
  - *Traceability:* `NetBalanceEngine.kt`, `SharedFinanceNetBalanceTest.kt`.
- **REQ-F-014 (UPI QR Presentation & Storage):** The application shall allow uploading, private storage, and display of UPI payment QR images for split expenses, including external sharing.
  - *Traceability:* `SplitQrStorageManager.kt`, `CreateSplitViewModel.kt`.
- **REQ-F-015 (Personalized WhatsApp Reminders):** The application shall generate personalized payment reminder messages (communicating bill title, total bill, individual share, and remaining amount) and launch targeted WhatsApp chats or system sharing.
  - *Traceability:* `WhatsAppShareHelper.kt`, `WhatsAppShareHelperTest.kt`.
- **REQ-F-016 (Split Ledger Integration):** When `addToTransactions` is enabled, saving a split expense creates an Expense transaction for the total amount. Marking an external participant's share as `SETTLED` optionally creates an Income transaction for their share.
  - *Traceability:* `SplitRepositoryImpl.kt`, `SplitTransactionIntegrationTest.kt`.

### 2.3 Planning & Obligations
- **REQ-F-020 (Monthly Budgeting):** The application shall support defining monthly overall spending budgets as well as category-specific budgets, tracking percentage used, remaining amounts, and warning statuses (`ON_TRACK`, `APPROACHING_LIMIT` at $\ge 75\%$, `LIMIT_REACHED` at $100\%$, `OVER_BUDGET` at $> 100\%$).
  - *Traceability:* `GetBudgetProgressUseCase.kt`, `BudgetCalculationTest.kt`, `BudgetEntity.kt`.
- **REQ-F-021 (Target-Driven Savings Goals):** The application shall support creating savings goals with target amount, optional target date, custom icon, color, and note. Users can add or delete contributions, with an option to link contributions as ledger expense transactions under "Savings & Goals".
  - *Traceability:* `SavingsGoal.kt`, `SaveSavingsGoalContributionUseCase.kt`, `SavingsGoalProgressTest.kt`.
- **REQ-F-022 (Recurring Transactions & Salary Auto-Generation):** The application shall support recurring transactions with Daily, Weekly, Monthly, and Yearly frequencies. An automatic processor shall generate transactions when due, clamping month-end dates (e.g. 31st to 28th/29th/30th).
  - *Traceability:* `RecurringTransactionRepositoryImpl.kt`, `RecurringEmiDayOfMonthTest.kt`.
- **REQ-F-023 (Financial Obligation Reminders):** The application shall track bill, EMI, credit card, and custom payment obligations with due dates, recurrence, advance notification offsets (e.g., 1 day before), and the ability to mark as paid (advancing the cycle and optionally logging an expense transaction).
  - *Traceability:* `Reminder.kt`, `ReminderRepositoryImpl.kt`, `ReminderReceiver.kt`.

### 2.4 Financial Tools & Calculators
- **REQ-F-030 (EMI Calculator):** Equated Monthly Installment calculation with monthly reducing balance formula:
  $$\text{EMI} = \frac{P \cdot r \cdot (1+r)^n}{(1+r)^n - 1}$$
  - *Traceability:* `FinancialCalculatorEngine.kt#calculateEmi`, `FinancialCalculatorEngineTest.kt`.
- **REQ-F-031 (SIP Calculator):** Systematic Investment Plan calculation using beginning-of-month annuity-due compounding:
  $$M = P \cdot \left[\frac{(1+i)^n - 1}{i}\right] \cdot (1+i)$$
  - *Traceability:* `FinancialCalculatorEngine.kt#calculateSip`.
- **REQ-F-032 (FD Calculator):** Fixed Deposit calculation with quarterly compounding:
  $$A = P \cdot \left(1 + \frac{r}{4}\right)^{4t}$$
  - *Traceability:* `FinancialCalculatorEngine.kt#calculateFd`.
- **REQ-F-033 (RD Calculator):** Recurring Deposit calculation summing quarterly compounded monthly tranches:
  $$A = \sum_{m=1}^{n} P \cdot \left(1 + \frac{r}{4}\right)^{\frac{4(n - m + 1)}{12}}$$
  - *Traceability:* `FinancialCalculatorEngine.kt#calculateRd`.
- **REQ-F-034 (GST & Discount Calculators):** Both Exclusive and Inclusive GST tax calculations, and percentage discount price calculations.
  - *Traceability:* `FinancialCalculatorEngine.kt#calculateGst`, `#calculateDiscount`.
- **REQ-F-035 (In-Expression Calculator Evaluator):** Arithmetic evaluation supporting `+`, `-`, `×`, `÷`, parentheses, operator precedence (Dijkstra's Shunting-Yard), live partial previews, and division-by-zero protection.
  - *Traceability:* `EvaluateCalculatorExpressionUseCase.kt`, `CalculatorExpressionEvaluatorTest.kt`.

---

## 3. Financial Calculation & Precision Requirements (REQ-C)

- **REQ-C-001 (Zero Floating-Point Drift):** All core database records, balances, summaries, splits, budgets, and savings amounts must be stored and computed as 64-bit signed integers representing currency subunits (e.g. paise / cents). Floating-point data types (`Float`, `Double`) are strictly prohibited in the persistence layer and financial domain models.
- **REQ-C-002 (Multi-Currency Scaling):** The application shall support ISO 4217 currencies with explicit subunit scaling factors:
  - 2 decimal digits ($\times 100$ factor): INR, USD, EUR, GBP, AED, SGD, CAD, AUD.
  - 0 decimal digits ($\times 1$ factor): JPY.
- **REQ-C-003 (Deterministic Remainder Reconciliation):** Whenever a financial quantity is divided among multiple parties or periods, the sum of all parts must exactly equal the original total. Any fractional remainder must be allocated deterministically to the initial partition elements.
- **REQ-C-004 (Overflow Protection Ceiling):** Input values and monetary allocations shall enforce a strict upper bound of $10^{14}$ subunits (₹100 Crore / 1 Billion units) to prevent 64-bit integer overflow during aggregation.

---

## 4. Security & Privacy Requirements (REQ-S)

- **REQ-S-001 (Zero Telemetry & Offline Sovereignty):** The application shall not integrate any third-party analytics, crash reporting, tracking SDKs, or remote ad networks. Network communication shall be strictly restricted to user-initiated actions (cloud backup sync, GitHub release update checks).
- **REQ-S-002 (Salted PBKDF2 / SHA-256 App Lock PIN):** App Lock PINs must be salted with a cryptographically secure 16-byte random salt, hashed using SHA-256 (or PBKDF2/Argon2), and stored in an isolated, secure keychain vault separate from application database backups.
- **REQ-S-003 (PIN Throttling & Lockout):** After 5 consecutive failed PIN verification attempts, the application shall enforce a temporary lockout of 30 seconds before allowing further verification attempts.
- **REQ-S-004 (Biometric Authentication):** The application shall support biometric authentication (Face ID / Touch ID on iOS, BiometricPrompt on Android) as an optional convenience when App Lock is active.
- **REQ-S-005 (App Switcher Privacy / Content Concealment):** When App Lock is enabled and `hideContentInRecents` is true, the application must obscure or blur the app preview in the system app switcher/multitasking view.
- **REQ-S-006 (Credential Exclusion from Backups):** Security vault PIN hashes, salts, lockout counters, and OAuth tokens must never be serialized into exported JSON or CSV backup files.

---

## 5. Persistence & Data Integrity Requirements (REQ-D)

- **REQ-D-001 (Relational Data Model):** Persistence must enforce relational integrity, primary keys, indexes on queried columns (`timestamp`, `category_id`, `due_date`), and cascading / restrict foreign key constraints.
- **REQ-D-002 (Atomic Transactions):** Multi-table persistence operations (such as creating a split expense with linked ledger transactions, or saving a savings goal contribution with account deduction) must execute inside atomic database transactions.
- **REQ-D-003 (Immutable Historical Records):** Deleting a split expense or reverting a participant's settlement status to `PENDING` must preserve existing ledger transactions to maintain historical auditing integrity.
- **REQ-D-004 (Category Protection):** Pre-seeded default categories must not be deletable. Categories linked to existing transactions must be protected against deletion unless transactions are reassigned or protected.

---

## 6. Non-Functional & Quality Requirements (REQ-N)

- **REQ-N-001 (Cold Start & Frame Performance):** The application shall launch within 1.5 seconds on modern devices and maintain 60/120 fps fluid scrolling without frame drops.
- **REQ-N-002 (Accessible Design):** High contrast ratios meeting WCAG AA standards, support for dynamic system font sizing, voiceover / screen reader accessibility labels, and accessible touch targets ($\ge 44 \times 44$ pt).
- **REQ-N-003 (Internationalization):** Full support for English, Hindi, and Marathi locales, with extensible string resource catalogs and localized number/date formatting.
- **REQ-N-004 (Dark & Light Theme Parity):** Flawless presentation across Obsidian Dark mode (`#0A0C0F`) and Daylight Light mode (`#F4F6F9`) with dedicated financial color palettes.

