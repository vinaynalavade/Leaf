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
import com.vinaynalavade.expensetracker.domain.usecase.GetSplitExpenseByIdUseCase
import com.vinaynalavade.expensetracker.domain.usecase.GetUserPreferencesUseCase
import com.vinaynalavade.expensetracker.domain.usecase.UpdateSplitExpenseUseCase
import com.vinaynalavade.expensetracker.presentation.split.create.CustomSplitSubMode
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.firstOrNull
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import java.util.UUID

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
    val participantPhoneNumbers: Map<String, String?> = emptyMap(),
    val splitMethod: SplitMethod = SplitMethod.EQUAL,
    val customSplitSubMode: CustomSplitSubMode = CustomSplitSubMode.ITEMIZED,
    val items: List<SplitItem> = emptyList(),
    val sharedRemainingParticipants: List<String> = emptyList(),
    val itemizedCalculation: ItemizedSplitCalculationResult? = null,
    val customSharesInput: Map<String, String> = emptyMap(),
    val calculatedParticipants: List<SplitParticipant> = emptyList(),
    val existingSettlements: Map<String, SettlementStatus> = emptyMap(),
    val existingParticipantTransactions: Map<String, Long?> = emptyMap(),
    val customValidation: CustomSplitValidation = CustomSplitValidation(
        isValid = true,
        allocatedAmount = Amount.ZERO,
        remainingAmount = Amount.ZERO,
        overallocatedAmount = Amount.ZERO
    ),
    val qrImagePath: String? = null,
    val qrImageBitmap: ImageBitmap? = null,
    val addToTransactions: Boolean = false,
    val expenseTransactionId: Long? = null,
    val paymentMethod: PaymentMethod = PaymentMethod.CASH,
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
                val phoneMap = expense.participants.associate { it.name to it.phoneNumber }
                val customMap = expense.participants.associate { it.name to it.amount.toInputString(currency) }
                val settlements = expense.participants.associate { it.name to it.settlementStatus }
                val txMap = expense.participants.associate { it.name to it.settlementTransactionId }

                // Parse items if available
                val parsedItemData = SplitItemJsonAdapter.fromJson(expense.itemsJson)
                val hasItems = parsedItemData != null && parsedItemData.items.isNotEmpty()
                val loadedSubMode = if (hasItems) CustomSplitSubMode.ITEMIZED else CustomSplitSubMode.DIRECT
                val loadedItems = parsedItemData?.items ?: emptyList()
                val loadedShared = parsedItemData?.sharedRemainingParticipantNames?.takeIf { it.isNotEmpty() } ?: participantNames

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
                        participantPhoneNumbers = phoneMap,
                        splitMethod = expense.splitMethod,
                        customSplitSubMode = loadedSubMode,
                        items = loadedItems,
                        sharedRemainingParticipants = loadedShared,
                        customSharesInput = customMap,
                        calculatedParticipants = expense.participants,
                        existingSettlements = settlements,
                        existingParticipantTransactions = txMap,
                        qrImagePath = expense.qrImagePath,
                        qrImageBitmap = bitmap,
                        addToTransactions = expense.addToTransactions,
                        expenseTransactionId = expense.expenseTransactionId,
                        paymentMethod = expense.paymentMethod,
                        isLoading = false,
                        currency = currency
                    )
                }
                recalculateShares()
            } else {
                _uiState.update { it.copy(isLoading = false, validationError = "Split expense not found.") }
            }
        }
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
            return
        }
        val newList = _uiState.value.participants.filterNot { it.equals(name, ignoreCase = true) }
        val newCustomMap = _uiState.value.customSharesInput.filterKeys { !it.equals(name, ignoreCase = true) }
        val newPhoneMap = _uiState.value.participantPhoneNumbers.filterKeys { !it.equals(name, ignoreCase = true) }
        val newShared = _uiState.value.sharedRemainingParticipants.filterNot { it.equals(name, ignoreCase = true) }

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

    // --- Item-Based Actions ---

    fun onAddItem() {
        val currentItems = _uiState.value.items
        val nextIndex = currentItems.size + 1
        val newItem = SplitItem(
            id = UUID.randomUUID().toString(),
            name = "Item $nextIndex",
            amount = Amount.ZERO,
            amountInput = "",
            participantNames = _uiState.value.participants.take(1)
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

    // --- Recalculation Engine ---

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
                val existingStatus = state.existingSettlements[p.name] ?: SettlementStatus.PENDING
                val existingTx = state.existingParticipantTransactions[p.name]
                p.copy(
                    settlementStatus = existingStatus,
                    settlementTransactionId = existingTx,
                    phoneNumber = state.participantPhoneNumbers[p.name]
                )
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
                val existingStatus = state.existingSettlements[name] ?: SettlementStatus.PENDING
                val existingTx = state.existingParticipantTransactions[name]
                SplitParticipant(
                    name = name,
                    isCurrentUser = isCurrentUser,
                    amount = share,
                    settlementStatus = existingStatus,
                    settlementTransactionId = existingTx,
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
            // Direct Per-Person Custom Mode
            var allocatedSubunits = 0L
            val participantList = participants.map { name ->
                val input = state.customSharesInput[name] ?: ""
                val shareAmount = Amount.fromStringOrNull(input, currency) ?: Amount.ZERO
                allocatedSubunits += shareAmount.subunits
                val isCurrentUser = name.equals("Me", ignoreCase = true) || name.equals(state.paidBy, ignoreCase = true)
                val existingStatus = state.existingSettlements[name] ?: SettlementStatus.PENDING
                val existingTx = state.existingParticipantTransactions[name]
                SplitParticipant(
                    name = name,
                    isCurrentUser = isCurrentUser,
                    amount = shareAmount,
                    settlementStatus = existingStatus,
                    settlementTransactionId = existingTx,
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

    fun saveChanges(onSuccess: () -> Unit) {
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

            val updatedExpense = SplitExpense(
                id = state.splitId,
                title = state.title.trim(),
                totalAmount = state.totalAmount,
                date = state.date,
                categoryId = resolvedCategoryId,
                paidBy = state.paidBy,
                splitMethod = state.splitMethod,
                qrImagePath = state.qrImagePath,
                addToTransactions = state.addToTransactions,
                expenseTransactionId = state.expenseTransactionId,
                paymentMethod = state.paymentMethod,
                participants = state.calculatedParticipants,
                createdAt = state.date,
                updatedAt = System.currentTimeMillis(),
                itemsJson = itemsJson
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
