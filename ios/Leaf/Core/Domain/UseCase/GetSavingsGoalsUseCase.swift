import Foundation

public struct SavingsGoalsSummary: Hashable, Sendable {
    public let activeCount: Int
    public let completedCount: Int
    public let archivedCount: Int
    public let totalSavedAmount: Amount
    public let totalTargetAmount: Amount
    public let remainingAmount: Amount
    public let overallProgressPercentage: Double

    public init(
        activeCount: Int = 0,
        completedCount: Int = 0,
        archivedCount: Int = 0,
        totalSavedAmount: Amount = .zero,
        totalTargetAmount: Amount = .zero,
        remainingAmount: Amount = .zero,
        overallProgressPercentage: Double = 0.0
    ) {
        self.activeCount = activeCount
        self.completedCount = completedCount
        self.archivedCount = archivedCount
        self.totalSavedAmount = totalSavedAmount
        self.totalTargetAmount = totalTargetAmount
        self.remainingAmount = remainingAmount
        self.overallProgressPercentage = overallProgressPercentage
    }

    public static var empty: SavingsGoalsSummary {
        SavingsGoalsSummary()
    }
}

/// UseCase retrieving savings goals and calculating aggregated portfolio savings metrics.
public final class GetSavingsGoalsUseCase: Sendable {

    private let savingsGoalRepository: SavingsGoalRepositoryProtocol

    public init(savingsGoalRepository: SavingsGoalRepositoryProtocol) {
        self.savingsGoalRepository = savingsGoalRepository
    }

    public func getActiveGoals() async throws -> [SavingsGoal] {
        try await savingsGoalRepository.getActiveGoals()
    }

    public func getArchivedGoals() async throws -> [SavingsGoal] {
        try await savingsGoalRepository.getArchivedGoals()
    }

    public func getAllGoals() async throws -> [SavingsGoal] {
        try await savingsGoalRepository.getAllGoals()
    }

    public func getGoal(id: Int64) async throws -> SavingsGoal? {
        try await savingsGoalRepository.getGoal(id: id)
    }

    public func getSummary() async throws -> SavingsGoalsSummary {
        let allGoals = try await savingsGoalRepository.getAllGoals()
        let activeGoals = allGoals.filter { !$0.isArchived }
        let archivedGoals = allGoals.filter { $0.isArchived }

        let completedCount = activeGoals.filter { $0.isCompleted }.count
        let totalTargetSubunits = activeGoals.reduce(Int64(0)) { $0 + $1.targetAmount.subunits }
        let totalSavedSubunits = activeGoals.reduce(Int64(0)) { $0 + $1.currentSavedAmount.subunits }
        let remainingSubunits = max(0, totalTargetSubunits - totalSavedSubunits)

        let overallPercentage: Double
        if totalTargetSubunits > 0 {
            overallPercentage = min(100.0, max(0.0, (Double(totalSavedSubunits) / Double(totalTargetSubunits)) * 100.0))
        } else {
            overallPercentage = 0.0
        }

        return SavingsGoalsSummary(
            activeCount: activeGoals.count,
            completedCount: completedCount,
            archivedCount: archivedGoals.count,
            totalSavedAmount: Amount(subunits: totalSavedSubunits),
            totalTargetAmount: Amount(subunits: totalTargetSubunits),
            remainingAmount: Amount(subunits: remainingSubunits),
            overallProgressPercentage: overallPercentage
        )
    }
}

