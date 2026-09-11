package com.vinaynalavade.expensetracker.domain.usecase

import com.vinaynalavade.expensetracker.core.result.AppError
import com.vinaynalavade.expensetracker.core.result.AppResult
import com.vinaynalavade.expensetracker.domain.model.SavingsGoal
import com.vinaynalavade.expensetracker.domain.repository.SavingsGoalRepository

class SaveSavingsGoalUseCase(
    private val savingsGoalRepository: SavingsGoalRepository
) {
    suspend operator fun invoke(goal: SavingsGoal): AppResult<Long> {
        if (goal.name.isBlank()) {
            return AppResult.Error(AppError.ValidationError("Goal name cannot be empty."))
        }
        if (goal.targetAmount.subunits <= 0L) {
            return AppResult.Error(AppError.ValidationError("Target amount must be greater than zero."))
        }
        if (goal.targetAmount.subunits > 100_000_000_000_000L) {
            return AppResult.Error(AppError.ValidationError("Target amount exceeds maximum allowed limit."))
        }

        return savingsGoalRepository.saveSavingsGoal(goal)
    }
}
