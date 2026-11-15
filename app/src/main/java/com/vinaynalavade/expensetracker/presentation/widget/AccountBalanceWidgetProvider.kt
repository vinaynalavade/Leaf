package com.vinaynalavade.expensetracker.presentation.widget

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent

/**
 * Widget 1 — Account Balance AppWidget Provider.
 * Displays Account ledger balance only with privacy eye toggle to hide/unhide balance.
 * Strictly displays the actual Account ledger balance (excluding Cash ledger).
 */
open class AccountBalanceWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        WidgetUpdateManager.updateAccountBalanceWidgets(context, appWidgetManager, appWidgetIds)
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        when (intent.action) {
            WidgetUpdateManager.ACTION_WIDGET_REFRESH,
            WidgetUpdateManager.ACTION_TODAY_WIDGET_REFRESH -> {
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
