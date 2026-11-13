import Foundation

/// Pure Swift engine executing recurrence calendar arithmetic, anchor-preserving date progressions,
/// leap-year adjustments, and payment occurrence lifecycle evaluations.
public enum RecurrenceEngine {

    private static var calendar: Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone.current
        return cal
    }

    // MARK: - 1. Date Calculation with Anchor Preservation

    /// Calculates the occurrence date for step `stepIndex` (0-based) from `startDate`
    /// preserving the intended day-of-month or month-of-year anchor.
    public static func dateForOccurrence(
        stepIndex: Int,
        startDate: Date,
        frequency: RecurringScheduleFrequency,
        interval: Int = 1,
        anchorDayOfMonth: Int,
        anchorDayOfWeek: Int
    ) -> Date {
        let cal = calendar
        let startComponents = cal.dateComponents([.year, .month, .day, .hour, .minute, .second], from: startDate)
        let safeInterval = max(1, interval)

        switch frequency {
        case .daily:
            let daysToAdd = stepIndex * safeInterval
            return cal.date(byAdding: .day, value: daysToAdd, to: startDate) ?? startDate

        case .weekly:
            let daysToAdd = stepIndex * safeInterval * 7
            return cal.date(byAdding: .day, value: daysToAdd, to: startDate) ?? startDate

        case .biweekly:
            let daysToAdd = stepIndex * safeInterval * 14
            return cal.date(byAdding: .day, value: daysToAdd, to: startDate) ?? startDate

        case .monthly:
            let monthsToAdd = stepIndex * safeInterval
            return addMonthsPreservingAnchor(
                from: startComponents,
                monthsToAdd: monthsToAdd,
                anchorDay: anchorDayOfMonth,
                calendar: cal
            )

        case .everyTwoMonths:
            let monthsToAdd = stepIndex * safeInterval * 2
            return addMonthsPreservingAnchor(
                from: startComponents,
                monthsToAdd: monthsToAdd,
                anchorDay: anchorDayOfMonth,
                calendar: cal
            )

        case .quarterly:
            let monthsToAdd = stepIndex * safeInterval * 3
            return addMonthsPreservingAnchor(
                from: startComponents,
                monthsToAdd: monthsToAdd,
                anchorDay: anchorDayOfMonth,
                calendar: cal
            )

        case .halfYearly:
            let monthsToAdd = stepIndex * safeInterval * 6
            return addMonthsPreservingAnchor(
                from: startComponents,
                monthsToAdd: monthsToAdd,
                anchorDay: anchorDayOfMonth,
                calendar: cal
            )

        case .yearly:
            let yearsToAdd = stepIndex * safeInterval
            var targetComponents = startComponents
            guard let startYear = startComponents.year, let startMonth = startComponents.month else {
                return startDate
            }
            let targetYear = startYear + yearsToAdd
            targetComponents.year = targetYear

            // Calculate max days in that month/year (e.g. Feb 29 on leap years vs Feb 28 on non-leap years)
            var rangeComponents = DateComponents()
            rangeComponents.year = targetYear
            rangeComponents.month = startMonth
            if let monthStart = cal.date(from: rangeComponents),
               let range = cal.range(of: .day, in: .month, for: monthStart) {
                let maxDays = range.count
                targetComponents.day = min(anchorDayOfMonth, maxDays)
            } else {
                targetComponents.day = min(anchorDayOfMonth, 28)
            }

            return cal.date(from: targetComponents) ?? startDate

        case .custom:
            let daysToAdd = stepIndex * safeInterval
            return cal.date(byAdding: .day, value: daysToAdd, to: startDate) ?? startDate
        }
    }

    /// Adds `monthsToAdd` months to `startComponents` while clamping the day to the maximum available in that month,
    /// without drifting the original `anchorDay` for subsequent steps.
    private static func addMonthsPreservingAnchor(
        from startComponents: DateComponents,
        monthsToAdd: Int,
        anchorDay: Int,
        calendar: Calendar
    ) -> Date {
        guard let startYear = startComponents.year, let startMonth = startComponents.month else {
            return Date()
        }

        let totalMonthIndex = (startYear * 12 + (startMonth - 1)) + monthsToAdd
        let targetYear = totalMonthIndex / 12
        let targetMonth = (totalMonthIndex % 12) + 1

        var targetComponents = startComponents
        targetComponents.year = targetYear
        targetComponents.month = targetMonth

        var rangeComponents = DateComponents()
        rangeComponents.year = targetYear
        rangeComponents.month = targetMonth
        if let monthStart = calendar.date(from: rangeComponents),
           let range = calendar.range(of: .day, in: .month, for: monthStart) {
            let maxDays = range.count
            targetComponents.day = min(anchorDay, maxDays)
        } else {
            targetComponents.day = min(anchorDay, 28)
        }

        return calendar.date(from: targetComponents) ?? Date()
    }

    // MARK: - 2. Schedule Progression & Due Occurrences Generation

    /// Generates due occurrence timestamps for a recurring schedule up to a given cutoff date.
    /// Handles multiple missed occurrences when a user returns after being away.
    public static func generateOccurrenceTimestamps(
        startDateEpoch: Int64,
        endDateEpoch: Int64?,
        frequency: RecurringScheduleFrequency,
        interval: Int = 1,
        anchorDayOfMonth: Int,
        anchorDayOfWeek: Int,
        upTo targetDate: Date = Date(),
        maxOccurrences: Int = 120
    ) -> [Int64] {
        let cal = calendar
        let start = Date(timeIntervalSince1970: Double(startDateEpoch) / 1000.0)
        let targetDayEnd = cal.startOfDay(for: targetDate).addingTimeInterval(86400 - 1)
        let endCutoff = endDateEpoch.map { Date(timeIntervalSince1970: Double($0) / 1000.0) }

        var results: [Int64] = []
        var step = 0

        while step < maxOccurrences {
            let occDate = dateForOccurrence(
                stepIndex: step,
                startDate: start,
                frequency: frequency,
                interval: interval,
                anchorDayOfMonth: anchorDayOfMonth,
                anchorDayOfWeek: anchorDayOfWeek
            )

            // If past the configured end date, terminate
            if let end = endCutoff, occDate > end {
                break
            }

            // If occurrence is beyond targetDate window, stop
            if occDate > targetDayEnd {
                break
            }

            let epochMs = Int64(occDate.timeIntervalSince1970 * 1000.0)
            results.append(epochMs)
            step += 1
        }

        return results
    }

    /// Determines the next future occurrence date after a given reference point.
    public static func calculateNextOccurrence(
        startDateEpoch: Int64,
        endDateEpoch: Int64?,
        frequency: RecurringScheduleFrequency,
        interval: Int = 1,
        anchorDayOfMonth: Int,
        anchorDayOfWeek: Int,
        after referenceDate: Date = Date()
    ) -> Int64? {
        let cal = calendar
        let start = Date(timeIntervalSince1970: Double(startDateEpoch) / 1000.0)
        let endCutoff = endDateEpoch.map { Date(timeIntervalSince1970: Double($0) / 1000.0) }
        let referenceStartOfDay = cal.startOfDay(for: referenceDate)

        var step = 0
        while step < 365 {
            let occDate = dateForOccurrence(
                stepIndex: step,
                startDate: start,
                frequency: frequency,
                interval: interval,
                anchorDayOfMonth: anchorDayOfMonth,
                anchorDayOfWeek: anchorDayOfWeek
            )

            if let end = endCutoff, occDate > end {
                return nil
            }

            let occStartOfDay = cal.startOfDay(for: occDate)
            if occStartOfDay >= referenceStartOfDay {
                return Int64(occDate.timeIntervalSince1970 * 1000.0)
            }

            step += 1
        }

        return nil
    }

    // MARK: - 3. Occurrence Status Resolution

    /// Determines the payment status of an occurrence given its scheduled date and current time.
    public static func resolveStatus(
        scheduledDateEpoch: Int64,
        isPaid: Bool,
        isSkipped: Bool,
        referenceDate: Date = Date()
    ) -> BillPaymentStatus {
        if isPaid { return .paid }
        if isSkipped { return .skipped }

        let cal = calendar
        let occDate = Date(timeIntervalSince1970: Double(scheduledDateEpoch) / 1000.0)
        let occStartOfDay = cal.startOfDay(for: occDate)
        let refStartOfDay = cal.startOfDay(for: referenceDate)

        if occStartOfDay < refStartOfDay {
            return .overdue
        } else if occStartOfDay == refStartOfDay {
            return .due
        } else {
            return .upcoming
        }
    }
}

