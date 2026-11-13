import Foundation

/// Represents a directional net debt between two participants in split expenses.
public struct ParticipantDebt: Hashable, Sendable {
    public let debtorName: String
    public let isDebtorCurrentUser: Bool
    public let creditorName: String
    public let isCreditorCurrentUser: Bool
    public let netAmount: Amount

    public init(
        debtorName: String,
        isDebtorCurrentUser: Bool,
        creditorName: String,
        isCreditorCurrentUser: Bool,
        netAmount: Amount
    ) {
        self.debtorName = debtorName
        self.isDebtorCurrentUser = isDebtorCurrentUser
        self.creditorName = creditorName
        self.isCreditorCurrentUser = isCreditorCurrentUser
        self.netAmount = netAmount
    }
}

/// Comprehensive summary of all balances, group spend, and debt relationships across split expenses.
public struct GroupBalanceSummary: Hashable, Sendable {
    public let totalExpensesCount: Int
    public let activeSplitsCount: Int
    public let totalGroupSpend: Amount
    public let netOwedToCurrentUser: Amount  // Amount others owe me
    public let netCurrentUserOwes: Amount    // Amount I owe others
    public let debts: [ParticipantDebt]

    public init(
        totalExpensesCount: Int,
        activeSplitsCount: Int = 0,
        totalGroupSpend: Amount,
        netOwedToCurrentUser: Amount,
        netCurrentUserOwes: Amount,
        debts: [ParticipantDebt] = []
    ) {
        self.totalExpensesCount = totalExpensesCount
        self.activeSplitsCount = activeSplitsCount
        self.totalGroupSpend = totalGroupSpend
        self.netOwedToCurrentUser = netOwedToCurrentUser
        self.netCurrentUserOwes = netCurrentUserOwes
        self.debts = debts
    }

    public static var empty: GroupBalanceSummary {
        GroupBalanceSummary(
            totalExpensesCount: 0,
            activeSplitsCount: 0,
            totalGroupSpend: .zero,
            netOwedToCurrentUser: .zero,
            netCurrentUserOwes: .zero,
            debts: []
        )
    }
}

/// Pure computation engine for directional net balances across a collection of split expenses.
/// Matches Leaf Android NetBalanceEngine parity with 100% precision using integer currency subunits.
public enum NetBalanceEngine {

    public struct PairKey: Hashable {
        public let debtor: String
        public let creditor: String

        public init(debtor: String, creditor: String) {
            self.debtor = debtor
            self.creditor = creditor
        }
    }

    /// Computes directional net balances, total spend, and pairwise debt simplification.
    public static func calculateNetBalances(expenses: [SplitExpense]) -> GroupBalanceSummary {
        var totalGroupSpendSubunits: Int64 = 0
        var totalExpensesCount = 0
        var activeSplitsCount = 0

        var pairwiseNetDebt: [PairKey: Int64] = [:]
        var currentUserParticipantMap: [String: Bool] = [:]

        for expense in expenses {
            totalExpensesCount += 1
            totalGroupSpendSubunits += expense.totalAmount.subunits

            let hasPending = expense.participants.contains { $0.settlementStatus != .settled && !$0.isCurrentUser }
            if hasPending {
                activeSplitsCount += 1
            }

            let payer = expense.participants.first { $0.name.caseInsensitiveCompare(expense.paidBy) == .orderedSame }
            let payerName = expense.paidBy
            let isPayerCurrentUser = payer?.isCurrentUser ?? (payerName.caseInsensitiveCompare("Me") == .orderedSame || payerName.caseInsensitiveCompare("You") == .orderedSame)
            currentUserParticipantMap[payerName] = isPayerCurrentUser

            for participant in expense.participants {
                currentUserParticipantMap[participant.name] = participant.isCurrentUser

                // Payer does not owe themselves
                if participant.name.caseInsensitiveCompare(payerName) == .orderedSame {
                    continue
                }

                // If fully settled, no debt exists
                if participant.settlementStatus == .settled {
                    continue
                }

                let amountOwedSubunits = participant.remainingAmount.subunits
                if amountOwedSubunits <= 0 {
                    continue
                }

                // Participant owes Payer amountOwedSubunits
                let forwardKey = PairKey(debtor: participant.name, creditor: payerName)
                let reverseKey = PairKey(debtor: payerName, creditor: participant.name)

                let existingReverse = pairwiseNetDebt[reverseKey] ?? 0
                if existingReverse > 0 {
                    if existingReverse >= amountOwedSubunits {
                        pairwiseNetDebt[reverseKey] = existingReverse - amountOwedSubunits
                    } else {
                        pairwiseNetDebt.removeValue(forKey: reverseKey)
                        pairwiseNetDebt[forwardKey] = amountOwedSubunits - existingReverse
                    }
                } else {
                    let existingForward = pairwiseNetDebt[forwardKey] ?? 0
                    pairwiseNetDebt[forwardKey] = existingForward + amountOwedSubunits
                }
            }
        }

        var owedToCurrentUserSubunits: Int64 = 0
        var currentUserOwesSubunits: Int64 = 0
        var debtList: [ParticipantDebt] = []

        for (pair, amountSubunits) in pairwiseNetDebt {
            if amountSubunits <= 0 { continue }

            let debtor = pair.debtor
            let creditor = pair.creditor
            let isDebtorMe = currentUserParticipantMap[debtor] == true
            let isCreditorMe = currentUserParticipantMap[creditor] == true

            if isCreditorMe && !isDebtorMe {
                owedToCurrentUserSubunits += amountSubunits
            } else if isDebtorMe && !isCreditorMe {
                currentUserOwesSubunits += amountSubunits
            }

            debtList.append(
                ParticipantDebt(
                    debtorName: debtor,
                    isDebtorCurrentUser: isDebtorMe,
                    creditorName: creditor,
                    isCreditorCurrentUser: isCreditorMe,
                    netAmount: Amount(subunits: amountSubunits)
                )
            )
        }

        return GroupBalanceSummary(
            totalExpensesCount: totalExpensesCount,
            activeSplitsCount: activeSplitsCount,
            totalGroupSpend: Amount(subunits: totalGroupSpendSubunits),
            netOwedToCurrentUser: Amount(subunits: owedToCurrentUserSubunits),
            netCurrentUserOwes: Amount(subunits: currentUserOwesSubunits),
            debts: debtList
        )
    }
}

