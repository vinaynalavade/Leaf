package com.vinaynalavade.expensetracker.presentation.split.edit

import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.PickVisualMediaRequest
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.animation.AnimatedVisibility
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.CalendarMonth
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.QrCode
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.DatePicker
import androidx.compose.material3.DatePickerDialog
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.FilterChip
import androidx.compose.material3.FilterChipDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Scaffold
import androidx.compose.material3.SegmentedButton
import androidx.compose.material3.SegmentedButtonDefaults
import androidx.compose.material3.SingleChoiceSegmentedButtonRow
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.rememberDatePickerState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.input.KeyboardCapitalization
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.vinaynalavade.expensetracker.R
import com.vinaynalavade.expensetracker.domain.model.SplitMethod
import com.vinaynalavade.expensetracker.presentation.components.AppTopBar
import com.vinaynalavade.expensetracker.presentation.components.CategoryIcon
import com.vinaynalavade.expensetracker.presentation.components.LoadingView
import com.vinaynalavade.expensetracker.presentation.components.PaymentMethodSelector
import com.vinaynalavade.expensetracker.presentation.split.components.CustomSplitBalanceIndicator
import com.vinaynalavade.expensetracker.presentation.theme.ButtonShape
import com.vinaynalavade.expensetracker.presentation.theme.CardShape
import com.vinaynalavade.expensetracker.presentation.theme.PillShape
import com.vinaynalavade.expensetracker.presentation.theme.spacing
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun EditSplitScreen(
    viewModel: EditSplitViewModel,
    onNavigateBack: () -> Unit,
    onSplitUpdated: () -> Unit,
    modifier: Modifier = Modifier
) {
    val uiState by viewModel.uiState.collectAsStateWithLifecycle()
    val scrollState = rememberScrollState()

    val photoPickerLauncher = rememberLauncherForActivityResult(
        contract = ActivityResultContracts.PickVisualMedia()
    ) { uri ->
        uri?.let { viewModel.onQrImageSelected(it) }
    }

    var showDatePicker by remember { mutableStateOf(false) }
    val datePickerState = rememberDatePickerState(
        initialSelectedDateMillis = uiState.date
    )

    if (showDatePicker) {
        DatePickerDialog(
            onDismissRequest = { showDatePicker = false },
            confirmButton = {
                TextButton(onClick = {
                    datePickerState.selectedDateMillis?.let {
                        viewModel.onDateChange(it)
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

    var newParticipantName by remember { mutableStateOf("") }
    val dateFormat = SimpleDateFormat("EEE, MMM d, yyyy", Locale.getDefault())

    Scaffold(
        topBar = {
            AppTopBar(
                title = stringResource(R.string.split_edit_title),
                canNavigateBack = true,
                onNavigateBack = onNavigateBack
            )
        },
        bottomBar = {
            Surface(
                tonalElevation = 3.dp,
                color = MaterialTheme.colorScheme.surface,
                modifier = Modifier.fillMaxWidth()
            ) {
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(MaterialTheme.spacing.md),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    OutlinedButton(
                        onClick = onNavigateBack,
                        shape = ButtonShape
                    ) {
                        Text(stringResource(R.string.btn_cancel))
                    }

                    Button(
                        onClick = {
                            viewModel.saveChanges {
                                onSplitUpdated()
                            }
                        },
                        enabled = !uiState.isSaving,
                        shape = ButtonShape,
                        colors = ButtonDefaults.buttonColors(
                            containerColor = MaterialTheme.colorScheme.primary,
                            contentColor = MaterialTheme.colorScheme.onPrimary
                        )
                    ) {
                        Text(
                            text = if (uiState.isSaving) "Saving..." else stringResource(R.string.btn_save),
                            fontWeight = FontWeight.Bold
                        )
                    }
                }
            }
        },
        modifier = modifier.fillMaxSize()
    ) { innerPadding ->
        if (uiState.isLoading) {
            LoadingView(modifier = Modifier.padding(innerPadding))
        } else {
            Column(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(innerPadding)
                    .verticalScroll(scrollState)
                    .padding(MaterialTheme.spacing.md),
                verticalArrangement = Arrangement.spacedBy(MaterialTheme.spacing.md)
            ) {
                // Validation Error Banner
                AnimatedVisibility(visible = uiState.validationError != null) {
                    uiState.validationError?.let { error ->
                        Surface(
                            shape = CardShape,
                            color = MaterialTheme.colorScheme.errorContainer,
                            modifier = Modifier.fillMaxWidth()
                        ) {
                            Text(
                                text = error,
                                style = MaterialTheme.typography.bodyMedium,
                                color = MaterialTheme.colorScheme.onErrorContainer,
                                modifier = Modifier.padding(MaterialTheme.spacing.md)
                            )
                        }
                    }
                }

                // Expense Name
                Column {
                    Text(
                        text = stringResource(R.string.split_name_label),
                        style = MaterialTheme.typography.labelLarge,
                        fontWeight = FontWeight.SemiBold
                    )
                    Spacer(modifier = Modifier.height(MaterialTheme.spacing.xs))
                    OutlinedTextField(
                        value = uiState.title,
                        onValueChange = { viewModel.onTitleChange(it) },
                        modifier = Modifier.fillMaxWidth(),
                        shape = ButtonShape,
                        singleLine = true,
                        keyboardOptions = KeyboardOptions(capitalization = KeyboardCapitalization.Words)
                    )
                }

                // Total Amount
                Column {
                    Text(
                        text = stringResource(R.string.split_amount_label),
                        style = MaterialTheme.typography.labelLarge,
                        fontWeight = FontWeight.SemiBold
                    )
                    Spacer(modifier = Modifier.height(MaterialTheme.spacing.xs))
                    OutlinedTextField(
                        value = uiState.amountInput,
                        onValueChange = { viewModel.onAmountChange(it) },
                        prefix = { Text(uiState.currency.symbol) },
                        modifier = Modifier.fillMaxWidth(),
                        shape = ButtonShape,
                        singleLine = true,
                        keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Decimal)
                    )
                }

                // Date
                Column {
                    Text(
                        text = stringResource(R.string.split_date_label),
                        style = MaterialTheme.typography.labelLarge,
                        fontWeight = FontWeight.SemiBold
                    )
                    Spacer(modifier = Modifier.height(MaterialTheme.spacing.xs))
                    OutlinedButton(
                        onClick = { showDatePicker = true },
                        shape = ButtonShape,
                        modifier = Modifier.fillMaxWidth()
                    ) {
                        Icon(imageVector = Icons.Default.CalendarMonth, contentDescription = null, modifier = Modifier.size(18.dp))
                        Spacer(modifier = Modifier.width(MaterialTheme.spacing.sm))
                        Text(dateFormat.format(Date(uiState.date)))
                    }
                }

                // Category
                Column {
                    Text(
                        text = stringResource(R.string.split_category_label),
                        style = MaterialTheme.typography.labelLarge,
                        fontWeight = FontWeight.SemiBold
                    )
                    Spacer(modifier = Modifier.height(MaterialTheme.spacing.xs))
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .horizontalScroll(rememberScrollState()),
                        horizontalArrangement = Arrangement.spacedBy(MaterialTheme.spacing.xs)
                    ) {
                        uiState.availableCategories.forEach { category ->
                            val isSelected = uiState.selectedCategory?.id == category.id
                            FilterChip(
                                selected = isSelected,
                                onClick = { viewModel.onCategorySelect(category) },
                                label = { Text(category.name) },
                                leadingIcon = {
                                    CategoryIcon(iconName = category.iconName, colorHex = category.colorHex, size = 18.dp)
                                },
                                shape = PillShape,
                                colors = FilterChipDefaults.filterChipColors(
                                    selectedContainerColor = MaterialTheme.colorScheme.primaryContainer,
                                    selectedLabelColor = MaterialTheme.colorScheme.onPrimaryContainer
                                )
                            )
                        }
                    }
                }

                // If Transaction Integration is enabled, allow editing payment method
                if (uiState.addToTransactions) {
                    PaymentMethodSelector(
                        selectedMethod = uiState.paymentMethod,
                        onMethodSelect = { viewModel.onPaymentMethodChange(it) },
                        isCompact = true,
                        horizontalPadding = 0.dp,
                        showLabel = true
                    )
                }

                // Add People
                Column {
                    Text(
                        text = stringResource(R.string.split_people_title),
                        style = MaterialTheme.typography.labelLarge,
                        fontWeight = FontWeight.SemiBold
                    )
                    Spacer(modifier = Modifier.height(MaterialTheme.spacing.xs))
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        OutlinedTextField(
                            value = newParticipantName,
                            onValueChange = { newParticipantName = it },
                            placeholder = { Text(stringResource(R.string.split_add_person_hint)) },
                            modifier = Modifier.weight(1f),
                            shape = ButtonShape,
                            singleLine = true
                        )
                        Spacer(modifier = Modifier.width(MaterialTheme.spacing.sm))
                        Button(
                            onClick = {
                                if (newParticipantName.isNotBlank()) {
                                    viewModel.onAddParticipant(newParticipantName)
                                    newParticipantName = ""
                                }
                            },
                            shape = ButtonShape
                        ) {
                            Icon(imageVector = Icons.Default.Add, contentDescription = null)
                        }
                    }

                    Spacer(modifier = Modifier.height(MaterialTheme.spacing.xs))

                    uiState.participants.forEach { name ->
                        val isMe = name.equals("Me", ignoreCase = true) || name.equals(uiState.paidBy, ignoreCase = true)
                        Row(
                            modifier = Modifier
                                .fillMaxWidth()
                                .padding(vertical = 4.dp),
                            horizontalArrangement = Arrangement.SpaceBetween,
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Text(if (isMe) "$name (You)" else name, style = MaterialTheme.typography.bodyMedium)
                            if (!isMe) {
                                IconButton(
                                    onClick = { viewModel.onRemoveParticipant(name) },
                                    modifier = Modifier.size(28.dp)
                                ) {
                                    Icon(imageVector = Icons.Default.Close, contentDescription = "Remove", modifier = Modifier.size(16.dp))
                                }
                            }
                        }
                    }
                }

                // Split Method & Shares
                Column {
                    Text(
                        text = stringResource(R.string.split_method_title),
                        style = MaterialTheme.typography.labelLarge,
                        fontWeight = FontWeight.SemiBold
                    )
                    Spacer(modifier = Modifier.height(MaterialTheme.spacing.xs))

                    SingleChoiceSegmentedButtonRow(modifier = Modifier.fillMaxWidth()) {
                        SegmentedButton(
                            selected = uiState.splitMethod == SplitMethod.EQUAL,
                            onClick = { viewModel.onSplitMethodChange(SplitMethod.EQUAL) },
                            shape = SegmentedButtonDefaults.itemShape(index = 0, count = 2)
                        ) {
                            Text(stringResource(R.string.split_method_equal))
                        }
                        SegmentedButton(
                            selected = uiState.splitMethod == SplitMethod.CUSTOM,
                            onClick = { viewModel.onSplitMethodChange(SplitMethod.CUSTOM) },
                            shape = SegmentedButtonDefaults.itemShape(index = 1, count = 2)
                        ) {
                            Text(stringResource(R.string.split_method_custom))
                        }
                    }

                    Spacer(modifier = Modifier.height(MaterialTheme.spacing.sm))

                    if (uiState.splitMethod == SplitMethod.CUSTOM) {
                        CustomSplitBalanceIndicator(
                            totalAmount = uiState.totalAmount,
                            allocatedAmount = uiState.customValidation.allocatedAmount,
                            remainingAmount = uiState.customValidation.remainingAmount,
                            overallocatedAmount = uiState.customValidation.overallocatedAmount,
                            currency = uiState.currency
                        )

                        Spacer(modifier = Modifier.height(MaterialTheme.spacing.sm))

                        uiState.participants.forEach { name ->
                            val currentVal = uiState.customSharesInput[name] ?: ""
                            Row(
                                modifier = Modifier.fillMaxWidth(),
                                verticalAlignment = Alignment.CenterVertically,
                                horizontalArrangement = Arrangement.SpaceBetween
                            ) {
                                Text(name, style = MaterialTheme.typography.bodyMedium, modifier = Modifier.weight(1f))
                                OutlinedTextField(
                                    value = currentVal,
                                    onValueChange = { viewModel.onCustomShareChange(name, it) },
                                    prefix = { Text(uiState.currency.symbol) },
                                    modifier = Modifier.width(130.dp),
                                    shape = ButtonShape,
                                    singleLine = true,
                                    keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Decimal)
                                )
                            }
                        }
                    }
                }

                // QR Code
                Column {
                    Text(
                        text = stringResource(R.string.split_qr_section_title),
                        style = MaterialTheme.typography.labelLarge,
                        fontWeight = FontWeight.SemiBold
                    )
                    Spacer(modifier = Modifier.height(MaterialTheme.spacing.xs))

                    if (uiState.qrImageBitmap != null) {
                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Image(
                                bitmap = uiState.qrImageBitmap!!,
                                contentDescription = "QR Preview",
                                modifier = Modifier
                                    .size(80.dp)
                                    .clip(RoundedCornerShape(8.dp)),
                                contentScale = ContentScale.Fit
                            )
                            Spacer(modifier = Modifier.width(MaterialTheme.spacing.md))
                            Column {
                                OutlinedButton(
                                    onClick = {
                                        photoPickerLauncher.launch(
                                            PickVisualMediaRequest(ActivityResultContracts.PickVisualMedia.ImageOnly)
                                        )
                                    },
                                    shape = ButtonShape
                                ) {
                                    Text(stringResource(R.string.split_replace_qr_btn))
                                }
                                TextButton(
                                    onClick = { viewModel.onRemoveQrImage() },
                                    shape = ButtonShape
                                ) {
                                    Text(stringResource(R.string.split_remove_qr_btn), color = MaterialTheme.colorScheme.error)
                                }
                            }
                        }
                    } else {
                        OutlinedButton(
                            onClick = {
                                photoPickerLauncher.launch(
                                    PickVisualMediaRequest(ActivityResultContracts.PickVisualMedia.ImageOnly)
                                )
                            },
                            shape = ButtonShape,
                            modifier = Modifier.fillMaxWidth()
                        ) {
                            Icon(imageVector = Icons.Default.QrCode, contentDescription = null)
                            Spacer(modifier = Modifier.width(MaterialTheme.spacing.sm))
                            Text(stringResource(R.string.split_upload_qr_btn))
                        }
                    }
                }
            }
        }
    }
}
