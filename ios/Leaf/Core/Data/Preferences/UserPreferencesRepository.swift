import Foundation

/// Persistent implementation of `UserPreferencesRepositoryProtocol` backed by `UserDefaults`.
public final class UserPreferencesRepository: UserPreferencesRepositoryProtocol, @unchecked Sendable {

    private let defaults: UserDefaults
    private let lock = NSLock()

    // Canonical DataStore Keys (matching master documentation Section 10.4)
    private enum Keys {
        static let isBalanceVisible = "pref_is_balance_visible"
        static let currencyCode = "pref_currency_code"
        static let openingBalance = "pref_opening_balance"
        static let profileName = "pref_profile_name"
        static let themeMode = "pref_theme_mode"
        static let lastBackupTimestamp = "pref_last_backup_timestamp"
        static let appLockEnabled = "pref_app_lock_enabled"
        static let biometricEnabled = "pref_biometric_enabled"
        static let autoLockDurationSeconds = "pref_auto_lock_duration_seconds"
        static let dailyReminderEnabled = "pref_daily_reminder_enabled"
        static let dailyReminderHour = "pref_daily_reminder_hour"
        static let dailyReminderMinute = "pref_daily_reminder_minute"
        static let automaticBackupEnabled = "pref_automatic_backup_enabled"
        static let defaultTransactionSource = "pref_default_transaction_source"
    }

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        registerDefaults()
    }

    private func registerDefaults() {
        defaults.register(defaults: [
            Keys.isBalanceVisible: true,
            Keys.currencyCode: "INR",
            Keys.openingBalance: Int64(0),
            Keys.themeMode: "SYSTEM",
            Keys.appLockEnabled: false,
            Keys.biometricEnabled: false,
            Keys.defaultTransactionSource: "CASH"
        ])
    }

    public func getUserPreferences() -> UserPreferences {
        lock.lock()
        defer { lock.unlock() }

        var prefs = UserPreferences.default
        if let suite = UserDefaults(suiteName: "group.com.vinaynalavade.Leaf"),
           suite.object(forKey: Keys.isBalanceVisible) != nil {
            let groupVis = suite.bool(forKey: Keys.isBalanceVisible)
            prefs.isBalanceVisible = groupVis
            defaults.set(groupVis, forKey: Keys.isBalanceVisible)
        } else if defaults.object(forKey: Keys.isBalanceVisible) != nil {
            prefs.isBalanceVisible = defaults.bool(forKey: Keys.isBalanceVisible)
        } else {
            prefs.isBalanceVisible = true
        }
        if let code = defaults.string(forKey: Keys.currencyCode) {
            prefs.currencyCode = code
        }
        prefs.openingBalanceSubunits = defaults.object(forKey: Keys.openingBalance) as? Int64 ?? Int64(defaults.integer(forKey: Keys.openingBalance))
        prefs.profileName = defaults.string(forKey: Keys.profileName)
        if let theme = defaults.string(forKey: Keys.themeMode) {
            prefs.themeMode = theme
        }
        prefs.lastBackupTimestamp = defaults.object(forKey: Keys.lastBackupTimestamp) as? Int64 ?? Int64(defaults.integer(forKey: Keys.lastBackupTimestamp))
        prefs.appLockEnabled = defaults.bool(forKey: Keys.appLockEnabled)
        prefs.biometricEnabled = defaults.bool(forKey: Keys.biometricEnabled)
        let autoLockVal = defaults.object(forKey: Keys.autoLockDurationSeconds) as? Int64 ?? Int64(defaults.integer(forKey: Keys.autoLockDurationSeconds))
        prefs.autoLockDurationSeconds = autoLockVal
        prefs.dailyReminderEnabled = defaults.bool(forKey: Keys.dailyReminderEnabled)
        if defaults.object(forKey: Keys.dailyReminderHour) != nil {
            prefs.dailyReminderHour = defaults.integer(forKey: Keys.dailyReminderHour)
        }
        if defaults.object(forKey: Keys.dailyReminderMinute) != nil {
            prefs.dailyReminderMinute = defaults.integer(forKey: Keys.dailyReminderMinute)
        }
        prefs.automaticBackupEnabled = defaults.bool(forKey: Keys.automaticBackupEnabled)
        if let defaultSrc = defaults.string(forKey: Keys.defaultTransactionSource) {
            prefs.defaultTransactionSource = PaymentMethod.fromString(defaultSrc)
        } else {
            prefs.defaultTransactionSource = .cash
        }
        return prefs
    }

    public func setBalanceVisible(_ isVisible: Bool) {
        lock.lock()
        defer { lock.unlock() }
        defaults.set(isVisible, forKey: Keys.isBalanceVisible)
        if let suite = UserDefaults(suiteName: "group.com.vinaynalavade.Leaf") {
            suite.set(isVisible, forKey: Keys.isBalanceVisible)
            suite.set(isVisible, forKey: "leaf_widget_is_balance_visible")
        }
        WidgetDataManager.shared.setBalanceVisible(isVisible)
    }

    public func setDefaultTransactionSource(_ source: PaymentMethod) {
        lock.lock()
        defer { lock.unlock() }
        defaults.set(source.rawValue, forKey: Keys.defaultTransactionSource)
    }

    public func setCurrencyCode(_ code: String) {
        lock.lock()
        defer { lock.unlock() }
        defaults.set(code, forKey: Keys.currencyCode)
    }

    public func setOpeningBalance(_ subunits: Int64) {
        lock.lock()
        defer { lock.unlock() }
        defaults.set(subunits, forKey: Keys.openingBalance)
    }

    public func setProfileName(_ name: String?) {
        lock.lock()
        defer { lock.unlock() }
        if let name = name {
            defaults.set(name, forKey: Keys.profileName)
        } else {
            defaults.removeObject(forKey: Keys.profileName)
        }
    }

    public func setThemeMode(_ mode: String) {
        lock.lock()
        defer { lock.unlock() }
        defaults.set(mode, forKey: Keys.themeMode)
    }

    public func setLastBackupTimestamp(_ timestamp: Int64) {
        lock.lock()
        defer { lock.unlock() }
        defaults.set(timestamp, forKey: Keys.lastBackupTimestamp)
    }

    public func setAppLockEnabled(_ enabled: Bool) {
        lock.lock()
        defer { lock.unlock() }
        defaults.set(enabled, forKey: Keys.appLockEnabled)
    }

    public func setBiometricEnabled(_ enabled: Bool) {
        lock.lock()
        defer { lock.unlock() }
        defaults.set(enabled, forKey: Keys.biometricEnabled)
    }

    public func setAutoLockDurationSeconds(_ seconds: Int64) {
        lock.lock()
        defer { lock.unlock() }
        defaults.set(seconds, forKey: Keys.autoLockDurationSeconds)
    }

    public func setDailyReminder(enabled: Bool, hour: Int, minute: Int) {
        lock.lock()
        defer { lock.unlock() }
        defaults.set(enabled, forKey: Keys.dailyReminderEnabled)
        defaults.set(hour, forKey: Keys.dailyReminderHour)
        defaults.set(minute, forKey: Keys.dailyReminderMinute)
    }

    public func setAutomaticBackupEnabled(_ enabled: Bool) {
        lock.lock()
        defer { lock.unlock() }
        defaults.set(enabled, forKey: Keys.automaticBackupEnabled)
    }

    public func resetAllPreferences() {
        lock.lock()
        defer { lock.unlock() }
        defaults.removeObject(forKey: Keys.isBalanceVisible)
        defaults.removeObject(forKey: Keys.currencyCode)
        defaults.removeObject(forKey: Keys.openingBalance)
        defaults.removeObject(forKey: Keys.profileName)
        defaults.removeObject(forKey: Keys.themeMode)
        defaults.removeObject(forKey: Keys.lastBackupTimestamp)
        defaults.removeObject(forKey: Keys.appLockEnabled)
        defaults.removeObject(forKey: Keys.biometricEnabled)
        defaults.removeObject(forKey: Keys.autoLockDurationSeconds)
        registerDefaults()
    }
}

