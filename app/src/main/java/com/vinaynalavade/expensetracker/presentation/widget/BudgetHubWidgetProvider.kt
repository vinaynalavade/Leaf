package com.vinaynalavade.expensetracker.presentation.widget

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent

/**
 * Large Financial Snapshot & Budget Hub AppWidget Provider (4x4).
 * iOS parity matching LeafLargeWidgetView:
 * Displays Current Balance, Inflow & Outflow, Monthly Budget Progress Bar, and Quick Hub Action Buttons.
 */
class BudgetHubWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        WidgetUpdateManager.updateBudgetHubWidgets(context, appWidgetManager, appWidgetIds)
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

