package com.vinaynalavade.expensetracker.presentation.widget

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent

/**
 * Legacy Medium Budget Widget Provider.
 * Consolidated into Widget 2 (Balance & Quick Actions) in v1.1.5 Phase 5.
 */
class MediumBudgetWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        WidgetUpdateManager.updateBalanceQuickActionsWidgets(context, appWidgetManager, appWidgetIds)
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        if (intent.action == WidgetUpdateManager.ACTION_WIDGET_REFRESH) {
            WidgetUpdateManager.refreshAllWidgets(context)
        } else if (intent.action == WidgetUpdateManager.ACTION_TOGGLE_BALANCE_VISIBILITY) {
            WidgetUpdateManager.toggleBalanceVisibility(context)
        }
    }
}
