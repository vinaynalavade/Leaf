package com.vinaynalavade.expensetracker.presentation.insights

import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.PrimaryTabRow
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Tab
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import com.vinaynalavade.expensetracker.R
import com.vinaynalavade.expensetracker.presentation.components.LoadingView
import com.vinaynalavade.expensetracker.presentation.summary.MonthlySummaryScreen
import com.vinaynalavade.expensetracker.presentation.summary.MonthlySummaryViewModel

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun InsightsScreen(
    insightsViewModel: InsightsViewModel,
    monthlySummaryViewModel: MonthlySummaryViewModel,
    onNavigateToTransactionDetail: (Long) -> Unit,
    modifier: Modifier = Modifier
) {
    val uiState by insightsViewModel.uiState.collectAsState()

    Scaffold(
        topBar = {
            TopAppBar(
                title = {
                    Text(
                        text = stringResource(R.string.nav_insights),
                        fontWeight = FontWeight.Bold,
                        style = MaterialTheme.typography.headlineMedium
                    )
                },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = MaterialTheme.colorScheme.background
                )
            )
        },
        modifier = modifier
    ) { paddingValues ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
        ) {
            PrimaryTabRow(
                selectedTabIndex = uiState.selectedTab.ordinal,
                containerColor = MaterialTheme.colorScheme.background,
                contentColor = MaterialTheme.colorScheme.primary
            ) {
                Tab(
                    selected = uiState.selectedTab == InsightsTab.SUMMARY,
                    onClick = { insightsViewModel.selectTab(InsightsTab.SUMMARY) },
                    text = {
                        Text(
                            text = stringResource(R.string.insights_tab_summary),
                            fontWeight = if (uiState.selectedTab == InsightsTab.SUMMARY) FontWeight.Bold else FontWeight.Normal
                        )
                    }
                )
                Tab(
                    selected = uiState.selectedTab == InsightsTab.TRENDS,
                    onClick = { insightsViewModel.selectTab(InsightsTab.TRENDS) },
                    text = {
                        Text(
                            text = stringResource(R.string.insights_tab_trends),
                            fontWeight = if (uiState.selectedTab == InsightsTab.TRENDS) FontWeight.Bold else FontWeight.Normal
                        )
                    }
                )
            }

            if (uiState.selectedTab == InsightsTab.SUMMARY) {
                MonthlySummaryScreen(
                    viewModel = monthlySummaryViewModel,
                    onNavigateBack = {},
                    onNavigateToTransactionDetail = onNavigateToTransactionDetail
                )
            } else {
                if (uiState.isLoading || uiState.trendData == null) {
                    LoadingView()
                } else {
                    SpendingTrendsScreen(
                        trendData = uiState.trendData!!,
                        currency = uiState.currency,
                        selectedMonthsCount = uiState.selectedMonthsCount,
                        onSelectMonthsCount = { insightsViewModel.setMonthsCount(it) }
                    )
                }
            }
        }
    }
}
