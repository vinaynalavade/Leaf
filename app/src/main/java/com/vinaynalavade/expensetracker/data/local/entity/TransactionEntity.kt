package com.vinaynalavade.expensetracker.data.local.entity

import androidx.room.ColumnInfo
import androidx.room.Embedded
import androidx.room.Entity
import androidx.room.ForeignKey
import androidx.room.Index
import androidx.room.PrimaryKey
import androidx.room.Relation
import com.vinaynalavade.expensetracker.core.model.Amount
import com.vinaynalavade.expensetracker.domain.model.Category
import com.vinaynalavade.expensetracker.domain.model.PaymentMethod
import com.vinaynalavade.expensetracker.domain.model.Transaction
import com.vinaynalavade.expensetracker.domain.model.TransactionType

@Entity(
    tableName = "transactions",
    foreignKeys = [
        ForeignKey(
            entity = CategoryEntity::class,
            parentColumns = ["id"],
            childColumns = ["category_id"],
            onDelete = ForeignKey.RESTRICT
        )
    ],
    indices = [
        Index(value = ["category_id"]),
        Index(value = ["timestamp"]),
        Index(value = ["type"]),
        Index(value = ["payment_method"]),
        Index(value = ["transfer_pair_id"]),
        Index(value = ["is_internal_transfer"])
    ]
)
data class TransactionEntity(
    @PrimaryKey(autoGenerate = true)
    @ColumnInfo(name = "id")
    val id: Long = 0L,

    @ColumnInfo(name = "amount_subunits")
    val amountSubunits: Long,

    @ColumnInfo(name = "type")
    val type: String,

    @ColumnInfo(name = "category_id")
    val categoryId: Long,

    @ColumnInfo(name = "payment_method", defaultValue = "CASH")
    val paymentMethod: String = "CASH",

    @ColumnInfo(name = "note")
    val note: String? = null,

    @ColumnInfo(name = "timestamp")
    val timestamp: Long,

    @ColumnInfo(name = "created_at")
    val createdAt: Long = timestamp,

    @ColumnInfo(name = "updated_at")
    val updatedAt: Long = timestamp,

    @ColumnInfo(name = "raw_payment_method")
    val rawPaymentMethod: String? = null,

    @ColumnInfo(name = "transfer_pair_id")
    val transferPairId: Long? = null,

    @ColumnInfo(name = "is_internal_transfer", defaultValue = "0")
    val isInternalTransfer: Boolean = false
) {
    companion object {
        fun fromDomainModel(transaction: Transaction): TransactionEntity {
            return TransactionEntity(
                id = transaction.id,
                amountSubunits = transaction.amount.subunits,
                type = transaction.type.name,
                categoryId = transaction.category.id,
                paymentMethod = transaction.paymentMethod.name,
                note = transaction.note,
                timestamp = transaction.timestamp,
                createdAt = transaction.createdAt,
                updatedAt = transaction.updatedAt,
                rawPaymentMethod = transaction.rawPaymentMethod ?: transaction.paymentMethod.name,
                transferPairId = transaction.transferPairId,
                isInternalTransfer = transaction.isInternalTransfer
            )
        }
    }
}

/**
 * Relation model for fetching transaction with its associated category entity.
 */
data class TransactionWithCategory(
    @Embedded
    val transaction: TransactionEntity,

    @Relation(
        parentColumn = "category_id",
        entityColumn = "id"
    )
    val category: CategoryEntity?
) {
    fun toDomainModel(): Transaction {
        return Transaction(
            id = transaction.id,
            amount = Amount.fromSubunits(transaction.amountSubunits),
            type = TransactionType.fromString(transaction.type),
            category = category?.toDomainModel() ?: Category.UNCATEGORIZED,
            paymentMethod = PaymentMethod.fromString(transaction.paymentMethod),
            note = transaction.note,
            timestamp = transaction.timestamp,
            createdAt = transaction.createdAt,
            updatedAt = transaction.updatedAt,
            rawPaymentMethod = transaction.rawPaymentMethod,
            transferPairId = transaction.transferPairId,
            isInternalTransfer = transaction.isInternalTransfer
        )
    }
}
