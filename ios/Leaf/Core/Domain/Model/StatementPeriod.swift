import Foundation

/// Defines statement reporting periods for comprehensive financial exports.
public enum StatementPeriod: Hashable, Sendable, Identifiable {
    case thisMonth
    case lastMonth
    case previous3Months
    case previous6Months
    case thisYear
    case previousYear
    case allTime
    case custom(startDate: Date, endDate: Date)

    public var id: String {
        switch self {
        case .thisMonth: return "thisMonth"
        case .lastMonth: return "lastMonth"
        case .previous3Months: return "previous3Months"
        case .previous6Months: return "previous6Months"
        case .thisYear: return "thisYear"
        case .previousYear: return "previousYear"
        case .allTime: return "allTime"
        case .custom(let start, let end):
            return "custom_\(Int64(start.timeIntervalSince1970))_\(Int64(end.timeIntervalSince1970))"
        }
    }

    public var displayName: String {
        switch self {
        case .thisMonth: return "This Month"
        case .lastMonth: return "Last Month"
        case .previous3Months: return "Previous 3 Months"
        case .previous6Months: return "Previous 6 Months"
        case .thisYear: return "This Year"
        case .previousYear: return "Previous Year"
        case .allTime: return "All Time (All Activity)"
        case .custom: return "Custom Range"
        }
    }

    public static var custom: StatementPeriod {
        let now = Date()
        let start = Calendar.current.date(byAdding: .month, value: -1, to: now) ?? now
        return .custom(startDate: start, endDate: now)
    }

    public var isCustom: Bool {
        if case .custom = self { return true }
        return false
    }

    public func defaultTitle(calendar: Calendar = .current, referenceDate: Date = Date()) -> String {
        defaultStatementTitle(calendar: calendar, referenceDate: referenceDate)
    }

    /// Computes the exact start and end Date for the period using the current calendar.
    public func dateInterval(calendar: Calendar = .current, referenceDate: Date = Date()) -> DateInterval {
        switch self {
        case .thisMonth:
            guard let monthInterval = calendar.dateInterval(of: .month, for: referenceDate) else {
                let start = calendar.startOfDay(for: referenceDate)
                let end = calendar.date(byAdding: .month, value: 1, to: start) ?? referenceDate
                return DateInterval(start: start, end: end)
            }
            return monthInterval

        case .lastMonth:
            guard let prevMonthDate = calendar.date(byAdding: .month, value: -1, to: referenceDate),
                  let prevMonthInterval = calendar.dateInterval(of: .month, for: prevMonthDate) else {
                let start = calendar.startOfDay(for: referenceDate)
                return DateInterval(start: start, end: start)
            }
            return prevMonthInterval

        case .previous3Months:
            let startOfCurrentMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: referenceDate)) ?? referenceDate
            let start = calendar.date(byAdding: .month, value: -2, to: startOfCurrentMonth) ?? startOfCurrentMonth
            let endOfCurrentMonth = calendar.dateInterval(of: .month, for: referenceDate)?.end ?? referenceDate
            return DateInterval(start: start, end: endOfCurrentMonth)

        case .previous6Months:
            let startOfCurrentMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: referenceDate)) ?? referenceDate
            let start = calendar.date(byAdding: .month, value: -5, to: startOfCurrentMonth) ?? startOfCurrentMonth
            let endOfCurrentMonth = calendar.dateInterval(of: .month, for: referenceDate)?.end ?? referenceDate
            return DateInterval(start: start, end: endOfCurrentMonth)

        case .thisYear:
            guard let yearInterval = calendar.dateInterval(of: .year, for: referenceDate) else {
                let start = calendar.startOfDay(for: referenceDate)
                let end = calendar.date(byAdding: .year, value: 1, to: start) ?? referenceDate
                return DateInterval(start: start, end: end)
            }
            return yearInterval

        case .previousYear:
            guard let prevYearDate = calendar.date(byAdding: .year, value: -1, to: referenceDate),
                  let prevYearInterval = calendar.dateInterval(of: .year, for: prevYearDate) else {
                let start = calendar.startOfDay(for: referenceDate)
                return DateInterval(start: start, end: start)
            }
            return prevYearInterval

        case .allTime:
            let start = Date(timeIntervalSince1970: 0)
            return DateInterval(start: start, end: referenceDate)

        case .custom(let start, let end):
            let normalizedStart = calendar.startOfDay(for: min(start, end))
            let endOfDay = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: max(start, end)) ?? max(start, end)
            return DateInterval(start: normalizedStart, end: endOfDay)
        }
    }

    /// User-friendly title for the statement report (e.g. "November 2026 Statement").
    public func defaultStatementTitle(calendar: Calendar = .current, referenceDate: Date = Date()) -> String {
        let interval = dateInterval(calendar: calendar, referenceDate: referenceDate)
        let formatter = DateFormatter()
        formatter.locale = .current

        switch self {
        case .thisMonth, .lastMonth:
            formatter.dateFormat = "MMMM yyyy"
            return "\(formatter.string(from: interval.start)) Statement"
        case .thisYear:
            formatter.dateFormat = "yyyy"
            return "Annual Statement \(formatter.string(from: interval.start))"
        case .previousYear:
            formatter.dateFormat = "yyyy"
            return "Annual Statement \(formatter.string(from: interval.start))"
        case .previous3Months:
            return "3-Month Financial Statement"
        case .previous6Months:
            return "6-Month Financial Statement"
        case .allTime:
            return "All-Time Financial Statement"
        case .custom:
            formatter.dateFormat = "MMM d, yyyy"
            let endAdjusted = calendar.date(byAdding: .second, value: -1, to: interval.end) ?? interval.end
            return "Statement (\(formatter.string(from: interval.start)) – \(formatter.string(from: endAdjusted)))"
        }
    }

    /// Clean filename prefix for exported PDF or CSV files.
    public func filenamePrefix(calendar: Calendar = .current, referenceDate: Date = Date()) -> String {
        let interval = dateInterval(calendar: calendar, referenceDate: referenceDate)
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")

        switch self {
        case .thisMonth, .lastMonth:
            formatter.dateFormat = "yyyy_MM"
            return "Leaf_Statement_\(formatter.string(from: interval.start))"
        case .thisYear, .previousYear:
            formatter.dateFormat = "yyyy"
            return "Leaf_Annual_Statement_\(formatter.string(from: interval.start))"
        case .previous3Months:
            return "Leaf_3Month_Statement"
        case .previous6Months:
            return "Leaf_6Month_Statement"
        case .allTime:
            return "Leaf_All_Time_Statement"
        case .custom:
            formatter.dateFormat = "yyyyMMdd"
            let endAdjusted = calendar.date(byAdding: .second, value: -1, to: interval.end) ?? interval.end
            return "Leaf_Statement_\(formatter.string(from: interval.start))_to_\(formatter.string(from: endAdjusted))"
        }
    }

    /// Formatted date range label for UI presentation.
    public func formattedRange(calendar: Calendar = .current, referenceDate: Date = Date()) -> String {
        if case .allTime = self {
            return "All Recorded Activity"
        }

        let interval = dateInterval(calendar: calendar, referenceDate: referenceDate)
        let formatter = DateFormatter()
        formatter.locale = .current

        let startYear = calendar.component(.year, from: interval.start)
        let endYear = calendar.component(.year, from: interval.end)

        if startYear == endYear {
            formatter.dateFormat = "MMM d"
            let startStr = formatter.string(from: interval.start)
            formatter.dateFormat = "MMM d, yyyy"
            let endAdjusted = calendar.date(byAdding: .second, value: -1, to: interval.end) ?? interval.end
            let endStr = formatter.string(from: endAdjusted)
            return "\(startStr) – \(endStr)"
        } else {
            formatter.dateFormat = "MMM d, yyyy"
            let startStr = formatter.string(from: interval.start)
            let endAdjusted = calendar.date(byAdding: .second, value: -1, to: interval.end) ?? interval.end
            let endStr = formatter.string(from: endAdjusted)
            return "\(startStr) – \(endStr)"
        }
    }
}

