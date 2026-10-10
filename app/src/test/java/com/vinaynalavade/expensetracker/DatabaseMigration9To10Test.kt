package com.vinaynalavade.expensetracker

import androidx.sqlite.db.SupportSQLiteDatabase
import com.vinaynalavade.expensetracker.data.local.database.ExpenseTrackerDatabase
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test
import java.lang.reflect.Proxy

class DatabaseMigration9To10Test {

    @Test
    fun testMigrationVersionNumbers() {
        assertEquals(9, ExpenseTrackerDatabase.MIGRATION_9_10.startVersion)
        assertEquals(10, ExpenseTrackerDatabase.MIGRATION_9_10.endVersion)
    }

    @Test
    fun testMigration9To10ExecutesColumnAdditions() {
        val executedStatements = mutableListOf<String>()
        val fakeDb = createRecordingDatabase(executedStatements)

        ExpenseTrackerDatabase.MIGRATION_9_10.migrate(fakeDb)

        val sqls = executedStatements

        assertTrue(
            "Must alter split_participants to add phone_number",
            sqls.any { it.contains("ALTER TABLE `split_participants` ADD COLUMN `phone_number` TEXT") }
        )
        assertTrue(
            "Must alter split_expenses to add items_json",
            sqls.any { it.contains("ALTER TABLE `split_expenses` ADD COLUMN `items_json` TEXT") }
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
