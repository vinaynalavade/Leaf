# Leaf Business Logic: Transaction Rules, Ledger Architecture & Financial Continuity

## 1. Executive Summary
The core ledger in Leaf is designed around financial continuity, auditability, and immutability. While Leaf provides consumer-friendly features such as shared bill splitting, recurring deductions, and savings goals, all underlying movements of money ultimately resolve into the unified `transactions` ledger.

This document details the ledger integration contracts, payment method segregations, and soft-unlinking rules that guarantee zero data corruption or balance drift.

---

## 2. Ledger Invariants & Flow Directionality

### 2.1 Fundamental Accounting Invariants
Every recorded financial movement belongs to one of two atomic directions:
1. **INCOME**: Represents an external inflow of funds into the user's possession. Increases net worth and liquid balances.
2. **EXPENSE**: Represents an outflow of funds from the user's possession. Decreases net worth and liquid balances.

Leaf does not currently support multi-currency conversions in a single ledger; all historical records are accounted for in the user's chosen primary currency unit.

### 2.2 Payment Method Segregation (Cash vs. Account)
Leaf segregates funds across two primary liquid liquidity pools:
- **`ACCOUNT`**: Bank accounts, debit cards, UPI, digital wallets, and digital electronic payment rails.
- **`CASH`**: Physical physical banknotes and coins.

Both methods roll up into the overall **Liquid Net Balance**:
$$\text{NetBalance} = \text{CashBalance} + \text{AccountBalance}$$
Where:
$$\text{CashBalance} = \text{OpeningCashSubunits} + \sum \text{Income}_{\text{Cash}} - \sum \text{Expense}_{\text{Cash}}$$
$$\text{AccountBalance} = \text{OpeningAccountSubunits} + \sum \text{Income}_{\text{Account}} - \sum \text{Expense}_{\text{Account}}$$

---

## 3. Split & Collect 2.0 Ledger Integration

### 3.1 Bill Creation with Ledger Integration (`add_to_transactions = 1`)
When a user creates a split expense and checks the option *"Add my share to expenses"*:
1. A record is inserted into `split_expenses`.
2. Individual participant records are inserted into `split_participants`.
3. If the user paid for the bill (`isPayerCurrentUser == true`):
   - A linked `EXPENSE` transaction is generated in `transactions`.
   - **Amount**: The user's individual calculated share (or the full bill amount, depending on whether the user tracks upfront outlay or personal net expense). In Leaf's standard configuration, it records the user's personal share to prevent artificially inflating individual expense budgets.
   - **Category**: Matches the category assigned to the split expense.
   - **Payment Method**: Matches the payment method selected in the split form.
   - **Linkage**: The generated `transactions.id` is stored in `split_expenses.expense_transaction_id`.

### 3.2 Settlement Ledger Integration (Receiving Repayments)
When another participant settles their outstanding debt to the user:
1. Participant's `settlement_status` is updated to `SETTLED`, and `settled_at` timestamp is recorded.
2. A linked `INCOME` transaction is automatically generated in `transactions`:
   - **Title**: `"Settlement: [ParticipantName] ([SplitTitle])"`
   - **Amount**: Exactly equals `participant.amount_subunits`.
   - **Category**: Mapped to "Other Income" or the split's category.
   - **Date**: The exact timestamp when settlement occurred.
   - **Linkage**: The generated `transactions.id` is stored in `split_participants.settlement_transaction_id`.

### 3.3 Financial Immutability on Deletion
If a user deletes a split expense:
- The `split_expenses` and `split_participants` records are removed.
- **Ledger Invariant**: The linked records in `transactions` (both the original expense and any past settlement income entries) are **NOT deleted**.
- Rationale: Real money was already spent and real repayments were already collected in the past. Silently deleting past ledger entries would break previous monthly statements and alter historical net balances. The foreign key references are safely cleared to `NULL`.

---

## 4. Savings Goals & Contributions Integration

1. When a user logs a contribution to a savings goal:
   - A record is created in `savings_goal_contributions`.
   - Optionally, an `EXPENSE` transaction is logged in `transactions` (under a "Savings & Investments" category) if the user wishes to deduct the contributed funds from their liquid checking/cash balance.
   - The transaction ID is stored in `savings_goal_contributions.transaction_id`.
2. If the contribution is later removed or edited:
   - The linked transaction is either updated or cleanly soft-unlinked based on user preference.

---

## 5. Recurring Transactions Auto-Generation

1. Recurring transaction templates are stored in `recurring_transactions`.
2. When the background generator worker triggers on the due date:
   - A new concrete entry is inserted into `transactions` with:
     - `title = template.title`
     - `amount_subunits = template.amount_subunits`
     - `type = template.type`
     - `category_id = template.category_id`
     - `payment_method = template.payment_method`
     - `date = currentEpochMillis`
   - The template's `last_generated_date` is updated to prevent duplicate generations in the same billing cycle.
3. Once generated, the resulting transaction is an independent, immutable ledger row. Editing or deleting the recurring rule in the future has zero retroactive effect on historical generated transactions.

---

## 6. Continuous Financial Continuity Contract
Across the application lifecycle, Leaf guarantees:
- **No Temporal Gaps**: Opening balance calculations continuously aggregate all preceding historical records from the dawn of the database up to the requested month.
- **Atomic Operations**: All multi-table ledger mutations (e.g., creating a split + inserting transaction, or settling participant + inserting income) must execute within an atomic SQLite / Room transaction (`@Transaction` / `BEGIN TRANSACTION ... COMMIT`). If any step fails, the entire operation is rolled back.

