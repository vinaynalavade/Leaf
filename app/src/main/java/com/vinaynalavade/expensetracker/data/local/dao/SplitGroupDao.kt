package com.vinaynalavade.expensetracker.data.local.dao

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import androidx.room.Update
import com.vinaynalavade.expensetracker.data.local.entity.SplitGroupEntity
import kotlinx.coroutines.flow.Flow

@Dao
interface SplitGroupDao {

    @Query("SELECT * FROM split_groups ORDER BY name ASC")
    fun getAllGroups(): Flow<List<SplitGroupEntity>>

    @Query("SELECT * FROM split_groups WHERE id = :id LIMIT 1")
    fun getGroupById(id: Long): Flow<SplitGroupEntity?>

    @Query("SELECT * FROM split_groups WHERE id = :id LIMIT 1")
    suspend fun getGroupByIdSuspend(id: Long): SplitGroupEntity?

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertGroup(group: SplitGroupEntity): Long

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertGroups(groups: List<SplitGroupEntity>)

    @Update
    suspend fun updateGroup(group: SplitGroupEntity)

    @Query("DELETE FROM split_groups WHERE id = :id")
    suspend fun deleteGroupById(id: Long)

    @Query("DELETE FROM split_groups")
    suspend fun deleteAllGroups()

    @Query("SELECT COUNT(*) FROM split_expenses WHERE group_id = :groupId")
    fun getExpenseCountByGroupId(groupId: Long): Flow<Int>
}
