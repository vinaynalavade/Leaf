import Foundation
import SwiftUI
import UserNotifications

@Observable
public final class PrivacyDashboardViewModel {

    private let preferencesRepository: UserPreferencesRepositoryProtocol
    private let appLockService: AppLockService
    private let deleteAllFinancialDataUseCase: DeleteAllFinancialDataUseCase
    private let notificationService: NotificationService

    public var isAppLockEnabled: Bool = false
    public var isBiometricEnabled: Bool = false
    public var selectedTimeout: AutoLockTimeout = .immediately
    public var biometricType: BiometricType = .none
    public var lastBackupDate: Date? = nil
    public var notificationStatus: UNAuthorizationStatus = .notDetermined

    public var isCreateBackupSheetPresented: Bool = false
    public var isRestoreBackupSheetPresented: Bool = false
    public var isDeleteConfirmationPresented: Bool = false
    public var isDeleting: Bool = false
    public var deleteSuccess: Bool = false

    public init(
        preferencesRepository: UserPreferencesRepositoryProtocol,
        appLockService: AppLockService,
        deleteAllFinancialDataUseCase: DeleteAllFinancialDataUseCase,
        notificationService: NotificationService = .shared
    ) {
        self.preferencesRepository = preferencesRepository
        self.appLockService = appLockService
        self.deleteAllFinancialDataUseCase = deleteAllFinancialDataUseCase
        self.notificationService = notificationService
        loadData()
    }

    public func loadData() {
        let prefs = preferencesRepository.getUserPreferences()
        self.isAppLockEnabled = appLockService.isAppLockEnabled && appLockService.isPinConfigured
        self.isBiometricEnabled = appLockService.isBiometricEnabled
        self.selectedTimeout = appLockService.autoLockTimeout
        self.biometricType = appLockService.availableBiometricType

        if prefs.lastBackupTimestamp > 0 {
            self.lastBackupDate = Date(timeIntervalSince1970: Double(prefs.lastBackupTimestamp) / 1000.0)
        } else {
            self.lastBackupDate = nil
        }

        Task {
            let status = await notificationService.checkAuthorizationStatus()
            await MainActor.run {
                self.notificationStatus = status
            }
        }
    }

    public func setBiometricEnabled(_ enabled: Bool) {
        isBiometricEnabled = enabled
        appLockService.setBiometricEnabled(enabled)
    }

    public func updateTimeout(timeout: AutoLockTimeout) {
        selectedTimeout = timeout
        appLockService.setAutoLockTimeout(timeout)
    }

    public func deleteAllData() async throws {
        isDeleting = true
        defer { isDeleting = false }

        try await deleteAllFinancialDataUseCase.execute()
        _ = SecurePinManager.shared.clearPin()
        appLockService.setAppLockEnabled(false)
        isAppLockEnabled = false
        isBiometricEnabled = false
        lastBackupDate = nil
        deleteSuccess = true
    }
}
