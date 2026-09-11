package com.vinaynalavade.expensetracker.data.repository

import com.vinaynalavade.expensetracker.core.result.AppError
import com.vinaynalavade.expensetracker.core.result.AppResult
import com.vinaynalavade.expensetracker.data.local.dao.BudgetDao
import com.vinaynalavade.expensetracker.data.local.entity.BudgetEntity
import com.vinaynalavade.expensetracker.domain.model.Budget
import com.vinaynalavade.expensetracker.domain.repository.BudgetRepository
import kotlinx.coroutines.CoroutineDispatcher
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.withContext

class BudgetRepositoryImpl(
    private val budgetDao: BudgetDao,
    private val ioDispatcher: CoroutineDispatcher = Dispatchers.IO
) : BudgetRepository {

    override fun getAllBudgets(): Flow<List<Budget>> {
        return budgetDao.getAllBudgets().map { list -> list.map { it.toDomainModel() } }
    }

    override fun getBudgetsForMonth(year: Int, month: Int): Flow<List<Budget>> {
        return budgetDao.getBudgetsForMonth(year, month).map { list -> list.map { it.toDomainModel() } }
    }

    override fun getBudgetById(id: Long): Flow<Budget?> {
        return budgetDao.getBudgetById(id).map { it?.toDomainModel() }
    }

    override suspend fun getBudgetByIdSuspend(id: Long): Budget? = withContext(ioDispatcher) {
        budgetDao.getBudgetByIdSuspend(id)?.toDomainModel()
    }

    override fun getOverallBudget(year: Int, month: Int): Flow<Budget?> {
        return budgetDao.getOverallBudget(year, month).map { it?.toDomainModel() }
    }

    override fun getCategoryBudget(year: Int, month: Int, categoryId: Long): Flow<Budget?> {
        return budgetDao.getCategoryBudget(year, month, categoryId).map { it?.toDomainModel() }
    }

    override suspend fun saveBudget(budget: Budget): AppResult<Long> = withContext(ioDispatcher) {
        try {
            val entity = BudgetEntity.fromDomainModel(budget)
            val id = budgetDao.insertBudget(entity)
            AppResult.Success(id)
        } catch (e: Exception) {
            AppResult.Error(AppError.DatabaseError("Failed to save budget: ${e.message}", e))
        }
    }

    override suspend fun deleteBudget(id: Long): AppResult<Unit> = withContext(ioDispatcher) {
        try {
            budgetDao.deleteBudgetById(id)
            AppResult.Success(Unit)
        } catch (e: Exception) {
            AppResult.Error(AppError.DatabaseError("Failed to delete budget: ${e.message}", e))
        }
    }

    override suspend fun deleteAllBudgets(): AppResult<Unit> = withContext(ioDispatcher) {
        try {
            budgetDao.deleteAllBudgets()
            AppResult.Success(Unit)
        } catch (e: Exception) {
            AppResult.Error(AppError.DatabaseError("Failed to delete all budgets: ${e.message}", e))
        }
    }
}
