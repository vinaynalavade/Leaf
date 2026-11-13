import Foundation

/// UseCase calculating aggregated monthly expense statistics, including daily average and month-over-month delta.
public final class GetMonthlyExpenseSummaryUseCase: Sendable {

    private let transactionRepository: TransactionRepositoryProtocol

    public init(transactionRepository: TransactionRepositoryProtocol) {
        self.transactionRepository = transactionRepository
    }

    public func execute(year: Int, month: Int) async throws -> MonthlyExpenseSummary {
        let calendar = Calendar.current

        // 1. Calculate start and end epoch timestamps for the selected month
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = 1
        components.hour = 0
        components.minute = 0
        components.second = 0

        guard let startOfMonth = calendar.date(from: components),
              let endOfMonth = calendar.date(byAdding: DateComponents(month: 1, second: -1), to: startOfMonth) else {
            return .empty
        }

        let startEpoch = Int64(startOfMonth.timeIntervalSince1970 * 1000)
        let endEpoch = Int64(endOfMonth.timeIntervalSince1970 * 1000)

        // 2. Fetch all transactions for the period
        let transactions = try await transactionRepository.getTransactionsBetween(
            startEpoch: startEpoch,
            endEpoch: endEpoch
        )

        let expenseTransactions = transactions.filter { $0.type == .expense && !$0.isInternalTransfer }
        let totalExpenseSubunits = expenseTransactions.reduce(Int64(0)) { $0 + $1.amount.subunits }
        let totalExpense = Amount(subunits: totalExpenseSubunits)
        let count = expenseTransactions.count

        // 3. Compute daily average
        let now = Date()
        let currentYear = calendar.component(.year, from: now)
        let currentMonth = calendar.component(.month, from: now)
        let currentDay = calendar.component(.day, from: now)

        let daysInMonth: Int
        if year == currentYear && month == currentMonth {
            daysInMonth = max(1, currentDay)
        } else if (year < currentYear) || (year == currentYear && month < currentMonth) {
            daysInMonth = calendar.range(of: .day, in: .month, for: startOfMonth)?.count ?? 30
        } else {
            daysInMonth = 1
        }

        let dailyAverageSubunits = daysInMonth > 0 ? (totalExpenseSubunits / Int64(daysInMonth)) : 0
        let dailyAverage = Amount(subunits: dailyAverageSubunits)

        // 4. Query previous month for comparison
        let prevYear = month == 1 ? year - 1 : year
        let prevMonth = month == 1 ? 12 : month - 1

        var prevComponents = DateComponents()
        prevComponents.year = prevYear
        prevComponents.month = prevMonth
        prevComponents.day = 1
        prevComponents.hour = 0
        prevComponents.minute = 0
        prevComponents.second = 0

        var previousMonthExpense: Amount? = nil
        var percentageChange: Double? = nil

        if let prevStart = calendar.date(from: prevComponents),
           let prevEnd = calendar.date(byAdding: DateComponents(month: 1, second: -1), to: prevStart) {
            let prevStartEpoch = Int64(prevStart.timeIntervalSince1970 * 1000)
            let prevEndEpoch = Int64(prevEnd.timeIntervalSince1970 * 1000)

            let prevExpenses = try await transactionRepository.getTotalExpense(
                startEpoch: prevStartEpoch,
                endEpoch: prevEndEpoch
            )
            previousMonthExpense = prevExpenses

            if prevExpenses.subunits > 0 {
                let delta = Double(totalExpenseSubunits - prevExpenses.subunits)
                percentageChange = (delta / Double(prevExpenses.subunits)) * 100.0
            } else if prevExpenses.subunits == 0 && totalExpenseSubunits > 0 {
                percentageChange = 100.0
            }
        }

        return MonthlyExpenseSummary(
            selectedYear: year,
            selectedMonth: month,
            totalExpense: totalExpense,
            transactionCount: count,
            dailyAverage: dailyAverage,
            previousMonthExpense: previousMonthExpense,
            percentageChangeVsPreviousMonth: percentageChange
        )
    }
}

