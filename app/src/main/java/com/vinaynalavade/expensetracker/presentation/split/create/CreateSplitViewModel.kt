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
import com.vinaynalavade.expensetracker.domain.model.ItemizedSplitData
import com.vinaynalavade.expensetracker.domain.model.PaymentMethod
import com.vinaynalavade.expensetracker.domain.model.SettlementStatus
import com.vinaynalavade.expensetracker.domain.model.SplitExpense
import com.vinaynalavade.expensetracker.domain.model.SplitItem
import com.vinaynalavade.expensetracker.domain.model.SplitMethod
import com.vinaynalavade.expensetracker.domain.model.SplitParticipant
import com.vinaynalavade.expensetracker.domain.model.TransactionType
import com.vinaynalavade.expensetracker.domain.split.CustomSplitValidation
import com.vinaynalavade.expensetracker.domain.split.ItemizedSplitCalculationResult
import com.vinaynalavade.expensetracker.domain.split.SplitCalculationEngine
import com.vinaynalavade.expensetracker.domain.split.SplitItemJsonAdapter
import com.vinaynalavade.expensetracker.domain.usecase.GetCategoriesUseCase
import com.vinaynalavade.expensetracker.domain.usecase.GetUserPreferencesUseCase
import com.vinaynalavade.expensetracker.domain.usecase.SaveSplitExpenseUseCase
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.firstOrNull
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import java.util.UUID

enum class CustomSplitSubMode {
    ITEMIZED,
    DIRECT
}

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
    val participantPhoneNumbers: Map<String, String?> = emptyMap(),
    val splitMethod: SplitMethod = SplitMethod.EQUAL,
    val customSplitSubMode: CustomSplitSubMode = CustomSplitSubMode.ITEMIZED,
    val items: List<SplitItem> = emptyList(),
    val sharedRemainingParticipants: List<String> = listOf("Me"),
    val itemizedCalculation: ItemizedSplitCalculationResult? = null,
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

    fun onAddParticipant(name: String, phoneNumber: String? = null) {
        val trimmed = name.trim()
        if (trimmed.isBlank()) return
        val currentList = _uiState.value.participants
        if (currentList.any { it.equals(trimmed, ignoreCase = true) }) {
            // Update phone number if provided and not previously recorded
            if (!phoneNumber.isNullOrBlank()) {
                val updatedPhoneMap = _uiState.value.participantPhoneNumbers.toMutableMap()
                val existingName = currentList.first { it.equals(trimmed, ignoreCase = true) }
                updatedPhoneMap[existingName] = phoneNumber.trim()
                _uiState.update { it.copy(participantPhoneNumbers = updatedPhoneMap) }
            }
            return
        }
        val newList = currentList + trimmed
        val updatedPhoneMap = _uiState.value.participantPhoneNumbers.toMutableMap()
        if (!phoneNumber.isNullOrBlank()) {
            updatedPhoneMap[trimmed] = phoneNumber.trim()
        }

        val currentShared = _uiState.value.sharedRemainingParticipants
        val shouldAddToShared = currentShared.isEmpty() || currentShared.size >= currentList.size
        val updatedShared = if (shouldAddToShared) currentShared + trimmed else currentShared

        _uiState.update {
            it.copy(
                participants = newList,
                participantPhoneNumbers = updatedPhoneMap,
                sharedRemainingParticipants = updatedShared,
                validationError = null
            )
        }
        recalculateShares()
    }

    fun onRemoveParticipant(name: String) {
        if (name.equals("Me", ignoreCase = true) || name.equals(_uiState.value.paidBy, ignoreCase = true)) {
            return // Cannot remove current user/payer
        }
        val newList = _uiState.value.participants.filterNot { it.equals(name, ignoreCase = true) }
        val newCustomMap = _uiState.value.customSharesInput.filterKeys { !it.equals(name, ignoreCase = true) }
        val newPhoneMap = _uiState.value.participantPhoneNumbers.filterKeys { !it.equals(name, ignoreCase = true) }
        val newShared = _uiState.value.sharedRemainingParticipants.filterNot { it.equals(name, ignoreCase = true) }

        // Remove participant from items safely
        val updatedItems = _uiState.value.items.map { item ->
            item.copy(
                participantNames = item.participantNames.filterNot { it.equals(name, ignoreCase = true) },
                customAllocations = item.customAllocations.filterKeys { !it.equals(name, ignoreCase = true) },
                customAllocationInputs = item.customAllocationInputs.filterKeys { !it.equals(name, ignoreCase = true) }
            )
        }

        _uiState.update {
            it.copy(
                participants = newList,
                participantPhoneNumbers = newPhoneMap,
                customSharesInput = newCustomMap,
                items = updatedItems,
                sharedRemainingParticipants = newShared,
                validationError = null
            )
        }
        recalculateShares()
    }

    fun onSplitMethodChange(method: SplitMethod) {
        val currentShared = _uiState.value.sharedRemainingParticipants
        val updatedShared = if (currentShared.isEmpty()) _uiState.value.participants else currentShared
        _uiState.update {
            it.copy(
                splitMethod = method,
                sharedRemainingParticipants = updatedShared,
                validationError = null
            )
        }
        recalculateShares()
    }

    fun onCustomSplitSubModeChange(mode: CustomSplitSubMode) {
        _uiState.update { it.copy(customSplitSubMode = mode, validationError = null) }
        recalculateShares()
    }

    // --- Item-Based Custom Split Actions ---

    fun onAddItem() {
        val currentItems = _uiState.value.items
        val nextIndex = currentItems.size + 1
        val newItem = SplitItem(
            id = UUID.randomUUID().toString(),
            name = "Item $nextIndex",
            amount = Amount.ZERO,
            amountInput = "",
            participantNames = _uiState.value.participants.take(1) // Defaults to current user
        )
        _uiState.update { it.copy(items = currentItems + newItem) }
        recalculateShares()
    }

    fun onRemoveItem(itemId: String) {
        val updated = _uiState.value.items.filterNot { it.id == itemId }
        _uiState.update { it.copy(items = updated) }
        recalculateShares()
    }

    fun onUpdateItemName(itemId: String, name: String) {
        val updated = _uiState.value.items.map { item ->
            if (item.id == itemId) item.copy(name = name) else item
        }
        _uiState.update { it.copy(items = updated) }
    }

    fun onUpdateItemAmount(itemId: String, amountStr: String) {
        val clean = amountStr.filter { it.isDigit() || it == '.' }
        val parsed = Amount.fromStringOrNull(clean, _uiState.value.currency) ?: Amount.ZERO
        val updated = _uiState.value.items.map { item ->
            if (item.id == itemId) item.copy(amount = parsed, amountInput = clean) else item
        }
        _uiState.update { it.copy(items = updated) }
        recalculateShares()
    }

    fun onToggleItemConsumer(itemId: String, participantName: String) {
        val updated = _uiState.value.items.map { item ->
            if (item.id == itemId) {
                val exists = item.participantNames.any { it.equals(participantName, ignoreCase = true) }
                val newConsumers = if (exists) {
                    item.participantNames.filterNot { it.equals(participantName, ignoreCase = true) }
                } else {
                    item.participantNames + participantName
                }
                val newAllocations = item.customAllocations.filterKeys { k ->
                    newConsumers.any { it.equals(k, ignoreCase = true) }
                }
                val newInputs = item.customAllocationInputs.filterKeys { k ->
                    newConsumers.any { it.equals(k, ignoreCase = true) }
                }
                item.copy(
                    participantNames = newConsumers,
                    customAllocations = newAllocations,
                    customAllocationInputs = newInputs
                )
            } else item
        }
        _uiState.update { it.copy(items = updated) }
        recalculateShares()
    }

    fun onToggleItemCustomAllocation(itemId: String, isCustom: Boolean) {
        val updated = _uiState.value.items.map { item ->
            if (item.id == itemId) item.copy(isCustomAllocation = isCustom) else item
        }
        _uiState.update { it.copy(items = updated) }
        recalculateShares()
    }

    fun onUpdateItemCustomShare(itemId: String, participantName: String, amountStr: String) {
        val clean = amountStr.filter { it.isDigit() || it == '.' }
        val parsed = Amount.fromStringOrNull(clean, _uiState.value.currency) ?: Amount.ZERO
        val updated = _uiState.value.items.map { item ->
            if (item.id == itemId) {
                val newAllocations = item.customAllocations.toMutableMap().apply { put(participantName, parsed) }
                val newInputs = item.customAllocationInputs.toMutableMap().apply { put(participantName, clean) }
                item.copy(customAllocations = newAllocations, customAllocationInputs = newInputs)
            } else item
        }
        _uiState.update { it.copy(items = updated) }
        recalculateShares()
    }

    fun onToggleSharedRemainingParticipant(participantName: String) {
        val current = _uiState.value.sharedRemainingParticipants
        val updated = if (current.any { it.equals(participantName, ignoreCase = true) }) {
            current.filterNot { it.equals(participantName, ignoreCase = true) }
        } else {
            current + participantName
        }
        _uiState.update { it.copy(sharedRemainingParticipants = updated) }
        recalculateShares()
    }

    fun onDistributeSharedRemainingToAll() {
        val allParticipants = _uiState.value.participants
        _uiState.update { it.copy(sharedRemainingParticipants = allParticipants) }
        recalculateShares()
    }

    fun onClearSharedRemaining() {
        _uiState.update { it.copy(sharedRemainingParticipants = emptyList()) }
        recalculateShares()
    }

    // --- Direct Per-Person Custom Actions ---

    fun onCustomShareChange(name: String, amountStr: String) {
        val clean = amountStr.filter { it.isDigit() || it == '.' }
        val updatedMap = _uiState.value.customSharesInput.toMutableMap().apply {
            put(name, clean)
        }
        _uiState.update { it.copy(customSharesInput = updatedMap) }
        recalculateShares()
    }

    // --- Live Recalculation Engine ---

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
            ).map { p ->
                p.copy(phoneNumber = state.participantPhoneNumbers[p.name])
            }
            _uiState.update {
                it.copy(
                    calculatedParticipants = calculated,
                    customValidation = CustomSplitValidation(
                        isValid = true,
                        allocatedAmount = totalAmount,
                        remainingAmount = Amount.ZERO,
                        overallocatedAmount = Amount.ZERO
                    ),
                    itemizedCalculation = null
                )
            }
        } else if (state.customSplitSubMode == CustomSplitSubMode.ITEMIZED) {
            val itemizedResult = SplitCalculationEngine.calculateItemizedSplit(
                totalBill = totalAmount,
                participants = participants,
                items = state.items,
                sharedRemainingParticipants = state.sharedRemainingParticipants
            )
            val participantList = participants.map { name ->
                val share = itemizedResult.participantShares[name] ?: Amount.ZERO
                val isCurrentUser = name.equals("Me", ignoreCase = true) || name.equals(state.paidBy, ignoreCase = true)
                SplitParticipant(
                    name = name,
                    isCurrentUser = isCurrentUser,
                    amount = share,
                    settlementStatus = SettlementStatus.PENDING,
                    phoneNumber = state.participantPhoneNumbers[name]
                )
            }
            _uiState.update {
                it.copy(
                    calculatedParticipants = participantList,
                    customValidation = CustomSplitValidation(
                        isValid = itemizedResult.isValid,
                        allocatedAmount = itemizedResult.totalAllocatedAmount,
                        remainingAmount = itemizedResult.unallocatedRemainingAmount,
                        overallocatedAmount = itemizedResult.overallocatedAmount,
                        errorMessage = itemizedResult.errorMessage
                    ),
                    itemizedCalculation = itemizedResult
                )
            }
        } else {
            // Direct per-person custom mode
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
                    settlementStatus = SettlementStatus.PENDING,
                    phoneNumber = state.participantPhoneNumbers[name]
                )
            }

            val validation = SplitCalculationEngine.validateCustomSplit(totalAmount, allocatedSubunits)
            _uiState.update {
                it.copy(
                    calculatedParticipants = participantList,
                    customValidation = validation,
                    itemizedCalculation = null
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
                    val errorMsg = state.customValidation.errorMessage
                        ?: "Allocated shares must exactly equal total bill."
                    _uiState.update { it.copy(validationError = errorMsg) }
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
            _uiState.update { it.copy(validationError = state.customValidation.errorMessage ?: "Allocated shares must equal total amount.") }
            return
        }

        _uiState.update { it.copy(isSaving = true) }

        viewModelScope.launch {
            val resolvedCategoryId = state.selectedCategory?.id
                ?: state.availableCategories.firstOrNull()?.id
                ?: 1L

            val itemsJson = if (state.splitMethod == SplitMethod.CUSTOM && state.customSplitSubMode == CustomSplitSubMode.ITEMIZED) {
                SplitItemJsonAdapter.toJson(
                    ItemizedSplitData(
                        items = state.items,
                        sharedRemainingParticipantNames = state.sharedRemainingParticipants,
                        isSharedRemainingDistributed = state.sharedRemainingParticipants.isNotEmpty()
                    )
                )
            } else null

            val expense = SplitExpense(
                title = state.title.trim(),
                totalAmount = state.totalAmount,
                date = state.date,
                categoryId = resolvedCategoryId,
                groupId = state.selectedGroupId,
                paidBy = state.paidBy,
                splitMethod = state.splitMethod,
                qrImagePath = state.qrImagePath,
                addToTransactions = state.addToTransactions,
                paymentMethod = state.paymentMethod,
                participants = state.calculatedParticipants,
                createdAt = state.date,
                updatedAt = System.currentTimeMillis(),
                itemsJson = itemsJson
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
