package com.vinaynalavade.expensetracker.presentation.widget

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.util.Log
import android.widget.RemoteViews
import com.vinaynalavade.expensetracker.ExpenseTrackerApp
import com.vinaynalavade.expensetracker.MainActivity
import com.vinaynalavade.expensetracker.QuickAddTransactionActivity
import com.vinaynalavade.expensetracker.R
import com.vinaynalavade.expensetracker.core.model.Amount
import com.vinaynalavade.expensetracker.core.model.Currency
import com.vinaynalavade.expensetracker.core.notification.NotificationHelper
import com.vinaynalavade.expensetracker.di.AppContainer
import com.vinaynalavade.expensetracker.domain.model.BalanceDisplayMode
import com.vinaynalavade.expensetracker.domain.model.TransactionType
import com.vinaynalavade.expensetracker.domain.model.UserPreferences
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.firstOrNull
import kotlinx.coroutines.launch
import java.time.YearMonth

/**
 * Centralized widget management and update engine for Leaf v1.1.5.
 * Consolidates all home-screen widgets into exactly two canonical designs:
 * 1. Financial Overview Widget ([ExpenseTrackerWidgetProvider]) - Balance & Quick Actions
 * 2. Quick Actions Widget ([QuickAddWidgetProvider])
 */
object WidgetUpdateManager {

    private const val TAG = "WidgetUpdateManager"

    const val ACTION_WIDGET_REFRESH = "com.vinaynalavade.expensetracker.ACTION_WIDGET_REFRESH"
    const val ACTION_TODAY_WIDGET_REFRESH = "com.vinaynalavade.expensetracker.ACTION_TODAY_WIDGET_REFRESH"
    const val ACTION_TOGGLE_BALANCE_VISIBILITY = "com.vinaynalavade.expensetracker.ACTION_TOGGLE_BALANCE_VISIBILITY"

    /**
     * Safely obtains the [AppContainer] from the application context.
     * Returns null if the application is not yet initialized.
     */
    private fun getContainerSafely(context: Context): AppContainer? {
        val app = context.applicationContext as? ExpenseTrackerApp ?: return null
        if (!app.isContainerInitialized) {
            Log.w(TAG, "AppContainer not yet initialized; widget update deferred.")
            return null
        }
        return app.container
    }

    /**
     * Toggles persistent balance visibility and immediately triggers refresh across all widgets.
     */
    fun toggleBalanceVisibility(context: Context) {
        val container = getContainerSafely(context) ?: return
        CoroutineScope(Dispatchers.IO).launch {
            try {
                val prefs = container.getUserPreferencesUseCase().firstOrNull() ?: UserPreferences()
                container.userPreferencesRepository.setBalanceVisible(!prefs.isBalanceVisible)
                refreshAllWidgets(context)
            } catch (e: Exception) {
                Log.e(TAG, "Failed to toggle balance visibility", e)
            }
        }
    }

    /**
     * Triggers a refresh for all active widget instances across the two consolidated designs.
     */
    fun refreshAllWidgets(context: Context) {
        val appWidgetManager = AppWidgetManager.getInstance(context)

        // 1. Update Financial Overview (Balance & Quick Actions) Widgets
        try {
            val balanceIds = mutableSetOf<Int>()
            try {
                balanceIds.addAll(
                    appWidgetManager.getAppWidgetIds(
                        ComponentName(context, ExpenseTrackerWidgetProvider::class.java)
                    ).toList()
                )
            } catch (_: Exception) {}
            // Gracefully update any lingering legacy Medium / Hub widgets
            try {
                balanceIds.addAll(
                    appWidgetManager.getAppWidgetIds(
                        ComponentName(context, MediumBudgetWidgetProvider::class.java)
                    ).toList()
                )
            } catch (_: Exception) {}
            try {
                balanceIds.addAll(
                    appWidgetManager.getAppWidgetIds(
                        ComponentName(context, BudgetHubWidgetProvider::class.java)
                    ).toList()
                )
            } catch (_: Exception) {}

            if (balanceIds.isNotEmpty()) {
                updateBalanceQuickActionsWidgets(context, appWidgetManager, balanceIds.toIntArray())
            }
        } catch (e: Exception) {
            Log.e(TAG, "Failed to refresh Balance & Quick Actions widgets", e)
        }

        // 2. Update Quick Actions Widgets
        try {
            val quickAddIds = appWidgetManager.getAppWidgetIds(
                ComponentName(context, QuickAddWidgetProvider::class.java)
            )
            if (quickAddIds.isNotEmpty()) {
                updateQuickActionsWidgets(context, appWidgetManager, quickAddIds)
            }
        } catch (e: Exception) {
            Log.e(TAG, "Failed to refresh Quick Actions widgets", e)
        }
    }

    /**
     * Updates Widget 1 — Financial Overview (Balance & Quick Actions) instances.
     * Displays Current / Account / Cash balance based on the user's selected BalanceDisplayMode,
     * eye privacy toggle, budget progress line, income/expense flow, refresh action, and Add Expense / Add Income buttons.
     */
    fun updateBalanceQuickActionsWidgets(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        val container = getContainerSafely(context) ?: return

        CoroutineScope(Dispatchers.IO).launch {
            try {
                val summary = container.getWidgetFinancialSummaryUseCase().firstOrNull()
                val prefs = container.getUserPreferencesUseCase().firstOrNull()
                val currency = prefs?.currency ?: Currency.DEFAULT
                val isLocked = container.appLockManager.isLocked(prefs ?: UserPreferences())
                val isVisible = (prefs?.isBalanceVisible ?: true) && !isLocked

                val displayMode = prefs?.balanceDisplayMode ?: BalanceDisplayMode.COMBINED
                val effectiveBalance = when (displayMode) {
                    BalanceDisplayMode.ACCOUNT -> {
                        val acctBal = container.transactionRepository.getAccountBalance().firstOrNull() ?: Amount.ZERO
                        val opening = prefs?.openingBalance ?: Amount.ZERO
                        acctBal + opening
                    }
                    BalanceDisplayMode.CASH -> {
                        container.transactionRepository.getCashBalance().firstOrNull() ?: Amount.ZERO
                    }
                    BalanceDisplayMode.COMBINED -> {
                        summary?.balance ?: Amount.ZERO
                    }
                }

                val balanceLabel = when (displayMode) {
                    BalanceDisplayMode.ACCOUNT -> "ACCOUNT BALANCE"
                    BalanceDisplayMode.CASH -> "CASH BALANCE"
                    BalanceDisplayMode.COMBINED -> "CURRENT BALANCE"
                }

                val balanceStr = if (!isVisible) "••••••••" else effectiveBalance.format(currency)
                val monthlyIncomeStr = if (!isVisible) "+••••" else "+${summary?.monthlyIncome?.format(currency) ?: "₹0.00"}"
                val monthlyExpenseStr = if (!isVisible) "-••••" else "-${summary?.monthlyExpense?.format(currency) ?: "₹0.00"}"
                val monthLabelStr = if (isLocked) "Protected" else (summary?.monthLabel?.ifBlank { "This Month" } ?: "This Month")

                // Budget progress line calculation
                val currentMonth = YearMonth.now()
                val budgets = container.getBudgetProgressUseCase(currentMonth).firstOrNull() ?: emptyList()
                val featuredBudget = budgets.find { it.budget.categoryId == null }
                    ?: budgets.maxByOrNull { it.usedAmount.subunits }

                val (budgetText, progressPercent) = if (featuredBudget != null) {
                    val usedStr = if (!isVisible) "••••" else featuredBudget.usedAmount.format(currency)
                    val limitStr = if (!isVisible) "••••" else featuredBudget.budget.amount.format(currency)
                    val pct = featuredBudget.percentageUsed.toInt().coerceIn(0, 100)
                    Pair("Budget: $usedStr / $limitStr ($pct%)", pct)
                } else {
                    val spentStr = if (!isVisible) "••••" else (summary?.monthlyExpense?.format(currency) ?: "₹0.00")
                    Pair("Spent this month: $spentStr", 0)
                }

                // 1. Root tap -> Open MainActivity (Dashboard)
                val mainIntent = Intent(context, MainActivity::class.java).apply {
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                }
                val mainPendingIntent = PendingIntent.getActivity(
                    context,
                    100,
                    mainIntent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )

                // 2. Expense tap -> Open QuickAddTransactionActivity
                val expenseIntent = Intent(context, QuickAddTransactionActivity::class.java).apply {
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                    putExtra(QuickAddTransactionActivity.EXTRA_TRANSACTION_TYPE, TransactionType.EXPENSE.name)
                    putExtra(NotificationHelper.EXTRA_START_ROUTE, NotificationHelper.ROUTE_ADD_EXPENSE)
                }
                val expensePendingIntent = PendingIntent.getActivity(
                    context,
                    101,
                    expenseIntent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )

                // 3. Income tap -> Open QuickAddTransactionActivity
                val incomeIntent = Intent(context, QuickAddTransactionActivity::class.java).apply {
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                    putExtra(QuickAddTransactionActivity.EXTRA_TRANSACTION_TYPE, TransactionType.INCOME.name)
                    putExtra(NotificationHelper.EXTRA_START_ROUTE, NotificationHelper.ROUTE_ADD_INCOME)
                }
                val incomePendingIntent = PendingIntent.getActivity(
                    context,
                    102,
                    incomeIntent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )

                // 4. Refresh icon tap -> Broadcast to update widget
                val refreshIntent = Intent(context, ExpenseTrackerWidgetProvider::class.java).apply {
                    action = ACTION_WIDGET_REFRESH
                }
                val refreshPendingIntent = PendingIntent.getBroadcast(
                    context,
                    103,
                    refreshIntent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )

                // 5. Visibility toggle icon tap -> Broadcast to toggle visibility
                val toggleIntent = Intent(context, ExpenseTrackerWidgetProvider::class.java).apply {
                    action = ACTION_TOGGLE_BALANCE_VISIBILITY
                }
                val togglePendingIntent = PendingIntent.getBroadcast(
                    context,
                    104,
                    toggleIntent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )

                for (widgetId in appWidgetIds) {
                    val views = RemoteViews(context.packageName, R.layout.widget_expense_tracker).apply {
                        setTextViewText(R.id.widget_balance_label, balanceLabel)
                        setTextViewText(R.id.widget_total_balance, balanceStr)
                        setTextViewText(R.id.widget_monthly_income, monthlyIncomeStr)
                        setTextViewText(R.id.widget_monthly_expense, monthlyExpenseStr)
                        setTextViewText(R.id.widget_month_label, monthLabelStr)

                        // Budget Progress Line
                        setTextViewText(R.id.widget_budget_text, budgetText)
                        setProgressBar(R.id.widget_budget_progress, 100, progressPercent, false)

                        setImageViewResource(
                            R.id.widget_btn_toggle_visibility,
                            if (isVisible) R.drawable.ic_visibility else R.drawable.ic_visibility_off
                        )

                        setOnClickPendingIntent(R.id.widget_root, mainPendingIntent)
                        setOnClickPendingIntent(R.id.widget_btn_toggle_visibility, togglePendingIntent)
                        setOnClickPendingIntent(R.id.widget_btn_refresh, refreshPendingIntent)
                        setOnClickPendingIntent(R.id.widget_btn_add_expense, expensePendingIntent)
                        setOnClickPendingIntent(R.id.widget_btn_add_income, incomePendingIntent)
                    }
                    appWidgetManager.updateAppWidget(widgetId, views)
                }
            } catch (e: Exception) {
                Log.e(TAG, "Error updating Balance & Quick Actions widgets", e)
            }
        }
    }

    /**
     * Updates Widget 2 — Quick Actions instances.
     * Includes only the existing Add Expense and Add Income buttons,
     * and the monthly budget progress line. Zero balance figures or charts.
     */
    fun updateQuickActionsWidgets(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        val container = getContainerSafely(context) ?: return

        CoroutineScope(Dispatchers.IO).launch {
            try {
                val prefs = container.getUserPreferencesUseCase().firstOrNull()
                val currency = prefs?.currency ?: Currency.DEFAULT
                val isLocked = container.appLockManager.isLocked(prefs ?: UserPreferences())
                val isVisible = (prefs?.isBalanceVisible ?: true) && !isLocked

                val currentMonth = YearMonth.now()
                val budgets = container.getBudgetProgressUseCase(currentMonth).firstOrNull() ?: emptyList()
                val featuredBudget = budgets.find { it.budget.categoryId == null }
                    ?: budgets.maxByOrNull { it.usedAmount.subunits }

                val (budgetText, progressPercent) = if (featuredBudget != null) {
                    val usedStr = if (!isVisible) "••••" else featuredBudget.usedAmount.format(currency)
                    val limitStr = if (!isVisible) "••••" else featuredBudget.budget.amount.format(currency)
                    val pct = featuredBudget.percentageUsed.toInt().coerceIn(0, 100)
                    Pair("Budget: $pct% used ($usedStr / $limitStr)", pct)
                } else {
                    Pair("Monthly Budget", 0)
                }

                val mainIntent = Intent(context, MainActivity::class.java).apply {
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                }
                val mainPendingIntent = PendingIntent.getActivity(
                    context,
                    200,
                    mainIntent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )

                val expenseIntent = Intent(context, QuickAddTransactionActivity::class.java).apply {
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                    putExtra(QuickAddTransactionActivity.EXTRA_TRANSACTION_TYPE, TransactionType.EXPENSE.name)
                    putExtra(NotificationHelper.EXTRA_START_ROUTE, NotificationHelper.ROUTE_ADD_EXPENSE)
                }
                val expensePendingIntent = PendingIntent.getActivity(
                    context,
                    201,
                    expenseIntent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )

                val incomeIntent = Intent(context, QuickAddTransactionActivity::class.java).apply {
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                    putExtra(QuickAddTransactionActivity.EXTRA_TRANSACTION_TYPE, TransactionType.INCOME.name)
                    putExtra(NotificationHelper.EXTRA_START_ROUTE, NotificationHelper.ROUTE_ADD_INCOME)
                }
                val incomePendingIntent = PendingIntent.getActivity(
                    context,
                    202,
                    incomeIntent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )

                for (widgetId in appWidgetIds) {
                    val views = RemoteViews(context.packageName, R.layout.widget_quick_add).apply {
                        // Budget progress line
                        setTextViewText(R.id.quick_widget_budget_text, budgetText)
                        setProgressBar(R.id.quick_widget_budget_progress, 100, progressPercent, false)

                        // Quick action buttons
                        setOnClickPendingIntent(R.id.quick_widget_root, mainPendingIntent)
                        setOnClickPendingIntent(R.id.quick_widget_btn_expense, expensePendingIntent)
                        setOnClickPendingIntent(R.id.quick_widget_btn_income, incomePendingIntent)
                    }
                    appWidgetManager.updateAppWidget(widgetId, views)
                }
            } catch (e: Exception) {
                Log.e(TAG, "Error updating Quick Actions widgets", e)
            }
        }
    }

    // --- Backwards-compatibility aliases for legacy code & test suites ---

    fun updateFinancialSummaryWidgets(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        updateBalanceQuickActionsWidgets(context, appWidgetManager, appWidgetIds)
    }

    fun updateTodayExpenseWidgets(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        updateBalanceQuickActionsWidgets(context, appWidgetManager, appWidgetIds)
    }

    fun updateQuickAddWidgets(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        updateQuickActionsWidgets(context, appWidgetManager, appWidgetIds)
    }

    fun updateBudgetHubWidgets(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        updateBalanceQuickActionsWidgets(context, appWidgetManager, appWidgetIds)
    }

    fun updateMediumBudgetWidgets(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        updateBalanceQuickActionsWidgets(context, appWidgetManager, appWidgetIds)
    }
}
