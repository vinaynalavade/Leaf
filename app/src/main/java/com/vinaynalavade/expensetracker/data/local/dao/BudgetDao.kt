package com.vinaynalavade.expensetracker.data.local.dao

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import androidx.room.Transaction
import androidx.room.Update
import com.vinaynalavade.expensetracker.data.local.entity.BudgetEntity
import com.vinaynalavade.expensetracker.data.local.entity.BudgetWithCategory
import kotlinx.coroutines.flow.Flow

@Dao
interface BudgetDao {

    @Transaction
    @Query("SELECT * FROM budgets ORDER BY year DESC, month DESC, category_id IS NOT NULL, id ASC")
    fun getAllBudgets(): Flow<List<BudgetWithCategory>>

    @Transaction
    @Query("SELECT * FROM budgets WHERE year = :year AND month = :month ORDER BY category_id IS NOT NULL, id ASC")
    fun getBudgetsForMonth(year: Int, month: Int): Flow<List<BudgetWithCategory>>

    @Transaction
    @Query("SELECT * FROM budgets WHERE id = :id LIMIT 1")
    fun getBudgetById(id: Long): Flow<BudgetWithCategory?>

    @Transaction
    @Query("SELECT * FROM budgets WHERE id = :id LIMIT 1")
    suspend fun getBudgetByIdSuspend(id: Long): BudgetWithCategory?

    @Transaction
    @Query("SELECT * FROM budgets WHERE year = :year AND month = :month AND category_id IS NULL LIMIT 1")
    fun getOverallBudget(year: Int, month: Int): Flow<BudgetWithCategory?>

    @Transaction
    @Query("SELECT * FROM budgets WHERE year = :year AND month = :month AND category_id = :categoryId LIMIT 1")
    fun getCategoryBudget(year: Int, month: Int, categoryId: Long): Flow<BudgetWithCategory?>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertBudget(budget: BudgetEntity): Long

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertBudgets(budgets: List<BudgetEntity>)

    @Update
    suspend fun updateBudget(budget: BudgetEntity)

    @Query("DELETE FROM budgets WHERE id = :id")
    suspend fun deleteBudgetById(id: Long)

    @Query("DELETE FROM budgets")
    suspend fun deleteAllBudgets()
}
