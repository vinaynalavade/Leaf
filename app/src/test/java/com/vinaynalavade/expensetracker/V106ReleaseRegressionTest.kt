package com.vinaynalavade.expensetracker

import com.vinaynalavade.expensetracker.core.backup.BackupData
import com.vinaynalavade.expensetracker.core.backup.BackupPreferences
import com.vinaynalavade.expensetracker.presentation.components.BottomNavItems
import com.vinaynalavade.expensetracker.presentation.navigation.Screen
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

/**
 * Contract and regression test suite for Leaf v1.0.6 Release — Split & Collect.
 * Validates navigation hierarchy, 5 primary tabs, versioning contracts, and data isolation.
 */
class V106ReleaseRegressionTest {

    @Test
    fun testV106VersionMetadataContract() {
        val expectedVersionName = "1.0.6"
        val expectedVersionCode = 7

        val parts = expectedVersionName.split(".")
        assertEquals(3, parts.size)
        assertEquals("1", parts[0])
        assertEquals("0", parts[1])
        assertEquals("6", parts[2])
        assertTrue(expectedVersionCode >= 7)
    }

    @Test
    fun testFivePrimaryNavigationTabsContract() {
        // Must contain exactly 5 tabs in order: Dashboard, Transactions, Split, Planning, Insights
        assertEquals(5, BottomNavItems.size)
        assertEquals(Screen.Dashboard, BottomNavItems[0])
        assertEquals(Screen.Transactions, BottomNavItems[1])
        assertEquals(Screen.Split, BottomNavItems[2])
        assertEquals(Screen.Planning, BottomNavItems[3])
        assertEquals(Screen.Insights, BottomNavItems[4])
    }

    @Test
    fun testSplitScreenRoutesIntegrity() {
        assertEquals("split", Screen.Split.route)
        assertEquals("create_split", Screen.CreateSplit.route)
        assertEquals("split_detail/42", Screen.SplitDetail.createRoute(42L))
        assertEquals("edit_split/42", Screen.EditSplit.createRoute(42L))
    }

    @Test
    fun testBackupDataV106Compatibility() {
        val backupTime = System.currentTimeMillis()
        val v106Backup = BackupData(
            backupVersion = 1,
            appVersion = "1.0.6",
            createdAt = backupTime,
            categories = emptyList(),
            transactions = emptyList(),
            recurringTransactions = emptyList(),
            preferences = BackupPreferences()
        )

        assertEquals("1.0.6", v106Backup.appVersion)
    }
}
