package com.vinaynalavade.expensetracker.data.repository

import com.vinaynalavade.expensetracker.core.result.AppError
import com.vinaynalavade.expensetracker.core.result.AppResult
import com.vinaynalavade.expensetracker.data.local.dao.SavingsGoalDao
import com.vinaynalavade.expensetracker.data.local.entity.SavingsGoalContributionEntity
import com.vinaynalavade.expensetracker.data.local.entity.SavingsGoalEntity
import com.vinaynalavade.expensetracker.domain.model.SavingsGoal
import com.vinaynalavade.expensetracker.domain.model.SavingsGoalContribution
import com.vinaynalavade.expensetracker.domain.repository.SavingsGoalRepository
import kotlinx.coroutines.CoroutineDispatcher
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.withContext

class SavingsGoalRepositoryImpl(
    private val savingsGoalDao: SavingsGoalDao,
    private val ioDispatcher: CoroutineDispatcher = Dispatchers.IO
) : SavingsGoalRepository {

    override fun getActiveSavingsGoals(): Flow<List<SavingsGoal>> {
        return savingsGoalDao.getActiveSavingsGoals().map { list -> list.map { it.toDomainModel() } }
    }

    override fun getArchivedSavingsGoals(): Flow<List<SavingsGoal>> {
        return savingsGoalDao.getArchivedSavingsGoals().map { list -> list.map { it.toDomainModel() } }
    }

    override fun getAllSavingsGoals(): Flow<List<SavingsGoal>> {
        return savingsGoalDao.getAllSavingsGoals().map { list -> list.map { it.toDomainModel() } }
    }

    override fun getSavingsGoalById(id: Long): Flow<SavingsGoal?> {
        return savingsGoalDao.getSavingsGoalById(id).map { it?.toDomainModel() }
    }

    override suspend fun getSavingsGoalByIdSuspend(id: Long): SavingsGoal? = withContext(ioDispatcher) {
        savingsGoalDao.getSavingsGoalByIdSuspend(id)?.toDomainModel()
    }

    override fun getContributionsForGoal(goalId: Long): Flow<List<SavingsGoalContribution>> {
        return savingsGoalDao.getContributionsForGoal(goalId).map { list -> list.map { it.toDomainModel() } }
    }

    override suspend fun saveSavingsGoal(goal: SavingsGoal): AppResult<Long> = withContext(ioDispatcher) {
        try {
            val entity = SavingsGoalEntity.fromDomainModel(goal)
            val id = savingsGoalDao.insertGoal(entity)
            AppResult.Success(id)
        } catch (e: Exception) {
            AppResult.Error(AppError.DatabaseError("Failed to save savings goal: ${e.message}", e))
        }
    }

    override suspend fun deleteSavingsGoal(id: Long): AppResult<Unit> = withContext(ioDispatcher) {
        try {
            savingsGoalDao.deleteGoalById(id)
            AppResult.Success(Unit)
        } catch (e: Exception) {
            AppResult.Error(AppError.DatabaseError("Failed to delete savings goal: ${e.message}", e))
        }
    }

    override suspend fun setGoalArchived(id: Long, isArchived: Boolean): AppResult<Unit> = withContext(ioDispatcher) {
        try {
            savingsGoalDao.setGoalArchived(id, isArchived)
            AppResult.Success(Unit)
        } catch (e: Exception) {
            AppResult.Error(AppError.DatabaseError("Failed to set goal archived status: ${e.message}", e))
        }
    }

    override suspend fun addContribution(contribution: SavingsGoalContribution): AppResult<Long> = withContext(ioDispatcher) {
        try {
            val entity = SavingsGoalContributionEntity.fromDomainModel(contribution)
            val id = savingsGoalDao.insertContribution(entity)
            AppResult.Success(id)
        } catch (e: Exception) {
            AppResult.Error(AppError.DatabaseError("Failed to add contribution: ${e.message}", e))
        }
    }

    override suspend fun updateContribution(contribution: SavingsGoalContribution): AppResult<Unit> = withContext(ioDispatcher) {
        try {
            val entity = SavingsGoalContributionEntity.fromDomainModel(contribution)
            savingsGoalDao.updateContribution(entity)
            AppResult.Success(Unit)
        } catch (e: Exception) {
            AppResult.Error(AppError.DatabaseError("Failed to update contribution: ${e.message}", e))
        }
    }

    override suspend fun deleteContribution(id: Long): AppResult<Unit> = withContext(ioDispatcher) {
        try {
            savingsGoalDao.deleteContributionById(id)
            AppResult.Success(Unit)
        } catch (e: Exception) {
            AppResult.Error(AppError.DatabaseError("Failed to delete contribution: ${e.message}", e))
        }
    }

    override suspend fun deleteAllGoals(): AppResult<Unit> = withContext(ioDispatcher) {
        try {
            savingsGoalDao.deleteAllContributions()
            savingsGoalDao.deleteAllGoals()
            AppResult.Success(Unit)
        } catch (e: Exception) {
            AppResult.Error(AppError.DatabaseError("Failed to delete all savings goals: ${e.message}", e))
        }
    }
}
