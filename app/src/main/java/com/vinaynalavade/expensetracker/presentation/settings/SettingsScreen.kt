package com.vinaynalavade.expensetracker.presentation.settings

import android.Manifest
import android.app.Activity
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.PickVisualMediaRequest
import androidx.activity.result.contract.ActivityResultContracts
import androidx.activity.result.contract.ActivityResultContracts.PickVisualMedia
import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.animateColorAsState
import androidx.compose.animation.core.tween
import androidx.compose.animation.expandVertically
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.shrinkVertically
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ColumnScope
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.ui.window.DialogProperties
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowForwardIos
import androidx.compose.material.icons.automirrored.filled.ReceiptLong
import androidx.compose.material.icons.filled.AccountBalance
import androidx.compose.material.icons.filled.AccountCircle
import androidx.compose.material.icons.filled.Calculate
import androidx.compose.material.icons.filled.Category
import androidx.compose.material.icons.filled.CloudDone
import androidx.compose.material.icons.filled.CloudOff
import androidx.compose.material.icons.filled.CloudSync
import androidx.compose.material.icons.filled.CloudUpload
import androidx.compose.material.icons.filled.CreditCard
import androidx.compose.material.icons.filled.DarkMode
import androidx.compose.material.icons.filled.Description
import androidx.compose.material.icons.filled.Fingerprint
import androidx.compose.material.icons.filled.Flag
import androidx.compose.material.icons.filled.Info
import androidx.compose.material.icons.filled.LightMode
import androidx.compose.material.icons.filled.Lock
import androidx.compose.material.icons.filled.LockOpen
import androidx.compose.material.icons.filled.LockReset
import androidx.compose.material.icons.filled.Notifications
import androidx.compose.material.icons.filled.Payments
import androidx.compose.material.icons.filled.PieChart
import androidx.compose.material.icons.filled.RadioButtonChecked
import androidx.compose.material.icons.filled.RadioButtonUnchecked
import androidx.compose.material.icons.filled.Schedule
import androidx.compose.material.icons.filled.Security
import androidx.compose.material.icons.filled.SettingsBrightness
import androidx.compose.material.icons.filled.Sync
import androidx.compose.material.icons.filled.Timer
import androidx.compose.material.icons.filled.Translate
import androidx.compose.material.icons.filled.VisibilityOff
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Scaffold
import androidx.compose.material3.SnackbarDuration
import androidx.compose.material3.SnackbarHost
import androidx.compose.material3.SnackbarHostState
import androidx.compose.material3.Surface
import androidx.compose.material3.Switch
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TimePicker
import androidx.compose.material3.rememberTimePickerState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import kotlinx.coroutines.launch
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp
import androidx.core.content.ContextCompat
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.vinaynalavade.expensetracker.BuildConfig
import com.vinaynalavade.expensetracker.R
import com.vinaynalavade.expensetracker.core.model.Amount
import com.vinaynalavade.expensetracker.core.model.Currency
import com.vinaynalavade.expensetracker.core.security.BiometricAuthHelper
import com.vinaynalavade.expensetracker.core.utils.DateTimeUtils
import com.vinaynalavade.expensetracker.domain.model.GoogleAccountInfo
import com.vinaynalavade.expensetracker.domain.model.GoogleBackupState
import com.vinaynalavade.expensetracker.domain.model.PaymentMethod
import com.vinaynalavade.expensetracker.domain.model.RecurringReminderAdvance
import com.vinaynalavade.expensetracker.domain.model.ThemeMode
import com.vinaynalavade.expensetracker.domain.model.UserPreferences
import com.vinaynalavade.expensetracker.presentation.backup.components.ReplaceDataConfirmationDialog
import com.vinaynalavade.expensetracker.presentation.backup.components.RestorePromptDialog
import com.vinaynalavade.expensetracker.presentation.components.AppTopBar
import com.vinaynalavade.expensetracker.presentation.settings.components.EditProfileDialog
import com.vinaynalavade.expensetracker.presentation.settings.components.ImageCropDialog
import com.vinaynalavade.expensetracker.presentation.settings.components.ProfileCard
import com.vinaynalavade.expensetracker.presentation.settings.components.ProfilePhotoOptionsDialog
import com.vinaynalavade.expensetracker.presentation.settings.components.SettingsCustomTile
import com.vinaynalavade.expensetracker.presentation.settings.components.SettingsDivider
import com.vinaynalavade.expensetracker.presentation.settings.components.SettingsNavigationTile
import com.vinaynalavade.expensetracker.presentation.settings.components.SettingsSectionContainer
import com.vinaynalavade.expensetracker.presentation.settings.components.SettingsSwitchTile
import com.vinaynalavade.expensetracker.presentation.settings.components.ThemeSelectionSection
import com.vinaynalavade.expensetracker.presentation.theme.ButtonShape
import com.vinaynalavade.expensetracker.presentation.theme.CardShape
import com.vinaynalavade.expensetracker.presentation.theme.PillShape
import com.vinaynalavade.expensetracker.presentation.theme.pressScale
import com.vinaynalavade.expensetracker.presentation.theme.spacing
import com.vinaynalavade.expensetracker.presentation.widget.WidgetUpdateManager
import java.time.LocalTime
import java.time.format.DateTimeFormatter
import java.time.format.FormatStyle

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SettingsScreen(
    viewModel: SettingsViewModel,
    onNavigateToCategories: () -> Unit = {},
    onNavigateToRecurring: () -> Unit = {},
    onNavigateToStatements: () -> Unit = {},
    onNavigateToMonthlySummary: () -> Unit = {},
    onNavigateToBackup: () -> Unit = {},
    onNavigateToAppLockSetup: () -> Unit = {},
    onNavigateToChangePin: () -> Unit = {},
    onNavigateToTools: () -> Unit = {},
    onNavigateToAbout: () -> Unit = {},
    onNavigateToReminders: () -> Unit = {},
    modifier: Modifier = Modifier
) {
    val context = LocalContext.current
    val userPreferences by viewModel.userPreferences.collectAsStateWithLifecycle()
    val googleBackupState by viewModel.googleBackupState.collectAsStateWithLifecycle()
    val accountActionState by viewModel.accountActionState.collectAsStateWithLifecycle()
    val restorePromptEligibility by viewModel.restorePromptEligibility.collectAsStateWithLifecycle()
    val showReplaceConfirmation by viewModel.showReplaceConfirmation.collectAsStateWithLifecycle()
    val isManualBackupRunning by viewModel.isManualBackupRunning.collectAsStateWithLifecycle()

    val isBiometricAvailable = remember(context) { BiometricAuthHelper.isBiometricAvailable(context) }
    val snackbarHostState = remember { SnackbarHostState() }

    var showCurrencyDialog by remember { mutableStateOf(false) }
    var showOpeningBalanceDialog by remember { mutableStateOf(false) }
    var showTimePickerDialog by remember { mutableStateOf(false) }
    var showBudgetLimitDialog by remember { mutableStateOf(false) }
    var showRecurringAdvanceDialog by remember { mutableStateOf(false) }
    var showAutoLockDialog by remember { mutableStateOf(false) }
    var showUnlockMethodDialog by remember { mutableStateOf(false) }
    var showDisableAppLockDialog by remember { mutableStateOf(false) }
    var showDisconnectGoogleDialog by remember { mutableStateOf(false) }
    var showLanguageDialog by remember { mutableStateOf(false) }
    var showEditProfileDialog by remember { mutableStateOf(false) }
    var showProfilePhotoOptionsDialog by remember { mutableStateOf(false) }
    var showDefaultOffsetDialog by remember { mutableStateOf(false) }
    var showDefaultTimePickerDialog by remember { mutableStateOf(false) }
    var showWhatsNewDialog by remember { mutableStateOf(false) }
    var pendingCropImageUri by remember { mutableStateOf<Uri?>(null) }

    val photoPickerLauncher = rememberLauncherForActivityResult(
        contract = ActivityResultContracts.PickVisualMedia()
    ) { uri ->
        if (uri != null) {
            pendingCropImageUri = uri
        }
    }

    val permissionLauncher = rememberLauncherForActivityResult(
        contract = ActivityResultContracts.RequestPermission()
    ) { isGranted ->
        if (isGranted) {
            viewModel.onNotificationsMasterToggled(true)
        } else {
            viewModel.onNotificationsMasterToggled(false)
        }
    }

    val googleSignInLauncher = rememberLauncherForActivityResult(
        contract = ActivityResultContracts.StartActivityForResult()
    ) { result ->
        viewModel.onGoogleSignInResult(result.data)
    }

    val consentLauncher = rememberLauncherForActivityResult(
        contract = ActivityResultContracts.StartActivityForResult()
    ) { result ->
        viewModel.onConsentResult(result.resultCode)
    }

    LaunchedEffect(accountActionState) {
        when (val state = accountActionState) {
            is AccountActionState.ConsentRequired -> {
                consentLauncher.launch(state.consentIntent)
            }
            is AccountActionState.Message -> {
                snackbarHostState.showSnackbar(
                    message = state.message,
                    duration = SnackbarDuration.Short
                )
                viewModel.clearAccountActionMessage()
            }
            else -> {}
        }
    }

    Scaffold(
        topBar = {
            AppTopBar(
                title = stringResource(R.string.nav_settings)
            )
        },
        snackbarHost = { SnackbarHost(snackbarHostState) },
        containerColor = MaterialTheme.colorScheme.background,
        modifier = modifier
    ) { innerPadding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(innerPadding)
                .verticalScroll(rememberScrollState())
                .padding(horizontal = MaterialTheme.spacing.screen, vertical = MaterialTheme.spacing.md),
            verticalArrangement = Arrangement.spacedBy(MaterialTheme.spacing.lg)
        ) {
            // 1. Profile Hero Section
            ProfileCard(
                userPreferences = userPreferences,
                googleBackupState = googleBackupState,
                onAvatarClick = { showProfilePhotoOptionsDialog = true },
                onEditNameClick = { showEditProfileDialog = true },
                onConnectGoogleClick = { googleSignInLauncher.launch(viewModel.getGoogleSignInIntent()) },
                onDisconnectGoogleClick = { showDisconnectGoogleDialog = true }
            )

            // 1. Personalization Section
            SettingsSectionContainer(title = stringResource(R.string.settings_section_personalization)) {
                ThemeSelectionSection(
                    currentThemeMode = userPreferences.themeMode,
                    onThemeModeSelected = { viewModel.onThemeModeSelected(it) }
                )

                SettingsDivider()

                val currentLanguage = AppLanguage.fromCode(userPreferences.appLanguage)
                SettingsNavigationTile(
                    icon = Icons.Default.Translate,
                    title = stringResource(R.string.settings_language_title),
                    valueBadge = currentLanguage.nativeName,
                    onClick = { showLanguageDialog = true }
                )

                SettingsDivider()

                SettingsSwitchTile(
                    icon = Icons.Default.VisibilityOff,
                    title = stringResource(R.string.settings_balance_visibility_title),
                    subtitle = if (userPreferences.isBalanceVisible) stringResource(R.string.settings_balance_visible)
                    else stringResource(R.string.settings_balance_hidden),
                    checked = userPreferences.isBalanceVisible,
                    onCheckedChange = { viewModel.toggleBalanceVisibility() }
                )
            }

            // 2. Finance Section
            SettingsSectionContainer(title = stringResource(R.string.settings_section_finance)) {
                SettingsNavigationTile(
                    icon = Icons.Default.AccountBalance,
                    title = stringResource(R.string.settings_currency_title),
                    valueBadge = "${userPreferences.currency.symbol} ${userPreferences.currency.code}",
                    onClick = { showCurrencyDialog = true }
                )

                SettingsDivider()

                SettingsNavigationTile(
                    icon = Icons.Default.Payments,
                    title = stringResource(R.string.settings_opening_balance_title),
                    valueBadge = userPreferences.openingBalance.format(userPreferences.currency),
                    onClick = { showOpeningBalanceDialog = true }
                )

                SettingsDivider()

                val budgetLimitBadge = if (userPreferences.monthlyBudgetLimitSubunits > 0L) {
                    userPreferences.monthlyBudgetLimit.format(userPreferences.currency)
                } else {
                    stringResource(R.string.settings_monthly_budget_not_set)
                }

                SettingsNavigationTile(
                    icon = Icons.Default.PieChart,
                    title = stringResource(R.string.settings_monthly_budget_title),
                    valueBadge = budgetLimitBadge,
                    onClick = { showBudgetLimitDialog = true }
                )

                SettingsDivider()

                SettingsNavigationTile(
                    icon = Icons.Default.Category,
                    title = stringResource(R.string.settings_categories_title),
                    subtitle = stringResource(R.string.settings_categories_subtitle),
                    onClick = onNavigateToCategories
                )

                SettingsDivider()

                DefaultSourceSettingRow(
                    title = "Default Expense Source",
                    selectedMethod = userPreferences.defaultExpenseSource,
                    onMethodSelect = { viewModel.onDefaultExpenseSourceSelected(it) }
                )

                SettingsDivider()

                DefaultSourceSettingRow(
                    title = "Default Income Source",
                    selectedMethod = userPreferences.defaultIncomeSource,
                    onMethodSelect = { viewModel.onDefaultIncomeSourceSelected(it) }
                )

                SettingsDivider()

                SettingsNavigationTile(
                    icon = Icons.AutoMirrored.Filled.ReceiptLong,
                    title = stringResource(R.string.settings_recurring_title),
                    subtitle = stringResource(R.string.settings_recurring_subtitle),
                    onClick = onNavigateToRecurring
                )
            }

            // 3. Notifications & Reminders Section
            SettingsSectionContainer(title = stringResource(R.string.settings_section_notifications)) {
                SettingsSwitchTile(
                    icon = Icons.Default.Notifications,
                    title = stringResource(R.string.settings_notifications_master_title),
                    subtitle = stringResource(R.string.settings_notifications_master_desc),
                    checked = userPreferences.notificationsMasterEnabled,
                    onCheckedChange = { isChecked ->
                        if (isChecked) {
                            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU &&
                                ContextCompat.checkSelfPermission(context, Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED
                            ) {
                                permissionLauncher.launch(Manifest.permission.POST_NOTIFICATIONS)
                            } else {
                                viewModel.onNotificationsMasterToggled(true)
                            }
                        } else {
                            viewModel.onNotificationsMasterToggled(false)
                        }
                    }
                )

                AnimatedVisibility(
                    visible = userPreferences.notificationsMasterEnabled,
                    enter = expandVertically() + fadeIn(),
                    exit = shrinkVertically() + fadeOut()
                ) {
                    Column {
                        SettingsDivider()

                        // Loan & EMI Reminders
                        SettingsSwitchTile(
                            icon = Icons.Default.AccountBalance,
                            title = stringResource(R.string.settings_notif_loan_emi_title),
                            subtitle = stringResource(R.string.settings_notif_loan_emi_desc),
                            checked = userPreferences.emiRemindersEnabled,
                            onCheckedChange = { viewModel.onLoanRemindersToggled(it) }
                        )

                        SettingsDivider()

                        // Bill & Utility Reminders
                        SettingsSwitchTile(
                            icon = Icons.AutoMirrored.Filled.ReceiptLong,
                            title = stringResource(R.string.settings_notif_bill_title),
                            subtitle = stringResource(R.string.settings_notif_bill_desc),
                            checked = userPreferences.billRemindersEnabled,
                            onCheckedChange = { viewModel.onBillRemindersToggled(it) }
                        )

                        SettingsDivider()

                        // Credit Card Reminders
                        SettingsSwitchTile(
                            icon = Icons.Default.CreditCard,
                            title = stringResource(R.string.settings_notif_credit_card_title),
                            subtitle = stringResource(R.string.settings_notif_credit_card_desc),
                            checked = userPreferences.creditCardRemindersEnabled,
                            onCheckedChange = { viewModel.onCreditCardRemindersToggled(it) }
                        )

                        SettingsDivider()

                        // Daily Expense Reminder
                        SettingsSwitchTile(
                            icon = Icons.Default.Schedule,
                            title = stringResource(R.string.settings_notif_daily_reminder_title),
                            checked = userPreferences.dailyReminderEnabled,
                            onCheckedChange = { viewModel.onDailyReminderToggled(it) }
                        )

                        if (userPreferences.dailyReminderEnabled) {
                            val timeFormatter = remember { DateTimeFormatter.ofLocalizedTime(FormatStyle.SHORT) }
                            val formattedTime = remember(userPreferences.dailyReminderHour, userPreferences.dailyReminderMinute) {
                                LocalTime.of(userPreferences.dailyReminderHour, userPreferences.dailyReminderMinute).format(timeFormatter)
                            }

                            SettingsNavigationTile(
                                icon = Icons.Default.Schedule,
                                title = stringResource(R.string.settings_reminder_time_title),
                                valueBadge = formattedTime,
                                onClick = { showTimePickerDialog = true }
                            )
                        }

                        SettingsDivider()

                        // Budget Alerts
                        SettingsSwitchTile(
                            icon = Icons.Default.PieChart,
                            title = stringResource(R.string.settings_notif_budget_alerts_title),
                            checked = userPreferences.budgetAlertsEnabled,
                            onCheckedChange = { viewModel.onBudgetAlertsToggled(it) }
                        )

                        SettingsDivider()

                        // Savings Goal Milestones
                        SettingsSwitchTile(
                            icon = Icons.Default.Flag,
                            title = stringResource(R.string.settings_notif_savings_goals_title),
                            checked = userPreferences.savingsGoalNotificationsEnabled,
                            onCheckedChange = { viewModel.onSavingsGoalNotificationsToggled(it) }
                        )

                        SettingsDivider()

                        // Default Reminder Offset
                        val defaultOffsetBadge = when (userPreferences.defaultReminderOffsetDays) {
                            0 -> stringResource(R.string.reminder_offset_on_due_date)
                            1 -> stringResource(R.string.reminder_offset_1_day)
                            2 -> stringResource(R.string.reminder_offset_2_days)
                            3 -> stringResource(R.string.reminder_offset_3_days)
                            5 -> stringResource(R.string.reminder_offset_5_days)
                            7 -> stringResource(R.string.reminder_offset_7_days)
                            else -> "${userPreferences.defaultReminderOffsetDays} days before"
                        }
                        SettingsNavigationTile(
                            icon = Icons.Default.Timer,
                            title = stringResource(R.string.settings_notif_default_offset_title),
                            valueBadge = defaultOffsetBadge,
                            onClick = { showDefaultOffsetDialog = true }
                        )

                        SettingsDivider()

                        // Default Notification Time
                        val formattedDefaultTime = String.format("%02d:%02d", userPreferences.defaultReminderHour, userPreferences.defaultReminderMinute)
                        SettingsNavigationTile(
                            icon = Icons.Default.Schedule,
                            title = stringResource(R.string.settings_notif_default_time_title),
                            valueBadge = formattedDefaultTime,
                            onClick = { showDefaultTimePickerDialog = true }
                        )

                        SettingsDivider()

                        // Manage Reminders
                        SettingsNavigationTile(
                            icon = Icons.Default.Notifications,
                            title = stringResource(R.string.reminders_title),
                            subtitle = "View and configure all payment obligations",
                            onClick = onNavigateToReminders
                        )
                    }
                }
            }

            // 4. Security & Privacy Section
            SettingsSectionContainer(title = stringResource(R.string.settings_section_security)) {
                SettingsSwitchTile(
                    icon = Icons.Default.Lock,
                    title = stringResource(R.string.settings_app_lock_title),
                    subtitle = if (userPreferences.appLockEnabled) stringResource(R.string.settings_enabled)
                    else stringResource(R.string.settings_disabled),
                    checked = userPreferences.appLockEnabled,
                    onCheckedChange = { isChecked ->
                        if (isChecked) {
                            onNavigateToAppLockSetup()
                        } else {
                            showDisableAppLockDialog = true
                        }
                    }
                )

                AnimatedVisibility(
                    visible = userPreferences.appLockEnabled,
                    enter = expandVertically() + fadeIn(),
                    exit = shrinkVertically() + fadeOut()
                ) {
                    Column {
                        SettingsDivider()

                        if (isBiometricAvailable) {
                            SettingsNavigationTile(
                                icon = Icons.Default.Fingerprint,
                                title = stringResource(R.string.settings_biometric_title),
                                valueBadge = if (userPreferences.biometricEnabled) "Biometric + PIN" else "PIN Only",
                                onClick = { showUnlockMethodDialog = true }
                            )
                            SettingsDivider()
                        }

                        val autoLockBadge = when (userPreferences.autoLockDurationSeconds) {
                            0L -> "Immediately"
                            30L -> "30 seconds"
                            60L -> "1 minute"
                            300L -> "5 minutes"
                            else -> "${userPreferences.autoLockDurationSeconds}s"
                        }

                        SettingsNavigationTile(
                            icon = Icons.Default.Timer,
                            title = stringResource(R.string.settings_auto_lock_title),
                            valueBadge = autoLockBadge,
                            onClick = { showAutoLockDialog = true }
                        )

                        SettingsDivider()

                        SettingsNavigationTile(
                            icon = Icons.Default.LockReset,
                            title = stringResource(R.string.settings_change_pin),
                            onClick = onNavigateToChangePin
                        )

                        SettingsDivider()

                        SettingsSwitchTile(
                            icon = Icons.Default.VisibilityOff,
                            title = stringResource(R.string.settings_privacy_recents_title),
                            subtitle = stringResource(R.string.settings_privacy_recents_desc),
                            checked = userPreferences.hideContentInRecents,
                            onCheckedChange = { viewModel.onHideContentInRecentsToggled(it) }
                        )
                    }
                }
            }

            // 5. Data & Tools Section
            SettingsSectionContainer(title = stringResource(R.string.settings_section_data)) {
                SettingsNavigationTile(
                    icon = Icons.Default.Sync,
                    title = stringResource(R.string.settings_local_backup_title),
                    subtitle = stringResource(R.string.settings_local_backup_desc),
                    onClick = onNavigateToBackup
                )

                SettingsDivider()

                val lastTimestamp = (googleBackupState as? GoogleBackupState.Connected)?.lastBackupTimestamp
                    ?: userPreferences.lastDismissedRestoreBackupTimestamp
                val statusText = when {
                    userPreferences.lastBackupStatus == "FAILED" -> {
                        stringResource(R.string.backup_status_failed)
                    }
                    lastTimestamp != null && lastTimestamp > 0L -> {
                        val instant = java.time.Instant.ofEpochMilli(lastTimestamp)
                        val formatted = java.time.format.DateTimeFormatter.ofLocalizedDateTime(
                            java.time.format.FormatStyle.MEDIUM,
                            java.time.format.FormatStyle.SHORT
                        ).format(instant.atZone(java.time.ZoneId.systemDefault()))
                        stringResource(R.string.backup_status_last_success, formatted)
                    }
                    else -> stringResource(R.string.backup_status_no_backup)
                }

                SettingsNavigationTile(
                    icon = Icons.Default.CloudSync,
                    title = stringResource(R.string.settings_google_backup_title),
                    subtitle = statusText,
                    valueBadge = if (googleBackupState is GoogleBackupState.Connected) "Connected" else "Not Connected",
                    onClick = onNavigateToBackup
                )

                SettingsDivider()

                SettingsNavigationTile(
                    icon = Icons.Default.Description,
                    title = stringResource(R.string.settings_statements_title),
                    subtitle = stringResource(R.string.settings_statements_subtitle),
                    onClick = onNavigateToStatements
                )

                SettingsDivider()

                SettingsNavigationTile(
                    icon = Icons.Default.Calculate,
                    title = stringResource(R.string.settings_tools_title),
                    subtitle = stringResource(R.string.settings_tools_subtitle),
                    onClick = onNavigateToTools
                )
            }

            // 6. About Leaf Section
            SettingsSectionContainer(title = stringResource(R.string.settings_section_about)) {
                SettingsNavigationTile(
                    icon = Icons.Default.Info,
                    title = stringResource(R.string.settings_about_leaf_title),
                    subtitle = "Privacy-focused & offline-first personal finance",
                    valueBadge = "v${BuildConfig.VERSION_NAME}",
                    onClick = onNavigateToAbout
                )

                SettingsDivider()

                SettingsNavigationTile(
                    icon = Icons.Default.Flag,
                    title = stringResource(R.string.settings_whats_new_title),
                    subtitle = stringResource(R.string.settings_whats_new_desc),
                    onClick = { showWhatsNewDialog = true }
                )
            }

            Spacer(modifier = Modifier.height(MaterialTheme.spacing.md))
        }
    }

    // --- Dialogs ---

    if (showEditProfileDialog) {
        val currentName = userPreferences.userName ?: (googleBackupState as? GoogleBackupState.Connected)?.account?.displayName
        EditProfileDialog(
            currentName = currentName,
            onSave = { newName ->
                viewModel.onProfileNameChanged(newName)
                showEditProfileDialog = false
            },
            onDismiss = { showEditProfileDialog = false }
        )
    }

    if (showProfilePhotoOptionsDialog) {
        ProfilePhotoOptionsDialog(
            hasCustomPhoto = !userPreferences.profileImageUri.isNullOrBlank(),
            onChoosePhoto = {
                showProfilePhotoOptionsDialog = false
                photoPickerLauncher.launch(
                    PickVisualMediaRequest(ActivityResultContracts.PickVisualMedia.ImageOnly)
                )
            },
            onRemovePhoto = {
                showProfilePhotoOptionsDialog = false
                viewModel.onRemoveProfileImage()
            },
            onDismiss = { showProfilePhotoOptionsDialog = false }
        )
    }

    if (showCurrencyDialog) {
        CurrencySelectionDialog(
            selectedCurrency = userPreferences.currency,
            onCurrencySelected = { currency ->
                viewModel.onCurrencySelected(currency)
                WidgetUpdateManager.refreshAllWidgets(context)
                showCurrencyDialog = false
            },
            onDismiss = { showCurrencyDialog = false }
        )
    }

    if (showOpeningBalanceDialog) {
        OpeningBalanceDialog(
            initialSubunits = userPreferences.openingBalanceSubunits,
            currency = userPreferences.currency,
            onDismiss = { showOpeningBalanceDialog = false },
            onSave = { newSubunits ->
                viewModel.onOpeningBalanceChanged(newSubunits)
                WidgetUpdateManager.refreshAllWidgets(context)
            }
        )
    }

    if (showLanguageDialog) {
        LanguageSelectionDialog(
            currentLanguageCode = userPreferences.appLanguage,
            onLanguageSelected = { languageCode ->
                viewModel.onLanguageSelected(languageCode)
                showLanguageDialog = false
            },
            onDismiss = { showLanguageDialog = false }
        )
    }

    if (showTimePickerDialog) {
        ReminderTimePickerDialog(
            initialHour = userPreferences.dailyReminderHour,
            initialMinute = userPreferences.dailyReminderMinute,
            onTimeSelected = { hour, minute ->
                viewModel.onReminderTimeSelected(hour, minute)
            },
            onDismiss = { showTimePickerDialog = false }
        )
    }

    if (showBudgetLimitDialog) {
        MonthlyBudgetLimitDialog(
            currentLimit = userPreferences.monthlyBudgetLimit,
            currency = userPreferences.currency,
            onSave = { newLimitSubunits ->
                viewModel.onMonthlyBudgetLimitChanged(newLimitSubunits)
            },
            onDismiss = { showBudgetLimitDialog = false }
        )
    }

    if (showRecurringAdvanceDialog) {
        RecurringAdvanceSelectionDialog(
            currentAdvanceDays = userPreferences.recurringReminderAdvanceDays,
            onDaysSelected = { days ->
                viewModel.onRecurringReminderAdvanceDaysSelected(days)
            },
            onDismiss = { showRecurringAdvanceDialog = false }
        )
    }

    if (showAutoLockDialog) {
        AutoLockSelectionDialog(
            currentDurationSeconds = userPreferences.autoLockDurationSeconds,
            onDurationSelected = { seconds ->
                viewModel.onAutoLockDurationSelected(seconds)
                showAutoLockDialog = false
            },
            onDismiss = { showAutoLockDialog = false }
        )
    }

    if (showUnlockMethodDialog) {
        UnlockMethodDialog(
            isBiometricEnabled = userPreferences.biometricEnabled,
            onMethodSelected = { enableBiometric ->
                viewModel.onBiometricToggled(enableBiometric)
                showUnlockMethodDialog = false
            },
            onDismiss = { showUnlockMethodDialog = false }
        )
    }

    if (showDisableAppLockDialog) {
        val disabledMessage = stringResource(R.string.app_lock_disabled_success)
        val coroutineScope = rememberCoroutineScope()
        DisableAppLockVerificationDialog(
            onDismiss = { showDisableAppLockDialog = false },
            onVerifyAndDisable = { pin, onSuccess, onError ->
                viewModel.verifyAndDisableAppLock(pin, onSuccess, onError)
            },
            getLockoutSeconds = { viewModel.getLockoutSecondsRemaining() },
            onDisabledSuccess = {
                showDisableAppLockDialog = false
                coroutineScope.launch {
                    snackbarHostState.showSnackbar(disabledMessage)
                }
            }
        )
    }

    if (showDisconnectGoogleDialog) {
        AlertDialog(
            onDismissRequest = { showDisconnectGoogleDialog = false },
            icon = {
                Icon(
                    imageVector = Icons.Default.CloudOff,
                    contentDescription = null,
                    tint = MaterialTheme.colorScheme.error,
                    modifier = Modifier.size(32.dp)
                )
            },
            title = {
                Text(
                    text = "Disconnect Google Account?",
                    style = MaterialTheme.typography.titleMedium.copy(fontWeight = FontWeight.Bold)
                )
            },
            text = {
                Text(
                    text = "Your local transaction data will NOT be deleted. Google Drive cloud backup will be disabled until you reconnect.",
                    style = MaterialTheme.typography.bodyMedium
                )
            },
            confirmButton = {
                TextButton(
                    onClick = {
                        showDisconnectGoogleDialog = false
                        viewModel.disconnectGoogleAccount()
                    }
                ) {
                    Text(
                        text = "Disconnect",
                        color = MaterialTheme.colorScheme.error,
                        fontWeight = FontWeight.Bold
                    )
                }
            },
            dismissButton = {
                TextButton(onClick = { showDisconnectGoogleDialog = false }) {
                    Text("Cancel")
                }
            }
        )
    }

    restorePromptEligibility?.let { eligible ->
        RestorePromptDialog(
            backupDate = eligible.formattedDate,
            backupSizeBytes = eligible.metadata.sizeBytes,
            onRestoreClick = { viewModel.onRestorePromptAccepted() },
            onNotNowClick = { viewModel.onDismissRestorePrompt(dontAskAgain = false) },
            onDontAskAgainClick = { viewModel.onDismissRestorePrompt(dontAskAgain = true) }
        )
    }

    if (showReplaceConfirmation) {
        ReplaceDataConfirmationDialog(
            onConfirmReplace = { viewModel.onConfirmReplaceAndRestore() },
            onDismiss = { viewModel.onCancelReplaceConfirmation() }
        )
    }

    val cropUri = pendingCropImageUri
    if (cropUri != null) {
        ImageCropDialog(
            imageUri = cropUri,
            onCropConfirmed = { croppedUriString ->
                viewModel.onProfileImageSelected(croppedUriString)
                pendingCropImageUri = null
            },
            onDismiss = {
                pendingCropImageUri = null
            }
        )
    }

    if (showDefaultOffsetDialog) {
        DefaultReminderOffsetDialog(
            currentOffsetDays = userPreferences.defaultReminderOffsetDays,
            onOffsetSelected = { offset ->
                viewModel.onDefaultReminderOffsetSelected(offset)
                showDefaultOffsetDialog = false
            },
            onDismiss = { showDefaultOffsetDialog = false }
        )
    }

    if (showDefaultTimePickerDialog) {
        ReminderTimePickerDialog(
            initialHour = userPreferences.defaultReminderHour,
            initialMinute = userPreferences.defaultReminderMinute,
            onTimeSelected = { hour, minute ->
                viewModel.onDefaultReminderTimeSelected(hour, minute)
                showDefaultTimePickerDialog = false
            },
            onDismiss = { showDefaultTimePickerDialog = false }
        )
    }

    if (showWhatsNewDialog) {
        WhatsNewDialog(
            onDismiss = { showWhatsNewDialog = false }
        )
    }
}


@Composable
private fun SettingOptionChip(
    label: String,
    icon: ImageVector,
    isSelected: Boolean,
    onClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    val interactionSource = remember { MutableInteractionSource() }
    val animatedBg by animateColorAsState(
        targetValue = if (isSelected) MaterialTheme.colorScheme.primaryContainer else MaterialTheme.colorScheme.surface,
        animationSpec = tween(com.vinaynalavade.expensetracker.presentation.theme.Motion.DurationFast),
        label = "ThemeChipBg"
    )
    val animatedBorderColor by animateColorAsState(
        targetValue = if (isSelected) MaterialTheme.colorScheme.primary else MaterialTheme.colorScheme.outline.copy(alpha = 0.25f),
        animationSpec = tween(com.vinaynalavade.expensetracker.presentation.theme.Motion.DurationFast),
        label = "ThemeChipBorder"
    )

    Surface(
        shape = PillShape,
        color = animatedBg,
        border = androidx.compose.foundation.BorderStroke(
            width = if (isSelected) 1.5.dp else 1.dp,
            color = animatedBorderColor
        ),
        modifier = modifier
            .clip(PillShape)
            .pressScale(interactionSource = interactionSource)
            .clickable(
                interactionSource = interactionSource,
                indication = androidx.compose.material3.ripple(),
                onClick = onClick
            )
    ) {
        Row(
            modifier = Modifier.padding(horizontal = MaterialTheme.spacing.sm, vertical = MaterialTheme.spacing.sm),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.Center
        ) {
            Icon(
                imageVector = icon,
                contentDescription = null,
                tint = if (isSelected) MaterialTheme.colorScheme.primary else MaterialTheme.colorScheme.onSurfaceVariant,
                modifier = Modifier.size(16.dp)
            )
            Spacer(modifier = Modifier.width(4.dp))
            Text(
                text = label,
                style = MaterialTheme.typography.labelSmall,
                fontWeight = if (isSelected) FontWeight.Bold else FontWeight.Medium,
                color = if (isSelected) MaterialTheme.colorScheme.onPrimaryContainer else MaterialTheme.colorScheme.onSurface
            )
        }
    }
}

@Composable
private fun CurrencySelectionDialog(
    selectedCurrency: Currency,
    onCurrencySelected: (Currency) -> Unit,
    onDismiss: () -> Unit
) {
    AlertDialog(
        onDismissRequest = onDismiss,
        properties = DialogProperties(
            dismissOnBackPress = true,
            dismissOnClickOutside = true,
            usePlatformDefaultWidth = false
        ),
        modifier = Modifier
            .fillMaxWidth(0.92f)
            .widthIn(max = 420.dp),
        title = {
            Text(
                text = "Select Default Currency",
                style = MaterialTheme.typography.titleMedium.copy(fontWeight = FontWeight.Bold)
            )
        },
        text = {
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .verticalScroll(rememberScrollState()),
                verticalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                Currency.SUPPORTED_CURRENCIES.forEach { currency ->
                    val isSelected = currency.code == selectedCurrency.code
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .clip(RoundedCornerShape(8.dp))
                            .clickable { onCurrencySelected(currency) }
                            .padding(vertical = 10.dp, horizontal = 8.dp),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Icon(
                            imageVector = if (isSelected) Icons.Default.RadioButtonChecked else Icons.Default.RadioButtonUnchecked,
                            contentDescription = null,
                            tint = if (isSelected) MaterialTheme.colorScheme.primary else MaterialTheme.colorScheme.onSurfaceVariant,
                            modifier = Modifier.size(20.dp)
                        )
                        Spacer(modifier = Modifier.width(12.dp))
                        Column {
                            Text(
                                text = "${currency.symbol} ${currency.name} (${currency.code})",
                                style = MaterialTheme.typography.bodyMedium.copy(
                                    fontWeight = if (isSelected) FontWeight.SemiBold else FontWeight.Normal,
                                    color = if (isSelected) MaterialTheme.colorScheme.primary else MaterialTheme.colorScheme.onSurface
                                )
                            )
                        }
                    }
                }
            }
        },
        confirmButton = {},
        dismissButton = {
            TextButton(onClick = onDismiss) {
                Text("Cancel")
            }
        }
    )
}

@Composable
private fun OpeningBalanceDialog(
    initialSubunits: Long,
    currency: Currency,
    onDismiss: () -> Unit,
    onSave: (Long) -> Unit
) {
    var rawInput by remember {
        mutableStateOf(if (initialSubunits == 0L) "" else (initialSubunits / 100.0).toString().removeSuffix(".0"))
    }

    AlertDialog(
        onDismissRequest = onDismiss,
        properties = DialogProperties(
            dismissOnBackPress = true,
            dismissOnClickOutside = true,
            usePlatformDefaultWidth = false
        ),
        modifier = Modifier
            .fillMaxWidth(0.92f)
            .widthIn(max = 420.dp),
        title = {
            Text(
                text = "Set Starting Balance",
                style = MaterialTheme.typography.titleMedium.copy(fontWeight = FontWeight.Bold)
            )
        },
        text = {
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .verticalScroll(rememberScrollState()),
                verticalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                Text(
                    text = "Enter your starting account balance. This will be added to your net total calculations.",
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
                OutlinedTextField(
                    value = rawInput,
                    onValueChange = { newValue ->
                        if (newValue.isEmpty() || newValue.matches(Regex("""^-?\d*\.?\d{0,2}$"""))) {
                            rawInput = newValue
                        }
                    },
                    label = { Text("Opening Balance") },
                    prefix = { Text(currency.symbol) },
                    singleLine = true,
                    keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Decimal),
                    modifier = Modifier.fillMaxWidth()
                )
            }
        },
        confirmButton = {
            TextButton(
                onClick = {
                    val amountSubunits = Amount.fromStringOrNull(rawInput, currency)?.subunits ?: 0L
                    onSave(amountSubunits)
                    onDismiss()
                }
            ) {
                Text("Save", fontWeight = FontWeight.Bold)
            }
        },
        dismissButton = {
            TextButton(onClick = onDismiss) {
                Text("Cancel")
            }
        }
    )
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun ReminderTimePickerDialog(
    initialHour: Int,
    initialMinute: Int,
    onTimeSelected: (Int, Int) -> Unit,
    onDismiss: () -> Unit
) {
    val timePickerState = rememberTimePickerState(
        initialHour = initialHour,
        initialMinute = initialMinute,
        is24Hour = false
    )

    AlertDialog(
        onDismissRequest = onDismiss,
        title = {
            Text(
                text = stringResource(R.string.settings_select_time),
                style = MaterialTheme.typography.titleMedium.copy(fontWeight = FontWeight.Bold)
            )
        },
        text = {
            Box(
                modifier = Modifier.fillMaxWidth(),
                contentAlignment = Alignment.Center
            ) {
                TimePicker(state = timePickerState)
            }
        },
        confirmButton = {
            TextButton(
                onClick = {
                    onTimeSelected(timePickerState.hour, timePickerState.minute)
                    onDismiss()
                }
            ) {
                Text("OK", fontWeight = FontWeight.Bold)
            }
        },
        dismissButton = {
            TextButton(onClick = onDismiss) {
                Text("Cancel")
            }
        }
    )
}

@Composable
private fun MonthlyBudgetLimitDialog(
    currentLimit: Amount,
    currency: Currency,
    onSave: (Long) -> Unit,
    onDismiss: () -> Unit
) {
    var rawInput by remember {
        mutableStateOf(if (currentLimit.isZero) "" else (currentLimit.subunits / 100.0).toString().removeSuffix(".0"))
    }

    AlertDialog(
        onDismissRequest = onDismiss,
        properties = DialogProperties(
            dismissOnBackPress = true,
            dismissOnClickOutside = true,
            usePlatformDefaultWidth = false
        ),
        modifier = Modifier
            .fillMaxWidth(0.92f)
            .widthIn(max = 420.dp),
        title = {
            Text(
                text = stringResource(R.string.settings_budget_limit_title),
                style = MaterialTheme.typography.titleMedium.copy(fontWeight = FontWeight.Bold)
            )
        },
        text = {
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .verticalScroll(rememberScrollState()),
                verticalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                Text(
                    text = "Set your monthly spending target. You will receive alerts when reaching 50%, 75%, 90%, 100%, and when over budget.",
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
                OutlinedTextField(
                    value = rawInput,
                    onValueChange = { newValue ->
                        if (newValue.isEmpty() || newValue.matches(Regex("""^\d*\.?\d{0,2}$"""))) {
                            rawInput = newValue
                        }
                    },
                    label = { Text("Monthly Budget") },
                    prefix = { Text(currency.symbol) },
                    singleLine = true,
                    keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Decimal),
                    modifier = Modifier.fillMaxWidth()
                )
            }
        },
        confirmButton = {
            TextButton(
                onClick = {
                    val amountSubunits = Amount.fromStringOrNull(rawInput, currency)?.subunits ?: 0L
                    onSave(amountSubunits)
                    onDismiss()
                }
            ) {
                Text("Save", fontWeight = FontWeight.Bold)
            }
        },
        dismissButton = {
            TextButton(onClick = onDismiss) {
                Text("Cancel")
            }
        }
    )
}

@Composable
private fun RecurringAdvanceSelectionDialog(
    currentAdvanceDays: Int,
    onDaysSelected: (Int) -> Unit,
    onDismiss: () -> Unit
) {
    val options = listOf(
        RecurringReminderAdvance.ON_DUE_DATE,
        RecurringReminderAdvance.ONE_DAY_BEFORE,
        RecurringReminderAdvance.THREE_DAYS_BEFORE,
        RecurringReminderAdvance.SEVEN_DAYS_BEFORE
    )

    AlertDialog(
        onDismissRequest = onDismiss,
        properties = DialogProperties(
            dismissOnBackPress = true,
            dismissOnClickOutside = true,
            usePlatformDefaultWidth = false
        ),
        modifier = Modifier
            .fillMaxWidth(0.92f)
            .widthIn(max = 420.dp),
        title = {
            Text(
                text = stringResource(R.string.settings_recurring_advance_title),
                style = MaterialTheme.typography.titleMedium.copy(fontWeight = FontWeight.Bold)
            )
        },
        text = {
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .verticalScroll(rememberScrollState()),
                verticalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                options.forEach { advance ->
                    val isSelected = currentAdvanceDays == advance.days
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .clip(RoundedCornerShape(8.dp))
                            .clickable {
                                onDaysSelected(advance.days)
                                onDismiss()
                            }
                            .padding(vertical = 10.dp, horizontal = 8.dp),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Icon(
                            imageVector = if (isSelected) Icons.Default.RadioButtonChecked else Icons.Default.RadioButtonUnchecked,
                            contentDescription = null,
                            tint = if (isSelected) MaterialTheme.colorScheme.primary else MaterialTheme.colorScheme.onSurfaceVariant,
                            modifier = Modifier.size(20.dp)
                        )
                        Spacer(modifier = Modifier.width(12.dp))
                        Text(
                            text = advance.label,
                            style = MaterialTheme.typography.bodyMedium.copy(
                                fontWeight = if (isSelected) FontWeight.SemiBold else FontWeight.Normal,
                                color = if (isSelected) MaterialTheme.colorScheme.primary else MaterialTheme.colorScheme.onSurface
                            )
                        )
                    }
                }
            }
        },
        confirmButton = {},
        dismissButton = {
            TextButton(onClick = onDismiss) {
                Text("Cancel")
            }
        }
    )
}

@Composable
private fun AutoLockSelectionDialog(
    currentDurationSeconds: Long,
    onDurationSelected: (Long) -> Unit,
    onDismiss: () -> Unit
) {
    val options = listOf(
        0L to "Immediately",
        30L to "After 30 seconds",
        60L to "After 1 minute",
        300L to "After 5 minutes"
    )

    AlertDialog(
        onDismissRequest = onDismiss,
        properties = DialogProperties(
            dismissOnBackPress = true,
            dismissOnClickOutside = true,
            usePlatformDefaultWidth = false
        ),
        modifier = Modifier
            .fillMaxWidth(0.92f)
            .widthIn(max = 420.dp),
        title = {
            Text(
                text = stringResource(R.string.settings_auto_lock_title),
                style = MaterialTheme.typography.titleMedium.copy(fontWeight = FontWeight.Bold)
            )
        },
        text = {
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .verticalScroll(rememberScrollState()),
                verticalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                options.forEach { (seconds, label) ->
                    val isSelected = currentDurationSeconds == seconds
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .clip(RoundedCornerShape(8.dp))
                            .clickable { onDurationSelected(seconds) }
                            .padding(vertical = 10.dp, horizontal = 8.dp),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Icon(
                            imageVector = if (isSelected) Icons.Default.RadioButtonChecked else Icons.Default.RadioButtonUnchecked,
                            contentDescription = null,
                            tint = if (isSelected) MaterialTheme.colorScheme.primary else MaterialTheme.colorScheme.onSurfaceVariant,
                            modifier = Modifier.size(20.dp)
                        )
                        Spacer(modifier = Modifier.width(12.dp))
                        Text(
                            text = label,
                            style = MaterialTheme.typography.bodyMedium.copy(
                                fontWeight = if (isSelected) FontWeight.SemiBold else FontWeight.Normal,
                                color = if (isSelected) MaterialTheme.colorScheme.primary else MaterialTheme.colorScheme.onSurface
                            )
                        )
                    }
                }
            }
        },
        confirmButton = {},
        dismissButton = {
            TextButton(onClick = onDismiss) {
                Text("Cancel")
            }
        }
    )
}

@Composable
private fun UnlockMethodDialog(
    isBiometricEnabled: Boolean,
    onMethodSelected: (Boolean) -> Unit,
    onDismiss: () -> Unit
) {
    AlertDialog(
        onDismissRequest = onDismiss,
        properties = DialogProperties(
            dismissOnBackPress = true,
            dismissOnClickOutside = true,
            usePlatformDefaultWidth = false
        ),
        modifier = Modifier
            .fillMaxWidth(0.92f)
            .widthIn(max = 420.dp),
        title = {
            Text(
                text = stringResource(R.string.settings_unlock_method_title),
                style = MaterialTheme.typography.titleMedium.copy(fontWeight = FontWeight.Bold)
            )
        },
        text = {
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .verticalScroll(rememberScrollState()),
                verticalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .clip(RoundedCornerShape(8.dp))
                        .clickable { onMethodSelected(true) }
                        .padding(vertical = 10.dp, horizontal = 8.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Icon(
                        imageVector = if (isBiometricEnabled) Icons.Default.RadioButtonChecked else Icons.Default.RadioButtonUnchecked,
                        contentDescription = null,
                        tint = if (isBiometricEnabled) MaterialTheme.colorScheme.primary else MaterialTheme.colorScheme.onSurfaceVariant,
                        modifier = Modifier.size(20.dp)
                    )
                    Spacer(modifier = Modifier.width(12.dp))
                    Column {
                        Text(
                            text = "Biometric + PIN (Recommended)",
                            style = MaterialTheme.typography.bodyMedium.copy(
                                fontWeight = if (isBiometricEnabled) FontWeight.SemiBold else FontWeight.Normal,
                                color = if (isBiometricEnabled) MaterialTheme.colorScheme.primary else MaterialTheme.colorScheme.onSurface
                            )
                        )
                        Text(
                            text = "Use fingerprint or face unlock, with PIN fallback",
                            style = MaterialTheme.typography.bodySmall,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                    }
                }

                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .clip(RoundedCornerShape(8.dp))
                        .clickable { onMethodSelected(false) }
                        .padding(vertical = 10.dp, horizontal = 8.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Icon(
                        imageVector = if (!isBiometricEnabled) Icons.Default.RadioButtonChecked else Icons.Default.RadioButtonUnchecked,
                        contentDescription = null,
                        tint = if (!isBiometricEnabled) MaterialTheme.colorScheme.primary else MaterialTheme.colorScheme.onSurfaceVariant,
                        modifier = Modifier.size(20.dp)
                    )
                    Spacer(modifier = Modifier.width(12.dp))
                    Column {
                        Text(
                            text = "PIN Only",
                            style = MaterialTheme.typography.bodyMedium.copy(
                                fontWeight = if (!isBiometricEnabled) FontWeight.SemiBold else FontWeight.Normal,
                                color = if (!isBiometricEnabled) MaterialTheme.colorScheme.primary else MaterialTheme.colorScheme.onSurface
                            )
                        )
                        Text(
                            text = "Always enter your 4-digit PIN manually",
                            style = MaterialTheme.typography.bodySmall,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                    }
                }
            }
        },
        confirmButton = {},
        dismissButton = {
            TextButton(onClick = onDismiss) {
                Text("Cancel")
            }
        }
    )
}

@Composable
private fun DefaultSourceSettingRow(
    title: String,
    selectedMethod: PaymentMethod,
    onMethodSelect: (PaymentMethod) -> Unit,
    modifier: Modifier = Modifier,
    subtitle: String? = null
) {
    SettingsCustomTile(
        title = title,
        subtitle = subtitle,
        modifier = modifier
    ) {
        Row(
            horizontalArrangement = Arrangement.spacedBy(MaterialTheme.spacing.xs),
            verticalAlignment = Alignment.CenterVertically
        ) {
            PaymentMethod.entries.forEach { method ->
                val isSelected = selectedMethod == method
                val icon = when (method) {
                    PaymentMethod.CASH -> Icons.Default.Payments
                    PaymentMethod.ACCOUNT -> Icons.Default.AccountBalance
                }
                SettingOptionChip(
                    label = method.displayName,
                    icon = icon,
                    isSelected = isSelected,
                    onClick = { onMethodSelect(method) }
                )
            }
        }
    }
}

@Composable
private fun DefaultReminderOffsetDialog(
    currentOffsetDays: Int,
    onOffsetSelected: (Int) -> Unit,
    onDismiss: () -> Unit
) {
    val offsets = listOf(
        0 to stringResource(R.string.reminder_offset_on_due_date),
        1 to stringResource(R.string.reminder_offset_1_day),
        2 to stringResource(R.string.reminder_offset_2_days),
        3 to stringResource(R.string.reminder_offset_3_days),
        5 to stringResource(R.string.reminder_offset_5_days),
        7 to stringResource(R.string.reminder_offset_7_days)
    )

    AlertDialog(
        onDismissRequest = onDismiss,
        properties = DialogProperties(
            dismissOnBackPress = true,
            dismissOnClickOutside = true,
            usePlatformDefaultWidth = false
        ),
        modifier = Modifier
            .fillMaxWidth(0.92f)
            .widthIn(max = 420.dp),
        title = {
            Text(
                text = stringResource(R.string.settings_notif_default_offset_title),
                style = MaterialTheme.typography.titleMedium.copy(fontWeight = FontWeight.Bold)
            )
        },
        text = {
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .verticalScroll(rememberScrollState()),
                verticalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                offsets.forEach { (days, label) ->
                    val isSelected = currentOffsetDays == days
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .clip(RoundedCornerShape(8.dp))
                            .clickable {
                                onOffsetSelected(days)
                                onDismiss()
                            }
                            .padding(vertical = 12.dp, horizontal = 8.dp),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Icon(
                            imageVector = if (isSelected) Icons.Default.RadioButtonChecked else Icons.Default.RadioButtonUnchecked,
                            contentDescription = null,
                            tint = if (isSelected) MaterialTheme.colorScheme.primary else MaterialTheme.colorScheme.onSurfaceVariant,
                            modifier = Modifier.size(20.dp)
                        )
                        Spacer(modifier = Modifier.width(12.dp))
                        Text(
                            text = label,
                            style = MaterialTheme.typography.bodyMedium.copy(
                                fontWeight = if (isSelected) FontWeight.SemiBold else FontWeight.Normal,
                                color = if (isSelected) MaterialTheme.colorScheme.primary else MaterialTheme.colorScheme.onSurface
                            )
                        )
                    }
                }
            }
        },
        confirmButton = {},
        dismissButton = {
            TextButton(onClick = onDismiss) {
                Text(stringResource(R.string.cancel))
            }
        }
    )
}

@Composable
private fun WhatsNewDialog(
    onDismiss: () -> Unit
) {
    AlertDialog(
        onDismissRequest = onDismiss,
        properties = DialogProperties(
            dismissOnBackPress = true,
            dismissOnClickOutside = true,
            usePlatformDefaultWidth = false
        ),
        modifier = Modifier
            .fillMaxWidth(0.92f)
            .widthIn(max = 480.dp),
        icon = {
            Icon(
                imageVector = Icons.Default.Notifications,
                contentDescription = null,
                tint = MaterialTheme.colorScheme.primary,
                modifier = Modifier.size(32.dp)
            )
        },
        title = {
            Text(
                text = "What's New in Leaf v1.1.0",
                style = MaterialTheme.typography.titleLarge.copy(fontWeight = FontWeight.Bold),
                textAlign = androidx.compose.ui.text.style.TextAlign.Center
            )
        },
        text = {
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .verticalScroll(rememberScrollState()),
                verticalArrangement = Arrangement.spacedBy(16.dp)
            ) {
                WhatsNewItem(
                    title = "Payment & Loan Reminders",
                    description = "Set one-time or recurring reminders for Loans, EMIs, Bills, Credit Cards, and Subscriptions. Custom alert timing and multi-day offsets."
                )
                WhatsNewItem(
                    title = "Upcoming Payments",
                    description = "Stay on top of upcoming cash flows right on your Dashboard and Planning tabs, with 1-tap 'Mark Paid' to record payments."
                )
                WhatsNewItem(
                    title = "Financial Payment Calendar",
                    description = "Visualize all scheduled dues and reminders alongside your daily expense history on an interactive calendar."
                )
                WhatsNewItem(
                    title = "Settings 2.0 Control Center",
                    description = "Redesigned information architecture with clear sections, instant status badges, and 48dp+ accessibility targets."
                )
                WhatsNewItem(
                    title = "Offline & Reboot Reliability",
                    description = "All reminders persist locally and automatically restore upon device reboot with zero battery drain or telemetry."
                )
            }
        },
        confirmButton = {
            Button(
                onClick = onDismiss,
                shape = RoundedCornerShape(12.dp),
                modifier = Modifier.fillMaxWidth()
            ) {
                Text("Got It", fontWeight = FontWeight.Bold)
            }
        }
    )
}

@Composable
private fun WhatsNewItem(
    title: String,
    description: String
) {
    Column(verticalArrangement = Arrangement.spacedBy(2.dp)) {
        Text(
            text = title,
            style = MaterialTheme.typography.titleSmall.copy(fontWeight = FontWeight.SemiBold),
            color = MaterialTheme.colorScheme.primary
        )
        Text(
            text = description,
            style = MaterialTheme.typography.bodySmall,
            color = MaterialTheme.colorScheme.onSurfaceVariant
        )
    }
}

