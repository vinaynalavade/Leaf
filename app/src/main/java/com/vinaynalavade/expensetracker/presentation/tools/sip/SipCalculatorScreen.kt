package com.vinaynalavade.expensetracker.presentation.tools.sip

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
fun SipCalculatorScreen(
    currency: Currency,
    onNavigateBack: () -> Unit,
    modifier: Modifier = Modifier
) {
    var monthlyInvestmentText by remember { mutableStateOf("5000") }
    var expectedReturnText by remember { mutableStateOf("12") }
    var tenureYearsText by remember { mutableStateOf("10") }

    val monthlyInvestment = monthlyInvestmentText.toDoubleOrNull() ?: 0.0
    val expectedReturn = expectedReturnText.toDoubleOrNull() ?: 0.0
    val tenureYears = tenureYearsText.toIntOrNull() ?: 0

    val result = FinancialCalculatorEngine.calculateSip(monthlyInvestment, expectedReturn, tenureYears)

    CalculatorLayout(
        title = stringResource(R.string.calculator_sip_title),
        onNavigateBack = onNavigateBack,
        resultTitle = "Expected Maturity Value",
        resultAmount = result.totalMaturity,
        currency = currency,
        breakdownContent = {
            BreakdownRow(label = "Total Amount Invested", amount = result.totalInvested, currency = currency)
            BreakdownRow(label = "Estimated Wealth Gain", amount = result.estimatedReturns, currency = currency, overrideColor = Color(0xFF10B981))
            BreakdownRow(label = "Total Maturity Amount", amount = result.totalMaturity, currency = currency, overrideColor = MaterialTheme.colorScheme.primary)
        },
        inputsContent = {
            OutlinedTextField(
                value = monthlyInvestmentText,
                onValueChange = { input ->
                    if (input.isEmpty() || input.matches(Regex("^\\d*(\\.\\d{0,2})?$"))) {
                        monthlyInvestmentText = input
                    }
                },
                label = { Text("Monthly Investment Amount") },
                prefix = { Text(currency.symbol) },
                singleLine = true,
                keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Decimal),
                modifier = Modifier.fillMaxWidth(),
                shape = RoundedCornerShape(14.dp)
            )

            OutlinedTextField(
                value = expectedReturnText,
                onValueChange = { input ->
                    if (input.isEmpty() || input.matches(Regex("^\\d*(\\.\\d{0,2})?$"))) {
                        expectedReturnText = input
                    }
                },
                label = { Text("Expected Annual Return (p.a.)") },
                suffix = { Text("%") },
                singleLine = true,
                keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Decimal),
                modifier = Modifier.fillMaxWidth(),
                shape = RoundedCornerShape(14.dp)
            )

            OutlinedTextField(
                value = tenureYearsText,
                onValueChange = { input ->
                    if (input.isEmpty() || input.matches(Regex("^\\d*$"))) {
                        tenureYearsText = input
                    }
                },
                label = { Text("Time Period (Years)") },
                suffix = { Text("yrs") },
                singleLine = true,
                keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number),
                modifier = Modifier.fillMaxWidth(),
                shape = RoundedCornerShape(14.dp)
            )
        },
        modifier = modifier
    )
}
