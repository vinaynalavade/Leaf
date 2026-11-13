import SwiftUI

/// Secure 3-step PIN change sheet.
/// Requires current PIN verification before accepting and confirming a new 6-digit PIN.
public struct ChangePinSheet: View {
    @Environment(AppContainer.self) private var container
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss

    private enum ChangeStep {
        case enterCurrent
        case enterNew
        case confirmNew
    }

    @State private var currentStep: ChangeStep = .enterCurrent
    @State private var currentPin: String = ""
    @State private var newPin: String = ""
    @State private var confirmNewPin: String = ""
    @State private var errorMessage: String? = nil
    @State private var isError: Bool = false
    @State private var lockoutSecondsRemaining: Int = 0
    @State private var lockoutTimer: Timer? = nil

    public init() {}

    public var body: some View {
        NavigationStack {
            ZStack {
                LeafTheme.canvas(for: colorScheme).ignoresSafeArea()

                VStack(spacing: 24) {
                    Spacer(minLength: 16)

                    // Header Icon
                    ZStack {
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(LeafTheme.brandEmerald.opacity(0.12))
                            .frame(width: 72, height: 72)

                        Image(systemName: "key.fill")
                            .font(.system(size: 30))
                            .foregroundStyle(LeafTheme.brandEmerald)
                    }

                    // Step Instructions
                    VStack(spacing: 8) {
                        Text(stepTitle)
                            .font(LeafTypography.titleLarge)
                            .foregroundStyle(LeafTheme.textPrimary(for: colorScheme))

                        Text(stepSubtitle)
                            .font(LeafTypography.bodyMedium)
                            .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }

                    // 6-Dot PIN Indicator
                    PinDotsIndicator(
                        pinLength: SecurePinManager.pinLength,
                        filledCount: currentFilledCount,
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

                    // Numeric Keypad
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
            .navigationTitle("Change PIN")
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

    private var currentFilledCount: Int {
        switch currentStep {
        case .enterCurrent: return currentPin.count
        case .enterNew: return newPin.count
        case .confirmNew: return confirmNewPin.count
        }
    }

    private var stepTitle: String {
        switch currentStep {
        case .enterCurrent: return "Enter Current PIN"
        case .enterNew: return "Enter New PIN"
        case .confirmNew: return "Confirm New PIN"
        }
    }

    private var stepSubtitle: String {
        switch currentStep {
        case .enterCurrent: return "Verify your identity by entering your current 6-digit PIN."
        case .enterNew: return "Choose a new 6-digit PIN."
        case .confirmNew: return "Re-enter your new 6-digit PIN to confirm."
        }
    }

    private func handleDigit(_ digit: String) {
        guard lockoutSecondsRemaining == 0 else { return }
        errorMessage = nil
        isError = false

        switch currentStep {
        case .enterCurrent:
            guard currentPin.count < SecurePinManager.pinLength else { return }
            currentPin.append(digit)
            if currentPin.count == SecurePinManager.pinLength {
                verifyCurrentPin()
            }

        case .enterNew:
            guard newPin.count < SecurePinManager.pinLength else { return }
            newPin.append(digit)
            if newPin.count == SecurePinManager.pinLength {
                triggerStepAdvanceHaptic()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    currentStep = .confirmNew
                }
            }

        case .confirmNew:
            guard confirmNewPin.count < SecurePinManager.pinLength else { return }
            confirmNewPin.append(digit)
            if confirmNewPin.count == SecurePinManager.pinLength {
                verifyConfirmation()
            }
        }
    }

    private func handleDelete() {
        errorMessage = nil
        isError = false

        switch currentStep {
        case .enterCurrent:
            if !currentPin.isEmpty { currentPin.removeLast() }
        case .enterNew:
            if !newPin.isEmpty { newPin.removeLast() }
        case .confirmNew:
            if !confirmNewPin.isEmpty {
                confirmNewPin.removeLast()
            } else {
                newPin = ""
                currentStep = .enterNew
            }
        }
    }

    private func verifyCurrentPin() {
        let result = SecurePinManager.shared.verifyPin(currentPin)
        switch result {
        case .success:
            triggerSuccessHaptic()
            currentStep = .enterNew

        case .incorrect(let remainingAttempts):
            triggerErrorHaptic()
            isError = true
            currentPin = ""
            if remainingAttempts > 0 {
                errorMessage = "Incorrect current PIN. \(remainingAttempts) \(remainingAttempts == 1 ? "attempt" : "attempts") remaining."
            } else {
                errorMessage = "Incorrect current PIN."
            }

        case .lockedOut(let secondsRemaining):
            triggerErrorHaptic()
            isError = true
            currentPin = ""
            startLockoutCountdown(seconds: secondsRemaining)
        }
    }

    private func verifyConfirmation() {
        if newPin == confirmNewPin {
            let result = container.appLockService.changePin(currentPin: currentPin, newPin: newPin)
            if result == .success {
                triggerSuccessHaptic()
                dismiss()
            } else {
                triggerErrorHaptic()
                isError = true
                errorMessage = "Failed to update PIN. Please try again."
            }
        } else {
            triggerErrorHaptic()
            isError = true
            errorMessage = "New PINs do not match. Please try again."
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                newPin = ""
                confirmNewPin = ""
                currentStep = .enterNew
                isError = false
            }
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

    private func triggerStepAdvanceHaptic() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
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
