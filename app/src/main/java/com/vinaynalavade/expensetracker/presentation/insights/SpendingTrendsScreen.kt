package com.vinaynalavade.expensetracker.presentation.insights

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.expandVertically
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.shrinkVertically
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.gestures.detectTapGestures
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.asPaddingValues
import androidx.compose.foundation.layout.defaultMinSize
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.navigationBars
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.TrendingDown
import androidx.compose.material.icons.automirrored.filled.TrendingUp
import androidx.compose.material.icons.filled.Close
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.FilterChip
import androidx.compose.material3.FilterChipDefaults
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.LinearProgressIndicator
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.geometry.CornerRadius
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.nativeCanvas
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.vinaynalavade.expensetracker.R
import com.vinaynalavade.expensetracker.core.model.Amount
import com.vinaynalavade.expensetracker.core.model.Currency
import com.vinaynalavade.expensetracker.domain.model.CategorySpendingSummary
import com.vinaynalavade.expensetracker.domain.model.MonthlySpendingPoint
import com.vinaynalavade.expensetracker.domain.model.SpendingTrendData
import com.vinaynalavade.expensetracker.domain.model.TransactionType
import com.vinaynalavade.expensetracker.presentation.components.AmountDisplay
import com.vinaynalavade.expensetracker.presentation.components.CategoryIcon
import com.vinaynalavade.expensetracker.presentation.components.EmptyStateView
import com.vinaynalavade.expensetracker.presentation.components.TransactionItem
import com.vinaynalavade.expensetracker.presentation.theme.CardShape
import com.vinaynalavade.expensetracker.presentation.theme.PillShape

@Composable
fun SpendingTrendsScreen(
    trendData: SpendingTrendData,
    currency: Currency,
    selectedMonthsCount: Int,
    onSelectMonthsCount: (Int) -> Unit,
    onNavigateToTransactionDetail: (Long) -> Unit = {},
    modifier: Modifier = Modifier
) {
    if (trendData.monthlyPoints.all { it.totalExpense == 0.0 }) {
        EmptyStateView(
            title = "No spending trends data",
            description = "Add expenses across months to visualize your spending trends and patterns.",
            modifier = modifier
        )
        return
    }

    var selectedMonthIndex by remember(selectedMonthsCount) { mutableStateOf<Int?>(null) }
    var selectedCategorySummary by remember(selectedMonthsCount) { mutableStateOf<CategorySpendingSummary?>(null) }

    LazyColumn(
        modifier = modifier.fillMaxSize(),
        contentPadding = PaddingValues(
            start = 20.dp,
            end = 20.dp,
            top = 16.dp,
            bottom = 110.dp + WindowInsets.navigationBars.asPaddingValues().calculateBottomPadding()
        ),
        verticalArrangement = Arrangement.spacedBy(18.dp)
    ) {
        // Timeframe Selector Chips
        item {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                listOf(3, 6, 12).forEach { count ->
                    FilterChip(
                        selected = selectedMonthsCount == count,
                        onClick = {
                            selectedMonthIndex = null
                            selectedCategorySummary = null
                            onSelectMonthsCount(count)
                        },
                        label = { Text("$count Months") }
                    )
                }
            }
        }

        // Summary Metric Cards (Average & MoM Growth)
        item {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(12.dp)
            ) {
                // Average Monthly Card
                Card(
                    modifier = Modifier.weight(1f),
                    shape = RoundedCornerShape(20.dp),
                    colors = CardDefaults.cardColors(
                        containerColor = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.45f)
                    )
                ) {
                    Column(modifier = Modifier.padding(16.dp)) {
                        Text(
                            text = stringResource(R.string.trends_avg_monthly),
                            style = MaterialTheme.typography.labelSmall,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                        Spacer(modifier = Modifier.height(4.dp))
                        AmountDisplay(
                            amount = Amount((trendData.averageMonthlyExpense * currency.subunitFactor).toLong()),
                            currency = currency,
                            style = MaterialTheme.typography.titleMedium,
                            fontWeight = FontWeight.Bold
                        )
                    }
                }

                // MoM Growth Card
                val isIncrease = trendData.monthOverMonthGrowthRate > 0
                val momColor = if (isIncrease) Color(0xFFEF4444) else Color(0xFF10B981)
                Card(
                    modifier = Modifier.weight(1f),
                    shape = RoundedCornerShape(20.dp),
                    colors = CardDefaults.cardColors(
                        containerColor = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.45f)
                    )
                ) {
                    Column(modifier = Modifier.padding(16.dp)) {
                        Text(
                            text = stringResource(R.string.trends_mom_change),
                            style = MaterialTheme.typography.labelSmall,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                        Spacer(modifier = Modifier.height(4.dp))
                        Row(verticalAlignment = Alignment.CenterVertically) {
                            Icon(
                                imageVector = if (isIncrease) Icons.AutoMirrored.Filled.TrendingUp else Icons.AutoMirrored.Filled.TrendingDown,
                                contentDescription = null,
                                tint = momColor,
                                modifier = Modifier.size(18.dp)
                            )
                            Spacer(modifier = Modifier.width(4.dp))
                            Text(
                                text = "${if (isIncrease) "+" else ""}${String.format("%.1f", trendData.monthOverMonthGrowthRate)}%",
                                style = MaterialTheme.typography.titleMedium,
                                fontWeight = FontWeight.Bold,
                                color = momColor
                            )
                        }
                    }
                }
            }
        }

        // Multi-Month Canvas Chart Card
        item {
            Card(
                modifier = Modifier.fillMaxWidth(),
                shape = RoundedCornerShape(22.dp),
                colors = CardDefaults.cardColors(
                    containerColor = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.45f)
                )
            ) {
                Column(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(18.dp)
                ) {
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Column {
                            Text(
                                text = stringResource(R.string.trends_monthly_spending),
                                style = MaterialTheme.typography.titleMedium,
                                fontWeight = FontWeight.Bold,
                                color = MaterialTheme.colorScheme.onSurface
                            )
                            Text(
                                text = "Tap any bar or month chip to view details",
                                style = MaterialTheme.typography.labelSmall.copy(fontSize = 11.sp),
                                color = MaterialTheme.colorScheme.onSurfaceVariant
                            )
                        }
                        if (selectedMonthIndex != null) {
                            Text(
                                text = "Clear",
                                style = MaterialTheme.typography.labelSmall,
                                fontWeight = FontWeight.SemiBold,
                                color = MaterialTheme.colorScheme.primary,
                                modifier = Modifier
                                    .defaultMinSize(minHeight = 48.dp, minWidth = 48.dp)
                                    .clickable { selectedMonthIndex = null }
                                    .padding(vertical = 14.dp, horizontal = 8.dp)
                            )
                        }
                    }

                    Spacer(modifier = Modifier.height(16.dp))

                    MonthlyTrendCanvasChart(
                        points = trendData.monthlyPoints,
                        selectedIndex = selectedMonthIndex,
                        onPointSelected = { index ->
                            selectedMonthIndex = if (selectedMonthIndex == index) null else index
                        },
                        modifier = Modifier
                            .fillMaxWidth()
                            .height(180.dp)
                    )

                    Spacer(modifier = Modifier.height(12.dp))

                    // Month Selector Chips for easy accessible touch navigation
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .horizontalScroll(rememberScrollState()),
                        horizontalArrangement = Arrangement.spacedBy(8.dp)
                    ) {
                        trendData.monthlyPoints.forEachIndexed { index, point ->
                            FilterChip(
                                selected = selectedMonthIndex == index,
                                onClick = {
                                    selectedMonthIndex = if (selectedMonthIndex == index) null else index
                                },
                                label = {
                                    Text(
                                        text = point.yearMonth,
                                        style = MaterialTheme.typography.labelSmall,
                                        fontWeight = if (selectedMonthIndex == index) FontWeight.Bold else FontWeight.Normal
                                    )
                                },
                                shape = PillShape,
                                colors = FilterChipDefaults.filterChipColors(
                                    selectedContainerColor = MaterialTheme.colorScheme.primaryContainer,
                                    selectedLabelColor = MaterialTheme.colorScheme.onPrimaryContainer
                                )
                            )
                        }
                    }
                }
            }
        }

        // Selected Month Period Detail Card (Contributing Transactions)
        val activeMonthPoint = selectedMonthIndex?.let { trendData.monthlyPoints.getOrNull(it) }
        if (activeMonthPoint != null) {
            item {
                PeriodDetailsCard(
                    monthPoint = activeMonthPoint,
                    currency = currency,
                    onDismiss = { selectedMonthIndex = null },
                    onTransactionClick = onNavigateToTransactionDetail
                )
            }
        }

        // Category Breakdown Section
        if (trendData.categoryBreakdown.isNotEmpty()) {
            item {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Column {
                        Text(
                            text = stringResource(R.string.trends_top_categories),
                            style = MaterialTheme.typography.titleMedium,
                            fontWeight = FontWeight.Bold,
                            color = MaterialTheme.colorScheme.onSurface
                        )
                        Text(
                            text = "Tap a category to inspect its contributing transactions",
                            style = MaterialTheme.typography.labelSmall.copy(fontSize = 11.sp),
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                    }
                    if (selectedCategorySummary != null) {
                        Text(
                            text = "Clear filter",
                            style = MaterialTheme.typography.labelSmall,
                            fontWeight = FontWeight.SemiBold,
                            color = MaterialTheme.colorScheme.primary,
                            modifier = Modifier
                                .defaultMinSize(minHeight = 48.dp, minWidth = 48.dp)
                                .clickable { selectedCategorySummary = null }
                                .padding(vertical = 14.dp, horizontal = 8.dp)
                        )
                    }
                }
            }

            // If a category is selected, show its contributing transactions card
            if (selectedCategorySummary != null) {
                item {
                    CategoryDetailsCard(
                        categorySummary = selectedCategorySummary!!,
                        currency = currency,
                        onDismiss = { selectedCategorySummary = null },
                        onTransactionClick = onNavigateToTransactionDetail
                    )
                }
            }

            items(trendData.categoryBreakdown) { catSummary ->
                val isSelected = selectedCategorySummary?.categoryId == catSummary.categoryId
                Card(
                    modifier = Modifier
                        .fillMaxWidth()
                        .defaultMinSize(minHeight = 48.dp)
                        .clip(RoundedCornerShape(16.dp))
                        .then(
                            if (isSelected) {
                                Modifier.border(
                                    width = 1.5.dp,
                                    color = MaterialTheme.colorScheme.primary,
                                    shape = RoundedCornerShape(16.dp)
                                )
                            } else {
                                Modifier
                            }
                        )
                        .clickable {
                            selectedCategorySummary = if (isSelected) null else catSummary
                        },
                    shape = RoundedCornerShape(16.dp),
                    colors = CardDefaults.cardColors(
                        containerColor = if (isSelected) {
                            MaterialTheme.colorScheme.primaryContainer.copy(alpha = 0.25f)
                        } else {
                            MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.35f)
                        }
                    )
                ) {
                    Column(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(14.dp)
                    ) {
                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            verticalAlignment = Alignment.CenterVertically,
                            horizontalArrangement = Arrangement.SpaceBetween
                        ) {
                            Row(
                                verticalAlignment = Alignment.CenterVertically,
                                modifier = Modifier.weight(1f)
                            ) {
                                CategoryIcon(
                                    iconName = catSummary.categoryIcon,
                                    colorHex = catSummary.categoryColorHex,
                                    size = 36.dp,
                                    iconSize = 18.dp
                                )
                                Spacer(modifier = Modifier.width(10.dp))
                                Column {
                                    Row(verticalAlignment = Alignment.CenterVertically) {
                                        Text(
                                            text = catSummary.categoryName,
                                            style = MaterialTheme.typography.bodyMedium,
                                            fontWeight = if (isSelected) FontWeight.Bold else FontWeight.SemiBold,
                                            color = MaterialTheme.colorScheme.onSurface
                                        )
                                        if (isSelected) {
                                            Spacer(modifier = Modifier.width(6.dp))
                                            Box(
                                                modifier = Modifier
                                                    .clip(PillShape)
                                                    .background(MaterialTheme.colorScheme.primary.copy(alpha = 0.2f))
                                                    .padding(horizontal = 6.dp, vertical = 2.dp)
                                            ) {
                                                Text(
                                                    text = "Inspecting",
                                                    style = MaterialTheme.typography.labelSmall.copy(fontSize = 9.sp),
                                                    fontWeight = FontWeight.Bold,
                                                    color = MaterialTheme.colorScheme.primary
                                                )
                                            }
                                        }
                                    }
                                    if (catSummary.transactions.isNotEmpty()) {
                                        Text(
                                            text = "${catSummary.transactions.size} transactions",
                                            style = MaterialTheme.typography.labelSmall.copy(fontSize = 11.sp),
                                            color = MaterialTheme.colorScheme.onSurfaceVariant
                                        )
                                    }
                                }
                            }

                            Column(horizontalAlignment = Alignment.End) {
                                AmountDisplay(
                                    amount = Amount((catSummary.totalAmount * currency.subunitFactor).toLong()),
                                    currency = currency,
                                    style = MaterialTheme.typography.bodyMedium,
                                    fontWeight = FontWeight.Bold
                                )
                                Text(
                                    text = "${String.format("%.1f", catSummary.percentageOfTotal)}%",
                                    style = MaterialTheme.typography.labelSmall,
                                    color = MaterialTheme.colorScheme.onSurfaceVariant
                                )
                            }
                        }

                        Spacer(modifier = Modifier.height(8.dp))

                        val catColor = try {
                            val cleanHex = if (catSummary.categoryColorHex.startsWith("#")) catSummary.categoryColorHex.substring(1) else catSummary.categoryColorHex
                            val colorInt = cleanHex.toLong(16)
                            if (cleanHex.length == 6) Color(0xFF000000 or colorInt) else Color(colorInt)
                        } catch (_: Exception) {
                            MaterialTheme.colorScheme.primary
                        }

                        LinearProgressIndicator(
                            progress = { (catSummary.percentageOfTotal / 100.0).toFloat().coerceIn(0f, 1f) },
                            modifier = Modifier
                                .fillMaxWidth()
                                .height(6.dp)
                                .clip(CircleShape),
                            color = catColor,
                            trackColor = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.08f),
                            strokeCap = StrokeCap.Round
                        )
                    }
                }
            }
        }

        item {
            Spacer(modifier = Modifier.height(24.dp))
        }
    }
}

@Composable
private fun PeriodDetailsCard(
    monthPoint: MonthlySpendingPoint,
    currency: Currency,
    onDismiss: () -> Unit,
    onTransactionClick: (Long) -> Unit
) {
    val expenseTxs = monthPoint.transactions.filter { it.type == TransactionType.EXPENSE }

    Card(
        modifier = Modifier
            .fillMaxWidth()
            .border(
                width = 1.dp,
                color = MaterialTheme.colorScheme.primary.copy(alpha = 0.4f),
                shape = RoundedCornerShape(20.dp)
            ),
        shape = RoundedCornerShape(20.dp),
        colors = CardDefaults.cardColors(
            containerColor = MaterialTheme.colorScheme.surface
        ),
        elevation = CardDefaults.cardElevation(defaultElevation = 2.dp)
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(18.dp)
        ) {
            // Header Row with Title and Close Button
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Column {
                    Text(
                        text = "${monthPoint.yearMonth.uppercase()} CONTRIBUTIONS",
                        style = MaterialTheme.typography.labelSmall,
                        fontWeight = FontWeight.Bold,
                        color = MaterialTheme.colorScheme.primary,
                        letterSpacing = 1.sp
                    )
                    Text(
                        text = "Period Summary & Transactions",
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }

                IconButton(
                    onClick = onDismiss,
                    modifier = Modifier.size(48.dp)
                ) {
                    Icon(
                        imageVector = Icons.Default.Close,
                        contentDescription = "Return to Trend Overview",
                        tint = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }
            }

            Spacer(modifier = Modifier.height(12.dp))

            // Period Total Summary Box
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .clip(RoundedCornerShape(14.dp))
                    .background(MaterialTheme.colorScheme.primaryContainer.copy(alpha = 0.35f))
                    .padding(14.dp)
            ) {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Column {
                        Text(
                            text = "Period Total Expenses",
                            style = MaterialTheme.typography.labelSmall,
                            color = MaterialTheme.colorScheme.onPrimaryContainer.copy(alpha = 0.8f)
                        )
                        AmountDisplay(
                            amount = Amount((monthPoint.totalExpense * currency.subunitFactor).toLong()),
                            currency = currency,
                            style = MaterialTheme.typography.titleLarge,
                            fontWeight = FontWeight.Bold
                        )
                    }

                    if (monthPoint.totalIncome > 0) {
                        Column(horizontalAlignment = Alignment.End) {
                            Text(
                                text = "Period Income",
                                style = MaterialTheme.typography.labelSmall,
                                color = MaterialTheme.colorScheme.onPrimaryContainer.copy(alpha = 0.8f)
                            )
                            AmountDisplay(
                                amount = Amount((monthPoint.totalIncome * currency.subunitFactor).toLong()),
                                currency = currency,
                                style = MaterialTheme.typography.titleMedium,
                                fontWeight = FontWeight.SemiBold
                            )
                        }
                    }
                }
            }

            Spacer(modifier = Modifier.height(16.dp))

            // Contributing Transactions List
            Text(
                text = "CONTRIBUTING TRANSACTIONS (${expenseTxs.size})",
                style = MaterialTheme.typography.labelSmall,
                fontWeight = FontWeight.Bold,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
                letterSpacing = 0.8.sp
            )

            Spacer(modifier = Modifier.height(8.dp))

            if (expenseTxs.isEmpty()) {
                Text(
                    text = "No individual expense transactions recorded for ${monthPoint.yearMonth}.",
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.7f),
                    modifier = Modifier.padding(vertical = 12.dp)
                )
            } else {
                expenseTxs.take(15).forEach { tx ->
                    TransactionItem(
                        transaction = tx,
                        onClick = { onTransactionClick(tx.id) },
                        modifier = Modifier.padding(vertical = 2.dp)
                    )
                }

                if (expenseTxs.size > 15) {
                    Text(
                        text = "Showing 15 of ${expenseTxs.size} transactions for this period.",
                        style = MaterialTheme.typography.labelSmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                        modifier = Modifier.padding(top = 8.dp)
                    )
                }
            }

            Spacer(modifier = Modifier.height(14.dp))

            OutlinedButton(
                onClick = onDismiss,
                modifier = Modifier
                    .fillMaxWidth()
                    .defaultMinSize(minHeight = 48.dp),
                shape = RoundedCornerShape(12.dp)
            ) {
                Text("Return to Trend Overview")
            }
        }
    }
}

@Composable
private fun CategoryDetailsCard(
    categorySummary: CategorySpendingSummary,
    currency: Currency,
    onDismiss: () -> Unit,
    onTransactionClick: (Long) -> Unit
) {
    Card(
        modifier = Modifier
            .fillMaxWidth()
            .border(
                width = 1.dp,
                color = MaterialTheme.colorScheme.primary.copy(alpha = 0.4f),
                shape = RoundedCornerShape(20.dp)
            ),
        shape = RoundedCornerShape(20.dp),
        colors = CardDefaults.cardColors(
            containerColor = MaterialTheme.colorScheme.surface
        ),
        elevation = CardDefaults.cardElevation(defaultElevation = 2.dp)
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(18.dp)
        ) {
            // Header Row
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    modifier = Modifier.weight(1f)
                ) {
                    CategoryIcon(
                        iconName = categorySummary.categoryIcon,
                        colorHex = categorySummary.categoryColorHex,
                        size = 36.dp,
                        iconSize = 20.dp
                    )
                    Spacer(modifier = Modifier.width(10.dp))
                    Column {
                        Text(
                            text = categorySummary.categoryName.uppercase(),
                            style = MaterialTheme.typography.labelSmall,
                            fontWeight = FontWeight.Bold,
                            color = MaterialTheme.colorScheme.primary,
                            letterSpacing = 1.sp
                        )
                        Text(
                            text = "Contributing Transactions Over Period",
                            style = MaterialTheme.typography.bodySmall,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                    }
                }

                IconButton(
                    onClick = onDismiss,
                    modifier = Modifier.size(48.dp)
                ) {
                    Icon(
                        imageVector = Icons.Default.Close,
                        contentDescription = "Return to All Categories",
                        tint = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }
            }

            Spacer(modifier = Modifier.height(12.dp))

            // Total box
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .clip(RoundedCornerShape(14.dp))
                    .background(MaterialTheme.colorScheme.primaryContainer.copy(alpha = 0.35f))
                    .padding(14.dp)
            ) {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Column {
                        Text(
                            text = "Total Spending in Period",
                            style = MaterialTheme.typography.labelSmall,
                            color = MaterialTheme.colorScheme.onPrimaryContainer.copy(alpha = 0.8f)
                        )
                        AmountDisplay(
                            amount = Amount((categorySummary.totalAmount * currency.subunitFactor).toLong()),
                            currency = currency,
                            style = MaterialTheme.typography.titleLarge,
                            fontWeight = FontWeight.Bold
                        )
                    }

                    Column(horizontalAlignment = Alignment.End) {
                        Text(
                            text = "Share of Total Spend",
                            style = MaterialTheme.typography.labelSmall,
                            color = MaterialTheme.colorScheme.onPrimaryContainer.copy(alpha = 0.8f)
                        )
                        Text(
                            text = "${String.format("%.1f", categorySummary.percentageOfTotal)}%",
                            style = MaterialTheme.typography.titleMedium,
                            fontWeight = FontWeight.Bold,
                            color = MaterialTheme.colorScheme.primary
                        )
                    }
                }
            }

            Spacer(modifier = Modifier.height(16.dp))

            Text(
                text = "TRANSACTIONS (${categorySummary.transactions.size})",
                style = MaterialTheme.typography.labelSmall,
                fontWeight = FontWeight.Bold,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
                letterSpacing = 0.8.sp
            )

            Spacer(modifier = Modifier.height(8.dp))

            if (categorySummary.transactions.isEmpty()) {
                Text(
                    text = "No individual transactions recorded for this category.",
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.7f),
                    modifier = Modifier.padding(vertical = 12.dp)
                )
            } else {
                categorySummary.transactions.take(15).forEach { tx ->
                    TransactionItem(
                        transaction = tx,
                        onClick = { onTransactionClick(tx.id) },
                        modifier = Modifier.padding(vertical = 2.dp)
                    )
                }

                if (categorySummary.transactions.size > 15) {
                    Text(
                        text = "Showing 15 of ${categorySummary.transactions.size} transactions.",
                        style = MaterialTheme.typography.labelSmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                        modifier = Modifier.padding(top = 8.dp)
                    )
                }
            }

            Spacer(modifier = Modifier.height(14.dp))

            OutlinedButton(
                onClick = onDismiss,
                modifier = Modifier
                    .fillMaxWidth()
                    .defaultMinSize(minHeight = 48.dp),
                shape = RoundedCornerShape(12.dp)
            ) {
                Text("Return to All Categories")
            }
        }
    }
}

@Composable
private fun MonthlyTrendCanvasChart(
    points: List<MonthlySpendingPoint>,
    selectedIndex: Int?,
    onPointSelected: (Int) -> Unit,
    modifier: Modifier = Modifier
) {
    val maxExpense = (points.maxOfOrNull { it.totalExpense } ?: 1.0).coerceAtLeast(1.0)
    val primaryColor = MaterialTheme.colorScheme.primary
    val gridColor = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.1f)
    val textColor = MaterialTheme.colorScheme.onSurfaceVariant

    Canvas(
        modifier = modifier
            .pointerInput(points) {
                detectTapGestures { offset ->
                    if (points.isNotEmpty() && size.width > 0) {
                        val availableWidth = size.width.toFloat() / points.size
                        val clickedIndex = (offset.x / availableWidth).toInt().coerceIn(0, points.lastIndex)
                        onPointSelected(clickedIndex)
                    }
                }
            }
    ) {
        val width = size.width
        val height = size.height
        val bottomPadding = 32.dp.toPx()
        val chartHeight = height - bottomPadding

        // Horizontal gridlines (3 lines)
        val gridLines = 3
        for (i in 0..gridLines) {
            val y = chartHeight * (i.toFloat() / gridLines)
            drawLine(
                color = gridColor,
                start = Offset(0f, y),
                end = Offset(width, y),
                strokeWidth = 1.dp.toPx()
            )
        }

        if (points.isEmpty()) return@Canvas

        val barCount = points.size
        val availableWidth = width / barCount
        val barWidth = (availableWidth * 0.55f).coerceIn(16.dp.toPx(), 42.dp.toPx())

        points.forEachIndexed { index, point ->
            val isSelected = selectedIndex == index
            val isAnySelected = selectedIndex != null

            val centerX = (index * availableWidth) + (availableWidth / 2f)
            val barHeightRatio = (point.totalExpense / maxExpense).toFloat().coerceIn(0.04f, 1f)
            val barHeight = chartHeight * barHeightRatio
            val topY = chartHeight - barHeight

            val barAlpha = when {
                isSelected -> 1f
                isAnySelected -> 0.30f
                else -> 0.85f
            }

            val brush = if (isSelected) {
                Brush.verticalGradient(
                    colors = listOf(primaryColor, primaryColor.copy(alpha = 0.7f))
                )
            } else {
                Brush.verticalGradient(
                    colors = listOf(primaryColor.copy(alpha = barAlpha), primaryColor.copy(alpha = barAlpha * 0.4f))
                )
            }

            // Draw rounded bar
            drawRoundRect(
                brush = brush,
                topLeft = Offset(centerX - (barWidth / 2f), topY),
                size = Size(barWidth, barHeight),
                cornerRadius = CornerRadius(6.dp.toPx(), 6.dp.toPx())
            )

            // Draw selection indicator highlight if selected
            if (isSelected) {
                drawCircle(
                    color = primaryColor,
                    radius = 4.dp.toPx(),
                    center = Offset(centerX, (topY - 8.dp.toPx()).coerceAtLeast(6.dp.toPx()))
                )
            }

            // Month Label (e.g. "Oct")
            val monthLabel = point.yearMonth.split(" ").firstOrNull() ?: point.yearMonth
            drawContext.canvas.nativeCanvas.apply {
                val paint = android.graphics.Paint().apply {
                    color = if (isSelected) {
                        android.graphics.Color.argb(
                            255,
                            (primaryColor.red * 255).toInt(),
                            (primaryColor.green * 255).toInt(),
                            (primaryColor.blue * 255).toInt()
                        )
                    } else {
                        android.graphics.Color.argb(
                            (textColor.alpha * 255).toInt(),
                            (textColor.red * 255).toInt(),
                            (textColor.green * 255).toInt(),
                            (textColor.blue * 255).toInt()
                        )
                    }
                    textSize = if (isSelected) 11.sp.toPx() else 10.sp.toPx()
                    isFakeBoldText = isSelected
                    textAlign = android.graphics.Paint.Align.CENTER
                    isAntiAlias = true
                }
                drawText(
                    monthLabel,
                    centerX,
                    height - 8.dp.toPx(),
                    paint
                )
            }
        }
    }
}
