package com.vinaynalavade.expensetracker.domain.usecase

import com.vinaynalavade.expensetracker.core.result.AppResult
import com.vinaynalavade.expensetracker.domain.repository.BudgetRepository

class DeleteBudgetUseCase(
    private val budgetRepository: BudgetRepository
) {
    suspend operator fun invoke(id: Long): AppResult<Unit> {
        return budgetRepository.deleteBudget(id)
    }
}
