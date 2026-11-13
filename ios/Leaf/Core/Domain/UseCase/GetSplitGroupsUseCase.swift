import Foundation

/// Model summarizing a SplitGroup with its calculated total expense volume and expense count.
public struct SplitGroupSummary: Identifiable, Hashable, Sendable {
    public var id: Int64 { group.id }
    public let group: SplitGroup
    public let totalSpending: Amount
    public let expenseCount: Int
    public let participantCount: Int

    public init(
        group: SplitGroup,
        totalSpending: Amount,
        expenseCount: Int,
        participantCount: Int
    ) {
        self.group = group
        self.totalSpending = totalSpending
        self.expenseCount = expenseCount
        self.participantCount = participantCount
    }
}

/// UseCase retrieving all SplitGroups with aggregated total original spending and count statistics.
public final class GetSplitGroupsUseCase: Sendable {

    private let splitRepository: SplitRepositoryProtocol

    public init(splitRepository: SplitRepositoryProtocol) {
        self.splitRepository = splitRepository
    }

    public func execute() async throws -> [SplitGroupSummary] {
        let groups = try await splitRepository.getAllSplitGroups()
        var summaries: [SplitGroupSummary] = []

        for group in groups {
            let expenses = try await splitRepository.getSplitExpensesForGroup(groupId: group.id)
            let totalSubunits = expenses.reduce(Int64(0)) { $0 + $1.totalAmount.subunits }

            var uniqueParticipants = Set<String>()
            for exp in expenses {
                for p in exp.participants {
                    let trimmed = p.name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                    if !trimmed.isEmpty { uniqueParticipants.insert(trimmed) }
                }
            }

            summaries.append(
                SplitGroupSummary(
                    group: group,
                    totalSpending: Amount(subunits: totalSubunits),
                    expenseCount: expenses.count,
                    participantCount: max(1, uniqueParticipants.count)
                )
            )
        }

        return summaries
    }
}

