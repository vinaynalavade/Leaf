package com.vinaynalavade.expensetracker.data.local.dao

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import androidx.room.Transaction
import androidx.room.Update
import com.vinaynalavade.expensetracker.data.local.entity.SavingsGoalContributionEntity
import com.vinaynalavade.expensetracker.data.local.entity.SavingsGoalEntity
import com.vinaynalavade.expensetracker.data.local.entity.SavingsGoalWithContributions
import kotlinx.coroutines.flow.Flow

@Dao
interface SavingsGoalDao {

    @Transaction
    @Query("SELECT * FROM savings_goals WHERE is_archived = 0 ORDER BY id DESC")
    fun getActiveSavingsGoals(): Flow<List<SavingsGoalWithContributions>>

    @Transaction
    @Query("SELECT * FROM savings_goals WHERE is_archived = 1 ORDER BY id DESC")
    fun getArchivedSavingsGoals(): Flow<List<SavingsGoalWithContributions>>

    @Transaction
    @Query("SELECT * FROM savings_goals ORDER BY id DESC")
    fun getAllSavingsGoals(): Flow<List<SavingsGoalWithContributions>>

    @Transaction
    @Query("SELECT * FROM savings_goals WHERE id = :id LIMIT 1")
    fun getSavingsGoalById(id: Long): Flow<SavingsGoalWithContributions?>

    @Transaction
    @Query("SELECT * FROM savings_goals WHERE id = :id LIMIT 1")
    suspend fun getSavingsGoalByIdSuspend(id: Long): SavingsGoalWithContributions?

    @Query("SELECT * FROM savings_goal_contributions WHERE goal_id = :goalId ORDER BY timestamp DESC, id DESC")
    fun getContributionsForGoal(goalId: Long): Flow<List<SavingsGoalContributionEntity>>

    @Query("SELECT * FROM savings_goal_contributions WHERE id = :id LIMIT 1")
    suspend fun getContributionById(id: Long): SavingsGoalContributionEntity?

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertGoal(goal: SavingsGoalEntity): Long

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertGoals(goals: List<SavingsGoalEntity>)

    @Update
    suspend fun updateGoal(goal: SavingsGoalEntity)

    @Query("DELETE FROM savings_goals WHERE id = :id")
    suspend fun deleteGoalById(id: Long)

    @Query("DELETE FROM savings_goals")
    suspend fun deleteAllGoals()

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertContribution(contribution: SavingsGoalContributionEntity): Long

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertContributions(contributions: List<SavingsGoalContributionEntity>)

    @Update
    suspend fun updateContribution(contribution: SavingsGoalContributionEntity)

    @Query("DELETE FROM savings_goal_contributions WHERE id = :id")
    suspend fun deleteContributionById(id: Long)

    @Query("DELETE FROM savings_goal_contributions WHERE goal_id = :goalId")
    suspend fun deleteContributionsByGoalId(goalId: Long)

    @Query("DELETE FROM savings_goal_contributions")
    suspend fun deleteAllContributions()

    @Query("UPDATE savings_goals SET is_archived = :isArchived, updated_at = :updatedAt WHERE id = :id")
    suspend fun setGoalArchived(id: Long, isArchived: Boolean, updatedAt: Long = System.currentTimeMillis())
}
