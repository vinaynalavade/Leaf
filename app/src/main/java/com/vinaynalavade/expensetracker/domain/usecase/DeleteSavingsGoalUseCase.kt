package com.vinaynalavade.expensetracker.domain.usecase

import com.vinaynalavade.expensetracker.core.result.AppResult
import com.vinaynalavade.expensetracker.domain.repository.SavingsGoalRepository
import com.vinaynalavade.expensetracker.domain.repository.TransactionRepository

class DeleteSavingsGoalUseCase(
    private val savingsGoalRepository: SavingsGoalRepository,
    private val transactionRepository: TransactionRepository? = null
) {
    suspend operator fun invoke(
        id: Long,
        deleteLinkedTransactions: Boolean = false
    ): AppResult<Unit> {
        if (deleteLinkedTransactions) {
            val goal = savingsGoalRepository.getSavingsGoalByIdSuspend(id)
            goal?.contributions?.forEach { contrib ->
                contrib.transactionId?.let { txId ->
                    transactionRepository?.deleteTransaction(txId)
                }
            }
        }
        return savingsGoalRepository.deleteSavingsGoal(id)
    }
}
