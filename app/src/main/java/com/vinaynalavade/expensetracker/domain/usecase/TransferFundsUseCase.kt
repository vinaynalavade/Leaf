package com.vinaynalavade.expensetracker.domain.usecase

import com.vinaynalavade.expensetracker.core.model.Amount
import com.vinaynalavade.expensetracker.core.result.AppError
import com.vinaynalavade.expensetracker.core.result.AppResult
import com.vinaynalavade.expensetracker.domain.model.PaymentMethod
import com.vinaynalavade.expensetracker.domain.repository.TransactionRepository

/**
 * UseCase to execute an internal transfer between Cash and Account ledgers.
 * Creates an atomic linked pair of transactions with zero net effect on income/expense metrics.
 */
class TransferFundsUseCase(
    private val transactionRepository: TransactionRepository
) {
    suspend operator fun invoke(
        from: PaymentMethod,
        to: PaymentMethod,
        amount: Amount,
        note: String? = null,
        timestamp: Long = System.currentTimeMillis()
    ): AppResult<Pair<Long, Long>> {
        if (from == to) {
            return AppResult.Error(AppError.ValidationError("Source and destination ledgers must be different."))
        }
        if (amount.subunits <= 0) {
            return AppResult.Error(AppError.ValidationError("Transfer amount must be greater than zero."))
        }
        return transactionRepository.transferBetweenLedgers(from, to, amount, note, timestamp)
    }
}

