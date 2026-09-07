package com.vinaynalavade.expensetracker.presentation.split.detail

import androidx.compose.foundation.Image
import androidx.compose.foundation.border
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
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material.icons.filled.Edit
import androidx.compose.material.icons.filled.QrCode
import androidx.compose.material.icons.filled.Share
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.vinaynalavade.expensetracker.R
import com.vinaynalavade.expensetracker.presentation.components.AppTopBar
import com.vinaynalavade.expensetracker.presentation.components.CategoryIcon
import com.vinaynalavade.expensetracker.presentation.components.LoadingView
import com.vinaynalavade.expensetracker.presentation.split.components.DeleteSplitConfirmDialog
import com.vinaynalavade.expensetracker.presentation.split.components.ParticipantShareRow
import com.vinaynalavade.expensetracker.presentation.split.components.SettlementConfirmDialog
import com.vinaynalavade.expensetracker.presentation.theme.ButtonShape
import com.vinaynalavade.expensetracker.presentation.theme.CardShape
import com.vinaynalavade.expensetracker.presentation.theme.IncomeEmerald
import com.vinaynalavade.expensetracker.presentation.theme.PillShape
import com.vinaynalavade.expensetracker.presentation.theme.spacing
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SplitDetailScreen(
    viewModel: SplitDetailViewModel,
    onNavigateBack: () -> Unit,
    onNavigateToEdit: (Long) -> Unit,
    modifier: Modifier = Modifier
) {
    val uiState by viewModel.uiState.collectAsStateWithLifecycle()
    val context = LocalContext.current
    val scrollState = rememberScrollState()
    val expense = uiState.splitExpense

    // Settlement confirmation dialog
    uiState.selectedParticipantForSettle?.let { participant ->
        SettlementConfirmDialog(
            participantName = participant.name,
            amount = participant.amount,
            currency = uiState.currency,
            onConfirm = { viewModel.confirmSettle() },
            onDismiss = { viewModel.dismissSettleDialog() }
        )
    }

    // Delete confirmation dialog
    if (uiState.showDeleteConfirmDialog) {
        DeleteSplitConfirmDialog(
            onConfirm = {
                viewModel.confirmDelete {
                    onNavigateBack()
                }
            },
            onDismiss = { viewModel.dismissDeleteDialog() }
        )
    }

    Scaffold(
        topBar = {
            AppTopBar(
                title = expense?.title ?: stringResource(R.string.split_title),
                canNavigateBack = true,
                onNavigateBack = onNavigateBack,
                actions = {
                    val currentExpense = expense
                    if (currentExpense != null) {
                        IconButton(onClick = { onNavigateToEdit(currentExpense.id) }) {
                            Icon(
                                imageVector = Icons.Default.Edit,
                                contentDescription = "Edit Split",
                                tint = MaterialTheme.colorScheme.onSurface
                            )
                        }
                        IconButton(onClick = { viewModel.onDeleteClick() }) {
                            Icon(
                                imageVector = Icons.Default.Delete,
                                contentDescription = "Delete Split",
                                tint = MaterialTheme.colorScheme.error
                            )
                        }
                    }
                }
            )
        },
        modifier = modifier.fillMaxSize()
    ) { innerPadding ->
        if (uiState.isLoading || expense == null) {
            LoadingView(modifier = Modifier.padding(innerPadding))
        } else {
            val dateFormat = SimpleDateFormat("EEEE, MMMM d, yyyy", Locale.getDefault())
            val formattedDate = dateFormat.format(Date(expense.date))
            val isFullySettled = expense.isFullySettled
            val hasEqualShares = expense.hasEqualShares

            Column(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(innerPadding)
                    .verticalScroll(scrollState)
                    .padding(MaterialTheme.spacing.md),
                verticalArrangement = Arrangement.spacedBy(MaterialTheme.spacing.md)
            ) {
                // Hero Header Card
                Card(
                    modifier = Modifier.fillMaxWidth(),
                    shape = CardShape,
                    colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface),
                    border = CardDefaults.outlinedCardBorder()
                ) {
                    Column(modifier = Modifier.padding(MaterialTheme.spacing.md)) {
                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            verticalAlignment = Alignment.CenterVertically,
                            horizontalArrangement = Arrangement.SpaceBetween
                        ) {
                            Row(verticalAlignment = Alignment.CenterVertically) {
                                CategoryIcon(
                                    iconName = expense.category?.iconName ?: "category",
                                    colorHex = expense.category?.colorHex ?: "#028166",
                                    size = 44.dp
                                )
                                Spacer(modifier = Modifier.width(MaterialTheme.spacing.sm))
                                Column {
                                    Text(
                                        text = expense.title,
                                        style = MaterialTheme.typography.titleLarge,
                                        fontWeight = FontWeight.Bold,
                                        color = MaterialTheme.colorScheme.onSurface
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
                                    text = expense.totalAmount.format(uiState.currency),
                                    style = MaterialTheme.typography.titleLarge,
                                    fontWeight = FontWeight.Bold,
                                    color = MaterialTheme.colorScheme.onSurface
                                )
                                Text(
                                    text = "Paid by ${expense.paidBy}",
                                    style = MaterialTheme.typography.labelSmall,
                                    color = MaterialTheme.colorScheme.onSurfaceVariant
                                )
                            }
                        }

                        Spacer(modifier = Modifier.height(MaterialTheme.spacing.md))

                        // Collection Status Metric Bar
                        Surface(
                            shape = CardShape,
                            color = MaterialTheme.colorScheme.surfaceVariant,
                            modifier = Modifier.fillMaxWidth()
                        ) {
                            Row(
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .padding(MaterialTheme.spacing.md),
                                horizontalArrangement = Arrangement.SpaceAround
                            ) {
                                Column(horizontalAlignment = Alignment.CenterHorizontally) {
                                    Text("Your Share", style = MaterialTheme.typography.labelSmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
                                    Text(expense.userShare.format(uiState.currency), style = MaterialTheme.typography.titleSmall, fontWeight = FontWeight.Bold)
                                }
                                Column(horizontalAlignment = Alignment.CenterHorizontally) {
                                    Text("Collected", style = MaterialTheme.typography.labelSmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
                                    Text(expense.collectedAmount.format(uiState.currency), style = MaterialTheme.typography.titleSmall, fontWeight = FontWeight.Bold, color = IncomeEmerald)
                                }
                                Column(horizontalAlignment = Alignment.CenterHorizontally) {
                                    Text("To Collect", style = MaterialTheme.typography.labelSmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
                                    Text(
                                        text = if (isFullySettled) "₹0 (Settled)" else expense.toCollectAmount.format(uiState.currency),
                                        style = MaterialTheme.typography.titleSmall,
                                        fontWeight = FontWeight.Bold,
                                        color = if (isFullySettled) IncomeEmerald else MaterialTheme.colorScheme.primary
                                    )
                                }
                            }
                        }
                    }
                }

                // Consolidated WhatsApp Sharing (When all other participants have equal shares)
                if (!isFullySettled && hasEqualShares) {
                    Button(
                        onClick = {
                            viewModel.onShareWhatsApp(context = context, isConsolidated = true)
                        },
                        shape = ButtonShape,
                        modifier = Modifier.fillMaxWidth(),
                        colors = ButtonDefaults.buttonColors(
                            containerColor = MaterialTheme.colorScheme.primary,
                            contentColor = MaterialTheme.colorScheme.onPrimary
                        )
                    ) {
                        Icon(
                            imageVector = Icons.Default.Share,
                            contentDescription = null,
                            modifier = Modifier.size(18.dp)
                        )
                        Spacer(modifier = Modifier.width(MaterialTheme.spacing.xs))
                        Text(
                            text = stringResource(R.string.split_share_everyone),
                            style = MaterialTheme.typography.labelLarge,
                            fontWeight = FontWeight.Bold
                        )
                    }
                }

                // UPI QR Code Preview Card (If attached)
                if (uiState.qrImageBitmap != null) {
                    Card(
                        modifier = Modifier.fillMaxWidth(),
                        shape = CardShape,
                        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface),
                        border = CardDefaults.outlinedCardBorder()
                    ) {
                        Column(
                            modifier = Modifier
                                .fillMaxWidth()
                                .padding(MaterialTheme.spacing.md),
                            horizontalAlignment = Alignment.CenterHorizontally
                        ) {
                            Row(
                                modifier = Modifier.fillMaxWidth(),
                                verticalAlignment = Alignment.CenterVertically
                            ) {
                                Icon(
                                    imageVector = Icons.Default.QrCode,
                                    contentDescription = null,
                                    tint = MaterialTheme.colorScheme.primary,
                                    modifier = Modifier.size(20.dp)
                                )
                                Spacer(modifier = Modifier.width(MaterialTheme.spacing.xs))
                                Text(
                                    text = stringResource(R.string.split_qr_preview_title),
                                    style = MaterialTheme.typography.titleSmall,
                                    fontWeight = FontWeight.Bold
                                )
                            }

                            Spacer(modifier = Modifier.height(MaterialTheme.spacing.md))

                            Image(
                                bitmap = uiState.qrImageBitmap!!,
                                contentDescription = "Recipient UPI QR",
                                modifier = Modifier
                                    .size(220.dp)
                                    .clip(RoundedCornerShape(8.dp))
                                    .border(1.dp, MaterialTheme.colorScheme.outlineVariant, RoundedCornerShape(8.dp)),
                                contentScale = ContentScale.Fit
                            )

                            Spacer(modifier = Modifier.height(MaterialTheme.spacing.sm))

                            Text(
                                text = "Participants can scan this QR with any UPI app to pay.",
                                style = MaterialTheme.typography.bodySmall,
                                color = MaterialTheme.colorScheme.onSurfaceVariant
                            )
                        }
                    }
                }

                // Participants Collection Section
                Card(
                    modifier = Modifier.fillMaxWidth(),
                    shape = CardShape,
                    colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface),
                    border = CardDefaults.outlinedCardBorder()
                ) {
                    Column(modifier = Modifier.padding(MaterialTheme.spacing.md)) {
                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.SpaceBetween,
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Text(
                                text = stringResource(R.string.split_shares_title),
                                style = MaterialTheme.typography.titleMedium,
                                fontWeight = FontWeight.Bold
                            )
                            if (isFullySettled) {
                                Surface(
                                    shape = PillShape,
                                    color = IncomeEmerald.copy(alpha = 0.12f),
                                    contentColor = IncomeEmerald
                                ) {
                                    Row(
                                        modifier = Modifier.padding(horizontal = 8.dp, vertical = 4.dp),
                                        verticalAlignment = Alignment.CenterVertically
                                    ) {
                                        Icon(imageVector = Icons.Default.CheckCircle, contentDescription = null, modifier = Modifier.size(12.dp))
                                        Spacer(modifier = Modifier.width(4.dp))
                                        Text(stringResource(R.string.split_status_fully_settled), style = MaterialTheme.typography.labelSmall, fontWeight = FontWeight.Bold)
                                    }
                                }
                            }
                        }

                        Spacer(modifier = Modifier.height(MaterialTheme.spacing.sm))

                        expense.participants.forEachIndexed { index, participant ->
                            if (index > 0) {
                                HorizontalDivider(
                                    modifier = Modifier.padding(vertical = MaterialTheme.spacing.xs),
                                    color = MaterialTheme.colorScheme.outlineVariant.copy(alpha = 0.35f)
                                )
                            }
                            ParticipantShareRow(
                                participant = participant,
                                currency = uiState.currency,
                                onMarkSettledClick = {
                                    viewModel.onMarkSettledClick(participant)
                                },
                                onMarkPendingClick = {
                                    viewModel.onMarkPendingClick(participant)
                                },
                                onShareClick = if (!participant.isCurrentUser && !hasEqualShares) {
                                    { viewModel.onShareWhatsApp(context = context, participant = participant, isConsolidated = false) }
                                } else null
                            )
                        }
                    }
                }
            }
        }
    }
}
