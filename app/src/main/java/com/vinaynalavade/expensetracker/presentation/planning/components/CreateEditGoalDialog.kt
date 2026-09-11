package com.vinaynalavade.expensetracker.presentation.planning.components

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
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardCapitalization
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp
import com.vinaynalavade.expensetracker.R
import com.vinaynalavade.expensetracker.core.model.Currency
import com.vinaynalavade.expensetracker.domain.model.SavingsGoal

private val AVAILABLE_COLORS = listOf(
    "#3B82F6", // Blue
    "#10B981", // Emerald
    "#8B5CF6", // Purple
    "#EC4899", // Pink
    "#F59E0B", // Amber
    "#06B6D4", // Cyan
    "#F97316", // Orange
    "#6366F1"  // Indigo
)

@Composable
fun CreateEditGoalDialog(
    initialGoal: SavingsGoal? = null,
    currency: Currency,
    onDismiss: () -> Unit,
    onSave: (SavingsGoal) -> Unit
) {
    var name by remember { mutableStateOf(initialGoal?.name ?: "") }
    var nameError by remember { mutableStateOf<String?>(null) }
    var targetAmountText by remember {
        mutableStateOf(
            if (initialGoal != null && initialGoal.targetAmount.subunits > 0) {
                if (initialGoal.targetAmount.subunits % 100 == 0L) {
                    (initialGoal.targetAmount.subunits / 100).toString()
                } else {
                    String.format(java.util.Locale.US, "%.2f", initialGoal.targetAmount.subunits / 100.0)
                }
            } else ""
        )
    }
    var amountError by remember { mutableStateOf<String?>(null) }
    var selectedColor by remember { mutableStateOf(initialGoal?.colorHex ?: AVAILABLE_COLORS[0]) }

    val isEditing = initialGoal != null

    AlertDialog(
        onDismissRequest = onDismiss,
        title = {
            Text(
                text = if (isEditing) stringResource(R.string.goal_edit_title) else stringResource(R.string.goal_create_title),
                style = MaterialTheme.typography.headlineSmall,
                fontWeight = FontWeight.Bold
            )
        },
        text = {
            Column(
                modifier = Modifier.fillMaxWidth()
            ) {
                OutlinedTextField(
                    value = name,
                    onValueChange = {
                        name = it
                        nameError = null
                    },
                    label = { Text(stringResource(R.string.goal_name_label)) },
                    singleLine = true,
                    keyboardOptions = KeyboardOptions(capitalization = KeyboardCapitalization.Words),
                    isError = nameError != null,
                    supportingText = nameError?.let { { Text(it) } },
                    modifier = Modifier.fillMaxWidth(),
                    shape = RoundedCornerShape(14.dp)
                )

                Spacer(modifier = Modifier.height(12.dp))

                OutlinedTextField(
                    value = targetAmountText,
                    onValueChange = { input ->
                        if (input.isEmpty() || input.matches(Regex("^\\d*(\\.\\d{0,2})?$"))) {
                            targetAmountText = input
                            amountError = null
                        }
                    },
                    label = { Text(stringResource(R.string.goal_target_amount_label)) },
                    prefix = { Text(currency.symbol) },
                    singleLine = true,
                    keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Decimal),
                    isError = amountError != null,
                    supportingText = amountError?.let { { Text(it) } },
                    modifier = Modifier.fillMaxWidth(),
                    shape = RoundedCornerShape(14.dp)
                )

                Spacer(modifier = Modifier.height(16.dp))

                Text(
                    text = stringResource(R.string.goal_color_theme),
                    style = MaterialTheme.typography.labelMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )

                Spacer(modifier = Modifier.height(8.dp))

                LazyRow(
                    horizontalArrangement = Arrangement.spacedBy(10.dp),
                    modifier = Modifier.fillMaxWidth()
                ) {
                    items(AVAILABLE_COLORS) { hex ->
                        val color = Color(android.graphics.Color.parseColor(hex))
                        val isSelected = selectedColor.equals(hex, ignoreCase = true)

                        Box(
                            modifier = Modifier
                                .size(36.dp)
                                .clip(CircleShape)
                                .background(color)
                                .clickable { selectedColor = hex }
                                .then(
                                    if (isSelected) {
                                        Modifier.border(3.dp, MaterialTheme.colorScheme.onSurface, CircleShape)
                                    } else Modifier
                                )
                        )
                    }
                }
            }
        },
        confirmButton = {
            Button(
                onClick = {
                    if (name.trim().isEmpty()) {
                        nameError = "Goal name cannot be empty"
                        return@Button
                    }
                    val amount = targetAmountText.toDoubleOrNull()
                    if (amount == null || amount <= 0.0) {
                        amountError = "Please enter a valid target amount greater than 0"
                        return@Button
                    }
                    if (amount > 1_000_000_000_000.0) {
                        amountError = "Target amount exceeds maximum limit"
                        return@Button
                    }

                    val amountObj = com.vinaynalavade.expensetracker.core.model.Amount.fromSubunits((amount * 100).toLong())

                    val goalToSave = initialGoal?.copy(
                        name = name.trim(),
                        targetAmount = amountObj,
                        colorHex = selectedColor
                    ) ?: SavingsGoal(
                        name = name.trim(),
                        targetAmount = amountObj,
                        colorHex = selectedColor
                    )

                    onSave(goalToSave)
                }
            ) {
                Text(stringResource(R.string.save))
            }
        },
        dismissButton = {
            TextButton(onClick = onDismiss) {
                Text(stringResource(R.string.cancel))
            }
        }
    )
}
