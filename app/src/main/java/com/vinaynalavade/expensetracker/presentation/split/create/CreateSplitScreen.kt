package com.vinaynalavade.expensetracker.presentation.split.create

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.provider.ContactsContract
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.PickVisualMediaRequest
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.Crossfade
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
import androidx.compose.material.icons.automirrored.filled.ArrowForward
import androidx.compose.material.icons.automirrored.filled.ReceiptLong
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.Calculate
import androidx.compose.material.icons.filled.CalendarMonth
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.Contacts
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material.icons.filled.Group
import androidx.compose.material.icons.filled.Image
import androidx.compose.material.icons.filled.Person
import androidx.compose.material.icons.filled.Phone
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
import androidx.compose.ui.unit.sp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.vinaynalavade.expensetracker.R
import com.vinaynalavade.expensetracker.core.contact.ContactPickerHelper
import com.vinaynalavade.expensetracker.domain.model.Category
import com.vinaynalavade.expensetracker.domain.model.PaymentMethod
import com.vinaynalavade.expensetracker.domain.model.SplitItem
import com.vinaynalavade.expensetracker.domain.model.SplitMethod
import com.vinaynalavade.expensetracker.presentation.components.AppTopBar
import com.vinaynalavade.expensetracker.presentation.components.CalculatorBottomSheet
import com.vinaynalavade.expensetracker.presentation.components.CategoryIcon
import com.vinaynalavade.expensetracker.presentation.components.PaymentMethodSelector
import com.vinaynalavade.expensetracker.presentation.split.components.BaseEqualShareCard
import com.vinaynalavade.expensetracker.presentation.split.components.CustomSplitBalanceIndicator
import com.vinaynalavade.expensetracker.presentation.split.components.ParticipantCalculationBreakdownCard
import com.vinaynalavade.expensetracker.presentation.theme.ButtonShape
import com.vinaynalavade.expensetracker.presentation.theme.CardShape
import com.vinaynalavade.expensetracker.presentation.theme.IncomeEmerald
import com.vinaynalavade.expensetracker.presentation.theme.PillShape
import com.vinaynalavade.expensetracker.presentation.theme.spacing
import kotlinx.coroutines.launch
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

sealed interface CalculatorTarget {
    data object TotalBill : CalculatorTarget
    data class ItemAmount(val itemId: String, val currentVal: String) : CalculatorTarget
    data class ItemCustomShare(val itemId: String, val participantName: String, val currentVal: String) : CalculatorTarget
    data class DirectShare(val participantName: String, val currentVal: String) : CalculatorTarget
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun CreateSplitScreen(
    viewModel: CreateSplitViewModel,
    onNavigateBack: () -> Unit,
    onSplitCreated: (Long) -> Unit,
    modifier: Modifier = Modifier
) {
    val uiState by viewModel.uiState.collectAsStateWithLifecycle()
    val scrollState = rememberScrollState()
    val context = LocalContext.current
    val coroutineScope = rememberCoroutineScope()

    // Calculator Sheet State
    var activeCalculatorTarget by remember { mutableStateOf<CalculatorTarget?>(null) }
    val calcSheetState = rememberModalBottomSheetState(skipPartiallyExpanded = true)

    // Photo picker launcher
    val photoPickerLauncher = rememberLauncherForActivityResult(
        contract = ActivityResultContracts.PickVisualMedia()
    ) { uri ->
        uri?.let { viewModel.onQrImageSelected(it) }
    }

    // Date Picker Dialog State
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

    Scaffold(
        topBar = {
            AppTopBar(
                title = stringResource(R.string.split_create_title),
                canNavigateBack = true,
                onNavigateBack = {
                    if (!viewModel.onPreviousStep()) {
                        onNavigateBack()
                    }
                }
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
                    if (uiState.currentStep > 1) {
                        OutlinedButton(
                            onClick = { viewModel.onPreviousStep() },
                            shape = ButtonShape
                        ) {
                            Text(stringResource(R.string.btn_cancel))
                        }
                    } else {
                        Spacer(modifier = Modifier.width(1.dp))
                    }

                    if (uiState.currentStep < 5) {
                        Button(
                            onClick = { viewModel.onNextStep() },
                            shape = ButtonShape,
                            colors = ButtonDefaults.buttonColors(
                                containerColor = MaterialTheme.colorScheme.primary,
                                contentColor = MaterialTheme.colorScheme.onPrimary
                            )
                        ) {
                            Text(stringResource(R.string.btn_continue))
                            Spacer(modifier = Modifier.width(MaterialTheme.spacing.xs))
                            Icon(
                                imageVector = Icons.AutoMirrored.Filled.ArrowForward,
                                contentDescription = null,
                                modifier = Modifier.size(16.dp)
                            )
                        }
                    } else {
                        Button(
                            onClick = {
                                viewModel.saveSplitExpense { createdId ->
                                    onSplitCreated(createdId)
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
                                text = if (uiState.isSaving) "Creating..." else stringResource(R.string.split_create_btn),
                                fontWeight = FontWeight.Bold
                            )
                        }
                    }
                }
            }
        },
        modifier = modifier.fillMaxSize()
    ) { innerPadding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(innerPadding)
                .verticalScroll(scrollState)
                .padding(MaterialTheme.spacing.md)
        ) {
            // Step Progress Indicator
            StepProgressHeader(
                currentStep = uiState.currentStep,
                totalSteps = 5
            )

            Spacer(modifier = Modifier.height(MaterialTheme.spacing.md))

            // Validation Error Banner
            AnimatedVisibility(visible = uiState.validationError != null) {
                uiState.validationError?.let { error ->
                    Surface(
                        shape = CardShape,
                        color = MaterialTheme.colorScheme.errorContainer,
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(bottom = MaterialTheme.spacing.md)
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

            Crossfade(
                targetState = uiState.currentStep,
                label = "step_crossfade"
            ) { step ->
                when (step) {
                    1 -> Step1ExpenseDetails(
                        uiState = uiState,
                        onTitleChange = { viewModel.onTitleChange(it) },
                        onAmountChange = { viewModel.onAmountChange(it) },
                        onCategorySelect = { viewModel.onCategorySelect(it) },
                        onGroupSelect = { viewModel.onGroupSelect(it) },
                        onAddToTransactionsChange = { viewModel.onAddToTransactionsChange(it) },
                        onPaymentMethodChange = { viewModel.onPaymentMethodChange(it) },
                        onOpenDatePicker = { showDatePicker = true },
                        onOpenCalculator = {
                            activeCalculatorTarget = CalculatorTarget.TotalBill
                        }
                    )
                    2 -> Step2AddPeople(
                        uiState = uiState,
                        onAddParticipant = { name, phone -> viewModel.onAddParticipant(name, phone) },
                        onRemoveParticipant = { viewModel.onRemoveParticipant(it) }
                    )
                    3 -> Step3SplitMethod(
                        uiState = uiState,
                        onSplitMethodChange = { viewModel.onSplitMethodChange(it) },
                        onCustomSubModeChange = { viewModel.onCustomSplitSubModeChange(it) },
                        onAddItem = { viewModel.onAddItem() },
                        onRemoveItem = { viewModel.onRemoveItem(it) },
                        onUpdateItemName = { id, name -> viewModel.onUpdateItemName(id, name) },
                        onUpdateItemAmount = { id, amt -> viewModel.onUpdateItemAmount(id, amt) },
                        onToggleItemConsumer = { id, p -> viewModel.onToggleItemConsumer(id, p) },
                        onToggleItemCustomAllocation = { id, custom -> viewModel.onToggleItemCustomAllocation(id, custom) },
                        onUpdateItemCustomShare = { id, p, amt -> viewModel.onUpdateItemCustomShare(id, p, amt) },
                        onToggleSharedRemainingParticipant = { viewModel.onToggleSharedRemainingParticipant(it) },
                        onDistributeSharedRemainingToAll = { viewModel.onDistributeSharedRemainingToAll() },
                        onClearSharedRemaining = { viewModel.onClearSharedRemaining() },
                        onCustomShareChange = { name, amt -> viewModel.onCustomShareChange(name, amt) },
                        onOpenCalculator = { target -> activeCalculatorTarget = target }
                    )
                    4 -> Step4PaymentQr(
                        uiState = uiState,
                        onUploadClick = {
                            photoPickerLauncher.launch(
                                PickVisualMediaRequest(ActivityResultContracts.PickVisualMedia.ImageOnly)
                            )
                        },
                        onRemoveQr = { viewModel.onRemoveQrImage() }
                    )
                    5 -> Step5Review(
                        uiState = uiState
                    )
                }
            }
        }
    }
}

@Composable
private fun StepProgressHeader(currentStep: Int, totalSteps: Int) {
    val stepTitle = when (currentStep) {
        1 -> stringResource(R.string.split_details_step)
        2 -> stringResource(R.string.split_people_step)
        3 -> stringResource(R.string.split_method_step)
        4 -> stringResource(R.string.split_qr_step)
        5 -> stringResource(R.string.split_review_step)
        else -> ""
    }

    Column(modifier = Modifier.fillMaxWidth()) {
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Text(
                text = stepTitle,
                style = MaterialTheme.typography.titleMedium,
                fontWeight = FontWeight.Bold,
                color = MaterialTheme.colorScheme.onSurface
            )
            Text(
                text = "Step $currentStep of $totalSteps",
                style = MaterialTheme.typography.labelMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
        }

        Spacer(modifier = Modifier.height(MaterialTheme.spacing.xs))

        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.spacedBy(4.dp)
        ) {
            for (i in 1..totalSteps) {
                Box(
                    modifier = Modifier
                        .weight(1f)
                        .height(4.dp)
                        .clip(RoundedCornerShape(2.dp))
                        .background(
                            if (i <= currentStep) MaterialTheme.colorScheme.primary
                            else MaterialTheme.colorScheme.surfaceVariant
                        )
                )
            }
        }
    }
}

@Composable
private fun Step1ExpenseDetails(
    uiState: CreateSplitUiState,
    onTitleChange: (String) -> Unit,
    onAmountChange: (String) -> Unit,
    onCategorySelect: (Category) -> Unit,
    onGroupSelect: (Long?) -> Unit,
    onAddToTransactionsChange: (Boolean) -> Unit,
    onPaymentMethodChange: (PaymentMethod) -> Unit,
    onOpenDatePicker: () -> Unit,
    onOpenCalculator: () -> Unit
) {
    val quickSuggestions = listOf("Dinner", "Hotel", "Movie", "Road Trip", "Groceries", "Coffee")
    val dateFormat = SimpleDateFormat("EEE, MMM d, yyyy", Locale.getDefault())

    Column(modifier = Modifier.fillMaxWidth()) {
        Text(
            text = stringResource(R.string.split_name_label),
            style = MaterialTheme.typography.labelLarge,
            fontWeight = FontWeight.SemiBold,
            color = MaterialTheme.colorScheme.onSurface
        )
        Spacer(modifier = Modifier.height(MaterialTheme.spacing.xs))
        OutlinedTextField(
            value = uiState.title,
            onValueChange = onTitleChange,
            placeholder = { Text(stringResource(R.string.split_name_hint)) },
            modifier = Modifier.fillMaxWidth(),
            shape = ButtonShape,
            singleLine = true,
            keyboardOptions = KeyboardOptions(
                capitalization = KeyboardCapitalization.Words,
                imeAction = ImeAction.Next
            )
        )

        Spacer(modifier = Modifier.height(MaterialTheme.spacing.xs))

        // Quick title suggestion pills
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .horizontalScroll(rememberScrollState()),
            horizontalArrangement = Arrangement.spacedBy(MaterialTheme.spacing.xs)
        ) {
            quickSuggestions.forEach { suggestion ->
                Surface(
                    shape = PillShape,
                    color = MaterialTheme.colorScheme.surfaceVariant,
                    modifier = Modifier.clickable { onTitleChange(suggestion) }
                ) {
                    Text(
                        text = suggestion,
                        style = MaterialTheme.typography.labelSmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                        modifier = Modifier.padding(horizontal = 10.dp, vertical = 5.dp)
                    )
                }
            }
        }

        Spacer(modifier = Modifier.height(MaterialTheme.spacing.md))

        // Total Amount with Integrated Calculator
        Text(
            text = stringResource(R.string.split_amount_label),
            style = MaterialTheme.typography.labelLarge,
            fontWeight = FontWeight.SemiBold,
            color = MaterialTheme.colorScheme.onSurface
        )
        Spacer(modifier = Modifier.height(MaterialTheme.spacing.xs))
        OutlinedTextField(
            value = uiState.amountInput,
            onValueChange = onAmountChange,
            prefix = { Text(uiState.currency.symbol) },
            trailingIcon = {
                IconButton(onClick = onOpenCalculator) {
                    Icon(
                        imageVector = Icons.Default.Calculate,
                        contentDescription = stringResource(R.string.split_calculator_btn),
                        tint = MaterialTheme.colorScheme.primary
                    )
                }
            },
            placeholder = { Text("0.00") },
            modifier = Modifier.fillMaxWidth(),
            shape = ButtonShape,
            singleLine = true,
            keyboardOptions = KeyboardOptions(
                keyboardType = KeyboardType.Decimal,
                imeAction = ImeAction.Done
            )
        )

        Spacer(modifier = Modifier.height(MaterialTheme.spacing.md))

        // Date Picker Button
        Text(
            text = stringResource(R.string.split_date_label),
            style = MaterialTheme.typography.labelLarge,
            fontWeight = FontWeight.SemiBold,
            color = MaterialTheme.colorScheme.onSurface
        )
        Spacer(modifier = Modifier.height(MaterialTheme.spacing.xs))
        OutlinedButton(
            onClick = onOpenDatePicker,
            modifier = Modifier.fillMaxWidth(),
            shape = ButtonShape
        ) {
            Icon(
                imageVector = Icons.Default.CalendarMonth,
                contentDescription = null,
                modifier = Modifier.size(18.dp)
            )
            Spacer(modifier = Modifier.width(MaterialTheme.spacing.xs))
            Text(dateFormat.format(Date(uiState.date)))
        }

        Spacer(modifier = Modifier.height(MaterialTheme.spacing.md))

        // Category Chips
        Text(
            text = stringResource(R.string.split_category_label),
            style = MaterialTheme.typography.labelLarge,
            fontWeight = FontWeight.SemiBold,
            color = MaterialTheme.colorScheme.onSurface
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
                    onClick = { onCategorySelect(category) },
                    label = { Text(category.name) },
                    leadingIcon = {
                        CategoryIcon(
                            iconName = category.iconName,
                            colorHex = category.colorHex,
                            size = 18.dp
                        )
                    },
                    shape = PillShape,
                    colors = FilterChipDefaults.filterChipColors(
                        selectedContainerColor = MaterialTheme.colorScheme.primaryContainer,
                        selectedLabelColor = MaterialTheme.colorScheme.onPrimaryContainer
                    )
                )
            }
        }

        if (uiState.availableGroups.isNotEmpty()) {
            Spacer(modifier = Modifier.height(MaterialTheme.spacing.md))

            Text(
                text = "Group (Optional)",
                style = MaterialTheme.typography.labelLarge,
                fontWeight = FontWeight.SemiBold,
                color = MaterialTheme.colorScheme.onSurface
            )
            Spacer(modifier = Modifier.height(MaterialTheme.spacing.xs))
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .horizontalScroll(rememberScrollState()),
                horizontalArrangement = Arrangement.spacedBy(MaterialTheme.spacing.xs)
            ) {
                FilterChip(
                    selected = uiState.selectedGroupId == null,
                    onClick = { onGroupSelect(null) },
                    label = { Text("None") },
                    shape = PillShape
                )
                uiState.availableGroups.forEach { group ->
                    val isSelected = uiState.selectedGroupId == group.id
                    FilterChip(
                        selected = isSelected,
                        onClick = { onGroupSelect(group.id) },
                        label = { Text(group.name) },
                        shape = PillShape
                    )
                }
            }
        }

        Spacer(modifier = Modifier.height(MaterialTheme.spacing.lg))

        // Add to Transactions Integration Card
        Card(
            modifier = Modifier.fillMaxWidth(),
            shape = CardShape,
            colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface),
            border = CardDefaults.outlinedCardBorder()
        ) {
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(MaterialTheme.spacing.md)
            ) {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Icon(
                        imageVector = Icons.AutoMirrored.Filled.ReceiptLong,
                        contentDescription = null,
                        tint = MaterialTheme.colorScheme.primary,
                        modifier = Modifier.size(20.dp)
                    )
                    Spacer(modifier = Modifier.width(MaterialTheme.spacing.xs))
                    Text(
                        text = stringResource(R.string.split_add_to_transactions_title),
                        style = MaterialTheme.typography.titleSmall,
                        fontWeight = FontWeight.Bold,
                        color = MaterialTheme.colorScheme.onSurface
                    )
                }

                Spacer(modifier = Modifier.height(4.dp))

                Text(
                    text = stringResource(R.string.split_add_to_transactions_desc),
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )

                Spacer(modifier = Modifier.height(MaterialTheme.spacing.md))

                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(MaterialTheme.spacing.xs)
                ) {
                    Surface(
                        shape = PillShape,
                        color = if (uiState.addToTransactions) MaterialTheme.colorScheme.primaryContainer else MaterialTheme.colorScheme.surfaceVariant,
                        border = if (uiState.addToTransactions) BorderStroke(1.5.dp, MaterialTheme.colorScheme.primary) else null,
                        modifier = Modifier
                            .weight(1f)
                            .clip(PillShape)
                            .clickable { onAddToTransactionsChange(true) }
                    ) {
                        Row(
                            modifier = Modifier.padding(horizontal = 8.dp, vertical = 10.dp),
                            verticalAlignment = Alignment.CenterVertically,
                            horizontalArrangement = Arrangement.Center
                        ) {
                            if (uiState.addToTransactions) {
                                Icon(
                                    imageVector = Icons.Default.Check,
                                    contentDescription = null,
                                    modifier = Modifier.size(14.dp),
                                    tint = MaterialTheme.colorScheme.primary
                                )
                                Spacer(modifier = Modifier.width(4.dp))
                            }
                            Text(
                                text = stringResource(R.string.split_add_to_transactions_yes),
                                style = MaterialTheme.typography.labelSmall,
                                fontWeight = if (uiState.addToTransactions) FontWeight.Bold else FontWeight.Medium,
                                color = if (uiState.addToTransactions) MaterialTheme.colorScheme.onPrimaryContainer else MaterialTheme.colorScheme.onSurfaceVariant
                            )
                        }
                    }

                    Surface(
                        shape = PillShape,
                        color = if (!uiState.addToTransactions) MaterialTheme.colorScheme.primaryContainer else MaterialTheme.colorScheme.surfaceVariant,
                        border = if (!uiState.addToTransactions) BorderStroke(1.5.dp, MaterialTheme.colorScheme.primary) else null,
                        modifier = Modifier
                            .weight(1f)
                            .clip(PillShape)
                            .clickable { onAddToTransactionsChange(false) }
                    ) {
                        Row(
                            modifier = Modifier.padding(horizontal = 8.dp, vertical = 10.dp),
                            verticalAlignment = Alignment.CenterVertically,
                            horizontalArrangement = Arrangement.Center
                        ) {
                            if (!uiState.addToTransactions) {
                                Icon(
                                    imageVector = Icons.Default.Check,
                                    contentDescription = null,
                                    modifier = Modifier.size(14.dp),
                                    tint = MaterialTheme.colorScheme.primary
                                )
                                Spacer(modifier = Modifier.width(4.dp))
                            }
                            Text(
                                text = stringResource(R.string.split_add_to_transactions_no),
                                style = MaterialTheme.typography.labelSmall,
                                fontWeight = if (!uiState.addToTransactions) FontWeight.Bold else FontWeight.Medium,
                                color = if (!uiState.addToTransactions) MaterialTheme.colorScheme.onPrimaryContainer else MaterialTheme.colorScheme.onSurfaceVariant
                            )
                        }
                    }
                }

                AnimatedVisibility(visible = uiState.addToTransactions) {
                    Column(modifier = Modifier.padding(top = MaterialTheme.spacing.md)) {
                        PaymentMethodSelector(
                            selectedMethod = uiState.paymentMethod,
                            onMethodSelect = onPaymentMethodChange,
                            isCompact = true,
                            horizontalPadding = 0.dp,
                            showLabel = true
                        )
                    }
                }
            }
        }
    }
}

@Composable
private fun Step2AddPeople(
    uiState: CreateSplitUiState,
    onAddParticipant: (String, String?) -> Unit,
    onRemoveParticipant: (String) -> Unit
) {
    var newPersonName by remember { mutableStateOf("") }
    val quickPeople = listOf("Rahul", "Akash", "Sameer", "Priya", "Amit", "Sneha", "Rohit")
    val context = LocalContext.current

    val contactPickerLauncher = rememberLauncherForActivityResult(
        contract = ActivityResultContracts.StartActivityForResult()
    ) { result ->
        val uri = result.data?.data
        if (uri != null) {
            val contact = ContactPickerHelper.extractContact(context, uri)
            if (contact != null) {
                onAddParticipant(contact.name, contact.phoneNumber)
            }
        }
    }

    Column(modifier = Modifier.fillMaxWidth()) {
        Text(
            text = stringResource(R.string.split_people_title),
            style = MaterialTheme.typography.titleMedium,
            fontWeight = FontWeight.SemiBold,
            color = MaterialTheme.colorScheme.onSurface
        )
        Spacer(modifier = Modifier.height(MaterialTheme.spacing.xs))
        Text(
            text = "Add participants manually or select directly from your contacts for instant WhatsApp sharing.",
            style = MaterialTheme.typography.bodySmall,
            color = MaterialTheme.colorScheme.onSurfaceVariant
        )

        Spacer(modifier = Modifier.height(MaterialTheme.spacing.md))

        // Action Row: Add from Contacts Button
        OutlinedButton(
            onClick = {
                try {
                    val intent = Intent(Intent.ACTION_PICK, ContactsContract.CommonDataKinds.Phone.CONTENT_URI)
                    contactPickerLauncher.launch(intent)
                } catch (_: Exception) {
                    // Fallback to manual entry
                }
            },
            shape = ButtonShape,
            modifier = Modifier.fillMaxWidth()
        ) {
            Icon(
                imageVector = Icons.Default.Contacts,
                contentDescription = null,
                modifier = Modifier.size(18.dp)
            )
            Spacer(modifier = Modifier.width(MaterialTheme.spacing.xs))
            Text(stringResource(R.string.split_add_from_contacts))
        }

        Spacer(modifier = Modifier.height(MaterialTheme.spacing.sm))

        // Manual Text Entry Row
        Row(
            modifier = Modifier.fillMaxWidth(),
            verticalAlignment = Alignment.CenterVertically
        ) {
            OutlinedTextField(
                value = newPersonName,
                onValueChange = { newPersonName = it },
                placeholder = { Text(stringResource(R.string.split_add_person_hint)) },
                modifier = Modifier.weight(1f),
                shape = ButtonShape,
                singleLine = true,
                keyboardOptions = KeyboardOptions(
                    capitalization = KeyboardCapitalization.Words,
                    imeAction = ImeAction.Done
                ),
                keyboardActions = KeyboardActions(
                    onDone = {
                        if (newPersonName.isNotBlank()) {
                            onAddParticipant(newPersonName, null)
                            newPersonName = ""
                        }
                    }
                )
            )
            Spacer(modifier = Modifier.width(MaterialTheme.spacing.sm))
            Button(
                onClick = {
                    if (newPersonName.isNotBlank()) {
                        onAddParticipant(newPersonName, null)
                        newPersonName = ""
                    }
                },
                shape = ButtonShape
            ) {
                Icon(imageVector = Icons.Default.Add, contentDescription = null)
            }
        }

        Spacer(modifier = Modifier.height(MaterialTheme.spacing.xs))

        // Quick suggestions
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .horizontalScroll(rememberScrollState()),
            horizontalArrangement = Arrangement.spacedBy(MaterialTheme.spacing.xs)
        ) {
            quickPeople.forEach { name ->
                if (!uiState.participants.any { it.equals(name, ignoreCase = true) }) {
                    Surface(
                        shape = PillShape,
                        color = MaterialTheme.colorScheme.surfaceVariant,
                        modifier = Modifier.clickable { onAddParticipant(name, null) }
                    ) {
                        Text(
                            text = "+ $name",
                            style = MaterialTheme.typography.labelSmall,
                            color = MaterialTheme.colorScheme.onSurfaceVariant,
                            modifier = Modifier.padding(horizontal = 10.dp, vertical = 5.dp)
                        )
                    }
                }
            }
        }

        Spacer(modifier = Modifier.height(MaterialTheme.spacing.md))

        Text(
            text = "Added Participants (${uiState.participants.size})",
            style = MaterialTheme.typography.labelLarge,
            fontWeight = FontWeight.Bold,
            color = MaterialTheme.colorScheme.onSurface
        )

        Spacer(modifier = Modifier.height(MaterialTheme.spacing.xs))

        Column(
            modifier = Modifier.fillMaxWidth(),
            verticalArrangement = Arrangement.spacedBy(MaterialTheme.spacing.xs)
        ) {
            uiState.participants.forEach { name ->
                val isMe = name.equals("Me", ignoreCase = true) || name.equals(uiState.paidBy, ignoreCase = true)
                val phoneNumber = uiState.participantPhoneNumbers[name]

                Card(
                    modifier = Modifier.fillMaxWidth(),
                    shape = CardShape,
                    colors = CardDefaults.cardColors(
                        containerColor = if (isMe) MaterialTheme.colorScheme.primary.copy(alpha = 0.08f) else MaterialTheme.colorScheme.surface
                    ),
                    border = CardDefaults.outlinedCardBorder().copy(
                        brush = androidx.compose.ui.graphics.SolidColor(MaterialTheme.colorScheme.outlineVariant.copy(alpha = 0.5f))
                    )
                ) {
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(horizontal = MaterialTheme.spacing.md, vertical = MaterialTheme.spacing.sm),
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.SpaceBetween
                    ) {
                        Row(verticalAlignment = Alignment.CenterVertically, modifier = Modifier.weight(1f)) {
                            Box(
                                modifier = Modifier
                                    .size(36.dp)
                                    .clip(CircleShape)
                                    .background(
                                        if (isMe) MaterialTheme.colorScheme.primary.copy(alpha = 0.15f)
                                        else MaterialTheme.colorScheme.surfaceVariant
                                    ),
                                contentAlignment = Alignment.Center
                            ) {
                                Text(
                                    text = name.take(1).uppercase(Locale.getDefault()),
                                    style = MaterialTheme.typography.labelMedium,
                                    fontWeight = FontWeight.Bold,
                                    color = if (isMe) MaterialTheme.colorScheme.primary else MaterialTheme.colorScheme.onSurfaceVariant
                                )
                            }
                            Spacer(modifier = Modifier.width(MaterialTheme.spacing.sm))
                            Column {
                                Text(
                                    text = if (isMe) "$name (You - Paid the bill)" else name,
                                    style = MaterialTheme.typography.bodyMedium,
                                    fontWeight = if (isMe) FontWeight.Bold else FontWeight.Medium,
                                    color = MaterialTheme.colorScheme.onSurface
                                )
                                if (!phoneNumber.isNullOrBlank()) {
                                    Row(verticalAlignment = Alignment.CenterVertically) {
                                        Icon(
                                            imageVector = Icons.Default.Phone,
                                            contentDescription = null,
                                            modifier = Modifier.size(12.dp),
                                            tint = MaterialTheme.colorScheme.primary
                                        )
                                        Spacer(modifier = Modifier.width(4.dp))
                                        Text(
                                            text = phoneNumber,
                                            style = MaterialTheme.typography.labelSmall,
                                            color = MaterialTheme.colorScheme.onSurfaceVariant
                                        )
                                    }
                                }
                            }
                        }

                        if (!isMe) {
                            IconButton(
                                onClick = { onRemoveParticipant(name) },
                                modifier = Modifier.size(32.dp)
                            ) {
                                Icon(
                                    imageVector = Icons.Default.Close,
                                    contentDescription = "Remove",
                                    tint = MaterialTheme.colorScheme.onSurfaceVariant,
                                    modifier = Modifier.size(16.dp)
                                )
                            }
                        }
                    }
                }
            }
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class, ExperimentalLayoutApi::class)
@Composable
private fun Step3SplitMethod(
    uiState: CreateSplitUiState,
    onSplitMethodChange: (SplitMethod) -> Unit,
    onCustomSubModeChange: (CustomSplitSubMode) -> Unit,
    onAddItem: () -> Unit,
    onRemoveItem: (String) -> Unit,
    onUpdateItemName: (String, String) -> Unit,
    onUpdateItemAmount: (String, String) -> Unit,
    onToggleItemConsumer: (String, String) -> Unit,
    onToggleItemCustomAllocation: (String, Boolean) -> Unit,
    onUpdateItemCustomShare: (String, String, String) -> Unit,
    onToggleSharedRemainingParticipant: (String) -> Unit,
    onDistributeSharedRemainingToAll: () -> Unit,
    onClearSharedRemaining: () -> Unit,
    onCustomShareChange: (String, String) -> Unit,
    onOpenCalculator: (CalculatorTarget) -> Unit
) {
    Column(modifier = Modifier.fillMaxWidth()) {
        Text(
            text = stringResource(R.string.split_method_title),
            style = MaterialTheme.typography.titleMedium,
            fontWeight = FontWeight.SemiBold,
            color = MaterialTheme.colorScheme.onSurface
        )

        Spacer(modifier = Modifier.height(MaterialTheme.spacing.sm))

        SingleChoiceSegmentedButtonRow(modifier = Modifier.fillMaxWidth()) {
            SegmentedButton(
                selected = uiState.splitMethod == SplitMethod.EQUAL,
                onClick = { onSplitMethodChange(SplitMethod.EQUAL) },
                shape = SegmentedButtonDefaults.itemShape(index = 0, count = 2)
            ) {
                Text(stringResource(R.string.split_method_equal))
            }
            SegmentedButton(
                selected = uiState.splitMethod == SplitMethod.CUSTOM,
                onClick = { onSplitMethodChange(SplitMethod.CUSTOM) },
                shape = SegmentedButtonDefaults.itemShape(index = 1, count = 2)
            ) {
                Text(stringResource(R.string.split_method_custom))
            }
        }

        Spacer(modifier = Modifier.height(MaterialTheme.spacing.md))

        if (uiState.splitMethod == SplitMethod.EQUAL) {
            Card(
                modifier = Modifier.fillMaxWidth(),
                shape = CardShape,
                colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface),
                border = CardDefaults.outlinedCardBorder()
            ) {
                Column(modifier = Modifier.padding(MaterialTheme.spacing.md)) {
                    Text(
                        text = "Equal Split Breakdown",
                        style = MaterialTheme.typography.titleSmall,
                        fontWeight = FontWeight.Bold
                    )
                    Spacer(modifier = Modifier.height(MaterialTheme.spacing.xs))
                    Text(
                        text = "${uiState.totalAmount.format(uiState.currency)} divided equally among ${uiState.participants.size} people.",
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                    Spacer(modifier = Modifier.height(MaterialTheme.spacing.sm))

                    uiState.calculatedParticipants.forEach { participant ->
                        Row(
                            modifier = Modifier
                                .fillMaxWidth()
                                .padding(vertical = 4.dp),
                            horizontalArrangement = Arrangement.SpaceBetween
                        ) {
                            Text(
                                text = if (participant.isCurrentUser) "${participant.name} (You)" else participant.name,
                                style = MaterialTheme.typography.bodyMedium,
                                fontWeight = if (participant.isCurrentUser) FontWeight.Bold else FontWeight.Normal
                            )
                            Text(
                                text = participant.amount.format(uiState.currency),
                                style = MaterialTheme.typography.bodyMedium,
                                fontWeight = FontWeight.SemiBold
                            )
                        }
                    }
                }
            }
        } else {
            // Custom Split Mode (Itemized vs Direct)
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(MaterialTheme.spacing.xs)
            ) {
                FilterChip(
                    selected = uiState.customSplitSubMode == CustomSplitSubMode.ITEMIZED,
                    onClick = { onCustomSubModeChange(CustomSplitSubMode.ITEMIZED) },
                    label = { Text(stringResource(R.string.split_custom_mode_items)) },
                    shape = PillShape,
                    colors = FilterChipDefaults.filterChipColors(
                        selectedContainerColor = MaterialTheme.colorScheme.primaryContainer,
                        selectedLabelColor = MaterialTheme.colorScheme.onPrimaryContainer
                    )
                )
                FilterChip(
                    selected = uiState.customSplitSubMode == CustomSplitSubMode.DIRECT,
                    onClick = { onCustomSubModeChange(CustomSplitSubMode.DIRECT) },
                    label = { Text(stringResource(R.string.split_custom_mode_direct)) },
                    shape = PillShape,
                    colors = FilterChipDefaults.filterChipColors(
                        selectedContainerColor = MaterialTheme.colorScheme.primaryContainer,
                        selectedLabelColor = MaterialTheme.colorScheme.onPrimaryContainer
                    )
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

            // Balance Indicator
            CustomSplitBalanceIndicator(
                totalAmount = uiState.totalAmount,
                allocatedAmount = uiState.customValidation.allocatedAmount,
                remainingAmount = uiState.customValidation.remainingAmount,
                overallocatedAmount = uiState.customValidation.overallocatedAmount,
                currency = uiState.currency
            )

            Spacer(modifier = Modifier.height(MaterialTheme.spacing.md))

            if (uiState.customSplitSubMode == CustomSplitSubMode.ITEMIZED) {
                // Itemized Split Mode
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Text(
                        text = "Items & Products (${uiState.items.size})",
                        style = MaterialTheme.typography.titleSmall,
                        fontWeight = FontWeight.Bold
                    )
                    Button(
                        onClick = onAddItem,
                        shape = PillShape,
                        contentPadding = androidx.compose.foundation.layout.PaddingValues(horizontal = 12.dp, vertical = 6.dp)
                    ) {
                        Icon(imageVector = Icons.Default.Add, contentDescription = null, modifier = Modifier.size(16.dp))
                        Spacer(modifier = Modifier.width(4.dp))
                        Text(stringResource(R.string.split_add_item), style = MaterialTheme.typography.labelMedium)
                    }
                }

                Spacer(modifier = Modifier.height(MaterialTheme.spacing.xs))

                if (uiState.items.isEmpty()) {
                    Card(
                        modifier = Modifier.fillMaxWidth(),
                        shape = CardShape,
                        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.5f)),
                        border = CardDefaults.outlinedCardBorder()
                    ) {
                        Column(
                            modifier = Modifier
                                .fillMaxWidth()
                                .padding(MaterialTheme.spacing.lg),
                            horizontalAlignment = Alignment.CenterHorizontally
                        ) {
                            Text(
                                text = "No items added yet",
                                style = MaterialTheme.typography.titleSmall,
                                fontWeight = FontWeight.Bold
                            )
                            Spacer(modifier = Modifier.height(4.dp))
                            Text(
                                text = "Everyone participates in the base bill equally. Add items to assign specific product costs to consumers.",
                                style = MaterialTheme.typography.bodySmall,
                                color = MaterialTheme.colorScheme.onSurfaceVariant,
                                textAlign = androidx.compose.ui.text.style.TextAlign.Center
                            )
                            Spacer(modifier = Modifier.height(MaterialTheme.spacing.sm))
                            OutlinedButton(onClick = onAddItem, shape = PillShape) {
                                Text(stringResource(R.string.split_add_item))
                            }
                        }
                    }
                } else {
                    Column(verticalArrangement = Arrangement.spacedBy(MaterialTheme.spacing.sm)) {
                        uiState.items.forEachIndexed { itemIndex, item ->
                            ItemRowCard(
                                item = item,
                                allParticipants = uiState.participants,
                                currency = uiState.currency,
                                onUpdateName = { onUpdateItemName(item.id, it) },
                                onUpdateAmount = { onUpdateItemAmount(item.id, it) },
                                onToggleConsumer = { onToggleItemConsumer(item.id, it) },
                                onToggleCustom = { onToggleItemCustomAllocation(item.id, it) },
                                onUpdateCustomShare = { p, amt -> onUpdateItemCustomShare(item.id, p, amt) },
                                onRemove = { onRemoveItem(item.id) },
                                onOpenCalculator = onOpenCalculator
                            )
                        }
                    }
                }

                Spacer(modifier = Modifier.height(MaterialTheme.spacing.md))

                // Shared / Remaining Unallocated Section
                val remainingSubunits = uiState.totalAmount.subunits - uiState.items.sumOf { it.amount.subunits }
                if (remainingSubunits > 0L) {
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
                                TextButton(onClick = onDistributeSharedRemainingToAll) {
                                    Text(stringResource(R.string.split_distribute_to_all), style = MaterialTheme.typography.labelSmall)
                                }
                            }

                            Spacer(modifier = Modifier.height(MaterialTheme.spacing.xs))

                            Text(
                                text = "Split remaining among:",
                                style = MaterialTheme.typography.labelSmall,
                                fontWeight = FontWeight.SemiBold
                            )
                            Spacer(modifier = Modifier.height(4.dp))

                            FlowRow(
                                horizontalArrangement = Arrangement.spacedBy(4.dp),
                                verticalArrangement = Arrangement.spacedBy(4.dp)
                            ) {
                                uiState.participants.forEach { pName ->
                                    val isSelected = uiState.sharedRemainingParticipants.any { it.equals(pName, ignoreCase = true) }
                                    FilterChip(
                                        selected = isSelected,
                                        onClick = { onToggleSharedRemainingParticipant(pName) },
                                        label = { Text(pName) },
                                        shape = PillShape
                                    )
                                }
                            }
                        }
                    }
                }

                Spacer(modifier = Modifier.height(MaterialTheme.spacing.md))

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
                        uiState.calculatedParticipants.forEach { participant ->
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
                                    Text(
                                        text = if (participant.isCurrentUser) "${participant.name} (You)" else participant.name,
                                        style = MaterialTheme.typography.bodyMedium,
                                        fontWeight = if (participant.isCurrentUser) FontWeight.Bold else FontWeight.Medium
                                    )
                                    Text(
                                        text = participant.amount.format(uiState.currency),
                                        style = MaterialTheme.typography.bodyMedium,
                                        fontWeight = FontWeight.Bold,
                                        color = if (participant.amount.subunits > 0L) MaterialTheme.colorScheme.primary else MaterialTheme.colorScheme.onSurfaceVariant
                                    )
                                }
                            }
                        }
                    }
                }
            } else {
                // Direct Per-Person Custom Mode
                Column(verticalArrangement = Arrangement.spacedBy(MaterialTheme.spacing.sm)) {
                    uiState.participants.forEach { name ->
                        val isMe = name.equals("Me", ignoreCase = true) || name.equals(uiState.paidBy, ignoreCase = true)
                        val currentVal = uiState.customSharesInput[name] ?: ""

                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            verticalAlignment = Alignment.CenterVertically,
                            horizontalArrangement = Arrangement.SpaceBetween
                        ) {
                            Text(
                                text = if (isMe) "$name (You)" else name,
                                style = MaterialTheme.typography.bodyMedium,
                                fontWeight = if (isMe) FontWeight.Bold else FontWeight.Medium,
                                modifier = Modifier.weight(1f)
                            )
                            OutlinedTextField(
                                value = currentVal,
                                onValueChange = { onCustomShareChange(name, it) },
                                prefix = { Text(uiState.currency.symbol) },
                                trailingIcon = {
                                    IconButton(onClick = { onOpenCalculator(CalculatorTarget.DirectShare(name, currentVal)) }) {
                                        Icon(
                                            imageVector = Icons.Default.Calculate,
                                            contentDescription = "Calculator",
                                            tint = MaterialTheme.colorScheme.primary,
                                            modifier = Modifier.size(18.dp)
                                        )
                                    }
                                },
                                placeholder = { Text("0") },
                                modifier = Modifier.width(160.dp),
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

@OptIn(ExperimentalLayoutApi::class)
@Composable
private fun ItemRowCard(
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
            // Row 1: Name, Amount with Calculator, Remove Button
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

            // Row 2: Consumer Assignment Chips
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

            // Row 3: Per-person share display & Advanced Allocation Toggle
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

            // Custom allocation per consumer if toggled
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
                            Text(
                                text = consumerName,
                                style = MaterialTheme.typography.bodySmall,
                                modifier = Modifier.weight(1f)
                            )
                            OutlinedTextField(
                                value = currentVal,
                                onValueChange = { onUpdateCustomShare(consumerName, it) },
                                prefix = { Text(currency.symbol) },
                                placeholder = { Text("0") },
                                trailingIcon = {
                                    IconButton(onClick = {
                                        onOpenCalculator(CalculatorTarget.ItemCustomShare(item.id, consumerName, currentVal))
                                    }) {
                                        Icon(
                                            imageVector = Icons.Default.Calculate,
                                            contentDescription = "Calculator",
                                            tint = MaterialTheme.colorScheme.primary,
                                            modifier = Modifier.size(16.dp)
                                        )
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

@Composable
private fun Step4PaymentQr(
    uiState: CreateSplitUiState,
    onUploadClick: () -> Unit,
    onRemoveQr: () -> Unit
) {
    Column(modifier = Modifier.fillMaxWidth()) {
        Text(
            text = stringResource(R.string.split_qr_section_title),
            style = MaterialTheme.typography.titleMedium,
            fontWeight = FontWeight.SemiBold,
            color = MaterialTheme.colorScheme.onSurface
        )
        Spacer(modifier = Modifier.height(MaterialTheme.spacing.xs))
        Text(
            text = "Upload the recipient's UPI QR code so participants can easily pay their share.",
            style = MaterialTheme.typography.bodySmall,
            color = MaterialTheme.colorScheme.onSurfaceVariant
        )

        Spacer(modifier = Modifier.height(MaterialTheme.spacing.md))

        if (uiState.qrImageBitmap != null) {
            Card(
                modifier = Modifier.fillMaxWidth(),
                shape = CardShape,
                colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface),
                border = CardDefaults.outlinedCardBorder()
            ) {
                Column(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(MaterialTheme.spacing.md),
                    horizontalAlignment = Alignment.CenterHorizontally
                ) {
                    Text(
                        text = stringResource(R.string.split_qr_preview_title),
                        style = MaterialTheme.typography.labelLarge,
                        fontWeight = FontWeight.Bold
                    )
                    Spacer(modifier = Modifier.height(MaterialTheme.spacing.md))

                    Image(
                        bitmap = uiState.qrImageBitmap,
                        contentDescription = "UPI QR Code Preview",
                        modifier = Modifier
                            .size(200.dp)
                            .clip(RoundedCornerShape(8.dp))
                            .border(1.dp, MaterialTheme.colorScheme.outlineVariant, RoundedCornerShape(8.dp)),
                        contentScale = ContentScale.Fit
                    )

                    Spacer(modifier = Modifier.height(MaterialTheme.spacing.md))

                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.Center
                    ) {
                        OutlinedButton(
                            onClick = onUploadClick,
                            shape = ButtonShape
                        ) {
                            Text(stringResource(R.string.split_replace_qr_btn))
                        }
                        Spacer(modifier = Modifier.width(MaterialTheme.spacing.sm))
                        TextButton(
                            onClick = onRemoveQr,
                            shape = ButtonShape,
                            colors = ButtonDefaults.textButtonColors(contentColor = MaterialTheme.colorScheme.error)
                        ) {
                            Text(stringResource(R.string.split_remove_qr_btn))
                        }
                    }
                }
            }
        } else {
            Card(
                modifier = Modifier
                    .fillMaxWidth()
                    .clip(CardShape)
                    .clickable(onClick = onUploadClick),
                shape = CardShape,
                colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.5f)),
                border = CardDefaults.outlinedCardBorder()
            ) {
                Column(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(MaterialTheme.spacing.xl),
                    horizontalAlignment = Alignment.CenterHorizontally,
                    verticalArrangement = Arrangement.Center
                ) {
                    Box(
                        modifier = Modifier
                            .size(56.dp)
                            .clip(CircleShape)
                            .background(MaterialTheme.colorScheme.primary.copy(alpha = 0.1f)),
                        contentAlignment = Alignment.Center
                    ) {
                        Icon(
                            imageVector = Icons.Default.Image,
                            contentDescription = null,
                            tint = MaterialTheme.colorScheme.primary,
                            modifier = Modifier.size(28.dp)
                        )
                    }

                    Spacer(modifier = Modifier.height(MaterialTheme.spacing.sm))

                    Text(
                        text = stringResource(R.string.split_upload_qr_btn),
                        style = MaterialTheme.typography.labelLarge,
                        fontWeight = FontWeight.SemiBold,
                        color = MaterialTheme.colorScheme.primary
                    )

                    Spacer(modifier = Modifier.height(4.dp))

                    Text(
                        text = "PNG, JPG up to 10MB (Optional)",
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }
            }
        }

        Spacer(modifier = Modifier.height(MaterialTheme.spacing.md))

        Text(
            text = stringResource(R.string.split_qr_disclaimer),
            style = MaterialTheme.typography.bodySmall,
            color = MaterialTheme.colorScheme.onSurfaceVariant
        )
    }
}

@Composable
private fun Step5Review(
    uiState: CreateSplitUiState
) {
    val dateFormat = SimpleDateFormat("EEE, MMM d, yyyy", Locale.getDefault())

    Column(modifier = Modifier.fillMaxWidth()) {
        Text(
            text = "Review & Create",
            style = MaterialTheme.typography.titleMedium,
            fontWeight = FontWeight.SemiBold,
            color = MaterialTheme.colorScheme.onSurface
        )
        Spacer(modifier = Modifier.height(MaterialTheme.spacing.xs))
        Text(
            text = "Check the final settlement numbers before saving.",
            style = MaterialTheme.typography.bodySmall,
            color = MaterialTheme.colorScheme.onSurfaceVariant
        )

        Spacer(modifier = Modifier.height(MaterialTheme.spacing.md))

        // Expense Summary Card
        Card(
            modifier = Modifier.fillMaxWidth(),
            shape = CardShape,
            colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface),
            border = CardDefaults.outlinedCardBorder()
        ) {
            Column(modifier = Modifier.padding(MaterialTheme.spacing.md)) {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Column {
                        Text(
                            text = uiState.title,
                            style = MaterialTheme.typography.titleMedium,
                            fontWeight = FontWeight.Bold
                        )
                        Text(
                            text = dateFormat.format(Date(uiState.date)),
                            style = MaterialTheme.typography.bodySmall,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                    }
                    Text(
                        text = uiState.totalAmount.format(uiState.currency),
                        style = MaterialTheme.typography.titleLarge,
                        fontWeight = FontWeight.Bold,
                        color = MaterialTheme.colorScheme.primary
                    )
                }

                Spacer(modifier = Modifier.height(MaterialTheme.spacing.md))

                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween
                ) {
                    Column {
                        Text(
                            text = "Your Share",
                            style = MaterialTheme.typography.labelSmall,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                        Text(
                            text = uiState.userShare.format(uiState.currency),
                            style = MaterialTheme.typography.bodyLarge,
                            fontWeight = FontWeight.SemiBold
                        )
                    }
                    Column(horizontalAlignment = Alignment.End) {
                        Text(
                            text = "To Collect",
                            style = MaterialTheme.typography.labelSmall,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                        Text(
                            text = uiState.toCollectAmount.format(uiState.currency),
                            style = MaterialTheme.typography.bodyLarge,
                            fontWeight = FontWeight.Bold,
                            color = IncomeEmerald
                        )
                    }
                }
            }
        }

        Spacer(modifier = Modifier.height(MaterialTheme.spacing.md))

        // Breakdown per participant
        Card(
            modifier = Modifier.fillMaxWidth(),
            shape = CardShape,
            colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface),
            border = CardDefaults.outlinedCardBorder()
        ) {
            Column(modifier = Modifier.padding(MaterialTheme.spacing.md)) {
                Text(
                    text = "Individual Shares",
                    style = MaterialTheme.typography.titleSmall,
                    fontWeight = FontWeight.Bold
                )
                Spacer(modifier = Modifier.height(MaterialTheme.spacing.xs))

                uiState.calculatedParticipants.forEach { participant ->
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(vertical = 4.dp),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Column {
                            Text(
                                text = if (participant.isCurrentUser) "${participant.name} (You)" else participant.name,
                                style = MaterialTheme.typography.bodyMedium,
                                fontWeight = if (participant.isCurrentUser) FontWeight.Bold else FontWeight.Medium
                            )
                            if (!participant.phoneNumber.isNullOrBlank()) {
                                Text(
                                    text = participant.phoneNumber,
                                    style = MaterialTheme.typography.labelSmall,
                                    color = MaterialTheme.colorScheme.onSurfaceVariant
                                )
                            }
                        }
                        Text(
                            text = participant.amount.format(uiState.currency),
                            style = MaterialTheme.typography.bodyMedium,
                            fontWeight = FontWeight.Bold
                        )
                    }
                }
            }
        }
    }
}
