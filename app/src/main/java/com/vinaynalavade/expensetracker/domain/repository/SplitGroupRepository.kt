package com.vinaynalavade.expensetracker.domain.repository

import com.vinaynalavade.expensetracker.domain.model.SplitGroup
import kotlinx.coroutines.flow.Flow

interface SplitGroupRepository {
    fun getAllGroups(): Flow<List<SplitGroup>>
    fun getGroupById(id: Long): Flow<SplitGroup?>
    suspend fun getGroupByIdSuspend(id: Long): SplitGroup?
    suspend fun insertGroup(group: SplitGroup): Long
    suspend fun updateGroup(group: SplitGroup)
    suspend fun deleteGroup(id: Long)
}
