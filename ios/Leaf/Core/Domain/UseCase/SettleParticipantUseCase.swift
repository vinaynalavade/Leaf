import Foundation

public final class SettleParticipantUseCase: Sendable {

    private let splitRepository: SplitRepositoryProtocol
    private let transactionRepository: TransactionRepositoryProtocol?

    public init(
        splitRepository: SplitRepositoryProtocol,
        transactionRepository: TransactionRepositoryProtocol? = nil
    ) {
        self.splitRepository = splitRepository
        self.transactionRepository = transactionRepository
    }

    private func isCurrentUserName(_ name: String, in participants: [SplitParticipant]) -> Bool {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.caseInsensitiveCompare("Me") == .orderedSame || trimmed.caseInsensitiveCompare("You") == .orderedSame {
            return true
        }
        return participants.first { $0.name.caseInsensitiveCompare(trimmed) == .orderedSame }?.isCurrentUser == true
    }

    public func execute(
        participant: SplitParticipant,
        settleDate: Int64 = Int64(Date().timeIntervalSince1970 * 1000),
        createOffsetTransaction: Bool = true,
        paymentMethod: PaymentMethod = .account,
        incomeCategoryId: Int64? = nil
    ) async throws {
        var offsetTxId: Int64? = participant.settlementTransactionId

        let splitExpense = try await splitRepository.getSplitExpense(id: participant.splitExpenseId)
        let participants = splitExpense?.participants ?? []
        let paidBy = splitExpense?.paidBy ?? "Me"

        let isRecipientMe = isCurrentUserName(paidBy, in: participants)
        let isDebtorMe = participant.isCurrentUser ||
                         participant.name.caseInsensitiveCompare("Me") == .orderedSame ||
                         participant.name.caseInsensitiveCompare("You") == .orderedSame

        if createOffsetTransaction && offsetTxId == nil,
           let txRepo = transactionRepository,
           let expense = splitExpense,
           expense.addToTransactions {
            let catId = incomeCategoryId ?? expense.categoryId
            let settleAmount = participant.remainingAmount.subunits > 0 ? participant.remainingAmount : participant.amount

            if isRecipientMe && !isDebtorMe {
                // Scenario A & D: Current user received payment -> INCOME
                let note = "\(participant.name) — \(expense.title) settlement"
                let offsetTx = Transaction(
                    amount: settleAmount,
                    type: .income,
                    categoryId: catId,
                    paymentMethod: paymentMethod,
                    note: note,
                    timestamp: settleDate
                )
                offsetTxId = try await txRepo.insertTransaction(offsetTx)
            } else if !isRecipientMe && isDebtorMe {
                // Scenario B: Current user pays share to original bill payer -> EXPENSE
                let note = "Settlement: \(expense.title) to \(expense.paidBy)"
                let offsetTx = Transaction(
                    amount: settleAmount,
                    type: .expense,
                    categoryId: catId,
                    paymentMethod: paymentMethod,
                    note: note,
                    timestamp: settleDate
                )
                offsetTxId = try await txRepo.insertTransaction(offsetTx)
            } else {
                // Scenario C: Neither party is current user -> ZERO ledger transactions
                offsetTxId = nil
            }
        }

        try await splitRepository.settleParticipant(
            participantId: participant.id,
            settledAt: settleDate,
            settlementTransactionId: offsetTxId
        )
    }

    /// Reverts a participant settlement back to pending, removing the linked ledger transaction if one was created.
    public func unsettle(participantId: Int64) async throws {
        try await splitRepository.unsettleParticipant(participantId: participantId)
    }
}

