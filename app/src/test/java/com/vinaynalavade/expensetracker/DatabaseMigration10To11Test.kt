package com.vinaynalavade.expensetracker

import androidx.sqlite.db.SupportSQLiteDatabase
import com.vinaynalavade.expensetracker.data.local.database.ExpenseTrackerDatabase
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test
import java.lang.reflect.Proxy

class DatabaseMigration10To11Test {

    @Test
    fun testMigrationVersionNumbers() {
        assertEquals(10, ExpenseTrackerDatabase.MIGRATION_10_11.startVersion)
        assertEquals(11, ExpenseTrackerDatabase.MIGRATION_10_11.endVersion)
    }

    @Test
    fun testMigration10To11ExecutesSchemaAdditionsAndNormalization() {
        val executedStatements = mutableListOf<String>()
        val fakeDb = createRecordingDatabase(executedStatements)

        ExpenseTrackerDatabase.MIGRATION_10_11.migrate(fakeDb)

        val sqls = executedStatements

        assertTrue(
            "Must alter transactions to add raw_payment_method",
            sqls.any { it.contains("ALTER TABLE `transactions` ADD COLUMN `raw_payment_method` TEXT") }
        )
        assertTrue(
            "Must backfill raw_payment_method from payment_method",
            sqls.any { it.contains("UPDATE `transactions` SET `raw_payment_method` = `payment_method`") }
        )
        assertTrue(
            "Must alter transactions to add transfer_pair_id",
            sqls.any { it.contains("ALTER TABLE `transactions` ADD COLUMN `transfer_pair_id` INTEGER") }
        )
        assertTrue(
            "Must create index on transfer_pair_id",
            sqls.any { it.contains("CREATE INDEX IF NOT EXISTS `index_transactions_transfer_pair_id`") }
        )
        assertTrue(
            "Must alter transactions to add is_internal_transfer",
            sqls.any { it.contains("ALTER TABLE `transactions` ADD COLUMN `is_internal_transfer` INTEGER NOT NULL DEFAULT 0") }
        )
        assertTrue(
            "Must create index on is_internal_transfer",
            sqls.any { it.contains("CREATE INDEX IF NOT EXISTS `index_transactions_is_internal_transfer`") }
        )
        assertTrue(
            "Must normalize account payment methods",
            sqls.any { it.contains("SET `payment_method` = 'ACCOUNT'") }
        )
        assertTrue(
            "Must normalize cash payment methods",
            sqls.any { it.contains("SET `payment_method` = 'CASH'") }
        )
        assertTrue(
            "Must create index on payment_method",
            sqls.any { it.contains("CREATE INDEX IF NOT EXISTS `index_transactions_payment_method`") }
        )
        assertTrue(
            "Must link paired transfers",
            sqls.any { it.contains("SET `transfer_pair_id` =") }
        )
    }

    private fun createRecordingDatabase(statements: MutableList<String>): SupportSQLiteDatabase {
        return Proxy.newProxyInstance(
            SupportSQLiteDatabase::class.java.classLoader,
            arrayOf(SupportSQLiteDatabase::class.java)
        ) { _, method, args ->
            when (method.name) {
                "execSQL" -> {
                    if (args != null && args.isNotEmpty() && args[0] is String) {
                        statements.add(args[0] as String)
                    }
                    null
                }
                else -> null
            }
        } as SupportSQLiteDatabase
    }
}

