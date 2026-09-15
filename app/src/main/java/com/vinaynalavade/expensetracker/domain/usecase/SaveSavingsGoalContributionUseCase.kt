package com.vinaynalavade.expensetracker.domain.usecase

import com.vinaynalavade.expensetracker.core.constants.AppConstants
import com.vinaynalavade.expensetracker.core.result.AppError
import com.vinaynalavade.expensetracker.core.result.AppResult
import com.vinaynalavade.expensetracker.domain.model.Category
import com.vinaynalavade.expensetracker.domain.model.PaymentMethod
import com.vinaynalavade.expensetracker.domain.model.SavingsGoalContribution
import com.vinaynalavade.expensetracker.domain.model.Transaction
import com.vinaynalavade.expensetracker.domain.model.TransactionType
import com.vinaynalavade.expensetracker.domain.repository.CategoryRepository
import com.vinaynalavade.expensetracker.domain.repository.SavingsGoalRepository
import com.vinaynalavade.expensetracker.domain.repository.TransactionRepository
import kotlinx.coroutines.flow.first

class SaveSavingsGoalContributionUseCase(
    private val savingsGoalRepository: SavingsGoalRepository,
    private val transactionRepository: TransactionRepository? = null,
    private val categoryRepository: CategoryRepository? = null
) {
    suspend operator fun invoke(
        contribution: SavingsGoalContribution,
        deductFromAccount: Boolean = false
    ): AppResult<Long> {
        if (contribution.amount.subunits <= 0L) {
            return AppResult.Error(AppError.ValidationError("Contribution amount must be greater than zero."))
        }
        if (contribution.amount.subunits > 100_000_000_000_000L) {
            return AppResult.Error(AppError.ValidationError("Contribution amount exceeds maximum allowed limit."))
        }
        if (contribution.timestamp > System.currentTimeMillis()) {
            return AppResult.Error(AppError.ValidationError("Contribution date cannot be in the future."))
        }

        val goal = savingsGoalRepository.getSavingsGoalByIdSuspend(contribution.goalId)
            ?: return AppResult.Error(AppError.ValidationError("Associated savings goal not found."))

        if (goal.isArchived) {
            return AppResult.Error(AppError.ValidationError("Cannot add or modify contributions for an archived savings goal."))
        }

        var linkedTransactionId: Long? = contribution.transactionId
        val catRepo = categoryRepository
        val txRepo = transactionRepository
        if (deductFromAccount && linkedTransactionId == null && txRepo != null && catRepo != null) {
            // Find or create internal "Savings & Goals" category
            val allCategories = catRepo.getCategories().first()
            val savingsCategory = allCategories.firstOrNull {
                it.name.equals(AppConstants.CATEGORY_SAVINGS_AND_GOALS, ignoreCase = true)
            } ?: run {
                val newCat = Category(
                    id = 0L,
                    name = AppConstants.CATEGORY_SAVINGS_AND_GOALS,
                    iconName = "savings",
                    colorHex = "#10B981",
                    type = TransactionType.EXPENSE,
                    isDefault = false
                )
                val insertResult = catRepo.insertCategory(newCat)
                if (insertResult is AppResult.Success) {
                    newCat.copy(id = insertResult.data)
                } else {
                    newCat
                }
            }

            val noteText = if (!contribution.note.isNullOrBlank()) {
                "Contribution: ${goal.name} (${contribution.note})"
            } else {
                "Contribution: ${goal.name}"
            }

            val transaction = Transaction(
                id = 0L,
                amount = contribution.amount,
                type = TransactionType.EXPENSE,
                category = savingsCategory,
                timestamp = contribution.timestamp,
                note = noteText,
                paymentMethod = PaymentMethod.ACCOUNT
            )

            val txResult = txRepo.insertTransaction(transaction)
            if (txResult is AppResult.Success) {
                linkedTransactionId = txResult.data
            }
        }

        val contributionToSave = contribution.copy(transactionId = linkedTransactionId)

        return if (contributionToSave.id == 0L) {
            savingsGoalRepository.addContribution(contributionToSave)
        } else {
            val updateResult = savingsGoalRepository.updateContribution(contributionToSave)
            when (updateResult) {
                is AppResult.Success<*> -> AppResult.Success(contributionToSave.id)
                is AppResult.Error -> updateResult
            }
        }
    }
}
