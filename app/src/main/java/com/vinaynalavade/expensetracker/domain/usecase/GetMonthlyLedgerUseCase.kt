package com.vinaynalavade.expensetracker.domain.usecase

import com.vinaynalavade.expensetracker.core.constants.AppConstants
import com.vinaynalavade.expensetracker.core.model.Amount
import com.vinaynalavade.expensetracker.core.utils.DateTimeUtils
import com.vinaynalavade.expensetracker.domain.model.Category
import com.vinaynalavade.expensetracker.domain.model.CategorySpending
import com.vinaynalavade.expensetracker.domain.model.MonthlyLedgerSummary
import com.vinaynalavade.expensetracker.domain.model.Transaction
import com.vinaynalavade.expensetracker.domain.model.TransactionType
import com.vinaynalavade.expensetracker.domain.repository.TransactionRepository
import com.vinaynalavade.expensetracker.domain.repository.UserPreferencesRepository
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.combine
import java.time.LocalDate
import java.time.YearMonth

/**
 * Calculates continuous financial continuity, opening balance carry-forward,
 * income, ordinary expenses, savings allocations, and closing balance for any requested YearMonth.
 */
class GetMonthlyLedgerUseCase(
    private val transactionRepository: TransactionRepository,
    private val userPreferencesRepository: UserPreferencesRepository
) {
    operator fun invoke(yearMonth: YearMonth): Flow<MonthlyLedgerSummary> {
        val startOfMonthEpoch = DateTimeUtils.getStartOfDayEpoch(yearMonth.atDay(1))
        val endOfMonthEpoch = DateTimeUtils.getEndOfDayEpoch(yearMonth.atEndOfMonth())

        val prevMonth = yearMonth.minusMonths(1)
        val startOfPrevMonthEpoch = DateTimeUtils.getStartOfDayEpoch(prevMonth.atDay(1))
        val endOfPrevMonthEpoch = DateTimeUtils.getEndOfDayEpoch(prevMonth.atEndOfMonth())

        return combine(
            transactionRepository.getTransactions(),
            userPreferencesRepository.getUserPreferences()
        ) { allTransactions, preferences ->
            val baseOpeningBalance = preferences.openingBalance

            // 1. Calculate past carry-forward before the current month starts
            var pastIncome = Amount.ZERO
            var pastExpense = Amount.ZERO

            val monthTransactions = mutableListOf<Transaction>()
            var monthIncome = Amount.ZERO
            var monthExpense = Amount.ZERO
            var monthOrdinaryExpense = Amount.ZERO
            var monthSavingsAllocation = Amount.ZERO

            var prevMonthOrdinaryExpense = Amount.ZERO

            val expenseCategoryMap = mutableMapOf<Long, Pair<Category, MutableList<Amount>>>()
            val incomeCategoryMap = mutableMapOf<Long, Pair<Category, MutableList<Amount>>>()

            for (tx in allTransactions) {
                if (tx.timestamp < startOfMonthEpoch) {
                    if (tx.type == TransactionType.INCOME) {
                        pastIncome += tx.amount
                    } else {
                        pastExpense += tx.amount
                    }

                    if (tx.timestamp in startOfPrevMonthEpoch..endOfPrevMonthEpoch && tx.type == TransactionType.EXPENSE) {
                        if (!tx.category.name.equals(AppConstants.CATEGORY_SAVINGS_AND_GOALS, ignoreCase = true)) {
                            prevMonthOrdinaryExpense += tx.amount
                        }
                    }
                } else if (tx.timestamp <= endOfMonthEpoch) {
                    monthTransactions.add(tx)
                    if (tx.type == TransactionType.INCOME) {
                        monthIncome += tx.amount
                        val entry = incomeCategoryMap.getOrPut(tx.category.id) { tx.category to mutableListOf() }
                        entry.second.add(tx.amount)
                    } else {
                        monthExpense += tx.amount
                        if (tx.category.name.equals(AppConstants.CATEGORY_SAVINGS_AND_GOALS, ignoreCase = true)) {
                            monthSavingsAllocation += tx.amount
                        } else {
                            monthOrdinaryExpense += tx.amount
                        }
                        val entry = expenseCategoryMap.getOrPut(tx.category.id) { tx.category to mutableListOf() }
                        entry.second.add(tx.amount)
                    }
                }
            }

            val openingBalance = baseOpeningBalance + pastIncome - pastExpense
            val closingBalance = openingBalance + monthIncome - monthExpense
            val netChange = monthIncome - monthExpense

            // Daily average spend calculation
            val now = LocalDate.now()
            val currentYearMonth = YearMonth.now()
            val daysCount = when {
                yearMonth == currentYearMonth -> now.dayOfMonth.coerceAtLeast(1)
                yearMonth.isBefore(currentYearMonth) -> yearMonth.lengthOfMonth()
                else -> 1
            }
            val dailyAvgSubunits = (monthOrdinaryExpense.subunits / daysCount.toDouble()).toLong()
            val dailyAverageExpense = Amount.fromSubunits(dailyAvgSubunits)

            // MoM Growth on ordinary expenses
            val momChangePct = if (prevMonthOrdinaryExpense.subunits > 0L) {
                ((monthOrdinaryExpense.subunits - prevMonthOrdinaryExpense.subunits).toDouble() / prevMonthOrdinaryExpense.subunits.toDouble()) * 100.0
            } else {
                null
            }

            // Compute category breakdowns
            val expenseBreakdown = expenseCategoryMap.values.map { (cat, amounts) ->
                val total = amounts.fold(Amount.ZERO) { acc, a -> acc + a }
                val pct = if (monthExpense.subunits > 0) total.subunits.toFloat() / monthExpense.subunits.toFloat() else 0f
                CategorySpending(category = cat, totalAmount = total, percentageOfTotal = pct, transactionCount = amounts.size)
            }.sortedByDescending { it.totalAmount.subunits }

            val incomeBreakdown = incomeCategoryMap.values.map { (cat, amounts) ->
                val total = amounts.fold(Amount.ZERO) { acc, a -> acc + a }
                val pct = if (monthIncome.subunits > 0) total.subunits.toFloat() / monthIncome.subunits.toFloat() else 0f
                CategorySpending(category = cat, totalAmount = total, percentageOfTotal = pct, transactionCount = amounts.size)
            }.sortedByDescending { it.totalAmount.subunits }

            MonthlyLedgerSummary(
                yearMonth = yearMonth,
                openingBalance = openingBalance,
                totalIncome = monthIncome,
                totalExpense = monthExpense,
                ordinaryExpense = monthOrdinaryExpense,
                savingsAllocation = monthSavingsAllocation,
                netChange = netChange,
                closingBalance = closingBalance,
                dailyAverageExpense = dailyAverageExpense,
                previousMonthExpense = if (prevMonthOrdinaryExpense.subunits > 0L) prevMonthOrdinaryExpense else null,
                momChangePercentage = momChangePct,
                transactions = monthTransactions.sortedByDescending { it.timestamp },
                expenseBreakdown = expenseBreakdown,
                incomeBreakdown = incomeBreakdown
            )
        }
    }
}
