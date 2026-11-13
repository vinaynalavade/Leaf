import SwiftUI

/// Sheet requiring current 6-digit PIN verification before disabling App Lock.
public struct DisableAppLockSheet: View {
    @Environment(AppContainer.self) private var container
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss

    @State private var enteredPin: String = ""
    @State private var errorMessage: String? = nil
    @State private var isError: Bool = false
    @State private var lockoutSecondsRemaining: Int = 0
    @State private var lockoutTimer: Timer? = nil

    public let onDisabled: () -> Void

    public init(onDisabled: @escaping () -> Void = {}) {
        self.onDisabled = onDisabled
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                LeafTheme.canvas(for: colorScheme).ignoresSafeArea()

                VStack(spacing: 24) {
                    Spacer(minLength: 16)

                    // Header Icon
                    ZStack {
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(LeafTheme.expenseCoral.opacity(0.12))
                            .frame(width: 72, height: 72)

                        Image(systemName: "lock.open.fill")
                            .font(.system(size: 32))
                            .foregroundStyle(LeafTheme.expenseCoral)
                    }

                    // Instructions
                    VStack(spacing: 8) {
                        Text("Disable App Lock")
                            .font(LeafTypography.titleLarge)
                            .foregroundStyle(LeafTheme.textPrimary(for: colorScheme))

                        Text("Enter your 6-digit PIN to confirm disabling App Lock.")
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
                    .frame(height: 20)

                    Spacer(minLength: 16)

                    // Keypad
                    PinNumericKeypad(
                        biometricIcon: nil,
                        onBiometric: nil,
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
            .navigationTitle("Confirm Disable")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .onDisappear {
                lockoutTimer?.invalidate()
                lockoutTimer = nil
            }
        }
    }

    private func handleDigit(_ digit: String) {
        guard lockoutSecondsRemaining == 0 else { return }
        errorMessage = nil
        isError = false

        guard enteredPin.count < SecurePinManager.pinLength else { return }
        enteredPin.append(digit)

        if enteredPin.count == SecurePinManager.pinLength {
            verifyAndDisable()
        }
    }

    private func handleDelete() {
        guard !enteredPin.isEmpty else { return }
        errorMessage = nil
        isError = false
        enteredPin.removeLast()
    }

    private func verifyAndDisable() {
        let result = container.appLockService.disableAppLock(currentPin: enteredPin)
        switch result {
        case .success:
            triggerSuccessHaptic()
            onDisabled()
            dismiss()

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
