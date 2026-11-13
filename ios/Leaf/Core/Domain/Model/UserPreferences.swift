import Foundation

public struct UserPreferences: Hashable, Codable, Sendable {
    public var openingBalanceSubunits: Int64
    public var currencyCode: String
    public var themeMode: String
    public var isFirstLaunch: Bool
    public var dynamicColors: Bool
    public var dailyReminderEnabled: Bool
    public var dailyReminderHour: Int
    public var dailyReminderMinute: Int
    public var emiRemindersEnabled: Bool
    public var billRemindersEnabled: Bool
    public var creditCardRemindersEnabled: Bool
    public var defaultReminderOffsetDays: Int
    public var defaultReminderHour: Int
    public var defaultReminderMinute: Int
    public var lastBackupTimestamp: Int64
    public var appLockEnabled: Bool
    public var biometricEnabled: Bool
    public var autoLockDurationSeconds: Int64
    public var hideContentInRecents: Bool
    public var notificationsMasterEnabled: Bool
    public var budgetAlertsEnabled: Bool
    public var monthlyBudgetLimitSubunits: Int64
    public var recurringRemindersEnabled: Bool
    public var recurringReminderAdvanceDays: Int
    public var savingsGoalNotificationsEnabled: Bool
    public var appLanguage: String
    public var profileName: String?
    public var profileImageUri: String?
    public var automaticBackupEnabled: Bool
    public var isAppTourCompleted: Bool
    public var defaultIncomeSource: PaymentMethod
    public var defaultExpenseSource: PaymentMethod
    public var defaultTransactionSource: PaymentMethod
    public var isBalanceVisible: Bool

    public init(
        openingBalanceSubunits: Int64 = 0,
        currencyCode: String = "INR",
        themeMode: String = "SYSTEM",
        isFirstLaunch: Bool = true,
        dynamicColors: Bool = true,
        dailyReminderEnabled: Bool = false,
        dailyReminderHour: Int = 21,
        dailyReminderMinute: Int = 0,
        emiRemindersEnabled: Bool = true,
        billRemindersEnabled: Bool = true,
        creditCardRemindersEnabled: Bool = true,
        defaultReminderOffsetDays: Int = 1,
        defaultReminderHour: Int = 9,
        defaultReminderMinute: Int = 0,
        lastBackupTimestamp: Int64 = 0,
        appLockEnabled: Bool = false,
        biometricEnabled: Bool = false,
        autoLockDurationSeconds: Int64 = 0,
        hideContentInRecents: Bool = true,
        notificationsMasterEnabled: Bool = false,
        budgetAlertsEnabled: Bool = false,
        monthlyBudgetLimitSubunits: Int64 = 0,
        recurringRemindersEnabled: Bool = false,
        recurringReminderAdvanceDays: Int = 1,
        savingsGoalNotificationsEnabled: Bool = false,
        appLanguage: String = "SYSTEM",
        profileName: String? = nil,
        profileImageUri: String? = nil,
        automaticBackupEnabled: Bool = false,
        isAppTourCompleted: Bool = false,
        defaultIncomeSource: PaymentMethod = .account,
        defaultExpenseSource: PaymentMethod = .cash,
        defaultTransactionSource: PaymentMethod = .cash,
        isBalanceVisible: Bool = true
    ) {
        self.openingBalanceSubunits = openingBalanceSubunits
        self.currencyCode = currencyCode
        self.themeMode = themeMode
        self.isFirstLaunch = isFirstLaunch
        self.dynamicColors = dynamicColors
        self.dailyReminderEnabled = dailyReminderEnabled
        self.dailyReminderHour = dailyReminderHour
        self.dailyReminderMinute = dailyReminderMinute
        self.emiRemindersEnabled = emiRemindersEnabled
        self.billRemindersEnabled = billRemindersEnabled
        self.creditCardRemindersEnabled = creditCardRemindersEnabled
        self.defaultReminderOffsetDays = defaultReminderOffsetDays
        self.defaultReminderHour = defaultReminderHour
        self.defaultReminderMinute = defaultReminderMinute
        self.lastBackupTimestamp = lastBackupTimestamp
        self.appLockEnabled = appLockEnabled
        self.biometricEnabled = biometricEnabled
        self.autoLockDurationSeconds = autoLockDurationSeconds
        self.hideContentInRecents = hideContentInRecents
        self.notificationsMasterEnabled = notificationsMasterEnabled
        self.budgetAlertsEnabled = budgetAlertsEnabled
        self.monthlyBudgetLimitSubunits = monthlyBudgetLimitSubunits
        self.recurringRemindersEnabled = recurringRemindersEnabled
        self.recurringReminderAdvanceDays = recurringReminderAdvanceDays
        self.savingsGoalNotificationsEnabled = savingsGoalNotificationsEnabled
        self.appLanguage = appLanguage
        self.profileName = profileName
        self.profileImageUri = profileImageUri
        self.automaticBackupEnabled = automaticBackupEnabled
        self.isAppTourCompleted = isAppTourCompleted
        self.defaultIncomeSource = defaultIncomeSource
        self.defaultExpenseSource = defaultExpenseSource
        self.defaultTransactionSource = defaultTransactionSource
        self.isBalanceVisible = isBalanceVisible
    }

    public static let `default` = UserPreferences()

    public var currency: Currency {
        Currency.fromCode(currencyCode)
    }

    public var openingBalance: Amount {
        Amount(subunits: openingBalanceSubunits)
    }
}

