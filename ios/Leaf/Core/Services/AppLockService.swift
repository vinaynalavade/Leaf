import Foundation
import LocalAuthentication
import SwiftUI

/// Manages application-level authentication via secure 6-digit PIN and optional biometrics
/// (Face ID / Touch ID), along with App Switcher privacy shielding.
@Observable
public final class AppLockService: @unchecked Sendable {

    public static let shared = AppLockService()

    private let preferencesRepository: UserPreferencesRepositoryProtocol?
    private let pinManager: SecurePinManager
    private let lock = NSLock()

    public var isLocked: Bool = false
    public var isAppLockEnabled: Bool = false
    public var isBiometricEnabled: Bool = false
    public var autoLockTimeout: AutoLockTimeout = .immediately
    public var availableBiometricType: BiometricType = .none
    public var showPrivacyShield: Bool = false

    private var lastBackgroundDate: Date? = nil

    public init(
        preferencesRepository: UserPreferencesRepositoryProtocol? = nil,
        pinManager: SecurePinManager = .shared
    ) {
        self.preferencesRepository = preferencesRepository
        self.pinManager = pinManager
        self.availableBiometricType = Self.detectBiometricType()

        if let prefs = preferencesRepository?.getUserPreferences() {
            let pinConfigured = pinManager.isPinConfigured()
            // Defensive sanitization: if App Lock was flagged enabled but no PIN exists in Keychain,
            // automatically disable App Lock to prevent locking users out.
            if prefs.appLockEnabled && !pinConfigured {
                self.isAppLockEnabled = false
                self.isLocked = false
                self.isBiometricEnabled = false
                preferencesRepository?.setAppLockEnabled(false)
                preferencesRepository?.setBiometricEnabled(false)
            } else {
                self.isAppLockEnabled = prefs.appLockEnabled
                self.isBiometricEnabled = prefs.biometricEnabled
                self.isLocked = prefs.appLockEnabled
            }
            self.autoLockTimeout = AutoLockTimeout(rawValue: prefs.autoLockDurationSeconds) ?? .immediately
        }
    }

    // MARK: - PIN Operations

    public var isPinConfigured: Bool {
        pinManager.isPinConfigured()
    }

    /// Unlocks the app if the entered PIN matches the Keychain credential.
    public func unlockWithPin(_ pin: String) -> PinVerificationResult {
        guard isAppLockEnabled else {
            unlockManually()
            return .success
        }

        let result = pinManager.verifyPin(pin)
        if result == .success {
            unlockManually()
        }
        return result
    }

    /// Activates App Lock after validating and storing a new 6-digit PIN in the Keychain.
    public func enableAppLock(pin: String, enableBiometrics: Bool = false) -> Bool {
        guard pinManager.savePin(pin) else { return false }

        lock.lock()
        isAppLockEnabled = true
        isBiometricEnabled = enableBiometrics
        lock.unlock()

        preferencesRepository?.setAppLockEnabled(true)
        preferencesRepository?.setBiometricEnabled(enableBiometrics)
        return true
    }

    /// Verifies current PIN before disabling App Lock and purging Keychain credentials.
    public func disableAppLock(currentPin: String) -> PinVerificationResult {
        let result = pinManager.verifyPin(currentPin)
        guard result == .success else {
            return result
        }

        _ = pinManager.clearPin()

        lock.lock()
        isAppLockEnabled = false
        isBiometricEnabled = false
        isLocked = false
        showPrivacyShield = false
        lock.unlock()

        preferencesRepository?.setAppLockEnabled(false)
        preferencesRepository?.setBiometricEnabled(false)
        return .success
    }

    /// Verifies current PIN and updates Keychain with a new 6-digit PIN.
    public func changePin(currentPin: String, newPin: String) -> PinVerificationResult {
        let verifyResult = pinManager.verifyPin(currentPin)
        guard verifyResult == .success else {
            return verifyResult
        }

        guard newPin.count == SecurePinManager.pinLength, newPin.allSatisfy(\.isNumber) else {
            return .incorrect(remainingAttempts: SecurePinManager.maxFailedAttempts)
        }

        guard pinManager.savePin(newPin) else {
            return .incorrect(remainingAttempts: SecurePinManager.maxFailedAttempts)
        }

        return .success
    }

    // MARK: - Biometric Detection & Authentication

    public static func detectBiometricType() -> BiometricType {
        let context = LAContext()
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            return .none
        }

        switch context.biometryType {
        case .faceID:
            return .faceID
        case .touchID:
            return .touchID
        case .opticID:
            return .opticID
        case .none:
            return .none
        @unknown default:
            return .none
        }
    }

    /// Optional biometric unlock convenience. Never replaces PIN configuration.
    public func authenticateWithBiometrics(reason: String = "Unlock Leaf to access your financial data") async -> Bool {
        guard isAppLockEnabled && isBiometricEnabled && availableBiometricType != .none else {
            return false
        }

        let context = LAContext()
        context.localizedCancelTitle = "Use PIN"

        return await withCheckedContinuation { continuation in
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { [weak self] success, _ in
                DispatchQueue.main.async {
                    if success {
                        self?.unlockManually()
                        continuation.resume(returning: true)
                    } else {
                        continuation.resume(returning: false)
                    }
                }
            }
        }
    }

    /// Backward-compatibility wrapper for biometric evaluation.
    public func authenticate(reason: String = "Unlock Leaf to access your financial data") async -> Bool {
        await authenticateWithBiometrics(reason: reason)
    }

    public func unlockManually() {
        lock.lock()
        isLocked = false
        lastBackgroundDate = nil
        showPrivacyShield = false
        lock.unlock()
    }

    public func lockImmediately() {
        guard isAppLockEnabled else { return }
        lock.lock()
        isLocked = true
        lock.unlock()
    }

    // MARK: - Lifecycle Hooks

    /// Invoked when app transitions to inactive (e.g. multitasking gesture, notification shade, phone call).
    public func handleAppWillResignActive() {
        guard isAppLockEnabled else { return }
        lock.lock()
        lastBackgroundDate = Date()
        if autoLockTimeout == .immediately {
            isLocked = true
        }
        lock.unlock()
    }

    /// Invoked when app enters background.
    public func handleAppDidEnterBackground() {
        guard isAppLockEnabled else { return }
        lock.lock()
        if lastBackgroundDate == nil {
            lastBackgroundDate = Date()
        }
        if autoLockTimeout == .immediately {
            isLocked = true
        }
        lock.unlock()
    }

    /// Invoked when app enters foreground.
    public func handleAppWillEnterForeground() {
        guard isAppLockEnabled else { return }
        lock.lock()
        defer { lock.unlock() }

        if let bgDate = lastBackgroundDate {
            let elapsed = Date().timeIntervalSince(bgDate)
            if elapsed >= Double(autoLockTimeout.rawValue) {
                isLocked = true
            }
        } else if autoLockTimeout == .immediately {
            isLocked = true
        }
    }

    // MARK: - Settings Mutators

    public func setAppLockEnabled(_ enabled: Bool) {
        lock.lock()
        isAppLockEnabled = enabled
        if !enabled {
            isLocked = false
            showPrivacyShield = false
        }
        lock.unlock()
        preferencesRepository?.setAppLockEnabled(enabled)
    }

    public func setBiometricEnabled(_ enabled: Bool) {
        lock.lock()
        isBiometricEnabled = enabled
        lock.unlock()
        preferencesRepository?.setBiometricEnabled(enabled)
    }

    public func setAutoLockTimeout(_ timeout: AutoLockTimeout) {
        lock.lock()
        autoLockTimeout = timeout
        lock.unlock()
        preferencesRepository?.setAutoLockDurationSeconds(timeout.rawValue)
    }
}
