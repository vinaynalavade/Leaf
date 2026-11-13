import SwiftUI

/// Dedicated 6-digit PIN setup sheet (Create & Confirm flow).
/// App Lock is activated ONLY after successful PIN confirmation.
public struct AppLockSetupSheet: View {
    @Environment(AppContainer.self) private var container
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss

    private enum SetupStep {
        case createPin
        case confirmPin
    }

    @State private var currentStep: SetupStep = .createPin
    @State private var firstPin: String = ""
    @State private var confirmPin: String = ""
    @State private var errorMessage: String? = nil
    @State private var isError: Bool = false
    @State private var showBiometricsPrompt: Bool = false

    public let onSetupCompleted: () -> Void

    public init(onSetupCompleted: @escaping () -> Void = {}) {
        self.onSetupCompleted = onSetupCompleted
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
                            .fill(LeafTheme.brandEmerald.opacity(0.12))
                            .frame(width: 72, height: 72)

                        Image(systemName: "lock.badge.clock.fill")
                            .font(.system(size: 32))
                            .foregroundStyle(LeafTheme.brandEmerald)
                    }

                    // Step Instructions
                    VStack(spacing: 8) {
                        Text(currentStep == .createPin ? "Set Up 6-Digit PIN" : "Confirm Your PIN")
                            .font(LeafTypography.titleLarge)
                            .foregroundStyle(LeafTheme.textPrimary(for: colorScheme))

                        Text(currentStep == .createPin
                             ? "Choose a 6-digit security PIN to protect your financial records."
                             : "Re-enter your 6-digit PIN to confirm.")
                            .font(LeafTypography.bodyMedium)
                            .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }

                    // 6-Dot PIN Indicator
                    PinDotsIndicator(
                        pinLength: SecurePinManager.pinLength,
                        filledCount: currentStep == .createPin ? firstPin.count : confirmPin.count,
                        isError: isError
                    )

                    // Error Message
                    Group {
                        if let error = errorMessage {
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
                    .padding(.bottom, 24)
                }
            }
            .navigationTitle("App Lock Setup")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Enable Biometric Unlock?", isPresented: $showBiometricsPrompt) {
                Button("Enable \(container.appLockService.availableBiometricType.rawValue)") {
                    finishSetup(enableBiometrics: true)
                }
                Button("PIN Only", role: .cancel) {
                    finishSetup(enableBiometrics: false)
                }
            } message: {
                Text("Would you like to unlock Leaf with \(container.appLockService.availableBiometricType.rawValue) in addition to your PIN?")
            }
        }
    }

    private func handleDigit(_ digit: String) {
        errorMessage = nil
        isError = false

        switch currentStep {
        case .createPin:
            guard firstPin.count < SecurePinManager.pinLength else { return }
            firstPin.append(digit)
            if firstPin.count == SecurePinManager.pinLength {
                triggerStepAdvanceHaptic()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    currentStep = .confirmPin
                }
            }

        case .confirmPin:
            guard confirmPin.count < SecurePinManager.pinLength else { return }
            confirmPin.append(digit)
            if confirmPin.count == SecurePinManager.pinLength {
                verifyConfirmation()
            }
        }
    }

    private func handleDelete() {
        errorMessage = nil
        isError = false

        switch currentStep {
        case .createPin:
            if !firstPin.isEmpty {
                firstPin.removeLast()
            }
        case .confirmPin:
            if !confirmPin.isEmpty {
                confirmPin.removeLast()
            } else {
                // If backspace on empty confirm, go back to createPin
                firstPin = ""
                currentStep = .createPin
            }
        }
    }

    private func verifyConfirmation() {
        if firstPin == confirmPin {
            triggerSuccessHaptic()
            if container.appLockService.availableBiometricType != .none {
                showBiometricsPrompt = true
            } else {
                finishSetup(enableBiometrics: false)
            }
        } else {
            triggerErrorHaptic()
            isError = true
            errorMessage = "PINs do not match. Please try again."
            // Reset to step 1 for a clean retry flow
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                firstPin = ""
                confirmPin = ""
                currentStep = .createPin
                isError = false
            }
        }
    }

    private func finishSetup(enableBiometrics: Bool) {
        let success = container.appLockService.enableAppLock(pin: firstPin, enableBiometrics: enableBiometrics)
        if success {
            triggerSuccessHaptic()
            onSetupCompleted()
            dismiss()
        } else {
            errorMessage = "Failed to save PIN in secure Keychain."
            isError = true
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
