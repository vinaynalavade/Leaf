import Foundation

/// UseCase validating and recording a partial or full payment against a participant's split share.
public final class RecordParticipantPaymentUseCase: Sendable {

    private let splitRepository: SplitRepositoryProtocol

    public init(splitRepository: SplitRepositoryProtocol) {
        self.splitRepository = splitRepository
    }

    public enum PaymentError: LocalizedError {
        case nonPositiveAmount
        case exceedsRemaining(remaining: Amount)

        public var errorDescription: String? {
            switch self {
            case .nonPositiveAmount:
                return "Payment amount must be strictly greater than zero."
            case .exceedsRemaining(let remaining):
                return "Payment cannot exceed the remaining balance of \(remaining.subunits) subunits."
            }
        }
    }

    @discardableResult
    public func execute(
        splitExpenseId: Int64,
        participant: SplitParticipant,
        amount: Amount,
        paymentMethod: PaymentMethod = .cash,
        date: Int64 = Int64(Date().timeIntervalSince1970 * 1000),
        note: String? = nil,
        createOffsetTransaction: Bool = true
    ) async throws -> SplitPayment {
        if amount.subunits <= 0 {
            throw PaymentError.nonPositiveAmount
        }

        if amount.subunits > participant.remainingAmount.subunits {
            throw PaymentError.exceedsRemaining(remaining: participant.remainingAmount)
        }

        return try await splitRepository.recordPayment(
            splitExpenseId: splitExpenseId,
            participantId: participant.id,
            amount: amount,
            paymentMethod: paymentMethod,
            date: date,
            note: note,
            createOffsetTransaction: createOffsetTransaction
        )
    }
}

