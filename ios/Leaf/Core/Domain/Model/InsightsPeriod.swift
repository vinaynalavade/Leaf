import Foundation

/// Defines time period windows for financial analysis and comparisons.
public enum InsightsPeriod: Hashable, Sendable, Identifiable {
    case thisWeek
    case thisMonth
    case lastMonth
    case last3Months
    case last6Months
    case thisYear
    case custom(startDate: Date, endDate: Date)

    public var id: String {
        switch self {
        case .thisWeek: return "thisWeek"
        case .thisMonth: return "thisMonth"
        case .lastMonth: return "lastMonth"
        case .last3Months: return "last3Months"
        case .last6Months: return "last6Months"
        case .thisYear: return "thisYear"
        case .custom(let start, let end):
            return "custom_\(Int64(start.timeIntervalSince1970))_\(Int64(end.timeIntervalSince1970))"
        }
    }

    public var title: String {
        switch self {
        case .thisWeek: return "This Week"
        case .thisMonth: return "This Month"
        case .lastMonth: return "Last Month"
        case .last3Months: return "3 Months"
        case .last6Months: return "6 Months"
        case .thisYear: return "This Year"
        case .custom: return "Custom"
        }
    }

    /// Computes the exact start and end Date for the period using the current calendar.
    public func dateInterval(calendar: Calendar = .current, referenceDate: Date = Date()) -> DateInterval {
        switch self {
        case .thisWeek:
            guard let weekInterval = calendar.dateInterval(of: .weekOfYear, for: referenceDate) else {
                let start = calendar.startOfDay(for: referenceDate)
                let end = calendar.date(byAdding: .day, value: 7, to: start) ?? referenceDate
                return DateInterval(start: start, end: end)
            }
            return weekInterval

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

        case .last3Months:
            let startOfCurrentMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: referenceDate)) ?? referenceDate
            let start = calendar.date(byAdding: .month, value: -2, to: startOfCurrentMonth) ?? startOfCurrentMonth
            let endOfCurrentMonth = calendar.dateInterval(of: .month, for: referenceDate)?.end ?? referenceDate
            return DateInterval(start: start, end: endOfCurrentMonth)

        case .last6Months:
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

        case .custom(let start, let end):
            let normalizedStart = calendar.startOfDay(for: min(start, end))
            let endOfDay = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: max(start, end)) ?? max(start, end)
            return DateInterval(start: normalizedStart, end: endOfDay)
        }
    }

    /// Computes the equivalent preceding period for comparison (e.g., previous month or matching duration shifted back).
    public func previousEquivalentInterval(calendar: Calendar = .current, referenceDate: Date = Date()) -> DateInterval {
        let currentInterval = self.dateInterval(calendar: calendar, referenceDate: referenceDate)

        switch self {
        case .thisWeek:
            let prevStart = calendar.date(byAdding: .day, value: -7, to: currentInterval.start) ?? currentInterval.start
            let prevEnd = currentInterval.start
            return DateInterval(start: prevStart, end: prevEnd)

        case .thisMonth:
            guard let prevMonthDate = calendar.date(byAdding: .month, value: -1, to: currentInterval.start),
                  let prevMonthInterval = calendar.dateInterval(of: .month, for: prevMonthDate) else {
                let prevStart = calendar.date(byAdding: .day, value: -30, to: currentInterval.start) ?? currentInterval.start
                return DateInterval(start: prevStart, end: currentInterval.start)
            }
            return prevMonthInterval

        case .lastMonth:
            guard let twoMonthsAgoDate = calendar.date(byAdding: .month, value: -1, to: currentInterval.start),
                  let twoMonthsAgoInterval = calendar.dateInterval(of: .month, for: twoMonthsAgoDate) else {
                let prevStart = calendar.date(byAdding: .day, value: -30, to: currentInterval.start) ?? currentInterval.start
                return DateInterval(start: prevStart, end: currentInterval.start)
            }
            return twoMonthsAgoInterval

        case .last3Months:
            let prevStart = calendar.date(byAdding: .month, value: -3, to: currentInterval.start) ?? currentInterval.start
            let prevEnd = currentInterval.start
            return DateInterval(start: prevStart, end: prevEnd)

        case .last6Months:
            let prevStart = calendar.date(byAdding: .month, value: -6, to: currentInterval.start) ?? currentInterval.start
            let prevEnd = currentInterval.start
            return DateInterval(start: prevStart, end: prevEnd)

        case .thisYear:
            let prevStart = calendar.date(byAdding: .year, value: -1, to: currentInterval.start) ?? currentInterval.start
            let prevEnd = currentInterval.start
            return DateInterval(start: prevStart, end: prevEnd)

        case .custom:
            let duration = currentInterval.duration
            let prevStart = currentInterval.start.addingTimeInterval(-duration)
            let prevEnd = currentInterval.start
            return DateInterval(start: prevStart, end: prevEnd)
        }
    }

    /// Formatted date range label for UI presentation, e.g. "Nov 1 – Nov 30, 2026".
    public func formattedRange(calendar: Calendar = .current, referenceDate: Date = Date()) -> String {
        let interval = self.dateInterval(calendar: calendar, referenceDate: referenceDate)
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

