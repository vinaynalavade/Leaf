import Foundation

public final class CalculateSplitUseCase: Sendable {

    public init() {}

    public func executeEqualSplit(
        totalAmount: Amount,
        participants: [String],
        payerName: String = "Me",
        currentUserName: String = "Me"
    ) -> [SplitParticipant] {
        SplitCalculationEngine.calculateEqualSplit(
            totalAmount: totalAmount,
            participants: participants,
            payerName: payerName,
            currentUserName: currentUserName
        )
    }

    public func executeItemizedSplit(
        totalBill: Amount,
        participants: [String],
        items: [SplitItem],
        sharedRemainingParticipants: [String]
    ) -> ItemizedSplitCalculationResult {
        SplitCalculationEngine.calculateItemizedSplit(
            totalBill: totalBill,
            participants: participants,
            items: items,
            sharedRemainingParticipants: sharedRemainingParticipants
        )
    }

    public func validateCustomSplit(
        totalAmount: Amount,
        allocatedSubunits: Int64
    ) -> CustomSplitValidation {
        SplitCalculationEngine.validateCustomSplit(
            totalAmount: totalAmount,
            allocatedSubunits: allocatedSubunits
        )
    }

    public func executePercentageSplit(
        totalAmount: Amount,
        participants: [(name: String, percentage: Double)],
        payerName: String = "Me",
        currentUserName: String = "Me"
    ) -> [SplitParticipant] {
        SplitCalculationEngine.calculatePercentageSplit(
            totalAmount: totalAmount,
            participants: participants,
            payerName: payerName,
            currentUserName: currentUserName
        )
    }

    public func executeExactCustomSplit(
        totalAmount: Amount,
        participants: [(name: String, amount: Amount)],
        payerName: String = "Me",
        currentUserName: String = "Me"
    ) -> [SplitParticipant] {
        SplitCalculationEngine.calculateExactCustomSplit(
            totalAmount: totalAmount,
            participants: participants,
            payerName: payerName,
            currentUserName: currentUserName
        )
    }
}

