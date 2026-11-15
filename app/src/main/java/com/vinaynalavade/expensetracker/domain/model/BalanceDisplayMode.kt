package com.vinaynalavade.expensetracker.domain.model

/**
 * Display modes for the dashboard balance hero card.
 *
 * Controls the displayed balance without modifying underlying financial data or ledger balances:
 * - [COMBINED]: Combined total balance (Account + Cash)
 * - [ACCOUNT]: Account balance only
 * - [CASH]: Cash balance only
 */
enum class BalanceDisplayMode(val displayName: String) {
    COMBINED("Combined"),
    ACCOUNT("Account"),
    CASH("Cash")
}
