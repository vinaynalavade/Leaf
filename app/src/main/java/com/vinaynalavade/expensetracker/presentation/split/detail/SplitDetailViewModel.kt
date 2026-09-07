package com.vinaynalavade.expensetracker.presentation.split.detail

import android.content.Context
import androidx.compose.ui.graphics.ImageBitmap
import androidx.lifecycle.ViewModel
import androidx.lifecycle.ViewModelProvider
import androidx.lifecycle.viewModelScope
import com.vinaynalavade.expensetracker.core.model.Currency
import com.vinaynalavade.expensetracker.core.share.WhatsAppShareHelper
import com.vinaynalavade.expensetracker.core.storage.SplitQrStorageManager
import com.vinaynalavade.expensetracker.domain.model.PaymentMethod
import com.vinaynalavade.expensetracker.domain.model.SettlementStatus
import com.vinaynalavade.expensetracker.domain.model.SplitExpense
import com.vinaynalavade.expensetracker.domain.model.SplitParticipant
import com.vinaynalavade.expensetracker.domain.usecase.DeleteSplitExpenseUseCase
import com.vinaynalavade.expensetracker.domain.usecase.GetSplitExpenseByIdUseCase
import com.vinaynalavade.expensetracker.domain.usecase.GetUserPreferencesUseCase
import com.vinaynalavade.expensetracker.domain.usecase.UpdateParticipantSettlementUseCase
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.launchIn
import kotlinx.coroutines.flow.onEach
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch

data class SplitDetailUiState(
    val splitExpense: SplitExpense? = null,
    val qrImageBitmap: ImageBitmap? = null,
    val currency: Currency = Currency.DEFAULT,
    val isLoading: Boolean = true,
    val selectedParticipantForSettle: SplitParticipant? = null,
    val settlePaymentMethod: PaymentMethod = PaymentMethod.CASH,
    val showDeleteConfirmDialog: Boolean = false,
    val isDeleting: Boolean = false
)

class SplitDetailViewModel(
    private val splitId: Long,
    private val getSplitExpenseByIdUseCase: GetSplitExpenseByIdUseCase,
    private val updateParticipantSettlementUseCase: UpdateParticipantSettlementUseCase,
    private val deleteSplitExpenseUseCase: DeleteSplitExpenseUseCase,
    private val qrStorageManager: SplitQrStorageManager,
    private val getUserPreferencesUseCase: GetUserPreferencesUseCase
) : ViewModel() {

    private val _uiState = MutableStateFlow(SplitDetailUiState())
    val uiState: StateFlow<SplitDetailUiState> = _uiState.asStateFlow()

    init {
        loadData()
    }

    private fun loadData() {
        combine(
            getSplitExpenseByIdUseCase(splitId),
            getUserPreferencesUseCase()
        ) { expense, prefs ->
            val bitmap = if (expense?.qrImagePath != null) {
                qrStorageManager.loadQrBitmap(expense.qrImagePath)
            } else {
                null
            }

            _uiState.update {
                it.copy(
                    splitExpense = expense,
                    qrImageBitmap = bitmap,
                    currency = prefs.currency,
                    settlePaymentMethod = prefs.defaultIncomeSource,
                    isLoading = false
                )
            }
        }.launchIn(viewModelScope)
    }

    fun onMarkSettledClick(participant: SplitParticipant) {
        _uiState.update { it.copy(selectedParticipantForSettle = participant) }
    }

    fun onSettlePaymentMethodSelect(method: PaymentMethod) {
        _uiState.update { it.copy(settlePaymentMethod = method) }
    }

    fun dismissSettleDialog() {
        _uiState.update { it.copy(selectedParticipantForSettle = null) }
    }

    fun confirmSettle() {
        val participant = _uiState.value.selectedParticipantForSettle ?: return
        val paymentMethod = _uiState.value.settlePaymentMethod
        viewModelScope.launch {
            updateParticipantSettlementUseCase(
                participantId = participant.id,
                status = SettlementStatus.SETTLED,
                paymentMethod = paymentMethod
            )
            _uiState.update { it.copy(selectedParticipantForSettle = null) }
        }
    }

    fun onMarkPendingClick(participant: SplitParticipant) {
        viewModelScope.launch {
            updateParticipantSettlementUseCase(
                participantId = participant.id,
                status = SettlementStatus.PENDING
            )
        }
    }

    fun onShareWhatsApp(
        context: Context,
        participant: SplitParticipant? = null,
        isConsolidated: Boolean = false
    ) {
        val expense = _uiState.value.splitExpense ?: return
        val currency = _uiState.value.currency

        val message = if (isConsolidated) {
            val nonPayerShare = expense.otherParticipants.firstOrNull()?.amount ?: expense.totalAmount
            WhatsAppShareHelper.createShareMessage(
                expenseTitle = expense.title,
                participantName = null,
                amount = nonPayerShare,
                currency = currency,
                isConsolidated = true
            )
        } else {
            val personName = participant?.name ?: ""
            val personAmount = participant?.amount ?: expense.totalAmount
            WhatsAppShareHelper.createShareMessage(
                expenseTitle = expense.title,
                participantName = personName,
                amount = personAmount,
                currency = currency,
                isConsolidated = false
            )
        }

        val qrUri = qrStorageManager.getShareableUri(expense.qrImagePath)
        WhatsAppShareHelper.sharePaymentReminder(
            context = context,
            message = message,
            qrImageUri = qrUri
        )
    }

    fun onDeleteClick() {
        _uiState.update { it.copy(showDeleteConfirmDialog = true) }
    }

    fun dismissDeleteDialog() {
        _uiState.update { it.copy(showDeleteConfirmDialog = false) }
    }

    fun confirmDelete(onSuccess: () -> Unit) {
        val expense = _uiState.value.splitExpense ?: return
        _uiState.update { it.copy(isDeleting = true, showDeleteConfirmDialog = false) }
        viewModelScope.launch {
            deleteSplitExpenseUseCase(expense)
            onSuccess()
        }
    }

    class Factory(
        private val splitId: Long,
        private val getSplitExpenseByIdUseCase: GetSplitExpenseByIdUseCase,
        private val updateParticipantSettlementUseCase: UpdateParticipantSettlementUseCase,
        private val deleteSplitExpenseUseCase: DeleteSplitExpenseUseCase,
        private val qrStorageManager: SplitQrStorageManager,
        private val getUserPreferencesUseCase: GetUserPreferencesUseCase
    ) : ViewModelProvider.Factory {
        @Suppress("UNCHECKED_CAST")
        override fun <T : ViewModel> create(modelClass: Class<T>): T {
            return SplitDetailViewModel(
                splitId,
                getSplitExpenseByIdUseCase,
                updateParticipantSettlementUseCase,
                deleteSplitExpenseUseCase,
                qrStorageManager,
                getUserPreferencesUseCase
            ) as T
        }
    }
}
