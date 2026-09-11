package com.vinaynalavade.expensetracker.domain.usecase

import com.vinaynalavade.expensetracker.domain.model.CategorySpendingSummary
import com.vinaynalavade.expensetracker.domain.model.MonthlySpendingPoint
import com.vinaynalavade.expensetracker.domain.model.SpendingTrendData
import com.vinaynalavade.expensetracker.domain.model.TransactionType
import com.vinaynalavade.expensetracker.domain.repository.CategoryRepository
import com.vinaynalavade.expensetracker.domain.repository.TransactionRepository
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.combine
import java.time.Instant
import java.time.LocalDate
import java.time.YearMonth
import java.time.ZoneId
import java.time.format.DateTimeFormatter
import java.util.Locale

class GetSpendingTrendsUseCase(
    private val transactionRepository: TransactionRepository,
    private val categoryRepository: CategoryRepository
) {
    operator fun invoke(monthsCount: Int = 6): Flow<SpendingTrendData> {
        return combine(
            transactionRepository.getTransactions(),
            categoryRepository.getCategories()
        ) { transactions, categories ->
            val zone = ZoneId.systemDefault()
            val currentYearMonth = YearMonth.now(zone)
            val monthFormatter = DateTimeFormatter.ofPattern("MMM yyyy", Locale.getDefault())

            val targetMonths = (monthsCount - 1 downTo 0).map { offset ->
                currentYearMonth.minusMonths(offset.toLong())
            }

            val categoryMap = categories.associateBy { it.id }

            val points = targetMonths.map { ym ->
                val startEpoch = ym.atDay(1).atStartOfDay(zone).toInstant().toEpochMilli()
                val endEpoch = ym.atEndOfMonth().atTime(23, 59, 59, 999_999_999).atZone(zone).toInstant().toEpochMilli()

                val monthTransactions = transactions.filter { it.timestamp in startEpoch..endEpoch }
                val expenseSum = monthTransactions
                    .filter { it.type == TransactionType.EXPENSE }
                    .sumOf { it.amount.subunits / 100.0 }
                val incomeSum = monthTransactions
                    .filter { it.type == TransactionType.INCOME }
                    .sumOf { it.amount.subunits / 100.0 }

                MonthlySpendingPoint(
                    yearMonth = ym.format(monthFormatter),
                    epochMonthStart = startEpoch,
                    totalExpense = expenseSum,
                    totalIncome = incomeSum
                )
            }

            val totalExpenseOverPeriod = points.sumOf { it.totalExpense }
            val averageMonthlyExpense = if (points.isNotEmpty()) totalExpenseOverPeriod / points.size else 0.0

            // MoM Growth: compare last month (points.last()) to previous month (points[points.size - 2])
            val currentMonthExpense = points.lastOrNull()?.totalExpense ?: 0.0
            val previousMonthExpense = if (points.size >= 2) points[points.size - 2].totalExpense else 0.0
            val momGrowth = if (previousMonthExpense > 0) {
                ((currentMonthExpense - previousMonthExpense) / previousMonthExpense) * 100.0
            } else {
                0.0
            }

            // Category breakdown for the entire period
            val periodStartEpoch = targetMonths.first().atDay(1).atStartOfDay(zone).toInstant().toEpochMilli()
            val periodEndEpoch = targetMonths.last().atEndOfMonth().atTime(23, 59, 59, 999_999_999).atZone(zone).toInstant().toEpochMilli()

            val periodExpenseTxs = transactions.filter {
                it.type == TransactionType.EXPENSE && it.timestamp in periodStartEpoch..periodEndEpoch
            }
            val periodTotalExpense = periodExpenseTxs.sumOf { it.amount.subunits / 100.0 }

            val categoryBreakdown = periodExpenseTxs
                .groupBy { it.category.id }
                .map { (catId, txList) ->
                    val catTotal = txList.sumOf { it.amount.subunits / 100.0 }
                    val cat = categoryMap[catId]
                    CategorySpendingSummary(
                        categoryId = catId,
                        categoryName = cat?.name ?: "Uncategorized",
                        categoryIcon = cat?.iconName ?: "more_horiz",
                        categoryColorHex = cat?.colorHex ?: "#64748B",
                        totalAmount = catTotal,
                        percentageOfTotal = if (periodTotalExpense > 0) (catTotal / periodTotalExpense) * 100.0 else 0.0
                    )
                }
                .sortedByDescending { it.totalAmount }

            SpendingTrendData(
                monthlyPoints = points,
                averageMonthlyExpense = averageMonthlyExpense,
                monthOverMonthGrowthRate = momGrowth,
                categoryBreakdown = categoryBreakdown
            )
        }
    }
}
