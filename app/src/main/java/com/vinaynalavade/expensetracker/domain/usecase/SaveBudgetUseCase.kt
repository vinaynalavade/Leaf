package com.vinaynalavade.expensetracker.domain.usecase

import com.vinaynalavade.expensetracker.core.result.AppError
import com.vinaynalavade.expensetracker.core.result.AppResult
import com.vinaynalavade.expensetracker.domain.model.Budget
import com.vinaynalavade.expensetracker.domain.repository.BudgetRepository

class SaveBudgetUseCase(
    private val budgetRepository: BudgetRepository
) {
    suspend operator fun invoke(budget: Budget): AppResult<Long> {
        if (budget.amount.subunits <= 0L) {
            return AppResult.Error(AppError.ValidationError("Budget limit must be greater than zero."))
        }
        if (budget.amount.subunits > 100_000_000_000_000L) {
            return AppResult.Error(AppError.ValidationError("Budget limit exceeds maximum allowed amount."))
        }
        if (budget.month !in 1..12) {
            return AppResult.Error(AppError.ValidationError("Invalid budget month."))
        }
        if (budget.year < 2000) {
            return AppResult.Error(AppError.ValidationError("Invalid budget year."))
        }

        return budgetRepository.saveBudget(budget)
    }
}
