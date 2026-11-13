# Leaf Database: Entity-Relationship Diagram (ERD)

## 1. Executive Summary
This document provides the visual and structural Entity-Relationship Diagram (ERD) representing all 10 tables in Leaf's SQLite schema at Version 10.

---

## 2. Complete Mermaid ER Diagram

```mermaid
erDiagram
    CATEGORIES {
        INTEGER id PK
        TEXT name
        TEXT icon_name
        TEXT color_hex
        TEXT type
        INTEGER is_default
    }

    TRANSACTIONS {
        INTEGER id PK
        INTEGER amount_subunits
        TEXT type
        INTEGER category_id FK
        TEXT payment_method
        TEXT note
        INTEGER timestamp
        INTEGER created_at
        INTEGER updated_at
    }

    RECURRING_TRANSACTIONS {
        INTEGER id PK
        TEXT title
        INTEGER amount_subunits
        TEXT type
        INTEGER category_id FK
        TEXT payment_method
        TEXT note
        TEXT frequency
        INTEGER day_of_month
        INTEGER day_of_week
        INTEGER start_date
        INTEGER end_date
        INTEGER is_enabled
        INTEGER is_auto_generated
        INTEGER reminder_days_before
        INTEGER last_generated_date
        INTEGER created_at
        INTEGER updated_at
    }

    SPLIT_GROUPS {
        INTEGER id PK
        TEXT name
        TEXT icon_name
        TEXT color_hex
        INTEGER created_at
    }

    SPLIT_EXPENSES {
        INTEGER id PK
        TEXT title
        INTEGER total_amount_subunits
        INTEGER date
        INTEGER category_id FK
        TEXT paid_by
        TEXT split_method
        TEXT qr_image_path
        INTEGER add_to_transactions
        INTEGER expense_transaction_id FK
        TEXT payment_method
        INTEGER group_id FK
        INTEGER created_at
        INTEGER updated_at
        TEXT items_json
    }

    SPLIT_PARTICIPANTS {
        INTEGER id PK
        INTEGER split_expense_id FK
        TEXT name
        INTEGER is_current_user
        INTEGER amount_subunits
        TEXT settlement_status
        INTEGER settled_at
        INTEGER settlement_transaction_id FK
        TEXT phone_number
    }

    BUDGETS {
        INTEGER id PK
        INTEGER category_id FK
        INTEGER amount_subunits
        INTEGER month
        INTEGER year
        INTEGER created_at
        INTEGER updated_at
    }

    SAVINGS_GOALS {
        INTEGER id PK
        TEXT name
        INTEGER target_amount_subunits
        INTEGER target_date
        TEXT note
        TEXT icon_name
        TEXT color_hex
        INTEGER is_archived
        INTEGER created_at
        INTEGER updated_at
    }

    SAVINGS_GOAL_CONTRIBUTIONS {
        INTEGER id PK
        INTEGER goal_id FK
        INTEGER amount_subunits
        TEXT note
        INTEGER timestamp
        INTEGER transaction_id FK
        INTEGER created_at
    }

    REMINDERS {
        INTEGER id PK
        TEXT title
        TEXT description
        INTEGER amount_subunits
        TEXT type
        INTEGER due_date
        TEXT recurrence
        INTEGER configured_day_of_month
        INTEGER reminder_offset_days
        TEXT additional_offsets
        INTEGER notification_hour
        INTEGER notification_minute
        INTEGER is_enabled
        INTEGER is_paid
        INTEGER last_paid_date
        INTEGER created_at
        INTEGER updated_at
    }

    CATEGORIES ||--o{ TRANSACTIONS : "classifies (RESTRICT)"
    CATEGORIES ||--o{ RECURRING_TRANSACTIONS : "classifies (RESTRICT)"
    CATEGORIES ||--o{ SPLIT_EXPENSES : "categorizes (RESTRICT)"
    CATEGORIES ||--o{ BUDGETS : "limits (SET NULL)"

    SPLIT_GROUPS ||--o{ SPLIT_EXPENSES : "groups (SET NULL)"
    SPLIT_EXPENSES ||--|{ SPLIT_PARTICIPANTS : "divides into (CASCADE)"
    
    SAVINGS_GOALS ||--o{ SAVINGS_GOAL_CONTRIBUTIONS : "receives (CASCADE)"
    TRANSACTIONS ||--o{ SAVINGS_GOAL_CONTRIBUTIONS : "funds (SET NULL)"

    TRANSACTIONS ||--o{ SPLIT_EXPENSES : "soft linked expense"
    TRANSACTIONS ||--o{ SPLIT_PARTICIPANTS : "soft linked settlement"
```

---

## 3. Structural Analysis & Integrity Highlights

1. **Category Centrality**:
   The `CATEGORIES` entity forms the semantic core of the application, linked via restricted foreign keys to `transactions`, `recurring_transactions`, and `split_expenses`.
2. **Double Ledger Linkage**:
   The diagram highlights the dual relationship between `TRANSACTIONS` and the Split module:
   - Outflow link: `SPLIT_EXPENSES.expense_transaction_id` tracks the payer's initial outlay.
   - Inflow link: `SPLIT_PARTICIPANTS.settlement_transaction_id` tracks participant repayments.
3. **Decoupled Standalone Modules**:
   - `REMINDERS` is intentionally decoupled from transactional tables, allowing lightweight schedule evaluation without locking transaction tables.
   - `SAVINGS_GOALS` maintains its own historical contribution ledger (`savings_goal_contributions`), with optional soft links to `transactions`.

