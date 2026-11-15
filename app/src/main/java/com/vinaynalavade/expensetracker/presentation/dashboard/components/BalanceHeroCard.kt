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
import androidx.compose.material.icons.filled.ChevronRight
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
import com.vinaynalavade.expensetracker.domain.model.BalanceDisplayMode
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

import androidx.compose.ui.graphics.luminance
import com.vinaynalavade.expensetracker.presentation.theme.financialColors

/**
 * Dominant, luxury Hero Balance Card inspired by modern fintech reference designs.
 * Features large 38sp financial typography, continuous 28dp squircle curvature,
 * gradient depth, visibility toggling, and integrated glassmorphic income/expense capsules.
 */
@Composable
fun BalanceHeroCard(
    summary: FinancialSummary,
    isBalanceVisible: Boolean = true,
    cashBalance: com.vinaynalavade.expensetracker.core.model.Amount? = null,
    accountBalance: com.vinaynalavade.expensetracker.core.model.Amount? = null,
    displayMode: BalanceDisplayMode = BalanceDisplayMode.COMBINED,
    onToggleBalanceVisibility: () -> Unit = {},
    onModeChange: (BalanceDisplayMode) -> Unit = {},
    onLedgerClick: () -> Unit = {},
    modifier: Modifier = Modifier
) {
    val isDark = MaterialTheme.colorScheme.surface.luminance() < 0.5f
    val heroGradient = if (isDark) HeroObsidianGradient else HeroEmeraldGradient

    val displayedAmount = when (displayMode) {
        BalanceDisplayMode.COMBINED -> summary.currentBalance
        BalanceDisplayMode.ACCOUNT -> accountBalance ?: com.vinaynalavade.expensetracker.core.model.Amount.ZERO
        BalanceDisplayMode.CASH -> cashBalance ?: com.vinaynalavade.expensetracker.core.model.Amount.ZERO
    }

    val labelText = when (displayMode) {
        BalanceDisplayMode.COMBINED -> "TOTAL BALANCE"
        BalanceDisplayMode.ACCOUNT -> "ACCOUNT BALANCE"
        BalanceDisplayMode.CASH -> "CASH BALANCE"
    }

    val statusPillText = when (displayMode) {
        BalanceDisplayMode.COMBINED -> "Combined"
        BalanceDisplayMode.ACCOUNT -> "Account"
        BalanceDisplayMode.CASH -> "Cash"
    }

    Box(
        modifier = modifier
            .fillMaxWidth()
            .padding(horizontal = MaterialTheme.spacing.screen)
            .shadow(
                elevation = if (isDark) 0.dp else 6.dp,
                shape = HeroCardShape,
                ambientColor = if (isDark) Color(0x30000000) else Color(0xFF025442).copy(alpha = 0.25f),
                spotColor = if (isDark) Color(0x60000000) else Color(0xFF025442).copy(alpha = 0.35f)
            )
            .clip(HeroCardShape)
            .background(heroGradient)
            .border(
                width = 0.75.dp,
                color = if (isDark) MaterialTheme.colorScheme.outline.copy(alpha = 0.45f) else Color.White.copy(alpha = 0.25f),
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
                        text = labelText,
                        style = MaterialTheme.typography.labelSmall.copy(
                            fontSize = 11.sp,
                            fontWeight = FontWeight.Bold,
                            letterSpacing = 1.2.sp
                        ),
                        color = Color.White.copy(alpha = 0.80f)
                    )
                    Spacer(modifier = Modifier.width(6.dp))
                    IconButton(
                        onClick = onToggleBalanceVisibility,
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
                        text = statusPillText,
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
                    amount = displayedAmount,
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

            Spacer(modifier = Modifier.height(12.dp))

            // Balance Display Mode Selector (Combined | Account | Cash)
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .clip(PillShape)
                    .background(Color.White.copy(alpha = 0.12f))
                    .border(
                        width = 0.5.dp,
                        color = Color.White.copy(alpha = 0.15f),
                        shape = PillShape
                    )
                    .padding(3.dp),
                horizontalArrangement = Arrangement.spacedBy(4.dp)
            ) {
                BalanceDisplayMode.entries.forEach { mode ->
                    val isSelected = displayMode == mode
                    Box(
                        modifier = Modifier
                            .weight(1f)
                            .clip(PillShape)
                            .background(
                                if (isSelected) Color.White.copy(alpha = 0.28f)
                                else Color.Transparent
                            )
                            .clickable { onModeChange(mode) }
                            .padding(vertical = 6.dp),
                        contentAlignment = Alignment.Center
                    ) {
                        Text(
                            text = mode.displayName,
                            style = MaterialTheme.typography.labelSmall.copy(
                                fontSize = 11.sp,
                                fontWeight = if (isSelected) FontWeight.Bold else FontWeight.Medium
                            ),
                            color = if (isSelected) PureWhite else PureWhite.copy(alpha = 0.70f)
                        )
                    }
                }
            }

            // Cash & Account Ledger Breakdown Pills
            if (cashBalance != null && accountBalance != null) {
                Spacer(modifier = Modifier.height(10.dp))
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .clip(PillShape)
                        .clickable { onLedgerClick() }
                        .background(Color.White.copy(alpha = 0.10f))
                        .padding(horizontal = 10.dp, vertical = 6.dp),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Row(
                        horizontalArrangement = Arrangement.spacedBy(8.dp),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        // Cash Pill
                        Box(
                            modifier = Modifier
                                .clip(PillShape)
                                .background(Color.White.copy(alpha = 0.16f))
                                .padding(horizontal = 8.dp, vertical = 3.dp)
                        ) {
                            Text(
                                text = if (isBalanceVisible) "Cash: ${cashBalance.format()}" else "Cash: ••••",
                                style = MaterialTheme.typography.labelSmall.copy(
                                    fontSize = 11.sp,
                                    fontWeight = FontWeight.SemiBold
                                ),
                                color = Color.White
                            )
                        }

                        // Account Pill
                        Box(
                            modifier = Modifier
                                .clip(PillShape)
                                .background(Color.White.copy(alpha = 0.16f))
                                .padding(horizontal = 8.dp, vertical = 3.dp)
                        ) {
                            Text(
                                text = if (isBalanceVisible) "Account: ${accountBalance.format()}" else "Account: ••••",
                                style = MaterialTheme.typography.labelSmall.copy(
                                    fontSize = 11.sp,
                                    fontWeight = FontWeight.SemiBold
                                ),
                                color = Color.White
                            )
                        }
                    }

                    Icon(
                        imageVector = Icons.Default.ChevronRight,
                        contentDescription = "View Ledgers",
                        tint = Color.White.copy(alpha = 0.80f),
                        modifier = Modifier.size(16.dp)
                    )
                }
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
    val semanticColor = if (isIncome) MaterialTheme.financialColors.income else MaterialTheme.financialColors.expense
    val iconBgColor = semanticColor.copy(alpha = 0.25f)
    val iconTint = semanticColor

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

