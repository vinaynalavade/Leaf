package com.vinaynalavade.expensetracker.presentation.split

import androidx.compose.foundation.background
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
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.CallSplit
import androidx.compose.material.icons.filled.Add
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
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
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.vinaynalavade.expensetracker.R
import com.vinaynalavade.expensetracker.domain.model.SplitGroup
import com.vinaynalavade.expensetracker.presentation.components.EmptyStateView
import com.vinaynalavade.expensetracker.presentation.components.LoadingView
import com.vinaynalavade.expensetracker.presentation.split.components.CreateGroupDialog
import com.vinaynalavade.expensetracker.presentation.split.components.GroupCard
import com.vinaynalavade.expensetracker.presentation.split.components.NetBalanceSummaryBanner
import com.vinaynalavade.expensetracker.presentation.split.components.SplitExpenseCard

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SplitLandingScreen(
    viewModel: SplitLandingViewModel,
    onNavigateToCreateSplit: () -> Unit,
    onNavigateToSplitDetail: (Long) -> Unit,
    modifier: Modifier = Modifier
) {
    val uiState by viewModel.uiState.collectAsStateWithLifecycle()

    var showGroupDialog by remember { mutableStateOf(false) }
    var editingGroup by remember { mutableStateOf<SplitGroup?>(null) }
    var groupToDelete by remember { mutableStateOf<Long?>(null) }

    Scaffold(
        topBar = {
            TopAppBar(
                title = {
                    Text(
                        text = stringResource(R.string.split_title),
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
                    if (uiState.selectedTab == SplitTab.EXPENSES) {
                        onNavigateToCreateSplit()
                    } else {
                        editingGroup = null
                        showGroupDialog = true
                    }
                },
                containerColor = MaterialTheme.colorScheme.primary,
                contentColor = MaterialTheme.colorScheme.onPrimary,
                shape = CircleShape
            ) {
                Icon(
                    imageVector = Icons.Default.Add,
                    contentDescription = if (uiState.selectedTab == SplitTab.EXPENSES) {
                        stringResource(R.string.split_cta_new)
                    } else {
                        "New Group"
                    }
                )
            }
        },
        modifier = modifier.fillMaxSize()
    ) { innerPadding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(innerPadding)
        ) {
            PrimaryTabRow(
                selectedTabIndex = uiState.selectedTab.ordinal,
                containerColor = MaterialTheme.colorScheme.background,
                contentColor = MaterialTheme.colorScheme.primary
            ) {
                Tab(
                    selected = uiState.selectedTab == SplitTab.EXPENSES,
                    onClick = { viewModel.selectTab(SplitTab.EXPENSES) },
                    text = {
                        Text(
                            text = "Expenses",
                            fontWeight = if (uiState.selectedTab == SplitTab.EXPENSES) FontWeight.Bold else FontWeight.Normal
                        )
                    }
                )
                Tab(
                    selected = uiState.selectedTab == SplitTab.GROUPS,
                    onClick = { viewModel.selectTab(SplitTab.GROUPS) },
                    text = {
                        Text(
                            text = "Groups",
                            fontWeight = if (uiState.selectedTab == SplitTab.GROUPS) FontWeight.Bold else FontWeight.Normal
                        )
                    }
                )
            }

            if (uiState.isLoading) {
                LoadingView()
            } else if (uiState.selectedTab == SplitTab.EXPENSES) {
                // Filter expenses if a group is selected
                val filteredExpenses = if (uiState.selectedGroupId != null) {
                    uiState.splitExpenses.filter { it.groupId == uiState.selectedGroupId }
                } else {
                    uiState.splitExpenses
                }

                if (uiState.splitExpenses.isEmpty()) {
                    Box(
                        modifier = Modifier.fillMaxSize(),
                        contentAlignment = Alignment.Center
                    ) {
                        EmptyStateView(
                            title = stringResource(R.string.split_empty_title),
                            description = stringResource(R.string.split_empty_desc),
                            actionButtonText = "+ " + stringResource(R.string.split_cta_new),
                            onActionClick = onNavigateToCreateSplit,
                            icon = Icons.AutoMirrored.Filled.CallSplit
                        )
                    }
                } else {
                    LazyColumn(
                        modifier = Modifier.fillMaxSize(),
                        contentPadding = PaddingValues(horizontal = 20.dp, vertical = 12.dp),
                        verticalArrangement = Arrangement.spacedBy(14.dp)
                    ) {
                        // Net balance banner
                        item {
                            NetBalanceSummaryBanner(
                                summary = uiState.groupBalanceSummary,
                                currency = uiState.currency
                            )
                        }

                        // Group filter chips if groups exist
                        if (uiState.groups.isNotEmpty()) {
                            item {
                                LazyRow(
                                    horizontalArrangement = Arrangement.spacedBy(8.dp),
                                    modifier = Modifier.fillMaxWidth()
                                ) {
                                    item {
                                        FilterChip(
                                            selected = uiState.selectedGroupId == null,
                                            onClick = { viewModel.selectGroupFilter(null) },
                                            label = { Text("All Expenses (${uiState.splitExpenses.size})") }
                                        )
                                    }
                                    items(uiState.groups) { group ->
                                        val count = uiState.splitExpenses.count { it.groupId == group.id }
                                        FilterChip(
                                            selected = uiState.selectedGroupId == group.id,
                                            onClick = { viewModel.selectGroupFilter(group.id) },
                                            label = { Text("${group.name} ($count)") }
                                        )
                                    }
                                }
                            }
                        }

                        // Expense Cards
                        items(filteredExpenses, key = { it.id }) { expense ->
                            SplitExpenseCard(
                                splitExpense = expense,
                                currency = uiState.currency,
                                onClick = { onNavigateToSplitDetail(expense.id) }
                            )
                        }

                        item {
                            Spacer(modifier = Modifier.height(72.dp))
                        }
                    }
                }
            } else {
                // Groups Tab
                if (uiState.groups.isEmpty()) {
                    Box(
                        modifier = Modifier.fillMaxSize(),
                        contentAlignment = Alignment.Center
                    ) {
                        EmptyStateView(
                            title = "No Shared Finance Groups",
                            description = "Organize shared trip or household expenses into groups with net balances.",
                            actionButtonText = "+ New Group",
                            onActionClick = {
                                editingGroup = null
                                showGroupDialog = true
                            },
                            icon = Icons.AutoMirrored.Filled.CallSplit
                        )
                    }
                } else {
                    LazyColumn(
                        modifier = Modifier.fillMaxSize(),
                        contentPadding = PaddingValues(horizontal = 20.dp, vertical = 14.dp),
                        verticalArrangement = Arrangement.spacedBy(14.dp)
                    ) {
                        items(uiState.groups, key = { it.id }) { group ->
                            val groupExpenses = uiState.splitExpenses.filter { it.groupId == group.id }
                            GroupCard(
                                group = group,
                                expenses = groupExpenses,
                                currency = uiState.currency,
                                onClick = {
                                    viewModel.selectGroupFilter(group.id)
                                    viewModel.selectTab(SplitTab.EXPENSES)
                                },
                                onEdit = {
                                    editingGroup = group
                                    showGroupDialog = true
                                },
                                onDelete = { groupToDelete = group.id }
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

    if (showGroupDialog) {
        CreateGroupDialog(
            initialGroup = editingGroup,
            onDismiss = {
                showGroupDialog = false
                editingGroup = null
            },
            onSave = { group ->
                viewModel.saveGroup(group)
                showGroupDialog = false
                editingGroup = null
            }
        )
    }

    groupToDelete?.let { groupId ->
        AlertDialog(
            onDismissRequest = { groupToDelete = null },
            title = { Text("Delete Group") },
            text = { Text("Are you sure you want to delete this group? Expenses inside this group will remain intact without a group assignment.") },
            confirmButton = {
                TextButton(
                    onClick = {
                        viewModel.deleteGroup(groupId)
                        groupToDelete = null
                    }
                ) {
                    Text(stringResource(R.string.delete), color = MaterialTheme.colorScheme.error)
                }
            },
            dismissButton = {
                TextButton(onClick = { groupToDelete = null }) {
                    Text(stringResource(R.string.cancel))
                }
            }
        )
    }
}
