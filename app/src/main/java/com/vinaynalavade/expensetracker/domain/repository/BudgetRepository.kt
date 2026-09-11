package com.vinaynalavade.expensetracker.domain.repository

import com.vinaynalavade.expensetracker.core.result.AppResult
import com.vinaynalavade.expensetracker.domain.model.Budget
import kotlinx.coroutines.flow.Flow

interface BudgetRepository {
    fun getAllBudgets(): Flow<List<Budget>>
    fun getBudgetsForMonth(year: Int, month: Int): Flow<List<Budget>>
    fun getBudgetById(id: Long): Flow<Budget?>
    suspend fun getBudgetByIdSuspend(id: Long): Budget?
    fun getOverallBudget(year: Int, month: Int): Flow<Budget?>
    fun getCategoryBudget(year: Int, month: Int, categoryId: Long): Flow<Budget?>
    suspend fun saveBudget(budget: Budget): AppResult<Long>
    suspend fun deleteBudget(id: Long): AppResult<Unit>
    suspend fun deleteAllBudgets(): AppResult<Unit>
}
