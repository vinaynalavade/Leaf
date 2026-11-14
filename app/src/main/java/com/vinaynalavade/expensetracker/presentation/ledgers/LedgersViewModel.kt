package com.vinaynalavade.expensetracker.presentation.ledgers

import androidx.lifecycle.ViewModel
import androidx.lifecycle.ViewModelProvider
import androidx.lifecycle.viewModelScope
import com.vinaynalavade.expensetracker.core.model.Amount
import com.vinaynalavade.expensetracker.core.model.Currency
import com.vinaynalavade.expensetracker.core.result.AppResult
import com.vinaynalavade.expensetracker.domain.model.PaymentMethod
import com.vinaynalavade.expensetracker.domain.model.Transaction
import com.vinaynalavade.expensetracker.domain.model.TransactionType
import com.vinaynalavade.expensetracker.domain.repository.TransactionRepository
import com.vinaynalavade.expensetracker.domain.repository.UserPreferencesRepository
import com.vinaynalavade.expensetracker.domain.usecase.ReverseTransferUseCase
import com.vinaynalavade.expensetracker.domain.usecase.TransferFundsUseCase
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch

enum class LedgerFilter(val displayName: String) {
    ALL("All Ledgers"),
    CASH("Cash"),
    ACCOUNT("Account")
}

data class LedgersUiState(
    val combinedBalance: Amount = Amount.ZERO,
    val cashBalance: Amount = Amount.ZERO,
    val accountBalance: Amount = Amount.ZERO,
    val cashInflow: Amount = Amount.ZERO,
    val cashOutflow: Amount = Amount.ZERO,
    val accountInflow: Amount = Amount.ZERO,
    val accountOutflow: Amount = Amount.ZERO,
    val displayedTransactions: List<Transaction> = emptyList(),
    val totalCount: Int = 0,
    val selectedFilter: LedgerFilter = LedgerFilter.ALL,
    val currency: Currency = Currency.DEFAULT,
    val isLoading: Boolean = false,
    val error: String? = null
)

class LedgersViewModel(
    private val transactionRepository: TransactionRepository,
    private val userPreferencesRepository: UserPreferencesRepository,
    private val transferFundsUseCase: TransferFundsUseCase,
    private val reverseTransferUseCase: ReverseTransferUseCase
) : ViewModel() {

    private val _selectedFilter = MutableStateFlow(LedgerFilter.ALL)
    val selectedFilter: StateFlow<LedgerFilter> = _selectedFilter

    private val balancesFlow = combine(
        transactionRepository.getCashBalance(),
        transactionRepository.getAccountBalance(),
        userPreferencesRepository.getUserPreferences()
    ) { cashBal, acctBal, prefs ->
        Triple(cashBal, acctBal, prefs)
    }

    private val transactionsFlow = combine(
        transactionRepository.getCashTransactions(),
        transactionRepository.getAccountTransactions(),
        transactionRepository.getTransactions()
    ) { cashTxs, acctTxs, allTxs ->
        Triple(cashTxs, acctTxs, allTxs)
    }

    val uiState: StateFlow<LedgersUiState> = combine(
        balancesFlow,
        transactionsFlow,
        _selectedFilter
    ) { (cashBal, acctBal, prefs), (cashTxs, acctTxs, allTxs), filter ->
        val opening = prefs.openingBalance
        val effectiveAccountBal = acctBal + opening
        val combined = cashBal + effectiveAccountBal

        // Cash flow sums
        var cIn = 0L
        var cOut = 0L
        for (tx in cashTxs) {
            if (tx.type == TransactionType.INCOME) {
                cIn += tx.amount.subunits
            } else {
                cOut += tx.amount.subunits
            }
        }

        var aIn = 0L
        var aOut = 0L
        for (tx in acctTxs) {
            if (tx.type == TransactionType.INCOME) {
                aIn += tx.amount.subunits
            } else {
                aOut += tx.amount.subunits
            }
        }

        val filteredList = when (filter) {
            LedgerFilter.ALL -> allTxs
            LedgerFilter.CASH -> cashTxs
            LedgerFilter.ACCOUNT -> acctTxs
        }

        LedgersUiState(
            combinedBalance = combined,
            cashBalance = cashBal,
            accountBalance = effectiveAccountBal,
            cashInflow = Amount(cIn),
            cashOutflow = Amount(cOut),
            accountInflow = Amount(aIn),
            accountOutflow = Amount(aOut),
            displayedTransactions = filteredList,
            totalCount = filteredList.size,
            selectedFilter = filter,
            currency = prefs.currency,
            isLoading = false
        )
    }.stateIn(
        scope = viewModelScope,
        started = SharingStarted.WhileSubscribed(5000),
        initialValue = LedgersUiState(isLoading = true)
    )

    fun setFilter(filter: LedgerFilter) {
        _selectedFilter.value = filter
    }

    fun transfer(
        from: PaymentMethod,
        to: PaymentMethod,
        amount: Amount,
        note: String?,
        timestamp: Long,
        onComplete: (Boolean, String?) -> Unit
    ) {
        viewModelScope.launch {
            when (val res = transferFundsUseCase(from, to, amount, note, timestamp)) {
                is AppResult.Success -> onComplete(true, null)
                is AppResult.Error -> onComplete(false, res.error.userMessage)
            }
        }
    }

    fun reverseTransfer(transactionId: Long, onComplete: (Boolean, String?) -> Unit) {
        viewModelScope.launch {
            when (val res = reverseTransferUseCase(transactionId)) {
                is AppResult.Success -> onComplete(true, null)
                is AppResult.Error -> onComplete(false, res.error.userMessage)
            }
        }
    }

    class Factory(
        private val transactionRepository: TransactionRepository,
        private val userPreferencesRepository: UserPreferencesRepository,
        private val transferFundsUseCase: TransferFundsUseCase,
        private val reverseTransferUseCase: ReverseTransferUseCase
    ) : ViewModelProvider.Factory {
        @Suppress("UNCHECKED_CAST")
        override fun <T : ViewModel> create(modelClass: Class<T>): T {
            return LedgersViewModel(
                transactionRepository,
                userPreferencesRepository,
                transferFundsUseCase,
                reverseTransferUseCase
            ) as T
        }
    }
}
