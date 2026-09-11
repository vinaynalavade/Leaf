package com.vinaynalavade.expensetracker.data.local.entity

import androidx.room.ColumnInfo
import androidx.room.Embedded
import androidx.room.Entity
import androidx.room.PrimaryKey
import androidx.room.Relation
import com.vinaynalavade.expensetracker.core.model.Amount
import com.vinaynalavade.expensetracker.domain.model.SavingsGoal

@Entity(tableName = "savings_goals")
data class SavingsGoalEntity(
    @PrimaryKey(autoGenerate = true)
    @ColumnInfo(name = "id")
    val id: Long = 0L,

    @ColumnInfo(name = "name")
    val name: String,

    @ColumnInfo(name = "target_amount_subunits")
    val targetAmountSubunits: Long,

    @ColumnInfo(name = "target_date")
    val targetDate: Long? = null,

    @ColumnInfo(name = "note")
    val note: String? = null,

    @ColumnInfo(name = "icon_name", defaultValue = "savings")
    val iconName: String = "savings",

    @ColumnInfo(name = "color_hex", defaultValue = "#10B981")
    val colorHex: String = "#10B981",

    @ColumnInfo(name = "is_archived", defaultValue = "0")
    val isArchived: Boolean = false,

    @ColumnInfo(name = "created_at")
    val createdAt: Long = System.currentTimeMillis(),

    @ColumnInfo(name = "updated_at")
    val updatedAt: Long = System.currentTimeMillis()
) {
    fun toDomainModel(contributions: List<SavingsGoalContributionEntity> = emptyList()): SavingsGoal {
        return SavingsGoal(
            id = id,
            name = name,
            targetAmount = Amount.fromSubunits(targetAmountSubunits),
            targetDate = targetDate,
            note = note,
            iconName = iconName,
            colorHex = colorHex,
            isArchived = isArchived,
            contributions = contributions.map { it.toDomainModel() },
            createdAt = createdAt,
            updatedAt = updatedAt
        )
    }

    companion object {
        fun fromDomainModel(goal: SavingsGoal): SavingsGoalEntity {
            return SavingsGoalEntity(
                id = goal.id,
                name = goal.name,
                targetAmountSubunits = goal.targetAmount.subunits,
                targetDate = goal.targetDate,
                note = goal.note,
                iconName = goal.iconName,
                colorHex = goal.colorHex,
                isArchived = goal.isArchived,
                createdAt = goal.createdAt,
                updatedAt = goal.updatedAt
            )
        }
    }
}

/**
 * Relation model combining a SavingsGoalEntity with its associated contributions.
 */
data class SavingsGoalWithContributions(
    @Embedded
    val goal: SavingsGoalEntity,

    @Relation(
        parentColumn = "id",
        entityColumn = "goal_id"
    )
    val contributions: List<SavingsGoalContributionEntity>
) {
    fun toDomainModel(): SavingsGoal {
        return goal.toDomainModel(contributions)
    }
}
