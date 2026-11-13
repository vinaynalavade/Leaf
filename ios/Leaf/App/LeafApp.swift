import SwiftUI

@main
struct LeafApp: App {

    @State private var container: AppContainer
    @Environment(\.scenePhase) private var scenePhase

    init() {
        let appContainer = AppContainer.makeLive()
        _container = State(initialValue: appContainer)
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                // Base Tab Navigation
                MainTabView()
                    .environment(container)

                // Cold-launch & Biometric Lock Overlay
                if container.appLockService.isLocked {
                    AppLockView()
                        .environment(container)
                        .transition(.opacity)
                        .zIndex(998)
                }

                // App Switcher Multitasking Shield:
                // Immediately conceals balances, accounts, and transactions whenever app is inactive or in background
                if scenePhase != .active || container.appLockService.showPrivacyShield {
                    PrivacyShieldView()
                        .transition(.identity) // Zero-flicker instant snapshot masking
                        .zIndex(999)
                }
            }
            .task {
                // 1. Detect and safely recover any restore operation interrupted by a previous crash or termination
                await container.backupService.checkAndRecoverInterruptedRestore()

                // 2. Generate due occurrences and missed transactions on launch
                try? await container.generateDueOccurrencesUseCase.execute()
            }
            .onChange(of: scenePhase) { _, newPhase in
                switch newPhase {
                case .active:
                    container.appLockService.handleAppWillEnterForeground()
                    Task {
                        try? await container.generateDueOccurrencesUseCase.execute()
                    }
                case .inactive:
                    container.appLockService.handleAppWillResignActive()
                case .background:
                    container.appLockService.handleAppDidEnterBackground()
                @unknown default:
                    break
                }
            }
            .preferredColorScheme(container.themeColorScheme)
        }
    }
}
