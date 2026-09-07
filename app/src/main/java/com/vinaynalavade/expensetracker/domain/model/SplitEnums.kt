package com.vinaynalavade.expensetracker.domain.model

/**
 * Split method supported in Leaf v1.0.6.
 */
enum class SplitMethod {
    EQUAL,
    CUSTOM
}

/**
 * Settlement status for an individual participant's share.
 */
enum class SettlementStatus {
    PENDING,
    SETTLED
}
