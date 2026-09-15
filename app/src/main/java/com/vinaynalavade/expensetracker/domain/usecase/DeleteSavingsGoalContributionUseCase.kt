package com.vinaynalavade.expensetracker.domain.usecase

import com.vinaynalavade.expensetracker.core.result.AppResult
import com.vinaynalavade.expensetracker.domain.repository.SavingsGoalRepository
import com.vinaynalavade.expensetracker.domain.repository.TransactionRepository

class DeleteSavingsGoalContributionUseCase(
    private val savingsGoalRepository: SavingsGoalRepository,
    private val transactionRepository: TransactionRepository? = null
) {
    suspend operator fun invoke(
        contributionId: Long,
        deleteLinkedTransaction: Boolean = false
    ): AppResult<Unit> {
        val contribution = savingsGoalRepository.getContributionByIdSuspend(contributionId)
        if (contribution?.transactionId != null && deleteLinkedTransaction) {
            transactionRepository?.deleteTransaction(contribution.transactionId)
        }
        return savingsGoalRepository.deleteContribution(contributionId)
    }
}
