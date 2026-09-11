package com.vinaynalavade.expensetracker.presentation.split

import androidx.lifecycle.ViewModel
import androidx.lifecycle.ViewModelProvider
import androidx.lifecycle.viewModelScope
import com.vinaynalavade.expensetracker.core.model.Amount
import com.vinaynalavade.expensetracker.core.model.Currency
import com.vinaynalavade.expensetracker.core.split.GroupBalanceSummary
import com.vinaynalavade.expensetracker.core.split.NetBalanceEngine
import com.vinaynalavade.expensetracker.domain.model.SplitExpense
import com.vinaynalavade.expensetracker.domain.model.SplitGroup
import com.vinaynalavade.expensetracker.domain.usecase.DeleteSplitGroupUseCase
import com.vinaynalavade.expensetracker.domain.usecase.GetGroupNetBalancesUseCase
import com.vinaynalavade.expensetracker.domain.usecase.GetSplitExpensesUseCase
import com.vinaynalavade.expensetracker.domain.usecase.GetSplitGroupsUseCase
import com.vinaynalavade.expensetracker.domain.usecase.GetUserPreferencesUseCase
import com.vinaynalavade.expensetracker.domain.usecase.SaveSplitGroupUseCase
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.launchIn
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch

enum class SplitTab {
    EXPENSES,
    GROUPS
}

data class SplitLandingUiState(
    val selectedTab: SplitTab = SplitTab.EXPENSES,
    val splitExpenses: List<SplitExpense> = emptyList(),
    val groups: List<SplitGroup> = emptyList(),
    val groupBalanceSummary: GroupBalanceSummary = GroupBalanceSummary(0, Amount.ZERO, Amount.ZERO, Amount.ZERO, emptyList()),
    val selectedGroupId: Long? = null,
    val totalToCollect: Amount = Amount.ZERO,
    val totalCollected: Amount = Amount.ZERO,
    val currency: Currency = Currency.DEFAULT,
    val isLoading: Boolean = true
)

class SplitLandingViewModel(
    private val getSplitExpensesUseCase: GetSplitExpensesUseCase,
    private val getSplitGroupsUseCase: GetSplitGroupsUseCase,
    private val saveSplitGroupUseCase: SaveSplitGroupUseCase,
    private val deleteSplitGroupUseCase: DeleteSplitGroupUseCase,
    private val getGroupNetBalancesUseCase: GetGroupNetBalancesUseCase,
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
            getSplitGroupsUseCase(),
            getGroupNetBalancesUseCase(),
            getUserPreferencesUseCase()
        ) { expenses, groups, summary, prefs ->
            val toCollectSum = expenses.sumOf { it.toCollectAmount.subunits }
            val collectedSum = expenses.sumOf { it.collectedAmount.subunits }

            _uiState.value.copy(
                splitExpenses = expenses,
                groups = groups,
                groupBalanceSummary = summary,
                totalToCollect = Amount(toCollectSum),
                totalCollected = Amount(collectedSum),
                currency = prefs.currency,
                isLoading = false
            )
        }.launchIn(viewModelScope)
    }

    fun selectTab(tab: SplitTab) {
        _uiState.update { it.copy(selectedTab = tab) }
    }

    fun selectGroupFilter(groupId: Long?) {
        _uiState.update { it.copy(selectedGroupId = groupId) }
    }

    fun saveGroup(group: SplitGroup) {
        viewModelScope.launch {
            saveSplitGroupUseCase(group)
        }
    }

    fun deleteGroup(groupId: Long) {
        viewModelScope.launch {
            deleteSplitGroupUseCase(groupId)
        }
    }

    class Factory(
        private val getSplitExpensesUseCase: GetSplitExpensesUseCase,
        private val getSplitGroupsUseCase: GetSplitGroupsUseCase,
        private val saveSplitGroupUseCase: SaveSplitGroupUseCase,
        private val deleteSplitGroupUseCase: DeleteSplitGroupUseCase,
        private val getGroupNetBalancesUseCase: GetGroupNetBalancesUseCase,
        private val getUserPreferencesUseCase: GetUserPreferencesUseCase
    ) : ViewModelProvider.Factory {
        @Suppress("UNCHECKED_CAST")
        override fun <T : ViewModel> create(modelClass: Class<T>): T {
            return SplitLandingViewModel(
                getSplitExpensesUseCase,
                getSplitGroupsUseCase,
                saveSplitGroupUseCase,
                deleteSplitGroupUseCase,
                getGroupNetBalancesUseCase,
                getUserPreferencesUseCase
            ) as T
        }
    }
}
