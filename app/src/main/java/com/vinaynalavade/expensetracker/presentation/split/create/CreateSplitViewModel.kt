package com.vinaynalavade.expensetracker.presentation.split.create

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
import com.vinaynalavade.expensetracker.domain.model.PaymentMethod
import com.vinaynalavade.expensetracker.domain.model.SettlementStatus
import com.vinaynalavade.expensetracker.domain.model.SplitExpense
import com.vinaynalavade.expensetracker.domain.model.SplitMethod
import com.vinaynalavade.expensetracker.domain.model.SplitParticipant
import com.vinaynalavade.expensetracker.domain.model.TransactionType
import com.vinaynalavade.expensetracker.domain.split.CustomSplitValidation
import com.vinaynalavade.expensetracker.domain.split.SplitCalculationEngine
import com.vinaynalavade.expensetracker.domain.usecase.GetCategoriesUseCase
import com.vinaynalavade.expensetracker.domain.usecase.GetUserPreferencesUseCase
import com.vinaynalavade.expensetracker.domain.usecase.SaveSplitExpenseUseCase
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.firstOrNull
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch

data class CreateSplitUiState(
    val title: String = "",
    val amountInput: String = "",
    val totalAmount: Amount = Amount.ZERO,
    val date: Long = System.currentTimeMillis(),
    val selectedCategory: Category? = null,
    val availableCategories: List<Category> = emptyList(),
    val selectedGroupId: Long? = null,
    val availableGroups: List<com.vinaynalavade.expensetracker.domain.model.SplitGroup> = emptyList(),
    val paidBy: String = "Me",
    val participants: List<String> = listOf("Me"),
    val splitMethod: SplitMethod = SplitMethod.EQUAL,
    val customSharesInput: Map<String, String> = emptyMap(),
    val calculatedParticipants: List<SplitParticipant> = emptyList(),
    val customValidation: CustomSplitValidation = CustomSplitValidation(
        isValid = true,
        allocatedAmount = Amount.ZERO,
        remainingAmount = Amount.ZERO,
        overallocatedAmount = Amount.ZERO
    ),
    val qrImagePath: String? = null,
    val qrImageBitmap: ImageBitmap? = null,
    val addToTransactions: Boolean = false,
    val paymentMethod: PaymentMethod = PaymentMethod.CASH,
    val currentStep: Int = 1,
    val validationError: String? = null,
    val isSaving: Boolean = false,
    val currency: Currency = Currency.DEFAULT
) {
    val otherParticipants: List<SplitParticipant>
        get() = calculatedParticipants.filterNot { it.isCurrentUser }

    val userShare: Amount
        get() = calculatedParticipants.firstOrNull { it.isCurrentUser }?.amount ?: Amount.ZERO

    val toCollectAmount: Amount
        get() = Amount(otherParticipants.sumOf { it.amount.subunits })
}

class CreateSplitViewModel(
    private val saveSplitExpenseUseCase: SaveSplitExpenseUseCase,
    private val getCategoriesUseCase: GetCategoriesUseCase,
    private val getSplitGroupsUseCase: com.vinaynalavade.expensetracker.domain.usecase.GetSplitGroupsUseCase,
    private val getUserPreferencesUseCase: GetUserPreferencesUseCase,
    private val qrStorageManager: SplitQrStorageManager
) : ViewModel() {

    private val _uiState = MutableStateFlow(CreateSplitUiState())
    val uiState: StateFlow<CreateSplitUiState> = _uiState.asStateFlow()

    init {
        loadInitialData()
    }

    private fun loadInitialData() {
        viewModelScope.launch {
            val userPrefs = getUserPreferencesUseCase().firstOrNull()
            val currency = userPrefs?.currency ?: Currency.DEFAULT
            val defaultSource = userPrefs?.defaultExpenseSource ?: PaymentMethod.CASH
            val categories = getCategoriesUseCase().firstOrNull()?.filter { it.type == TransactionType.EXPENSE } ?: emptyList()
            val groups = getSplitGroupsUseCase().firstOrNull() ?: emptyList()
            val defaultCat = categories.firstOrNull { it.name.contains("Food", ignoreCase = true) } ?: categories.firstOrNull()

            _uiState.update {
                it.copy(
                    currency = currency,
                    paymentMethod = defaultSource,
                    availableCategories = categories,
                    availableGroups = groups,
                    selectedCategory = defaultCat
                )
            }
        }
    }

    fun onGroupSelect(groupId: Long?) {
        _uiState.update { it.copy(selectedGroupId = groupId) }
    }

    fun onAddToTransactionsChange(addToTransactions: Boolean) {
        _uiState.update { it.copy(addToTransactions = addToTransactions) }
    }

    fun onPaymentMethodChange(paymentMethod: PaymentMethod) {
        _uiState.update { it.copy(paymentMethod = paymentMethod) }
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
            return // Cannot remove current user/payer
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

        if (state.splitMethod == SplitMethod.EQUAL) {
            val calculated = SplitCalculationEngine.calculateEqualSplit(
                totalAmount = totalAmount,
                participants = participants,
                payerName = state.paidBy
            )
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
            // Custom Split Mode
            var allocatedSubunits = 0L
            val participantList = participants.map { name ->
                val input = state.customSharesInput[name] ?: ""
                val shareAmount = Amount.fromStringOrNull(input, currency) ?: Amount.ZERO
                allocatedSubunits += shareAmount.subunits
                val isCurrentUser = name.equals("Me", ignoreCase = true) || name.equals(state.paidBy, ignoreCase = true)
                SplitParticipant(
                    name = name,
                    isCurrentUser = isCurrentUser,
                    amount = shareAmount,
                    settlementStatus = SettlementStatus.PENDING
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
            } else {
                _uiState.update { it.copy(validationError = "Unable to process selected image.") }
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

    fun onNextStep(): Boolean {
        val state = _uiState.value
        when (state.currentStep) {
            1 -> {
                if (state.title.isBlank()) {
                    _uiState.update { it.copy(validationError = "Please enter an expense name.") }
                    return false
                }
                if (state.totalAmount.subunits <= 0L) {
                    _uiState.update { it.copy(validationError = "Please enter an amount greater than 0.") }
                    return false
                }
                _uiState.update { it.copy(currentStep = 2, validationError = null) }
                return true
            }
            2 -> {
                if (state.participants.size < 2) {
                    _uiState.update { it.copy(validationError = "Please add at least one other participant.") }
                    return false
                }
                recalculateShares()
                _uiState.update { it.copy(currentStep = 3, validationError = null) }
                return true
            }
            3 -> {
                if (state.splitMethod == SplitMethod.CUSTOM && !state.customValidation.isValid) {
                    _uiState.update { it.copy(validationError = "Allocated shares must exactly equal total expense.") }
                    return false
                }
                _uiState.update { it.copy(currentStep = 4, validationError = null) }
                return true
            }
            4 -> {
                _uiState.update { it.copy(currentStep = 5, validationError = null) }
                return true
            }
            else -> return true
        }
    }

    fun onPreviousStep(): Boolean {
        val current = _uiState.value.currentStep
        if (current > 1) {
            _uiState.update { it.copy(currentStep = current - 1, validationError = null) }
            return true
        }
        return false
    }

    fun saveSplitExpense(onSuccess: (Long) -> Unit) {
        val state = _uiState.value
        if (state.title.isBlank() || state.totalAmount.subunits <= 0L || state.participants.size < 2) {
            _uiState.update { it.copy(validationError = "Please complete all required fields.") }
            return
        }

        if (state.splitMethod == SplitMethod.CUSTOM && !state.customValidation.isValid) {
            _uiState.update { it.copy(validationError = "Allocated shares must equal total amount.") }
            return
        }

        _uiState.update { it.copy(isSaving = true) }

        viewModelScope.launch {
            val expense = SplitExpense(
                title = state.title.trim(),
                totalAmount = state.totalAmount,
                date = state.date,
                categoryId = state.selectedCategory?.id ?: 1L,
                groupId = state.selectedGroupId,
                paidBy = state.paidBy,
                splitMethod = state.splitMethod,
                qrImagePath = state.qrImagePath,
                addToTransactions = state.addToTransactions,
                paymentMethod = state.paymentMethod,
                participants = state.calculatedParticipants,
                createdAt = state.date,
                updatedAt = System.currentTimeMillis()
            )

            when (val result = saveSplitExpenseUseCase(expense)) {
                is AppResult.Success -> {
                    _uiState.update { it.copy(isSaving = false) }
                    onSuccess(result.data)
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
        private val saveSplitExpenseUseCase: SaveSplitExpenseUseCase,
        private val getCategoriesUseCase: GetCategoriesUseCase,
        private val getSplitGroupsUseCase: com.vinaynalavade.expensetracker.domain.usecase.GetSplitGroupsUseCase,
        private val getUserPreferencesUseCase: GetUserPreferencesUseCase,
        private val qrStorageManager: SplitQrStorageManager
    ) : ViewModelProvider.Factory {
        @Suppress("UNCHECKED_CAST")
        override fun <T : ViewModel> create(modelClass: Class<T>): T {
            return CreateSplitViewModel(
                saveSplitExpenseUseCase,
                getCategoriesUseCase,
                getSplitGroupsUseCase,
                getUserPreferencesUseCase,
                qrStorageManager
            ) as T
        }
    }
}
