package com.vinaynalavade.expensetracker.presentation.reminders

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ExperimentalLayoutApi
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.CalendarToday
import androidx.compose.material.icons.filled.Schedule
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.DatePicker
import androidx.compose.material3.DatePickerDialog
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.ExposedDropdownMenuBox
import androidx.compose.material3.ExposedDropdownMenuDefaults
import androidx.compose.material3.FilterChip
import androidx.compose.material3.FilterChipDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TimePicker
import androidx.compose.material3.rememberDatePickerState
import androidx.compose.material3.rememberTimePickerState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp
import androidx.compose.ui.window.Dialog
import androidx.compose.ui.window.DialogProperties
import com.vinaynalavade.expensetracker.R
import com.vinaynalavade.expensetracker.core.model.Amount
import com.vinaynalavade.expensetracker.core.model.Currency
import com.vinaynalavade.expensetracker.domain.model.Reminder
import com.vinaynalavade.expensetracker.domain.model.ReminderRecurrence
import com.vinaynalavade.expensetracker.domain.model.ReminderType
import java.time.Instant
import java.time.LocalDate
import java.time.LocalTime
import java.time.ZoneId
import java.time.format.DateTimeFormatter

@OptIn(ExperimentalMaterial3Api::class, ExperimentalLayoutApi::class)
@Composable
fun AddEditReminderDialog(
    initialReminder: Reminder? = null,
    currency: Currency,
    onDismiss: () -> Unit,
    onSave: (Reminder) -> Unit
) {
    var title by remember { mutableStateOf(initialReminder?.title ?: "") }
    var note by remember { mutableStateOf(initialReminder?.description ?: "") }
    var amountText by remember {
        mutableStateOf(
            if (initialReminder != null && initialReminder.amount.subunits > 0L) {
                String.format(java.util.Locale.US, "%.2f", initialReminder.amount.subunits / 100.0)
            } else ""
        )
    }
    var selectedType by remember { mutableStateOf(initialReminder?.type ?: ReminderType.LOAN_EMI) }
    var selectedDueDate by remember {
        mutableStateOf(
            initialReminder?.dueDate?.let {
                Instant.ofEpochMilli(it).atZone(ZoneId.systemDefault()).toLocalDate()
            } ?: LocalDate.now().plusDays(1)
        )
    }
    var selectedRecurrence by remember { mutableStateOf(initialReminder?.recurrence ?: ReminderRecurrence.MONTHLY) }
    var primaryOffset by remember { mutableIntStateOf(initialReminder?.reminderOffsetDays ?: 1) }
    var selectedHour by remember { mutableIntStateOf(initialReminder?.notificationHour ?: 9) }
    var selectedMinute by remember { mutableIntStateOf(initialReminder?.notificationMinute ?: 0) }

    // Additional offsets set (parsed from comma-separated string)
    var additionalOffsets by remember {
        mutableStateOf(
            initialReminder?.additionalOffsets
                ?.split(",")
                ?.mapNotNull { it.trim().toIntOrNull() }
                ?.toSet()
                ?: emptySet()
        )
    }

    var showDatePicker by remember { mutableStateOf(false) }
    var showTimePicker by remember { mutableStateOf(false) }
    var isTypeDropdownExpanded by remember { mutableStateOf(false) }
    var isRecurrenceDropdownExpanded by remember { mutableStateOf(false) }

    var titleError by remember { mutableStateOf(false) }
    var amountError by remember { mutableStateOf(false) }

    val dateFormatter = remember { DateTimeFormatter.ofPattern("dd MMMM yyyy") }

    AlertDialog(
        onDismissRequest = onDismiss,
        properties = DialogProperties(usePlatformDefaultWidth = false),
        modifier = Modifier
            .fillMaxWidth(0.92f)
            .heightIn(max = 680.dp),
        title = {
            Text(
                text = if (initialReminder == null) stringResource(R.string.reminders_add)
                else stringResource(R.string.reminders_edit),
                style = MaterialTheme.typography.titleLarge,
                fontWeight = FontWeight.Bold
            )
        },
        text = {
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .verticalScroll(rememberScrollState()),
                verticalArrangement = Arrangement.spacedBy(14.dp)
            ) {
                // Title Field
                OutlinedTextField(
                    value = title,
                    onValueChange = {
                        title = it
                        if (it.isNotBlank()) titleError = false
                    },
                    label = { Text(stringResource(R.string.reminder_title_label)) },
                    placeholder = { Text(stringResource(R.string.reminder_title_hint)) },
                    isError = titleError,
                    singleLine = true,
                    shape = RoundedCornerShape(12.dp),
                    modifier = Modifier.fillMaxWidth()
                )

                // Amount Field
                OutlinedTextField(
                    value = amountText,
                    onValueChange = {
                        amountText = it
                        amountError = false
                    },
                    label = { Text("${stringResource(R.string.reminder_amount_label)} (${currency.symbol})") },
                    keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Decimal),
                    isError = amountError,
                    singleLine = true,
                    shape = RoundedCornerShape(12.dp),
                    modifier = Modifier.fillMaxWidth()
                )

                // Obligation Type Selector
                ExposedDropdownMenuBox(
                    expanded = isTypeDropdownExpanded,
                    onExpandedChange = { isTypeDropdownExpanded = !isTypeDropdownExpanded }
                ) {
                    OutlinedTextField(
                        value = getReminderTypeLabel(selectedType),
                        onValueChange = {},
                        readOnly = true,
                        label = { Text(stringResource(R.string.reminder_type_label)) },
                        trailingIcon = { ExposedDropdownMenuDefaults.TrailingIcon(expanded = isTypeDropdownExpanded) },
                        shape = RoundedCornerShape(12.dp),
                        modifier = Modifier
                            .menuAnchor()
                            .fillMaxWidth()
                    )
                    ExposedDropdownMenu(
                        expanded = isTypeDropdownExpanded,
                        onDismissRequest = { isTypeDropdownExpanded = false }
                    ) {
                        ReminderType.entries.forEach { type ->
                            DropdownMenuItem(
                                text = { Text(getReminderTypeLabel(type)) },
                                onClick = {
                                    selectedType = type
                                    isTypeDropdownExpanded = false
                                }
                            )
                        }
                    }
                }

                // Due Date Selector
                OutlinedTextField(
                    value = selectedDueDate.format(dateFormatter),
                    onValueChange = {},
                    readOnly = true,
                    label = { Text(stringResource(R.string.reminder_due_date_label)) },
                    trailingIcon = {
                        IconButton(onClick = { showDatePicker = true }) {
                            Icon(Icons.Default.CalendarToday, contentDescription = "Select Date")
                        }
                    },
                    shape = RoundedCornerShape(12.dp),
                    modifier = Modifier
                        .fillMaxWidth()
                        .clickable { showDatePicker = true }
                )

                // Recurrence Selector
                ExposedDropdownMenuBox(
                    expanded = isRecurrenceDropdownExpanded,
                    onExpandedChange = { isRecurrenceDropdownExpanded = !isRecurrenceDropdownExpanded }
                ) {
                    OutlinedTextField(
                        value = getRecurrenceLabel(selectedRecurrence),
                        onValueChange = {},
                        readOnly = true,
                        label = { Text(stringResource(R.string.reminder_recurrence_label)) },
                        trailingIcon = { ExposedDropdownMenuDefaults.TrailingIcon(expanded = isRecurrenceDropdownExpanded) },
                        shape = RoundedCornerShape(12.dp),
                        modifier = Modifier
                            .menuAnchor()
                            .fillMaxWidth()
                    )
                    ExposedDropdownMenu(
                        expanded = isRecurrenceDropdownExpanded,
                        onDismissRequest = { isRecurrenceDropdownExpanded = false }
                    ) {
                        ReminderRecurrence.entries.forEach { recurrence ->
                            DropdownMenuItem(
                                text = { Text(getRecurrenceLabel(recurrence)) },
                                onClick = {
                                    selectedRecurrence = recurrence
                                    isRecurrenceDropdownExpanded = false
                                }
                            )
                        }
                    }
                }

                // Primary Reminder Offset Options
                Text(
                    text = stringResource(R.string.reminder_offset_label),
                    style = MaterialTheme.typography.labelMedium,
                    fontWeight = FontWeight.SemiBold,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
                FlowRow(
                    horizontalArrangement = Arrangement.spacedBy(8.dp),
                    verticalArrangement = Arrangement.spacedBy(6.dp)
                ) {
                    val offsetOptions = listOf(0, 1, 2, 3, 5, 7)
                    offsetOptions.forEach { days ->
                        val label = when (days) {
                            0 -> stringResource(R.string.reminder_offset_on_due_date)
                            1 -> stringResource(R.string.reminder_offset_1_day)
                            2 -> stringResource(R.string.reminder_offset_2_days)
                            3 -> stringResource(R.string.reminder_offset_3_days)
                            5 -> stringResource(R.string.reminder_offset_5_days)
                            7 -> stringResource(R.string.reminder_offset_7_days)
                            else -> "${days}d"
                        }
                        FilterChip(
                            selected = primaryOffset == days,
                            onClick = { primaryOffset = days },
                            label = { Text(label) },
                            colors = FilterChipDefaults.filterChipColors(
                                selectedContainerColor = MaterialTheme.colorScheme.primaryContainer,
                                selectedLabelColor = MaterialTheme.colorScheme.onPrimaryContainer
                            )
                        )
                    }
                }

                // Additional Offsets
                Text(
                    text = stringResource(R.string.reminder_multiple_offsets_label),
                    style = MaterialTheme.typography.labelMedium,
                    fontWeight = FontWeight.SemiBold,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
                FlowRow(
                    horizontalArrangement = Arrangement.spacedBy(8.dp),
                    verticalArrangement = Arrangement.spacedBy(6.dp)
                ) {
                    listOf(0, 1, 3, 7).filter { it != primaryOffset }.forEach { days ->
                        val label = when (days) {
                            0 -> stringResource(R.string.reminder_offset_on_due_date)
                            1 -> stringResource(R.string.reminder_offset_1_day)
                            3 -> stringResource(R.string.reminder_offset_3_days)
                            7 -> stringResource(R.string.reminder_offset_7_days)
                            else -> "${days}d"
                        }
                        val isSelected = additionalOffsets.contains(days)
                        FilterChip(
                            selected = isSelected,
                            onClick = {
                                additionalOffsets = if (isSelected) {
                                    additionalOffsets - days
                                } else {
                                    additionalOffsets + days
                                }
                            },
                            label = { Text("+ $label") }
                        )
                    }
                }

                // Notification Time Selector
                OutlinedTextField(
                    value = String.format("%02d:%02d", selectedHour, selectedMinute),
                    onValueChange = {},
                    readOnly = true,
                    label = { Text(stringResource(R.string.reminder_time_label)) },
                    trailingIcon = {
                        IconButton(onClick = { showTimePicker = true }) {
                            Icon(Icons.Default.Schedule, contentDescription = "Select Time")
                        }
                    },
                    shape = RoundedCornerShape(12.dp),
                    modifier = Modifier
                        .fillMaxWidth()
                        .clickable { showTimePicker = true }
                )

                // Optional Note Field
                OutlinedTextField(
                    value = note,
                    onValueChange = { note = it },
                    label = { Text(stringResource(R.string.reminder_note_label)) },
                    singleLine = false,
                    maxLines = 2,
                    shape = RoundedCornerShape(12.dp),
                    modifier = Modifier.fillMaxWidth()
                )
            }
        },
        confirmButton = {
            Button(
                onClick = {
                    val cleanTitle = title.trim()
                    if (cleanTitle.isBlank()) {
                        titleError = true
                        return@Button
                    }
                    val amountDouble = amountText.toDoubleOrNull() ?: 0.0
                    val amountSubunits = (amountDouble * 100).toLong()

                    val additionalOffsetsString = if (additionalOffsets.isNotEmpty()) {
                        additionalOffsets.joinToString(",")
                    } else null

                    val reminderToSave = Reminder(
                        id = initialReminder?.id ?: 0L,
                        title = cleanTitle,
                        description = note.trim().ifBlank { null },
                        amount = Amount(amountSubunits),
                        type = selectedType,
                        dueDate = selectedDueDate.atStartOfDay(ZoneId.systemDefault()).toInstant().toEpochMilli(),
                        configuredDayOfMonth = selectedDueDate.dayOfMonth,
                        recurrence = selectedRecurrence,
                        reminderOffsetDays = primaryOffset,
                        additionalOffsets = additionalOffsetsString,
                        notificationHour = selectedHour,
                        notificationMinute = selectedMinute,
                        isEnabled = initialReminder?.isEnabled ?: true,
                        isPaid = initialReminder?.isPaid ?: false,
                        lastPaidDate = initialReminder?.lastPaidDate
                    )
                    onSave(reminderToSave)
                }
            ) {
                Text(stringResource(R.string.btn_save))
            }
        },
        dismissButton = {
            TextButton(onClick = onDismiss) {
                Text(stringResource(R.string.btn_cancel))
            }
        }
    )

    // DatePicker Dialog
    if (showDatePicker) {
        val datePickerState = rememberDatePickerState(
            initialSelectedDateMillis = selectedDueDate.atStartOfDay(ZoneId.systemDefault()).toInstant().toEpochMilli()
        )
        DatePickerDialog(
            onDismissRequest = { showDatePicker = false },
            confirmButton = {
                TextButton(onClick = {
                    datePickerState.selectedDateMillis?.let { millis ->
                        selectedDueDate = Instant.ofEpochMilli(millis)
                            .atZone(ZoneId.systemDefault())
                            .toLocalDate()
                    }
                    showDatePicker = false
                }) {
                    Text(stringResource(R.string.btn_done))
                }
            },
            dismissButton = {
                TextButton(onClick = { showDatePicker = false }) {
                    Text(stringResource(R.string.btn_cancel))
                }
            }
        ) {
            DatePicker(state = datePickerState)
        }
    }

    // TimePicker Dialog
    if (showTimePicker) {
        val timePickerState = rememberTimePickerState(
            initialHour = selectedHour,
            initialMinute = selectedMinute,
            is24Hour = false
        )
        AlertDialog(
            onDismissRequest = { showTimePicker = false },
            title = { Text(stringResource(R.string.reminder_time_label)) },
            text = {
                Box(
                    modifier = Modifier.fillMaxWidth(),
                    contentAlignment = Alignment.Center
                ) {
                    TimePicker(state = timePickerState)
                }
            },
            confirmButton = {
                TextButton(onClick = {
                    selectedHour = timePickerState.hour
                    selectedMinute = timePickerState.minute
                    showTimePicker = false
                }) {
                    Text(stringResource(R.string.btn_done))
                }
            },
            dismissButton = {
                TextButton(onClick = { showTimePicker = false }) {
                    Text(stringResource(R.string.btn_cancel))
                }
            }
        )
    }
}

@Composable
private fun getReminderTypeLabel(type: ReminderType): String {
    return when (type) {
        ReminderType.LOAN_EMI -> stringResource(R.string.reminder_type_loan_emi)
        ReminderType.CREDIT_CARD -> stringResource(R.string.reminder_type_credit_card)
        ReminderType.BILL -> stringResource(R.string.reminder_type_bill)
        ReminderType.INSURANCE -> stringResource(R.string.reminder_type_insurance)
        ReminderType.RENT -> stringResource(R.string.reminder_type_rent)
        ReminderType.SUBSCRIPTION -> stringResource(R.string.reminder_type_subscription)
        ReminderType.CUSTOM -> stringResource(R.string.reminder_type_custom)
    }
}

@Composable
private fun getRecurrenceLabel(recurrence: ReminderRecurrence): String {
    return when (recurrence) {
        ReminderRecurrence.ONE_TIME -> stringResource(R.string.reminder_recurrence_one_time)
        ReminderRecurrence.DAILY -> stringResource(R.string.reminder_recurrence_daily)
        ReminderRecurrence.WEEKLY -> stringResource(R.string.reminder_recurrence_weekly)
        ReminderRecurrence.MONTHLY -> stringResource(R.string.reminder_recurrence_monthly)
        ReminderRecurrence.YEARLY -> stringResource(R.string.reminder_recurrence_yearly)
    }
}
