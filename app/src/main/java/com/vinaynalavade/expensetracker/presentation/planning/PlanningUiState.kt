package com.vinaynalavade.expensetracker.presentation.planning

import com.vinaynalavade.expensetracker.core.model.Currency
import com.vinaynalavade.expensetracker.domain.model.BudgetProgress
import com.vinaynalavade.expensetracker.domain.model.Category
import com.vinaynalavade.expensetracker.domain.model.SavingsGoal

enum class PlanningTab {
    BUDGETS,
    SAVINGS
}

data class PlanningUiState(
    val selectedTab: PlanningTab = PlanningTab.BUDGETS,
    val selectedYear: Int = java.time.YearMonth.now().year,
    val selectedMonth: Int = java.time.YearMonth.now().monthValue,
    val budgetProgressList: List<BudgetProgress> = emptyList(),
    val overallBudget: BudgetProgress? = null,
    val categoryBudgets: List<BudgetProgress> = emptyList(),
    val savingsGoals: List<SavingsGoal> = emptyList(),
    val activeSavingsGoals: List<SavingsGoal> = emptyList(),
    val archivedSavingsGoals: List<SavingsGoal> = emptyList(),
    val categories: List<Category> = emptyList(),
    val currency: Currency = Currency.DEFAULT,
    val isLoading: Boolean = true,
    val errorMessage: String? = null
)
