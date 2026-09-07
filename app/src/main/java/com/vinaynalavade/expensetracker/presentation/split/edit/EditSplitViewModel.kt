package com.vinaynalavade.expensetracker.presentation.split.edit

import android.net.Uri
import androidx.compose.ui.graphics.ImageBitmap
import androidx.lifecycle.ViewModel
import androidx.lifecycle.ViewModelProvider
import androidx.lifecycle.viewModelScope
import com.vinaynalavade.expensetracker.core.model.Amount
import com.vinaynalavade.expensetracker.core.model.Currency
import com.vinaynalavade.expensetracker.core.result.AppResult
import com.vinaynalavade.expensetracker.core.storage.SplitQrStorageManager
import com.vinaynalavade.expensetracker.domain.model.Category
import com.vinaynalavade.expensetracker.domain.model.SettlementStatus
import com.vinaynalavade.expensetracker.domain.model.SplitExpense
import com.vinaynalavade.expensetracker.domain.model.SplitMethod
import com.vinaynalavade.expensetracker.domain.model.SplitParticipant
import com.vinaynalavade.expensetracker.domain.model.TransactionType
import com.vinaynalavade.expensetracker.domain.split.CustomSplitValidation
import com.vinaynalavade.expensetracker.domain.split.SplitCalculationEngine
import com.vinaynalavade.expensetracker.domain.usecase.GetCategoriesUseCase
import com.vinaynalavade.expensetracker.domain.usecase.GetSplitExpenseByIdUseCase
import com.vinaynalavade.expensetracker.domain.usecase.GetUserPreferencesUseCase
import com.vinaynalavade.expensetracker.domain.usecase.UpdateSplitExpenseUseCase
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.firstOrNull
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch

data class EditSplitUiState(
    val splitId: Long = 0L,
    val title: String = "",
    val amountInput: String = "",
    val totalAmount: Amount = Amount.ZERO,
    val date: Long = System.currentTimeMillis(),
    val selectedCategory: Category? = null,
    val availableCategories: List<Category> = emptyList(),
    val paidBy: String = "Me",
    val participants: List<String> = emptyList(),
    val splitMethod: SplitMethod = SplitMethod.EQUAL,
    val customSharesInput: Map<String, String> = emptyMap(),
    val calculatedParticipants: List<SplitParticipant> = emptyList(),
    val existingSettlements: Map<String, SettlementStatus> = emptyMap(),
    val customValidation: CustomSplitValidation = CustomSplitValidation(
        isValid = true,
        allocatedAmount = Amount.ZERO,
        remainingAmount = Amount.ZERO,
        overallocatedAmount = Amount.ZERO
    ),
    val qrImagePath: String? = null,
    val qrImageBitmap: ImageBitmap? = null,
    val validationError: String? = null,
    val isSaving: Boolean = false,
    val isLoading: Boolean = true,
    val currency: Currency = Currency.DEFAULT
)

class EditSplitViewModel(
    private val splitId: Long,
    private val getSplitExpenseByIdUseCase: GetSplitExpenseByIdUseCase,
    private val updateSplitExpenseUseCase: UpdateSplitExpenseUseCase,
    private val getCategoriesUseCase: GetCategoriesUseCase,
    private val getUserPreferencesUseCase: GetUserPreferencesUseCase,
    private val qrStorageManager: SplitQrStorageManager
) : ViewModel() {

    private val _uiState = MutableStateFlow(EditSplitUiState(splitId = splitId))
    val uiState: StateFlow<EditSplitUiState> = _uiState.asStateFlow()

    init {
        loadData()
    }

    private fun loadData() {
        viewModelScope.launch {
            val userPrefs = getUserPreferencesUseCase().firstOrNull()
            val currency = userPrefs?.currency ?: Currency.DEFAULT
            val categories = getCategoriesUseCase().firstOrNull()?.filter { it.type == TransactionType.EXPENSE } ?: emptyList()
            val expense = getSplitExpenseByIdUseCase.getOnce(splitId)

            if (expense != null) {
                val bitmap = if (expense.qrImagePath != null) {
                    qrStorageManager.loadQrBitmap(expense.qrImagePath)
                } else null

                val participantNames = expense.participants.map { it.name }
                val customMap = expense.participants.associate { it.name to it.amount.toInputString(currency) }
                val settlements = expense.participants.associate { it.name to it.settlementStatus }

                _uiState.update {
                    it.copy(
                        title = expense.title,
                        amountInput = expense.totalAmount.toInputString(currency),
                        totalAmount = expense.totalAmount,
                        date = expense.date,
                        selectedCategory = categories.firstOrNull { c -> c.id == expense.categoryId } ?: categories.firstOrNull(),
                        availableCategories = categories,
                        paidBy = expense.paidBy,
                        participants = participantNames,
                        splitMethod = expense.splitMethod,
                        customSharesInput = customMap,
                        calculatedParticipants = expense.participants,
                        existingSettlements = settlements,
                        qrImagePath = expense.qrImagePath,
                        qrImageBitmap = bitmap,
                        isLoading = false,
                        currency = currency
                    )
                }
            } else {
                _uiState.update { it.copy(isLoading = false, validationError = "Split expense not found.") }
            }
        }
    }

    fun onTitleChange(newTitle: String) {
        _uiState.update { it.copy(title = newTitle, validationError = null) }
    }

    fun onAmountChange(newAmount: String) {
        val clean = newAmount.filter { it.isDigit() || it == '.' }
        val parsedAmount = Amount.fromStringOrNull(clean, _uiState.value.currency) ?: Amount.ZERO
        _uiState.update {
            it.copy(
                amountInput = clean,
                totalAmount = parsedAmount,
                validationError = null
            )
        }
        recalculateShares()
    }

    fun onDateChange(newDate: Long) {
        _uiState.update { it.copy(date = newDate) }
    }

    fun onCategorySelect(category: Category) {
        _uiState.update { it.copy(selectedCategory = category) }
    }

    fun onAddParticipant(name: String) {
        val trimmed = name.trim()
        if (trimmed.isBlank()) return
        val currentList = _uiState.value.participants
        if (currentList.any { it.equals(trimmed, ignoreCase = true) }) {
            _uiState.update { it.copy(validationError = "Participant already added.") }
            return
        }
        val newList = currentList + trimmed
        _uiState.update { it.copy(participants = newList, validationError = null) }
        recalculateShares()
    }

    fun onRemoveParticipant(name: String) {
        if (name.equals("Me", ignoreCase = true) || name.equals(_uiState.value.paidBy, ignoreCase = true)) {
            return
        }
        val newList = _uiState.value.participants.filterNot { it.equals(name, ignoreCase = true) }
        val newCustomMap = _uiState.value.customSharesInput.filterKeys { !it.equals(name, ignoreCase = true) }
        _uiState.update {
            it.copy(
                participants = newList,
                customSharesInput = newCustomMap,
                validationError = null
            )
        }
        recalculateShares()
    }

    fun onSplitMethodChange(method: SplitMethod) {
        _uiState.update { it.copy(splitMethod = method, validationError = null) }
        recalculateShares()
    }

    fun onCustomShareChange(name: String, amountStr: String) {
        val clean = amountStr.filter { it.isDigit() || it == '.' }
        val updatedMap = _uiState.value.customSharesInput.toMutableMap().apply {
            put(name, clean)
        }
        _uiState.update { it.copy(customSharesInput = updatedMap) }
        recalculateShares()
    }

    private fun recalculateShares() {
        val state = _uiState.value
        val totalAmount = state.totalAmount
        val participants = state.participants
        val currency = state.currency
        val settlements = state.existingSettlements

        if (state.splitMethod == SplitMethod.EQUAL) {
            val calculated = SplitCalculationEngine.calculateEqualSplit(
                totalAmount = totalAmount,
                participants = participants,
                payerName = state.paidBy
            ).map { p ->
                val prevStatus = settlements[p.name] ?: SettlementStatus.PENDING
                p.copy(settlementStatus = prevStatus)
            }

            _uiState.update {
                it.copy(
                    calculatedParticipants = calculated,
                    customValidation = CustomSplitValidation(
                        isValid = true,
                        allocatedAmount = totalAmount,
                        remainingAmount = Amount.ZERO,
                        overallocatedAmount = Amount.ZERO
                    )
                )
            }
        } else {
            var allocatedSubunits = 0L
            val participantList = participants.map { name ->
                val input = state.customSharesInput[name] ?: ""
                val shareAmount = Amount.fromStringOrNull(input, currency) ?: Amount.ZERO
                allocatedSubunits += shareAmount.subunits
                val isCurrentUser = name.equals("Me", ignoreCase = true) || name.equals(state.paidBy, ignoreCase = true)
                val prevStatus = settlements[name] ?: SettlementStatus.PENDING
                SplitParticipant(
                    name = name,
                    isCurrentUser = isCurrentUser,
                    amount = shareAmount,
                    settlementStatus = prevStatus
                )
            }

            val validation = SplitCalculationEngine.validateCustomSplit(totalAmount, allocatedSubunits)
            _uiState.update {
                it.copy(
                    calculatedParticipants = participantList,
                    customValidation = validation
                )
            }
        }
    }

    fun onQrImageSelected(uri: Uri) {
        viewModelScope.launch {
            val savedPath = qrStorageManager.saveQrImage(uri)
            if (savedPath != null) {
                val bitmap = qrStorageManager.loadQrBitmap(savedPath)
                _uiState.update {
                    it.copy(
                        qrImagePath = savedPath,
                        qrImageBitmap = bitmap,
                        validationError = null
                    )
                }
            }
        }
    }

    fun onRemoveQrImage() {
        viewModelScope.launch {
            _uiState.value.qrImagePath?.let { path ->
                qrStorageManager.deleteQrImage(path)
            }
            _uiState.update {
                it.copy(
                    qrImagePath = null,
                    qrImageBitmap = null
                )
            }
        }
    }

    fun saveChanges(onSuccess: () -> Unit) {
        val state = _uiState.value
        if (state.title.isBlank()) {
            _uiState.update { it.copy(validationError = "Please enter an expense name.") }
            return
        }
        if (state.totalAmount.subunits <= 0L) {
            _uiState.update { it.copy(validationError = "Please enter an amount greater than 0.") }
            return
        }
        if (state.participants.size < 2) {
            _uiState.update { it.copy(validationError = "Please add at least one other participant.") }
            return
        }
        if (state.splitMethod == SplitMethod.CUSTOM && !state.customValidation.isValid) {
            _uiState.update { it.copy(validationError = "Allocated shares must exactly equal total expense.") }
            return
        }

        _uiState.update { it.copy(isSaving = true) }

        viewModelScope.launch {
            val updatedExpense = SplitExpense(
                id = state.splitId,
                title = state.title.trim(),
                totalAmount = state.totalAmount,
                date = state.date,
                categoryId = state.selectedCategory?.id ?: 1L,
                paidBy = state.paidBy,
                splitMethod = state.splitMethod,
                qrImagePath = state.qrImagePath,
                participants = state.calculatedParticipants,
                createdAt = state.date,
                updatedAt = System.currentTimeMillis()
            )

            when (val result = updateSplitExpenseUseCase(updatedExpense)) {
                is AppResult.Success -> {
                    _uiState.update { it.copy(isSaving = false) }
                    onSuccess()
                }
                is AppResult.Error -> {
                    _uiState.update {
                        it.copy(
                            isSaving = false,
                            validationError = result.error.userMessage
                        )
                    }
                }
            }
        }
    }

    class Factory(
        private val splitId: Long,
        private val getSplitExpenseByIdUseCase: GetSplitExpenseByIdUseCase,
        private val updateSplitExpenseUseCase: UpdateSplitExpenseUseCase,
        private val getCategoriesUseCase: GetCategoriesUseCase,
        private val getUserPreferencesUseCase: GetUserPreferencesUseCase,
        private val qrStorageManager: SplitQrStorageManager
    ) : ViewModelProvider.Factory {
        @Suppress("UNCHECKED_CAST")
        override fun <T : ViewModel> create(modelClass: Class<T>): T {
            return EditSplitViewModel(
                splitId,
                getSplitExpenseByIdUseCase,
                updateSplitExpenseUseCase,
                getCategoriesUseCase,
                getUserPreferencesUseCase,
                qrStorageManager
            ) as T
        }
    }
}
