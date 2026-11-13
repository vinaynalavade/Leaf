# Leaf Quality Assurance: Detailed Test Cases & Execution Matrix

## 1. Executive Summary
This document provides executable test cases for validating the functional correctness and cross-platform parity of Leaf. Every test case defines unique identifiers, preconditions, input parameters, execution steps, expected outcomes, and pass/fail criteria.

---

## 2. Test Case Specifications

### 2.1 Transaction Management (`TC-TXN`)

#### TC-TXN-01: Create Valid Expense Transaction
- **Preconditions**: Category "Food & Dining" (`id: 1`) exists.
- **Inputs**: Amount = `"180.50"`, Type = `EXPENSE`, Category = `1`, PaymentMethod = `CASH`, Note = `"Lunch"`.
- **Steps**:
  1. Open `AddEditTransactionSheet`.
  2. Input amount, select category, select CASH, input note.
  3. Tap "Save".
- **Expected Outcome**:
  - Record inserted into `transactions` table with `amount_subunits = 18050L`.
  - Net balance on Dashboard decrements by exactly 18050 subunits.
  - Sheet dismisses.
- **Pass Criteria**: DB record matches inputs exactly; net balance updates reactively.

#### TC-TXN-02: Reject Zero or Negative Amount Transaction
- **Inputs**: Amount = `"0"` or `"-50.00"`.
- **Steps**: Input value in amount field and attempt to tap "Save".
- **Expected Outcome**: "Save" button remains disabled or validation error banner appears: *"Amount must be greater than zero."*
- **Pass Criteria**: Zero/negative amounts cannot be saved to the database.

#### TC-TXN-03: Reject Subunit Overflow
- **Inputs**: Amount = `"1000000000000001"` (exceeds $10^{14}$ subunits).
- **Steps**: Paste large number into amount field.
- **Expected Outcome**: Field clamps or rejects input with error: *"Amount exceeds maximum allowed limit."*
- **Pass Criteria**: Integer overflow is impossible.

---

### 2.2 Split & Collect 2.0 (`TC-SPLIT`)

#### TC-SPLIT-01: Equal Split with Remainder Allocation
- **Inputs**: Total Bill = `"100.00"` (10,000 paise), Participants = `["Me", "Rahul", "Priya"]` ($N = 3$), Payer = `"Me"`.
- **Steps**:
  1. Open `CreateSplitScreen`.
  2. Enter details, select `Equal Split`, tap "Save".
- **Expected Outcome**:
  - Participant 0 ("Me"): $\lfloor 10000 / 3 \rfloor + 1 = 3334$ paise (₹33.34).
  - Participant 1 ("Rahul"): $3333$ paise (₹33.33).
  - Participant 2 ("Priya"): $3333$ paise (₹33.33).
  - Sum of shares: $3334 + 3333 + 3333 = 10000$ paise (₹100.00) exactly.
- **Pass Criteria**: Absolute penny zero-sum invariant holds.

#### TC-SPLIT-02: Custom Split Mismatch Validation
- **Inputs**: Total Bill = `"100.00"` (10,000 paise), Custom allocations: "Me" = ₹40, "Rahul" = ₹50 (Sum = ₹90).
- **Steps**: Enter custom values and attempt to save.
- **Expected Outcome**: Save button is disabled. Banner displays: *"Allocated amounts do not match total bill. Difference: ₹10.00 remaining"*.
- **Pass Criteria**: Unbalanced custom split cannot be saved.

#### TC-SPLIT-03: Settlement Ledger Integration
- **Preconditions**: Unsettled split exists where Rahul owes Me ₹800.
- **Steps**:
  1. Open `SplitDetailScreen`.
  2. Expand Rahul's participant row and toggle "Mark as Settled".
- **Expected Outcome**:
  - Rahul's `settlement_status` changes to `SETTLED`, `settled_at` records timestamp.
  - Linked `INCOME` transaction generated in `transactions` with `amount_subunits = 80000L` and title `"Settlement: Rahul ([BillTitle])"`.
  - Net balance on Dashboard increases by ₹800.
- **Pass Criteria**: Repayment is recorded in personal ledger without manual double entry.

#### TC-SPLIT-04: Split Deletion Ledger Immutability
- **Preconditions**: Split exists with linked expense and settled income transactions.
- **Steps**: Delete the split bill from `SplitDetailScreen`.
- **Expected Outcome**:
  - `split_expenses` and `split_participants` records are removed.
  - Linked `transactions` records remain intact in the database with their foreign keys cleared to `NULL`.
  - Historical bank statements and net balances remain stable.
- **Pass Criteria**: Realized historical ledger entries are preserved.

---

### 2.3 Planning & Budgets (`TC-BUD`)

#### TC-BUD-01: Budget Threshold State Transitions
- **Inputs**: Category Budget Limit = ₹10,000 (1,000,000 subunits).
- **Scenarios**:
  - Spend = ₹5,000 ($50\%$): State is `On Track`, progress bar is **Emerald Green**.
  - Spend = ₹8,000 ($80\%$): State is `Approaching Limit`, progress bar is **Amber Gold**.
  - Spend = ₹10,000 ($100\%$): State is `Limit Reached`, progress bar is **Warning Amber**.
  - Spend = ₹10,500 ($105\%$): State is `Over Budget`, progress bar is **Crimson Red**.
- **Pass Criteria**: Visual colors and text labels transition accurately at boundary thresholds.

---

### 2.4 Financial Calculators (`TC-CALC`)

#### TC-CALC-01: Standard Banking EMI Test Vector
- **Inputs**: Principal = ₹10,00,000 ($10^6$), Annual Rate = $8.5\%$, Tenure = $240$ months ($20$ years).
- **Formulas**:
  - Monthly Rate $r = 8.5 / (12 \times 100) = 0.007083333333$.
  - Factor $(1 + r)^{240} = 5.412175$.
  - Monthly EMI: $1000000 \times 0.007083333333 \times (5.412175 / 4.412175) = ₹8,678.23$.
  - Total Payment: $8678.23 \times 240 = ₹20,82,775.20$.
  - Total Interest: $2082775.20 - 1000000 = ₹10,82,775.20$.
- **Pass Criteria**: Output matches banking standard within ₹0.50 tolerance.

---

### 2.5 Security & PIN Vault (`TC-SEC`)

#### TC-SEC-01: 5 Failed PIN Lockout Rate Limiting
- **Preconditions**: App Lock is enabled with PIN `"1234"`.
- **Steps**:
  1. Launch app. `AppLockScreen` appears.
  2. Input incorrect PIN `"9999"` 5 consecutive times.
- **Expected Outcome**:
  - Keypad is disabled.
  - Countdown timer appears: *"Too many incorrect attempts. Try again in 30 seconds."*
  - Lockout persists across app restarts until 30 seconds elapse.
- **Pass Criteria**: Rate-limiting actively stops brute-force attempts.

