package com.vinaynalavade.expensetracker.data.repository

import androidx.room.withTransaction
import com.vinaynalavade.expensetracker.core.result.AppError
import com.vinaynalavade.expensetracker.core.result.AppResult
import com.vinaynalavade.expensetracker.data.local.dao.SplitDao
import com.vinaynalavade.expensetracker.data.local.dao.TransactionDao
import com.vinaynalavade.expensetracker.data.local.database.ExpenseTrackerDatabase
import com.vinaynalavade.expensetracker.data.local.entity.SplitExpenseEntity
import com.vinaynalavade.expensetracker.data.local.entity.SplitParticipantEntity
import com.vinaynalavade.expensetracker.data.local.entity.TransactionEntity
import com.vinaynalavade.expensetracker.domain.model.PaymentMethod
import com.vinaynalavade.expensetracker.domain.model.SettlementStatus
import com.vinaynalavade.expensetracker.domain.model.SplitExpense
import com.vinaynalavade.expensetracker.domain.model.TransactionType
import com.vinaynalavade.expensetracker.domain.repository.SplitRepository
import kotlinx.coroutines.CoroutineDispatcher
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.withContext

class SplitRepositoryImpl(
    private val database: ExpenseTrackerDatabase? = null,
    private val splitDao: SplitDao,
    private val transactionDao: TransactionDao,
    private val ioDispatcher: CoroutineDispatcher = Dispatchers.IO
) : SplitRepository {

    private suspend fun <T> runInDbTransaction(block: suspend () -> T): T {
        return if (database != null) {
            database.withTransaction(block)
        } else {
            block()
        }
    }

    override fun getAllSplitExpenses(): Flow<List<SplitExpense>> {
        return splitDao.getAllSplitExpenses().map { list ->
            list.map { it.toDomainModel() }
        }
    }

    override fun getSplitExpenseById(id: Long): Flow<SplitExpense?> {
        return splitDao.getSplitExpenseById(id).map { it?.toDomainModel() }
    }

    override suspend fun getSplitExpenseByIdOnce(id: Long): SplitExpense? = withContext(ioDispatcher) {
        splitDao.getSplitExpenseByIdSuspend(id)?.toDomainModel()
    }

    override suspend fun insertSplitExpense(splitExpense: SplitExpense): AppResult<Long> = withContext(ioDispatcher) {
        try {
            val insertedId = runInDbTransaction {
                var expenseTxId: Long? = null
                if (splitExpense.addToTransactions) {
                    val expenseTx = TransactionEntity(
                        amountSubunits = splitExpense.totalAmount.subunits,
                        type = TransactionType.EXPENSE.name,
                        categoryId = splitExpense.categoryId,
                        paymentMethod = splitExpense.paymentMethod.name,
                        note = "Split – ${splitExpense.title}",
                        timestamp = splitExpense.date,
                        createdAt = splitExpense.date,
                        updatedAt = splitExpense.date
                    )
                    expenseTxId = transactionDao.insertTransaction(expenseTx)
                }

                val expenseWithTx = splitExpense.copy(expenseTransactionId = expenseTxId)
                val expenseEntity = SplitExpenseEntity.fromDomainModel(expenseWithTx)
                val participantEntities = splitExpense.participants.map {
                    SplitParticipantEntity.fromDomainModel(it, 0L)
                }
                splitDao.insertSplitExpenseWithParticipants(expenseEntity, participantEntities)
            }
            AppResult.Success(insertedId)
        } catch (e: Exception) {
            AppResult.Error(AppError.DatabaseError("Failed to create split expense: ${e.localizedMessage}", e))
        }
    }

    override suspend fun updateSplitExpense(splitExpense: SplitExpense): AppResult<Unit> = withContext(ioDispatcher) {
        try {
            runInDbTransaction {
                if (splitExpense.addToTransactions && splitExpense.expenseTransactionId != null) {
                    val existingTx = transactionDao.getTransactionByIdSuspend(splitExpense.expenseTransactionId)
                    if (existingTx != null) {
                        transactionDao.updateTransaction(
                            existingTx.copy(
                                amountSubunits = splitExpense.totalAmount.subunits,
                                categoryId = splitExpense.categoryId,
                                paymentMethod = splitExpense.paymentMethod.name,
                                note = "Split – ${splitExpense.title}",
                                timestamp = splitExpense.date,
                                updatedAt = System.currentTimeMillis()
                            )
                        )
                    }
                }

                val expenseEntity = SplitExpenseEntity.fromDomainModel(splitExpense)
                val participantEntities = splitExpense.participants.map {
                    SplitParticipantEntity.fromDomainModel(it, splitExpense.id)
                }
                splitDao.updateSplitExpenseWithParticipants(expenseEntity, participantEntities)
            }
            AppResult.Success(Unit)
        } catch (e: Exception) {
            AppResult.Error(AppError.DatabaseError("Failed to update split expense: ${e.localizedMessage}", e))
        }
    }

    override suspend fun deleteSplitExpense(id: Long): AppResult<Unit> = withContext(ioDispatcher) {
        try {
            runInDbTransaction {
                // Preserves normal ledger transactions as immutable financial history
                splitDao.deleteParticipantsByExpenseId(id)
                splitDao.deleteExpenseById(id)
            }
            AppResult.Success(Unit)
        } catch (e: Exception) {
            AppResult.Error(AppError.DatabaseError("Failed to delete split expense: ${e.localizedMessage}", e))
        }
    }

    override suspend fun updateParticipantSettlement(
        participantId: Long,
        status: SettlementStatus,
        paymentMethod: PaymentMethod,
        settledAt: Long?
    ): AppResult<Unit> = withContext(ioDispatcher) {
        try {
            runInDbTransaction {
                val participant = splitDao.getParticipantById(participantId)
                    ?: return@runInDbTransaction

                if (status == SettlementStatus.SETTLED) {
                    val actualSettledAt = settledAt ?: System.currentTimeMillis()
                    // Current user ("Me") never generates an income settlement transaction
                    if (!participant.isCurrentUser) {
                        val expenseDetails = splitDao.getSplitExpenseByIdSuspend(participant.splitExpenseId)
                        if (expenseDetails != null && expenseDetails.expense.addToTransactions) {
                            // Check if transaction was already created to prevent duplicates
                            if (participant.settlementTransactionId == null) {
                                val incomeTx = TransactionEntity(
                                    amountSubunits = participant.amountSubunits,
                                    type = TransactionType.INCOME.name,
                                    categoryId = expenseDetails.expense.categoryId,
                                    paymentMethod = paymentMethod.name,
                                    note = "${participant.name} — ${expenseDetails.expense.title} settlement",
                                    timestamp = actualSettledAt,
                                    createdAt = actualSettledAt,
                                    updatedAt = actualSettledAt
                                )
                                val txId = transactionDao.insertTransaction(incomeTx)
                                splitDao.updateParticipantSettlementWithTransaction(
                                    participantId = participantId,
                                    status = SettlementStatus.SETTLED.name,
                                    settledAt = actualSettledAt,
                                    transactionId = txId
                                )
                            } else {
                                splitDao.updateParticipantSettlementWithTransaction(
                                    participantId = participantId,
                                    status = SettlementStatus.SETTLED.name,
                                    settledAt = actualSettledAt,
                                    transactionId = participant.settlementTransactionId
                                )
                            }
                        } else {
                            splitDao.updateParticipantSettlement(
                                participantId = participantId,
                                status = SettlementStatus.SETTLED.name,
                                settledAt = actualSettledAt
                            )
                        }
                    } else {
                        splitDao.updateParticipantSettlement(
                            participantId = participantId,
                            status = SettlementStatus.SETTLED.name,
                            settledAt = actualSettledAt
                        )
                    }
                } else {
                    // Changing to PENDING: preserves historical transaction records in the ledger
                    splitDao.updateParticipantSettlement(
                        participantId = participantId,
                        status = SettlementStatus.PENDING.name,
                        settledAt = null
                    )
                }
            }
            AppResult.Success(Unit)
        } catch (e: Exception) {
            AppResult.Error(AppError.DatabaseError("Failed to update settlement status: ${e.localizedMessage}", e))
        }
    }
}
