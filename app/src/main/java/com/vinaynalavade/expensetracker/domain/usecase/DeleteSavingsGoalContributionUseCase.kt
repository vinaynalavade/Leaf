package com.vinaynalavade.expensetracker.domain.usecase

import com.vinaynalavade.expensetracker.domain.repository.SavingsGoalRepository

class DeleteSavingsGoalContributionUseCase(
    private val repository: SavingsGoalRepository
) {
    suspend operator fun invoke(contributionId: Long) {
        repository.deleteContribution(contributionId)
    }
}
