package com.vinaynalavade.expensetracker.presentation.reminders

import androidx.lifecycle.ViewModel
import androidx.lifecycle.ViewModelProvider
import androidx.lifecycle.viewModelScope
import com.vinaynalavade.expensetracker.core.model.Currency
import com.vinaynalavade.expensetracker.domain.model.Reminder
import com.vinaynalavade.expensetracker.domain.model.ReminderType
import com.vinaynalavade.expensetracker.domain.model.UpcomingPaymentItem
import com.vinaynalavade.expensetracker.domain.usecase.DeleteReminderUseCase
import com.vinaynalavade.expensetracker.domain.usecase.GetRemindersUseCase
import com.vinaynalavade.expensetracker.domain.usecase.GetUpcomingPaymentsUseCase
import com.vinaynalavade.expensetracker.domain.usecase.GetUserPreferencesUseCase
import com.vinaynalavade.expensetracker.domain.usecase.MarkReminderPaidUseCase
import com.vinaynalavade.expensetracker.domain.usecase.SaveReminderUseCase
import com.vinaynalavade.expensetracker.domain.usecase.ToggleReminderEnabledUseCase
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.launchIn
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch

enum class ReminderFilter {
    ALL,
    LOAN_EMI,
    BILLS,
    CREDIT_CARD,
    OTHER
}

data class RemindersUiState(
    val reminders: List<Reminder> = emptyList(),
    val filteredReminders: List<Reminder> = emptyList(),
    val upcomingPayments: List<UpcomingPaymentItem> = emptyList(),
    val selectedFilter: ReminderFilter = ReminderFilter.ALL,
    val currency: Currency = Currency.DEFAULT,
    val isLoading: Boolean = true,
    val errorMessage: String? = null,
    val infoMessage: String? = null
)

class RemindersViewModel(
    private val getRemindersUseCase: GetRemindersUseCase,
    private val getUpcomingPaymentsUseCase: GetUpcomingPaymentsUseCase,
    private val saveReminderUseCase: SaveReminderUseCase,
    private val deleteReminderUseCase: DeleteReminderUseCase,
    private val markReminderPaidUseCase: MarkReminderPaidUseCase,
    private val toggleReminderEnabledUseCase: ToggleReminderEnabledUseCase,
    private val getUserPreferencesUseCase: GetUserPreferencesUseCase
) : ViewModel() {

    private val _uiState = MutableStateFlow(RemindersUiState())
    val uiState: StateFlow<RemindersUiState> = _uiState.asStateFlow()

    init {
        loadData()
    }

    private fun loadData() {
        combine(
            getRemindersUseCase(),
            getUpcomingPaymentsUseCase(daysAhead = 30),
            getUserPreferencesUseCase()
        ) { reminders, upcoming, prefs ->
            val filter = _uiState.value.selectedFilter
            val filtered = filterReminders(reminders, filter)
            _uiState.update { current ->
                current.copy(
                    reminders = reminders,
                    filteredReminders = filtered,
                    upcomingPayments = upcoming,
                    currency = prefs.currency,
                    isLoading = false
                )
            }
        }.launchIn(viewModelScope)
    }

    fun setFilter(filter: ReminderFilter) {
        _uiState.update { current ->
            current.copy(
                selectedFilter = filter,
                filteredReminders = filterReminders(current.reminders, filter)
            )
        }
    }

    private fun filterReminders(list: List<Reminder>, filter: ReminderFilter): List<Reminder> {
        return when (filter) {
            ReminderFilter.ALL -> list
            ReminderFilter.LOAN_EMI -> list.filter { it.type == ReminderType.LOAN_EMI }
            ReminderFilter.BILLS -> list.filter { it.type == ReminderType.BILL || it.type == ReminderType.RENT }
            ReminderFilter.CREDIT_CARD -> list.filter { it.type == ReminderType.CREDIT_CARD }
            ReminderFilter.OTHER -> list.filter { it.type == ReminderType.INSURANCE || it.type == ReminderType.SUBSCRIPTION || it.type == ReminderType.CUSTOM }
        }
    }

    fun saveReminder(reminder: Reminder) {
        viewModelScope.launch {
            try {
                saveReminderUseCase(reminder)
                _uiState.update { it.copy(infoMessage = "Reminder saved") }
            } catch (e: Exception) {
                _uiState.update { it.copy(errorMessage = e.message ?: "Failed to save reminder") }
            }
        }
    }

    fun deleteReminder(id: Long) {
        viewModelScope.launch {
            try {
                deleteReminderUseCase(id)
                _uiState.update { it.copy(infoMessage = "Reminder deleted") }
            } catch (e: Exception) {
                _uiState.update { it.copy(errorMessage = e.message ?: "Failed to delete reminder") }
            }
        }
    }

    fun toggleReminder(id: Long, enabled: Boolean) {
        viewModelScope.launch {
            try {
                toggleReminderEnabledUseCase(id, enabled)
            } catch (e: Exception) {
                _uiState.update { it.copy(errorMessage = e.message ?: "Failed to update reminder") }
            }
        }
    }

    fun markPaid(id: Long, recordTransaction: Boolean) {
        viewModelScope.launch {
            try {
                markReminderPaidUseCase(id, recordTransaction)
                _uiState.update { it.copy(infoMessage = if (recordTransaction) "Marked paid and recorded in transactions" else "Marked paid") }
            } catch (e: Exception) {
                _uiState.update { it.copy(errorMessage = e.message ?: "Failed to mark paid") }
            }
        }
    }

    fun clearMessages() {
        _uiState.update { it.copy(errorMessage = null, infoMessage = null) }
    }

    class Factory(
        private val getRemindersUseCase: GetRemindersUseCase,
        private val getUpcomingPaymentsUseCase: GetUpcomingPaymentsUseCase,
        private val saveReminderUseCase: SaveReminderUseCase,
        private val deleteReminderUseCase: DeleteReminderUseCase,
        private val markReminderPaidUseCase: MarkReminderPaidUseCase,
        private val toggleReminderEnabledUseCase: ToggleReminderEnabledUseCase,
        private val getUserPreferencesUseCase: GetUserPreferencesUseCase
    ) : ViewModelProvider.Factory {
        @Suppress("UNCHECKED_CAST")
        override fun <T : ViewModel> create(modelClass: Class<T>): T {
            return RemindersViewModel(
                getRemindersUseCase,
                getUpcomingPaymentsUseCase,
                saveReminderUseCase,
                deleteReminderUseCase,
                markReminderPaidUseCase,
                toggleReminderEnabledUseCase,
                getUserPreferencesUseCase
            ) as T
        }
    }
}
