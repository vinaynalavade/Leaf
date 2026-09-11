package com.vinaynalavade.expensetracker.presentation.insights

import androidx.lifecycle.ViewModel
import androidx.lifecycle.ViewModelProvider
import androidx.lifecycle.viewModelScope
import com.vinaynalavade.expensetracker.domain.usecase.GetSpendingTrendsUseCase
import com.vinaynalavade.expensetracker.domain.usecase.GetUserPreferencesUseCase
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.flatMapLatest
import kotlinx.coroutines.flow.launchIn
import kotlinx.coroutines.flow.onEach
import kotlinx.coroutines.flow.update

@OptIn(ExperimentalCoroutinesApi::class)
class InsightsViewModel(
    private val getSpendingTrendsUseCase: GetSpendingTrendsUseCase,
    private val getUserPreferencesUseCase: GetUserPreferencesUseCase
) : ViewModel() {

    private val _monthsCount = MutableStateFlow(6)
    private val _uiState = MutableStateFlow(InsightsUiState())
    val uiState: StateFlow<InsightsUiState> = _uiState.asStateFlow()

    init {
        loadData()
    }

    private fun loadData() {
        _monthsCount.flatMapLatest { months ->
            combine(
                getSpendingTrendsUseCase(months),
                getUserPreferencesUseCase()
            ) { trendData, userPrefs ->
                _uiState.value.copy(
                    selectedMonthsCount = months,
                    trendData = trendData,
                    currency = userPrefs.currency,
                    isLoading = false
                )
            }
        }.onEach { state ->
            _uiState.value = state
        }.launchIn(viewModelScope)
    }

    fun selectTab(tab: InsightsTab) {
        _uiState.update { it.copy(selectedTab = tab) }
    }

    fun setMonthsCount(count: Int) {
        _monthsCount.value = count
    }

    class Factory(
        private val getSpendingTrendsUseCase: GetSpendingTrendsUseCase,
        private val getUserPreferencesUseCase: GetUserPreferencesUseCase
    ) : ViewModelProvider.Factory {
        @Suppress("UNCHECKED_CAST")
        override fun <T : ViewModel> create(modelClass: Class<T>): T {
            return InsightsViewModel(
                getSpendingTrendsUseCase,
                getUserPreferencesUseCase
            ) as T
        }
    }
}
