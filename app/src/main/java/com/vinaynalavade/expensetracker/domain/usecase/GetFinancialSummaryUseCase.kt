package com.vinaynalavade.expensetracker.domain.usecase

import com.vinaynalavade.expensetracker.core.model.Amount
import com.vinaynalavade.expensetracker.domain.model.FinancialSummary
import com.vinaynalavade.expensetracker.domain.model.TransactionType
import com.vinaynalavade.expensetracker.domain.repository.TransactionRepository
import com.vinaynalavade.expensetracker.domain.repository.UserPreferencesRepository
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.combine

/**
 * UseCase to retrieve overall and date-ranged financial summaries.
 * Accurately differentiates checking account liquid cash movements from ordinary earned income and expenses:
 * - Liquid checking balance includes all cash flows (earned income, ordinary expenses, and internal transfers).
 * - Income and Expense metrics strictly reflect ordinary economic transactions (excluding internal transfers).
 */
class GetFinancialSummaryUseCase(
    private val transactionRepository: TransactionRepository,
    private val userPreferencesRepository: UserPreferencesRepository
) {
    operator fun invoke(): Flow<FinancialSummary> =
        combine(
            transactionRepository.getTransactions(),
            userPreferencesRepository.getUserPreferences()
        ) { transactions, preferences ->
            val startingBalance = preferences.openingBalance
            var earnedIncomeSubunits = 0L
            var ordinaryExpenseSubunits = 0L
            var totalInflowSubunits = 0L
            var totalOutflowSubunits = 0L

            for (tx in transactions) {
                if (tx.type == TransactionType.INCOME) {
                    totalInflowSubunits += tx.amount.subunits
                    if (!tx.isInternalTransfer) {
                        earnedIncomeSubunits += tx.amount.subunits
                    }
                } else {
                    totalOutflowSubunits += tx.amount.subunits
                    if (!tx.isInternalTransfer) {
                        ordinaryExpenseSubunits += tx.amount.subunits
                    }
                }
            }
            val totalIncome = Amount(earnedIncomeSubunits)
            val totalExpense = Amount(ordinaryExpenseSubunits)
            val netChange = totalIncome - totalExpense
            val currentBalance = startingBalance + Amount(totalInflowSubunits - totalOutflowSubunits)

            FinancialSummary(
                openingBalance = startingBalance,
                totalIncome = totalIncome,
                totalExpense = totalExpense,
                netChange = netChange,
                currentBalance = currentBalance,
                transactionCount = transactions.size
            )
        }

    fun getByDateRange(startDateEpoch: Long, endDateEpoch: Long): Flow<FinancialSummary> =
        combine(
            transactionRepository.getTransactionsBetween(startDateEpoch, endDateEpoch),
            userPreferencesRepository.getUserPreferences()
        ) { transactions, preferences ->
            val startingBalance = preferences.openingBalance
            var earnedIncomeSubunits = 0L
            var ordinaryExpenseSubunits = 0L
            var totalInflowSubunits = 0L
            var totalOutflowSubunits = 0L

            for (tx in transactions) {
                if (tx.type == TransactionType.INCOME) {
                    totalInflowSubunits += tx.amount.subunits
                    if (!tx.isInternalTransfer) {
                        earnedIncomeSubunits += tx.amount.subunits
                    }
                } else {
                    totalOutflowSubunits += tx.amount.subunits
                    if (!tx.isInternalTransfer) {
                        ordinaryExpenseSubunits += tx.amount.subunits
                    }
                }
            }
            val totalIncome = Amount(earnedIncomeSubunits)
            val totalExpense = Amount(ordinaryExpenseSubunits)
            val netChange = totalIncome - totalExpense
            val currentBalance = startingBalance + Amount(totalInflowSubunits - totalOutflowSubunits)

            FinancialSummary(
                openingBalance = startingBalance,
                totalIncome = totalIncome,
                totalExpense = totalExpense,
                netChange = netChange,
                currentBalance = currentBalance,
                transactionCount = transactions.size
            )
        }

    /**
     * Computes segregated Cash and Account ledger balances.
     * Combined total strictly equals `currentBalance` without double counting.
     */
    fun executeForLedgers(): Flow<Pair<Amount, Amount>> =
        combine(
            transactionRepository.getCashBalance(),
            transactionRepository.getAccountBalance(),
            userPreferencesRepository.getUserPreferences()
        ) { cashBalance, accountBalance, preferences ->
            val startingBalance = preferences.openingBalance
            Pair(cashBalance, accountBalance + startingBalance)
        }
}
