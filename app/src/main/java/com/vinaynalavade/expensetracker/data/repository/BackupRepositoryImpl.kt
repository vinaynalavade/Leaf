package com.vinaynalavade.expensetracker.data.repository

import androidx.room.withTransaction
import com.vinaynalavade.expensetracker.core.backup.BackupBudget
import com.vinaynalavade.expensetracker.core.backup.BackupCategory
import com.vinaynalavade.expensetracker.core.backup.BackupData
import com.vinaynalavade.expensetracker.core.backup.BackupPreferences
import com.vinaynalavade.expensetracker.core.backup.BackupRecurringTransaction
import com.vinaynalavade.expensetracker.core.backup.BackupSavingsGoal
import com.vinaynalavade.expensetracker.core.backup.BackupSavingsGoalContribution
import com.vinaynalavade.expensetracker.core.backup.BackupSplitExpense
import com.vinaynalavade.expensetracker.core.backup.BackupSplitGroup
import com.vinaynalavade.expensetracker.core.backup.BackupSplitParticipant
import com.vinaynalavade.expensetracker.core.backup.BackupTransaction
import com.vinaynalavade.expensetracker.core.backup.BackupValidationResult
import com.vinaynalavade.expensetracker.core.backup.CsvTransactionHelper
import com.vinaynalavade.expensetracker.core.backup.ImportValidationResult
import com.vinaynalavade.expensetracker.core.backup.JsonBackupParser
import com.vinaynalavade.expensetracker.core.model.Amount
import com.vinaynalavade.expensetracker.core.model.Currency
import com.vinaynalavade.expensetracker.core.result.AppError
import com.vinaynalavade.expensetracker.core.result.AppResult
import com.vinaynalavade.expensetracker.data.local.database.ExpenseTrackerDatabase
import com.vinaynalavade.expensetracker.data.local.entity.BudgetEntity
import com.vinaynalavade.expensetracker.data.local.entity.CategoryEntity
import com.vinaynalavade.expensetracker.data.local.entity.RecurringTransactionEntity
import com.vinaynalavade.expensetracker.data.local.entity.SavingsGoalContributionEntity
import com.vinaynalavade.expensetracker.data.local.entity.SavingsGoalEntity
import com.vinaynalavade.expensetracker.data.local.entity.SplitExpenseEntity
import com.vinaynalavade.expensetracker.data.local.entity.SplitGroupEntity
import com.vinaynalavade.expensetracker.data.local.entity.SplitParticipantEntity
import com.vinaynalavade.expensetracker.data.local.entity.TransactionEntity
import com.vinaynalavade.expensetracker.domain.model.Category
import com.vinaynalavade.expensetracker.domain.model.PaymentMethod
import com.vinaynalavade.expensetracker.domain.model.RecurrenceFrequency
import com.vinaynalavade.expensetracker.domain.model.ThemeMode
import com.vinaynalavade.expensetracker.domain.model.Transaction
import com.vinaynalavade.expensetracker.domain.model.TransactionType
import com.vinaynalavade.expensetracker.domain.repository.BackupRepository
import com.vinaynalavade.expensetracker.domain.repository.CategoryRepository
import com.vinaynalavade.expensetracker.domain.repository.RecurringTransactionRepository
import com.vinaynalavade.expensetracker.domain.repository.TransactionRepository
import com.vinaynalavade.expensetracker.domain.repository.UserPreferencesRepository
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.firstOrNull

class BackupRepositoryImpl(
    private val database: ExpenseTrackerDatabase,
    private val transactionRepository: TransactionRepository,
    private val categoryRepository: CategoryRepository,
    private val recurringTransactionRepository: RecurringTransactionRepository,
    private val userPreferencesRepository: UserPreferencesRepository
) : BackupRepository {

    override fun getLastBackupTimestamp(): Flow<Long?> {
        return userPreferencesRepository.getLastBackupTimestamp()
    }

    override suspend fun createFullBackup(): AppResult<BackupData> {
        return try {
            val categories = categoryRepository.getCategories().firstOrNull() ?: emptyList()
            val transactions = transactionRepository.getTransactions().firstOrNull() ?: emptyList()
            val recurringList = recurringTransactionRepository.getRecurringTransactions().firstOrNull() ?: emptyList()
            val prefs = userPreferencesRepository.getUserPreferences().firstOrNull()

            val budgetsWithCat = database.budgetDao().getAllBudgets().firstOrNull() ?: emptyList()
            val goalsWithContribs = database.savingsGoalDao().getAllSavingsGoals().firstOrNull() ?: emptyList()
            val splitGroupsList = database.splitGroupDao().getAllGroups().firstOrNull() ?: emptyList()
            val splitExpensesWithDetails = database.splitDao().getAllSplitExpenses().firstOrNull() ?: emptyList()

            val backupCategories = categories.map { cat ->
                BackupCategory(
                    id = cat.id,
                    name = cat.name,
                    iconName = cat.iconName,
                    colorHex = cat.colorHex,
                    type = cat.type.name,
                    isDefault = cat.isDefault
                )
            }

            val backupTransactions = transactions.map { tx ->
                BackupTransaction(
                    id = tx.id,
                    amountSubunits = tx.amount.subunits,
                    type = tx.type.name,
                    categoryId = tx.category.id,
                    paymentMethod = tx.paymentMethod.name,
                    note = tx.note,
                    timestamp = tx.timestamp
                )
            }

            val backupRecurring = recurringList.map { rec ->
                BackupRecurringTransaction(
                    id = rec.id,
                    title = rec.title,
                    amountSubunits = rec.amount.subunits,
                    type = rec.type.name,
                    categoryId = rec.category.id,
                    paymentMethod = rec.paymentMethod.name,
                    note = rec.note,
                    frequency = rec.frequency.name,
                    dayOfMonth = rec.dayOfMonth,
                    dayOfWeek = rec.dayOfWeek,
                    startDate = rec.startDate,
                    endDate = rec.endDate,
                    isEnabled = rec.isEnabled,
                    isAutoGenerated = rec.isAutoGenerated,
                    reminderDaysBefore = rec.reminderDaysBefore,
                    lastGeneratedDate = rec.lastGeneratedDate,
                    createdAt = rec.createdAt,
                    updatedAt = rec.updatedAt
                )
            }

            val backupBudgets = budgetsWithCat.map { b ->
                BackupBudget(
                    id = b.budget.id,
                    categoryId = b.budget.categoryId,
                    amountSubunits = b.budget.amountSubunits,
                    month = b.budget.month,
                    year = b.budget.year,
                    createdAt = b.budget.createdAt,
                    updatedAt = b.budget.updatedAt
                )
            }

            val backupSavingsGoals = goalsWithContribs.map { g ->
                BackupSavingsGoal(
                    id = g.goal.id,
                    name = g.goal.name,
                    targetAmountSubunits = g.goal.targetAmountSubunits,
                    targetDate = g.goal.targetDate,
                    note = g.goal.note,
                    iconName = g.goal.iconName,
                    colorHex = g.goal.colorHex,
                    isArchived = g.goal.isArchived,
                    createdAt = g.goal.createdAt,
                    updatedAt = g.goal.updatedAt
                )
            }

            val backupContributions = goalsWithContribs.flatMap { g ->
                g.contributions.map { c ->
                    BackupSavingsGoalContribution(
                        id = c.id,
                        goalId = c.goalId,
                        amountSubunits = c.amountSubunits,
                        note = c.note,
                        timestamp = c.timestamp,
                        createdAt = c.createdAt
                    )
                }
            }

            val backupSplitGroups = splitGroupsList.map { g ->
                BackupSplitGroup(
                    id = g.id,
                    name = g.name,
                    iconName = g.iconName,
                    colorHex = g.colorHex,
                    createdAt = g.createdAt
                )
            }

            val backupSplitExpenses = splitExpensesWithDetails.map { s ->
                BackupSplitExpense(
                    id = s.expense.id,
                    title = s.expense.title,
                    totalAmountSubunits = s.expense.totalAmountSubunits,
                    date = s.expense.date,
                    categoryId = s.expense.categoryId,
                    paidBy = s.expense.paidBy,
                    splitMethod = s.expense.splitMethod,
                    qrImagePath = s.expense.qrImagePath,
                    addToTransactions = s.expense.addToTransactions,
                    expenseTransactionId = s.expense.expenseTransactionId,
                    paymentMethod = s.expense.paymentMethod,
                    groupId = s.expense.groupId,
                    createdAt = s.expense.createdAt,
                    updatedAt = s.expense.updatedAt
                )
            }

            val backupSplitParticipants = splitExpensesWithDetails.flatMap { s ->
                s.participants.map { p ->
                    BackupSplitParticipant(
                        id = p.id,
                        splitExpenseId = p.splitExpenseId,
                        name = p.name,
                        isCurrentUser = p.isCurrentUser,
                        amountSubunits = p.amountSubunits,
                        settlementStatus = p.settlementStatus,
                        settledAt = p.settledAt,
                        settlementTransactionId = p.settlementTransactionId
                    )
                }
            }

            val backupPreferences = BackupPreferences(
                openingBalanceSubunits = prefs?.openingBalanceSubunits ?: 0L,
                currencyCode = prefs?.currency?.code ?: "INR",
                themeMode = prefs?.themeMode?.name ?: "SYSTEM",
                dailyReminderEnabled = prefs?.dailyReminderEnabled ?: false,
                dailyReminderHour = prefs?.dailyReminderHour ?: 21,
                dailyReminderMinute = prefs?.dailyReminderMinute ?: 0,
                emiRemindersEnabled = prefs?.emiRemindersEnabled ?: true,
                notificationsMasterEnabled = prefs?.notificationsMasterEnabled ?: false,
                budgetAlertsEnabled = prefs?.budgetAlertsEnabled ?: false,
                monthlyBudgetLimitSubunits = prefs?.monthlyBudgetLimitSubunits ?: 0L,
                recurringRemindersEnabled = prefs?.recurringRemindersEnabled ?: false,
                recurringReminderAdvanceDays = prefs?.recurringReminderAdvanceDays ?: 1,
                savingsGoalNotificationsEnabled = prefs?.savingsGoalNotificationsEnabled ?: false
            )

            val now = System.currentTimeMillis()
            val backupData = BackupData(
                backupVersion = BackupData.CURRENT_VERSION,
                appVersion = com.vinaynalavade.expensetracker.BuildConfig.VERSION_NAME,
                createdAt = now,
                categories = backupCategories,
                transactions = backupTransactions,
                recurringTransactions = backupRecurring,
                preferences = backupPreferences,
                budgets = backupBudgets,
                savingsGoals = backupSavingsGoals,
                savingsGoalContributions = backupContributions,
                splitGroups = backupSplitGroups,
                splitExpenses = backupSplitExpenses,
                splitParticipants = backupSplitParticipants
            )

            userPreferencesRepository.setLastBackupTimestamp(now)
            AppResult.Success(backupData)
        } catch (e: Exception) {
            AppResult.Error(AppError.DatabaseError(e.message ?: "Failed to create backup.", e))
        }
    }

    override suspend fun validateBackupJson(jsonString: String): BackupValidationResult {
        return try {
            val backup = JsonBackupParser.fromJson(jsonString)

            if (backup.backupVersion > BackupData.CURRENT_VERSION) {
                return BackupValidationResult.Invalid("Backup version ${backup.backupVersion} is newer than supported version (${BackupData.CURRENT_VERSION}). Please update Leaf.")
            }
            if (backup.backupVersion <= 0) {
                return BackupValidationResult.Invalid("Invalid backup version ${backup.backupVersion}.")
            }

            if (backup.categories.isEmpty()) {
                return BackupValidationResult.Invalid("Corrupted backup: No categories found in file.")
            }

            val categoryIds = backup.categories.map { it.id }.toSet()

            // Validate that all transactions have valid categories and amounts
            for (tx in backup.transactions) {
                if (tx.amountSubunits <= 0L) {
                    return BackupValidationResult.Invalid("Invalid transaction amount in backup (ID: ${tx.id}).")
                }
                if (tx.categoryId !in categoryIds) {
                    return BackupValidationResult.Invalid("Relationship integrity error: Transaction ${tx.id} references missing category ${tx.categoryId}.")
                }
                if (tx.type != "EXPENSE" && tx.type != "INCOME") {
                    return BackupValidationResult.Invalid("Invalid transaction type '${tx.type}' for transaction ${tx.id}.")
                }
            }

            // Validate recurring transactions
            for (rec in backup.recurringTransactions) {
                if (rec.amountSubunits <= 0L) {
                    return BackupValidationResult.Invalid("Invalid recurring amount in backup (ID: ${rec.id}).")
                }
                if (rec.categoryId !in categoryIds) {
                    return BackupValidationResult.Invalid("Relationship integrity error: Recurring transaction ${rec.id} references missing category ${rec.categoryId}.")
                }
            }

            // Validate budgets
            for (b in backup.budgets) {
                if (b.categoryId != null && b.categoryId !in categoryIds) {
                    return BackupValidationResult.Invalid("Relationship integrity error: Budget ${b.id} references missing category ${b.categoryId}.")
                }
            }

            // Validate savings goal contributions
            val goalIds = backup.savingsGoals.map { it.id }.toSet()
            for (c in backup.savingsGoalContributions) {
                if (c.goalId !in goalIds) {
                    return BackupValidationResult.Invalid("Relationship integrity error: Contribution ${c.id} references missing savings goal ${c.goalId}.")
                }
            }

            // Validate split expenses and participants
            val groupIds = backup.splitGroups.map { it.id }.toSet()
            for (se in backup.splitExpenses) {
                if (se.categoryId !in categoryIds) {
                    return BackupValidationResult.Invalid("Relationship integrity error: Split expense ${se.id} references missing category ${se.categoryId}.")
                }
                if (se.groupId != null && se.groupId !in groupIds) {
                    return BackupValidationResult.Invalid("Relationship integrity error: Split expense ${se.id} references missing group ${se.groupId}.")
                }
            }

            val expenseIds = backup.splitExpenses.map { it.id }.toSet()
            for (sp in backup.splitParticipants) {
                if (sp.splitExpenseId !in expenseIds) {
                    return BackupValidationResult.Invalid("Relationship integrity error: Participant ${sp.id} references missing split expense ${sp.splitExpenseId}.")
                }
            }

            BackupValidationResult.Valid(
                backupData = backup,
                transactionCount = backup.transactions.size,
                categoryCount = backup.categories.size,
                recurringCount = backup.recurringTransactions.size,
                createdAt = backup.createdAt,
                appVersion = backup.appVersion
            )
        } catch (e: Exception) {
            BackupValidationResult.Invalid(e.message ?: "Malformed or unreadable backup file.")
        }
    }

    override suspend fun restoreFullBackup(backupData: BackupData): AppResult<Unit> {
        return try {
            val categoryEntities = backupData.categories.map { cat ->
                CategoryEntity(
                    id = cat.id,
                    name = cat.name,
                    iconName = cat.iconName,
                    colorHex = cat.colorHex,
                    type = cat.type,
                    isDefault = cat.isDefault
                )
            }

            val transactionEntities = backupData.transactions.map { tx ->
                TransactionEntity(
                    id = tx.id,
                    amountSubunits = tx.amountSubunits,
                    type = tx.type,
                    categoryId = tx.categoryId,
                    paymentMethod = tx.paymentMethod,
                    note = tx.note,
                    timestamp = tx.timestamp
                )
            }

            val recurringEntities = backupData.recurringTransactions.map { rec ->
                RecurringTransactionEntity(
                    id = rec.id,
                    title = rec.title,
                    amountSubunits = rec.amountSubunits,
                    type = rec.type,
                    categoryId = rec.categoryId,
                    paymentMethod = rec.paymentMethod,
                    note = rec.note,
                    frequency = rec.frequency,
                    dayOfMonth = rec.dayOfMonth,
                    dayOfWeek = rec.dayOfWeek,
                    startDate = rec.startDate,
                    endDate = rec.endDate,
                    isEnabled = rec.isEnabled,
                    isAutoGenerated = rec.isAutoGenerated,
                    reminderDaysBefore = rec.reminderDaysBefore,
                    lastGeneratedDate = rec.lastGeneratedDate,
                    createdAt = rec.createdAt,
                    updatedAt = rec.updatedAt
                )
            }

            val budgetEntities = backupData.budgets.map { b ->
                BudgetEntity(
                    id = b.id,
                    categoryId = b.categoryId,
                    amountSubunits = b.amountSubunits,
                    month = b.month,
                    year = b.year,
                    createdAt = b.createdAt,
                    updatedAt = b.updatedAt
                )
            }

            val savingsGoalEntities = backupData.savingsGoals.map { g ->
                SavingsGoalEntity(
                    id = g.id,
                    name = g.name,
                    targetAmountSubunits = g.targetAmountSubunits,
                    targetDate = g.targetDate,
                    note = g.note,
                    iconName = g.iconName,
                    colorHex = g.colorHex,
                    isArchived = g.isArchived,
                    createdAt = g.createdAt,
                    updatedAt = g.updatedAt
                )
            }

            val contributionEntities = backupData.savingsGoalContributions.map { c ->
                SavingsGoalContributionEntity(
                    id = c.id,
                    goalId = c.goalId,
                    amountSubunits = c.amountSubunits,
                    note = c.note,
                    timestamp = c.timestamp,
                    createdAt = c.createdAt
                )
            }

            val splitGroupEntities = backupData.splitGroups.map { g ->
                SplitGroupEntity(
                    id = g.id,
                    name = g.name,
                    iconName = g.iconName,
                    colorHex = g.colorHex,
                    createdAt = g.createdAt
                )
            }

            val splitExpenseEntities = backupData.splitExpenses.map { se ->
                SplitExpenseEntity(
                    id = se.id,
                    title = se.title,
                    totalAmountSubunits = se.totalAmountSubunits,
                    date = se.date,
                    categoryId = se.categoryId,
                    paidBy = se.paidBy,
                    splitMethod = se.splitMethod,
                    qrImagePath = se.qrImagePath,
                    addToTransactions = se.addToTransactions,
                    expenseTransactionId = se.expenseTransactionId,
                    paymentMethod = se.paymentMethod,
                    groupId = se.groupId,
                    createdAt = se.createdAt,
                    updatedAt = se.updatedAt
                )
            }

            val splitParticipantEntities = backupData.splitParticipants.map { sp ->
                SplitParticipantEntity(
                    id = sp.id,
                    splitExpenseId = sp.splitExpenseId,
                    name = sp.name,
                    isCurrentUser = sp.isCurrentUser,
                    amountSubunits = sp.amountSubunits,
                    settlementStatus = sp.settlementStatus,
                    settledAt = sp.settledAt,
                    settlementTransactionId = sp.settlementTransactionId
                )
            }

            // Execute in an atomic database transaction
            database.withTransaction {
                // Delete children and dependent tables first
                database.savingsGoalDao().deleteAllContributions()
                database.savingsGoalDao().deleteAllGoals()
                database.budgetDao().deleteAllBudgets()
                database.splitDao().deleteAllParticipants()
                database.splitDao().deleteAllSplitExpenses()
                database.splitGroupDao().deleteAllGroups()
                database.recurringTransactionDao().deleteAllRecurringTransactions()
                database.transactionDao().deleteAllTransactions()
                database.categoryDao().deleteAllCategories()

                // Insert parents first, then children
                database.categoryDao().insertOrUpdateCategories(categoryEntities)
                database.transactionDao().insertTransactions(transactionEntities)
                database.recurringTransactionDao().insertRecurringTransactions(recurringEntities)
                database.splitGroupDao().insertGroups(splitGroupEntities)
                database.splitDao().insertExpenses(splitExpenseEntities)
                database.splitDao().insertParticipants(splitParticipantEntities)
                database.budgetDao().insertBudgets(budgetEntities)
                database.savingsGoalDao().insertGoals(savingsGoalEntities)
                database.savingsGoalDao().insertContributions(contributionEntities)
            }

            // Restore user preferences
            userPreferencesRepository.setOpeningBalance(backupData.preferences.openingBalanceSubunits)
            userPreferencesRepository.setCurrencyCode(backupData.preferences.currencyCode)
            userPreferencesRepository.setThemeMode(ThemeMode.fromString(backupData.preferences.themeMode))
            userPreferencesRepository.setDailyReminder(
                backupData.preferences.dailyReminderEnabled,
                backupData.preferences.dailyReminderHour,
                backupData.preferences.dailyReminderMinute
            )
            userPreferencesRepository.setEmiReminders(backupData.preferences.emiRemindersEnabled)
            userPreferencesRepository.setNotificationsMasterEnabled(backupData.preferences.notificationsMasterEnabled)
            userPreferencesRepository.setBudgetAlertsEnabled(backupData.preferences.budgetAlertsEnabled)
            userPreferencesRepository.setMonthlyBudgetLimit(backupData.preferences.monthlyBudgetLimitSubunits)
            userPreferencesRepository.setRecurringRemindersEnabled(backupData.preferences.recurringRemindersEnabled)
            userPreferencesRepository.setRecurringReminderAdvanceDays(backupData.preferences.recurringReminderAdvanceDays)
            userPreferencesRepository.setSavingsGoalNotificationsEnabled(backupData.preferences.savingsGoalNotificationsEnabled)
            userPreferencesRepository.setLastBackupTimestamp(System.currentTimeMillis())

            AppResult.Success(Unit)
        } catch (e: Exception) {
            AppResult.Error(AppError.DatabaseError(e.message ?: "Failed to restore backup.", e))
        }
    }

    override suspend fun getFilteredTransactions(
        startDate: Long?,
        endDate: Long?,
        type: TransactionType?,
        categoryId: Long?
    ): AppResult<List<Transaction>> {
        return try {
            val allTransactions = if (startDate != null && endDate != null) {
                transactionRepository.getTransactionsBetween(startDate, endDate).firstOrNull() ?: emptyList()
            } else {
                transactionRepository.getTransactions().firstOrNull() ?: emptyList()
            }

            val filtered = allTransactions.filter { tx ->
                val matchesType = type == null || tx.type == type
                val matchesCategory = categoryId == null || tx.category.id == categoryId
                matchesType && matchesCategory
            }

            AppResult.Success(filtered)
        } catch (e: Exception) {
            AppResult.Error(AppError.DatabaseError(e.message ?: "Failed to query transactions.", e))
        }
    }

    override suspend fun validateAndPrepareImportCsv(
        csvContent: String,
        defaultCurrency: Currency
    ): ImportValidationResult {
        val existingCategories = categoryRepository.getCategories().firstOrNull() ?: emptyList()
        val parsedRows = CsvTransactionHelper.parseCsv(csvContent, defaultCurrency)
        val validTransactions = mutableListOf<Transaction>()
        val issues = mutableListOf<String>()

        for (row in parsedRows) {
            if (!row.isValid) {
                issues.add(row.errorMessage ?: "Row ${row.rowIndex}: Invalid data")
                continue
            }

            val matchedCategory = existingCategories.find {
                it.name.trim().equals(row.categoryName?.trim(), ignoreCase = true) &&
                        it.type == row.type
            } ?: existingCategories.find {
                it.type == row.type && it.isDefault
            } ?: Category.UNCATEGORIZED

            validTransactions.add(
                Transaction(
                    id = 0L,
                    amount = row.amount ?: Amount.ZERO,
                    type = row.type ?: TransactionType.EXPENSE,
                    category = matchedCategory,
                    paymentMethod = row.paymentMethod,
                    note = row.note,
                    timestamp = row.dateEpoch ?: System.currentTimeMillis()
                )
            )
        }

        return ImportValidationResult(
            totalRows = parsedRows.size,
            validTransactions = validTransactions,
            issues = issues
        )
    }

    override suspend fun validateAndPrepareImportJson(jsonContent: String): ImportValidationResult {
        return try {
            val parsedTxList = JsonBackupParser.parseTransactionsJson(jsonContent)
            val existingCategories = categoryRepository.getCategories().firstOrNull() ?: emptyList()
            val validTransactions = mutableListOf<Transaction>()
            val issues = mutableListOf<String>()

            for ((index, item) in parsedTxList.withIndex()) {
                val type = try {
                    TransactionType.fromString(item.type)
                } catch (_: Exception) {
                    issues.add("Item ${index + 1}: Invalid transaction type '${item.type}'")
                    continue
                }

                val matchedCategory = existingCategories.find { it.id == item.categoryId }
                    ?: existingCategories.find { it.type == type && it.isDefault }
                    ?: Category.UNCATEGORIZED

                val paymentMethod = try {
                    PaymentMethod.fromString(item.paymentMethod)
                } catch (_: Exception) {
                    PaymentMethod.CASH
                }

                validTransactions.add(
                    Transaction(
                        id = 0L,
                        amount = Amount(item.amountSubunits),
                        type = type,
                        category = matchedCategory,
                        paymentMethod = paymentMethod,
                        note = item.note,
                        timestamp = item.timestamp
                    )
                )
            }

            ImportValidationResult(
                totalRows = parsedTxList.size,
                validTransactions = validTransactions,
                issues = issues
            )
        } catch (e: Exception) {
            ImportValidationResult(
                totalRows = 0,
                validTransactions = emptyList(),
                issues = listOf(e.message ?: "Failed to parse JSON file.")
            )
        }
    }

    override suspend fun importTransactions(transactions: List<Transaction>): AppResult<Int> {
        return try {
            var count = 0
            for (tx in transactions) {
                val result = transactionRepository.insertTransaction(tx)
                if (result is AppResult.Success) {
                    count++
                }
            }
            AppResult.Success(count)
        } catch (e: Exception) {
            AppResult.Error(AppError.DatabaseError(e.message ?: "Failed to import transactions.", e))
        }
    }
}
