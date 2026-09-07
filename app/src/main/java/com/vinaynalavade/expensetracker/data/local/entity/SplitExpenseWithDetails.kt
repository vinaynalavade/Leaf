package com.vinaynalavade.expensetracker.data.local.entity

import androidx.room.Embedded
import androidx.room.Relation
import com.vinaynalavade.expensetracker.domain.model.Category
import com.vinaynalavade.expensetracker.domain.model.SplitExpense

/**
 * Relation model combining a split expense with its associated category and participants.
 */
data class SplitExpenseWithDetails(
    @Embedded
    val expense: SplitExpenseEntity,

    @Relation(
        parentColumn = "category_id",
        entityColumn = "id"
    )
    val category: CategoryEntity?,

    @Relation(
        parentColumn = "id",
        entityColumn = "split_expense_id"
    )
    val participants: List<SplitParticipantEntity>
) {
    fun toDomainModel(): SplitExpense {
        val domainCategory = category?.toDomainModel() ?: Category.UNCATEGORIZED
        val domainParticipants = participants.map { it.toDomainModel() }
        return expense.toDomainModel(
            category = domainCategory,
            participants = domainParticipants
        )
    }
}
