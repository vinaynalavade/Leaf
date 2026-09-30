package com.vinaynalavade.expensetracker

import androidx.sqlite.db.SupportSQLiteDatabase
import com.vinaynalavade.expensetracker.data.local.database.ExpenseTrackerDatabase
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertTrue
import org.junit.Test
import java.lang.reflect.Proxy

class DatabaseMigration8To9Test {

    @Test
    fun testMigrationVersionNumbers() {
        assertEquals(8, ExpenseTrackerDatabase.MIGRATION_8_9.startVersion)
        assertEquals(9, ExpenseTrackerDatabase.MIGRATION_8_9.endVersion)
    }

    @Test
    fun testMigration8To9ExecutesTableAndIndexCreation() {
        val executedStatements = mutableListOf<String>()
        val fakeDb = createRecordingDatabase(executedStatements)

        ExpenseTrackerDatabase.MIGRATION_8_9.migrate(fakeDb)

        val sqls = executedStatements

        val createTableSql = sqls.firstOrNull { it.contains("CREATE TABLE IF NOT EXISTS `reminders`") }
        assertNotNull("CREATE TABLE reminders must be executed", createTableSql)
        assertTrue(createTableSql!!.contains("`id` INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL"))
        assertTrue(createTableSql.contains("`title` TEXT NOT NULL"))
        assertTrue(createTableSql.contains("`amount_subunits` INTEGER NOT NULL"))
        assertTrue(createTableSql.contains("`type` TEXT NOT NULL"))
        assertTrue(createTableSql.contains("`due_date` INTEGER NOT NULL"))
        assertTrue(createTableSql.contains("`recurrence` TEXT NOT NULL"))
        assertTrue(createTableSql.contains("`reminder_offset_days` INTEGER NOT NULL"))
        assertTrue(createTableSql.contains("`additional_offsets` TEXT"))
        assertTrue(createTableSql.contains("`notification_hour` INTEGER NOT NULL"))
        assertTrue(createTableSql.contains("`notification_minute` INTEGER NOT NULL"))
        assertTrue(createTableSql.contains("`is_enabled` INTEGER NOT NULL"))
        assertTrue(createTableSql.contains("`configured_day_of_month` INTEGER NOT NULL"))

        assertTrue("Must create index on is_enabled", sqls.any { it.contains("index_reminders_is_enabled") })
        assertTrue("Must create index on due_date", sqls.any { it.contains("index_reminders_due_date") })
        assertTrue("Must create index on type", sqls.any { it.contains("index_reminders_type") })
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
