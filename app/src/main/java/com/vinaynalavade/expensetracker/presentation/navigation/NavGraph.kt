package com.vinaynalavade.expensetracker.presentation.navigation

import androidx.compose.animation.AnimatedContentTransitionScope
import androidx.compose.animation.core.tween
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.lifecycle.viewmodel.compose.viewModel
import androidx.navigation.NavGraph.Companion.findStartDestination
import androidx.navigation.NavHostController
import androidx.navigation.NavType
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.navArgument
import com.vinaynalavade.expensetracker.di.AppContainer
import com.vinaynalavade.expensetracker.domain.model.TransactionType
import androidx.compose.runtime.getValue
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.vinaynalavade.expensetracker.domain.model.GoogleBackupState
import com.vinaynalavade.expensetracker.domain.model.UserPreferences
import com.vinaynalavade.expensetracker.presentation.transactions.TransactionFilter
import com.vinaynalavade.expensetracker.presentation.backup.BackupScreen
import com.vinaynalavade.expensetracker.presentation.backup.BackupViewModel
import com.vinaynalavade.expensetracker.presentation.calendar.CalendarScreen
import com.vinaynalavade.expensetracker.presentation.calendar.CalendarViewModel
import com.vinaynalavade.expensetracker.presentation.categories.CategoriesScreen
import com.vinaynalavade.expensetracker.presentation.categories.CategoriesViewModel
import com.vinaynalavade.expensetracker.presentation.dashboard.DashboardScreen
import com.vinaynalavade.expensetracker.presentation.dashboard.DashboardViewModel
import com.vinaynalavade.expensetracker.presentation.entry.AddTransactionScreen
import com.vinaynalavade.expensetracker.presentation.entry.AddTransactionViewModel
import com.vinaynalavade.expensetracker.presentation.recurring.RecurringTransactionsScreen
import com.vinaynalavade.expensetracker.presentation.recurring.RecurringViewModel
import com.vinaynalavade.expensetracker.presentation.settings.SettingsScreen
import com.vinaynalavade.expensetracker.presentation.settings.SettingsViewModel
import com.vinaynalavade.expensetracker.presentation.statements.StatementsScreen
import com.vinaynalavade.expensetracker.presentation.statements.StatementsViewModel
import com.vinaynalavade.expensetracker.presentation.summary.MonthlySummaryScreen
import com.vinaynalavade.expensetracker.presentation.summary.MonthlySummaryViewModel
import com.vinaynalavade.expensetracker.presentation.theme.Motion
import com.vinaynalavade.expensetracker.presentation.transactions.TransactionsScreen
import com.vinaynalavade.expensetracker.presentation.transactions.TransactionsViewModel
import com.vinaynalavade.expensetracker.presentation.transactions.detail.TransactionDetailScreen
import com.vinaynalavade.expensetracker.presentation.transactions.detail.TransactionDetailViewModel
import com.vinaynalavade.expensetracker.presentation.security.AppLockSetupScreen
import com.vinaynalavade.expensetracker.presentation.security.AppLockViewModel
import com.vinaynalavade.expensetracker.presentation.security.ChangePinScreen
import com.vinaynalavade.expensetracker.presentation.onboarding.WelcomeScreen
import com.vinaynalavade.expensetracker.presentation.onboarding.WelcomeViewModel
import com.vinaynalavade.expensetracker.presentation.tour.AppTourScreen
import com.vinaynalavade.expensetracker.presentation.tour.AppTourViewModel
import com.vinaynalavade.expensetracker.presentation.about.AboutScreen
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch

import com.vinaynalavade.expensetracker.presentation.split.SplitLandingScreen
import com.vinaynalavade.expensetracker.presentation.split.SplitLandingViewModel
import com.vinaynalavade.expensetracker.presentation.split.create.CreateSplitScreen
import com.vinaynalavade.expensetracker.presentation.split.create.CreateSplitViewModel
import com.vinaynalavade.expensetracker.presentation.split.detail.SplitDetailScreen
import com.vinaynalavade.expensetracker.presentation.split.detail.SplitDetailViewModel
import com.vinaynalavade.expensetracker.presentation.split.edit.EditSplitScreen
import com.vinaynalavade.expensetracker.presentation.split.edit.EditSplitViewModel

import com.vinaynalavade.expensetracker.presentation.planning.PlanningScreen
import com.vinaynalavade.expensetracker.presentation.planning.PlanningViewModel
import com.vinaynalavade.expensetracker.presentation.planning.GoalDetailScreen
import com.vinaynalavade.expensetracker.presentation.planning.GoalDetailViewModel
import com.vinaynalavade.expensetracker.presentation.insights.InsightsScreen
import com.vinaynalavade.expensetracker.presentation.insights.InsightsViewModel
import com.vinaynalavade.expensetracker.presentation.tools.ToolsLandingScreen
import com.vinaynalavade.expensetracker.presentation.tools.emi.EmiCalculatorScreen
import com.vinaynalavade.expensetracker.presentation.tools.sip.SipCalculatorScreen
import com.vinaynalavade.expensetracker.presentation.tools.fd.FdCalculatorScreen
import com.vinaynalavade.expensetracker.presentation.tools.rd.RdCalculatorScreen
import com.vinaynalavade.expensetracker.presentation.tools.discount.DiscountCalculatorScreen
import com.vinaynalavade.expensetracker.presentation.tools.gst.GstCalculatorScreen

private fun isPrimaryDestination(route: String?): Boolean {
    return route == Screen.Dashboard.route ||
        route == Screen.Transactions.route ||
        route?.startsWith("transactions") == true ||
        route == Screen.Split.route ||
        route == Screen.Planning.route ||
        route == Screen.Insights.route ||
        route == Screen.MonthlySummary.route ||
        route == Screen.Settings.route
}

@Composable
fun NavGraph(
    navController: NavHostController,
    container: AppContainer,
    isFirstLaunch: Boolean = false,
    isAppTourCompleted: Boolean = true,
    onOpenQuickAdd: () -> Unit,
    onShowSnackbar: (String) -> Unit,
    onShowUndoSnackbar: (String, () -> Unit) -> Unit,
    modifier: Modifier = Modifier
) {
    val navigateToPrimary: (String) -> Unit = { route ->
        navController.navigate(route) {
            popUpTo(navController.graph.findStartDestination().id) {
                saveState = true
            }
            launchSingleTop = true
            restoreState = true
        }
    }

    androidx.compose.runtime.LaunchedEffect(isFirstLaunch, isAppTourCompleted) {
        if (isFirstLaunch) {
            navController.navigate(Screen.Welcome.route) {
                launchSingleTop = true
            }
        } else if (!isAppTourCompleted) {
            val current = navController.currentDestination?.route
            if (current != Screen.Welcome.route && current != Screen.AppTour.route) {
                navController.navigate(Screen.AppTour.route) {
                    launchSingleTop = true
                }
            }
        }
    }

    NavHost(
        navController = navController,
        startDestination = Screen.Dashboard.route,
        enterTransition = {
            if (isPrimaryDestination(initialState.destination.route) && isPrimaryDestination(targetState.destination.route)) {
                fadeIn(animationSpec = tween(Motion.DurationFast, easing = Motion.EasingStandard))
            } else {
                fadeIn(animationSpec = tween(Motion.DurationNormal, easing = Motion.EasingStandard)) +
                    slideIntoContainer(AnimatedContentTransitionScope.SlideDirection.Start, animationSpec = tween(Motion.DurationNormal, easing = Motion.EasingEmphasized))
            }
        },
        exitTransition = {
            if (isPrimaryDestination(initialState.destination.route) && isPrimaryDestination(targetState.destination.route)) {
                fadeOut(animationSpec = tween(Motion.DurationFast, easing = Motion.EasingStandard))
            } else {
                fadeOut(animationSpec = tween(Motion.DurationFast, easing = Motion.EasingStandard))
            }
        },
        popEnterTransition = {
            if (isPrimaryDestination(initialState.destination.route) && isPrimaryDestination(targetState.destination.route)) {
                fadeIn(animationSpec = tween(Motion.DurationFast, easing = Motion.EasingStandard))
            } else {
                fadeIn(animationSpec = tween(Motion.DurationNormal, easing = Motion.EasingStandard))
            }
        },
        popExitTransition = {
            if (isPrimaryDestination(initialState.destination.route) && isPrimaryDestination(targetState.destination.route)) {
                fadeOut(animationSpec = tween(Motion.DurationFast, easing = Motion.EasingStandard))
            } else {
                fadeOut(animationSpec = tween(Motion.DurationFast, easing = Motion.EasingStandard)) +
                    slideOutOfContainer(AnimatedContentTransitionScope.SlideDirection.End, animationSpec = tween(Motion.DurationFast, easing = Motion.EasingStandard))
            }
        },
        modifier = modifier
    ) {
        composable(Screen.Dashboard.route) {
            val viewModel: DashboardViewModel = viewModel(
                factory = DashboardViewModel.Factory(
                    container.getFinancialSummaryUseCase,
                    container.getTransactionsUseCase,
                    container.getCategoryAnalysisUseCase,
                    container.getBudgetProgressUseCase,
                    container.getSavingsGoalsUseCase
                )
            )
            val userPrefs by container.getUserPreferencesUseCase()
                .collectAsStateWithLifecycle(initialValue = UserPreferences())
            val googleBackupState by container.getGoogleBackupStateUseCase()
                .collectAsStateWithLifecycle(initialValue = GoogleBackupState.Disconnected)

            val effectiveDisplayName = when {
                !userPrefs.userName.isNullOrBlank() -> userPrefs.userName
                googleBackupState is GoogleBackupState.Connected && !(googleBackupState as GoogleBackupState.Connected).account.displayName.isNullOrBlank() ->
                    (googleBackupState as GoogleBackupState.Connected).account.displayName
                else -> null
            }
            val effectiveProfileImageUri = when {
                !userPrefs.profileImageUri.isNullOrBlank() -> userPrefs.profileImageUri
                googleBackupState is GoogleBackupState.Connected && !(googleBackupState as GoogleBackupState.Connected).account.photoUrl.isNullOrBlank() ->
                    (googleBackupState as GoogleBackupState.Connected).account.photoUrl
                else -> null
            }

            DashboardScreen(
                viewModel = viewModel,
                displayName = effectiveDisplayName,
                profileImageUri = effectiveProfileImageUri,
                currency = userPrefs.currency,
                onNavigateToAddExpense = {
                    navController.navigate(Screen.AddExpense.route)
                },
                onNavigateToAddIncome = {
                    navController.navigate(Screen.AddIncome.route)
                },
                onNavigateToTransactions = {
                    navigateToPrimary(Screen.Transactions.createRoute())
                },
                onNavigateToCategories = {
                    navigateToPrimary(Screen.Categories.route)
                },
                onNavigateToPlanning = {
                    navigateToPrimary(Screen.Planning.route)
                },
                onNavigateToGoalDetail = { goalId ->
                    navController.navigate(Screen.GoalDetail.createRoute(goalId))
                },
                onNavigateToTools = {
                    navController.navigate(Screen.Tools.route)
                },
                onNavigateToCategoryTransactions = { month, categoryName, type ->
                    navController.navigate(
                        Screen.Transactions.createRoute(
                            filter = type.name,
                            query = categoryName
                        )
                    )
                },
                onNavigateToTransactionDetail = { id ->
                    navController.navigate(Screen.TransactionDetail.createRoute(id))
                },
                onProfileClick = {
                    navigateToPrimary(Screen.Settings.route)
                },
                onOpenQuickAdd = onOpenQuickAdd
            )
        }

        composable(
            route = Screen.Transactions.route,
            arguments = listOf(
                navArgument("filter") {
                    type = NavType.StringType
                    defaultValue = "ALL"
                    nullable = true
                },
                navArgument("query") {
                    type = NavType.StringType
                    defaultValue = ""
                    nullable = true
                }
            )
        ) { backStackEntry ->
            val filterParam = backStackEntry.arguments?.getString("filter")
            val queryParam = backStackEntry.arguments?.getString("query") ?: ""
            val initialFilter = when (filterParam?.uppercase()) {
                "EXPENSE" -> TransactionFilter.EXPENSE
                "INCOME" -> TransactionFilter.INCOME
                else -> TransactionFilter.ALL
            }

            val viewModel: TransactionsViewModel = viewModel(
                key = "tx_${filterParam}_${queryParam}",
                factory = TransactionsViewModel.Factory(
                    container.getTransactionsUseCase,
                    container.addTransactionUseCase,
                    initialFilter = initialFilter,
                    initialSearchQuery = queryParam
                )
            )
            TransactionsScreen(
                viewModel = viewModel,
                onOpenQuickAdd = onOpenQuickAdd,
                onNavigateToTransactionDetail = { transactionId ->
                    navController.navigate(Screen.TransactionDetail.createRoute(transactionId))
                },
                onNavigateToCalendar = {
                    navController.navigate(Screen.Calendar.route)
                }
            )
        }

        composable(Screen.Calendar.route) {
            val viewModel: CalendarViewModel = viewModel(
                factory = CalendarViewModel.Factory(
                    container.getTransactionsUseCase
                )
            )
            CalendarScreen(
                viewModel = viewModel,
                onNavigateBack = { navController.popBackStack() },
                onNavigateToTransactionDetail = { id ->
                    navController.navigate(Screen.TransactionDetail.createRoute(id))
                },
                onOpenAddTransaction = onOpenQuickAdd
            )
        }

        composable(
            route = Screen.TransactionDetail.route,
            arguments = listOf(navArgument("transactionId") { type = NavType.LongType })
        ) { backStackEntry ->
            val transactionId = backStackEntry.arguments?.getLong("transactionId") ?: 0L
            val viewModel: TransactionDetailViewModel = viewModel(
                factory = TransactionDetailViewModel.Factory(
                    transactionId = transactionId,
                    getTransactionByIdUseCase = container.getTransactionByIdUseCase,
                    deleteTransactionUseCase = container.deleteTransactionUseCase
                )
            )
            TransactionDetailScreen(
                viewModel = viewModel,
                onNavigateBack = { navController.popBackStack() },
                onNavigateToEdit = { id ->
                    navController.navigate(Screen.EditTransaction.createRoute(id))
                },
                onTransactionDeleted = { deletedTx ->
                    navController.popBackStack()
                    onShowUndoSnackbar("Transaction deleted") {
                        CoroutineScope(Dispatchers.IO).launch {
                            container.addTransactionUseCase(deletedTx)
                        }
                    }
                }
            )
        }

        composable(
            route = Screen.EditTransaction.route,
            arguments = listOf(navArgument("transactionId") { type = NavType.LongType })
        ) { backStackEntry ->
            val transactionId = backStackEntry.arguments?.getLong("transactionId") ?: 0L
            val viewModel: AddTransactionViewModel = viewModel(
                factory = AddTransactionViewModel.Factory(
                    editTransactionId = transactionId,
                    addTransactionUseCase = container.addTransactionUseCase,
                    updateTransactionUseCase = container.updateTransactionUseCase,
                    getTransactionByIdUseCase = container.getTransactionByIdUseCase,
                    getCategoriesUseCase = container.getCategoriesUseCase,
                    getUserPreferencesUseCase = container.getUserPreferencesUseCase
                )
            )
            AddTransactionScreen(
                viewModel = viewModel,
                onNavigateBack = { navController.popBackStack() },
                onTransactionSaved = { msg ->
                    navController.popBackStack()
                    onShowSnackbar(msg)
                }
            )
        }

        composable(Screen.Categories.route) {
            val viewModel: CategoriesViewModel = viewModel(
                factory = CategoriesViewModel.Factory(
                    container.getCategoriesUseCase,
                    container.saveCategoryUseCase,
                    container.deleteCategoryUseCase
                )
            )
            CategoriesScreen(
                viewModel = viewModel,
                onNavigateBack = { navController.popBackStack() }
            )
        }

        composable(Screen.Settings.route) {
            val viewModel: SettingsViewModel = viewModel(
                factory = SettingsViewModel.Factory(
                    container.getUserPreferencesUseCase,
                    container.setThemeModeUseCase,
                    container.setCurrencyUseCase,
                    container.setOpeningBalanceUseCase,
                    container.setDailyReminderUseCase,
                    container.dailyReminderScheduler,
                    container.setAppLockEnabledUseCase,
                    container.setBiometricEnabledUseCase,
                    container.setAutoLockDurationUseCase,
                    container.setHideContentInRecentsUseCase,
                    container.disableAppLockUseCase,
                    container.securePinManager,
                    container.userPreferencesRepository,
                    container.rescheduleAllRemindersUseCase,
                    container.getGoogleBackupStateUseCase,
                    container.disconnectGoogleAccountUseCase,
                    container.googleAccountManager,
                    container.saveConnectedGoogleAccountUseCase,
                    container.setAutomaticBackupUseCase,
                    container.checkRestoreEligibilityUseCase,
                    container.dismissRestorePromptUseCase,
                    container.performGoogleDriveBackupUseCase,
                    container.prepareGoogleDriveRestoreUseCase,
                    container.restoreBackupUseCase,
                    container.validateBackupUseCase
                )
            )
            SettingsScreen(
                viewModel = viewModel,
                onNavigateToCategories = { navController.navigate(Screen.Categories.route) },
                onNavigateToRecurring = { navController.navigate(Screen.RecurringTransactions.route) },
                onNavigateToStatements = { navController.navigate(Screen.Statements.route) },
                onNavigateToMonthlySummary = { navController.navigate(Screen.MonthlySummary.route) },
                onNavigateToBackup = { navController.navigate(Screen.BackupRestore.route) },
                onNavigateToAppLockSetup = { navController.navigate(Screen.AppLockSetup.route) },
                onNavigateToChangePin = { navController.navigate(Screen.ChangePin.route) },
                onNavigateToTools = { navController.navigate(Screen.Tools.route) },
                onNavigateToAbout = { navController.navigate(Screen.About.route) }
            )
        }

        composable(Screen.MonthlySummary.route) {
            val viewModel: MonthlySummaryViewModel = viewModel(
                factory = MonthlySummaryViewModel.Factory(
                    container.getMonthlyLedgerUseCase
                )
            )
            MonthlySummaryScreen(
                viewModel = viewModel,
                onNavigateBack = { navController.popBackStack() },
                onNavigateToTransactionDetail = { id ->
                    navController.navigate(Screen.TransactionDetail.createRoute(id))
                }
            )
        }

        composable(Screen.RecurringTransactions.route) {
            val viewModel: RecurringViewModel = viewModel(
                factory = RecurringViewModel.Factory(
                    container.getRecurringTransactionsUseCase,
                    container.saveRecurringTransactionUseCase,
                    container.deleteRecurringTransactionUseCase,
                    container.getCategoriesUseCase
                )
            )
            RecurringTransactionsScreen(
                viewModel = viewModel,
                onNavigateBack = { navController.popBackStack() }
            )
        }

        composable(Screen.Statements.route) {
            val viewModel: StatementsViewModel = viewModel(
                factory = StatementsViewModel.Factory(
                    container.generateStatementUseCase
                )
            )
            StatementsScreen(
                viewModel = viewModel,
                onNavigateBack = { navController.popBackStack() }
            )
        }

        composable(Screen.AddExpense.route) {
            val viewModel: AddTransactionViewModel = viewModel(
                factory = AddTransactionViewModel.Factory(
                    transactionType = TransactionType.EXPENSE,
                    addTransactionUseCase = container.addTransactionUseCase,
                    updateTransactionUseCase = container.updateTransactionUseCase,
                    getTransactionByIdUseCase = container.getTransactionByIdUseCase,
                    getCategoriesUseCase = container.getCategoriesUseCase,
                    getUserPreferencesUseCase = container.getUserPreferencesUseCase
                )
            )
            AddTransactionScreen(
                viewModel = viewModel,
                onNavigateBack = { navController.popBackStack() },
                onTransactionSaved = { confirmationMessage ->
                    navController.popBackStack()
                    onShowSnackbar(confirmationMessage)
                }
            )
        }

        composable(Screen.AddIncome.route) {
            val viewModel: AddTransactionViewModel = viewModel(
                factory = AddTransactionViewModel.Factory(
                    transactionType = TransactionType.INCOME,
                    addTransactionUseCase = container.addTransactionUseCase,
                    updateTransactionUseCase = container.updateTransactionUseCase,
                    getTransactionByIdUseCase = container.getTransactionByIdUseCase,
                    getCategoriesUseCase = container.getCategoriesUseCase,
                    getUserPreferencesUseCase = container.getUserPreferencesUseCase
                )
            )
            AddTransactionScreen(
                viewModel = viewModel,
                onNavigateBack = { navController.popBackStack() },
                onTransactionSaved = { confirmationMessage ->
                    navController.popBackStack()
                    onShowSnackbar(confirmationMessage)
                }
            )
        }

        composable(Screen.BackupRestore.route) {
            val viewModel: BackupViewModel = viewModel(
                factory = BackupViewModel.Factory(
                    backupRepository = container.backupRepository,
                    createBackupUseCase = container.createBackupUseCase,
                    validateBackupUseCase = container.validateBackupUseCase,
                    restoreBackupUseCase = container.restoreBackupUseCase,
                    exportTransactionsUseCase = container.exportTransactionsUseCase,
                    validateImportUseCase = container.validateImportUseCase,
                    importTransactionsUseCase = container.importTransactionsUseCase,
                    googleAccountManager = container.googleAccountManager,
                    getGoogleBackupStateUseCase = container.getGoogleBackupStateUseCase,
                    performGoogleDriveBackupUseCase = container.performGoogleDriveBackupUseCase,
                    prepareGoogleDriveRestoreUseCase = container.prepareGoogleDriveRestoreUseCase,
                    disconnectGoogleAccountUseCase = container.disconnectGoogleAccountUseCase,
                    saveConnectedGoogleAccountUseCase = container.saveConnectedGoogleAccountUseCase,
                    getCategoriesUseCase = container.getCategoriesUseCase
                )
            )
            BackupScreen(
                viewModel = viewModel,
                onNavigateBack = { navController.popBackStack() }
            )
        }

        composable(Screen.AppLockSetup.route) {
            val viewModel: AppLockViewModel = viewModel(
                factory = AppLockViewModel.Factory(
                    container.getUserPreferencesUseCase,
                    container.appLockManager,
                    container.securePinManager,
                    container.verifyPinUseCase,
                    container.savePinUseCase,
                    container.changePinUseCase,
                    container.setAppLockEnabledUseCase,
                    container.setBiometricEnabledUseCase,
                    container.disableAppLockUseCase
                )
            )
            AppLockSetupScreen(
                viewModel = viewModel,
                onNavigateBack = { navController.popBackStack() },
                onSetupComplete = {
                    navController.popBackStack()
                    onShowSnackbar("App Lock enabled successfully")
                }
            )
        }

        composable(Screen.ChangePin.route) {
            val viewModel: AppLockViewModel = viewModel(
                factory = AppLockViewModel.Factory(
                    container.getUserPreferencesUseCase,
                    container.appLockManager,
                    container.securePinManager,
                    container.verifyPinUseCase,
                    container.savePinUseCase,
                    container.changePinUseCase,
                    container.setAppLockEnabledUseCase,
                    container.setBiometricEnabledUseCase,
                    container.disableAppLockUseCase
                )
            )
            ChangePinScreen(
                viewModel = viewModel,
                onNavigateBack = { navController.popBackStack() },
                onPinChanged = {
                    navController.popBackStack()
                    onShowSnackbar("PIN successfully updated")
                }
            )
        }

        composable(Screen.Welcome.route) {
            val viewModel: WelcomeViewModel = viewModel(
                factory = WelcomeViewModel.Factory(
                    container.userPreferencesRepository,
                    container.googleAccountManager,
                    container.saveConnectedGoogleAccountUseCase
                )
            )
            WelcomeScreen(
                viewModel = viewModel,
                onOnboardingComplete = {
                    navController.popBackStack(Screen.Welcome.route, inclusive = true)
                    if (!isAppTourCompleted) {
                        navController.navigate(Screen.AppTour.route) {
                            launchSingleTop = true
                        }
                    }
                }
            )
        }

        composable(Screen.AppTour.route) {
            val viewModel: AppTourViewModel = viewModel(
                factory = AppTourViewModel.Factory(
                    container.setAppTourCompletedUseCase
                )
            )
            AppTourScreen(
                viewModel = viewModel,
                onTourComplete = {
                    navController.popBackStack(Screen.AppTour.route, inclusive = true)
                }
            )
        }

        composable(Screen.About.route) {
            val updateViewModel: com.vinaynalavade.expensetracker.presentation.update.UpdateViewModel = viewModel(
                factory = com.vinaynalavade.expensetracker.presentation.update.UpdateViewModel.Factory(
                    checkForUpdateUseCase = container.checkForUpdateUseCase,
                    downloadAndVerifyUpdateUseCase = container.downloadAndVerifyUpdateUseCase,
                    packageInstallerHelper = container.packageInstallerHelper
                )
            )
            AboutScreen(
                updateViewModel = updateViewModel,
                onNavigateBack = { navController.popBackStack() }
            )
        }

        // Split & Collect Destinations (v1.0.6 & v1.0.8)
        composable(Screen.Split.route) {
            val viewModel: SplitLandingViewModel = viewModel(
                factory = SplitLandingViewModel.Factory(
                    getSplitExpensesUseCase = container.getSplitExpensesUseCase,
                    getSplitGroupsUseCase = container.getSplitGroupsUseCase,
                    saveSplitGroupUseCase = container.saveSplitGroupUseCase,
                    deleteSplitGroupUseCase = container.deleteSplitGroupUseCase,
                    getGroupNetBalancesUseCase = container.getGroupNetBalancesUseCase,
                    getUserPreferencesUseCase = container.getUserPreferencesUseCase
                )
            )
            SplitLandingScreen(
                viewModel = viewModel,
                onNavigateToCreateSplit = {
                    navController.navigate(Screen.CreateSplit.route)
                },
                onNavigateToSplitDetail = { splitId ->
                    navController.navigate(Screen.SplitDetail.createRoute(splitId))
                }
            )
        }

        composable(Screen.CreateSplit.route) {
            val viewModel: CreateSplitViewModel = viewModel(
                factory = CreateSplitViewModel.Factory(
                    saveSplitExpenseUseCase = container.saveSplitExpenseUseCase,
                    getCategoriesUseCase = container.getCategoriesUseCase,
                    getSplitGroupsUseCase = container.getSplitGroupsUseCase,
                    getUserPreferencesUseCase = container.getUserPreferencesUseCase,
                    qrStorageManager = container.splitQrStorageManager
                )
            )
            CreateSplitScreen(
                viewModel = viewModel,
                onNavigateBack = { navController.popBackStack() },
                onSplitCreated = { createdId ->
                    navController.popBackStack()
                    navController.navigate(Screen.SplitDetail.createRoute(createdId))
                    onShowSnackbar("Split expense created successfully")
                }
            )
        }

        composable(
            route = Screen.SplitDetail.route,
            arguments = listOf(navArgument("splitId") { type = NavType.LongType })
        ) { backStackEntry ->
            val splitId = backStackEntry.arguments?.getLong("splitId") ?: 0L
            val viewModel: SplitDetailViewModel = viewModel(
                factory = SplitDetailViewModel.Factory(
                    splitId = splitId,
                    getSplitExpenseByIdUseCase = container.getSplitExpenseByIdUseCase,
                    updateParticipantSettlementUseCase = container.updateParticipantSettlementUseCase,
                    deleteSplitExpenseUseCase = container.deleteSplitExpenseUseCase,
                    qrStorageManager = container.splitQrStorageManager,
                    getUserPreferencesUseCase = container.getUserPreferencesUseCase
                )
            )
            SplitDetailScreen(
                viewModel = viewModel,
                onNavigateBack = { navController.popBackStack() },
                onNavigateToEdit = { id ->
                    navController.navigate(Screen.EditSplit.createRoute(id))
                }
            )
        }

        composable(
            route = Screen.EditSplit.route,
            arguments = listOf(navArgument("splitId") { type = NavType.LongType })
        ) { backStackEntry ->
            val splitId = backStackEntry.arguments?.getLong("splitId") ?: 0L
            val viewModel: EditSplitViewModel = viewModel(
                factory = EditSplitViewModel.Factory(
                    splitId = splitId,
                    getSplitExpenseByIdUseCase = container.getSplitExpenseByIdUseCase,
                    updateSplitExpenseUseCase = container.updateSplitExpenseUseCase,
                    getCategoriesUseCase = container.getCategoriesUseCase,
                    getUserPreferencesUseCase = container.getUserPreferencesUseCase,
                    qrStorageManager = container.splitQrStorageManager
                )
            )
            EditSplitScreen(
                viewModel = viewModel,
                onNavigateBack = { navController.popBackStack() },
                onSplitUpdated = {
                    navController.popBackStack()
                    onShowSnackbar("Split expense updated")
                }
            )
        }

        // Planning Module (v1.0.8)
        composable(Screen.Planning.route) {
            val viewModel: PlanningViewModel = viewModel(
                factory = PlanningViewModel.Factory(
                    getBudgetProgressUseCase = container.getBudgetProgressUseCase,
                    saveBudgetUseCase = container.saveBudgetUseCase,
                    deleteBudgetUseCase = container.deleteBudgetUseCase,
                    getSavingsGoalsUseCase = container.getSavingsGoalsUseCase,
                    saveSavingsGoalUseCase = container.saveSavingsGoalUseCase,
                    deleteSavingsGoalUseCase = container.deleteSavingsGoalUseCase,
                    setSavingsGoalArchivedUseCase = container.setSavingsGoalArchivedUseCase,
                    saveSavingsGoalContributionUseCase = container.saveSavingsGoalContributionUseCase,
                    deleteSavingsGoalContributionUseCase = container.deleteSavingsGoalContributionUseCase,
                    getCategoriesUseCase = container.getCategoriesUseCase,
                    getUserPreferencesUseCase = container.getUserPreferencesUseCase
                )
            )
            PlanningScreen(
                viewModel = viewModel,
                onNavigateToGoalDetail = { goalId ->
                    navController.navigate(Screen.GoalDetail.createRoute(goalId))
                }
            )
        }

        composable(
            route = Screen.GoalDetail.route,
            arguments = listOf(navArgument("goalId") { type = NavType.LongType })
        ) { backStackEntry ->
            val goalId = backStackEntry.arguments?.getLong("goalId") ?: 0L
            val viewModel: GoalDetailViewModel = viewModel(
                factory = GoalDetailViewModel.Factory(
                    goalId = goalId,
                    getSavingsGoalByIdUseCase = container.getSavingsGoalByIdUseCase,
                    saveSavingsGoalContributionUseCase = container.saveSavingsGoalContributionUseCase,
                    deleteSavingsGoalContributionUseCase = container.deleteSavingsGoalContributionUseCase,
                    setSavingsGoalArchivedUseCase = container.setSavingsGoalArchivedUseCase,
                    deleteSavingsGoalUseCase = container.deleteSavingsGoalUseCase,
                    getUserPreferencesUseCase = container.getUserPreferencesUseCase
                )
            )
            GoalDetailScreen(
                viewModel = viewModel,
                onNavigateBack = { navController.popBackStack() }
            )
        }

        // Insights Module (v1.0.8)
        composable(Screen.Insights.route) {
            val insightsViewModel: InsightsViewModel = viewModel(
                factory = InsightsViewModel.Factory(
                    getSpendingTrendsUseCase = container.getSpendingTrendsUseCase,
                    getUserPreferencesUseCase = container.getUserPreferencesUseCase
                )
            )
            val monthlySummaryViewModel: MonthlySummaryViewModel = viewModel(
                factory = MonthlySummaryViewModel.Factory(
                    container.getMonthlyLedgerUseCase
                )
            )
            InsightsScreen(
                insightsViewModel = insightsViewModel,
                monthlySummaryViewModel = monthlySummaryViewModel,
                onNavigateToTransactionDetail = { transactionId ->
                    navController.navigate(Screen.TransactionDetail.createRoute(transactionId))
                }
            )
        }

        // Tools & Financial Calculators (v1.0.8)
        composable(Screen.Tools.route) {
            ToolsLandingScreen(
                onNavigateBack = { navController.popBackStack() },
                onNavigateToEmi = { navController.navigate(Screen.EmiCalculator.route) },
                onNavigateToSip = { navController.navigate(Screen.SipCalculator.route) },
                onNavigateToFd = { navController.navigate(Screen.FdCalculator.route) },
                onNavigateToRd = { navController.navigate(Screen.RdCalculator.route) },
                onNavigateToDiscount = { navController.navigate(Screen.DiscountCalculator.route) },
                onNavigateToGst = { navController.navigate(Screen.GstCalculator.route) }
            )
        }

        composable(Screen.EmiCalculator.route) {
            val userPrefs by container.getUserPreferencesUseCase()
                .collectAsStateWithLifecycle(initialValue = UserPreferences())
            EmiCalculatorScreen(
                currency = userPrefs.currency,
                onNavigateBack = { navController.popBackStack() }
            )
        }

        composable(Screen.SipCalculator.route) {
            val userPrefs by container.getUserPreferencesUseCase()
                .collectAsStateWithLifecycle(initialValue = UserPreferences())
            SipCalculatorScreen(
                currency = userPrefs.currency,
                onNavigateBack = { navController.popBackStack() }
            )
        }

        composable(Screen.FdCalculator.route) {
            val userPrefs by container.getUserPreferencesUseCase()
                .collectAsStateWithLifecycle(initialValue = UserPreferences())
            FdCalculatorScreen(
                currency = userPrefs.currency,
                onNavigateBack = { navController.popBackStack() }
            )
        }

        composable(Screen.RdCalculator.route) {
            val userPrefs by container.getUserPreferencesUseCase()
                .collectAsStateWithLifecycle(initialValue = UserPreferences())
            RdCalculatorScreen(
                currency = userPrefs.currency,
                onNavigateBack = { navController.popBackStack() }
            )
        }

        composable(Screen.DiscountCalculator.route) {
            val userPrefs by container.getUserPreferencesUseCase()
                .collectAsStateWithLifecycle(initialValue = UserPreferences())
            DiscountCalculatorScreen(
                currency = userPrefs.currency,
                onNavigateBack = { navController.popBackStack() }
            )
        }

        composable(Screen.GstCalculator.route) {
            val userPrefs by container.getUserPreferencesUseCase()
                .collectAsStateWithLifecycle(initialValue = UserPreferences())
            GstCalculatorScreen(
                currency = userPrefs.currency,
                onNavigateBack = { navController.popBackStack() }
            )
        }
    }
}
