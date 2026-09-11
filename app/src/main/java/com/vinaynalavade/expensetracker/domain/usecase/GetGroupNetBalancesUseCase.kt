package com.vinaynalavade.expensetracker.domain.usecase

import com.vinaynalavade.expensetracker.core.split.GroupBalanceSummary
import com.vinaynalavade.expensetracker.core.split.NetBalanceEngine
import com.vinaynalavade.expensetracker.domain.repository.SplitRepository
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map

class GetGroupNetBalancesUseCase(
    private val splitRepository: SplitRepository
) {
    operator fun invoke(groupId: Long? = null): Flow<GroupBalanceSummary> {
        return splitRepository.getAllSplitExpenses().map { allExpenses ->
            val filteredExpenses = if (groupId != null) {
                allExpenses.filter { it.groupId == groupId }
            } else {
                allExpenses
            }
            NetBalanceEngine.calculateNetBalances(filteredExpenses)
        }
    }
}
