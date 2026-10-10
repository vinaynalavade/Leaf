package com.vinaynalavade.expensetracker.presentation.split.edit

import android.content.Intent
import android.provider.ContactsContract
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.PickVisualMediaRequest
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.animation.AnimatedVisibility
import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ExperimentalLayoutApi
import androidx.compose.foundation.layout.FlowRow
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
import androidx.compose.foundation.text.KeyboardActions
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.Calculate
import androidx.compose.material.icons.filled.CalendarMonth
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.Contacts
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material.icons.filled.Phone
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
import androidx.compose.material3.rememberModalBottomSheetState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.input.KeyboardCapitalization
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.vinaynalavade.expensetracker.R
import com.vinaynalavade.expensetracker.core.contact.ContactPickerHelper
import com.vinaynalavade.expensetracker.domain.model.SplitItem
import com.vinaynalavade.expensetracker.domain.model.SplitMethod
import com.vinaynalavade.expensetracker.presentation.components.AppTopBar
import com.vinaynalavade.expensetracker.presentation.components.CalculatorBottomSheet
import com.vinaynalavade.expensetracker.presentation.components.CategoryIcon
import com.vinaynalavade.expensetracker.presentation.components.LoadingView
import com.vinaynalavade.expensetracker.presentation.components.PaymentMethodSelector
import com.vinaynalavade.expensetracker.presentation.split.components.BaseEqualShareCard
import com.vinaynalavade.expensetracker.presentation.split.components.CustomSplitBalanceIndicator
import com.vinaynalavade.expensetracker.presentation.split.components.ParticipantCalculationBreakdownCard
import com.vinaynalavade.expensetracker.presentation.split.create.CalculatorTarget
import com.vinaynalavade.expensetracker.presentation.split.create.CustomSplitSubMode
import com.vinaynalavade.expensetracker.presentation.theme.ButtonShape
import com.vinaynalavade.expensetracker.presentation.theme.CardShape
import com.vinaynalavade.expensetracker.presentation.theme.PillShape
import com.vinaynalavade.expensetracker.presentation.theme.spacing
import kotlinx.coroutines.launch
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

@OptIn(ExperimentalMaterial3Api::class, ExperimentalLayoutApi::class)
@Composable
fun EditSplitScreen(
    viewModel: EditSplitViewModel,
    onNavigateBack: () -> Unit,
    onSplitUpdated: () -> Unit,
    modifier: Modifier = Modifier
) {
    val uiState by viewModel.uiState.collectAsStateWithLifecycle()
    val scrollState = rememberScrollState()
    val context = LocalContext.current
    val coroutineScope = rememberCoroutineScope()

    // Calculator Sheet State
    var activeCalculatorTarget by remember { mutableStateOf<CalculatorTarget?>(null) }
    val calcSheetState = rememberModalBottomSheetState(skipPartiallyExpanded = true)

    val photoPickerLauncher = rememberLauncherForActivityResult(
        contract = ActivityResultContracts.PickVisualMedia()
    ) { uri ->
        uri?.let { viewModel.onQrImageSelected(it) }
    }

    val contactPickerLauncher = rememberLauncherForActivityResult(
        contract = ActivityResultContracts.StartActivityForResult()
    ) { result ->
        val uri = result.data?.data
        if (uri != null) {
            val contact = ContactPickerHelper.extractContact(context, uri)
            if (contact != null) {
                viewModel.onAddParticipant(contact.name, contact.phoneNumber)
            }
        }
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

    // Built-in Calculator BottomSheet
    if (activeCalculatorTarget != null) {
        val target = activeCalculatorTarget!!
        val initialAmount = when (target) {
            is CalculatorTarget.TotalBill -> uiState.amountInput
            is CalculatorTarget.ItemAmount -> target.currentVal
            is CalculatorTarget.ItemCustomShare -> target.currentVal
            is CalculatorTarget.DirectShare -> target.currentVal
        }

        CalculatorBottomSheet(
            sheetState = calcSheetState,
            initialAmount = initialAmount,
            currency = uiState.currency,
            onDismissRequest = {
                coroutineScope.launch { calcSheetState.hide() }
                activeCalculatorTarget = null
            },
            onUseResult = { calculatedResult ->
                when (target) {
                    is CalculatorTarget.TotalBill -> viewModel.onAmountChange(calculatedResult)
                    is CalculatorTarget.ItemAmount -> viewModel.onUpdateItemAmount(target.itemId, calculatedResult)
                    is CalculatorTarget.ItemCustomShare -> viewModel.onUpdateItemCustomShare(target.itemId, target.participantName, calculatedResult)
                    is CalculatorTarget.DirectShare -> viewModel.onCustomShareChange(target.participantName, calculatedResult)
                }
                coroutineScope.launch { calcSheetState.hide() }
                activeCalculatorTarget = null
            }
        )
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
                    horizontalArrangement = Arrangement.End
                ) {
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

                // Total Amount with Calculator
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
                        trailingIcon = {
                            IconButton(onClick = { activeCalculatorTarget = CalculatorTarget.TotalBill }) {
                                Icon(
                                    imageVector = Icons.Default.Calculate,
                                    contentDescription = "Calculator",
                                    tint = MaterialTheme.colorScheme.primary
                                )
                            }
                        },
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
                        modifier = Modifier.fillMaxWidth(),
                        shape = ButtonShape
                    ) {
                        Icon(imageVector = Icons.Default.CalendarMonth, contentDescription = null, modifier = Modifier.size(18.dp))
                        Spacer(modifier = Modifier.width(MaterialTheme.spacing.xs))
                        Text(dateFormat.format(Date(uiState.date)))
                    }
                }

                // Category Selection
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
                                shape = PillShape
                            )
                        }
                    }
                }

                if (uiState.addToTransactions) {
                    PaymentMethodSelector(
                        selectedMethod = uiState.paymentMethod,
                        onMethodSelect = { viewModel.onPaymentMethodChange(it) },
                        isCompact = true,
                        horizontalPadding = 0.dp,
                        showLabel = true
                    )
                }

                // Add People (with Contact Picker)
                Column {
                    Text(
                        text = stringResource(R.string.split_people_title),
                        style = MaterialTheme.typography.labelLarge,
                        fontWeight = FontWeight.SemiBold
                    )
                    Spacer(modifier = Modifier.height(MaterialTheme.spacing.xs))

                    OutlinedButton(
                        onClick = {
                            try {
                                val intent = Intent(Intent.ACTION_PICK, ContactsContract.CommonDataKinds.Phone.CONTENT_URI)
                                contactPickerLauncher.launch(intent)
                            } catch (_: Exception) {}
                        },
                        shape = ButtonShape,
                        modifier = Modifier.fillMaxWidth()
                    ) {
                        Icon(imageVector = Icons.Default.Contacts, contentDescription = null, modifier = Modifier.size(18.dp))
                        Spacer(modifier = Modifier.width(MaterialTheme.spacing.xs))
                        Text(stringResource(R.string.split_add_from_contacts))
                    }

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
                                    viewModel.onAddParticipant(newParticipantName, null)
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
                        val phone = uiState.participantPhoneNumbers[name]
                        Row(
                            modifier = Modifier
                                .fillMaxWidth()
                                .padding(vertical = 4.dp),
                            horizontalArrangement = Arrangement.SpaceBetween,
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Column {
                                Text(if (isMe) "$name (You)" else name, style = MaterialTheme.typography.bodyMedium)
                                if (!phone.isNullOrBlank()) {
                                    Text(phone, style = MaterialTheme.typography.labelSmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
                                }
                            }
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
                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.spacedBy(MaterialTheme.spacing.xs)
                        ) {
                            FilterChip(
                                selected = uiState.customSplitSubMode == CustomSplitSubMode.ITEMIZED,
                                onClick = { viewModel.onCustomSplitSubModeChange(CustomSplitSubMode.ITEMIZED) },
                                label = { Text(stringResource(R.string.split_custom_mode_items)) },
                                shape = PillShape
                            )
                            FilterChip(
                                selected = uiState.customSplitSubMode == CustomSplitSubMode.DIRECT,
                                onClick = { viewModel.onCustomSplitSubModeChange(CustomSplitSubMode.DIRECT) },
                                label = { Text(stringResource(R.string.split_custom_mode_direct)) },
                                shape = PillShape
                            )
                        }

                        Spacer(modifier = Modifier.height(MaterialTheme.spacing.sm))

                        // Base Equal Share Foundation Card
                        BaseEqualShareCard(
                            totalBill = uiState.totalAmount,
                            participantCount = uiState.participants.size,
                            currency = uiState.currency
                        )

                        Spacer(modifier = Modifier.height(MaterialTheme.spacing.sm))

                        CustomSplitBalanceIndicator(
                            totalAmount = uiState.totalAmount,
                            allocatedAmount = uiState.customValidation.allocatedAmount,
                            remainingAmount = uiState.customValidation.remainingAmount,
                            overallocatedAmount = uiState.customValidation.overallocatedAmount,
                            currency = uiState.currency
                        )

                        Spacer(modifier = Modifier.height(MaterialTheme.spacing.sm))

                        if (uiState.customSplitSubMode == CustomSplitSubMode.ITEMIZED) {
                            Row(
                                modifier = Modifier.fillMaxWidth(),
                                horizontalArrangement = Arrangement.SpaceBetween,
                                verticalAlignment = Alignment.CenterVertically
                            ) {
                                Text(
                                    text = "Items (${uiState.items.size})",
                                    style = MaterialTheme.typography.titleSmall,
                                    fontWeight = FontWeight.Bold
                                )
                                Button(
                                    onClick = { viewModel.onAddItem() },
                                    shape = PillShape,
                                    contentPadding = androidx.compose.foundation.layout.PaddingValues(horizontal = 12.dp, vertical = 6.dp)
                                ) {
                                    Icon(imageVector = Icons.Default.Add, contentDescription = null, modifier = Modifier.size(16.dp))
                                    Spacer(modifier = Modifier.width(4.dp))
                                    Text(stringResource(R.string.split_add_item), style = MaterialTheme.typography.labelMedium)
                                }
                            }

                            Spacer(modifier = Modifier.height(MaterialTheme.spacing.xs))

                            Column(verticalArrangement = Arrangement.spacedBy(MaterialTheme.spacing.sm)) {
                                uiState.items.forEach { item ->
                                    EditItemRowCard(
                                        item = item,
                                        allParticipants = uiState.participants,
                                        currency = uiState.currency,
                                        onUpdateName = { viewModel.onUpdateItemName(item.id, it) },
                                        onUpdateAmount = { viewModel.onUpdateItemAmount(item.id, it) },
                                        onToggleConsumer = { viewModel.onToggleItemConsumer(item.id, it) },
                                        onToggleCustom = { viewModel.onToggleItemCustomAllocation(item.id, it) },
                                        onUpdateCustomShare = { p, amt -> viewModel.onUpdateItemCustomShare(item.id, p, amt) },
                                        onRemove = { viewModel.onRemoveItem(item.id) },
                                        onOpenCalculator = { target -> activeCalculatorTarget = target }
                                    )
                                }
                            }

                            val remainingSubunits = uiState.totalAmount.subunits - uiState.items.sumOf { it.amount.subunits }
                            if (remainingSubunits > 0L) {
                                Spacer(modifier = Modifier.height(MaterialTheme.spacing.sm))
                                Card(
                                    modifier = Modifier.fillMaxWidth(),
                                    shape = CardShape,
                                    colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface),
                                    border = BorderStroke(1.dp, MaterialTheme.colorScheme.primary.copy(alpha = 0.5f))
                                ) {
                                    Column(modifier = Modifier.padding(MaterialTheme.spacing.md)) {
                                        Row(
                                            modifier = Modifier.fillMaxWidth(),
                                            horizontalArrangement = Arrangement.SpaceBetween,
                                            verticalAlignment = Alignment.CenterVertically
                                        ) {
                                            Column {
                                                Text(
                                                    text = stringResource(R.string.split_shared_remaining_title),
                                                    style = MaterialTheme.typography.titleSmall,
                                                    fontWeight = FontWeight.Bold,
                                                    color = MaterialTheme.colorScheme.primary
                                                )
                                                Text(
                                                    text = "Remaining: ₹${remainingSubunits / 100.0} (shared bill / base portion)",
                                                    style = MaterialTheme.typography.bodySmall,
                                                    color = MaterialTheme.colorScheme.onSurfaceVariant
                                                )
                                            }
                                            TextButton(onClick = { viewModel.onDistributeSharedRemainingToAll() }) {
                                                Text(stringResource(R.string.split_distribute_to_all), style = MaterialTheme.typography.labelSmall)
                                            }
                                        }

                                        Spacer(modifier = Modifier.height(4.dp))

                                        FlowRow(
                                            horizontalArrangement = Arrangement.spacedBy(4.dp),
                                            verticalArrangement = Arrangement.spacedBy(4.dp)
                                        ) {
                                            uiState.participants.forEach { pName ->
                                                val isSelected = uiState.sharedRemainingParticipants.any { it.equals(pName, ignoreCase = true) }
                                                FilterChip(
                                                    selected = isSelected,
                                                    onClick = { viewModel.onToggleSharedRemainingParticipant(pName) },
                                                    label = { Text(pName) },
                                                    shape = PillShape
                                                )
                                            }
                                        }
                                    }
                                }
                            }

                            Spacer(modifier = Modifier.height(MaterialTheme.spacing.sm))

                            // Calculated Participant Shares Summary with Base + Item Breakdown
                            Column(verticalArrangement = Arrangement.spacedBy(MaterialTheme.spacing.xs)) {
                                Text(
                                    text = "Live Calculated Shares (${uiState.participants.size})",
                                    style = MaterialTheme.typography.titleSmall,
                                    fontWeight = FontWeight.Bold,
                                    color = MaterialTheme.colorScheme.onSurface
                                )
                                Spacer(modifier = Modifier.height(2.dp))

                                val itemizedCalc = uiState.itemizedCalculation
                                if (itemizedCalc != null) {
                                    itemizedCalc.participantDetails.forEach { detail ->
                                        val isMe = detail.participantName.equals("Me", ignoreCase = true) ||
                                            detail.participantName.equals(uiState.paidBy, ignoreCase = true)
                                        ParticipantCalculationBreakdownCard(
                                            detail = detail,
                                            isCurrentUser = isMe,
                                            currency = uiState.currency
                                        )
                                    }
                                } else {
                                    uiState.calculatedParticipants.forEach { p ->
                                        Card(
                                            modifier = Modifier.fillMaxWidth(),
                                            shape = CardShape,
                                            colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface),
                                            border = CardDefaults.outlinedCardBorder()
                                        ) {
                                            Row(
                                                modifier = Modifier
                                                    .fillMaxWidth()
                                                    .padding(MaterialTheme.spacing.md),
                                                horizontalArrangement = Arrangement.SpaceBetween,
                                                verticalAlignment = Alignment.CenterVertically
                                            ) {
                                                Text(if (p.isCurrentUser) "${p.name} (You)" else p.name, style = MaterialTheme.typography.bodyMedium)
                                                Text(p.amount.format(uiState.currency), style = MaterialTheme.typography.bodyMedium, fontWeight = FontWeight.Bold)
                                            }
                                        }
                                    }
                                }
                            }
                        } else {
                            // Direct Mode
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
                                        trailingIcon = {
                                            IconButton(onClick = { activeCalculatorTarget = CalculatorTarget.DirectShare(name, currentVal) }) {
                                                Icon(imageVector = Icons.Default.Calculate, contentDescription = "Calculator", modifier = Modifier.size(16.dp))
                                            }
                                        },
                                        modifier = Modifier.width(150.dp),
                                        shape = ButtonShape,
                                        singleLine = true,
                                        keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Decimal)
                                    )
                                }
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
                                    .clip(RoundedCornerShape(8.dp))
                                    .border(1.dp, MaterialTheme.colorScheme.outlineVariant, RoundedCornerShape(8.dp)),
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
                                    colors = ButtonDefaults.textButtonColors(contentColor = MaterialTheme.colorScheme.error)
                                ) {
                                    Text(stringResource(R.string.split_remove_qr_btn))
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
                            Icon(imageVector = Icons.Default.QrCode, contentDescription = null, modifier = Modifier.size(18.dp))
                            Spacer(modifier = Modifier.width(MaterialTheme.spacing.xs))
                            Text(stringResource(R.string.split_upload_qr_btn))
                        }
                    }
                }
            }
        }
    }
}

@OptIn(ExperimentalLayoutApi::class)
@Composable
private fun EditItemRowCard(
    item: SplitItem,
    allParticipants: List<String>,
    currency: com.vinaynalavade.expensetracker.core.model.Currency,
    onUpdateName: (String) -> Unit,
    onUpdateAmount: (String) -> Unit,
    onToggleConsumer: (String) -> Unit,
    onToggleCustom: (Boolean) -> Unit,
    onUpdateCustomShare: (String, String) -> Unit,
    onRemove: () -> Unit,
    onOpenCalculator: (CalculatorTarget) -> Unit
) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        shape = CardShape,
        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface),
        border = CardDefaults.outlinedCardBorder()
    ) {
        Column(modifier = Modifier.padding(MaterialTheme.spacing.md)) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                verticalAlignment = Alignment.CenterVertically
            ) {
                OutlinedTextField(
                    value = item.name,
                    onValueChange = onUpdateName,
                    placeholder = { Text(stringResource(R.string.split_item_name_hint)) },
                    modifier = Modifier.weight(1.3f),
                    shape = ButtonShape,
                    singleLine = true
                )

                Spacer(modifier = Modifier.width(MaterialTheme.spacing.xs))

                OutlinedTextField(
                    value = item.amountInput,
                    onValueChange = onUpdateAmount,
                    prefix = { Text(currency.symbol) },
                    placeholder = { Text("0") },
                    trailingIcon = {
                        IconButton(onClick = { onOpenCalculator(CalculatorTarget.ItemAmount(item.id, item.amountInput)) }) {
                            Icon(
                                imageVector = Icons.Default.Calculate,
                                contentDescription = "Calculator",
                                tint = MaterialTheme.colorScheme.primary,
                                modifier = Modifier.size(18.dp)
                            )
                        }
                    },
                    modifier = Modifier.weight(1.1f),
                    shape = ButtonShape,
                    singleLine = true,
                    keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Decimal)
                )

                IconButton(onClick = onRemove, modifier = Modifier.size(36.dp)) {
                    Icon(
                        imageVector = Icons.Default.Delete,
                        contentDescription = "Remove Item",
                        tint = MaterialTheme.colorScheme.error,
                        modifier = Modifier.size(20.dp)
                    )
                }
            }

            Spacer(modifier = Modifier.height(MaterialTheme.spacing.xs))

            Text(
                text = stringResource(R.string.split_item_consumers_label),
                style = MaterialTheme.typography.labelSmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )

            Spacer(modifier = Modifier.height(4.dp))

            FlowRow(
                horizontalArrangement = Arrangement.spacedBy(4.dp),
                verticalArrangement = Arrangement.spacedBy(4.dp)
            ) {
                allParticipants.forEach { pName ->
                    val isSelected = item.participantNames.any { it.equals(pName, ignoreCase = true) }
                    FilterChip(
                        selected = isSelected,
                        onClick = { onToggleConsumer(pName) },
                        label = { Text(pName) },
                        shape = PillShape,
                        colors = FilterChipDefaults.filterChipColors(
                            selectedContainerColor = MaterialTheme.colorScheme.primaryContainer,
                            selectedLabelColor = MaterialTheme.colorScheme.onPrimaryContainer
                        )
                    )
                }
            }

            Spacer(modifier = Modifier.height(MaterialTheme.spacing.xs))

            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                if (item.participantNames.isNotEmpty() && !item.isCustomAllocation) {
                    val count = item.participantNames.size
                    val eachVal = item.amount.subunits / count
                    Text(
                        text = "≈ ${currency.symbol}${eachVal / 100.0} each (${count} people)",
                        style = MaterialTheme.typography.labelSmall,
                        color = MaterialTheme.colorScheme.primary,
                        fontWeight = FontWeight.SemiBold
                    )
                } else if (item.participantNames.isEmpty()) {
                    Text(
                        text = "No one assigned yet",
                        style = MaterialTheme.typography.labelSmall,
                        color = MaterialTheme.colorScheme.error
                    )
                } else {
                    Text(
                        text = "Custom assigned",
                        style = MaterialTheme.typography.labelSmall,
                        color = MaterialTheme.colorScheme.primary
                    )
                }

                TextButton(onClick = { onToggleCustom(!item.isCustomAllocation) }) {
                    Text(
                        text = if (item.isCustomAllocation) stringResource(R.string.split_equal_alloc_item) else stringResource(R.string.split_custom_alloc_item),
                        style = MaterialTheme.typography.labelSmall
                    )
                }
            }

            if (item.isCustomAllocation && item.participantNames.isNotEmpty()) {
                Spacer(modifier = Modifier.height(MaterialTheme.spacing.xs))
                Column(verticalArrangement = Arrangement.spacedBy(4.dp)) {
                    item.participantNames.forEach { consumerName ->
                        val currentVal = item.customAllocationInputs[consumerName] ?: ""
                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            verticalAlignment = Alignment.CenterVertically,
                            horizontalArrangement = Arrangement.SpaceBetween
                        ) {
                            Text(text = consumerName, style = MaterialTheme.typography.bodySmall, modifier = Modifier.weight(1f))
                            OutlinedTextField(
                                value = currentVal,
                                onValueChange = { onUpdateCustomShare(consumerName, it) },
                                prefix = { Text(currency.symbol) },
                                placeholder = { Text("0") },
                                trailingIcon = {
                                    IconButton(onClick = {
                                        onOpenCalculator(CalculatorTarget.ItemCustomShare(item.id, consumerName, currentVal))
                                    }) {
                                        Icon(imageVector = Icons.Default.Calculate, contentDescription = "Calculator", modifier = Modifier.size(16.dp))
                                    }
                                },
                                modifier = Modifier.width(150.dp),
                                shape = ButtonShape,
                                singleLine = true,
                                keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Decimal)
                            )
                        }
                    }
                }
            }
        }
    }
}
