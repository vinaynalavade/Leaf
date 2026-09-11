package com.vinaynalavade.expensetracker.presentation.tools.rd

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
fun RdCalculatorScreen(
    currency: Currency,
    onNavigateBack: () -> Unit,
    modifier: Modifier = Modifier
) {
    var monthlyDepositText by remember { mutableStateOf("2000") }
    var rateText by remember { mutableStateOf("7.0") }
    var tenureMonthsText by remember { mutableStateOf("12") }

    val monthlyDeposit = monthlyDepositText.toDoubleOrNull() ?: 0.0
    val rate = rateText.toDoubleOrNull() ?: 0.0
    val tenureMonths = tenureMonthsText.toIntOrNull() ?: 0

    val result = FinancialCalculatorEngine.calculateRd(monthlyDeposit, rate, tenureMonths)

    CalculatorLayout(
        title = stringResource(R.string.calculator_rd_title),
        onNavigateBack = onNavigateBack,
        resultTitle = "RD Maturity Value",
        resultAmount = result.maturityAmount,
        currency = currency,
        breakdownContent = {
            BreakdownRow(label = "Total Investment Deposited", amount = result.investedAmount, currency = currency)
            BreakdownRow(label = "Total Interest Earned", amount = result.totalInterest, currency = currency, overrideColor = Color(0xFF10B981))
            BreakdownRow(label = "Total Maturity Amount", amount = result.maturityAmount, currency = currency, overrideColor = MaterialTheme.colorScheme.primary)
        },
        inputsContent = {
            OutlinedTextField(
                value = monthlyDepositText,
                onValueChange = { input ->
                    if (input.isEmpty() || input.matches(Regex("^\\d*(\\.\\d{0,2})?$"))) {
                        monthlyDepositText = input
                    }
                },
                label = { Text("Monthly Deposit Amount") },
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
                label = { Text("Interest Rate (% p.a.)") },
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
