package com.vinaynalavade.expensetracker.domain.usecase

import com.vinaynalavade.expensetracker.core.result.AppResult
import com.vinaynalavade.expensetracker.domain.repository.SavingsGoalRepository

class SetSavingsGoalArchivedUseCase(
    private val savingsGoalRepository: SavingsGoalRepository
) {
    suspend operator fun invoke(id: Long, isArchived: Boolean): AppResult<Unit> {
        return savingsGoalRepository.setGoalArchived(id, isArchived)
    }
}
