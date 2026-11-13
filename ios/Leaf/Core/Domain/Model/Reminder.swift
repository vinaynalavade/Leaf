import Foundation

public enum ReminderType: String, Codable, CaseIterable, Sendable {
    case loanEmi = "LOAN_EMI"
    case creditCard = "CREDIT_CARD"
    case bill = "BILL"
    case insurance = "INSURANCE"
    case rent = "RENT"
    case subscription = "SUBSCRIPTION"
    case custom = "CUSTOM"

    public var displayName: String {
        switch self {
        case .loanEmi: return "Loan EMI"
        case .creditCard: return "Credit Card"
        case .bill: return "Bill"
        case .insurance: return "Insurance"
        case .rent: return "Rent"
        case .subscription: return "Subscription"
        case .custom: return "Custom"
        }
    }
}

public enum ReminderRecurrence: String, Codable, CaseIterable, Sendable {
    case oneTime = "ONE_TIME"
    case daily = "DAILY"
    case weekly = "WEEKLY"
    case monthly = "MONTHLY"
    case yearly = "YEARLY"
}

public struct Reminder: Identifiable, Hashable, Codable, Sendable {
    public let id: Int64
    public let title: String
    public let description: String?
    public let amount: Amount
    public let type: ReminderType
    public let dueDate: Int64
    public let recurrence: ReminderRecurrence
    public let configuredDayOfMonth: Int
    public let reminderOffsetDays: Int
    public let additionalOffsets: String?
    public let notificationHour: Int
    public let notificationMinute: Int
    public let isEnabled: Bool
    public let isPaid: Bool
    public let lastPaidDate: Int64?
    public let createdAt: Int64
    public let updatedAt: Int64

    public init(
        id: Int64 = 0,
        title: String,
        description: String? = nil,
        amount: Amount,
        type: ReminderType = .bill,
        dueDate: Int64,
        recurrence: ReminderRecurrence = .monthly,
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
        self.amount = amount
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
}

