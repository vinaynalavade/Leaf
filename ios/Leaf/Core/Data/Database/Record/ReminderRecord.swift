import Foundation
import GRDB

public struct ReminderRecord: Codable, FetchableRecord, MutablePersistableRecord, TableRecord, Sendable {
    public static let databaseTableName = "reminders"

    public var id: Int64?
    public var title: String
    public var description: String?
    public var amountSubunits: Int64
    public var type: String
    public var dueDate: Int64
    public var recurrence: String
    public var configuredDayOfMonth: Int
    public var reminderOffsetDays: Int
    public var additionalOffsets: String?
    public var notificationHour: Int
    public var notificationMinute: Int
    public var isEnabled: Bool
    public var isPaid: Bool
    public var lastPaidDate: Int64?
    public var createdAt: Int64
    public var updatedAt: Int64

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case description
        case amountSubunits = "amount_subunits"
        case type
        case dueDate = "due_date"
        case recurrence
        case configuredDayOfMonth = "configured_day_of_month"
        case reminderOffsetDays = "reminder_offset_days"
        case additionalOffsets = "additional_offsets"
        case notificationHour = "notification_hour"
        case notificationMinute = "notification_minute"
        case isEnabled = "is_enabled"
        case isPaid = "is_paid"
        case lastPaidDate = "last_paid_date"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    public init(
        id: Int64? = nil,
        title: String,
        description: String? = nil,
        amountSubunits: Int64,
        type: String,
        dueDate: Int64,
        recurrence: String = "MONTHLY",
        configuredDayOfMonth: Int = 1,
        reminderOffsetDays: Int = 1,
        additionalOffsets: String? = nil,
        notificationHour: Int = 9,
        notificationMinute: Int = 0,
        isEnabled: Bool = true,
        isPaid: Bool = false,
        lastPaidDate: Int64? = nil,
        createdAt: Int64 = Int64(Date().timeIntervalSince1970 * 1000),
        updatedAt: Int64 = Int64(Date().timeIntervalSince1970 * 1000)
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.amountSubunits = amountSubunits
        self.type = type
        self.dueDate = dueDate
        self.recurrence = recurrence
        self.configuredDayOfMonth = configuredDayOfMonth
        self.reminderOffsetDays = reminderOffsetDays
        self.additionalOffsets = additionalOffsets
        self.notificationHour = notificationHour
        self.notificationMinute = notificationMinute
        self.isEnabled = isEnabled
        self.isPaid = isPaid
        self.lastPaidDate = lastPaidDate
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    public mutating func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }
}

