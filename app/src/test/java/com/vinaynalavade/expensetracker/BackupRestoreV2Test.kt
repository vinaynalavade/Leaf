package com.vinaynalavade.expensetracker

import com.vinaynalavade.expensetracker.core.backup.BackupBudget
import com.vinaynalavade.expensetracker.core.backup.BackupCategory
import com.vinaynalavade.expensetracker.core.backup.BackupData
import com.vinaynalavade.expensetracker.core.backup.BackupPreferences
import com.vinaynalavade.expensetracker.core.backup.BackupRecurringTransaction
import com.vinaynalavade.expensetracker.core.backup.BackupSavingsGoal
import com.vinaynalavade.expensetracker.core.backup.BackupSavingsGoalContribution
import com.vinaynalavade.expensetracker.core.backup.BackupSplitExpense
import com.vinaynalavade.expensetracker.core.backup.BackupSplitGroup
import com.vinaynalavade.expensetracker.core.backup.BackupSplitParticipant
import com.vinaynalavade.expensetracker.core.backup.BackupTransaction
import com.vinaynalavade.expensetracker.core.backup.JsonBackupParser
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

class BackupRestoreV2Test {

    @Test
    fun testLegacyV1BackupBackwardCompatibility() {
        val v1Json = """
        {
          "backupVersion": 1,
          "appVersion": "1.0.7",
          "createdAt": 1787000000000,
          "preferences": {
            "openingBalanceSubunits": 500000,
            "currencyCode": "INR",
            "themeMode": "SYSTEM",
            "dailyReminderEnabled": false,
            "dailyReminderHour": 21,
            "dailyReminderMinute": 0,
            "emiRemindersEnabled": true,
            "notificationsMasterEnabled": false,
            "budgetAlertsEnabled": false,
            "monthlyBudgetLimitSubunits": 0,
            "recurringRemindersEnabled": false,
            "recurringReminderAdvanceDays": 1,
            "savingsGoalNotificationsEnabled": false
          },
          "categories": [
            {
              "id": 1,
              "name": "Food & Dining",
              "iconName": "restaurant",
              "colorHex": "#EF4444",
              "type": "EXPENSE",
              "isDefault": true
            }
          ],
          "transactions": [
            {
              "id": 101,
              "amountSubunits": 45000,
              "type": "EXPENSE",
              "categoryId": 1,
              "paymentMethod": "UPI",
              "note": "Lunch",
              "timestamp": 1787000000000
            }
          ],
          "recurringTransactions": []
        }
        """.trimIndent()

        val parsed = JsonBackupParser.fromJson(v1Json)
        assertEquals(1, parsed.backupVersion)
        assertEquals("1.0.7", parsed.appVersion)
        assertEquals(1, parsed.categories.size)
        assertEquals(1, parsed.transactions.size)
        assertTrue(parsed.budgets.isEmpty())
        assertTrue(parsed.savingsGoals.isEmpty())
        assertTrue(parsed.savingsGoalContributions.isEmpty())
        assertTrue(parsed.splitGroups.isEmpty())
        assertTrue(parsed.splitExpenses.isEmpty())
        assertTrue(parsed.splitParticipants.isEmpty())
    }

    @Test
    fun testV2BackupFullSerializationRoundtrip() {
        val backupData = BackupData(
            backupVersion = 2,
            appVersion = "1.0.8",
            createdAt = 1788000000000L,
            categories = listOf(
                BackupCategory(1L, "Food & Dining", "restaurant", "#EF4444", "EXPENSE", true),
                BackupCategory(2L, "Travel", "flight", "#3B82F6", "EXPENSE", false)
            ),
            transactions = listOf(
                BackupTransaction(10L, 50000L, "EXPENSE", 1L, "UPI", "Dinner with \"friends\"", 1788001000000L)
            ),
            recurringTransactions = emptyList(),
            preferences = BackupPreferences(
                openingBalanceSubunits = 1000000L,
                currencyCode = "INR",
                themeMode = "DARK"
            ),
            budgets = listOf(
                BackupBudget(
                    id = 1L,
                    categoryId = null,
                    amountSubunits = 3000000L,
                    month = 9,
                    year = 2026,
                    createdAt = 1788000000000L,
                    updatedAt = 1788000000000L
                ),
                BackupBudget(
                    id = 2L,
                    categoryId = 1L,
                    amountSubunits = 1000000L,
                    month = 9,
                    year = 2026,
                    createdAt = 1788000000000L,
                    updatedAt = 1788000000000L
                )
            ),
            savingsGoals = listOf(
                BackupSavingsGoal(
                    id = 101L,
                    name = "Emergency Fund",
                    targetAmountSubunits = 10000000L,
                    targetDate = 1800000000000L,
                    note = "6 months expenses",
                    iconName = "savings",
                    colorHex = "#10B981",
                    isArchived = false,
                    createdAt = 1788000000000L,
                    updatedAt = 1788000000000L
                )
            ),
            savingsGoalContributions = listOf(
                BackupSavingsGoalContribution(
                    id = 201L,
                    goalId = 101L,
                    amountSubunits = 2500000L,
                    note = "Initial deposit",
                    timestamp = 1788002000000L,
                    createdAt = 1788002000000L
                )
            ),
            splitGroups = listOf(
                BackupSplitGroup(
                    id = 501L,
                    name = "Goa Trip",
                    iconName = "beach_access",
                    colorHex = "#F59E0B",
                    createdAt = 1788000000000L
                )
            ),
            splitExpenses = listOf(
                BackupSplitExpense(
                    id = 601L,
                    title = "Villa Booking",
                    totalAmountSubunits = 1500000L,
                    date = 1788000000000L,
                    categoryId = 2L,
                    paidBy = "Me",
                    splitMethod = "EQUAL",
                    groupId = 501L,
                    createdAt = 1788000000000L,
                    updatedAt = 1788000000000L
                )
            ),
            splitParticipants = listOf(
                BackupSplitParticipant(
                    id = 701L,
                    splitExpenseId = 601L,
                    name = "Me",
                    isCurrentUser = true,
                    amountSubunits = 500000L,
                    settlementStatus = "SETTLED"
                ),
                BackupSplitParticipant(
                    id = 702L,
                    splitExpenseId = 601L,
                    name = "Alice",
                    isCurrentUser = false,
                    amountSubunits = 500000L,
                    settlementStatus = "PENDING"
                ),
                BackupSplitParticipant(
                    id = 703L,
                    splitExpenseId = 601L,
                    name = "Bob",
                    isCurrentUser = false,
                    amountSubunits = 500000L,
                    settlementStatus = "PENDING"
                )
            )
        )

        // Serialize to JSON
        val jsonString = JsonBackupParser.toJson(backupData)
        assertTrue(jsonString.contains("\"backupVersion\": 2"))
        assertTrue(jsonString.contains("\"Goa Trip\""))
        assertTrue(jsonString.contains("\"Emergency Fund\""))
        assertTrue(jsonString.contains("\"Villa Booking\""))

        // Deserialize from JSON
        val parsed = JsonBackupParser.fromJson(jsonString)
        assertEquals(2, parsed.backupVersion)
        assertEquals("1.0.8", parsed.appVersion)

        // Budgets
        assertEquals(2, parsed.budgets.size)
        assertEquals(1L, parsed.budgets[0].id)
        assertNull(parsed.budgets[0].categoryId)
        assertEquals(3000000L, parsed.budgets[0].amountSubunits)
        assertEquals(1L, parsed.budgets[1].categoryId)

        // Savings Goals & Contributions
        assertEquals(1, parsed.savingsGoals.size)
        assertEquals(101L, parsed.savingsGoals[0].id)
        assertEquals("Emergency Fund", parsed.savingsGoals[0].name)
        assertEquals(10000000L, parsed.savingsGoals[0].targetAmountSubunits)
        assertFalse(parsed.savingsGoals[0].isArchived)

        assertEquals(1, parsed.savingsGoalContributions.size)
        assertEquals(201L, parsed.savingsGoalContributions[0].id)
        assertEquals(101L, parsed.savingsGoalContributions[0].goalId)
        assertEquals(2500000L, parsed.savingsGoalContributions[0].amountSubunits)

        // Split Groups, Expenses & Participants
        assertEquals(1, parsed.splitGroups.size)
        assertEquals(501L, parsed.splitGroups[0].id)
        assertEquals("Goa Trip", parsed.splitGroups[0].name)

        assertEquals(1, parsed.splitExpenses.size)
        assertEquals(601L, parsed.splitExpenses[0].id)
        assertEquals(501L, parsed.splitExpenses[0].groupId)
        assertEquals("Villa Booking", parsed.splitExpenses[0].title)

        assertEquals(3, parsed.splitParticipants.size)
        assertEquals(701L, parsed.splitParticipants[0].id)
        assertTrue(parsed.splitParticipants[0].isCurrentUser)
        assertEquals("SETTLED", parsed.splitParticipants[0].settlementStatus)

        assertEquals(702L, parsed.splitParticipants[1].id)
        assertFalse(parsed.splitParticipants[1].isCurrentUser)
        assertEquals("Alice", parsed.splitParticipants[1].name)
        assertEquals("PENDING", parsed.splitParticipants[1].settlementStatus)
    }
}
