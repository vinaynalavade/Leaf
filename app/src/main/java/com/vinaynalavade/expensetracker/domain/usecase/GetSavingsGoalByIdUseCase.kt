package com.vinaynalavade.expensetracker.domain.usecase

import com.vinaynalavade.expensetracker.domain.model.SavingsGoal
import com.vinaynalavade.expensetracker.domain.repository.SavingsGoalRepository
import kotlinx.coroutines.flow.Flow

class GetSavingsGoalByIdUseCase(
    private val savingsGoalRepository: SavingsGoalRepository
) {
    operator fun invoke(id: Long): Flow<SavingsGoal?> {
        return savingsGoalRepository.getSavingsGoalById(id)
    }

    suspend fun getSuspend(id: Long): SavingsGoal? {
        return savingsGoalRepository.getSavingsGoalByIdSuspend(id)
    }
}
