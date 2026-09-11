package com.vinaynalavade.expensetracker.data.local.dao

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import androidx.room.Transaction
import androidx.room.Update
import com.vinaynalavade.expensetracker.data.local.entity.SplitExpenseEntity
import com.vinaynalavade.expensetracker.data.local.entity.SplitExpenseWithDetails
import com.vinaynalavade.expensetracker.data.local.entity.SplitParticipantEntity
import kotlinx.coroutines.flow.Flow

@Dao
interface SplitDao {

    @Transaction
    @Query("SELECT * FROM split_expenses ORDER BY date DESC, id DESC")
    fun getAllSplitExpenses(): Flow<List<SplitExpenseWithDetails>>

    @Transaction
    @Query("SELECT * FROM split_expenses WHERE group_id = :groupId ORDER BY date DESC, id DESC")
    fun getSplitExpensesByGroupId(groupId: Long): Flow<List<SplitExpenseWithDetails>>

    @Transaction
    @Query("SELECT * FROM split_expenses WHERE id = :id LIMIT 1")
    fun getSplitExpenseById(id: Long): Flow<SplitExpenseWithDetails?>

    @Transaction
    @Query("SELECT * FROM split_expenses WHERE id = :id LIMIT 1")
    suspend fun getSplitExpenseByIdSuspend(id: Long): SplitExpenseWithDetails?

    @Query("SELECT * FROM split_participants WHERE id = :participantId LIMIT 1")
    suspend fun getParticipantById(participantId: Long): SplitParticipantEntity?

    @Query("SELECT * FROM split_participants WHERE split_expense_id = :expenseId")
    suspend fun getParticipantsByExpenseId(expenseId: Long): List<SplitParticipantEntity>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertExpense(expense: SplitExpenseEntity): Long

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertExpenses(expenses: List<SplitExpenseEntity>)

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertParticipants(participants: List<SplitParticipantEntity>)

    @Update
    suspend fun updateExpense(expense: SplitExpenseEntity)

    @Query("DELETE FROM split_participants WHERE split_expense_id = :expenseId")
    suspend fun deleteParticipantsByExpenseId(expenseId: Long)

    @Query("DELETE FROM split_expenses WHERE id = :id")
    suspend fun deleteExpenseById(id: Long)

    @Query("DELETE FROM split_participants")
    suspend fun deleteAllParticipants()

    @Query("DELETE FROM split_expenses")
    suspend fun deleteAllSplitExpenses()

    @Query("UPDATE split_participants SET settlement_status = :status, settled_at = :settledAt WHERE id = :participantId")
    suspend fun updateParticipantSettlement(participantId: Long, status: String, settledAt: Long?)

    @Query("UPDATE split_participants SET settlement_status = :status, settled_at = :settledAt, settlement_transaction_id = :transactionId WHERE id = :participantId")
    suspend fun updateParticipantSettlementWithTransaction(participantId: Long, status: String, settledAt: Long?, transactionId: Long?)

    @Transaction
    suspend fun insertSplitExpenseWithParticipants(
        expense: SplitExpenseEntity,
        participants: List<SplitParticipantEntity>
    ): Long {
        val expenseId = insertExpense(expense)
        val linkedParticipants = participants.map { it.copy(splitExpenseId = expenseId) }
        insertParticipants(linkedParticipants)
        return expenseId
    }

    @Transaction
    suspend fun updateSplitExpenseWithParticipants(
        expense: SplitExpenseEntity,
        participants: List<SplitParticipantEntity>
    ) {
        updateExpense(expense)
        deleteParticipantsByExpenseId(expense.id)
        val linkedParticipants = participants.map { it.copy(splitExpenseId = expense.id) }
        insertParticipants(linkedParticipants)
    }
}
