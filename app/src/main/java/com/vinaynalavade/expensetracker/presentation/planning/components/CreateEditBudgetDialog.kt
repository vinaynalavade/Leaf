package com.vinaynalavade.expensetracker.presentation.planning.components

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.FilterChip
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
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp
import com.vinaynalavade.expensetracker.R
import com.vinaynalavade.expensetracker.core.model.Currency
import com.vinaynalavade.expensetracker.domain.model.Budget
import com.vinaynalavade.expensetracker.domain.model.Category

@Composable
fun CreateEditBudgetDialog(
    initialBudget: Budget? = null,
    categories: List<Category>,
    existingCategoryIdsWithBudget: Set<Long>,
    currency: Currency,
    onDismiss: () -> Unit,
    onSave: (Budget) -> Unit
) {
    var selectedCategoryId by remember { mutableStateOf<Long?>(initialBudget?.categoryId) }
    var amountText by remember {
        mutableStateOf(
            if (initialBudget != null && initialBudget.amount.subunits > 0) {
                if (initialBudget.amount.subunits % 100 == 0L) {
                    (initialBudget.amount.subunits / 100).toString()
                } else {
                    String.format(java.util.Locale.US, "%.2f", initialBudget.amount.subunits / 100.0)
                }
            } else ""
        )
    }
    var amountError by remember { mutableStateOf<String?>(null) }

    val isEditing = initialBudget != null

    AlertDialog(
        onDismissRequest = onDismiss,
        title = {
            Text(
                text = if (isEditing) stringResource(R.string.budget_edit_title) else stringResource(R.string.budget_create_title),
                style = MaterialTheme.typography.headlineSmall,
                fontWeight = FontWeight.Bold
            )
        },
        text = {
            Column(
                modifier = Modifier.fillMaxWidth()
            ) {
                if (!isEditing) {
                    Text(
                        text = stringResource(R.string.budget_select_scope),
                        style = MaterialTheme.typography.labelMedium,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )

                    Spacer(modifier = Modifier.height(8.dp))

                    LazyRow(
                        horizontalArrangement = Arrangement.spacedBy(8.dp),
                        modifier = Modifier.fillMaxWidth()
                    ) {
                        item {
                            FilterChip(
                                selected = selectedCategoryId == null,
                                onClick = { selectedCategoryId = null },
                                label = { Text(stringResource(R.string.budget_overall)) }
                            )
                        }

                        items(categories) { category ->
                            val alreadyHasBudget = existingCategoryIdsWithBudget.contains(category.id)
                            FilterChip(
                                selected = selectedCategoryId == category.id,
                                onClick = { selectedCategoryId = category.id },
                                enabled = !alreadyHasBudget || selectedCategoryId == category.id,
                                label = { Text(category.name) }
                            )
                        }
                    }

                    Spacer(modifier = Modifier.height(16.dp))
                }

                OutlinedTextField(
                    value = amountText,
                    onValueChange = { input ->
                        if (input.isEmpty() || input.matches(Regex("^\\d*(\\.\\d{0,2})?$"))) {
                            amountText = input
                            amountError = null
                        }
                    },
                    label = { Text(stringResource(R.string.budget_monthly_limit)) },
                    prefix = { Text(currency.symbol) },
                    singleLine = true,
                    keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Decimal),
                    isError = amountError != null,
                    supportingText = amountError?.let { { Text(it) } },
                    modifier = Modifier.fillMaxWidth(),
                    shape = RoundedCornerShape(14.dp)
                )
            }
        },
        confirmButton = {
            Button(
                onClick = {
                    val amount = amountText.toDoubleOrNull()
                    if (amount == null || amount <= 0.0) {
                        amountError = "Please enter a valid amount greater than 0"
                        return@Button
                    }
                    if (amount > 1_000_000_000_000.0) {
                        amountError = "Amount exceeds maximum supported value"
                        return@Button
                    }

                    val cal = java.util.Calendar.getInstance()
                    val year = initialBudget?.year ?: cal.get(java.util.Calendar.YEAR)
                    val month = initialBudget?.month ?: (cal.get(java.util.Calendar.MONTH) + 1)
                    val amountObj = com.vinaynalavade.expensetracker.core.model.Amount.fromSubunits((amount * 100).toLong())

                    val budgetToSave = initialBudget?.copy(
                        categoryId = selectedCategoryId,
                        amount = amountObj,
                        month = month,
                        year = year
                    ) ?: Budget(
                        categoryId = selectedCategoryId,
                        amount = amountObj,
                        month = month,
                        year = year
                    )

                    onSave(budgetToSave)
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
