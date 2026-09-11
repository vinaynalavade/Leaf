package com.vinaynalavade.expensetracker.presentation.insights

import com.vinaynalavade.expensetracker.core.model.Currency
import com.vinaynalavade.expensetracker.domain.model.SpendingTrendData

enum class InsightsTab {
    SUMMARY,
    TRENDS
}

data class InsightsUiState(
    val selectedTab: InsightsTab = InsightsTab.SUMMARY,
    val selectedMonthsCount: Int = 6,
    val trendData: SpendingTrendData? = null,
    val currency: Currency = Currency.DEFAULT,
    val isLoading: Boolean = true
)
