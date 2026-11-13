# Leaf Database: Relationships, Foreign Keys & Cascading Integrity

## 1. Executive Summary
Relational integrity protects Leaf against orphaned records, broken aggregations, and corrupted financial history. This document provides an exhaustive reference of all foreign key constraints, deletion cascade policies, parent-child lifecycles, and join relationships across the 10 database tables.

---

## 2. Foreign Key & Cascade Policy Matrix

| Child Table | Foreign Key Column | Parent Table | Parent Key | `ON DELETE` Action | `ON UPDATE` Action | Business Rationale |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| `transactions` | `category_id` | `categories` | `id` | **RESTRICT** | NO ACTION | Prevents deleting categories that active transactions depend upon. Protects historical classification. |
| `recurring_transactions` | `category_id` | `categories` | `id` | **RESTRICT** | NO ACTION | Prevents recurring rules from referencing missing categories. |
| `split_expenses` | `category_id` | `categories` | `id` | **RESTRICT** | NO ACTION | Ensures shared bills are tagged with valid financial categories. |
| `split_expenses` | `group_id` | `split_groups` | `id` | **SET NULL** | NO ACTION | Deleting a group preserves its expenses as ungrouped shared bills. |
| `split_participants` | `split_expense_id` | `split_expenses` | `id` | **CASCADE** | NO ACTION | Deleting a split bill automatically deletes all constituent participant shares. |
| `budgets` | `category_id` | `categories` | `id` | **SET NULL** | NO ACTION | If a category is ever removed, its budget converts to an overall budget record rather than corrupting. |
| `savings_goal_contributions` | `goal_id` | `savings_goals` | `id` | **CASCADE** | NO ACTION | Deleting a savings goal purges its internal contribution log. |
| `savings_goal_contributions` | `transaction_id` | `transactions` | `id` | **SET NULL** | NO ACTION | Deleting a ledger transaction preserves the goal contribution record while clearing the ledger reference. |

---

## 3. Soft Relationships & Ledger Linkages

In addition to database-level foreign key constraints, Leaf enforces soft linkages to maintain ledger immutability:

### 3.1 Split Bill -> Expense Transaction Linkage
- Column: `split_expenses.expense_transaction_id`
- Target: `transactions.id`
- Integrity Contract: Deleting a `split_expenses` row does **NOT** cascade delete the linked `transactions` record. The transaction is retained in the general ledger to maintain historical net balance continuity.

### 3.2 Participant Settlement -> Income Transaction Linkage
- Column: `split_participants.settlement_transaction_id`
- Target: `transactions.id`
- Integrity Contract: Deleting or resetting a settled participant leaves the recorded repayment income transaction intact in the ledger, preventing previous bank statements from altering retroactively.

---

## 4. Complex Relational Queries & Room Join Objects

### 4.1 Transaction with Category (`TransactionWithCategory`)
```sql
SELECT t.*, c.name AS category_name, c.icon_name, c.color_hex, c.type AS category_type, c.is_default
FROM transactions t
LEFT JOIN categories c ON t.category_id = c.id
ORDER BY t.timestamp DESC;
```

### 4.2 Split Expense with Details (`SplitExpenseWithDetails`)
```sql
SELECT e.*, c.name AS category_name, c.icon_name, c.color_hex, g.name AS group_name
FROM split_expenses e
LEFT JOIN categories c ON e.category_id = c.id
LEFT JOIN split_groups g ON e.group_id = g.id
WHERE e.id = :expenseId;

-- Accompanied by secondary query for participants:
SELECT * FROM split_participants WHERE split_expense_id = :expenseId ORDER BY id ASC;
```

### 4.3 Savings Goal with Contributions (`SavingsGoalWithContributions`)
```sql
SELECT g.* FROM savings_goals g WHERE g.id = :goalId;

-- Child query:
SELECT * FROM savings_goal_contributions WHERE goal_id = :goalId ORDER BY timestamp ASC;
```

---

## 5. Indexing Strategy & Performance Considerations

To ensure query execution times remain under $5$ milliseconds even with $50,000+$ transactions:
1. `index_transactions_timestamp`: Optimizes monthly range filtering (`WHERE timestamp BETWEEN :start AND :end`).
2. `index_transactions_type`: Accelerates isolated Income vs Expense aggregations.
3. `index_transactions_category_id`: Accelerates category donut chart rollups.
4. `index_budgets_year_month`: Optimizes dashboard budget consumption retrieval.
5. `index_split_participants_split_expense_id`: Guarantees instantaneous loading of participant shares when viewing split details.
6. `index_reminders_due_date`: Enables fast retrieval of pending upcoming due dates.

