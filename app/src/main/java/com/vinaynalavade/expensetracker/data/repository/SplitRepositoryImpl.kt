package com.vinaynalavade.expensetracker.data.repository

import com.vinaynalavade.expensetracker.core.result.AppError
import com.vinaynalavade.expensetracker.core.result.AppResult
import com.vinaynalavade.expensetracker.data.local.dao.SplitDao
import com.vinaynalavade.expensetracker.data.local.entity.SplitExpenseEntity
import com.vinaynalavade.expensetracker.data.local.entity.SplitParticipantEntity
import com.vinaynalavade.expensetracker.domain.model.SettlementStatus
import com.vinaynalavade.expensetracker.domain.model.SplitExpense
import com.vinaynalavade.expensetracker.domain.repository.SplitRepository
import kotlinx.coroutines.CoroutineDispatcher
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.withContext

class SplitRepositoryImpl(
    private val splitDao: SplitDao,
    private val ioDispatcher: CoroutineDispatcher = Dispatchers.IO
) : SplitRepository {

    override fun getAllSplitExpenses(): Flow<List<SplitExpense>> {
        return splitDao.getAllSplitExpenses().map { list ->
            list.map { it.toDomainModel() }
        }
    }

    override fun getSplitExpenseById(id: Long): Flow<SplitExpense?> {
        return splitDao.getSplitExpenseById(id).map { it?.toDomainModel() }
    }

    override suspend fun getSplitExpenseByIdOnce(id: Long): SplitExpense? = withContext(ioDispatcher) {
        splitDao.getSplitExpenseByIdSuspend(id)?.toDomainModel()
    }

    override suspend fun insertSplitExpense(splitExpense: SplitExpense): AppResult<Long> = withContext(ioDispatcher) {
        try {
            val expenseEntity = SplitExpenseEntity.fromDomainModel(splitExpense)
            val participantEntities = splitExpense.participants.map {
                SplitParticipantEntity.fromDomainModel(it, splitExpense.id)
            }
            val insertedId = splitDao.insertSplitExpenseWithParticipants(expenseEntity, participantEntities)
            AppResult.Success(insertedId)
        } catch (e: Exception) {
            AppResult.Error(AppError.DatabaseError("Failed to create split expense: ${e.localizedMessage}", e))
        }
    }

    override suspend fun updateSplitExpense(splitExpense: SplitExpense): AppResult<Unit> = withContext(ioDispatcher) {
        try {
            val expenseEntity = SplitExpenseEntity.fromDomainModel(splitExpense)
            val participantEntities = splitExpense.participants.map {
                SplitParticipantEntity.fromDomainModel(it, splitExpense.id)
            }
            splitDao.updateSplitExpenseWithParticipants(expenseEntity, participantEntities)
            AppResult.Success(Unit)
        } catch (e: Exception) {
            AppResult.Error(AppError.DatabaseError("Failed to update split expense: ${e.localizedMessage}", e))
        }
    }

    override suspend fun deleteSplitExpense(id: Long): AppResult<Unit> = withContext(ioDispatcher) {
        try {
            splitDao.deleteExpenseById(id)
            AppResult.Success(Unit)
        } catch (e: Exception) {
            AppResult.Error(AppError.DatabaseError("Failed to delete split expense: ${e.localizedMessage}", e))
        }
    }

    override suspend fun updateParticipantSettlement(
        participantId: Long,
        status: SettlementStatus,
        settledAt: Long?
    ): AppResult<Unit> = withContext(ioDispatcher) {
        try {
            splitDao.updateParticipantSettlement(participantId, status.name, settledAt)
            AppResult.Success(Unit)
        } catch (e: Exception) {
            AppResult.Error(AppError.DatabaseError("Failed to update settlement status: ${e.localizedMessage}", e))
        }
    }
}
