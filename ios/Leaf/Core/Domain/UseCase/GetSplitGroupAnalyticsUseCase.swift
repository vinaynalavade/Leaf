import Foundation

/// UseCase responsible for compiling complete financial analytics strictly scoped to an individual SplitGroup.
/// Guarantees financial accuracy using integer subunit arithmetic (`Amount`), never counts settlement
/// reimbursements as original expenses, and keeps group spending strictly isolated from other groups
/// and the user's personal ledger.
public final class GetSplitGroupAnalyticsUseCase: Sendable {

    private let splitRepository: SplitRepositoryProtocol
    private let categoryRepository: CategoryRepositoryProtocol

    public init(
        splitRepository: SplitRepositoryProtocol,
        categoryRepository: CategoryRepositoryProtocol
    ) {
        self.splitRepository = splitRepository
        self.categoryRepository = categoryRepository
    }

    public enum AnalyticsError: LocalizedError {
        case groupNotFound(Int64)

        public var errorDescription: String? {
            switch self {
            case .groupNotFound(let id):
                return "Split group with ID \(id) was not found."
            }
        }
    }

    /// Compiles analytical metrics, category distribution, and spending timeline for a specific SplitGroup.
    public func execute(
        groupId: Int64,
        dateFilter: SplitGroupDateFilter,
        customStartDate: Date? = nil,
        customEndDate: Date? = nil,
        selectedCategoryId: Int64? = nil
    ) async throws -> SplitGroupAnalytics {
        // 1. Fetch group metadata
        guard let group = try await splitRepository.getSplitGroup(id: groupId) else {
            throw AnalyticsError.groupNotFound(groupId)
        }

        // 2. Fetch all expenses strictly belonging to this group (WHERE group_id = :groupId)
        let allGroupExpenses = try await splitRepository.getSplitExpensesForGroup(groupId: groupId)

        // 3. Fetch all categories for lookup
        let allCategories = try await categoryRepository.getAllCategories()
        let categoryMap = Dictionary(uniqueKeysWithValues: allCategories.map { ($0.id, $0) })

        // 4. Determine date interval for filter
        let calendar = Calendar.current
        let now = Date()
        let dateInterval: DateInterval?

        switch dateFilter {
        case .allTime:
            dateInterval = nil
        case .thisMonth:
            if let start = calendar.date(from: calendar.dateComponents([.year, .month], from: now)),
               let end = calendar.date(byAdding: DateComponents(month: 1, day: -1, hour: 23, minute: 59, second: 59), to: start) {
                dateInterval = DateInterval(start: start, end: end)
            } else {
                dateInterval = nil
            }
        case .lastMonth:
            if let thisMonthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: now)),
               let start = calendar.date(byAdding: .month, value: -1, to: thisMonthStart),
               let end = calendar.date(byAdding: DateComponents(month: 1, second: -1), to: start) {
                dateInterval = DateInterval(start: start, end: end)
            } else {
                dateInterval = nil
            }
        case .last3Months:
            if let thisMonthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: now)),
               let start = calendar.date(byAdding: .month, value: -3, to: thisMonthStart) {
                dateInterval = DateInterval(start: start, end: now)
            } else {
                dateInterval = nil
            }
        case .custom:
            if let start = customStartDate, let end = customEndDate {
                dateInterval = DateInterval(start: min(start, end), end: max(start, end))
            } else {
                dateInterval = nil
            }
        }

        // 5. Filter expenses by date interval
        let dateFilteredExpenses: [SplitExpense]
        if let interval = dateInterval {
            dateFilteredExpenses = allGroupExpenses.filter { expense in
                let expenseDate = Date(timeIntervalSince1970: Double(expense.date) / 1000.0)
                return expenseDate >= interval.start && expenseDate <= interval.end
            }
        } else {
            dateFilteredExpenses = allGroupExpenses
        }

        // 6. Compute Category Breakdown (based on dateFilteredExpenses)
        var categorySubunitsMap: [Int64: Int64] = [:]
        var categoryExpenseCountMap: [Int64: Int] = [:]

        for exp in dateFilteredExpenses {
            categorySubunitsMap[exp.categoryId, default: 0] += exp.totalAmount.subunits
            categoryExpenseCountMap[exp.categoryId, default: 0] += 1
        }

        let totalGroupSubunits = dateFilteredExpenses.reduce(Int64(0)) { $0 + $1.totalAmount.subunits }
        let totalSpending = Amount(subunits: totalGroupSubunits)

        var categoryBreakdown: [SplitGroupCategorySpending] = []
        for (catId, subunits) in categorySubunitsMap {
            let cat = categoryMap[catId]
            let name = cat?.name ?? "General"
            let icon = cat?.iconName ?? "cart.fill"
            let color = cat?.colorHex ?? "#10B981"
            let count = categoryExpenseCountMap[catId] ?? 0

            let percentage: Double
            if totalGroupSubunits > 0 {
                percentage = (Double(subunits) / Double(totalGroupSubunits)) * 100.0
            } else {
                percentage = 0.0
            }

            categoryBreakdown.append(
                SplitGroupCategorySpending(
                    categoryId: catId,
                    categoryName: name,
                    categoryIcon: icon,
                    categoryColorHex: color,
                    totalAmount: Amount(subunits: subunits),
                    percentage: percentage,
                    expenseCount: count
                )
            )
        }

        // Sort categories descending by spending amount
        categoryBreakdown.sort { $0.totalAmount.subunits > $1.totalAmount.subunits }
        let mostExpensiveCategory = categoryBreakdown.first

        // 7. Compute Timeline Points (daily or monthly aggregation)
        let isShortInterval: Bool
        if let interval = dateInterval {
            isShortInterval = interval.duration <= (35 * 86400) // <= 35 days
        } else {
            isShortInterval = false
        }

        let dayFormatter = DateFormatter()
        dayFormatter.dateFormat = "yyyy-MM-dd"

        let dayLabelFormatter = DateFormatter()
        dayLabelFormatter.dateFormat = "d MMM"

        let monthFormatter = DateFormatter()
        monthFormatter.dateFormat = "yyyy-MM"

        let monthLabelFormatter = DateFormatter()
        monthLabelFormatter.dateFormat = "MMM yyyy"

        struct BucketAccumulator {
            var date: Date
            var label: String
            var subunits: Int64
            var count: Int
        }

        var buckets: [String: BucketAccumulator] = [:]

        for exp in dateFilteredExpenses {
            let expDate = Date(timeIntervalSince1970: Double(exp.date) / 1000.0)
            let key: String
            let label: String

            if isShortInterval {
                key = dayFormatter.string(from: expDate)
                label = dayLabelFormatter.string(from: expDate)
            } else {
                key = monthFormatter.string(from: expDate)
                label = monthLabelFormatter.string(from: expDate)
            }

            if var existing = buckets[key] {
                existing.subunits += exp.totalAmount.subunits
                existing.count += 1
                buckets[key] = existing
            } else {
                buckets[key] = BucketAccumulator(
                    date: expDate,
                    label: label,
                    subunits: exp.totalAmount.subunits,
                    count: 1
                )
            }
        }

        let sortedKeys = buckets.keys.sorted()
        var timelinePoints: [SplitGroupTimelinePoint] = []
        var highestSpendingDate: Date? = nil
        var highestSpendingSubunits: Int64 = 0

        for key in sortedKeys {
            if let acc = buckets[key] {
                timelinePoints.append(
                    SplitGroupTimelinePoint(
                        id: key,
                        date: acc.date,
                        dateLabel: acc.label,
                        totalAmount: Amount(subunits: acc.subunits),
                        expenseCount: acc.count
                    )
                )

                if acc.subunits > highestSpendingSubunits {
                    highestSpendingSubunits = acc.subunits
                    highestSpendingDate = acc.date
                }
            }
        }

        // 8. Financial Overview Statistics
        var uniqueParticipantNames = Set<String>()
        for exp in allGroupExpenses {
            for p in exp.participants {
                let trimmed = p.name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                if !trimmed.isEmpty {
                    uniqueParticipantNames.insert(trimmed)
                }
            }
        }

        let participantCount = max(1, uniqueParticipantNames.count)
        let averageSubunits = totalGroupSubunits / Int64(participantCount)
        let averagePerParticipant = Amount(subunits: averageSubunits)

        let highestExpense = dateFilteredExpenses.max(by: { $0.totalAmount.subunits < $1.totalAmount.subunits })

        // 9. Apply Category Filter to the detailed expenses list if requested
        let finalExpenses: [SplitExpense]
        if let catId = selectedCategoryId {
            finalExpenses = dateFilteredExpenses.filter { $0.categoryId == catId }
        } else {
            finalExpenses = dateFilteredExpenses
        }

        return SplitGroupAnalytics(
            group: group,
            totalSpending: totalSpending,
            expenseCount: dateFilteredExpenses.count,
            participantCount: participantCount,
            averagePerParticipant: averagePerParticipant,
            highestExpense: highestExpense,
            mostExpensiveCategory: mostExpensiveCategory,
            categoryBreakdown: categoryBreakdown,
            timelinePoints: timelinePoints,
            highestSpendingDate: highestSpendingDate,
            highestSpendingAmount: Amount(subunits: highestSpendingSubunits),
            expenses: finalExpenses
        )
    }
}

