package com.vinaynalavade.expensetracker.data.repository

import com.vinaynalavade.expensetracker.core.model.Amount
import com.vinaynalavade.expensetracker.core.result.AppError
import com.vinaynalavade.expensetracker.core.result.AppResult
import com.vinaynalavade.expensetracker.data.local.dao.TransactionDao
import com.vinaynalavade.expensetracker.data.local.entity.TransactionEntity
import com.vinaynalavade.expensetracker.domain.model.FinancialSummary
import com.vinaynalavade.expensetracker.domain.model.PaymentMethod
import com.vinaynalavade.expensetracker.domain.model.Transaction
import com.vinaynalavade.expensetracker.domain.model.TransactionType
import com.vinaynalavade.expensetracker.domain.repository.TransactionRepository
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map

class TransactionRepositoryImpl(
    private val transactionDao: TransactionDao
) : TransactionRepository {

    override fun getTransactions(): Flow<List<Transaction>> {
        return transactionDao.getAllTransactionsWithCategory().map { list ->
            list.map { it.toDomainModel() }
        }
    }

    override fun getRecentTransactions(limit: Int): Flow<List<Transaction>> {
        return transactionDao.getRecentTransactionsWithCategory(limit).map { list ->
            list.map { it.toDomainModel() }
        }
    }

    override fun getTransactionById(id: Long): Flow<Transaction?> {
        return transactionDao.getTransactionWithCategoryById(id).map { item ->
            item?.toDomainModel()
        }
    }

    override fun getTransactionsBetween(startDate: Long, endDate: Long): Flow<List<Transaction>> {
        return transactionDao.getTransactionsBetween(startDate, endDate).map { list ->
            list.map { it.toDomainModel() }
        }
    }

    override fun getFinancialSummary(): Flow<FinancialSummary> {
        return getTransactions().map { transactions ->
            var incomeSubunits = 0L
            var expenseSubunits = 0L
            var totalInflowSubunits = 0L
            var totalOutflowSubunits = 0L
            for (tx in transactions) {
                if (tx.type == TransactionType.INCOME) {
                    totalInflowSubunits += tx.amount.subunits
                    if (!tx.isInternalTransfer) {
                        incomeSubunits += tx.amount.subunits
                    }
                } else {
                    totalOutflowSubunits += tx.amount.subunits
                    if (!tx.isInternalTransfer) {
                        expenseSubunits += tx.amount.subunits
                    }
                }
            }
            FinancialSummary(
                totalIncome = Amount(incomeSubunits),
                totalExpense = Amount(expenseSubunits),
                netChange = Amount(incomeSubunits - expenseSubunits),
                currentBalance = Amount(totalInflowSubunits - totalOutflowSubunits),
                transactionCount = transactions.size
            )
        }
    }

    override fun getFinancialSummaryByDateRange(startDate: Long, endDate: Long): Flow<FinancialSummary> {
        return getTransactionsBetween(startDate, endDate).map { transactions ->
            var incomeSubunits = 0L
            var expenseSubunits = 0L
            var totalInflowSubunits = 0L
            var totalOutflowSubunits = 0L
            for (tx in transactions) {
                if (tx.type == TransactionType.INCOME) {
                    totalInflowSubunits += tx.amount.subunits
                    if (!tx.isInternalTransfer) {
                        incomeSubunits += tx.amount.subunits
                    }
                } else {
                    totalOutflowSubunits += tx.amount.subunits
                    if (!tx.isInternalTransfer) {
                        expenseSubunits += tx.amount.subunits
                    }
                }
            }
            FinancialSummary(
                totalIncome = Amount(incomeSubunits),
                totalExpense = Amount(expenseSubunits),
                netChange = Amount(incomeSubunits - expenseSubunits),
                currentBalance = Amount(totalInflowSubunits - totalOutflowSubunits),
                transactionCount = transactions.size
            )
        }
    }

    override fun getCashBalance(): Flow<Amount> {
        return transactionDao.getCashBalanceSubunits().map { Amount(it) }
    }

    override fun getAccountBalance(): Flow<Amount> {
        return transactionDao.getAccountBalanceSubunits().map { Amount(it) }
    }

    override fun getCashTransactions(): Flow<List<Transaction>> {
        return transactionDao.getCashTransactionsWithCategory().map { list ->
            list.map { it.toDomainModel() }
        }
    }

    override fun getAccountTransactions(): Flow<List<Transaction>> {
        return transactionDao.getAccountTransactionsWithCategory().map { list ->
            list.map { it.toDomainModel() }
        }
    }

    override suspend fun transferBetweenLedgers(
        from: PaymentMethod,
        to: PaymentMethod,
        amount: Amount,
        note: String?,
        timestamp: Long
    ): AppResult<Pair<Long, Long>> {
        return try {
            val now = System.currentTimeMillis()
            val txTime = if (timestamp > 0) timestamp else now
            val transferCatId = transactionDao.getTransferCategoryId() ?: 1L
            val defaultNote = "Transfer from ${from.displayName} to ${to.displayName}"
            val fullNote = if (!note.isNullOrBlank()) note.trim() else defaultNote

            // 1. Outflow transaction from source ledger
            val outflow = TransactionEntity(
                amountSubunits = amount.subunits,
                type = TransactionType.EXPENSE.name,
                categoryId = transferCatId,
                paymentMethod = from.name,
                rawPaymentMethod = from.name,
                note = fullNote,
                timestamp = txTime,
                createdAt = now,
                updatedAt = now,
                isInternalTransfer = true
            )
            val outId = transactionDao.insertTransaction(outflow)

            // 2. Inflow transaction to destination ledger, linked to outflow
            val inflow = TransactionEntity(
                amountSubunits = amount.subunits,
                type = TransactionType.INCOME.name,
                categoryId = transferCatId,
                paymentMethod = to.name,
                rawPaymentMethod = to.name,
                transferPairId = outId,
                note = fullNote,
                timestamp = txTime,
                createdAt = now,
                updatedAt = now,
                isInternalTransfer = true
            )
            val inId = transactionDao.insertTransaction(inflow)

            // 3. Atomically link outflow to inflow
            transactionDao.updateTransferPairId(outId, inId)

            AppResult.Success(Pair(outId, inId))
        } catch (e: Exception) {
            AppResult.Error(AppError.DatabaseError(e.message ?: "Failed to execute transfer", e))
        }
    }

    override suspend fun reverseTransfer(transactionId: Long): AppResult<Pair<Long, Long>> {
        return try {
            val tx = transactionDao.getTransactionByIdSuspend(transactionId)
                ?: return AppResult.Error(AppError.ValidationError("Transaction not found."))
            if (!tx.isInternalTransfer) {
                return AppResult.Error(AppError.ValidationError("Transaction is not an internal transfer."))
            }

            var partner = tx.transferPairId?.let { transactionDao.getTransactionByIdSuspend(it) }
            if (partner == null) {
                partner = transactionDao.getTransactionByPairId(tx.id)
            }

            val currentType = tx.type
            val currentPmRaw = tx.paymentMethod
            val partnerPmRaw = partner?.paymentMethod ?: if (currentPmRaw == PaymentMethod.CASH.name) PaymentMethod.ACCOUNT.name else PaymentMethod.CASH.name
            val amountSubunits = tx.amountSubunits

            val originalSource = if (currentType == TransactionType.EXPENSE.name) currentPmRaw else partnerPmRaw
            val originalDest = if (currentType == TransactionType.EXPENSE.name) partnerPmRaw else currentPmRaw

            val revSourceMethod = PaymentMethod.fromString(originalDest)
            val revDestMethod = PaymentMethod.fromString(originalSource)

            val revNote = "Reversal: " + (tx.note ?: "Transfer from $originalSource to $originalDest")
            val now = System.currentTimeMillis()

            transferBetweenLedgers(
                from = revSourceMethod,
                to = revDestMethod,
                amount = Amount(amountSubunits),
                note = revNote,
                timestamp = now
            )
        } catch (e: Exception) {
            AppResult.Error(AppError.DatabaseError(e.message ?: "Failed to reverse transfer", e))
        }
    }

    override suspend fun insertTransaction(transaction: Transaction): AppResult<Long> {
        return try {
            val entity = TransactionEntity.fromDomainModel(transaction)
            val id = transactionDao.insertTransaction(entity)
            AppResult.Success(id)
        } catch (e: Exception) {
            AppResult.Error(AppError.DatabaseError(e.message ?: "Failed to insert transaction.", e))
        }
    }

    override suspend fun updateTransaction(transaction: Transaction): AppResult<Unit> {
        return try {
            val entity = TransactionEntity.fromDomainModel(transaction)
            transactionDao.updateTransaction(entity)

            // If internal transfer, atomically synchronize its paired counterpart
            if (transaction.isInternalTransfer) {
                var counterpartId = transaction.transferPairId
                if (counterpartId == null) {
                    val partner = transactionDao.getTransactionByPairId(transaction.id)
                    counterpartId = partner?.id
                }
                if (counterpartId != null) {
                    val partnerEntity = transactionDao.getTransactionByIdSuspend(counterpartId)
                    if (partnerEntity != null) {
                        val updatedPartner = partnerEntity.copy(
                            amountSubunits = transaction.amount.subunits,
                            note = transaction.note,
                            timestamp = transaction.timestamp,
                            updatedAt = System.currentTimeMillis()
                        )
                        transactionDao.updateTransaction(updatedPartner)
                    }
                }
            }
            AppResult.Success(Unit)
        } catch (e: Exception) {
            AppResult.Error(AppError.DatabaseError(e.message ?: "Failed to update transaction.", e))
        }
    }

    override suspend fun deleteTransaction(id: Long): AppResult<Unit> {
        return try {
            val tx = transactionDao.getTransactionByIdSuspend(id)
            if (tx != null && tx.isInternalTransfer) {
                var counterpartId = tx.transferPairId
                if (counterpartId == null) {
                    val partner = transactionDao.getTransactionByPairId(tx.id)
                    counterpartId = partner?.id
                }
                if (counterpartId != null) {
                    transactionDao.deleteTransactionById(counterpartId)
                }
            }
            transactionDao.deleteTransactionById(id)
            AppResult.Success(Unit)
        } catch (e: Exception) {
            AppResult.Error(AppError.DatabaseError(e.message ?: "Failed to delete transaction.", e))
        }
    }
}
