package com.vinaynalavade.expensetracker.domain.repository

import com.vinaynalavade.expensetracker.core.model.Amount
import com.vinaynalavade.expensetracker.core.result.AppResult
import com.vinaynalavade.expensetracker.domain.model.FinancialSummary
import com.vinaynalavade.expensetracker.domain.model.PaymentMethod
import com.vinaynalavade.expensetracker.domain.model.Transaction
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map

/**
 * Repository contract for managing transaction data.
 */
interface TransactionRepository {

    fun getTransactions(): Flow<List<Transaction>>

    fun getRecentTransactions(limit: Int): Flow<List<Transaction>> =
        getTransactions().map { it.take(limit) }

    fun getTransactionById(id: Long): Flow<Transaction?>

    fun getTransactionsBetween(startDate: Long, endDate: Long): Flow<List<Transaction>>

    fun getFinancialSummary(): Flow<FinancialSummary>

    fun getFinancialSummaryByDateRange(startDate: Long, endDate: Long): Flow<FinancialSummary>

    // Independent Ledger Operations
    fun getCashBalance(): Flow<Amount> = kotlinx.coroutines.flow.flowOf(Amount.ZERO)
    fun getAccountBalance(): Flow<Amount> = kotlinx.coroutines.flow.flowOf(Amount.ZERO)
    fun getCashTransactions(): Flow<List<Transaction>> = kotlinx.coroutines.flow.flowOf(emptyList())
    fun getAccountTransactions(): Flow<List<Transaction>> = kotlinx.coroutines.flow.flowOf(emptyList())

    suspend fun transferBetweenLedgers(
        from: PaymentMethod,
        to: PaymentMethod,
        amount: Amount,
        note: String?,
        timestamp: Long
    ): AppResult<Pair<Long, Long>> = AppResult.Success(Pair(0L, 0L))

    suspend fun reverseTransfer(transactionId: Long): AppResult<Pair<Long, Long>> = AppResult.Success(Pair(0L, 0L))

    suspend fun insertTransaction(transaction: Transaction): AppResult<Long>

    suspend fun updateTransaction(transaction: Transaction): AppResult<Unit>

    suspend fun deleteTransaction(id: Long): AppResult<Unit>
}
