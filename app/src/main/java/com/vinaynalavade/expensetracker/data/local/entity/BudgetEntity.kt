package com.vinaynalavade.expensetracker.data.local.entity

import androidx.room.ColumnInfo
import androidx.room.Embedded
import androidx.room.Entity
import androidx.room.ForeignKey
import androidx.room.Index
import androidx.room.PrimaryKey
import androidx.room.Relation
import com.vinaynalavade.expensetracker.core.model.Amount
import com.vinaynalavade.expensetracker.domain.model.Budget

@Entity(
    tableName = "budgets",
    foreignKeys = [
        ForeignKey(
            entity = CategoryEntity::class,
            parentColumns = ["id"],
            childColumns = ["category_id"],
            onDelete = ForeignKey.SET_NULL
        )
    ],
    indices = [
        Index(value = ["year", "month"]),
        Index(value = ["category_id"])
    ]
)
data class BudgetEntity(
    @PrimaryKey(autoGenerate = true)
    @ColumnInfo(name = "id")
    val id: Long = 0L,

    @ColumnInfo(name = "category_id")
    val categoryId: Long? = null,

    @ColumnInfo(name = "amount_subunits")
    val amountSubunits: Long,

    @ColumnInfo(name = "month")
    val month: Int,

    @ColumnInfo(name = "year")
    val year: Int,

    @ColumnInfo(name = "created_at")
    val createdAt: Long = System.currentTimeMillis(),

    @ColumnInfo(name = "updated_at")
    val updatedAt: Long = System.currentTimeMillis()
) {
    fun toDomainModel(category: CategoryEntity? = null): Budget {
        return Budget(
            id = id,
            categoryId = categoryId,
            category = category?.toDomainModel(),
            amount = Amount.fromSubunits(amountSubunits),
            month = month,
            year = year,
            createdAt = createdAt,
            updatedAt = updatedAt
        )
    }

    companion object {
        fun fromDomainModel(budget: Budget): BudgetEntity {
            return BudgetEntity(
                id = budget.id,
                categoryId = budget.categoryId,
                amountSubunits = budget.amount.subunits,
                month = budget.month,
                year = budget.year,
                createdAt = budget.createdAt,
                updatedAt = budget.updatedAt
            )
        }
    }
}

/**
 * Relation model combining a BudgetEntity with its optional CategoryEntity.
 */
data class BudgetWithCategory(
    @Embedded
    val budget: BudgetEntity,

    @Relation(
        parentColumn = "category_id",
        entityColumn = "id"
    )
    val category: CategoryEntity?
) {
    fun toDomainModel(): Budget {
        return budget.toDomainModel(category)
    }
}
