package com.vinaynalavade.expensetracker.domain.repository

import com.vinaynalavade.expensetracker.core.result.AppResult
import com.vinaynalavade.expensetracker.domain.model.SavingsGoal
import com.vinaynalavade.expensetracker.domain.model.SavingsGoalContribution
import kotlinx.coroutines.flow.Flow

interface SavingsGoalRepository {
    fun getActiveSavingsGoals(): Flow<List<SavingsGoal>>
    fun getArchivedSavingsGoals(): Flow<List<SavingsGoal>>
    fun getAllSavingsGoals(): Flow<List<SavingsGoal>>
    fun getSavingsGoalById(id: Long): Flow<SavingsGoal?>
    suspend fun getSavingsGoalByIdSuspend(id: Long): SavingsGoal?
    fun getContributionsForGoal(goalId: Long): Flow<List<SavingsGoalContribution>>
    suspend fun saveSavingsGoal(goal: SavingsGoal): AppResult<Long>
    suspend fun deleteSavingsGoal(id: Long): AppResult<Unit>
    suspend fun setGoalArchived(id: Long, isArchived: Boolean): AppResult<Unit>
    suspend fun addContribution(contribution: SavingsGoalContribution): AppResult<Long>
    suspend fun updateContribution(contribution: SavingsGoalContribution): AppResult<Unit>
    suspend fun deleteContribution(id: Long): AppResult<Unit>
    suspend fun deleteAllGoals(): AppResult<Unit>
}
