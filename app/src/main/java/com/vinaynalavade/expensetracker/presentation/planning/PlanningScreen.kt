package com.vinaynalavade.expensetracker.presentation.planning

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.asPaddingValues
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.navigationBars
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.windowInsetsPadding
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
import com.vinaynalavade.expensetracker.domain.model.Reminder
import com.vinaynalavade.expensetracker.domain.model.SavingsGoal
import com.vinaynalavade.expensetracker.presentation.components.EmptyStateView
import com.vinaynalavade.expensetracker.presentation.components.LoadingView
import com.vinaynalavade.expensetracker.presentation.planning.components.AddContributionDialog
import com.vinaynalavade.expensetracker.presentation.planning.components.BudgetCard
import com.vinaynalavade.expensetracker.presentation.planning.components.CreateEditBudgetDialog
import com.vinaynalavade.expensetracker.presentation.planning.components.CreateEditGoalDialog
import com.vinaynalavade.expensetracker.presentation.planning.components.SavingsGoalCard
import com.vinaynalavade.expensetracker.presentation.reminders.AddEditReminderDialog
import com.vinaynalavade.expensetracker.presentation.reminders.components.ReminderCard

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

    var showReminderDialog by remember { mutableStateOf(false) }
    var editingReminder by remember { mutableStateOf<Reminder?>(null) }
    var reminderToDelete by remember { mutableStateOf<Reminder?>(null) }
    var reminderToMarkPaid by remember { mutableStateOf<Reminder?>(null) }

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
                    when (uiState.selectedTab) {
                        PlanningTab.BUDGETS -> {
                            editingBudget = null
                            showBudgetDialog = true
                        }
                        PlanningTab.SAVINGS -> {
                            editingGoal = null
                            showGoalDialog = true
                        }
                        PlanningTab.REMINDERS -> {
                            editingReminder = null
                            showReminderDialog = true
                        }
                    }
                },
                containerColor = MaterialTheme.colorScheme.primary,
                contentColor = MaterialTheme.colorScheme.onPrimary,
                shape = CircleShape,
                modifier = Modifier
                    .windowInsetsPadding(WindowInsets.navigationBars)
                    .padding(bottom = 86.dp)
            ) {
                Icon(
                    imageVector = Icons.Default.Add,
                    contentDescription = when (uiState.selectedTab) {
                        PlanningTab.BUDGETS -> stringResource(R.string.budget_add_button)
                        PlanningTab.SAVINGS -> stringResource(R.string.goal_add_button)
                        PlanningTab.REMINDERS -> stringResource(R.string.reminders_add)
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
                Tab(
                    selected = uiState.selectedTab == PlanningTab.REMINDERS,
                    onClick = { viewModel.selectTab(PlanningTab.REMINDERS) },
                    text = {
                        Text(
                            text = stringResource(R.string.planning_tab_reminders),
                            fontWeight = if (uiState.selectedTab == PlanningTab.REMINDERS) FontWeight.Bold else FontWeight.Normal
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
                        contentPadding = PaddingValues(
                            start = 20.dp,
                            end = 20.dp,
                            top = 16.dp,
                            bottom = 110.dp + WindowInsets.navigationBars.asPaddingValues().calculateBottomPadding()
                        ),
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
            } else if (uiState.selectedTab == PlanningTab.SAVINGS) {
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
                            contentPadding = PaddingValues(
                                start = 20.dp,
                                end = 20.dp,
                                top = 8.dp,
                                bottom = 110.dp + WindowInsets.navigationBars.asPaddingValues().calculateBottomPadding()
                            ),
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
                        }
                    }
                }
            } else if (uiState.selectedTab == PlanningTab.REMINDERS) {
                // Reminders Tab
                if (uiState.reminders.isEmpty()) {
                    EmptyStateView(
                        title = stringResource(R.string.reminder_empty_title),
                        description = stringResource(R.string.reminder_empty_desc),
                        onActionClick = {
                            editingReminder = null
                            showReminderDialog = true
                        },
                        actionLabel = stringResource(R.string.reminders_add)
                    )
                } else {
                    LazyColumn(
                        modifier = Modifier.fillMaxSize(),
                        contentPadding = PaddingValues(
                            start = 20.dp,
                            end = 20.dp,
                            top = 16.dp,
                            bottom = 110.dp + WindowInsets.navigationBars.asPaddingValues().calculateBottomPadding()
                        ),
                        verticalArrangement = Arrangement.spacedBy(16.dp)
                    ) {
                        items(uiState.reminders, key = { it.id }) { reminder ->
                            ReminderCard(
                                reminder = reminder,
                                currency = uiState.currency,
                                onEdit = {
                                    editingReminder = reminder
                                    showReminderDialog = true
                                },
                                onDelete = { reminderToDelete = reminder },
                                onToggleEnabled = { isEnabled ->
                                    viewModel.toggleReminder(reminder.id, isEnabled)
                                },
                                onMarkPaid = { reminderToMarkPaid = reminder }
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
        val goal = uiState.savingsGoals.find { it.id == goalId }
        val hasLinkedTransactions = goal?.contributions?.any { it.transactionId != null } == true
        AlertDialog(
            onDismissRequest = { goalToDelete = null },
            title = { Text(stringResource(R.string.goal_delete_title)) },
            text = {
                Text(
                    if (hasLinkedTransactions) {
                        "Are you sure you want to delete this savings goal? This goal has contributions linked to your transaction history. Choose whether to remove the linked transactions or keep your ledger history intact."
                    } else {
                        "Are you sure you want to delete this savings goal and all its contributions?"
                    }
                )
            },
            confirmButton = {
                if (hasLinkedTransactions) {
                    Column(horizontalAlignment = Alignment.End) {
                        TextButton(
                            onClick = {
                                viewModel.deleteSavingsGoal(goalId, deleteLinkedTransactions = true)
                                goalToDelete = null
                            }
                        ) {
                            Text("Delete Goal & Transactions", color = MaterialTheme.colorScheme.error)
                        }
                        TextButton(
                            onClick = {
                                viewModel.deleteSavingsGoal(goalId, deleteLinkedTransactions = false)
                                goalToDelete = null
                            }
                        ) {
                            Text("Keep Transactions Only")
                        }
                    }
                } else {
                    TextButton(
                        onClick = {
                            viewModel.deleteSavingsGoal(goalId)
                            goalToDelete = null
                        }
                    ) {
                        Text(stringResource(R.string.delete), color = MaterialTheme.colorScheme.error)
                    }
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
            onSave = { amount, note, deductFromAccount ->
                viewModel.addContribution(goal.id, amount, note, deductFromAccount)
                goalForContribution = null
            }
        )
    }

    if (showReminderDialog) {
        AddEditReminderDialog(
            initialReminder = editingReminder,
            currency = uiState.currency,
            onDismiss = {
                showReminderDialog = false
                editingReminder = null
            },
            onSave = { savedReminder ->
                viewModel.saveReminder(savedReminder)
                showReminderDialog = false
                editingReminder = null
            }
        )
    }

    reminderToDelete?.let { reminder ->
        AlertDialog(
            onDismissRequest = { reminderToDelete = null },
            title = { Text(stringResource(R.string.reminder_delete_title)) },
            text = { Text(stringResource(R.string.reminder_delete_msg, reminder.title)) },
            confirmButton = {
                TextButton(
                    onClick = {
                        viewModel.deleteReminder(reminder.id)
                        reminderToDelete = null
                    }
                ) {
                    Text(
                        stringResource(R.string.btn_delete),
                        color = MaterialTheme.colorScheme.error
                    )
                }
            },
            dismissButton = {
                TextButton(onClick = { reminderToDelete = null }) {
                    Text(stringResource(R.string.btn_cancel))
                }
            }
        )
    }

    reminderToMarkPaid?.let { reminder ->
        AlertDialog(
            onDismissRequest = { reminderToMarkPaid = null },
            title = { Text(stringResource(R.string.reminder_mark_paid_confirm_title)) },
            text = { Text(stringResource(R.string.reminder_mark_paid_confirm_msg)) },
            confirmButton = {
                TextButton(
                    onClick = {
                        viewModel.markReminderPaid(reminder.id, recordTransaction = true)
                        reminderToMarkPaid = null
                    }
                ) {
                    Text(stringResource(R.string.reminder_mark_paid_record_tx), fontWeight = FontWeight.Bold)
                }
            },
            dismissButton = {
                TextButton(
                    onClick = {
                        viewModel.markReminderPaid(reminder.id, recordTransaction = false)
                        reminderToMarkPaid = null
                    }
                ) {
                    Text(stringResource(R.string.reminder_mark_paid_only))
                }
            }
        )
    }
}
