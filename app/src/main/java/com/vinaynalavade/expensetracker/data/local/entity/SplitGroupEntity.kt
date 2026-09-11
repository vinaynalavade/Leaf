package com.vinaynalavade.expensetracker.data.local.entity

import androidx.room.ColumnInfo
import androidx.room.Entity
import androidx.room.PrimaryKey
import com.vinaynalavade.expensetracker.domain.model.SplitGroup

@Entity(tableName = "split_groups")
data class SplitGroupEntity(
    @PrimaryKey(autoGenerate = true)
    @ColumnInfo(name = "id")
    val id: Long = 0L,

    @ColumnInfo(name = "name")
    val name: String,

    @ColumnInfo(name = "icon_name", defaultValue = "group")
    val iconName: String = "group",

    @ColumnInfo(name = "color_hex", defaultValue = "#3B82F6")
    val colorHex: String = "#3B82F6",

    @ColumnInfo(name = "created_at")
    val createdAt: Long = System.currentTimeMillis()
) {
    fun toDomainModel(): SplitGroup {
        return SplitGroup(
            id = id,
            name = name,
            iconName = iconName,
            colorHex = colorHex,
            createdAt = createdAt
        )
    }

    companion object {
        fun fromDomainModel(group: SplitGroup): SplitGroupEntity {
            return SplitGroupEntity(
                id = group.id,
                name = group.name,
                iconName = group.iconName,
                colorHex = group.colorHex,
                createdAt = group.createdAt
            )
        }
    }
}
