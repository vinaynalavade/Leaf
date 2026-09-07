package com.vinaynalavade.expensetracker.domain.repository

import com.vinaynalavade.expensetracker.core.result.AppResult
import com.vinaynalavade.expensetracker.domain.model.SettlementStatus
import com.vinaynalavade.expensetracker.domain.model.SplitExpense
import kotlinx.coroutines.flow.Flow

/**
 * Repository interface for managing split expenses and participant settlements.
 */
interface SplitRepository {

    /** Observes all split expenses in chronological order. */
    fun getAllSplitExpenses(): Flow<List<SplitExpense>>

    /** Observes a specific split expense by ID. */
    fun getSplitExpenseById(id: Long): Flow<SplitExpense?>

    /** Fetches a specific split expense synchronously / as a one-shot query. */
    suspend fun getSplitExpenseByIdOnce(id: Long): SplitExpense?

    /** Inserts a new split expense along with its participants. */
    suspend fun insertSplitExpense(splitExpense: SplitExpense): AppResult<Long>

    /** Updates an existing split expense and its participants. */
    suspend fun updateSplitExpense(splitExpense: SplitExpense): AppResult<Unit>

    /** Deletes a split expense and its associated participants. */
    suspend fun deleteSplitExpense(id: Long): AppResult<Unit>

    /** Updates the settlement state of an individual participant's share. */
    suspend fun updateParticipantSettlement(
        participantId: Long,
        status: SettlementStatus,
        paymentMethod: com.vinaynalavade.expensetracker.domain.model.PaymentMethod = com.vinaynalavade.expensetracker.domain.model.PaymentMethod.CASH,
        settledAt: Long? = if (status == SettlementStatus.SETTLED) System.currentTimeMillis() else null
    ): AppResult<Unit>
}
