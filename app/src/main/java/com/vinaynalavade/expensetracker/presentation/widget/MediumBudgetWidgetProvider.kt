package com.vinaynalavade.expensetracker.presentation.widget

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent

/**
 * Medium Budget & Quick Action AppWidget Provider (4x2).
 * Direct iOS parity matching LeafMediumWidgetView:
 * Displays Current Balance, Income/Expense Wells, Monthly Budget Progress Bar,
 * and 2 Quick Action Buttons (+ Add Expense, Split & Collect).
 */
class MediumBudgetWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        WidgetUpdateManager.updateMediumBudgetWidgets(context, appWidgetManager, appWidgetIds)
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        when (intent.action) {
            WidgetUpdateManager.ACTION_WIDGET_REFRESH -> {
                WidgetUpdateManager.refreshAllWidgets(context)
            }
            WidgetUpdateManager.ACTION_TOGGLE_BALANCE_VISIBILITY -> {
                WidgetUpdateManager.toggleBalanceVisibility(context)
            }
        }
    }

    companion object {
        fun updateAll(context: Context) {
            WidgetUpdateManager.refreshAllWidgets(context)
        }
    }
}

