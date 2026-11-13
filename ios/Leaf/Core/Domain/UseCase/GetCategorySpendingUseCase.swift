import Foundation

/// UseCase aggregating expenses into category-level spending records with percentage distribution.
public final class GetCategorySpendingUseCase: Sendable {

    private let transactionRepository: TransactionRepositoryProtocol

    public init(transactionRepository: TransactionRepositoryProtocol) {
        self.transactionRepository = transactionRepository
    }

    /// Computes category-wise expense breakdown for a given timestamp window.
    public func execute(startEpoch: Int64, endEpoch: Int64) async throws -> [CategorySpending] {
        let transactions = try await transactionRepository.getTransactionsBetween(
            startEpoch: startEpoch,
            endEpoch: endEpoch
        )

        return computeBreakdown(from: transactions)
    }

    /// Pure calculation method for computing category breakdown from an already-filtered transaction array.
    public func computeBreakdown(from transactions: [Transaction]) -> [CategorySpending] {
        let expenseTransactions = transactions.filter { $0.type == .expense && !$0.isInternalTransfer }
        let totalExpenseSubunits = expenseTransactions.reduce(Int64(0)) { $0 + $1.amount.subunits }

        if totalExpenseSubunits <= 0 || expenseTransactions.isEmpty {
            return []
        }

        // Group by categoryId
        var categoryMap: [Int64: (category: Category, totalSubunits: Int64, count: Int)] = [:]

        for tx in expenseTransactions {
            guard let cat = tx.category else { continue }
            if var existing = categoryMap[tx.categoryId] {
                existing.totalSubunits += tx.amount.subunits
                existing.count += 1
                categoryMap[tx.categoryId] = existing
            } else {
                categoryMap[tx.categoryId] = (category: cat, totalSubunits: tx.amount.subunits, count: 1)
            }
        }

        // Map to CategorySpending models
        let results = categoryMap.values.map { item in
            let percentage = (Double(item.totalSubunits) / Double(totalExpenseSubunits)) * 100.0
            return CategorySpending(
                category: item.category,
                totalAmount: Amount(subunits: item.totalSubunits),
                transactionCount: item.count,
                percentageOfTotal: percentage
            )
        }

        // Sort descending by highest spending
        return results.sorted { $0.totalAmount.subunits > $1.totalAmount.subunits }
    }
}

