import Foundation

/// UseCase to generate chronological time-series data points (daily, weekly, or monthly)
/// for Swift Charts visualizations and spending velocity analytics.
public final class GetSpendingTrendsUseCase: Sendable {
    private let transactionRepository: TransactionRepositoryProtocol

    public init(transactionRepository: TransactionRepositoryProtocol) {
        self.transactionRepository = transactionRepository
    }

    public enum TrendGranularity: Sendable {
        case daily
        case weekly
        case monthly
    }

    public func execute(
        period: InsightsPeriod,
        forcedGranularity: TrendGranularity? = nil,
        calendar: Calendar = .current,
        referenceDate: Date = Date()
    ) async throws -> [SpendingTrendPoint] {
        let interval = period.dateInterval(calendar: calendar, referenceDate: referenceDate)
        let startEpoch = Int64(interval.start.timeIntervalSince1970 * 1000)
        let endEpoch = Int64(interval.end.timeIntervalSince1970 * 1000)

        let transactions = try await transactionRepository.getTransactionsBetween(
            startEpoch: startEpoch,
            endEpoch: endEpoch
        )

        let granularity = forcedGranularity ?? determineGranularity(for: period, interval: interval, calendar: calendar)

        switch granularity {
        case .daily:
            return generateDailyPoints(interval: interval, transactions: transactions, calendar: calendar)
        case .weekly:
            return generateWeeklyPoints(interval: interval, transactions: transactions, calendar: calendar)
        case .monthly:
            return generateMonthlyPoints(interval: interval, transactions: transactions, calendar: calendar)
        }
    }

    private func determineGranularity(
        for period: InsightsPeriod,
        interval: DateInterval,
        calendar: Calendar
    ) -> TrendGranularity {
        switch period {
        case .thisWeek:
            return .daily
        case .thisMonth, .lastMonth:
            return .daily
        case .last3Months, .last6Months, .thisYear:
            return .monthly
        case .custom:
            let days = calendar.dateComponents([.day], from: interval.start, to: interval.end).day ?? 30
            if days <= 14 {
                return .daily
            } else if days <= 75 {
                return .weekly
            } else {
                return .monthly
            }
        }
    }

    // MARK: - Daily Buckets

    private func generateDailyPoints(
        interval: DateInterval,
        transactions: [Transaction],
        calendar: Calendar
    ) -> [SpendingTrendPoint] {
        var points: [SpendingTrendPoint] = []
        var currentDate = calendar.startOfDay(for: interval.start)
        let endDate = interval.end

        let dayFormatter = DateFormatter()
        dayFormatter.dateFormat = "d MMM"

        let shortDayFormatter = DateFormatter()
        shortDayFormatter.dateFormat = "E"

        // Group ordinary transactions by start-of-day epoch
        var expenseMap: [Date: Int64] = [:]
        var incomeMap: [Date: Int64] = [:]

        for tx in transactions where !tx.isInternalTransfer {
            let txDate = Date(timeIntervalSince1970: Double(tx.timestamp) / 1000.0)
            let dayKey = calendar.startOfDay(for: txDate)

            if tx.type == .expense {
                expenseMap[dayKey, default: 0] += tx.amount.subunits
            } else if tx.type == .income {
                incomeMap[dayKey, default: 0] += tx.amount.subunits
            }
        }

        while currentDate < endDate {
            let nextDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? endDate
            let expense = expenseMap[currentDate] ?? 0
            let income = incomeMap[currentDate] ?? 0

            let label = calendar.dateComponents([.day], from: interval.start, to: interval.end).day ?? 0 <= 7
                ? shortDayFormatter.string(from: currentDate)
                : dayFormatter.string(from: currentDate)

            points.append(SpendingTrendPoint(
                id: "day_\(Int64(currentDate.timeIntervalSince1970))",
                label: label,
                date: currentDate,
                expenseSubunits: expense,
                incomeSubunits: income
            ))

            currentDate = nextDate
        }

        return points
    }

    // MARK: - Weekly Buckets

    private func generateWeeklyPoints(
        interval: DateInterval,
        transactions: [Transaction],
        calendar: Calendar
    ) -> [SpendingTrendPoint] {
        var points: [SpendingTrendPoint] = []
        var currentWeekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: interval.start)) ?? interval.start
        let endDate = interval.end

        let labelFormatter = DateFormatter()
        labelFormatter.dateFormat = "MMM d"

        var index = 1
        while currentWeekStart < endDate {
            let nextWeekStart = calendar.date(byAdding: .day, value: 7, to: currentWeekStart) ?? endDate
            let weekStartEpoch = Int64(currentWeekStart.timeIntervalSince1970 * 1000)
            let weekEndEpoch = Int64(nextWeekStart.timeIntervalSince1970 * 1000)

            let weekTxs = transactions.filter {
                !$0.isInternalTransfer && $0.timestamp >= weekStartEpoch && $0.timestamp < weekEndEpoch
            }

            let expense = weekTxs.filter { $0.type == .expense }.reduce(Int64(0)) { $0 + $1.amount.subunits }
            let income = weekTxs.filter { $0.type == .income }.reduce(Int64(0)) { $0 + $1.amount.subunits }

            points.append(SpendingTrendPoint(
                id: "week_\(index)_\(Int64(currentWeekStart.timeIntervalSince1970))",
                label: labelFormatter.string(from: currentWeekStart),
                date: currentWeekStart,
                expenseSubunits: expense,
                incomeSubunits: income
            ))

            currentWeekStart = nextWeekStart
            index += 1
        }

        return points
    }

    // MARK: - Monthly Buckets

    private func generateMonthlyPoints(
        interval: DateInterval,
        transactions: [Transaction],
        calendar: Calendar
    ) -> [SpendingTrendPoint] {
        var points: [SpendingTrendPoint] = []
        var currentMonthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: interval.start)) ?? interval.start
        let endDate = interval.end

        let monthFormatter = DateFormatter()
        monthFormatter.dateFormat = "MMM"

        while currentMonthStart < endDate {
            let nextMonthStart = calendar.date(byAdding: .month, value: 1, to: currentMonthStart) ?? endDate
            let monthStartEpoch = Int64(currentMonthStart.timeIntervalSince1970 * 1000)
            let monthEndEpoch = Int64(nextMonthStart.timeIntervalSince1970 * 1000)

            let monthTxs = transactions.filter {
                !$0.isInternalTransfer && $0.timestamp >= monthStartEpoch && $0.timestamp < monthEndEpoch
            }

            let expense = monthTxs.filter { $0.type == .expense }.reduce(Int64(0)) { $0 + $1.amount.subunits }
            let income = monthTxs.filter { $0.type == .income }.reduce(Int64(0)) { $0 + $1.amount.subunits }

            points.append(SpendingTrendPoint(
                id: "month_\(Int64(currentMonthStart.timeIntervalSince1970))",
                label: monthFormatter.string(from: currentMonthStart),
                date: currentMonthStart,
                expenseSubunits: expense,
                incomeSubunits: income
            ))

            currentMonthStart = nextMonthStart
        }

        return points
    }
}

