package com.vinaynalavade.expensetracker.presentation.planning

import androidx.lifecycle.ViewModel
import androidx.lifecycle.ViewModelProvider
import androidx.lifecycle.viewModelScope
import com.vinaynalavade.expensetracker.core.model.Amount
import com.vinaynalavade.expensetracker.domain.model.Budget
import com.vinaynalavade.expensetracker.domain.model.SavingsGoal
import com.vinaynalavade.expensetracker.domain.model.SavingsGoalContribution
import com.vinaynalavade.expensetracker.domain.usecase.DeleteBudgetUseCase
import com.vinaynalavade.expensetracker.domain.usecase.DeleteSavingsGoalContributionUseCase
import com.vinaynalavade.expensetracker.domain.usecase.DeleteSavingsGoalUseCase
import com.vinaynalavade.expensetracker.domain.usecase.GetBudgetProgressUseCase
import com.vinaynalavade.expensetracker.domain.usecase.GetCategoriesUseCase
import com.vinaynalavade.expensetracker.domain.usecase.GetSavingsGoalsUseCase
import com.vinaynalavade.expensetracker.domain.usecase.GetUserPreferencesUseCase
import com.vinaynalavade.expensetracker.domain.usecase.SaveBudgetUseCase
import com.vinaynalavade.expensetracker.domain.usecase.SaveSavingsGoalContributionUseCase
import com.vinaynalavade.expensetracker.domain.usecase.SaveSavingsGoalUseCase
import com.vinaynalavade.expensetracker.domain.usecase.SetSavingsGoalArchivedUseCase
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.flatMapLatest
import kotlinx.coroutines.flow.launchIn
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import java.time.YearMonth

@OptIn(ExperimentalCoroutinesApi::class)
class PlanningViewModel(
    private val getBudgetProgressUseCase: GetBudgetProgressUseCase,
    private val saveBudgetUseCase: SaveBudgetUseCase,
    private val deleteBudgetUseCase: DeleteBudgetUseCase,
    private val getSavingsGoalsUseCase: GetSavingsGoalsUseCase,
    private val saveSavingsGoalUseCase: SaveSavingsGoalUseCase,
    private val deleteSavingsGoalUseCase: DeleteSavingsGoalUseCase,
    private val setSavingsGoalArchivedUseCase: SetSavingsGoalArchivedUseCase,
    private val saveSavingsGoalContributionUseCase: SaveSavingsGoalContributionUseCase,
    private val deleteSavingsGoalContributionUseCase: DeleteSavingsGoalContributionUseCase,
    private val getCategoriesUseCase: GetCategoriesUseCase,
    private val getUserPreferencesUseCase: GetUserPreferencesUseCase
) : ViewModel() {

    private val _selectedYearMonth = MutableStateFlow(YearMonth.now())
    private val _uiState = MutableStateFlow(PlanningUiState())
    val uiState: StateFlow<PlanningUiState> = _uiState.asStateFlow()

    init {
        loadData()
    }

    private fun loadData() {
        _selectedYearMonth.flatMapLatest { ym ->
            combine(
                getBudgetProgressUseCase(ym),
                getSavingsGoalsUseCase.getAllGoals(),
                getCategoriesUseCase(),
                getUserPreferencesUseCase()
            ) { budgetProgressList, savingsGoals, categories, userPrefs ->
                val overall = budgetProgressList.find { it.budget.categoryId == null }
                val categoryBudgets = budgetProgressList.filter { it.budget.categoryId != null }
                val activeGoals = savingsGoals.filter { !it.isArchived }
                val archivedGoals = savingsGoals.filter { it.isArchived }

                _uiState.update { current ->
                    current.copy(
                        selectedYear = ym.year,
                        selectedMonth = ym.monthValue,
                        budgetProgressList = budgetProgressList,
                        overallBudget = overall,
                        categoryBudgets = categoryBudgets,
                        savingsGoals = savingsGoals,
                        activeSavingsGoals = activeGoals,
                        archivedSavingsGoals = archivedGoals,
                        categories = categories,
                        currency = userPrefs.currency,
                        isLoading = false
                    )
                }
            }
        }.launchIn(viewModelScope)
    }

    fun previousMonth() {
        _selectedYearMonth.update { it.minusMonths(1) }
    }

    fun nextMonth() {
        _selectedYearMonth.update { it.plusMonths(1) }
    }

    fun selectTab(tab: PlanningTab) {
        _uiState.update { it.copy(selectedTab = tab) }
    }

    fun saveBudget(budget: Budget) {
        viewModelScope.launch {
            try {
                saveBudgetUseCase(budget)
            } catch (e: Exception) {
                _uiState.update { it.copy(errorMessage = e.message) }
            }
        }
    }

    fun deleteBudget(id: Long) {
        viewModelScope.launch {
            try {
                deleteBudgetUseCase(id)
            } catch (e: Exception) {
                _uiState.update { it.copy(errorMessage = e.message) }
            }
        }
    }

    fun saveSavingsGoal(goal: SavingsGoal) {
        viewModelScope.launch {
            try {
                saveSavingsGoalUseCase(goal)
            } catch (e: Exception) {
                _uiState.update { it.copy(errorMessage = e.message) }
            }
        }
    }

    fun deleteSavingsGoal(id: Long) {
        viewModelScope.launch {
            try {
                deleteSavingsGoalUseCase(id)
            } catch (e: Exception) {
                _uiState.update { it.copy(errorMessage = e.message) }
            }
        }
    }

    fun setGoalArchived(id: Long, isArchived: Boolean) {
        viewModelScope.launch {
            try {
                setSavingsGoalArchivedUseCase(id, isArchived)
            } catch (e: Exception) {
                _uiState.update { it.copy(errorMessage = e.message) }
            }
        }
    }

    fun addContribution(goalId: Long, amount: Double, note: String?) {
        viewModelScope.launch {
            try {
                saveSavingsGoalContributionUseCase(
                    SavingsGoalContribution(
                        goalId = goalId,
                        amount = Amount.fromSubunits((amount * 100).toLong()),
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

    fun clearError() {
        _uiState.update { it.copy(errorMessage = null) }
    }

    class Factory(
        private val getBudgetProgressUseCase: GetBudgetProgressUseCase,
        private val saveBudgetUseCase: SaveBudgetUseCase,
        private val deleteBudgetUseCase: DeleteBudgetUseCase,
        private val getSavingsGoalsUseCase: GetSavingsGoalsUseCase,
        private val saveSavingsGoalUseCase: SaveSavingsGoalUseCase,
        private val deleteSavingsGoalUseCase: DeleteSavingsGoalUseCase,
        private val setSavingsGoalArchivedUseCase: SetSavingsGoalArchivedUseCase,
        private val saveSavingsGoalContributionUseCase: SaveSavingsGoalContributionUseCase,
        private val deleteSavingsGoalContributionUseCase: DeleteSavingsGoalContributionUseCase,
        private val getCategoriesUseCase: GetCategoriesUseCase,
        private val getUserPreferencesUseCase: GetUserPreferencesUseCase
    ) : ViewModelProvider.Factory {
        @Suppress("UNCHECKED_CAST")
        override fun <T : ViewModel> create(modelClass: Class<T>): T {
            return PlanningViewModel(
                getBudgetProgressUseCase,
                saveBudgetUseCase,
                deleteBudgetUseCase,
                getSavingsGoalsUseCase,
                saveSavingsGoalUseCase,
                deleteSavingsGoalUseCase,
                setSavingsGoalArchivedUseCase,
                saveSavingsGoalContributionUseCase,
                deleteSavingsGoalContributionUseCase,
                getCategoriesUseCase,
                getUserPreferencesUseCase
            ) as T
        }
    }
}
