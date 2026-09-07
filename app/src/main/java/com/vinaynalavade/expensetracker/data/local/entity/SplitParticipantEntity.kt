package com.vinaynalavade.expensetracker.data.local.entity

import androidx.room.ColumnInfo
import androidx.room.Entity
import androidx.room.ForeignKey
import androidx.room.Index
import androidx.room.PrimaryKey
import com.vinaynalavade.expensetracker.core.model.Amount
import com.vinaynalavade.expensetracker.domain.model.SettlementStatus
import com.vinaynalavade.expensetracker.domain.model.SplitParticipant

@Entity(
    tableName = "split_participants",
    foreignKeys = [
        ForeignKey(
            entity = SplitExpenseEntity::class,
            parentColumns = ["id"],
            childColumns = ["split_expense_id"],
            onDelete = ForeignKey.CASCADE
        )
    ],
    indices = [
        Index("split_expense_id")
    ]
)
data class SplitParticipantEntity(
    @PrimaryKey(autoGenerate = true)
    @ColumnInfo(name = "id")
    val id: Long = 0L,

    @ColumnInfo(name = "split_expense_id")
    val splitExpenseId: Long,

    @ColumnInfo(name = "name")
    val name: String,

    @ColumnInfo(name = "is_current_user")
    val isCurrentUser: Boolean,

    @ColumnInfo(name = "amount_subunits")
    val amountSubunits: Long,

    @ColumnInfo(name = "settlement_status")
    val settlementStatus: String = "PENDING",

    @ColumnInfo(name = "settled_at")
    val settledAt: Long? = null
) {
    fun toDomainModel(): SplitParticipant {
        return SplitParticipant(
            id = id,
            splitExpenseId = splitExpenseId,
            name = name,
            isCurrentUser = isCurrentUser,
            amount = Amount(amountSubunits),
            settlementStatus = try { SettlementStatus.valueOf(settlementStatus) } catch (_: Exception) { SettlementStatus.PENDING },
            settledAt = settledAt
        )
    }

    companion object {
        fun fromDomainModel(participant: SplitParticipant, parentExpenseId: Long): SplitParticipantEntity {
            return SplitParticipantEntity(
                id = participant.id,
                splitExpenseId = if (participant.splitExpenseId != 0L) participant.splitExpenseId else parentExpenseId,
                name = participant.name,
                isCurrentUser = participant.isCurrentUser,
                amountSubunits = participant.amount.subunits,
                settlementStatus = participant.settlementStatus.name,
                settledAt = participant.settledAt
            )
        }
    }
}
