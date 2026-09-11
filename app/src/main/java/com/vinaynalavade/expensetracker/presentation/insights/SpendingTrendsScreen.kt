package com.vinaynalavade.expensetracker.presentation.insights

import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.tween
import androidx.compose.foundation.Canvas
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
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.TrendingDown
import androidx.compose.material.icons.automirrored.filled.TrendingUp
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.FilterChip
import androidx.compose.material3.Icon
import androidx.compose.material3.LinearProgressIndicator
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
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
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.vinaynalavade.expensetracker.R
import com.vinaynalavade.expensetracker.core.model.Amount
import com.vinaynalavade.expensetracker.core.model.Currency
import com.vinaynalavade.expensetracker.domain.model.SpendingTrendData
import com.vinaynalavade.expensetracker.presentation.components.AmountDisplay
import com.vinaynalavade.expensetracker.presentation.components.CategoryIcon
import com.vinaynalavade.expensetracker.presentation.components.EmptyStateView

@Composable
fun SpendingTrendsScreen(
    trendData: SpendingTrendData,
    currency: Currency,
    selectedMonthsCount: Int,
    onSelectMonthsCount: (Int) -> Unit,
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

    LazyColumn(
        modifier = modifier.fillMaxSize(),
        contentPadding = PaddingValues(horizontal = 20.dp, vertical = 16.dp),
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
                        onClick = { onSelectMonthsCount(count) },
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
                    Text(
                        text = stringResource(R.string.trends_monthly_spending),
                        style = MaterialTheme.typography.titleMedium,
                        fontWeight = FontWeight.Bold,
                        color = MaterialTheme.colorScheme.onSurface
                    )

                    Spacer(modifier = Modifier.height(16.dp))

                    MonthlyTrendCanvasChart(
                        points = trendData.monthlyPoints,
                        currency = currency,
                        modifier = Modifier
                            .fillMaxWidth()
                            .height(180.dp)
                    )
                }
            }
        }

        // Category Breakdown Section
        if (trendData.categoryBreakdown.isNotEmpty()) {
            item {
                Text(
                    text = stringResource(R.string.trends_top_categories),
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.Bold,
                    color = MaterialTheme.colorScheme.onSurface,
                    modifier = Modifier.padding(top = 8.dp)
                )
            }

            items(trendData.categoryBreakdown) { catSummary ->
                Card(
                    modifier = Modifier.fillMaxWidth(),
                    shape = RoundedCornerShape(16.dp),
                    colors = CardDefaults.cardColors(
                        containerColor = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.35f)
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
                                Text(
                                    text = catSummary.categoryName,
                                    style = MaterialTheme.typography.bodyMedium,
                                    fontWeight = FontWeight.SemiBold,
                                    color = MaterialTheme.colorScheme.onSurface
                                )
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
private fun MonthlyTrendCanvasChart(
    points: List<com.vinaynalavade.expensetracker.domain.model.MonthlySpendingPoint>,
    currency: Currency,
    modifier: Modifier = Modifier
) {
    val maxExpense = (points.maxOfOrNull { it.totalExpense } ?: 1.0).coerceAtLeast(1.0)
    val primaryColor = MaterialTheme.colorScheme.primary
    val barBrush = Brush.verticalGradient(
        colors = listOf(primaryColor, primaryColor.copy(alpha = 0.4f))
    )
    val gridColor = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.1f)
    val textColor = MaterialTheme.colorScheme.onSurfaceVariant

    Canvas(modifier = modifier) {
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
            val centerX = (index * availableWidth) + (availableWidth / 2f)
            val barHeightRatio = (point.totalExpense / maxExpense).toFloat().coerceIn(0.04f, 1f)
            val barHeight = chartHeight * barHeightRatio
            val topY = chartHeight - barHeight

            // Draw rounded bar
            drawRoundRect(
                brush = barBrush,
                topLeft = Offset(centerX - (barWidth / 2f), topY),
                size = Size(barWidth, barHeight),
                cornerRadius = CornerRadius(6.dp.toPx(), 6.dp.toPx())
            )

            // Month Label (e.g. "Oct")
            val monthLabel = point.yearMonth.split(" ").firstOrNull() ?: point.yearMonth
            drawContext.canvas.nativeCanvas.apply {
                val paint = android.graphics.Paint().apply {
                    color = android.graphics.Color.argb(
                        (textColor.alpha * 255).toInt(),
                        (textColor.red * 255).toInt(),
                        (textColor.green * 255).toInt(),
                        (textColor.blue * 255).toInt()
                    )
                    textSize = 10.sp.toPx()
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
