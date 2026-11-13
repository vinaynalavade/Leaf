import SwiftUI

/// Full-screen lock overlay presented whenever Leaf is locked.
/// Requires 6-digit PIN authentication, with optional Face ID / Touch ID convenience.
public struct AppLockView: View {
    @Environment(AppContainer.self) private var container
    @Environment(\.colorScheme) private var colorScheme

    @State private var enteredPin: String = ""
    @State private var errorMessage: String? = nil
    @State private var isError: Bool = false
    @State private var lockoutSecondsRemaining: Int = 0
    @State private var lockoutTimer: Timer? = nil

    public init() {}

    public var body: some View {
        ZStack {
            LeafTheme.canvas(for: colorScheme).ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer(minLength: 24)

                // App Brand Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(LeafTheme.brandEmerald.opacity(0.15))
                        .frame(width: 80, height: 80)

                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 38))
                        .foregroundStyle(LeafTheme.brandEmerald)
                }

                VStack(spacing: 8) {
                    Text("Leaf is Locked")
                        .font(LeafTypography.titleLarge)
                        .foregroundStyle(LeafTheme.textPrimary(for: colorScheme))

                    Text("Enter your 6-digit PIN to access your financial records.")
                        .font(LeafTypography.bodyMedium)
                        .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }

                // 6-Dot PIN Indicator
                PinDotsIndicator(
                    pinLength: SecurePinManager.pinLength,
                    filledCount: enteredPin.count,
                    isError: isError
                )

                // Error / Lockout Notification
                Group {
                    if lockoutSecondsRemaining > 0 {
                        Text("Too many failed attempts. Try again in \(lockoutSecondsRemaining)s.")
                            .font(LeafTypography.captionBold)
                            .foregroundStyle(LeafTheme.expenseCoral)
                    } else if let error = errorMessage {
                        Text(error)
                            .font(LeafTypography.captionBold)
                            .foregroundStyle(LeafTheme.expenseCoral)
                    } else {
                        Text(" ")
                            .font(LeafTypography.captionBold)
                    }
                }
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
                .frame(height: 20)

                Spacer(minLength: 16)

                // Keypad
                PinNumericKeypad(
                    biometricIcon: container.appLockService.isBiometricEnabled ? container.appLockService.availableBiometricType.iconName : nil,
                    onBiometric: container.appLockService.isBiometricEnabled ? {
                        triggerBiometrics()
                    } : nil,
                    onDigit: { digit in
                        handleDigit(digit)
                    },
                    onDelete: {
                        handleDelete()
                    }
                )
                .disabled(lockoutSecondsRemaining > 0)
                .opacity(lockoutSecondsRemaining > 0 ? 0.5 : 1.0)
                .padding(.bottom, 24)
            }
        }
        .task {
            checkLockoutStatus()
            if container.appLockService.isBiometricEnabled {
                triggerBiometrics()
            }
        }
        .onDisappear {
            lockoutTimer?.invalidate()
            lockoutTimer = nil
        }
    }

    private func handleDigit(_ digit: String) {
        guard lockoutSecondsRemaining == 0 else { return }
        errorMessage = nil
        isError = false

        guard enteredPin.count < SecurePinManager.pinLength else { return }
        enteredPin.append(digit)

        if enteredPin.count == SecurePinManager.pinLength {
            verifyPinSubmission()
        }
    }

    private func handleDelete() {
        guard !enteredPin.isEmpty else { return }
        errorMessage = nil
        isError = false
        enteredPin.removeLast()
    }

    private func verifyPinSubmission() {
        let pin = enteredPin
        let result = container.appLockService.unlockWithPin(pin)

        switch result {
        case .success:
            triggerSuccessHaptic()
            enteredPin = ""
            errorMessage = nil
            isError = false

        case .incorrect(let remainingAttempts):
            triggerErrorHaptic()
            isError = true
            enteredPin = ""
            if remainingAttempts > 0 {
                errorMessage = "Incorrect PIN. \(remainingAttempts) \(remainingAttempts == 1 ? "attempt" : "attempts") remaining."
            } else {
                errorMessage = "Incorrect PIN."
            }

        case .lockedOut(let secondsRemaining):
            triggerErrorHaptic()
            isError = true
            enteredPin = ""
            startLockoutCountdown(seconds: secondsRemaining)
        }
    }

    private func triggerBiometrics() {
        guard lockoutSecondsRemaining == 0 else { return }
        Task {
            _ = await container.appLockService.authenticateWithBiometrics()
        }
    }

    private func checkLockoutStatus() {
        let seconds = SecurePinManager.shared.getLockoutSecondsRemaining()
        if seconds > 0 {
            startLockoutCountdown(seconds: seconds)
        }
    }

    private func startLockoutCountdown(seconds: Int) {
        lockoutSecondsRemaining = seconds
        errorMessage = nil
        lockoutTimer?.invalidate()
        lockoutTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            if lockoutSecondsRemaining > 1 {
                lockoutSecondsRemaining -= 1
            } else {
                lockoutSecondsRemaining = 0
                timer.invalidate()
                lockoutTimer = nil
                isError = false
            }
        }
    }

    private func triggerErrorHaptic() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.error)
    }

    private func triggerSuccessHaptic() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
}
