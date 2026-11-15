package com.vinaynalavade.expensetracker.presentation.dashboard

import androidx.lifecycle.ViewModel
import androidx.lifecycle.ViewModelProvider
import androidx.lifecycle.viewModelScope
import com.vinaynalavade.expensetracker.domain.model.BalanceDisplayMode
import com.vinaynalavade.expensetracker.domain.model.BudgetProgress
import com.vinaynalavade.expensetracker.domain.model.CategoryAnalysisResult
import com.vinaynalavade.expensetracker.domain.model.FinancialSummary
import com.vinaynalavade.expensetracker.domain.model.SavingsGoal
import com.vinaynalavade.expensetracker.domain.model.SplitExpense
import com.vinaynalavade.expensetracker.domain.model.TransactionType
import com.vinaynalavade.expensetracker.domain.repository.SplitRepository
import com.vinaynalavade.expensetracker.domain.repository.UserPreferencesRepository
import com.vinaynalavade.expensetracker.domain.usecase.GetBudgetProgressUseCase
import com.vinaynalavade.expensetracker.domain.usecase.GetCategoryAnalysisUseCase
import com.vinaynalavade.expensetracker.domain.usecase.GetFinancialSummaryUseCase
import com.vinaynalavade.expensetracker.domain.usecase.GetSavingsGoalsUseCase
import com.vinaynalavade.expensetracker.domain.model.UpcomingPaymentItem
import com.vinaynalavade.expensetracker.domain.usecase.GetUpcomingPaymentsUseCase
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.catch
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.flatMapLatest
import kotlinx.coroutines.flow.flowOf
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch
import com.vinaynalavade.expensetracker.domain.model.Transaction
import com.vinaynalavade.expensetracker.domain.usecase.GetTransactionsUseCase
import java.time.YearMonth

data class DashboardUiState(
    val summary: FinancialSummary = FinancialSummary.EMPTY,
    val selectedMonth: YearMonth = YearMonth.now(),
    val categoryAnalysisType: TransactionType = TransactionType.EXPENSE,
    val categoryAnalysis: CategoryAnalysisResult? = null,
    val featuredBudget: BudgetProgress? = null,
    val topActiveGoal: SavingsGoal? = null,
    val unsettledSplits: List<SplitExpense> = emptyList(),
    val upcomingPayments: List<UpcomingPaymentItem> = emptyList(),
    val recentTransactions: List<Transaction> = emptyList(),
    val cashBalance: com.vinaynalavade.expensetracker.core.model.Amount? = null,
    val accountBalance: com.vinaynalavade.expensetracker.core.model.Amount? = null,
    val isBalanceVisible: Boolean = true,
    val balanceDisplayMode: BalanceDisplayMode = BalanceDisplayMode.COMBINED,
    val isLoading: Boolean = false,
    val error: String? = null
) {
    val displayedBalance: com.vinaynalavade.expensetracker.core.model.Amount
        get() = when (balanceDisplayMode) {
            BalanceDisplayMode.COMBINED -> summary.currentBalance
            BalanceDisplayMode.ACCOUNT -> accountBalance ?: com.vinaynalavade.expensetracker.core.model.Amount.ZERO
            BalanceDisplayMode.CASH -> cashBalance ?: com.vinaynalavade.expensetracker.core.model.Amount.ZERO
        }
}

@OptIn(ExperimentalCoroutinesApi::class)
class DashboardViewModel(
    getFinancialSummaryUseCase: GetFinancialSummaryUseCase,
    getCategoryAnalysisUseCase: GetCategoryAnalysisUseCase,
    getBudgetProgressUseCase: GetBudgetProgressUseCase,
    getSavingsGoalsUseCase: GetSavingsGoalsUseCase,
    splitRepository: SplitRepository,
    private val userPreferencesRepository: UserPreferencesRepository,
    getUpcomingPaymentsUseCase: GetUpcomingPaymentsUseCase? = null,
    getTransactionsUseCase: GetTransactionsUseCase? = null,
    private val onWidgetRefresh: (() -> Unit)? = null
) : ViewModel() {

    private val _selectedMonth = MutableStateFlow(YearMonth.now())
    val selectedMonth: StateFlow<YearMonth> = _selectedMonth

    private val _categoryAnalysisType = MutableStateFlow(TransactionType.EXPENSE)
    val categoryAnalysisType: StateFlow<TransactionType> = _categoryAnalysisType

    val uiState: StateFlow<DashboardUiState> = combine(
        _selectedMonth,
        _categoryAnalysisType
    ) { month, type ->
        month to type
    }.flatMapLatest { (month, type) ->
        val upcomingFlow = getUpcomingPaymentsUseCase?.invoke(daysAhead = 14) ?: flowOf(emptyList())
        val recentTxFlow = getTransactionsUseCase?.getRecent(limit = 4) ?: flowOf(emptyList())

        val baseDataFlow = combine(
            getFinancialSummaryUseCase(),
            getCategoryAnalysisUseCase(month, type),
            getBudgetProgressUseCase(month),
            getSavingsGoalsUseCase.getActiveGoals(),
            splitRepository.getAllSplitExpenses()
        ) { summary, analysis, budgets, goals, splits ->
            DashboardData(summary, analysis, budgets, goals, splits, emptyList(), emptyList())
        }

        val ledgersFlow = getFinancialSummaryUseCase.executeForLedgers()

        val enrichedDataFlow = combine(baseDataFlow, upcomingFlow, recentTxFlow, ledgersFlow) { base, upcoming, recent, ledgers ->
            base.copy(upcoming = upcoming, recent = recent, ledgers = ledgers)
        }

        combine(
            enrichedDataFlow,
            userPreferencesRepository.getUserPreferences()
        ) { data, prefs ->
            // Deterministic budget selection: Overall monthly budget -> Highest spend category budget -> null
            val featuredBudget = data.budgets.find { it.budget.categoryId == null }
                ?: data.budgets.maxByOrNull { it.usedAmount.subunits }

            // Top active savings goal: first active uncompleted goal, or active completed goal
            val topGoal = data.goals
                .sortedWith(compareBy<SavingsGoal> { it.isCompleted }.thenByDescending { it.progressPercentage })
                .firstOrNull()

            val unsettledSplits = data.splits.filter { it.hasUnsettledForUser }

            DashboardUiState(
                summary = data.summary,
                selectedMonth = month,
                categoryAnalysisType = type,
                categoryAnalysis = data.analysis,
                featuredBudget = featuredBudget,
                topActiveGoal = topGoal,
                unsettledSplits = unsettledSplits,
                upcomingPayments = data.upcoming,
                recentTransactions = data.recent,
                cashBalance = data.ledgers?.first,
                accountBalance = data.ledgers?.second,
                isBalanceVisible = prefs.isBalanceVisible,
                balanceDisplayMode = prefs.balanceDisplayMode,
                isLoading = false
            )
        }
    }.catch { e ->
        emit(DashboardUiState(isLoading = false, error = e.message ?: "Failed to load dashboard"))
    }.stateIn(
        scope = viewModelScope,
        started = SharingStarted.WhileSubscribed(5000),
        initialValue = DashboardUiState(isLoading = false)
    )

    fun toggleBalanceVisibility() {
        viewModelScope.launch {
            val current = uiState.value.isBalanceVisible
            userPreferencesRepository.setBalanceVisible(!current)
            onWidgetRefresh?.invoke()
        }
    }

    fun setBalanceDisplayMode(mode: BalanceDisplayMode) {
        viewModelScope.launch {
            userPreferencesRepository.setBalanceDisplayMode(mode)
            onWidgetRefresh?.invoke()
        }
    }

    fun onCategoryAnalysisTypeChange(type: TransactionType) {
        _categoryAnalysisType.value = type
    }

    fun onPreviousMonth() {
        _selectedMonth.value = _selectedMonth.value.minusMonths(1)
    }

    fun onNextMonth() {
        _selectedMonth.value = _selectedMonth.value.plusMonths(1)
    }

    fun onCurrentMonth() {
        _selectedMonth.value = YearMonth.now()
    }

    class Factory(
        private val getFinancialSummaryUseCase: GetFinancialSummaryUseCase,
        private val getCategoryAnalysisUseCase: GetCategoryAnalysisUseCase,
        private val getBudgetProgressUseCase: GetBudgetProgressUseCase,
        private val getSavingsGoalsUseCase: GetSavingsGoalsUseCase,
        private val splitRepository: SplitRepository,
        private val userPreferencesRepository: UserPreferencesRepository,
        private val getUpcomingPaymentsUseCase: GetUpcomingPaymentsUseCase? = null,
        private val getTransactionsUseCase: GetTransactionsUseCase? = null,
        private val onWidgetRefresh: (() -> Unit)? = null
    ) : ViewModelProvider.Factory {
        @Suppress("UNCHECKED_CAST")
        override fun <T : ViewModel> create(modelClass: Class<T>): T {
            return DashboardViewModel(
                getFinancialSummaryUseCase,
                getCategoryAnalysisUseCase,
                getBudgetProgressUseCase,
                getSavingsGoalsUseCase,
                splitRepository,
                userPreferencesRepository,
                getUpcomingPaymentsUseCase,
                getTransactionsUseCase,
                onWidgetRefresh
            ) as T
        }
    }
}

private data class DashboardData(
    val summary: FinancialSummary,
    val analysis: CategoryAnalysisResult,
    val budgets: List<BudgetProgress>,
    val goals: List<SavingsGoal>,
    val splits: List<SplitExpense>,
    val upcoming: List<UpcomingPaymentItem>,
    val recent: List<Transaction>,
    val ledgers: Pair<com.vinaynalavade.expensetracker.core.model.Amount, com.vinaynalavade.expensetracker.core.model.Amount>? = null
)

