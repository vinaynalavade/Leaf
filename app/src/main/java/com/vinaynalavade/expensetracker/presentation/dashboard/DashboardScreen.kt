package com.vinaynalavade.expensetracker.presentation.dashboard

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material3.FloatingActionButton
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.vinaynalavade.expensetracker.R
import com.vinaynalavade.expensetracker.core.constants.AppConstants
import com.vinaynalavade.expensetracker.core.model.Currency
import com.vinaynalavade.expensetracker.domain.model.TransactionType
import com.vinaynalavade.expensetracker.presentation.components.LoadingView
import com.vinaynalavade.expensetracker.presentation.dashboard.components.BalanceHeroCard
import com.vinaynalavade.expensetracker.presentation.dashboard.components.CategoryAnalysisSection
import com.vinaynalavade.expensetracker.presentation.dashboard.components.DashboardBudgetCard
import com.vinaynalavade.expensetracker.presentation.dashboard.components.DashboardGoalCard
import com.vinaynalavade.expensetracker.presentation.dashboard.components.DashboardSplitCard
import com.vinaynalavade.expensetracker.presentation.dashboard.components.DashboardToolsCard
import com.vinaynalavade.expensetracker.presentation.dashboard.components.GreetingHeader
import com.vinaynalavade.expensetracker.presentation.dashboard.components.MonthlyOverviewCard
import com.vinaynalavade.expensetracker.presentation.dashboard.components.QuickActionsSection
import com.vinaynalavade.expensetracker.presentation.theme.spacing
import java.time.YearMonth

/**
 * Modern, luxury financial dashboard screen with streamlined hierarchy,
 * active splits insights, persistent balance visibility, and elegant branding footer.
 */
@Composable
fun DashboardScreen(
    viewModel: DashboardViewModel,
    displayName: String? = null,
    profileImageUri: String? = null,
    currency: Currency = Currency.DEFAULT,
    onNavigateToAddExpense: () -> Unit,
    onNavigateToAddIncome: () -> Unit,
    onNavigateToTransactions: () -> Unit,
    onNavigateToCategories: () -> Unit,
    onNavigateToPlanning: () -> Unit = {},
    onNavigateToGoalDetail: (Long) -> Unit = {},
    onNavigateToSplit: () -> Unit = {},
    onNavigateToTools: () -> Unit = {},
    onNavigateToCategoryTransactions: (YearMonth, String, TransactionType) -> Unit = { _, _, _ -> },
    onProfileClick: () -> Unit = {},
    onOpenQuickAdd: () -> Unit,
    modifier: Modifier = Modifier
) {
    val uiState by viewModel.uiState.collectAsStateWithLifecycle()

    Scaffold(
        floatingActionButton = {
            FloatingActionButton(
                onClick = onOpenQuickAdd,
                containerColor = MaterialTheme.colorScheme.primary,
                contentColor = MaterialTheme.colorScheme.onPrimary,
                shape = CircleShape
            ) {
                Icon(
                    imageVector = Icons.Default.Add,
                    contentDescription = stringResource(R.string.cd_add_transaction)
                )
            }
        },
        modifier = modifier
    ) { innerPadding ->
        if (uiState.isLoading) {
            LoadingView(modifier = Modifier.padding(innerPadding))
        } else {
            LazyColumn(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(innerPadding),
                contentPadding = PaddingValues(bottom = 96.dp)
            ) {
                item {
                    GreetingHeader(
                        displayName = displayName,
                        profileImageUri = profileImageUri,
                        onAvatarClick = onProfileClick
                    )
                }

                item {
                    BalanceHeroCard(
                        summary = uiState.summary,
                        isBalanceVisible = uiState.isBalanceVisible,
                        onToggleBalanceVisibility = { viewModel.toggleBalanceVisibility() }
                    )
                }

                // Deterministic Budget Card (Overall -> Highest spend category -> Set Monthly Budget prompt)
                item {
                    Spacer(modifier = Modifier.height(MaterialTheme.spacing.md))
                    DashboardBudgetCard(
                        budgetProgress = uiState.featuredBudget,
                        currency = currency,
                        onClick = onNavigateToPlanning
                    )
                }

                // Top Active Savings Goal Card (if any active goals exist)
                uiState.topActiveGoal?.let { topGoal ->
                    item {
                        Spacer(modifier = Modifier.height(MaterialTheme.spacing.md))
                        DashboardGoalCard(
                            goal = topGoal,
                            currency = currency,
                            onClick = { onNavigateToGoalDetail(topGoal.id) }
                        )
                    }
                }

                // Active Splits Card (Handles both To Collect and To Pay unsettled splits)
                if (uiState.unsettledSplits.isNotEmpty()) {
                    item {
                        Spacer(modifier = Modifier.height(MaterialTheme.spacing.md))
                        DashboardSplitCard(
                            unsettledSplits = uiState.unsettledSplits,
                            currency = currency,
                            onClick = onNavigateToSplit
                        )
                    }
                }

                item {
                    Spacer(modifier = Modifier.height(MaterialTheme.spacing.lg))
                    QuickActionsSection(
                        onAddExpenseClick = onNavigateToAddExpense,
                        onAddIncomeClick = onNavigateToAddIncome,
                        onViewTransactionsClick = onNavigateToTransactions,
                        onViewCategoriesClick = onNavigateToCategories
                    )
                }

                // Compact Financial Tools Shortcut
                item {
                    Spacer(modifier = Modifier.height(MaterialTheme.spacing.md))
                    DashboardToolsCard(
                        onClick = onNavigateToTools
                    )
                }

                item {
                    Spacer(modifier = Modifier.height(MaterialTheme.spacing.lg))
                    MonthlyOverviewCard(summary = uiState.summary)
                }

                item {
                    Spacer(modifier = Modifier.height(MaterialTheme.spacing.lg))
                    CategoryAnalysisSection(
                        analysisResult = uiState.categoryAnalysis,
                        selectedMonth = uiState.selectedMonth,
                        selectedType = uiState.categoryAnalysisType,
                        currency = currency,
                        onTypeChange = { type -> viewModel.onCategoryAnalysisTypeChange(type) },
                        onPreviousMonth = { viewModel.onPreviousMonth() },
                        onNextMonth = { viewModel.onNextMonth() },
                        onCategoryClick = { category ->
                            onNavigateToCategoryTransactions(uiState.selectedMonth, category.categoryName, uiState.categoryAnalysisType)
                        }
                    )
                }

                // Footer with exact branding phrase
                item {
                    Spacer(modifier = Modifier.height(MaterialTheme.spacing.xxl))
                    Box(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(vertical = MaterialTheme.spacing.md),
                        contentAlignment = Alignment.Center
                    ) {
                        Text(
                            text = AppConstants.CREATOR_BRANDING,
                            style = MaterialTheme.typography.labelSmall.copy(
                                fontSize = 11.sp,
                                letterSpacing = 0.5.sp
                            ),
                            fontWeight = FontWeight.Medium,
                            color = MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.6f)
                        )
                    }
                }
            }
        }
    }
}
