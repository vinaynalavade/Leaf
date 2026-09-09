package com.vinaynalavade.expensetracker.presentation.dashboard.components

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ArrowDownward
import androidx.compose.material.icons.filled.ArrowUpward
import androidx.compose.material.icons.filled.Visibility
import androidx.compose.material.icons.filled.VisibilityOff
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.vinaynalavade.expensetracker.domain.model.FinancialSummary
import com.vinaynalavade.expensetracker.domain.model.TransactionType
import com.vinaynalavade.expensetracker.presentation.components.AmountDisplay
import com.vinaynalavade.expensetracker.presentation.theme.HeroCardShape
import com.vinaynalavade.expensetracker.presentation.theme.HeroEmeraldGradient
import com.vinaynalavade.expensetracker.presentation.theme.HeroObsidianGradient
import com.vinaynalavade.expensetracker.presentation.theme.InnerCardShape
import com.vinaynalavade.expensetracker.presentation.theme.PillShape
import com.vinaynalavade.expensetracker.presentation.theme.PureWhite
import com.vinaynalavade.expensetracker.presentation.theme.SquircleIconShape
import com.vinaynalavade.expensetracker.presentation.theme.spacing

/**
 * Dominant, luxury Hero Balance Card inspired by modern fintech reference designs.
 * Features large 38sp financial typography, continuous 28dp squircle curvature,
 * gradient depth, visibility toggling, and integrated glassmorphic income/expense capsules.
 */
@Composable
fun BalanceHeroCard(
    summary: FinancialSummary,
    modifier: Modifier = Modifier
) {
    var isBalanceVisible by remember { mutableStateOf(true) }
    val isDark = isSystemInDarkTheme()
    val heroGradient = if (isDark) HeroObsidianGradient else HeroEmeraldGradient

    Box(
        modifier = modifier
            .fillMaxWidth()
            .padding(horizontal = MaterialTheme.spacing.screen)
            .shadow(
                elevation = if (isDark) 0.dp else 6.dp,
                shape = HeroCardShape,
                ambientColor = Color(0xFF025442).copy(alpha = 0.3f),
                spotColor = Color(0xFF025442).copy(alpha = 0.4f)
            )
            .clip(HeroCardShape)
            .background(heroGradient)
            .border(
                width = 0.75.dp,
                color = if (isDark) Color(0xFF263242) else Color.White.copy(alpha = 0.25f),
                shape = HeroCardShape
            )
            .padding(all = 22.dp)
    ) {
        Column(modifier = Modifier.fillMaxWidth()) {
            // Top Row: Label, Eye Toggle & Live Status Pill
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Text(
                        text = "TOTAL BALANCE",
                        style = MaterialTheme.typography.labelSmall.copy(
                            fontSize = 11.sp,
                            fontWeight = FontWeight.Bold,
                            letterSpacing = 1.2.sp
                        ),
                        color = Color.White.copy(alpha = 0.80f)
                    )
                    Spacer(modifier = Modifier.width(6.dp))
                    IconButton(
                        onClick = { isBalanceVisible = !isBalanceVisible },
                        modifier = Modifier.size(24.dp)
                    ) {
                        Icon(
                            imageVector = if (isBalanceVisible) Icons.Default.Visibility else Icons.Default.VisibilityOff,
                            contentDescription = if (isBalanceVisible) "Hide balance" else "Show balance",
                            tint = Color.White.copy(alpha = 0.80f),
                            modifier = Modifier.size(16.dp)
                        )
                    }
                }

                // Status Pill
                Box(
                    modifier = Modifier
                        .clip(PillShape)
                        .background(Color.White.copy(alpha = 0.15f))
                        .padding(horizontal = 10.dp, vertical = 4.dp)
                ) {
                    Text(
                        text = "Live Ledger",
                        style = MaterialTheme.typography.labelSmall.copy(
                            fontSize = 10.sp,
                            fontWeight = FontWeight.SemiBold
                        ),
                        color = Color.White
                    )
                }
            }

            Spacer(modifier = Modifier.height(10.dp))

            // Main Hero Amount (Massive 38sp confident typography)
            if (isBalanceVisible) {
                AmountDisplay(
                    amount = summary.currentBalance,
                    style = MaterialTheme.typography.displayLarge.copy(
                        color = PureWhite,
                        fontWeight = FontWeight.Bold,
                        letterSpacing = (-1.2).sp
                    ),
                    showPrefix = false
                )
            } else {
                Text(
                    text = "••••••••",
                    style = MaterialTheme.typography.displayLarge.copy(
                        color = PureWhite,
                        fontWeight = FontWeight.Bold,
                        letterSpacing = 2.sp
                    )
                )
            }

            Spacer(modifier = Modifier.height(18.dp))

            // Integrated Glassmorphic Income & Expense Capsules
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(12.dp)
            ) {
                HeroStatCapsule(
                    title = "Income",
                    amount = summary.totalIncome,
                    type = TransactionType.INCOME,
                    icon = Icons.Default.ArrowDownward,
                    isVisible = isBalanceVisible,
                    modifier = Modifier.weight(1f)
                )

                HeroStatCapsule(
                    title = "Expenses",
                    amount = summary.totalExpense,
                    type = TransactionType.EXPENSE,
                    icon = Icons.Default.ArrowUpward,
                    isVisible = isBalanceVisible,
                    modifier = Modifier.weight(1f)
                )
            }
        }
    }
}

@Composable
private fun HeroStatCapsule(
    title: String,
    amount: com.vinaynalavade.expensetracker.core.model.Amount,
    type: TransactionType,
    icon: ImageVector,
    isVisible: Boolean,
    modifier: Modifier = Modifier
) {
    val isIncome = type == TransactionType.INCOME
    val iconBgColor = if (isIncome) Color(0xFF10B981).copy(alpha = 0.25f) else Color(0xFFF43F5E).copy(alpha = 0.25f)
    val iconTint = if (isIncome) Color(0xFF34D399) else Color(0xFFFB7185)

    Row(
        modifier = modifier
            .clip(InnerCardShape)
            .background(Color.White.copy(alpha = 0.12f))
            .border(
                width = 0.5.dp,
                color = Color.White.copy(alpha = 0.18f),
                shape = InnerCardShape
            )
            .padding(horizontal = 12.dp, vertical = 10.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Box(
            modifier = Modifier
                .size(32.dp)
                .clip(SquircleIconShape)
                .background(iconBgColor),
            contentAlignment = Alignment.Center
        ) {
            Icon(
                imageVector = icon,
                contentDescription = null,
                tint = iconTint,
                modifier = Modifier.size(15.dp)
            )
        }

        Spacer(modifier = Modifier.width(10.dp))

        Column {
            Text(
                text = title,
                style = MaterialTheme.typography.labelSmall.copy(
                    fontSize = 11.sp,
                    color = Color.White.copy(alpha = 0.75f)
                )
            )
            if (isVisible) {
                AmountDisplay(
                    amount = amount,
                    type = type,
                    style = MaterialTheme.typography.titleMedium.copy(
                        color = PureWhite,
                        fontWeight = FontWeight.Bold,
                        fontSize = 15.sp
                    ),
                    showPrefix = true
                )
            } else {
                Text(
                    text = "•••••",
                    style = MaterialTheme.typography.titleMedium.copy(
                        color = PureWhite,
                        fontWeight = FontWeight.Bold
                    )
                )
            }
        }
    }
}

