package com.vinaynalavade.expensetracker.domain.usecase

import com.vinaynalavade.expensetracker.core.result.AppResult
import com.vinaynalavade.expensetracker.core.storage.SplitQrStorageManager
import com.vinaynalavade.expensetracker.domain.model.SettlementStatus
import com.vinaynalavade.expensetracker.domain.model.SplitExpense
import com.vinaynalavade.expensetracker.domain.repository.SplitRepository
import kotlinx.coroutines.flow.Flow

class GetSplitExpensesUseCase(
    private val splitRepository: SplitRepository
) {
    operator fun invoke(): Flow<List<SplitExpense>> = splitRepository.getAllSplitExpenses()
}

class GetSplitExpenseByIdUseCase(
    private val splitRepository: SplitRepository
) {
    operator fun invoke(id: Long): Flow<SplitExpense?> = splitRepository.getSplitExpenseById(id)

    suspend fun getOnce(id: Long): SplitExpense? = splitRepository.getSplitExpenseByIdOnce(id)
}

class SaveSplitExpenseUseCase(
    private val splitRepository: SplitRepository
) {
    suspend operator fun invoke(splitExpense: SplitExpense): AppResult<Long> =
        splitRepository.insertSplitExpense(splitExpense)
}

class UpdateSplitExpenseUseCase(
    private val splitRepository: SplitRepository
) {
    suspend operator fun invoke(splitExpense: SplitExpense): AppResult<Unit> =
        splitRepository.updateSplitExpense(splitExpense)
}

class DeleteSplitExpenseUseCase(
    private val splitRepository: SplitRepository,
    private val qrStorageManager: SplitQrStorageManager
) {
    suspend operator fun invoke(splitExpense: SplitExpense): AppResult<Unit> {
        splitExpense.qrImagePath?.let { path ->
            qrStorageManager.deleteQrImage(path)
        }
        return splitRepository.deleteSplitExpense(splitExpense.id)
    }
}

class UpdateParticipantSettlementUseCase(
    private val splitRepository: SplitRepository
) {
    suspend operator fun invoke(
        participantId: Long,
        status: SettlementStatus,
        settledAt: Long? = if (status == SettlementStatus.SETTLED) System.currentTimeMillis() else null
    ): AppResult<Unit> = splitRepository.updateParticipantSettlement(participantId, status, settledAt)
}
