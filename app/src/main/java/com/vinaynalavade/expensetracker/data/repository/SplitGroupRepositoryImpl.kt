package com.vinaynalavade.expensetracker.data.repository

import com.vinaynalavade.expensetracker.data.local.dao.SplitGroupDao
import com.vinaynalavade.expensetracker.data.local.entity.SplitGroupEntity
import com.vinaynalavade.expensetracker.domain.model.SplitGroup
import com.vinaynalavade.expensetracker.domain.repository.SplitGroupRepository
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map

class SplitGroupRepositoryImpl(
    private val splitGroupDao: SplitGroupDao
) : SplitGroupRepository {

    override fun getAllGroups(): Flow<List<SplitGroup>> {
        return splitGroupDao.getAllGroups().map { list ->
            list.map { it.toDomainModel() }
        }
    }

    override fun getGroupById(id: Long): Flow<SplitGroup?> {
        return splitGroupDao.getGroupById(id).map { it?.toDomainModel() }
    }

    override suspend fun getGroupByIdSuspend(id: Long): SplitGroup? {
        return splitGroupDao.getGroupByIdSuspend(id)?.toDomainModel()
    }

    override suspend fun insertGroup(group: SplitGroup): Long {
        return splitGroupDao.insertGroup(SplitGroupEntity.fromDomainModel(group))
    }

    override suspend fun updateGroup(group: SplitGroup) {
        splitGroupDao.updateGroup(SplitGroupEntity.fromDomainModel(group))
    }

    override suspend fun deleteGroup(id: Long) {
        splitGroupDao.deleteGroupById(id)
    }
}
