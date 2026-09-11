package com.vinaynalavade.expensetracker.domain.usecase

import com.vinaynalavade.expensetracker.domain.model.SavingsGoal
import com.vinaynalavade.expensetracker.domain.repository.SavingsGoalRepository
import kotlinx.coroutines.flow.Flow

class GetSavingsGoalsUseCase(
    private val savingsGoalRepository: SavingsGoalRepository
) {
    fun getActiveGoals(): Flow<List<SavingsGoal>> {
        return savingsGoalRepository.getActiveSavingsGoals()
    }

    fun getArchivedGoals(): Flow<List<SavingsGoal>> {
        return savingsGoalRepository.getArchivedSavingsGoals()
    }

    fun getAllGoals(): Flow<List<SavingsGoal>> {
        return savingsGoalRepository.getAllSavingsGoals()
    }
}
