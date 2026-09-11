package com.vinaynalavade.expensetracker.core.split

import com.vinaynalavade.expensetracker.core.model.Amount
import com.vinaynalavade.expensetracker.domain.model.SettlementStatus
import com.vinaynalavade.expensetracker.domain.model.SplitExpense

data class ParticipantDebt(
    val debtorName: String,
    val isDebtorCurrentUser: Boolean,
    val creditorName: String,
    val isCreditorCurrentUser: Boolean,
    val netAmount: Amount
)

data class GroupBalanceSummary(
    val totalExpensesCount: Int,
    val totalGroupSpend: Amount,
    val netOwedToCurrentUser: Amount,  // Amount others owe me
    val netCurrentUserOwes: Amount,     // Amount I owe others
    val debts: List<ParticipantDebt>
)

object NetBalanceEngine {

    /**
     * Compute directional net balances across a list of SplitExpense items.
     * Uses participant.isCurrentUser == true as the sole authority for current-user identity.
     */
    fun calculateNetBalances(expenses: List<SplitExpense>): GroupBalanceSummary {
        var totalGroupSpendSubunits = 0L
        var totalExpensesCount = 0

        // Map of pairwise net debt: (Debtor, Creditor) -> Subunits owed
        // Key is Pair(debtorName, creditorName)
        val pairwiseNetDebt = mutableMapOf<Pair<String, String>, Long>()
        val currentUserParticipantMap = mutableMapOf<String, Boolean>()

        for (expense in expenses) {
            totalExpensesCount++
            totalGroupSpendSubunits += expense.totalAmount.subunits

            val payer = expense.participants.find { it.name.equals(expense.paidBy, ignoreCase = true) }
            val payerName = expense.paidBy
            val isPayerCurrentUser = payer?.isCurrentUser == true
            currentUserParticipantMap[payerName] = isPayerCurrentUser

            for (participant in expense.participants) {
                currentUserParticipantMap[participant.name] = participant.isCurrentUser

                // If this participant is the payer, they do not owe themselves
                if (participant.name.equals(payerName, ignoreCase = true)) {
                    continue
                }

                // If already settled, no outstanding debt exists
                if (participant.settlementStatus == SettlementStatus.SETTLED) {
                    continue
                }

                val amountOwedSubunits = participant.amount.subunits
                if (amountOwedSubunits <= 0L) {
                    continue
                }

                // Participant owes Payer amountOwedSubunits
                val forwardKey = Pair(participant.name, payerName)
                val reverseKey = Pair(payerName, participant.name)

                val existingReverse = pairwiseNetDebt.getOrDefault(reverseKey, 0L)
                if (existingReverse > 0L) {
                    if (existingReverse >= amountOwedSubunits) {
                        pairwiseNetDebt[reverseKey] = existingReverse - amountOwedSubunits
                    } else {
                        pairwiseNetDebt.remove(reverseKey)
                        pairwiseNetDebt[forwardKey] = amountOwedSubunits - existingReverse
                    }
                } else {
                    val existingForward = pairwiseNetDebt.getOrDefault(forwardKey, 0L)
                    pairwiseNetDebt[forwardKey] = existingForward + amountOwedSubunits
                }
            }
        }

        var owedToCurrentUserSubunits = 0L
        var currentUserOwesSubunits = 0L

        val debtList = mutableListOf<ParticipantDebt>()

        for ((pair, amountSubunits) in pairwiseNetDebt) {
            if (amountSubunits <= 0L) continue

            val debtor = pair.first
            val creditor = pair.second
            val isDebtorMe = currentUserParticipantMap[debtor] == true
            val isCreditorMe = currentUserParticipantMap[creditor] == true

            if (isCreditorMe && !isDebtorMe) {
                owedToCurrentUserSubunits += amountSubunits
            } else if (isDebtorMe && !isCreditorMe) {
                currentUserOwesSubunits += amountSubunits
            }

            debtList.add(
                ParticipantDebt(
                    debtorName = debtor,
                    isDebtorCurrentUser = isDebtorMe,
                    creditorName = creditor,
                    isCreditorCurrentUser = isCreditorMe,
                    netAmount = Amount(amountSubunits)
                )
            )
        }

        return GroupBalanceSummary(
            totalExpensesCount = totalExpensesCount,
            totalGroupSpend = Amount(totalGroupSpendSubunits),
            netOwedToCurrentUser = Amount(owedToCurrentUserSubunits),
            netCurrentUserOwes = Amount(currentUserOwesSubunits),
            debts = debtList.sortedByDescending { it.netAmount.subunits }
        )
    }
}
