package com.vinaynalavade.expensetracker.domain.usecase

import com.vinaynalavade.expensetracker.core.result.AppResult
import com.vinaynalavade.expensetracker.domain.repository.TransactionRepository

/**
 * UseCase to reverse an internal transfer transaction.
 * Creates a counterbalancing transfer in the opposite direction.
 */
class ReverseTransferUseCase(
    private val transactionRepository: TransactionRepository
) {
    suspend operator fun invoke(transactionId: Long): AppResult<Pair<Long, Long>> {
        return transactionRepository.reverseTransfer(transactionId)
    }
}

