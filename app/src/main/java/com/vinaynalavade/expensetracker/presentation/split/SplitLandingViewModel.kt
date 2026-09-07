package com.vinaynalavade.expensetracker.presentation.split

import androidx.lifecycle.ViewModel
import androidx.lifecycle.ViewModelProvider
import androidx.lifecycle.viewModelScope
import com.vinaynalavade.expensetracker.core.model.Amount
import com.vinaynalavade.expensetracker.core.model.Currency
import com.vinaynalavade.expensetracker.domain.model.SplitExpense
import com.vinaynalavade.expensetracker.domain.usecase.GetSplitExpensesUseCase
import com.vinaynalavade.expensetracker.domain.usecase.GetUserPreferencesUseCase
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.launchIn
import kotlinx.coroutines.flow.onEach

data class SplitLandingUiState(
    val splitExpenses: List<SplitExpense> = emptyList(),
    val totalToCollect: Amount = Amount.ZERO,
    val totalCollected: Amount = Amount.ZERO,
    val currency: Currency = Currency.DEFAULT,
    val isLoading: Boolean = true
)

class SplitLandingViewModel(
    private val getSplitExpensesUseCase: GetSplitExpensesUseCase,
    private val getUserPreferencesUseCase: GetUserPreferencesUseCase
) : ViewModel() {

    private val _uiState = MutableStateFlow(SplitLandingUiState())
    val uiState: StateFlow<SplitLandingUiState> = _uiState.asStateFlow()

    init {
        loadData()
    }

    private fun loadData() {
        combine(
            getSplitExpensesUseCase(),
            getUserPreferencesUseCase()
        ) { expenses, prefs ->
            val toCollectSum = expenses.sumOf { it.toCollectAmount.subunits }
            val collectedSum = expenses.sumOf { it.collectedAmount.subunits }

            SplitLandingUiState(
                splitExpenses = expenses,
                totalToCollect = Amount(toCollectSum),
                totalCollected = Amount(collectedSum),
                currency = prefs.currency,
                isLoading = false
            )
        }.onEach { state ->
            _uiState.value = state
        }.launchIn(viewModelScope)
    }

    class Factory(
        private val getSplitExpensesUseCase: GetSplitExpensesUseCase,
        private val getUserPreferencesUseCase: GetUserPreferencesUseCase
    ) : ViewModelProvider.Factory {
        @Suppress("UNCHECKED_CAST")
        override fun <T : ViewModel> create(modelClass: Class<T>): T {
            return SplitLandingViewModel(
                getSplitExpensesUseCase,
                getUserPreferencesUseCase
            ) as T
        }
    }
}
