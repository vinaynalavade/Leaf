import Foundation

/// Repository protocol managing user settings, financial preferences, and privacy toggles.
public protocol UserPreferencesRepositoryProtocol: Sendable {
    func getUserPreferences() -> UserPreferences
    func setBalanceVisible(_ isVisible: Bool)
    func setCurrencyCode(_ code: String)
    func setOpeningBalance(_ subunits: Int64)
    func setProfileName(_ name: String?)
    func setThemeMode(_ mode: String)
    func setLastBackupTimestamp(_ timestamp: Int64)
    func setAppLockEnabled(_ enabled: Bool)
    func setBiometricEnabled(_ enabled: Bool)
    func setAutoLockDurationSeconds(_ seconds: Int64)
    func setDailyReminder(enabled: Bool, hour: Int, minute: Int)
    func setAutomaticBackupEnabled(_ enabled: Bool)
    func setOpeningBalanceSubunits(_ subunits: Int64)
    func setDefaultTransactionSource(_ source: PaymentMethod)
    func resetAllPreferences()
}

public extension UserPreferencesRepositoryProtocol {
    func setOpeningBalanceSubunits(_ subunits: Int64) {
        setOpeningBalance(subunits)
    }

    func setBiometricEnabled(_ enabled: Bool) {}
    func setDefaultTransactionSource(_ source: PaymentMethod) {}
}

