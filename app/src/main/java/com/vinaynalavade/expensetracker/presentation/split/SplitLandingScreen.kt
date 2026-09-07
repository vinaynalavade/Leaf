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
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.CallSplit
import androidx.compose.material.icons.filled.Add
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.FloatingActionButton
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.vinaynalavade.expensetracker.R
import com.vinaynalavade.expensetracker.presentation.components.AppTopBar
import com.vinaynalavade.expensetracker.presentation.components.EmptyStateView
import com.vinaynalavade.expensetracker.presentation.components.LoadingView
import com.vinaynalavade.expensetracker.presentation.split.components.SplitExpenseCard
import com.vinaynalavade.expensetracker.presentation.theme.ButtonShape
import com.vinaynalavade.expensetracker.presentation.theme.CardShape
import com.vinaynalavade.expensetracker.presentation.theme.IncomeEmerald
import com.vinaynalavade.expensetracker.presentation.theme.spacing

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SplitLandingScreen(
    viewModel: SplitLandingViewModel,
    onNavigateToCreateSplit: () -> Unit,
    onNavigateToSplitDetail: (Long) -> Unit,
    modifier: Modifier = Modifier
) {
    val uiState by viewModel.uiState.collectAsStateWithLifecycle()

    Scaffold(
        topBar = {
            AppTopBar(
                title = stringResource(R.string.split_title)
            )
        },
        floatingActionButton = {
            if (uiState.splitExpenses.isNotEmpty()) {
                FloatingActionButton(
                    onClick = onNavigateToCreateSplit,
                    containerColor = MaterialTheme.colorScheme.primary,
                    contentColor = MaterialTheme.colorScheme.onPrimary,
                    shape = ButtonShape
                ) {
                    Icon(
                        imageVector = Icons.Default.Add,
                        contentDescription = stringResource(R.string.split_cta_new)
                    )
                }
            }
        },
        modifier = modifier.fillMaxSize()
    ) { innerPadding ->
        if (uiState.isLoading) {
            LoadingView(modifier = Modifier.padding(innerPadding))
        } else if (uiState.splitExpenses.isEmpty()) {
            Box(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(innerPadding),
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
                modifier = Modifier
                    .fillMaxSize()
                    .padding(innerPadding),
                contentPadding = PaddingValues(MaterialTheme.spacing.md),
                verticalArrangement = Arrangement.spacedBy(MaterialTheme.spacing.md)
            ) {
                // Header & Explanation
                item {
                    Column(modifier = Modifier.fillMaxWidth()) {
                        Text(
                            text = stringResource(R.string.split_subtitle),
                            style = MaterialTheme.typography.bodyMedium,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )

                        Spacer(modifier = Modifier.height(MaterialTheme.spacing.md))

                        // Primary Action Button
                        Button(
                            onClick = onNavigateToCreateSplit,
                            shape = ButtonShape,
                            modifier = Modifier.fillMaxWidth(),
                            colors = ButtonDefaults.buttonColors(
                                containerColor = MaterialTheme.colorScheme.primary,
                                contentColor = MaterialTheme.colorScheme.onPrimary
                            )
                        ) {
                            Icon(
                                imageVector = Icons.Default.Add,
                                contentDescription = null,
                                modifier = Modifier.size(18.dp)
                            )
                            Spacer(modifier = Modifier.width(MaterialTheme.spacing.xs))
                            Text(
                                text = stringResource(R.string.split_cta_new),
                                style = MaterialTheme.typography.labelLarge,
                                fontWeight = FontWeight.Bold
                            )
                        }

                        Spacer(modifier = Modifier.height(MaterialTheme.spacing.md))

                        // Overview Stat Banner
                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.spacedBy(MaterialTheme.spacing.sm)
                        ) {
                            Card(
                                modifier = Modifier.weight(1f),
                                shape = CardShape,
                                colors = CardDefaults.cardColors(
                                    containerColor = MaterialTheme.colorScheme.surface
                                ),
                                border = CardDefaults.outlinedCardBorder().copy(
                                    brush = androidx.compose.ui.graphics.SolidColor(MaterialTheme.colorScheme.outlineVariant.copy(alpha = 0.5f))
                                )
                            ) {
                                Column(modifier = Modifier.padding(MaterialTheme.spacing.md)) {
                                    Text(
                                        text = stringResource(R.string.split_to_collect),
                                        style = MaterialTheme.typography.labelSmall,
                                        color = MaterialTheme.colorScheme.onSurfaceVariant
                                    )
                                    Spacer(modifier = Modifier.height(2.dp))
                                    Text(
                                        text = uiState.totalToCollect.format(uiState.currency),
                                        style = MaterialTheme.typography.titleMedium,
                                        fontWeight = FontWeight.Bold,
                                        color = MaterialTheme.colorScheme.primary
                                    )
                                }
                            }

                            Card(
                                modifier = Modifier.weight(1f),
                                shape = CardShape,
                                colors = CardDefaults.cardColors(
                                    containerColor = MaterialTheme.colorScheme.surface
                                ),
                                border = CardDefaults.outlinedCardBorder().copy(
                                    brush = androidx.compose.ui.graphics.SolidColor(MaterialTheme.colorScheme.outlineVariant.copy(alpha = 0.5f))
                                )
                            ) {
                                Column(modifier = Modifier.padding(MaterialTheme.spacing.md)) {
                                    Text(
                                        text = stringResource(R.string.split_collected),
                                        style = MaterialTheme.typography.labelSmall,
                                        color = MaterialTheme.colorScheme.onSurfaceVariant
                                    )
                                    Spacer(modifier = Modifier.height(2.dp))
                                    Text(
                                        text = uiState.totalCollected.format(uiState.currency),
                                        style = MaterialTheme.typography.titleMedium,
                                        fontWeight = FontWeight.Bold,
                                        color = IncomeEmerald
                                    )
                                }
                            }
                        }

                        Spacer(modifier = Modifier.height(MaterialTheme.spacing.lg))

                        Text(
                            text = stringResource(R.string.split_recent_title),
                            style = MaterialTheme.typography.titleSmall,
                            fontWeight = FontWeight.Bold,
                            color = MaterialTheme.colorScheme.onSurface
                        )
                    }
                }

                items(uiState.splitExpenses, key = { it.id }) { splitExpense ->
                    SplitExpenseCard(
                        splitExpense = splitExpense,
                        currency = uiState.currency,
                        onClick = { onNavigateToSplitDetail(splitExpense.id) }
                    )
                }
            }
        }
    }
}
