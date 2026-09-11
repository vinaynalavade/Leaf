package com.vinaynalavade.expensetracker.domain.usecase

import com.vinaynalavade.expensetracker.core.result.AppError
import com.vinaynalavade.expensetracker.core.result.AppResult
import com.vinaynalavade.expensetracker.domain.model.SavingsGoalContribution
import com.vinaynalavade.expensetracker.domain.repository.SavingsGoalRepository

class SaveSavingsGoalContributionUseCase(
    private val savingsGoalRepository: SavingsGoalRepository
) {
    suspend operator fun invoke(contribution: SavingsGoalContribution): AppResult<Long> {
        if (contribution.amount.subunits <= 0L) {
            return AppResult.Error(AppError.ValidationError("Contribution amount must be greater than zero."))
        }
        if (contribution.amount.subunits > 100_000_000_000_000L) {
            return AppResult.Error(AppError.ValidationError("Contribution amount exceeds maximum allowed limit."))
        }
        if (contribution.timestamp > System.currentTimeMillis()) {
            return AppResult.Error(AppError.ValidationError("Contribution date cannot be in the future."))
        }

        val goal = savingsGoalRepository.getSavingsGoalByIdSuspend(contribution.goalId)
            ?: return AppResult.Error(AppError.ValidationError("Associated savings goal not found."))

        if (goal.isArchived) {
            return AppResult.Error(AppError.ValidationError("Cannot add or modify contributions for an archived savings goal."))
        }

        return if (contribution.id == 0L) {
            savingsGoalRepository.addContribution(contribution)
        } else {
            val updateResult = savingsGoalRepository.updateContribution(contribution)
            when (updateResult) {
                is AppResult.Success -> AppResult.Success(contribution.id)
                is AppResult.Error -> updateResult
            }
        }
    }
}
