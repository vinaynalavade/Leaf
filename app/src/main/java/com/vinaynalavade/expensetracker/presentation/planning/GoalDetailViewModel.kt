package com.vinaynalavade.expensetracker.presentation.planning

import androidx.lifecycle.ViewModel
import androidx.lifecycle.ViewModelProvider
import androidx.lifecycle.viewModelScope
import com.vinaynalavade.expensetracker.core.model.Currency
import com.vinaynalavade.expensetracker.domain.model.SavingsGoal
import com.vinaynalavade.expensetracker.domain.model.SavingsGoalContribution
import com.vinaynalavade.expensetracker.domain.usecase.DeleteSavingsGoalContributionUseCase
import com.vinaynalavade.expensetracker.domain.usecase.DeleteSavingsGoalUseCase
import com.vinaynalavade.expensetracker.domain.usecase.GetSavingsGoalByIdUseCase
import com.vinaynalavade.expensetracker.domain.usecase.GetUserPreferencesUseCase
import com.vinaynalavade.expensetracker.domain.usecase.SaveSavingsGoalContributionUseCase
import com.vinaynalavade.expensetracker.domain.usecase.SetSavingsGoalArchivedUseCase
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.launchIn
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch

data class GoalDetailUiState(
    val goal: SavingsGoal? = null,
    val currency: Currency = Currency.DEFAULT,
    val isLoading: Boolean = true,
    val isDeleted: Boolean = false,
    val errorMessage: String? = null
)

class GoalDetailViewModel(
    private val goalId: Long,
    private val getSavingsGoalByIdUseCase: GetSavingsGoalByIdUseCase,
    private val saveSavingsGoalContributionUseCase: SaveSavingsGoalContributionUseCase,
    private val deleteSavingsGoalContributionUseCase: DeleteSavingsGoalContributionUseCase,
    private val setSavingsGoalArchivedUseCase: SetSavingsGoalArchivedUseCase,
    private val deleteSavingsGoalUseCase: DeleteSavingsGoalUseCase,
    private val getUserPreferencesUseCase: GetUserPreferencesUseCase
) : ViewModel() {

    private val _uiState = MutableStateFlow(GoalDetailUiState())
    val uiState: StateFlow<GoalDetailUiState> = _uiState.asStateFlow()

    init {
        loadGoal()
    }

    private fun loadGoal() {
        combine(
            getSavingsGoalByIdUseCase(goalId),
            getUserPreferencesUseCase()
        ) { goal, prefs ->
            _uiState.update {
                it.copy(
                    goal = goal,
                    currency = prefs.currency,
                    isLoading = false
                )
            }
        }.launchIn(viewModelScope)
    }

    fun addContribution(amount: Double, note: String?) {
        viewModelScope.launch {
            try {
                saveSavingsGoalContributionUseCase(
                    SavingsGoalContribution(
                        goalId = goalId,
                        amount = com.vinaynalavade.expensetracker.core.model.Amount.fromSubunits((amount * 100).toLong()),
                        note = note,
                        timestamp = System.currentTimeMillis()
                    )
                )
            } catch (e: Exception) {
                _uiState.update { it.copy(errorMessage = e.message) }
            }
        }
    }

    fun deleteContribution(contributionId: Long) {
        viewModelScope.launch {
            try {
                deleteSavingsGoalContributionUseCase(contributionId)
            } catch (e: Exception) {
                _uiState.update { it.copy(errorMessage = e.message) }
            }
        }
    }

    fun toggleArchived() {
        viewModelScope.launch {
            val currentGoal = _uiState.value.goal ?: return@launch
            try {
                setSavingsGoalArchivedUseCase(goalId, !currentGoal.isArchived)
            } catch (e: Exception) {
                _uiState.update { it.copy(errorMessage = e.message) }
            }
        }
    }

    fun deleteGoal() {
        viewModelScope.launch {
            try {
                deleteSavingsGoalUseCase(goalId)
                _uiState.update { it.copy(isDeleted = true) }
            } catch (e: Exception) {
                _uiState.update { it.copy(errorMessage = e.message) }
            }
        }
    }

    class Factory(
        private val goalId: Long,
        private val getSavingsGoalByIdUseCase: GetSavingsGoalByIdUseCase,
        private val saveSavingsGoalContributionUseCase: SaveSavingsGoalContributionUseCase,
        private val deleteSavingsGoalContributionUseCase: DeleteSavingsGoalContributionUseCase,
        private val setSavingsGoalArchivedUseCase: SetSavingsGoalArchivedUseCase,
        private val deleteSavingsGoalUseCase: DeleteSavingsGoalUseCase,
        private val getUserPreferencesUseCase: GetUserPreferencesUseCase
    ) : ViewModelProvider.Factory {
        @Suppress("UNCHECKED_CAST")
        override fun <T : ViewModel> create(modelClass: Class<T>): T {
            return GoalDetailViewModel(
                goalId,
                getSavingsGoalByIdUseCase,
                saveSavingsGoalContributionUseCase,
                deleteSavingsGoalContributionUseCase,
                setSavingsGoalArchivedUseCase,
                deleteSavingsGoalUseCase,
                getUserPreferencesUseCase
            ) as T
        }
    }
}
