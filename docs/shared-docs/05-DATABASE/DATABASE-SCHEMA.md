# Leaf Database: Complete Database Schema Specification

## 1. Executive Summary
The primary persistent datastore for Leaf is an embedded SQLite database managed via Android Room (`expense_tracker.db` at **Schema Version 10**). 

The database contains **10 tables** designed to support transaction logging, categorization, recurring rules, multi-user bill splitting, budgeting, savings milestones, and financial calendar reminders. All monetary fields are strictly stored as signed 64-bit integers (`INTEGER` / `Long`).

---

## 2. Table-by-Table Schema Definitions

### 2.1 Table: `categories`
Stores taxonomy for expenses and income.

```sql
CREATE TABLE IF NOT EXISTS `categories` (
    `id` INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
    `name` TEXT NOT NULL,
    `icon_name` TEXT NOT NULL,
    `color_hex` TEXT NOT NULL,
    `type` TEXT NOT NULL,
    `is_default` INTEGER NOT NULL DEFAULT 0
);
```
- **Indices**: Implicit primary key index on `id`.
- **Pre-seeded**: 20 default system rows (12 `EXPENSE`, 8 `INCOME`).

---

### 2.2 Table: `transactions`
The central ledger of all confirmed monetary inflows and outflows.

```sql
CREATE TABLE IF NOT EXISTS `transactions` (
    `id` INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
    `amount_subunits` INTEGER NOT NULL,
    `type` TEXT NOT NULL,
    `category_id` INTEGER NOT NULL,
    `payment_method` TEXT NOT NULL DEFAULT 'CASH',
    `note` TEXT,
    `timestamp` INTEGER NOT NULL,
    `created_at` INTEGER NOT NULL,
    `updated_at` INTEGER NOT NULL,
    FOREIGN KEY(`category_id`) REFERENCES `categories`(`id`) ON UPDATE NO ACTION ON DELETE RESTRICT
);
```
- **Indices**:
  - `CREATE INDEX IF NOT EXISTS index_transactions_category_id ON transactions(category_id);`
  - `CREATE INDEX IF NOT EXISTS index_transactions_timestamp ON transactions(timestamp);`
  - `CREATE INDEX IF NOT EXISTS index_transactions_type ON transactions(type);`

---

### 2.3 Table: `recurring_transactions`
Templates for automated, periodic income and expense generation.

```sql
CREATE TABLE IF NOT EXISTS `recurring_transactions` (
    `id` INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
    `title` TEXT NOT NULL,
    `amount_subunits` INTEGER NOT NULL,
    `type` TEXT NOT NULL,
    `category_id` INTEGER NOT NULL,
    `payment_method` TEXT NOT NULL DEFAULT 'CASH',
    `note` TEXT,
    `frequency` TEXT NOT NULL,
    `day_of_month` INTEGER NOT NULL DEFAULT 1,
    `day_of_week` INTEGER NOT NULL DEFAULT 1,
    `start_date` INTEGER NOT NULL,
    `end_date` INTEGER,
    `is_enabled` INTEGER NOT NULL DEFAULT 1,
    `is_auto_generated` INTEGER NOT NULL DEFAULT 1,
    `reminder_days_before` INTEGER,
    `last_generated_date` INTEGER,
    `created_at` INTEGER NOT NULL,
    `updated_at` INTEGER NOT NULL,
    FOREIGN KEY(`category_id`) REFERENCES `categories`(`id`) ON UPDATE NO ACTION ON DELETE RESTRICT
);
```
- **Indices**:
  - `CREATE INDEX IF NOT EXISTS index_recurring_transactions_category_id ON recurring_transactions(category_id);`

---

### 2.4 Table: `split_groups`
Logical collections of recurring shared expenses (e.g. "Flatmates", "Goa Trip").

```sql
CREATE TABLE IF NOT EXISTS `split_groups` (
    `id` INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
    `name` TEXT NOT NULL,
    `icon_name` TEXT NOT NULL DEFAULT 'group',
    `color_hex` TEXT NOT NULL DEFAULT '#3B82F6',
    `created_at` INTEGER NOT NULL
);
```

---

### 2.5 Table: `split_expenses`
Parent bill records for shared expenses.

```sql
CREATE TABLE IF NOT EXISTS `split_expenses` (
    `id` INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
    `title` TEXT NOT NULL,
    `total_amount_subunits` INTEGER NOT NULL,
    `date` INTEGER NOT NULL,
    `category_id` INTEGER NOT NULL,
    `paid_by` TEXT NOT NULL DEFAULT 'Me',
    `split_method` TEXT NOT NULL DEFAULT 'EQUAL',
    `qr_image_path` TEXT,
    `add_to_transactions` INTEGER NOT NULL DEFAULT 0,
    `expense_transaction_id` INTEGER,
    `payment_method` TEXT NOT NULL DEFAULT 'CASH',
    `group_id` INTEGER,
    `created_at` INTEGER NOT NULL,
    `updated_at` INTEGER NOT NULL,
    `items_json` TEXT,
    FOREIGN KEY(`category_id`) REFERENCES `categories`(`id`) ON UPDATE NO ACTION ON DELETE RESTRICT,
    FOREIGN KEY(`group_id`) REFERENCES `split_groups`(`id`) ON UPDATE NO ACTION ON DELETE SET NULL
);
```
- **Indices**:
  - `CREATE INDEX IF NOT EXISTS index_split_expenses_category_id ON split_expenses(category_id);`
  - `CREATE INDEX IF NOT EXISTS index_split_expenses_group_id ON split_expenses(group_id);`

---

### 2.6 Table: `split_participants`
Individual shares, settlement status, and debtor details per split expense.

```sql
CREATE TABLE IF NOT EXISTS `split_participants` (
    `id` INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
    `split_expense_id` INTEGER NOT NULL,
    `name` TEXT NOT NULL,
    `is_current_user` INTEGER NOT NULL,
    `amount_subunits` INTEGER NOT NULL,
    `settlement_status` TEXT NOT NULL DEFAULT 'PENDING',
    `settled_at` INTEGER,
    `settlement_transaction_id` INTEGER,
    `phone_number` TEXT,
    FOREIGN KEY(`split_expense_id`) REFERENCES `split_expenses`(`id`) ON UPDATE NO ACTION ON DELETE CASCADE
);
```
- **Indices**:
  - `CREATE INDEX IF NOT EXISTS index_split_participants_split_expense_id ON split_participants(split_expense_id);`

---

### 2.7 Table: `budgets`
Monthly category-specific and overall expenditure caps.

```sql
CREATE TABLE IF NOT EXISTS `budgets` (
    `id` INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
    `category_id` INTEGER,
    `amount_subunits` INTEGER NOT NULL,
    `month` INTEGER NOT NULL,
    `year` INTEGER NOT NULL,
    `created_at` INTEGER NOT NULL,
    `updated_at` INTEGER NOT NULL,
    FOREIGN KEY(`category_id`) REFERENCES `categories`(`id`) ON UPDATE NO ACTION ON DELETE SET NULL
);
```
- **Indices**:
  - `CREATE INDEX IF NOT EXISTS index_budgets_year_month ON budgets(year, month);`
  - `CREATE INDEX IF NOT EXISTS index_budgets_category_id ON budgets(category_id);`

---

### 2.8 Table: `savings_goals`
Target savings milestones and progress buckets.

```sql
CREATE TABLE IF NOT EXISTS `savings_goals` (
    `id` INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
    `name` TEXT NOT NULL,
    `target_amount_subunits` INTEGER NOT NULL,
    `target_date` INTEGER,
    `note` TEXT,
    `icon_name` TEXT NOT NULL DEFAULT 'savings',
    `color_hex` TEXT NOT NULL DEFAULT '#10B981',
    `is_archived` INTEGER NOT NULL DEFAULT 0,
    `created_at` INTEGER NOT NULL,
    `updated_at` INTEGER NOT NULL
);
```

---

### 2.9 Table: `savings_goal_contributions`
Individual cash or transfer deposits into a savings goal.

```sql
CREATE TABLE IF NOT EXISTS `savings_goal_contributions` (
    `id` INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
    `goal_id` INTEGER NOT NULL,
    `amount_subunits` INTEGER NOT NULL,
    `note` TEXT,
    `timestamp` INTEGER NOT NULL,
    `transaction_id` INTEGER,
    `created_at` INTEGER NOT NULL,
    FOREIGN KEY(`goal_id`) REFERENCES `savings_goals`(`id`) ON UPDATE NO ACTION ON DELETE CASCADE,
    FOREIGN KEY(`transaction_id`) REFERENCES `transactions`(`id`) ON UPDATE NO ACTION ON DELETE SET NULL
);
```
- **Indices**:
  - `CREATE INDEX IF NOT EXISTS index_savings_goal_contributions_goal_id ON savings_goal_contributions(goal_id);`
  - `CREATE INDEX IF NOT EXISTS index_savings_goal_contributions_transaction_id ON savings_goal_contributions(transaction_id);`

---

### 2.10 Table: `reminders`
Due-date financial alerts for utility bills, loan EMIs, and credit card payments.

```sql
CREATE TABLE IF NOT EXISTS `reminders` (
    `id` INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
    `title` TEXT NOT NULL,
    `description` TEXT,
    `amount_subunits` INTEGER NOT NULL,
    `type` TEXT NOT NULL,
    `due_date` INTEGER NOT NULL,
    `recurrence` TEXT NOT NULL,
    `configured_day_of_month` INTEGER NOT NULL DEFAULT 1,
    `reminder_offset_days` INTEGER NOT NULL DEFAULT 1,
    `additional_offsets` TEXT,
    `notification_hour` INTEGER NOT NULL DEFAULT 9,
    `notification_minute` INTEGER NOT NULL DEFAULT 0,
    `is_enabled` INTEGER NOT NULL DEFAULT 1,
    `is_paid` INTEGER NOT NULL DEFAULT 0,
    `last_paid_date` INTEGER,
    `created_at` INTEGER NOT NULL,
    `updated_at` INTEGER NOT NULL
);
```
- **Indices**:
  - `CREATE INDEX IF NOT EXISTS index_reminders_due_date ON reminders(due_date);`
  - `CREATE INDEX IF NOT EXISTS index_reminders_is_enabled ON reminders(is_enabled);`
  - `CREATE INDEX IF NOT EXISTS index_reminders_type ON reminders(type);`

---

## 3. SQLite Pragmas & Connection Settings
To guarantee write performance, ACID guarantees, and database longevity:
```sql
PRAGMA foreign_keys = ON;
PRAGMA journal_mode = WAL;
PRAGMA synchronous = NORMAL;
PRAGMA busy_timeout = 5000;
```

