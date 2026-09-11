package com.vinaynalavade.expensetracker.domain.usecase

import com.vinaynalavade.expensetracker.core.result.AppResult
import com.vinaynalavade.expensetracker.domain.repository.SavingsGoalRepository

class DeleteSavingsGoalUseCase(
    private val savingsGoalRepository: SavingsGoalRepository
) {
    suspend operator fun invoke(id: Long): AppResult<Unit> {
        return savingsGoalRepository.deleteSavingsGoal(id)
    }
}
