package com.vinaynalavade.expensetracker.domain.usecase

import com.vinaynalavade.expensetracker.domain.model.SplitGroup
import com.vinaynalavade.expensetracker.domain.repository.SplitGroupRepository
import kotlinx.coroutines.flow.Flow

class GetSplitGroupsUseCase(
    private val repository: SplitGroupRepository
) {
    operator fun invoke(): Flow<List<SplitGroup>> = repository.getAllGroups()
}

class SaveSplitGroupUseCase(
    private val repository: SplitGroupRepository
) {
    suspend operator fun invoke(group: SplitGroup): Long {
        require(group.name.isNotBlank()) { "Group name cannot be blank" }
        return if (group.id == 0L) {
            repository.insertGroup(group)
        } else {
            repository.updateGroup(group)
            group.id
        }
    }
}

class DeleteSplitGroupUseCase(
    private val repository: SplitGroupRepository
) {
    suspend operator fun invoke(groupId: Long) {
        repository.deleteGroup(groupId)
    }
}
