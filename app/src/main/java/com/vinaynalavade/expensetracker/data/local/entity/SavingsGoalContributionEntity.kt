package com.vinaynalavade.expensetracker.data.local.entity

import androidx.room.ColumnInfo
import androidx.room.Entity
import androidx.room.ForeignKey
import androidx.room.Index
import androidx.room.PrimaryKey
import com.vinaynalavade.expensetracker.core.model.Amount
import com.vinaynalavade.expensetracker.domain.model.SavingsGoalContribution

@Entity(
    tableName = "savings_goal_contributions",
    foreignKeys = [
        ForeignKey(
            entity = SavingsGoalEntity::class,
            parentColumns = ["id"],
            childColumns = ["goal_id"],
            onDelete = ForeignKey.CASCADE
        )
    ],
    indices = [
        Index(value = ["goal_id"])
    ]
)
data class SavingsGoalContributionEntity(
    @PrimaryKey(autoGenerate = true)
    @ColumnInfo(name = "id")
    val id: Long = 0L,

    @ColumnInfo(name = "goal_id")
    val goalId: Long,

    @ColumnInfo(name = "amount_subunits")
    val amountSubunits: Long,

    @ColumnInfo(name = "note")
    val note: String? = null,

    @ColumnInfo(name = "timestamp")
    val timestamp: Long = System.currentTimeMillis(),

    @ColumnInfo(name = "created_at")
    val createdAt: Long = System.currentTimeMillis()
) {
    fun toDomainModel(): SavingsGoalContribution {
        return SavingsGoalContribution(
            id = id,
            goalId = goalId,
            amount = Amount.fromSubunits(amountSubunits),
            note = note,
            timestamp = timestamp,
            createdAt = createdAt
        )
    }

    companion object {
        fun fromDomainModel(contribution: SavingsGoalContribution): SavingsGoalContributionEntity {
            return SavingsGoalContributionEntity(
                id = contribution.id,
                goalId = contribution.goalId,
                amountSubunits = contribution.amount.subunits,
                note = contribution.note,
                timestamp = contribution.timestamp,
                createdAt = contribution.createdAt
            )
        }
    }
}
