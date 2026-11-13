import Foundation

public struct Budget: Identifiable, Hashable, Codable, Sendable {
    public let id: Int64
    public let categoryId: Int64?
    public let category: Category?
    public let amount: Amount
    public let month: Int
    public let year: Int
    public let periodType: BudgetPeriodType
    public let startDate: Int64?
    public let endDate: Int64?
    public let isRecurring: Bool
    public let createdAt: Int64
    public let updatedAt: Int64

    public init(
        id: Int64 = 0,
        categoryId: Int64? = nil,
        category: Category? = nil,
        amount: Amount,
        month: Int,
        year: Int,
        periodType: BudgetPeriodType = .monthly,
        startDate: Int64? = nil,
        endDate: Int64? = nil,
        isRecurring: Bool = false,
        createdAt: Int64 = Int64(Date().timeIntervalSince1970 * 1000),
        updatedAt: Int64 = Int64(Date().timeIntervalSince1970 * 1000)
    ) {
        self.id = id
        self.categoryId = categoryId
        self.category = category
        self.amount = amount
        self.month = month
        self.year = year
        self.periodType = periodType
        self.startDate = startDate
        self.endDate = endDate
        self.isRecurring = isRecurring
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    public var isOverallBudget: Bool {
        categoryId == nil
    }

    /// Computes the exact `[startEpoch, endEpoch]` timestamps (in milliseconds) for transaction filtering.
    public func dateRange(for referenceDate: Date = Date()) -> (startEpoch: Int64, endEpoch: Int64) {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone.current

        switch periodType {
        case .monthly:
            var startComp = DateComponents(year: year, month: month, day: 1, hour: 0, minute: 0, second: 0)
            guard let start = calendar.date(from: startComp),
                  let range = calendar.range(of: .day, in: .month, for: start),
                  let end = calendar.date(bySetting: .day, value: range.count, of: start),
                  let endOfDay = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: end) else {
                return (0, Int64.max)
            }
            return (Int64(start.timeIntervalSince1970 * 1000), Int64(endOfDay.timeIntervalSince1970 * 1000))

        case .weekly:
            if let s = startDate, let e = endDate {
                return (s, e)
            }
            // Derive week bounds containing the reference date or 1st of month/year
            var startComp = DateComponents(year: year, month: month, day: 1, hour: 0, minute: 0, second: 0)
            let baseDate = calendar.date(from: startComp) ?? referenceDate
            let weekday = calendar.component(.weekday, from: baseDate)
            // Assuming Monday = 2 in Gregorian (1 = Sunday)
            let daysToSubtract = (weekday + 5) % 7
            guard let weekStart = calendar.date(byAdding: .day, value: -daysToSubtract, to: calendar.startOfDay(for: baseDate)),
                  let weekEnd = calendar.date(byAdding: DateComponents(day: 6, hour: 23, minute: 59, second: 59), to: weekStart) else {
                return (0, Int64.max)
            }
            return (Int64(weekStart.timeIntervalSince1970 * 1000), Int64(weekEnd.timeIntervalSince1970 * 1000))

        case .yearly:
            var startComp = DateComponents(year: year, month: 1, day: 1, hour: 0, minute: 0, second: 0)
            var endComp = DateComponents(year: year, month: 12, day: 31, hour: 23, minute: 59, second: 59)
            guard let start = calendar.date(from: startComp),
                  let end = calendar.date(from: endComp) else {
                return (0, Int64.max)
            }
            return (Int64(start.timeIntervalSince1970 * 1000), Int64(end.timeIntervalSince1970 * 1000))

        case .custom:
            let s = startDate ?? Int64(Date().timeIntervalSince1970 * 1000)
            let e = endDate ?? s
            return (s, e)
        }
    }

    /// User-friendly label for the period (e.g. "November 2026", "Week of Nov 9", "2026", or "Nov 1 – Nov 15").
    public var periodSummaryLabel: String {
        let formatter = DateFormatter()
        formatter.locale = Locale.current

        switch periodType {
        case .monthly:
            formatter.dateFormat = "MMMM yyyy"
            var comps = DateComponents(year: year, month: month, day: 1)
            let date = Calendar.current.date(from: comps) ?? Date()
            return formatter.string(from: date)

        case .weekly:
            let (startEpoch, endEpoch) = dateRange()
            formatter.dateFormat = "d MMM"
            let startStr = formatter.string(from: Date(timeIntervalSince1970: TimeInterval(startEpoch) / 1000))
            let endStr = formatter.string(from: Date(timeIntervalSince1970: TimeInterval(endEpoch) / 1000))
            return "\(startStr) – \(endStr)"

        case .yearly:
            return "Full Year \(year)"

        case .custom:
            let (startEpoch, endEpoch) = dateRange()
            formatter.dateFormat = "d MMM yyyy"
            let startStr = formatter.string(from: Date(timeIntervalSince1970: TimeInterval(startEpoch) / 1000))
            let endStr = formatter.string(from: Date(timeIntervalSince1970: TimeInterval(endEpoch) / 1000))
            return "\(startStr) – \(endStr)"
        }
    }
}
