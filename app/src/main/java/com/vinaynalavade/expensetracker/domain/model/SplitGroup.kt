package com.vinaynalavade.expensetracker.domain.model

/**
 * Domain model representing a shared finance group or occasion (e.g. "Goa Trip", "Apartment 301").
 */
data class SplitGroup(
    val id: Long = 0L,
    val name: String,
    val iconName: String = "group",
    val colorHex: String = "#3B82F6",
    val createdAt: Long = System.currentTimeMillis()
)
