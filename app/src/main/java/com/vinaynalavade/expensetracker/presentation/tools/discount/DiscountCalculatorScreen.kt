package com.vinaynalavade.expensetracker.presentation.tools.discount

import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
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

@Composable
fun DiscountCalculatorScreen(
    currency: Currency,
    onNavigateBack: () -> Unit,
    modifier: Modifier = Modifier
) {
    var originalPriceText by remember { mutableStateOf("2500") }
    var discountPercentText by remember { mutableStateOf("20") }

    val originalPrice = originalPriceText.toDoubleOrNull() ?: 0.0
    val discountPercent = discountPercentText.toDoubleOrNull() ?: 0.0

    val result = FinancialCalculatorEngine.calculateDiscount(originalPrice, discountPercent)

    CalculatorLayout(
        title = stringResource(R.string.calculator_discount_title),
        onNavigateBack = onNavigateBack,
        resultTitle = "Final Discounted Price",
        resultAmount = result.finalPrice,
        currency = currency,
        breakdownContent = {
            BreakdownRow(label = "Original Price", amount = result.originalPrice, currency = currency)
            BreakdownRow(label = "Discount Savings (${String.format("%.1f", result.discountPercent)}%)", amount = result.discountAmount, currency = currency, overrideColor = Color(0xFF10B981))
            BreakdownRow(label = "You Pay", amount = result.finalPrice, currency = currency, overrideColor = MaterialTheme.colorScheme.primary)
        },
        inputsContent = {
            OutlinedTextField(
                value = originalPriceText,
                onValueChange = { input ->
                    if (input.isEmpty() || input.matches(Regex("^\\d*(\\.\\d{0,2})?$"))) {
                        originalPriceText = input
                    }
                },
                label = { Text("Original Price") },
                prefix = { Text(currency.symbol) },
                singleLine = true,
                keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Decimal),
                modifier = Modifier.fillMaxWidth(),
                shape = RoundedCornerShape(14.dp)
            )

            OutlinedTextField(
                value = discountPercentText,
                onValueChange = { input ->
                    if (input.isEmpty() || input.matches(Regex("^\\d*(\\.\\d{0,2})?$"))) {
                        discountPercentText = input
                    }
                },
                label = { Text("Discount Percentage") },
                suffix = { Text("%") },
                singleLine = true,
                keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Decimal),
                modifier = Modifier.fillMaxWidth(),
                shape = RoundedCornerShape(14.dp)
            )
        },
        modifier = modifier
    )
}
