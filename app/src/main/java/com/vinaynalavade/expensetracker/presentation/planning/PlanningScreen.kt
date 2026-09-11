package com.vinaynalavade.expensetracker.presentation.planning

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
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.Savings
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.FilterChip
import androidx.compose.material3.FloatingActionButton
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.PrimaryTabRow
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Tab
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.vinaynalavade.expensetracker.R
import com.vinaynalavade.expensetracker.domain.model.Budget
import com.vinaynalavade.expensetracker.domain.model.SavingsGoal
import com.vinaynalavade.expensetracker.presentation.components.EmptyStateView
import com.vinaynalavade.expensetracker.presentation.components.LoadingView
import com.vinaynalavade.expensetracker.presentation.planning.components.AddContributionDialog
import com.vinaynalavade.expensetracker.presentation.planning.components.BudgetCard
import com.vinaynalavade.expensetracker.presentation.planning.components.CreateEditBudgetDialog
import com.vinaynalavade.expensetracker.presentation.planning.components.CreateEditGoalDialog
import com.vinaynalavade.expensetracker.presentation.planning.components.SavingsGoalCard

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun PlanningScreen(
    viewModel: PlanningViewModel,
    onNavigateToGoalDetail: (Long) -> Unit,
    modifier: Modifier = Modifier
) {
    val uiState by viewModel.uiState.collectAsState()

    var showBudgetDialog by remember { mutableStateOf(false) }
    var editingBudget by remember { mutableStateOf<Budget?>(null) }
    var budgetToDelete by remember { mutableStateOf<Long?>(null) }

    var showGoalDialog by remember { mutableStateOf(false) }
    var editingGoal by remember { mutableStateOf<SavingsGoal?>(null) }
    var goalToDelete by remember { mutableStateOf<Long?>(null) }
    var goalForContribution by remember { mutableStateOf<SavingsGoal?>(null) }

    var showArchivedGoalsOnly by remember { mutableStateOf(false) }

    Scaffold(
        topBar = {
            TopAppBar(
                title = {
                    Text(
                        text = stringResource(R.string.nav_planning),
                        fontWeight = FontWeight.Bold,
                        style = MaterialTheme.typography.headlineMedium
                    )
                },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = MaterialTheme.colorScheme.background
                )
            )
        },
        floatingActionButton = {
            FloatingActionButton(
                onClick = {
                    if (uiState.selectedTab == PlanningTab.BUDGETS) {
                        editingBudget = null
                        showBudgetDialog = true
                    } else {
                        editingGoal = null
                        showGoalDialog = true
                    }
                },
                containerColor = MaterialTheme.colorScheme.primary,
                contentColor = MaterialTheme.colorScheme.onPrimary,
                shape = CircleShape
            ) {
                Icon(
                    imageVector = Icons.Default.Add,
                    contentDescription = if (uiState.selectedTab == PlanningTab.BUDGETS) {
                        stringResource(R.string.budget_add_button)
                    } else {
                        stringResource(R.string.goal_add_button)
                    }
                )
            }
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
                    selected = uiState.selectedTab == PlanningTab.BUDGETS,
                    onClick = { viewModel.selectTab(PlanningTab.BUDGETS) },
                    text = {
                        Text(
                            text = stringResource(R.string.planning_tab_budgets),
                            fontWeight = if (uiState.selectedTab == PlanningTab.BUDGETS) FontWeight.Bold else FontWeight.Normal
                        )
                    }
                )
                Tab(
                    selected = uiState.selectedTab == PlanningTab.SAVINGS,
                    onClick = { viewModel.selectTab(PlanningTab.SAVINGS) },
                    text = {
                        Text(
                            text = stringResource(R.string.planning_tab_savings),
                            fontWeight = if (uiState.selectedTab == PlanningTab.SAVINGS) FontWeight.Bold else FontWeight.Normal
                        )
                    }
                )
            }

            if (uiState.isLoading) {
                LoadingView()
            } else if (uiState.selectedTab == PlanningTab.BUDGETS) {
                // Budgets Tab
                if (uiState.budgetProgressList.isEmpty()) {
                    EmptyStateView(
                        title = stringResource(R.string.budget_empty_message),
                        description = "Set a monthly spending limit to keep your personal finances on track.",
                        onActionClick = {
                            editingBudget = null
                            showBudgetDialog = true
                        },
                        actionLabel = stringResource(R.string.budget_add_button)
                    )
                } else {
                    LazyColumn(
                        modifier = Modifier.fillMaxSize(),
                        contentPadding = PaddingValues(horizontal = 20.dp, vertical = 16.dp),
                        verticalArrangement = Arrangement.spacedBy(16.dp)
                    ) {
                        uiState.overallBudget?.let { overall ->
                            item {
                                Text(
                                    text = stringResource(R.string.budget_overall_section_title),
                                    style = MaterialTheme.typography.titleSmall,
                                    fontWeight = FontWeight.Bold,
                                    color = MaterialTheme.colorScheme.onSurfaceVariant
                                )
                                Spacer(modifier = Modifier.height(8.dp))
                                BudgetCard(
                                    progress = overall,
                                    currency = uiState.currency,
                                    onEdit = {
                                        editingBudget = overall.budget
                                        showBudgetDialog = true
                                    },
                                    onDelete = { budgetToDelete = overall.budget.id }
                                )
                            }
                        }

                        if (uiState.categoryBudgets.isNotEmpty()) {
                            item {
                                Text(
                                    text = stringResource(R.string.budget_categories_section_title),
                                    style = MaterialTheme.typography.titleSmall,
                                    fontWeight = FontWeight.Bold,
                                    color = MaterialTheme.colorScheme.onSurfaceVariant
                                )
                            }

                            items(uiState.categoryBudgets, key = { it.budget.id }) { catBudget ->
                                BudgetCard(
                                    progress = catBudget,
                                    currency = uiState.currency,
                                    onEdit = {
                                        editingBudget = catBudget.budget
                                        showBudgetDialog = true
                                    },
                                    onDelete = { budgetToDelete = catBudget.budget.id }
                                )
                            }
                        }

                        item {
                            Spacer(modifier = Modifier.height(72.dp))
                        }
                    }
                }
            } else {
                // Savings Goals Tab
                val displayGoals = if (showArchivedGoalsOnly) uiState.archivedSavingsGoals else uiState.activeSavingsGoals

                Column(modifier = Modifier.fillMaxSize()) {
                    // Filter Chips (Active vs Archived)
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(horizontal = 20.dp, vertical = 8.dp),
                        horizontalArrangement = Arrangement.spacedBy(8.dp)
                    ) {
                        FilterChip(
                            selected = !showArchivedGoalsOnly,
                            onClick = { showArchivedGoalsOnly = false },
                            label = { Text("Active (${uiState.activeSavingsGoals.size})") }
                        )
                        FilterChip(
                            selected = showArchivedGoalsOnly,
                            onClick = { showArchivedGoalsOnly = true },
                            label = { Text("Archived (${uiState.archivedSavingsGoals.size})") }
                        )
                    }

                    if (displayGoals.isEmpty()) {
                        EmptyStateView(
                            title = if (showArchivedGoalsOnly) {
                                "No archived savings goals"
                            } else {
                                stringResource(R.string.goal_empty_message)
                            },
                            description = if (showArchivedGoalsOnly) {
                                "Archived goals will appear here."
                            } else {
                                "Create a savings goal to start tracking your targets."
                            },
                            onActionClick = {
                                editingGoal = null
                                showGoalDialog = true
                            },
                            actionLabel = stringResource(R.string.goal_add_button)
                        )
                    } else {
                        LazyColumn(
                            modifier = Modifier.fillMaxSize(),
                            contentPadding = PaddingValues(horizontal = 20.dp, vertical = 8.dp),
                            verticalArrangement = Arrangement.spacedBy(16.dp)
                        ) {
                            items(displayGoals, key = { it.id }) { goal ->
                                SavingsGoalCard(
                                    goal = goal,
                                    currency = uiState.currency,
                                    onClick = { onNavigateToGoalDetail(goal.id) },
                                    onAddContribution = { goalForContribution = goal },
                                    onEdit = {
                                        editingGoal = goal
                                        showGoalDialog = true
                                    },
                                    onArchiveToggle = { viewModel.setGoalArchived(goal.id, !goal.isArchived) },
                                    onDelete = { goalToDelete = goal.id }
                                )
                            }

                            item {
                                Spacer(modifier = Modifier.height(72.dp))
                            }
                        }
                    }
                }
            }
        }
    }

    if (showBudgetDialog) {
        val existingCatIds = uiState.categoryBudgets.mapNotNull { it.budget.categoryId }.toSet()
        CreateEditBudgetDialog(
            initialBudget = editingBudget,
            categories = uiState.categories,
            existingCategoryIdsWithBudget = existingCatIds,
            currency = uiState.currency,
            onDismiss = {
                showBudgetDialog = false
                editingBudget = null
            },
            onSave = { budget ->
                viewModel.saveBudget(budget)
                showBudgetDialog = false
                editingBudget = null
            }
        )
    }

    budgetToDelete?.let { budgetId ->
        AlertDialog(
            onDismissRequest = { budgetToDelete = null },
            title = { Text(stringResource(R.string.budget_delete_title)) },
            text = { Text(stringResource(R.string.budget_delete_message)) },
            confirmButton = {
                TextButton(
                    onClick = {
                        viewModel.deleteBudget(budgetId)
                        budgetToDelete = null
                    }
                ) {
                    Text(stringResource(R.string.delete), color = MaterialTheme.colorScheme.error)
                }
            },
            dismissButton = {
                TextButton(onClick = { budgetToDelete = null }) {
                    Text(stringResource(R.string.cancel))
                }
            }
        )
    }

    if (showGoalDialog) {
        CreateEditGoalDialog(
            initialGoal = editingGoal,
            currency = uiState.currency,
            onDismiss = {
                showGoalDialog = false
                editingGoal = null
            },
            onSave = { goal ->
                viewModel.saveSavingsGoal(goal)
                showGoalDialog = false
                editingGoal = null
            }
        )
    }

    goalToDelete?.let { goalId ->
        AlertDialog(
            onDismissRequest = { goalToDelete = null },
            title = { Text(stringResource(R.string.goal_delete_title)) },
            text = { Text("Are you sure you want to delete this savings goal and all its contributions?") },
            confirmButton = {
                TextButton(
                    onClick = {
                        viewModel.deleteSavingsGoal(goalId)
                        goalToDelete = null
                    }
                ) {
                    Text(stringResource(R.string.delete), color = MaterialTheme.colorScheme.error)
                }
            },
            dismissButton = {
                TextButton(onClick = { goalToDelete = null }) {
                    Text(stringResource(R.string.cancel))
                }
            }
        )
    }

    goalForContribution?.let { goal ->
        AddContributionDialog(
            goal = goal,
            currency = uiState.currency,
            onDismiss = { goalForContribution = null },
            onSave = { amount, note ->
                viewModel.addContribution(goal.id, amount, note)
                goalForContribution = null
            }
        )
    }
}
