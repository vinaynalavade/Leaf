package com.vinaynalavade.expensetracker.presentation.summary

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.automirrored.filled.ArrowForward
import androidx.compose.material.icons.automirrored.filled.TrendingDown
import androidx.compose.material.icons.automirrored.filled.TrendingUp
import androidx.compose.material.icons.filled.CalendarToday
import androidx.compose.material.icons.filled.Savings
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.FilterChip
import androidx.compose.material3.FilterChipDefaults
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.LinearProgressIndicator
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.vinaynalavade.expensetracker.core.constants.AppConstants
import com.vinaynalavade.expensetracker.core.model.Amount
import com.vinaynalavade.expensetracker.domain.model.CategorySpending
import com.vinaynalavade.expensetracker.domain.model.MonthlyLedgerSummary
import com.vinaynalavade.expensetracker.domain.model.Transaction
import com.vinaynalavade.expensetracker.domain.model.TransactionType
import com.vinaynalavade.expensetracker.presentation.components.AmountDisplay
import com.vinaynalavade.expensetracker.presentation.components.AppTopBar
import com.vinaynalavade.expensetracker.presentation.components.CategoryIcon
import com.vinaynalavade.expensetracker.presentation.components.LoadingView
import com.vinaynalavade.expensetracker.presentation.components.TransactionItem
import com.vinaynalavade.expensetracker.presentation.components.UiState
import com.vinaynalavade.expensetracker.presentation.theme.CardShape
import com.vinaynalavade.expensetracker.presentation.theme.HeroCardShape
import com.vinaynalavade.expensetracker.presentation.theme.HeroEmeraldGradient
import com.vinaynalavade.expensetracker.presentation.theme.HeroObsidianGradient
import com.vinaynalavade.expensetracker.presentation.theme.PillShape
import com.vinaynalavade.expensetracker.presentation.theme.PureWhite
import com.vinaynalavade.expensetracker.presentation.theme.financialColors
import com.vinaynalavade.expensetracker.presentation.theme.spacing
import java.time.YearMonth
import java.time.format.DateTimeFormatter
import java.util.Locale

@Composable
fun MonthlySummaryScreen(
    viewModel: MonthlySummaryViewModel,
    onNavigateBack: () -> Unit,
    onNavigateToTransactionDetail: (Long) -> Unit,
    modifier: Modifier = Modifier
) {
    val selectedMonth by viewModel.selectedMonth.collectAsStateWithLifecycle()
    val selectedTab by viewModel.selectedTab.collectAsStateWithLifecycle()
    val uiState by viewModel.uiState.collectAsStateWithLifecycle()

    val currentYearMonth = YearMonth.now()
    val monthFormatter = DateTimeFormatter.ofPattern("MMMM yyyy", Locale.getDefault())

    Scaffold(
        topBar = {
            AppTopBar(
                title = "Monthly Summary",
                canNavigateBack = true,
                onNavigateBack = onNavigateBack
            )
        },
        modifier = modifier
    ) { innerPadding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(innerPadding)
                .verticalScroll(rememberScrollState())
                .padding(horizontal = MaterialTheme.spacing.screen, vertical = MaterialTheme.spacing.sm)
        ) {
            // Month Selector Row with Current Month Quick Return
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(vertical = MaterialTheme.spacing.xs),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                IconButton(onClick = viewModel::onPreviousMonth) {
                    Icon(imageVector = Icons.AutoMirrored.Filled.ArrowBack, contentDescription = "Previous Month")
                }

                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    modifier = Modifier.clickable(onClick = viewModel::onCurrentMonth)
                ) {
                    Text(
                        text = selectedMonth.format(monthFormatter),
                        style = MaterialTheme.typography.titleMedium,
                        fontWeight = FontWeight.Bold,
                        color = MaterialTheme.colorScheme.onBackground
                    )
                    if (selectedMonth != currentYearMonth) {
                        Spacer(modifier = Modifier.width(6.dp))
                        Box(
                            modifier = Modifier
                                .clip(PillShape)
                                .background(MaterialTheme.colorScheme.primary.copy(alpha = 0.15f))
                                .padding(horizontal = 6.dp, vertical = 2.dp)
                        ) {
                            Text(
                                text = "Today",
                                style = MaterialTheme.typography.labelSmall.copy(fontSize = 10.sp),
                                fontWeight = FontWeight.Bold,
                                color = MaterialTheme.colorScheme.primary
                            )
                        }
                    }
                }

                IconButton(onClick = viewModel::onNextMonth) {
                    Icon(imageVector = Icons.AutoMirrored.Filled.ArrowForward, contentDescription = "Next Month")
                }
            }

            Spacer(modifier = Modifier.height(MaterialTheme.spacing.sm))

            when (val state = uiState) {
                is UiState.Loading -> {
                    LoadingView()
                }
                is UiState.Empty -> {
                    Text(
                        text = "No records for this month.",
                        style = MaterialTheme.typography.bodyMedium,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }
                is UiState.Error -> {
                    Text(text = state.message, color = MaterialTheme.colorScheme.error)
                }
                is UiState.Success -> {
                    val summary = state.data
                    MonthlySummaryContent(
                        summary = summary,
                        selectedTab = selectedTab,
                        onTabSelected = viewModel::onTabSelected,
                        onTransactionClick = onNavigateToTransactionDetail
                    )
                }
            }

            Spacer(modifier = Modifier.height(MaterialTheme.spacing.xxl))
        }
    }
}

@Composable
private fun MonthlySummaryContent(
    summary: MonthlyLedgerSummary,
    selectedTab: SummaryFilterTab,
    onTabSelected: (SummaryFilterTab) -> Unit,
    onTransactionClick: (Long) -> Unit
) {
    val isDark = isSystemInDarkTheme()
    val heroGradient = if (isDark) HeroObsidianGradient else HeroEmeraldGradient

    // 1. Hero Balance Overview Card
    Box(
        modifier = Modifier
            .fillMaxWidth()
            .shadow(
                elevation = if (isDark) 0.dp else 4.dp,
                shape = HeroCardShape,
                ambientColor = Color(0xFF025442).copy(alpha = 0.25f),
                spotColor = Color(0xFF025442).copy(alpha = 0.35f)
            )
            .clip(HeroCardShape)
            .background(heroGradient)
            .border(
                width = 0.75.dp,
                color = if (isDark) Color(0xFF263242) else Color.White.copy(alpha = 0.25f),
                shape = HeroCardShape
            )
            .padding(20.dp)
    ) {
        Column(modifier = Modifier.fillMaxWidth()) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    text = "CLOSING BALANCE",
                    style = MaterialTheme.typography.labelSmall.copy(
                        fontSize = 11.sp,
                        fontWeight = FontWeight.Bold,
                        letterSpacing = 1.2.sp
                    ),
                    color = Color.White.copy(alpha = 0.80f)
                )

                // MoM Growth indicator badge
                summary.momChangePercentage?.let { pct ->
                    val isUp = pct > 0
                    val badgeColor = if (isUp) Color(0xFFFB7185) else Color(0xFF34D399)
                    val sign = if (isUp) "+" else ""
                    Box(
                        modifier = Modifier
                            .clip(PillShape)
                            .background(Color.White.copy(alpha = 0.15f))
                            .padding(horizontal = 8.dp, vertical = 3.dp)
                    ) {
                        Row(verticalAlignment = Alignment.CenterVertically) {
                            Icon(
                                imageVector = if (isUp) Icons.AutoMirrored.Filled.TrendingUp else Icons.AutoMirrored.Filled.TrendingDown,
                                contentDescription = null,
                                tint = badgeColor,
                                modifier = Modifier.size(12.dp)
                            )
                            Spacer(modifier = Modifier.width(4.dp))
                            Text(
                                text = "$sign${String.format(Locale.US, "%.1f", pct)}% MoM",
                                style = MaterialTheme.typography.labelSmall.copy(fontSize = 10.sp),
                                fontWeight = FontWeight.Bold,
                                color = Color.White
                            )
                        }
                    }
                }
            }

            Spacer(modifier = Modifier.height(6.dp))
            AmountDisplay(
                amount = summary.closingBalance,
                style = MaterialTheme.typography.displayMedium.copy(
                    color = PureWhite,
                    fontWeight = FontWeight.Bold,
                    letterSpacing = (-1.0).sp
                ),
                showPrefix = false
            )

            Spacer(modifier = Modifier.height(16.dp))

            Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
                SummaryStat(
                    label = "Opening Balance",
                    amount = summary.openingBalance,
                    color = Color.White.copy(alpha = 0.95f)
                )
                SummaryStat(
                    label = "Net Change",
                    amount = summary.netChange,
                    color = if (summary.netChange.isNegative) Color(0xFFFB7185) else Color(0xFF34D399),
                    isHighlight = true
                )
            }

            Spacer(modifier = Modifier.height(10.dp))

            Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
                SummaryStat(
                    label = "Total Income",
                    amount = summary.totalIncome,
                    color = Color(0xFF34D399)
                )
                SummaryStat(
                    label = "Actual Spending",
                    amount = summary.ordinaryExpense,
                    color = Color(0xFFFB7185)
                )
            }

            if (summary.savingsAllocation.subunits > 0L) {
                Spacer(modifier = Modifier.height(10.dp))
                Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
                    SummaryStat(
                        label = "Savings / Goal Allocation",
                        amount = summary.savingsAllocation,
                        color = Color(0xFF38BDF8)
                    )
                    SummaryStat(
                        label = "Daily Average Spend",
                        amount = summary.dailyAverageExpense,
                        color = Color.White.copy(alpha = 0.85f)
                    )
                }
            }
        }
    }

    Spacer(modifier = Modifier.height(MaterialTheme.spacing.md))

    // 2. Filter Tabs
    Row(
        modifier = Modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.spacedBy(8.dp)
    ) {
        SummaryFilterTab.entries.forEach { tab ->
            FilterChip(
                selected = selectedTab == tab,
                onClick = { onTabSelected(tab) },
                label = {
                    Text(
                        text = tab.label,
                        style = MaterialTheme.typography.labelSmall,
                        fontWeight = if (selectedTab == tab) FontWeight.Bold else FontWeight.Medium
                    )
                },
                colors = FilterChipDefaults.filterChipColors(
                    selectedContainerColor = MaterialTheme.colorScheme.primaryContainer,
                    selectedLabelColor = MaterialTheme.colorScheme.onPrimaryContainer
                ),
                shape = PillShape
            )
        }
    }

    Spacer(modifier = Modifier.height(MaterialTheme.spacing.md))

    // 3. Category Breakdown (show on ALL, EXPENSES, or SAVINGS)
    if (selectedTab != SummaryFilterTab.INCOME && summary.expenseBreakdown.isNotEmpty()) {
        val breakdownList = when (selectedTab) {
            SummaryFilterTab.SAVINGS -> summary.expenseBreakdown.filter {
                it.category.name.equals(AppConstants.CATEGORY_SAVINGS_AND_GOALS, ignoreCase = true)
            }
            SummaryFilterTab.EXPENSES -> summary.expenseBreakdown.filter {
                !it.category.name.equals(AppConstants.CATEGORY_SAVINGS_AND_GOALS, ignoreCase = true)
            }
            else -> summary.expenseBreakdown
        }

        if (breakdownList.isNotEmpty()) {
            Text(
                text = "CATEGORY BREAKDOWN",
                style = MaterialTheme.typography.labelSmall,
                fontWeight = FontWeight.Bold,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
                letterSpacing = 0.8.sp
            )
            Spacer(modifier = Modifier.height(MaterialTheme.spacing.xs))

            Card(
                modifier = Modifier
                    .fillMaxWidth()
                    .border(
                        width = 1.dp,
                        color = MaterialTheme.colorScheme.outlineVariant.copy(alpha = 0.4f),
                        shape = CardShape
                    ),
                shape = CardShape,
                colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface),
                elevation = CardDefaults.cardElevation(defaultElevation = 0.dp)
            ) {
                Column(modifier = Modifier.padding(MaterialTheme.spacing.card)) {
                    breakdownList.take(6).forEachIndexed { idx, item ->
                        if (idx > 0) HorizontalDivider(
                            modifier = Modifier.padding(vertical = MaterialTheme.spacing.sm),
                            color = MaterialTheme.colorScheme.outlineVariant.copy(alpha = 0.35f)
                        )
                        CategorySpendingRow(item = item)
                    }
                }
            }

            Spacer(modifier = Modifier.height(MaterialTheme.spacing.lg))
        }
    }

    // 4. Month Transactions List
    val filteredTransactions = when (selectedTab) {
        SummaryFilterTab.ALL -> summary.transactions
        SummaryFilterTab.INCOME -> summary.transactions.filter { it.type == TransactionType.INCOME }
        SummaryFilterTab.SAVINGS -> summary.transactions.filter {
            it.category.name.equals(AppConstants.CATEGORY_SAVINGS_AND_GOALS, ignoreCase = true)
        }
        SummaryFilterTab.EXPENSES -> summary.transactions.filter {
            it.type == TransactionType.EXPENSE && !it.category.name.equals(AppConstants.CATEGORY_SAVINGS_AND_GOALS, ignoreCase = true)
        }
    }

    Text(
        text = "MONTH ACTIVITY (${filteredTransactions.size})",
        style = MaterialTheme.typography.labelSmall,
        fontWeight = FontWeight.Bold,
        color = MaterialTheme.colorScheme.onSurfaceVariant,
        letterSpacing = 0.8.sp
    )
    Spacer(modifier = Modifier.height(MaterialTheme.spacing.xs))

    if (filteredTransactions.isEmpty()) {
        Text(
            text = "No transactions recorded for this filter.",
            style = MaterialTheme.typography.bodyMedium,
            color = MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.6f),
            modifier = Modifier.padding(vertical = 12.dp)
        )
    } else {
        filteredTransactions.forEach { tx ->
            TransactionItem(
                transaction = tx,
                onClick = { onTransactionClick(tx.id) },
                modifier = Modifier.padding(vertical = 2.dp)
            )
        }
    }
}

@Composable
private fun SummaryStat(
    label: String,
    amount: Amount,
    color: Color = MaterialTheme.colorScheme.onSurface,
    isHighlight: Boolean = false
) {
    Column {
        Text(
            text = label,
            style = MaterialTheme.typography.labelSmall.copy(fontSize = 10.sp),
            color = Color.White.copy(alpha = 0.75f)
        )
        Text(
            text = amount.format(),
            style = MaterialTheme.typography.titleMedium,
            fontWeight = if (isHighlight) FontWeight.Bold else FontWeight.SemiBold,
            color = color
        )
    }
}

@Composable
private fun CategorySpendingRow(item: CategorySpending) {
    val isSavings = item.category.name.equals(AppConstants.CATEGORY_SAVINGS_AND_GOALS, ignoreCase = true)
    Column(modifier = Modifier.fillMaxWidth()) {
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                CategoryIcon(iconName = item.category.iconName, colorHex = item.category.colorHex, size = 34.dp, iconSize = 18.dp)
                Spacer(modifier = Modifier.width(MaterialTheme.spacing.sm))
                Column {
                    Text(text = item.category.name, style = MaterialTheme.typography.bodyMedium, fontWeight = FontWeight.Medium)
                    if (isSavings) {
                        Text(
                            text = "Planning Allocation",
                            style = MaterialTheme.typography.labelSmall.copy(fontSize = 10.sp),
                            color = MaterialTheme.colorScheme.primary
                        )
                    }
                }
            }
            Text(text = item.totalAmount.format(), style = MaterialTheme.typography.bodyMedium, fontWeight = FontWeight.SemiBold)
        }
        Spacer(modifier = Modifier.height(8.dp))
        LinearProgressIndicator(
            progress = { item.percentageOfTotal },
            modifier = Modifier
                .fillMaxWidth()
                .height(6.dp),
            color = if (isSavings) Color(0xFF38BDF8) else MaterialTheme.financialColors.expense,
            trackColor = MaterialTheme.colorScheme.surfaceVariant,
            strokeCap = StrokeCap.Round
        )
    }
}
