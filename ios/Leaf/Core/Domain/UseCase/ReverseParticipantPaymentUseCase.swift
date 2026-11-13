import Foundation

/// UseCase reverting an individual payment transaction from history and updating participant balances.
public final class ReverseParticipantPaymentUseCase: Sendable {

    private let splitRepository: SplitRepositoryProtocol

    public init(splitRepository: SplitRepositoryProtocol) {
        self.splitRepository = splitRepository
    }

    public func execute(paymentId: Int64) async throws {
        try await splitRepository.reversePayment(paymentId: paymentId)
    }
}

