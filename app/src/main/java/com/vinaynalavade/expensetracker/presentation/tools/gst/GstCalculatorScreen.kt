package com.vinaynalavade.expensetracker.presentation.tools.gst

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material3.FilterChip
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.SegmentedButton
import androidx.compose.material3.SegmentedButtonDefaults
import androidx.compose.material3.SingleChoiceSegmentedButtonRow
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableDoubleStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp
import com.vinaynalavade.expensetracker.R
import com.vinaynalavade.expensetracker.core.calculator.FinancialCalculatorEngine
import com.vinaynalavade.expensetracker.core.model.Currency
import com.vinaynalavade.expensetracker.presentation.tools.components.BreakdownRow
import com.vinaynalavade.expensetracker.presentation.tools.components.CalculatorLayout

private val STANDARD_GST_RATES = listOf(5.0, 12.0, 18.0, 28.0)

@Composable
fun GstCalculatorScreen(
    currency: Currency,
    onNavigateBack: () -> Unit,
    modifier: Modifier = Modifier
) {
    var amountText by remember { mutableStateOf("1000") }
    var isInclusive by remember { mutableStateOf(false) }
    var selectedGstRate by remember { mutableDoubleStateOf(18.0) }

    val amount = amountText.toDoubleOrNull() ?: 0.0
    val result = FinancialCalculatorEngine.calculateGst(amount, selectedGstRate, isInclusive)

    CalculatorLayout(
        title = stringResource(R.string.calculator_gst_title),
        onNavigateBack = onNavigateBack,
        resultTitle = if (isInclusive) "Total Amount (Inclusive of GST)" else "Total Amount with GST",
        resultAmount = result.totalAmount,
        currency = currency,
        breakdownContent = {
            BreakdownRow(label = "Net Price", amount = result.netAmount, currency = currency)
            BreakdownRow(label = "CGST (${String.format("%.1f", selectedGstRate / 2)}%)", amount = result.cgstAmount, currency = currency, overrideColor = Color(0xFFF59E0B))
            BreakdownRow(label = "SGST (${String.format("%.1f", selectedGstRate / 2)}%)", amount = result.sgstAmount, currency = currency, overrideColor = Color(0xFFF59E0B))
            BreakdownRow(label = "Total GST Tax", amount = result.gstAmount, currency = currency, overrideColor = Color(0xFFEF4444))
            BreakdownRow(label = "Gross Total", amount = result.totalAmount, currency = currency, overrideColor = MaterialTheme.colorScheme.primary)
        },
        inputsContent = {
            SingleChoiceSegmentedButtonRow(modifier = Modifier.fillMaxWidth()) {
                SegmentedButton(
                    selected = !isInclusive,
                    onClick = { isInclusive = false },
                    shape = SegmentedButtonDefaults.itemShape(index = 0, count = 2)
                ) {
                    Text("Exclusive")
                }
                SegmentedButton(
                    selected = isInclusive,
                    onClick = { isInclusive = true },
                    shape = SegmentedButtonDefaults.itemShape(index = 1, count = 2)
                ) {
                    Text("Inclusive")
                }
            }

            Spacer(modifier = Modifier.height(6.dp))

            OutlinedTextField(
                value = amountText,
                onValueChange = { input ->
                    if (input.isEmpty() || input.matches(Regex("^\\d*(\\.\\d{0,2})?$"))) {
                        amountText = input
                    }
                },
                label = { Text(if (isInclusive) "Total Amount (incl. GST)" else "Net Amount (excl. GST)") },
                prefix = { Text(currency.symbol) },
                singleLine = true,
                keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Decimal),
                modifier = Modifier.fillMaxWidth(),
                shape = RoundedCornerShape(14.dp)
            )

            Spacer(modifier = Modifier.height(4.dp))
            Text(
                text = "Select GST Rate",
                style = MaterialTheme.typography.labelMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )

            LazyRow(
                horizontalArrangement = Arrangement.spacedBy(8.dp),
                modifier = Modifier.fillMaxWidth()
            ) {
                items(STANDARD_GST_RATES) { rate ->
                    FilterChip(
                        selected = selectedGstRate == rate,
                        onClick = { selectedGstRate = rate },
                        label = { Text("${rate.toInt()}%") }
                    )
                }
            }
        },
        modifier = modifier
    )
}
