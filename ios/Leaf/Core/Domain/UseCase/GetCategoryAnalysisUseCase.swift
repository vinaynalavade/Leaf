import Foundation

/// UseCase to calculate category-wise expense totals, percentage shares, counts,
/// and period-over-period spending comparisons.
public final class GetCategoryAnalysisUseCase: Sendable {
    private let transactionRepository: TransactionRepositoryProtocol
    private let categoryRepository: CategoryRepositoryProtocol

    public init(
        transactionRepository: TransactionRepositoryProtocol,
        categoryRepository: CategoryRepositoryProtocol
    ) {
        self.transactionRepository = transactionRepository
        self.categoryRepository = categoryRepository
    }

    public func execute(
        period: InsightsPeriod,
        calendar: Calendar = .current,
        referenceDate: Date = Date()
    ) async throws -> [CategoryAnalysisItem] {
        let currentInterval = period.dateInterval(calendar: calendar, referenceDate: referenceDate)
        let prevInterval = period.previousEquivalentInterval(calendar: calendar, referenceDate: referenceDate)

        let currentStartEpoch = Int64(currentInterval.start.timeIntervalSince1970 * 1000)
        let currentEndEpoch = Int64(currentInterval.end.timeIntervalSince1970 * 1000)

        let prevStartEpoch = Int64(prevInterval.start.timeIntervalSince1970 * 1000)
        let prevEndEpoch = Int64(prevInterval.end.timeIntervalSince1970 * 1000)

        // Fetch ordinary transactions for both periods
        let currentTransactions = try await transactionRepository.getTransactionsBetween(
            startEpoch: currentStartEpoch,
            endEpoch: currentEndEpoch
        )
        let prevTransactions = try await transactionRepository.getTransactionsBetween(
            startEpoch: prevStartEpoch,
            endEpoch: prevEndEpoch
        )

        // Strictly exclude internal transfers from ordinary expense calculations
        let currentExpenses = currentTransactions.filter { $0.type == .expense && !$0.isInternalTransfer }
        let prevExpenses = prevTransactions.filter { $0.type == .expense && !$0.isInternalTransfer }

        let totalCurrentSubunits = currentExpenses.reduce(Int64(0)) { $0 + $1.amount.subunits }

        // Group current expenses by category
        var currentMap: [Int64: (category: Category, subunits: Int64, count: Int)] = [:]
        for tx in currentExpenses {
            guard let cat = tx.category else { continue }
            if let existing = currentMap[cat.id] {
                currentMap[cat.id] = (
                    category: existing.category,
                    subunits: existing.subunits + tx.amount.subunits,
                    count: existing.count + 1
                )
            } else {
                currentMap[cat.id] = (
                    category: cat,
                    subunits: tx.amount.subunits,
                    count: 1
                )
            }
        }

        // Group previous expenses by category
        var prevMap: [Int64: Int64] = [:]
        for tx in prevExpenses {
            prevMap[tx.categoryId, default: 0] += tx.amount.subunits
        }

        var results: [CategoryAnalysisItem] = []
        for (_, entry) in currentMap {
            let percentage = totalCurrentSubunits > 0
                ? (Double(entry.subunits) / Double(totalCurrentSubunits)) * 100.0
                : 0.0

            let prevSubunits = prevMap[entry.category.id]
            let prevAmount = prevSubunits != nil ? Amount(prevSubunits!) : nil

            let changePct: Double?
            if let prev = prevSubunits, prev > 0 {
                changePct = (Double(entry.subunits - prev) / Double(prev)) * 100.0
            } else {
                changePct = nil
            }

            results.append(CategoryAnalysisItem(
                category: entry.category,
                amount: Amount(entry.subunits),
                percentageOfTotal: percentage,
                transactionCount: entry.count,
                previousPeriodAmount: prevAmount,
                changePercentageVsPrevious: changePct
            ))
        }

        // Sort descending by highest spending amount
        results.sort { $0.amount.subunits > $1.amount.subunits }
        return results
    }
}

