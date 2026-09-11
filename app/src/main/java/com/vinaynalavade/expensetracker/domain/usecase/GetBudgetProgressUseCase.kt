package com.vinaynalavade.expensetracker.domain.usecase

import com.vinaynalavade.expensetracker.core.model.Amount
import com.vinaynalavade.expensetracker.core.utils.DateTimeUtils
import com.vinaynalavade.expensetracker.domain.model.BudgetProgress
import com.vinaynalavade.expensetracker.domain.model.BudgetStatus
import com.vinaynalavade.expensetracker.domain.model.TransactionType
import com.vinaynalavade.expensetracker.domain.repository.BudgetRepository
import com.vinaynalavade.expensetracker.domain.repository.TransactionRepository
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.combine
import java.time.YearMonth

class GetBudgetProgressUseCase(
    private val budgetRepository: BudgetRepository,
    private val transactionRepository: TransactionRepository
) {
    operator fun invoke(yearMonth: YearMonth): Flow<List<BudgetProgress>> {
        val startEpoch = DateTimeUtils.getStartOfDayEpoch(yearMonth.atDay(1))
        val endEpoch = DateTimeUtils.getEndOfDayEpoch(yearMonth.atEndOfMonth())

        return combine(
            budgetRepository.getBudgetsForMonth(yearMonth.year, yearMonth.monthValue),
            transactionRepository.getTransactions()
        ) { budgets, allTransactions ->
            val monthExpenses = allTransactions.filter {
                it.timestamp in startEpoch..endEpoch && it.type == TransactionType.EXPENSE
            }

            budgets.map { budget ->
                val usedSubunits = if (budget.isOverall) {
                    monthExpenses.sumOf { it.amount.subunits }
                } else {
                    monthExpenses.filter { it.category.id == budget.categoryId }
                        .sumOf { it.amount.subunits }
                }

                val remainingSubunits = maxOf(0L, budget.amount.subunits - usedSubunits)
                val percentageUsed = if (budget.amount.subunits > 0L) {
                    (usedSubunits.toFloat() / budget.amount.subunits.toFloat()) * 100f
                } else {
                    0f
                }

                val maxBound = 100_000_000_000_000L // 10^14 subunits overflow guard
                val safeBudgetSubunits = minOf(budget.amount.subunits, maxBound)
                val threshold75 = (safeBudgetSubunits * 75L) / 100L

                val status = when {
                    usedSubunits < threshold75 -> BudgetStatus.ON_TRACK
                    usedSubunits in threshold75 until safeBudgetSubunits -> BudgetStatus.APPROACHING_LIMIT
                    usedSubunits == safeBudgetSubunits -> BudgetStatus.LIMIT_REACHED
                    else -> BudgetStatus.OVER_BUDGET
                }

                BudgetProgress(
                    budget = budget,
                    usedAmount = Amount.fromSubunits(usedSubunits),
                    remainingAmount = Amount.fromSubunits(remainingSubunits),
                    percentageUsed = percentageUsed,
                    status = status
                )
            }
        }
    }
}
