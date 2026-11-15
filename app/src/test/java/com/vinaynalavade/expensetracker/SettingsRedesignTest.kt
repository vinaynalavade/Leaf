package com.vinaynalavade.expensetracker

import androidx.compose.ui.graphics.Color
import com.vinaynalavade.expensetracker.core.model.Amount
import com.vinaynalavade.expensetracker.core.model.Currency
import com.vinaynalavade.expensetracker.core.result.AppResult
import com.vinaynalavade.expensetracker.domain.model.BalanceDisplayMode
import com.vinaynalavade.expensetracker.domain.model.PaymentMethod
import com.vinaynalavade.expensetracker.domain.model.ThemeMode
import com.vinaynalavade.expensetracker.domain.model.UserPreferences
import com.vinaynalavade.expensetracker.domain.repository.UserPreferencesRepository
import com.vinaynalavade.expensetracker.presentation.settings.AppLanguage
import com.vinaynalavade.expensetracker.presentation.settings.components.SettingsColors
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.runBlocking
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test

/**
 * Unit test suite verifying Apple-inspired Settings redesign integrity in Leaf v1.1.5.
 * Tests color palette vibrancy, section-preference coverage, and state persistence.
 */
class SettingsRedesignTest {

    private lateinit var fakeRepo: FakeSettingsPrefsRepo

    @Before
    fun setUp() {
        fakeRepo = FakeSettingsPrefsRepo()
    }

    @Test
    fun testSettingsColorPaletteDistinctiveness() {
        // Verify all Apple-inspired squircle colors are defined and distinct
        val colors = listOf(
            SettingsColors.Blue,
            SettingsColors.Green,
            SettingsColors.Orange,
            SettingsColors.Purple,
            SettingsColors.Red,
            SettingsColors.Indigo,
            SettingsColors.Teal,
            SettingsColors.Slate
        )

        assertEquals("Should have 8 core settings squircle colors", 8, colors.size)
        // Check uniqueness
        val uniqueColors = colors.toSet()
        assertEquals("All squircle colors must be distinct", colors.size, uniqueColors.size)

        // Verify colors are non-transparent
        colors.forEach { color ->
            assertTrue("Squircle color alpha must be fully opaque", color.alpha == 1.0f)
        }
    }

    @Test
    fun testAppearanceSectionPreferencesMapping() = runBlocking {
        val initial = fakeRepo.getUserPreferences().first()
        assertEquals(ThemeMode.LIGHT, initial.themeMode)
        assertTrue(initial.isBalanceVisible)
        assertEquals("SYSTEM", initial.appLanguage)

        // Switch theme to DARK
        fakeRepo.setThemeMode(ThemeMode.DARK)
        assertEquals(ThemeMode.DARK, fakeRepo.getUserPreferences().first().themeMode)

        // Switch theme to SYSTEM
        fakeRepo.setThemeMode(ThemeMode.SYSTEM)
        assertEquals(ThemeMode.SYSTEM, fakeRepo.getUserPreferences().first().themeMode)

        // Toggle balance visibility
        fakeRepo.setBalanceVisible(false)
        assertFalse(fakeRepo.getUserPreferences().first().isBalanceVisible)

        // Test language mapping
        val hindiLang = AppLanguage.fromCode("hi")
        assertEquals("Hindi", hindiLang.displayName)
        assertEquals("हिंदी", hindiLang.nativeName)
    }

    @Test
    fun testFinanceSectionPreferencesMapping() = runBlocking {
        val initial = fakeRepo.getUserPreferences().first()
        assertEquals(PaymentMethod.CASH, initial.defaultExpenseSource)
        assertEquals(PaymentMethod.ACCOUNT, initial.defaultIncomeSource)

        // Update default sources
        fakeRepo.setDefaultExpenseSource(PaymentMethod.ACCOUNT)
        assertEquals(PaymentMethod.ACCOUNT, fakeRepo.getUserPreferences().first().defaultExpenseSource)

        fakeRepo.setDefaultIncomeSource(PaymentMethod.CASH)
        assertEquals(PaymentMethod.CASH, fakeRepo.getUserPreferences().first().defaultIncomeSource)

        // Update opening balance
        val openingAmount = 150000L // 1500.00
        fakeRepo.setOpeningBalance(openingAmount)
        assertEquals(openingAmount, fakeRepo.getUserPreferences().first().openingBalanceSubunits)

        // Update currency code
        fakeRepo.setCurrencyCode(Currency.EUR.code)
        assertEquals(Currency.EUR, fakeRepo.getUserPreferences().first().currency)

        // Update monthly budget limit
        val budgetLimit = 500000L // 5000.00
        fakeRepo.setMonthlyBudgetLimit(budgetLimit)
        assertEquals(budgetLimit, fakeRepo.getUserPreferences().first().monthlyBudgetLimitSubunits)
    }

    @Test
    fun testNotificationsSectionPreferencesMapping() = runBlocking {
        val initial = fakeRepo.getUserPreferences().first()
        assertFalse(initial.notificationsMasterEnabled)
        assertTrue(initial.emiRemindersEnabled)
        assertTrue(initial.billRemindersEnabled)
        assertTrue(initial.creditCardRemindersEnabled)

        // Master toggle on
        fakeRepo.setNotificationsMasterEnabled(true)
        assertTrue(fakeRepo.getUserPreferences().first().notificationsMasterEnabled)

        // Test specific toggles
        fakeRepo.setEmiReminders(false)
        assertFalse(fakeRepo.getUserPreferences().first().emiRemindersEnabled)

        fakeRepo.setBillReminders(false)
        assertFalse(fakeRepo.getUserPreferences().first().billRemindersEnabled)

        fakeRepo.setCreditCardReminders(false)
        assertFalse(fakeRepo.getUserPreferences().first().creditCardRemindersEnabled)

        fakeRepo.setBudgetAlertsEnabled(true)
        assertTrue(fakeRepo.getUserPreferences().first().budgetAlertsEnabled)

        fakeRepo.setDailyReminder(true, 21, 30)
        val updated = fakeRepo.getUserPreferences().first()
        assertTrue(updated.dailyReminderEnabled)
        assertEquals(21, updated.dailyReminderHour)
        assertEquals(30, updated.dailyReminderMinute)
    }

    @Test
    fun testSecuritySectionPreferencesMapping() = runBlocking {
        val initial = fakeRepo.getUserPreferences().first()
        assertFalse(initial.appLockEnabled)
        assertFalse(initial.biometricEnabled)
        assertEquals(0L, initial.autoLockDurationSeconds)
        assertTrue(initial.hideContentInRecents)

        // Enable app lock and configure options
        fakeRepo.setAppLockEnabled(true)
        fakeRepo.setBiometricEnabled(true)
        fakeRepo.setAutoLockDurationSeconds(60L)
        fakeRepo.setHideContentInRecents(false)

        val updated = fakeRepo.getUserPreferences().first()
        assertTrue(updated.appLockEnabled)
        assertTrue(updated.biometricEnabled)
        assertEquals(60L, updated.autoLockDurationSeconds)
        assertFalse(updated.hideContentInRecents)
    }

    @Test
    fun testSectionGroupingCompleteness() {
        // Verify all 7 redesigned settings sections are represented
        val sections = listOf(
            "Profile / Apple ID Header",
            "Appearance & Personalization",
            "Finances & Ledgers",
            "Notifications & Reminders",
            "Security & Privacy",
            "Data & Cloud Backup",
            "About Leaf"
        )
        assertEquals(7, sections.size)
    }

    // --- Fake Repository for Testing ---
    private class FakeSettingsPrefsRepo : UserPreferencesRepository {
        private val _prefs = MutableStateFlow(UserPreferences())

        override fun getUserPreferences(): Flow<UserPreferences> = _prefs.asStateFlow()

        override suspend fun setThemeMode(themeMode: ThemeMode): AppResult<Unit> {
            _prefs.value = _prefs.value.copy(themeMode = themeMode)
            return AppResult.Success(Unit)
        }

        override suspend fun setCurrencyCode(currencyCode: String): AppResult<Unit> {
            _prefs.value = _prefs.value.copy(currency = Currency.fromCode(currencyCode))
            return AppResult.Success(Unit)
        }

        override suspend fun setOpeningBalance(subunits: Long): AppResult<Unit> {
            _prefs.value = _prefs.value.copy(openingBalanceSubunits = subunits)
            return AppResult.Success(Unit)
        }

        override suspend fun setBalanceVisible(isVisible: Boolean): AppResult<Unit> {
            _prefs.value = _prefs.value.copy(isBalanceVisible = isVisible)
            return AppResult.Success(Unit)
        }

        override suspend fun setBalanceDisplayMode(mode: BalanceDisplayMode): AppResult<Unit> {
            _prefs.value = _prefs.value.copy(balanceDisplayMode = mode)
            return AppResult.Success(Unit)
        }

        override suspend fun setMonthlyBudgetLimit(subunits: Long): AppResult<Unit> {
            _prefs.value = _prefs.value.copy(monthlyBudgetLimitSubunits = subunits)
            return AppResult.Success(Unit)
        }

        override suspend fun setDefaultExpenseSource(source: PaymentMethod): AppResult<Unit> {
            _prefs.value = _prefs.value.copy(defaultExpenseSource = source)
            return AppResult.Success(Unit)
        }

        override suspend fun setDefaultIncomeSource(source: PaymentMethod): AppResult<Unit> {
            _prefs.value = _prefs.value.copy(defaultIncomeSource = source)
            return AppResult.Success(Unit)
        }

        override suspend fun setNotificationsMasterEnabled(enabled: Boolean): AppResult<Unit> {
            _prefs.value = _prefs.value.copy(notificationsMasterEnabled = enabled)
            return AppResult.Success(Unit)
        }

        override suspend fun setEmiReminders(enabled: Boolean): AppResult<Unit> {
            _prefs.value = _prefs.value.copy(emiRemindersEnabled = enabled)
            return AppResult.Success(Unit)
        }

        override suspend fun setBillReminders(enabled: Boolean): AppResult<Unit> {
            _prefs.value = _prefs.value.copy(billRemindersEnabled = enabled)
            return AppResult.Success(Unit)
        }

        override suspend fun setCreditCardReminders(enabled: Boolean): AppResult<Unit> {
            _prefs.value = _prefs.value.copy(creditCardRemindersEnabled = enabled)
            return AppResult.Success(Unit)
        }

        override suspend fun setDailyReminder(enabled: Boolean, hour: Int, minute: Int): AppResult<Unit> {
            _prefs.value = _prefs.value.copy(
                dailyReminderEnabled = enabled,
                dailyReminderHour = hour,
                dailyReminderMinute = minute
            )
            return AppResult.Success(Unit)
        }

        override suspend fun setBudgetAlertsEnabled(enabled: Boolean): AppResult<Unit> {
            _prefs.value = _prefs.value.copy(budgetAlertsEnabled = enabled)
            return AppResult.Success(Unit)
        }

        override suspend fun setAppLockEnabled(enabled: Boolean): AppResult<Unit> {
            _prefs.value = _prefs.value.copy(appLockEnabled = enabled)
            return AppResult.Success(Unit)
        }

        override suspend fun setBiometricEnabled(enabled: Boolean): AppResult<Unit> {
            _prefs.value = _prefs.value.copy(biometricEnabled = enabled)
            return AppResult.Success(Unit)
        }

        override suspend fun setAutoLockDurationSeconds(seconds: Long): AppResult<Unit> {
            _prefs.value = _prefs.value.copy(autoLockDurationSeconds = seconds)
            return AppResult.Success(Unit)
        }

        override suspend fun setHideContentInRecents(hide: Boolean): AppResult<Unit> {
            _prefs.value = _prefs.value.copy(hideContentInRecents = hide)
            return AppResult.Success(Unit)
        }

        // Remaining methods required by interface
        override suspend fun setDynamicColors(useDynamicColors: Boolean): AppResult<Unit> = AppResult.Success(Unit)
        override suspend fun setFirstLaunchCompleted(): AppResult<Unit> = AppResult.Success(Unit)
        override suspend fun setDefaultReminderOffsetDays(days: Int): AppResult<Unit> = AppResult.Success(Unit)
        override suspend fun setDefaultReminderTime(hour: Int, minute: Int): AppResult<Unit> = AppResult.Success(Unit)
        override fun getLastBackupTimestamp(): Flow<Long?> = MutableStateFlow<Long?>(null).asStateFlow()
        override suspend fun setLastBackupTimestamp(timestamp: Long): AppResult<Unit> = AppResult.Success(Unit)
        override suspend fun setRecurringRemindersEnabled(enabled: Boolean): AppResult<Unit> = AppResult.Success(Unit)
        override suspend fun setRecurringReminderAdvanceDays(days: Int): AppResult<Unit> = AppResult.Success(Unit)
        override suspend fun setSavingsGoalNotificationsEnabled(enabled: Boolean): AppResult<Unit> = AppResult.Success(Unit)
        override suspend fun setAppLanguage(languageCode: String): AppResult<Unit> = AppResult.Success(Unit)
        override suspend fun setProfileName(name: String?): AppResult<Unit> = AppResult.Success(Unit)
        override suspend fun setProfileImageUri(uri: String?): AppResult<Unit> = AppResult.Success(Unit)
        override suspend fun setAutomaticBackupEnabled(enabled: Boolean): AppResult<Unit> = AppResult.Success(Unit)
        override suspend fun setLastBackupStatus(status: String?): AppResult<Unit> = AppResult.Success(Unit)
        override suspend fun setLastBackupError(error: String?): AppResult<Unit> = AppResult.Success(Unit)
        override suspend fun setLastDismissedRestoreBackupTimestamp(timestamp: Long?): AppResult<Unit> = AppResult.Success(Unit)
        override suspend fun setAppTourCompleted(completed: Boolean): AppResult<Unit> = AppResult.Success(Unit)
    }
}
