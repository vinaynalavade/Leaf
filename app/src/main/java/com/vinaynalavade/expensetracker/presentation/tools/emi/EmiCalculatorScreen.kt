package com.vinaynalavade.expensetracker.presentation.tools.emi

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
fun EmiCalculatorScreen(
    currency: Currency,
    onNavigateBack: () -> Unit,
    modifier: Modifier = Modifier
) {
    var principalText by remember { mutableStateOf("100000") }
    var rateText by remember { mutableStateOf("10.5") }
    var tenureMonthsText by remember { mutableStateOf("12") }

    val principal = principalText.toDoubleOrNull() ?: 0.0
    val rate = rateText.toDoubleOrNull() ?: 0.0
    val tenureMonths = tenureMonthsText.toIntOrNull() ?: 0

    val result = FinancialCalculatorEngine.calculateEmi(principal, rate, tenureMonths)

    CalculatorLayout(
        title = stringResource(R.string.calculator_emi_title),
        onNavigateBack = onNavigateBack,
        resultTitle = "Monthly EMI",
        resultAmount = result.monthlyEmi,
        currency = currency,
        breakdownContent = {
            BreakdownRow(label = "Principal Amount", amount = result.totalPrincipal, currency = currency)
            BreakdownRow(label = "Total Interest", amount = result.totalInterest, currency = currency, overrideColor = Color(0xFFEF4444))
            BreakdownRow(label = "Total Amount Payable", amount = result.totalPayment, currency = currency, overrideColor = MaterialTheme.colorScheme.primary)
        },
        inputsContent = {
            OutlinedTextField(
                value = principalText,
                onValueChange = { input ->
                    if (input.isEmpty() || input.matches(Regex("^\\d*(\\.\\d{0,2})?$"))) {
                        principalText = input
                    }
                },
                label = { Text("Loan Amount") },
                prefix = { Text(currency.symbol) },
                singleLine = true,
                keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Decimal),
                modifier = Modifier.fillMaxWidth(),
                shape = RoundedCornerShape(14.dp)
            )

            OutlinedTextField(
                value = rateText,
                onValueChange = { input ->
                    if (input.isEmpty() || input.matches(Regex("^\\d*(\\.\\d{0,2})?$"))) {
                        rateText = input
                    }
                },
                label = { Text("Interest Rate (% per annum)") },
                suffix = { Text("%") },
                singleLine = true,
                keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Decimal),
                modifier = Modifier.fillMaxWidth(),
                shape = RoundedCornerShape(14.dp)
            )

            OutlinedTextField(
                value = tenureMonthsText,
                onValueChange = { input ->
                    if (input.isEmpty() || input.matches(Regex("^\\d*$"))) {
                        tenureMonthsText = input
                    }
                },
                label = { Text("Tenure (Months)") },
                suffix = { Text("months") },
                singleLine = true,
                keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number),
                modifier = Modifier.fillMaxWidth(),
                shape = RoundedCornerShape(14.dp)
            )
        },
        modifier = modifier
    )
}
