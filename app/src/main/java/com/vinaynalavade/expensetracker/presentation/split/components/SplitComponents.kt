package com.vinaynalavade.expensetracker.presentation.split.components

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
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
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowForward
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.QrCode
import androidx.compose.material.icons.filled.Share
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.FilledTonalButton
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.LinearProgressIndicator
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.ImageBitmap
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import com.vinaynalavade.expensetracker.R
import com.vinaynalavade.expensetracker.core.model.Amount
import com.vinaynalavade.expensetracker.core.model.Currency
import com.vinaynalavade.expensetracker.domain.model.SettlementStatus
import com.vinaynalavade.expensetracker.domain.model.SplitExpense
import com.vinaynalavade.expensetracker.domain.model.SplitParticipant
import com.vinaynalavade.expensetracker.presentation.components.CategoryIcon
import com.vinaynalavade.expensetracker.presentation.theme.ButtonShape
import com.vinaynalavade.expensetracker.presentation.theme.CardShape
import com.vinaynalavade.expensetracker.presentation.theme.IncomeEmerald
import com.vinaynalavade.expensetracker.presentation.theme.PillShape
import com.vinaynalavade.expensetracker.presentation.theme.spacing
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

/**
 * Clean card representing a shared split expense on the Split Landing screen.
 */
@Composable
fun SplitExpenseCard(
    splitExpense: SplitExpense,
    currency: Currency,
    onClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    val dateFormat = SimpleDateFormat("MMM d, yyyy", Locale.getDefault())
    val formattedDate = dateFormat.format(Date(splitExpense.date))
    val isFullySettled = splitExpense.isFullySettled
    val totalOtherCount = splitExpense.otherParticipants.size
    val settledCount = splitExpense.otherParticipants.count { it.isSettled }

    Card(
        modifier = modifier
            .fillMaxWidth()
            .clip(CardShape)
            .clickable(onClick = onClick),
        shape = CardShape,
        colors = CardDefaults.cardColors(
            containerColor = MaterialTheme.colorScheme.surface
        ),
        border = CardDefaults.outlinedCardBorder().copy(
            brush = androidx.compose.ui.graphics.SolidColor(MaterialTheme.colorScheme.outlineVariant.copy(alpha = 0.5f))
        )
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(MaterialTheme.spacing.md)
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
                        iconName = splitExpense.category?.iconName ?: "category",
                        colorHex = splitExpense.category?.colorHex ?: "#028166",
                        size = 38.dp
                    )
                    Spacer(modifier = Modifier.width(MaterialTheme.spacing.sm))
                    Column {
                        Text(
                            text = splitExpense.title,
                            style = MaterialTheme.typography.titleMedium,
                            fontWeight = FontWeight.SemiBold,
                            color = MaterialTheme.colorScheme.onSurface,
                            maxLines = 1,
                            overflow = TextOverflow.Ellipsis
                        )
                        Text(
                            text = formattedDate,
                            style = MaterialTheme.typography.bodySmall,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                    }
                }

                Column(horizontalAlignment = Alignment.End) {
                    Text(
                        text = splitExpense.totalAmount.format(currency),
                        style = MaterialTheme.typography.titleMedium,
                        fontWeight = FontWeight.Bold,
                        color = MaterialTheme.colorScheme.onSurface
                    )
                    Text(
                        text = "You paid ${splitExpense.totalAmount.format(currency)}",
                        style = MaterialTheme.typography.labelSmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }
            }

            Spacer(modifier = Modifier.height(MaterialTheme.spacing.sm))

            // Settlement Status Bar
            Row(
                modifier = Modifier.fillMaxWidth(),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.SpaceBetween
            ) {
                if (isFullySettled) {
                    Surface(
                        shape = PillShape,
                        color = IncomeEmerald.copy(alpha = 0.12f),
                        contentColor = IncomeEmerald
                    ) {
                        Row(
                            modifier = Modifier.padding(horizontal = 10.dp, vertical = 4.dp),
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Icon(
                                imageVector = Icons.Default.CheckCircle,
                                contentDescription = null,
                                modifier = Modifier.size(14.dp)
                            )
                            Spacer(modifier = Modifier.width(4.dp))
                            Text(
                                text = stringResource(R.string.split_status_fully_settled),
                                style = MaterialTheme.typography.labelSmall,
                                fontWeight = FontWeight.Bold
                            )
                        }
                    }
                } else {
                    Text(
                        text = "${splitExpense.toCollectAmount.format(currency)} to collect",
                        style = MaterialTheme.typography.labelMedium,
                        fontWeight = FontWeight.SemiBold,
                        color = MaterialTheme.colorScheme.primary
                    )
                    if (totalOtherCount > 0) {
                        Text(
                            text = "$settledCount of $totalOtherCount settled",
                            style = MaterialTheme.typography.labelSmall,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                    }
                }
            }

            if (!isFullySettled && totalOtherCount > 0) {
                Spacer(modifier = Modifier.height(MaterialTheme.spacing.xs))
                LinearProgressIndicator(
                    progress = { settledCount.toFloat() / totalOtherCount.toFloat() },
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(4.dp)
                        .clip(RoundedCornerShape(2.dp)),
                    color = MaterialTheme.colorScheme.primary,
                    trackColor = MaterialTheme.colorScheme.surfaceVariant
                )
            }
        }
    }
}

/**
 * Row displaying an individual participant's share, settlement status, and action buttons.
 */
@Composable
fun ParticipantShareRow(
    participant: SplitParticipant,
    currency: Currency,
    onMarkSettledClick: (() -> Unit)?,
    onMarkPendingClick: (() -> Unit)?,
    onShareClick: (() -> Unit)?,
    modifier: Modifier = Modifier
) {
    val isCurrentUser = participant.isCurrentUser
    val isSettled = participant.isSettled

    Row(
        modifier = modifier
            .fillMaxWidth()
            .padding(vertical = MaterialTheme.spacing.xs),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.SpaceBetween
    ) {
        Row(
            verticalAlignment = Alignment.CenterVertically,
            modifier = Modifier.weight(1f)
        ) {
            // Participant Avatar Initial
            Box(
                modifier = Modifier
                    .size(36.dp)
                    .clip(CircleShape)
                    .background(
                        if (isCurrentUser) MaterialTheme.colorScheme.primary.copy(alpha = 0.12f)
                        else MaterialTheme.colorScheme.surfaceVariant
                    ),
                contentAlignment = Alignment.Center
            ) {
                Text(
                    text = participant.name.take(1).uppercase(Locale.getDefault()),
                    style = MaterialTheme.typography.labelMedium,
                    fontWeight = FontWeight.Bold,
                    color = if (isCurrentUser) MaterialTheme.colorScheme.primary else MaterialTheme.colorScheme.onSurfaceVariant
                )
            }

            Spacer(modifier = Modifier.width(MaterialTheme.spacing.sm))

            Column {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Text(
                        text = if (isCurrentUser) "${participant.name} (You)" else participant.name,
                        style = MaterialTheme.typography.bodyMedium,
                        fontWeight = if (isCurrentUser) FontWeight.Bold else FontWeight.Medium,
                        color = MaterialTheme.colorScheme.onSurface
                    )
                }
                Text(
                    text = participant.amount.format(currency),
                    style = MaterialTheme.typography.labelSmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
        }

        Row(verticalAlignment = Alignment.CenterVertically) {
            if (isCurrentUser) {
                Surface(
                    shape = PillShape,
                    color = MaterialTheme.colorScheme.surfaceVariant,
                    contentColor = MaterialTheme.colorScheme.onSurfaceVariant
                ) {
                    Text(
                        text = "Your Share",
                        style = MaterialTheme.typography.labelSmall,
                        fontWeight = FontWeight.Medium,
                        modifier = Modifier.padding(horizontal = 8.dp, vertical = 4.dp)
                    )
                }
            } else {
                if (isSettled) {
                    Surface(
                        shape = PillShape,
                        color = IncomeEmerald.copy(alpha = 0.12f),
                        contentColor = IncomeEmerald,
                        modifier = Modifier.clickable { onMarkPendingClick?.invoke() }
                    ) {
                        Row(
                            modifier = Modifier.padding(horizontal = 8.dp, vertical = 4.dp),
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Icon(
                                imageVector = Icons.Default.Check,
                                contentDescription = null,
                                modifier = Modifier.size(12.dp)
                            )
                            Spacer(modifier = Modifier.width(4.dp))
                            Text(
                                text = "Settled",
                                style = MaterialTheme.typography.labelSmall,
                                fontWeight = FontWeight.Bold
                            )
                        }
                    }
                } else {
                    if (onShareClick != null) {
                        IconButton(
                            onClick = onShareClick,
                            modifier = Modifier.size(32.dp)
                        ) {
                            Icon(
                                imageVector = Icons.Default.Share,
                                contentDescription = "Share",
                                tint = MaterialTheme.colorScheme.primary,
                                modifier = Modifier.size(18.dp)
                            )
                        }
                        Spacer(modifier = Modifier.width(4.dp))
                    }

                    FilledTonalButton(
                        onClick = { onMarkSettledClick?.invoke() },
                        shape = PillShape,
                        contentPadding = androidx.compose.foundation.layout.PaddingValues(horizontal = 10.dp, vertical = 4.dp),
                        colors = ButtonDefaults.filledTonalButtonColors(
                            containerColor = MaterialTheme.colorScheme.primaryContainer,
                            contentColor = MaterialTheme.colorScheme.onPrimaryContainer
                        )
                    ) {
                        Text(
                            text = "Settle",
                            style = MaterialTheme.typography.labelSmall,
                            fontWeight = FontWeight.Bold
                        )
                    }
                }
            }
        }
    }
}

/**
 * Confirmation dialog before marking a participant as settled.
 */
@Composable
fun SettlementConfirmDialog(
    participantName: String,
    amount: Amount,
    currency: Currency,
    onConfirm: () -> Unit,
    onDismiss: () -> Unit
) {
    AlertDialog(
        onDismissRequest = onDismiss,
        title = {
            Text(
                text = stringResource(R.string.split_settle_confirm_title),
                style = MaterialTheme.typography.titleMedium,
                fontWeight = FontWeight.Bold
            )
        },
        text = {
            Text(
                text = stringResource(
                    R.string.split_settle_confirm_msg,
                    amount.format(currency),
                    participantName
                ),
                style = MaterialTheme.typography.bodyMedium
            )
        },
        confirmButton = {
            Button(
                onClick = {
                    onConfirm()
                    onDismiss()
                },
                shape = ButtonShape
            ) {
                Text(stringResource(R.string.split_mark_settled))
            }
        },
        dismissButton = {
            TextButton(
                onClick = onDismiss,
                shape = ButtonShape
            ) {
                Text(stringResource(R.string.btn_cancel))
            }
        }
    )
}

/**
 * Confirmation dialog before deleting a split expense.
 */
@Composable
fun DeleteSplitConfirmDialog(
    onConfirm: () -> Unit,
    onDismiss: () -> Unit
) {
    AlertDialog(
        onDismissRequest = onDismiss,
        title = {
            Text(
                text = stringResource(R.string.split_delete_confirm_title),
                style = MaterialTheme.typography.titleMedium,
                fontWeight = FontWeight.Bold
            )
        },
        text = {
            Text(
                text = stringResource(R.string.split_delete_confirm_msg),
                style = MaterialTheme.typography.bodyMedium
            )
        },
        confirmButton = {
            Button(
                onClick = {
                    onConfirm()
                    onDismiss()
                },
                colors = ButtonDefaults.buttonColors(
                    containerColor = MaterialTheme.colorScheme.error,
                    contentColor = MaterialTheme.colorScheme.onError
                ),
                shape = ButtonShape
            ) {
                Text(stringResource(R.string.btn_delete))
            }
        },
        dismissButton = {
            TextButton(
                onClick = onDismiss,
                shape = ButtonShape
            ) {
                Text(stringResource(R.string.btn_cancel))
            }
        }
    )
}

/**
 * Live allocation balance indicator for Custom Split mode.
 */
@Composable
fun CustomSplitBalanceIndicator(
    totalAmount: Amount,
    allocatedAmount: Amount,
    remainingAmount: Amount,
    overallocatedAmount: Amount,
    currency: Currency,
    modifier: Modifier = Modifier
) {
    val isBalanced = remainingAmount.isZero && overallocatedAmount.isZero
    val isOver = overallocatedAmount.isPositive

    Surface(
        modifier = modifier.fillMaxWidth(),
        shape = CardShape,
        color = when {
            isBalanced -> IncomeEmerald.copy(alpha = 0.08f)
            isOver -> MaterialTheme.colorScheme.errorContainer.copy(alpha = 0.5f)
            else -> MaterialTheme.colorScheme.surfaceVariant
        },
        border = CardDefaults.outlinedCardBorder().copy(
            brush = androidx.compose.ui.graphics.SolidColor(
                when {
                    isBalanced -> IncomeEmerald.copy(alpha = 0.3f)
                    isOver -> MaterialTheme.colorScheme.error.copy(alpha = 0.3f)
                    else -> MaterialTheme.colorScheme.outlineVariant.copy(alpha = 0.5f)
                }
            )
        )
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(MaterialTheme.spacing.md),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.SpaceBetween
        ) {
            Column {
                Text(
                    text = "Allocated: ${allocatedAmount.format(currency)} / ${totalAmount.format(currency)}",
                    style = MaterialTheme.typography.labelMedium,
                    fontWeight = FontWeight.Bold,
                    color = MaterialTheme.colorScheme.onSurface
                )
                Text(
                    text = when {
                        isBalanced -> "✓ Exactly allocated"
                        isOver -> "Overallocated by ${overallocatedAmount.format(currency)}"
                        else -> "Remaining to allocate: ${remainingAmount.format(currency)}"
                    },
                    style = MaterialTheme.typography.bodySmall,
                    color = when {
                        isBalanced -> IncomeEmerald
                        isOver -> MaterialTheme.colorScheme.error
                        else -> MaterialTheme.colorScheme.onSurfaceVariant
                    },
                    fontWeight = if (isBalanced) FontWeight.SemiBold else FontWeight.Normal
                )
            }

            if (isBalanced) {
                Icon(
                    imageVector = Icons.Default.CheckCircle,
                    contentDescription = null,
                    tint = IncomeEmerald,
                    modifier = Modifier.size(24.dp)
                )
            }
        }
    }
}
