import Foundation
import GRDB

public enum DatabaseMigrations {

    public static var migrator: DatabaseMigrator {
        var migrator = DatabaseMigrator()

        #if DEBUG
        // Speed up development by wiping database when migrations change in debug
        // migrator.eraseDatabaseOnSchemaChange = true
        #endif

        // MARK: - Migration 1: Initial Schema (categories, transactions)
        migrator.registerMigration("v1") { db in
            try db.execute(sql: """
                CREATE TABLE IF NOT EXISTS categories (
                    id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
                    name TEXT NOT NULL,
                    icon_name TEXT NOT NULL,
                    color_hex TEXT NOT NULL,
                    type TEXT NOT NULL,
                    is_default INTEGER NOT NULL DEFAULT 0
                );

                CREATE TABLE IF NOT EXISTS transactions (
                    id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
                    amount_subunits INTEGER NOT NULL,
                    type TEXT NOT NULL,
                    category_id INTEGER NOT NULL,
                    note TEXT,
                    timestamp INTEGER NOT NULL,
                    created_at INTEGER NOT NULL,
                    updated_at INTEGER NOT NULL,
                    FOREIGN KEY(category_id) REFERENCES categories(id) ON UPDATE NO ACTION ON DELETE RESTRICT
                );

                CREATE INDEX IF NOT EXISTS index_transactions_category_id ON transactions (category_id);
                CREATE INDEX IF NOT EXISTS index_transactions_timestamp ON transactions (timestamp);
                CREATE INDEX IF NOT EXISTS index_transactions_type ON transactions (type);
            """)

            // Seed initial 20 categories
            for cat in CategorySeeds.defaultCategories {
                try db.execute(
                    sql: "INSERT INTO categories (name, icon_name, color_hex, type, is_default) VALUES (?, ?, ?, ?, 1)",
                    arguments: [cat.name, cat.iconName, cat.colorHex, cat.type]
                )
            }
        }

        // MARK: - Migration 2: Recurring Transactions
        migrator.registerMigration("v2") { db in
            try db.execute(sql: """
                CREATE TABLE IF NOT EXISTS recurring_transactions (
                    id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
                    title TEXT NOT NULL,
                    amount_subunits INTEGER NOT NULL,
                    type TEXT NOT NULL,
                    category_id INTEGER NOT NULL,
                    note TEXT,
                    frequency TEXT NOT NULL,
                    day_of_month INTEGER NOT NULL,
                    day_of_week INTEGER NOT NULL,
                    start_date INTEGER NOT NULL,
                    end_date INTEGER,
                    is_enabled INTEGER NOT NULL,
                    is_auto_generated INTEGER NOT NULL,
                    reminder_days_before INTEGER,
                    last_generated_date INTEGER,
                    created_at INTEGER NOT NULL,
                    updated_at INTEGER NOT NULL,
                    FOREIGN KEY(category_id) REFERENCES categories(id) ON UPDATE NO ACTION ON DELETE RESTRICT
                );

                CREATE INDEX IF NOT EXISTS index_recurring_transactions_category_id ON recurring_transactions (category_id);
            """)
        }

        // MARK: - Migration 3: Payment Method
        migrator.registerMigration("v3") { db in
            try db.execute(sql: """
                ALTER TABLE transactions ADD COLUMN payment_method TEXT NOT NULL DEFAULT 'CASH';
                ALTER TABLE recurring_transactions ADD COLUMN payment_method TEXT NOT NULL DEFAULT 'CASH';
            """)
        }

        // MARK: - Migration 4: Split Expenses & Participants
        migrator.registerMigration("v4") { db in
            try db.execute(sql: """
                CREATE TABLE IF NOT EXISTS split_expenses (
                    id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
                    title TEXT NOT NULL,
                    total_amount_subunits INTEGER NOT NULL,
                    date INTEGER NOT NULL,
                    category_id INTEGER NOT NULL,
                    paid_by TEXT NOT NULL,
                    split_method TEXT NOT NULL,
                    qr_image_path TEXT,
                    created_at INTEGER NOT NULL,
                    updated_at INTEGER NOT NULL,
                    FOREIGN KEY(category_id) REFERENCES categories(id) ON UPDATE NO ACTION ON DELETE RESTRICT
                );

                CREATE INDEX IF NOT EXISTS index_split_expenses_category_id ON split_expenses (category_id);

                CREATE TABLE IF NOT EXISTS split_participants (
                    id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
                    split_expense_id INTEGER NOT NULL,
                    name TEXT NOT NULL,
                    is_current_user INTEGER NOT NULL,
                    amount_subunits INTEGER NOT NULL,
                    settlement_status TEXT NOT NULL,
                    settled_at INTEGER,
                    FOREIGN KEY(split_expense_id) REFERENCES split_expenses(id) ON UPDATE NO ACTION ON DELETE CASCADE
                );

                CREATE INDEX IF NOT EXISTS index_split_participants_split_expense_id ON split_participants (split_expense_id);
            """)
        }

        // MARK: - Migration 5: Split Enhancements
        migrator.registerMigration("v5") { db in
            try db.execute(sql: """
                ALTER TABLE split_expenses ADD COLUMN add_to_transactions INTEGER NOT NULL DEFAULT 0;
                ALTER TABLE split_expenses ADD COLUMN expense_transaction_id INTEGER;
                ALTER TABLE split_expenses ADD COLUMN payment_method TEXT NOT NULL DEFAULT 'CASH';
                ALTER TABLE split_participants ADD COLUMN settlement_transaction_id INTEGER;
            """)
        }

        // MARK: - Migration 6: Budgets, Goals, Groups
        migrator.registerMigration("v6") { db in
            try db.execute(sql: """
                CREATE TABLE IF NOT EXISTS budgets (
                    id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
                    category_id INTEGER,
                    amount_subunits INTEGER NOT NULL,
                    month INTEGER NOT NULL,
                    year INTEGER NOT NULL,
                    created_at INTEGER NOT NULL,
                    updated_at INTEGER NOT NULL,
                    FOREIGN KEY(category_id) REFERENCES categories(id) ON UPDATE NO ACTION ON DELETE SET NULL
                );

                CREATE INDEX IF NOT EXISTS index_budgets_year_month ON budgets (year, month);
                CREATE INDEX IF NOT EXISTS index_budgets_category_id ON budgets (category_id);

                CREATE TABLE IF NOT EXISTS savings_goals (
                    id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
                    name TEXT NOT NULL,
                    target_amount_subunits INTEGER NOT NULL,
                    target_date INTEGER,
                    note TEXT,
                    icon_name TEXT NOT NULL DEFAULT 'savings',
                    color_hex TEXT NOT NULL DEFAULT '#10B981',
                    is_archived INTEGER NOT NULL DEFAULT 0,
                    created_at INTEGER NOT NULL,
                    updated_at INTEGER NOT NULL
                );

                CREATE TABLE IF NOT EXISTS savings_goal_contributions (
                    id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
                    goal_id INTEGER NOT NULL,
                    amount_subunits INTEGER NOT NULL,
                    note TEXT,
                    timestamp INTEGER NOT NULL,
                    created_at INTEGER NOT NULL,
                    FOREIGN KEY(goal_id) REFERENCES savings_goals(id) ON UPDATE NO ACTION ON DELETE CASCADE
                );

                CREATE INDEX IF NOT EXISTS index_savings_goal_contributions_goal_id ON savings_goal_contributions (goal_id);

                CREATE TABLE IF NOT EXISTS split_groups (
                    id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
                    name TEXT NOT NULL,
                    icon_name TEXT NOT NULL DEFAULT 'group',
                    color_hex TEXT NOT NULL DEFAULT '#3B82F6',
                    created_at INTEGER NOT NULL
                );

                ALTER TABLE split_expenses ADD COLUMN group_id INTEGER REFERENCES split_groups(id) ON DELETE SET NULL;
                CREATE INDEX IF NOT EXISTS index_split_expenses_group_id ON split_expenses (group_id);
            """)
        }

        // MARK: - Migration 7: Drop Unique Indexes on Budgets
        migrator.registerMigration("v7") { db in
            try db.execute(sql: """
                DROP INDEX IF EXISTS index_budgets_overall_unique;
                DROP INDEX IF EXISTS index_budgets_category_unique;
            """)
        }

        // MARK: - Migration 8: Link Savings Goal Contributions to Transactions
        migrator.registerMigration("v8") { db in
            try db.execute(sql: """
                ALTER TABLE savings_goal_contributions ADD COLUMN transaction_id INTEGER REFERENCES transactions(id) ON DELETE SET NULL;
                CREATE INDEX IF NOT EXISTS index_savings_goal_contributions_transaction_id ON savings_goal_contributions (transaction_id);
            """)
        }

        // MARK: - Migration 9: Reminders Table
        migrator.registerMigration("v9") { db in
            try db.execute(sql: """
                CREATE TABLE IF NOT EXISTS reminders (
                    id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
                    title TEXT NOT NULL,
                    description TEXT,
                    amount_subunits INTEGER NOT NULL,
                    type TEXT NOT NULL,
                    due_date INTEGER NOT NULL,
                    recurrence TEXT NOT NULL,
                    configured_day_of_month INTEGER NOT NULL DEFAULT 1,
                    reminder_offset_days INTEGER NOT NULL DEFAULT 1,
                    additional_offsets TEXT,
                    notification_hour INTEGER NOT NULL DEFAULT 9,
                    notification_minute INTEGER NOT NULL DEFAULT 0,
                    is_enabled INTEGER NOT NULL DEFAULT 1,
                    is_paid INTEGER NOT NULL DEFAULT 0,
                    last_paid_date INTEGER,
                    created_at INTEGER NOT NULL,
                    updated_at INTEGER NOT NULL
                );

                CREATE INDEX IF NOT EXISTS index_reminders_due_date ON reminders (due_date);
                CREATE INDEX IF NOT EXISTS index_reminders_is_enabled ON reminders (is_enabled);
                CREATE INDEX IF NOT EXISTS index_reminders_type ON reminders (type);
            """)
        }

        // MARK: - Migration 10: Phone Number & Itemized JSON
        migrator.registerMigration("v10") { db in
            try db.execute(sql: """
                ALTER TABLE split_participants ADD COLUMN phone_number TEXT;
                ALTER TABLE split_expenses ADD COLUMN items_json TEXT;
            """)
        }

        // MARK: - Migration 11: Partial Settlements & Payment History
        migrator.registerMigration("v11") { db in
            try db.execute(sql: """
                CREATE TABLE IF NOT EXISTS split_payments (
                    id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
                    split_expense_id INTEGER NOT NULL,
                    participant_id INTEGER NOT NULL,
                    amount_subunits INTEGER NOT NULL,
                    date INTEGER NOT NULL,
                    payment_method TEXT NOT NULL DEFAULT 'CASH',
                    note TEXT,
                    transaction_id INTEGER,
                    created_at INTEGER NOT NULL,
                    FOREIGN KEY(split_expense_id) REFERENCES split_expenses(id) ON UPDATE NO ACTION ON DELETE CASCADE,
                    FOREIGN KEY(participant_id) REFERENCES split_participants(id) ON UPDATE NO ACTION ON DELETE CASCADE,
                    FOREIGN KEY(transaction_id) REFERENCES transactions(id) ON UPDATE NO ACTION ON DELETE SET NULL
                );

                CREATE INDEX IF NOT EXISTS index_split_payments_participant_id ON split_payments (participant_id);
                CREATE INDEX IF NOT EXISTS index_split_payments_split_expense_id ON split_payments (split_expense_id);
                CREATE INDEX IF NOT EXISTS index_split_payments_transaction_id ON split_payments (transaction_id);
            """)
        }

        // MARK: - Migration 12: Budget Periods & Recurrence
        migrator.registerMigration("v12") { db in
            try db.execute(sql: """
                ALTER TABLE budgets ADD COLUMN period_type TEXT NOT NULL DEFAULT 'MONTHLY';
                ALTER TABLE budgets ADD COLUMN start_date INTEGER;
                ALTER TABLE budgets ADD COLUMN end_date INTEGER;
                ALTER TABLE budgets ADD COLUMN is_recurring INTEGER NOT NULL DEFAULT 0;
            """)
        }

        // MARK: - Migration 13: Internal Transfer Flag for Transactions
        migrator.registerMigration("v13") { db in
            try db.execute(sql: """
                ALTER TABLE transactions ADD COLUMN is_internal_transfer INTEGER NOT NULL DEFAULT 0;
                CREATE INDEX IF NOT EXISTS index_transactions_is_internal_transfer ON transactions (is_internal_transfer);
            """)

            // Backfill previously created savings deposits and withdrawals as internal transfers
            try db.execute(sql: """
                UPDATE transactions
                SET is_internal_transfer = 1
                WHERE id IN (
                    SELECT transaction_id FROM savings_goal_contributions WHERE transaction_id IS NOT NULL
                )
                OR note LIKE 'Savings:%'
                OR note LIKE 'Savings Withdrawal:%';
            """)
        }

        // MARK: - Migration 14: Statements Metadata & Export History
        migrator.registerMigration("v14") { db in
            try db.execute(sql: """
                CREATE TABLE IF NOT EXISTS statements (
                    id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
                    title TEXT NOT NULL,
                    period_type TEXT NOT NULL,
                    start_date INTEGER NOT NULL,
                    end_date INTEGER NOT NULL,
                    format TEXT NOT NULL,
                    file_path TEXT NOT NULL,
                    file_size INTEGER NOT NULL DEFAULT 0,
                    total_income_subunits INTEGER NOT NULL DEFAULT 0,
                    total_expense_subunits INTEGER NOT NULL DEFAULT 0,
                    operating_cashflow_subunits INTEGER NOT NULL DEFAULT 0,
                    transaction_count INTEGER NOT NULL DEFAULT 0,
                    generated_at INTEGER NOT NULL
                );

                CREATE INDEX IF NOT EXISTS index_statements_generated_at ON statements (generated_at);
                CREATE INDEX IF NOT EXISTS index_statements_period_type ON statements (period_type);
            """)
        }

        // MARK: - Migration 15: Recurring Transactions Enhancements & Occurrences Ledger
        migrator.registerMigration("v15") { db in
            // 1. Link transactions back to originating recurring schedules
            try db.execute(sql: """
                ALTER TABLE transactions ADD COLUMN recurring_transaction_id INTEGER REFERENCES recurring_transactions(id) ON DELETE SET NULL;
                CREATE INDEX IF NOT EXISTS index_transactions_recurring_transaction_id ON transactions (recurring_transaction_id);
            """)

            // 2. Enhance recurring_transactions table
            try db.execute(sql: """
                ALTER TABLE recurring_transactions ADD COLUMN status TEXT NOT NULL DEFAULT 'ACTIVE';
                ALTER TABLE recurring_transactions ADD COLUMN recurrence_interval INTEGER NOT NULL DEFAULT 1;
                ALTER TABLE recurring_transactions ADD COLUMN is_subscription INTEGER NOT NULL DEFAULT 0;
            """)

            // 3. Create persistent recurring_transaction_occurrences ledger table
            try db.execute(sql: """
                CREATE TABLE IF NOT EXISTS recurring_transaction_occurrences (
                    id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
                    recurring_transaction_id INTEGER NOT NULL,
                    scheduled_date INTEGER NOT NULL,
                    due_date INTEGER NOT NULL,
                    amount_subunits INTEGER NOT NULL,
                    status TEXT NOT NULL,
                    transaction_id INTEGER,
                    paid_at INTEGER,
                    snoozed_until INTEGER,
                    created_at INTEGER NOT NULL,
                    updated_at INTEGER NOT NULL,
                    FOREIGN KEY(recurring_transaction_id) REFERENCES recurring_transactions(id) ON UPDATE NO ACTION ON DELETE CASCADE,
                    FOREIGN KEY(transaction_id) REFERENCES transactions(id) ON UPDATE NO ACTION ON DELETE SET NULL
                );

                CREATE UNIQUE INDEX IF NOT EXISTS index_recurring_occurrences_unique
                ON recurring_transaction_occurrences (recurring_transaction_id, scheduled_date);

                CREATE INDEX IF NOT EXISTS index_recurring_occurrences_status ON recurring_transaction_occurrences (status);
                CREATE INDEX IF NOT EXISTS index_recurring_occurrences_due_date ON recurring_transaction_occurrences (due_date);
                CREATE INDEX IF NOT EXISTS index_recurring_occurrences_transaction_id ON recurring_transaction_occurrences (transaction_id);
                CREATE INDEX IF NOT EXISTS index_recurring_occurrences_recurring_id ON recurring_transaction_occurrences (recurring_transaction_id);
            """)
        }

        // MARK: - Migration 16: Receipt Image Attachment for Transactions
        migrator.registerMigration("v16") { db in
            try db.execute(sql: """
                ALTER TABLE transactions ADD COLUMN receipt_image_path TEXT;
            """)
        }

        // MARK: - Migration 17: Multi-Currency Support, Exchange Rates & Travel Wallets
        migrator.registerMigration("v17") { db in
            // 1. Create exchange_rates table
            try db.execute(sql: """
                CREATE TABLE IF NOT EXISTS exchange_rates (
                    id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
                    base_currency_code TEXT NOT NULL,
                    target_currency_code TEXT NOT NULL,
                    rate REAL NOT NULL,
                    effective_date INTEGER NOT NULL,
                    source TEXT NOT NULL DEFAULT 'MANUAL',
                    created_at INTEGER NOT NULL
                );
                CREATE INDEX IF NOT EXISTS index_exchange_rates_base_target ON exchange_rates (base_currency_code, target_currency_code);
                CREATE INDEX IF NOT EXISTS index_exchange_rates_effective ON exchange_rates (effective_date);
            """)

            // 2. Create travel_wallets table
            try db.execute(sql: """
                CREATE TABLE IF NOT EXISTS travel_wallets (
                    id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
                    name TEXT NOT NULL,
                    currency_code TEXT NOT NULL,
                    budget_amount_subunits INTEGER,
                    note TEXT,
                    color_hex TEXT NOT NULL DEFAULT '#10B981',
                    icon_name TEXT NOT NULL DEFAULT 'airplane',
                    is_archived INTEGER NOT NULL DEFAULT 0,
                    created_at INTEGER NOT NULL,
                    updated_at INTEGER NOT NULL
                );
                CREATE INDEX IF NOT EXISTS index_travel_wallets_archived ON travel_wallets (is_archived);
            """)

            // 3. Extend transactions table with multi-currency fields and wallet foreign key
            try db.execute(sql: """
                ALTER TABLE transactions ADD COLUMN original_amount_subunits INTEGER;
                ALTER TABLE transactions ADD COLUMN currency_code TEXT NOT NULL DEFAULT 'INR';
                ALTER TABLE transactions ADD COLUMN exchange_rate REAL NOT NULL DEFAULT 1.0;
                ALTER TABLE transactions ADD COLUMN exchange_rate_date INTEGER;
                ALTER TABLE transactions ADD COLUMN exchange_rate_source TEXT NOT NULL DEFAULT 'PRIMARY';
                ALTER TABLE transactions ADD COLUMN travel_wallet_id INTEGER REFERENCES travel_wallets(id) ON DELETE SET NULL;
                CREATE INDEX IF NOT EXISTS index_transactions_travel_wallet_id ON transactions (travel_wallet_id);
                CREATE INDEX IF NOT EXISTS index_transactions_currency_code ON transactions (currency_code);
            """)

            // 4. Backfill existing transactions: original_amount equals existing amount_subunits
            try db.execute(sql: """
                UPDATE transactions
                SET original_amount_subunits = amount_subunits
                WHERE original_amount_subunits IS NULL;
            """)

            // 5. Extend split_expenses table with multi-currency fields
            try db.execute(sql: """
                ALTER TABLE split_expenses ADD COLUMN currency_code TEXT NOT NULL DEFAULT 'INR';
                ALTER TABLE split_expenses ADD COLUMN exchange_rate REAL NOT NULL DEFAULT 1.0;
                ALTER TABLE split_expenses ADD COLUMN primary_total_amount_subunits INTEGER NOT NULL DEFAULT 0;
            """)

            try db.execute(sql: """
                UPDATE split_expenses
                SET primary_total_amount_subunits = total_amount_subunits
                WHERE primary_total_amount_subunits = 0;
            """)

            // 6. Seed initial common exchange rates to INR
            let now = Int64(Date().timeIntervalSince1970 * 1000)
            let defaultRates: [(String, Double)] = [
                ("USD", 83.50),
                ("EUR", 90.20),
                ("GBP", 105.80),
                ("AED", 22.75),
                ("SGD", 62.10),
                ("AUD", 54.30),
                ("CAD", 61.20),
                ("JPY", 0.55),
                ("CHF", 93.40),
                ("CNY", 11.50)
            ]

            for (curr, r) in defaultRates {
                try db.execute(
                    sql: """
                    INSERT INTO exchange_rates (base_currency_code, target_currency_code, rate, effective_date, source, created_at)
                    VALUES (?, 'INR', ?, ?, 'CACHED', ?)
                    """,
                    arguments: [curr, r, now, now]
                )
            }
        }

        // MARK: - Migration 18: Separate Cash and Account Ledgers & Indexes
        migrator.registerMigration("v18") { db in
            // 1. Safe schema extension: preserve historical original payment method before normalization
            let tableInfo = try Row.fetchAll(db, sql: "PRAGMA table_info(transactions)")
            let columnNames = Set(tableInfo.compactMap { $0["name"] as String? })

            if !columnNames.contains("raw_payment_method") {
                try db.execute(sql: "ALTER TABLE transactions ADD COLUMN raw_payment_method TEXT;")
                try db.execute(sql: "UPDATE transactions SET raw_payment_method = payment_method WHERE raw_payment_method IS NULL;")
            }

            // 2. Atomic transfer pairing column
            if !columnNames.contains("transfer_pair_id") {
                try db.execute(sql: "ALTER TABLE transactions ADD COLUMN transfer_pair_id INTEGER;")
                try db.execute(sql: "CREATE INDEX IF NOT EXISTS index_transactions_transfer_pair_id ON transactions (transfer_pair_id);")
            }

            // 3. Map explicitly recognized electronic/account methods to 'ACCOUNT'
            try db.execute(sql: """
                UPDATE transactions
                SET payment_method = 'ACCOUNT'
                WHERE UPPER(payment_method) IN ('ACCOUNT', 'BANK_ACCOUNT', 'UPI', 'BANK', 'CARD', 'NET_BANKING', 'ONLINE');
            """)

            // 4. Map explicitly recognized cash methods to 'CASH'
            try db.execute(sql: """
                UPDATE transactions
                SET payment_method = 'CASH'
                WHERE UPPER(payment_method) = 'CASH';
            """)

            // NOTE: Unknown payment methods (e.g. CHEQUE, WALLET, custom methods) and NULL values
            // are strictly preserved in their original form and never automatically converted to CASH.

            // 5. High-speed ledger indexes for independent accounting
            try db.execute(sql: """
                CREATE INDEX IF NOT EXISTS index_transactions_payment_method ON transactions (payment_method);
                CREATE INDEX IF NOT EXISTS index_transactions_type_payment_method ON transactions (type, payment_method);
                CREATE INDEX IF NOT EXISTS index_transactions_pm_timestamp ON transactions (payment_method, timestamp);
            """)

            // 6. Backfill transfer_pair_id for existing internal transfers
            try db.execute(sql: """
                UPDATE transactions
                SET transfer_pair_id = (
                    SELECT t2.id FROM transactions t2
                    WHERE t2.is_internal_transfer = 1
                      AND t2.id != transactions.id
                      AND t2.type != transactions.type
                      AND t2.amount_subunits = transactions.amount_subunits
                      AND ABS(t2.timestamp - transactions.timestamp) <= 2000
                    LIMIT 1
                )
                WHERE is_internal_transfer = 1 AND transfer_pair_id IS NULL;
            """)
        }

        return migrator
    }
}

