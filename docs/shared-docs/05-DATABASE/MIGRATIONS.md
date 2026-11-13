# Leaf Database: Complete Migration History & SQL Changelog

## 1. Executive Summary
This document provides the exhaustive, verified historical migration changelog for Leaf's SQLite database from **Schema Version 1 to Version 10**. 

For the new iOS application, starting directly at Schema Version 10 is recommended for fresh installs. However, this migration chronicle is critical for:
1. Ensuring complete schema fidelity between platforms.
2. Understanding default values, nullable fields, and legacy column additions.
3. Enabling cross-platform database import/export compatibility.

---

## 2. Migration Changelog (v1 to v10)

### 2.1 Version 1: Initial Baseline Schema
- Tables created: `transactions`, `categories`.
- Categories seeded with default 20 records.

---

### 2.2 Migration 1 -> 2: Introduction of Recurring Transactions
```sql
CREATE TABLE IF NOT EXISTS `recurring_transactions` (
    `id` INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
    `title` TEXT NOT NULL,
    `amount_subunits` INTEGER NOT NULL,
    `type` TEXT NOT NULL,
    `category_id` INTEGER NOT NULL,
    `note` TEXT,
    `frequency` TEXT NOT NULL,
    `day_of_month` INTEGER NOT NULL,
    `day_of_week` INTEGER NOT NULL,
    `start_date` INTEGER NOT NULL,
    `end_date` INTEGER,
    `is_enabled` INTEGER NOT NULL,
    `is_auto_generated` INTEGER NOT NULL,
    `reminder_days_before` INTEGER,
    `last_generated_date` INTEGER,
    `created_at` INTEGER NOT NULL,
    `updated_at` INTEGER NOT NULL,
    FOREIGN KEY(`category_id`) REFERENCES `categories`(`id`) ON UPDATE NO ACTION ON DELETE RESTRICT
);

CREATE INDEX IF NOT EXISTS `index_recurring_transactions_category_id` 
ON `recurring_transactions` (`category_id`);
```

---

### 2.3 Migration 2 -> 3: Payment Method Segregation
```sql
ALTER TABLE `transactions` ADD COLUMN `payment_method` TEXT NOT NULL DEFAULT 'CASH';
ALTER TABLE `recurring_transactions` ADD COLUMN `payment_method` TEXT NOT NULL DEFAULT 'CASH';
```

---

### 2.4 Migration 3 -> 4: Introduction of Split & Collect
```sql
CREATE TABLE IF NOT EXISTS `split_expenses` (
    `id` INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
    `title` TEXT NOT NULL,
    `total_amount_subunits` INTEGER NOT NULL,
    `date` INTEGER NOT NULL,
    `category_id` INTEGER NOT NULL,
    `paid_by` TEXT NOT NULL,
    `split_method` TEXT NOT NULL,
    `qr_image_path` TEXT,
    `created_at` INTEGER NOT NULL,
    `updated_at` INTEGER NOT NULL,
    FOREIGN KEY(`category_id`) REFERENCES `categories`(`id`) ON UPDATE NO ACTION ON DELETE RESTRICT
);

CREATE INDEX IF NOT EXISTS `index_split_expenses_category_id` 
ON `split_expenses` (`category_id`);

CREATE TABLE IF NOT EXISTS `split_participants` (
    `id` INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
    `split_expense_id` INTEGER NOT NULL,
    `name` TEXT NOT NULL,
    `is_current_user` INTEGER NOT NULL,
    `amount_subunits` INTEGER NOT NULL,
    `settlement_status` TEXT NOT NULL,
    `settled_at` INTEGER,
    FOREIGN KEY(`split_expense_id`) REFERENCES `split_expenses`(`id`) ON UPDATE NO ACTION ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS `index_split_participants_split_expense_id` 
ON `split_participants` (`split_expense_id`);
```

---

### 2.5 Migration 4 -> 5: Ledger Integration for Splits
```sql
ALTER TABLE `split_expenses` ADD COLUMN `add_to_transactions` INTEGER NOT NULL DEFAULT 0;
ALTER TABLE `split_expenses` ADD COLUMN `expense_transaction_id` INTEGER;
ALTER TABLE `split_expenses` ADD COLUMN `payment_method` TEXT NOT NULL DEFAULT 'CASH';
ALTER TABLE `split_participants` ADD COLUMN `settlement_transaction_id` INTEGER;
```

---

### 2.6 Migration 5 -> 6: Planning, Budgets, Savings Goals & Groups
```sql
-- 1. Budgets Table
CREATE TABLE `budgets` (
    `id` INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
    `category_id` INTEGER,
    `amount_subunits` INTEGER NOT NULL,
    `month` INTEGER NOT NULL,
    `year` INTEGER NOT NULL,
    `created_at` INTEGER NOT NULL,
    `updated_at` INTEGER NOT NULL,
    FOREIGN KEY(`category_id`) REFERENCES `categories`(`id`) ON UPDATE NO ACTION ON DELETE SET NULL
);

CREATE INDEX `index_budgets_year_month` ON `budgets` (`year`, `month`);
CREATE INDEX `index_budgets_category_id` ON `budgets` (`category_id`);

-- 2. Savings Goals Table
CREATE TABLE `savings_goals` (
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

-- 3. Savings Goal Contributions Table
CREATE TABLE `savings_goal_contributions` (
    `id` INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
    `goal_id` INTEGER NOT NULL,
    `amount_subunits` INTEGER NOT NULL,
    `note` TEXT,
    `timestamp` INTEGER NOT NULL,
    `created_at` INTEGER NOT NULL,
    FOREIGN KEY(`goal_id`) REFERENCES `savings_goals`(`id`) ON UPDATE NO ACTION ON DELETE CASCADE
);

CREATE INDEX `index_savings_goal_contributions_goal_id` 
ON `savings_goal_contributions` (`goal_id`);

-- 4. Split Groups Table
CREATE TABLE `split_groups` (
    `id` INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
    `name` TEXT NOT NULL,
    `icon_name` TEXT NOT NULL DEFAULT 'group',
    `color_hex` TEXT NOT NULL DEFAULT '#3B82F6',
    `created_at` INTEGER NOT NULL
);

-- 5. Add group_id to split_expenses
ALTER TABLE `split_expenses` ADD COLUMN `group_id` INTEGER REFERENCES `split_groups`(`id`) ON DELETE SET NULL;
CREATE INDEX `index_split_expenses_group_id` ON `split_expenses` (`group_id`);
```

---

### 2.7 Migration 6 -> 7: Budget Index Adjustments
```sql
DROP INDEX IF EXISTS `index_budgets_overall_unique`;
DROP INDEX IF EXISTS `index_budgets_category_unique`;
```

---

### 2.8 Migration 7 -> 8: Contribution to Ledger Integration
```sql
ALTER TABLE `savings_goal_contributions` 
ADD COLUMN `transaction_id` INTEGER REFERENCES `transactions`(`id`) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS `index_savings_goal_contributions_transaction_id` 
ON `savings_goal_contributions` (`transaction_id`);
```

---

### 2.9 Migration 8 -> 9: Financial Calendar Reminders
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

CREATE INDEX IF NOT EXISTS `index_reminders_due_date` ON `reminders` (`due_date`);
CREATE INDEX IF NOT EXISTS `index_reminders_is_enabled` ON `reminders` (`is_enabled`);
CREATE INDEX IF NOT EXISTS `index_reminders_type` ON `reminders` (`type`);
```

---

### 2.10 Migration 9 -> 10: Split 2.0 Itemization & Phone Numbers
```sql
ALTER TABLE `split_participants` ADD COLUMN `phone_number` TEXT;
ALTER TABLE `split_expenses` ADD COLUMN `items_json` TEXT;
```

---

## 3. iOS Clean Build Recommendation
For the native iOS project:
- Create the final **Version 10** database schema directly in the initial database creation script or Core Data / SwiftData model definition.
- There is no need to execute migrations 1 through 9 sequentially on a fresh iOS install.
- If importing an existing SQLite database file from an Android backup, the schema version pragma (`PRAGMA user_version;`) must be set to `10`.

