package com.vinaynalavade.expensetracker.data.local.entity

import androidx.room.ColumnInfo
import androidx.room.Entity
import androidx.room.ForeignKey
import androidx.room.Index
import androidx.room.PrimaryKey
import com.vinaynalavade.expensetracker.core.model.Amount
import com.vinaynalavade.expensetracker.domain.model.Category
import com.vinaynalavade.expensetracker.domain.model.SplitExpense
import com.vinaynalavade.expensetracker.domain.model.SplitMethod
import com.vinaynalavade.expensetracker.domain.model.SplitParticipant

@Entity(
    tableName = "split_expenses",
    foreignKeys = [
        ForeignKey(
            entity = CategoryEntity::class,
            parentColumns = ["id"],
            childColumns = ["category_id"],
            onDelete = ForeignKey.RESTRICT
        )
    ],
    indices = [
        Index("category_id")
    ]
)
data class SplitExpenseEntity(
    @PrimaryKey(autoGenerate = true)
    @ColumnInfo(name = "id")
    val id: Long = 0L,

    @ColumnInfo(name = "title")
    val title: String,

    @ColumnInfo(name = "total_amount_subunits")
    val totalAmountSubunits: Long,

    @ColumnInfo(name = "date")
    val date: Long,

    @ColumnInfo(name = "category_id")
    val categoryId: Long,

    @ColumnInfo(name = "paid_by")
    val paidBy: String = "Me",

    @ColumnInfo(name = "split_method")
    val splitMethod: String = "EQUAL",

    @ColumnInfo(name = "qr_image_path")
    val qrImagePath: String? = null,

    @ColumnInfo(name = "created_at")
    val createdAt: Long = date,

    @ColumnInfo(name = "updated_at")
    val updatedAt: Long = date
) {
    fun toDomainModel(category: Category?, participants: List<SplitParticipant>): SplitExpense {
        return SplitExpense(
            id = id,
            title = title,
            totalAmount = Amount(totalAmountSubunits),
            date = date,
            categoryId = categoryId,
            category = category,
            paidBy = paidBy,
            splitMethod = try { SplitMethod.valueOf(splitMethod) } catch (_: Exception) { SplitMethod.EQUAL },
            qrImagePath = qrImagePath,
            participants = participants,
            createdAt = createdAt,
            updatedAt = updatedAt
        )
    }

    companion object {
        fun fromDomainModel(splitExpense: SplitExpense): SplitExpenseEntity {
            return SplitExpenseEntity(
                id = splitExpense.id,
                title = splitExpense.title,
                totalAmountSubunits = splitExpense.totalAmount.subunits,
                date = splitExpense.date,
                categoryId = splitExpense.categoryId,
                paidBy = splitExpense.paidBy,
                splitMethod = splitExpense.splitMethod.name,
                qrImagePath = splitExpense.qrImagePath,
                createdAt = splitExpense.createdAt,
                updatedAt = splitExpense.updatedAt
            )
        }
    }
}
