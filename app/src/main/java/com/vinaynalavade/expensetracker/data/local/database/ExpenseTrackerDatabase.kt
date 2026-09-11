package com.vinaynalavade.expensetracker.data.local.database

import android.content.Context
import androidx.room.Database
import androidx.room.Room
import androidx.room.RoomDatabase
import androidx.room.migration.Migration
import androidx.sqlite.db.SupportSQLiteDatabase
import com.vinaynalavade.expensetracker.core.constants.AppConstants
import com.vinaynalavade.expensetracker.data.local.dao.BudgetDao
import com.vinaynalavade.expensetracker.data.local.dao.CategoryDao
import com.vinaynalavade.expensetracker.data.local.dao.RecurringTransactionDao
import com.vinaynalavade.expensetracker.data.local.dao.SavingsGoalDao
import com.vinaynalavade.expensetracker.data.local.dao.SplitDao
import com.vinaynalavade.expensetracker.data.local.dao.SplitGroupDao
import com.vinaynalavade.expensetracker.data.local.dao.TransactionDao
import com.vinaynalavade.expensetracker.data.local.entity.BudgetEntity
import com.vinaynalavade.expensetracker.data.local.entity.CategoryEntity
import com.vinaynalavade.expensetracker.data.local.entity.RecurringTransactionEntity
import com.vinaynalavade.expensetracker.data.local.entity.SavingsGoalContributionEntity
import com.vinaynalavade.expensetracker.data.local.entity.SavingsGoalEntity
import com.vinaynalavade.expensetracker.data.local.entity.SplitExpenseEntity
import com.vinaynalavade.expensetracker.data.local.entity.SplitGroupEntity
import com.vinaynalavade.expensetracker.data.local.entity.SplitParticipantEntity
import com.vinaynalavade.expensetracker.data.local.entity.TransactionEntity

@Database(
    entities = [
        TransactionEntity::class,
        CategoryEntity::class,
        RecurringTransactionEntity::class,
        SplitExpenseEntity::class,
        SplitParticipantEntity::class,
        SplitGroupEntity::class,
        BudgetEntity::class,
        SavingsGoalEntity::class,
        SavingsGoalContributionEntity::class
    ],
    version = 6,
    exportSchema = false
)
abstract class ExpenseTrackerDatabase : RoomDatabase() {

    abstract fun transactionDao(): TransactionDao
    abstract fun categoryDao(): CategoryDao
    abstract fun recurringTransactionDao(): RecurringTransactionDao
    abstract fun splitDao(): SplitDao
    abstract fun splitGroupDao(): SplitGroupDao
    abstract fun budgetDao(): BudgetDao
    abstract fun savingsGoalDao(): SavingsGoalDao

    companion object {
        @Volatile
        private var INSTANCE: ExpenseTrackerDatabase? = null

        val MIGRATION_1_2 = object : Migration(1, 2) {
            override fun migrate(db: SupportSQLiteDatabase) {
                db.execSQL("""
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
                    )
                """)
                db.execSQL("CREATE INDEX IF NOT EXISTS `index_recurring_transactions_category_id` ON `recurring_transactions` (`category_id`)")
            }
        }

        val MIGRATION_2_3 = object : Migration(2, 3) {
            override fun migrate(db: SupportSQLiteDatabase) {
                db.execSQL("ALTER TABLE `transactions` ADD COLUMN `payment_method` TEXT NOT NULL DEFAULT 'CASH'")
                db.execSQL("ALTER TABLE `recurring_transactions` ADD COLUMN `payment_method` TEXT NOT NULL DEFAULT 'CASH'")
            }
        }

        val MIGRATION_3_4 = object : Migration(3, 4) {
            override fun migrate(db: SupportSQLiteDatabase) {
                db.execSQL("""
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
                    )
                """)
                db.execSQL("CREATE INDEX IF NOT EXISTS `index_split_expenses_category_id` ON `split_expenses` (`category_id`)")

                db.execSQL("""
                    CREATE TABLE IF NOT EXISTS `split_participants` (
                        `id` INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
                        `split_expense_id` INTEGER NOT NULL,
                        `name` TEXT NOT NULL,
                        `is_current_user` INTEGER NOT NULL,
                        `amount_subunits` INTEGER NOT NULL,
                        `settlement_status` TEXT NOT NULL,
                        `settled_at` INTEGER,
                        FOREIGN KEY(`split_expense_id`) REFERENCES `split_expenses`(`id`) ON UPDATE NO ACTION ON DELETE CASCADE
                    )
                """)
                db.execSQL("CREATE INDEX IF NOT EXISTS `index_split_participants_split_expense_id` ON `split_participants` (`split_expense_id`)")
            }
        }

        val MIGRATION_4_5 = object : Migration(4, 5) {
            override fun migrate(db: SupportSQLiteDatabase) {
                db.execSQL("ALTER TABLE `split_expenses` ADD COLUMN `add_to_transactions` INTEGER NOT NULL DEFAULT 0")
                db.execSQL("ALTER TABLE `split_expenses` ADD COLUMN `expense_transaction_id` INTEGER")
                db.execSQL("ALTER TABLE `split_expenses` ADD COLUMN `payment_method` TEXT NOT NULL DEFAULT 'CASH'")
                db.execSQL("ALTER TABLE `split_participants` ADD COLUMN `settlement_transaction_id` INTEGER")
            }
        }

        val MIGRATION_5_6 = object : Migration(5, 6) {
            override fun migrate(db: SupportSQLiteDatabase) {
                // 1. Budgets Table (Strict CREATE TABLE)
                db.execSQL("""
                    CREATE TABLE `budgets` (
                        `id` INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
                        `category_id` INTEGER,
                        `amount_subunits` INTEGER NOT NULL,
                        `month` INTEGER NOT NULL,
                        `year` INTEGER NOT NULL,
                        `created_at` INTEGER NOT NULL,
                        `updated_at` INTEGER NOT NULL,
                        FOREIGN KEY(`category_id`) REFERENCES `categories`(`id`) ON UPDATE NO ACTION ON DELETE SET NULL
                    )
                """)
                db.execSQL("CREATE INDEX `index_budgets_year_month` ON `budgets` (`year`, `month`)")
                db.execSQL("CREATE INDEX `index_budgets_category_id` ON `budgets` (`category_id`)")
                db.execSQL("CREATE UNIQUE INDEX `index_budgets_overall_unique` ON `budgets` (`year`, `month`) WHERE `category_id` IS NULL")
                db.execSQL("CREATE UNIQUE INDEX `index_budgets_category_unique` ON `budgets` (`year`, `month`, `category_id`) WHERE `category_id` IS NOT NULL")

                // 2. Savings Goals Table (Strict CREATE TABLE)
                db.execSQL("""
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
                    )
                """)

                // 3. Savings Goal Contributions Table (Strict CREATE TABLE)
                db.execSQL("""
                    CREATE TABLE `savings_goal_contributions` (
                        `id` INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
                        `goal_id` INTEGER NOT NULL,
                        `amount_subunits` INTEGER NOT NULL,
                        `note` TEXT,
                        `timestamp` INTEGER NOT NULL,
                        `created_at` INTEGER NOT NULL,
                        FOREIGN KEY(`goal_id`) REFERENCES `savings_goals`(`id`) ON UPDATE NO ACTION ON DELETE CASCADE
                    )
                """)
                db.execSQL("CREATE INDEX `index_savings_goal_contributions_goal_id` ON `savings_goal_contributions` (`goal_id`)")

                // 4. Split Groups Table (Strict CREATE TABLE)
                db.execSQL("""
                    CREATE TABLE `split_groups` (
                        `id` INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
                        `name` TEXT NOT NULL,
                        `icon_name` TEXT NOT NULL DEFAULT 'group',
                        `color_hex` TEXT NOT NULL DEFAULT '#3B82F6',
                        `created_at` INTEGER NOT NULL
                    )
                """)

                // 5. Add group_id to split_expenses
                db.execSQL("ALTER TABLE `split_expenses` ADD COLUMN `group_id` INTEGER REFERENCES `split_groups`(`id`) ON DELETE SET NULL")
                db.execSQL("CREATE INDEX `index_split_expenses_group_id` ON `split_expenses` (`group_id`)")
            }
        }

        fun getInstance(context: Context): ExpenseTrackerDatabase {
            return INSTANCE ?: synchronized(this) {
                val instance = Room.databaseBuilder(
                    context.applicationContext,
                    ExpenseTrackerDatabase::class.java,
                    AppConstants.DATABASE_NAME
                )
                    .addMigrations(MIGRATION_1_2, MIGRATION_2_3, MIGRATION_3_4, MIGRATION_4_5, MIGRATION_5_6)
                    .addCallback(DatabaseCallback())
                    .build()
                INSTANCE = instance
                instance
            }
        }

        private class DatabaseCallback : Callback() {
            override fun onCreate(db: SupportSQLiteDatabase) {
                super.onCreate(db)
                seedDefaultCategoriesSql(db)
            }
        }

        private fun seedDefaultCategoriesSql(db: SupportSQLiteDatabase) {
            val defaultCategories = listOf(
                // Expense Categories
                Triple("Food & Dining", "restaurant", "#EF4444") to "EXPENSE",
                Triple("Transportation", "directions_car", "#F59E0B") to "EXPENSE",
                Triple("Shopping", "shopping_bag", "#8B5CF6") to "EXPENSE",
                Triple("Bills & Utilities", "receipt_long", "#3B82F6") to "EXPENSE",
                Triple("Entertainment", "movie", "#EC4899") to "EXPENSE",
                Triple("Health & Medical", "medical_services", "#10B981") to "EXPENSE",
                Triple("Education", "school", "#6366F1") to "EXPENSE",
                Triple("Personal Care", "spa", "#14B8A6") to "EXPENSE",
                Triple("Housing & Rent", "home", "#F97316") to "EXPENSE",
                Triple("EMI & Loans", "account_balance", "#DC2626") to "EXPENSE",
                Triple("Subscriptions", "subscriptions", "#7C3AED") to "EXPENSE",
                Triple("Other Expense", "more_horiz", "#64748B") to "EXPENSE",

                // Income Categories
                Triple("Salary", "payments", "#10B981") to "INCOME",
                Triple("Freelance & Consulting", "work", "#3B82F6") to "INCOME",
                Triple("Investments & Dividends", "trending_up", "#8B5CF6") to "INCOME",
                Triple("Rental Income", "real_estate_agent", "#F59E0B") to "INCOME",
                Triple("Business Revenue", "storefront", "#06B6D4") to "INCOME",
                Triple("Gifts & Grants", "card_giftcard", "#EC4899") to "INCOME",
                Triple("Refunds & Cashbacks", "replay", "#14B8A6") to "INCOME",
                Triple("Other Income", "attach_money", "#64748B") to "INCOME"
            )

            for ((item, type) in defaultCategories) {
                val (name, icon, color) = item
                db.execSQL(
                    "INSERT INTO categories (name, icon_name, color_hex, type, is_default) VALUES (?, ?, ?, ?, 1)",
                    arrayOf(name, icon, color, type)
                )
            }
        }
    }
}
