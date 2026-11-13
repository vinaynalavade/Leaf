import SwiftUI

/// Reusable 6-digit PIN indicator dots.
public struct PinDotsIndicator: View {
    public let pinLength: Int
    public let filledCount: Int
    public let isError: Bool

    public init(
        pinLength: Int = 6,
        filledCount: Int,
        isError: Bool = false
    ) {
        self.pinLength = pinLength
        self.filledCount = filledCount
        self.isError = isError
    }

    public var body: some View {
        HStack(spacing: 16) {
            ForEach(0..<pinLength, id: \.self) { index in
                Circle()
                    .fill(
                        isError
                            ? LeafTheme.expenseCoral
                            : (index < filledCount ? LeafTheme.brandEmerald : Color.clear)
                    )
                    .frame(width: 14, height: 14)
                    .overlay(
                        Circle()
                            .stroke(
                                isError
                                    ? LeafTheme.expenseCoral
                                    : (index < filledCount ? LeafTheme.brandEmerald : Color.secondary.opacity(0.4)),
                                lineWidth: 2
                            )
                    )
                    .animation(.easeInOut(duration: 0.15), value: filledCount)
                    .animation(.easeInOut(duration: 0.15), value: isError)
            }
        }
        .padding(.vertical, 8)
    }
}

/// Native numeric keypad (0-9, backspace, and optional biometric trigger).
public struct PinNumericKeypad: View {
    @Environment(\.colorScheme) private var colorScheme

    public let onDigit: (String) -> Void
    public let onDelete: () -> Void
    public let biometricIcon: String?
    public let onBiometric: (() -> Void)?

    public init(
        biometricIcon: String? = nil,
        onBiometric: (() -> Void)? = nil,
        onDigit: @escaping (String) -> Void,
        onDelete: @escaping () -> Void
    ) {
        self.biometricIcon = biometricIcon
        self.onBiometric = onBiometric
        self.onDigit = onDigit
        self.onDelete = onDelete
    }

    private let keypadRows: [[KeypadKey]] = [
        [.digit("1"), .digit("2"), .digit("3")],
        [.digit("4"), .digit("5"), .digit("6")],
        [.digit("7"), .digit("8"), .digit("9")],
        [.biometric, .digit("0"), .delete]
    ]

    private enum KeypadKey {
        case digit(String)
        case biometric
        case delete
    }

    public var body: some View {
        VStack(spacing: 16) {
            ForEach(0..<keypadRows.count, id: \.self) { rowIndex in
                HStack(spacing: 28) {
                    ForEach(0..<keypadRows[rowIndex].count, id: \.self) { colIndex in
                        let key = keypadRows[rowIndex][colIndex]
                        keyButton(for: key)
                    }
                }
            }
        }
        .padding(.horizontal, 24)
    }

    @ViewBuilder
    private func keyButton(for key: KeypadKey) -> some View {
        switch key {
        case .digit(let digit):
            Button {
                triggerKeyHaptic()
                onDigit(digit)
            } label: {
                Text(digit)
                    .font(.system(size: 28, weight: .regular, design: .rounded))
                    .foregroundStyle(LeafTheme.textPrimary(for: colorScheme))
                    .frame(width: 72, height: 72)
                    .background(
                        Circle()
                            .fill(colorScheme == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.05))
                    )
            }
            .buttonStyle(.plain)

        case .biometric:
            if let icon = biometricIcon, let onBiometric = onBiometric {
                Button {
                    triggerKeyHaptic()
                    onBiometric()
                } label: {
                    Image(systemName: icon)
                        .font(.system(size: 24, weight: .medium))
                        .foregroundStyle(LeafTheme.brandEmerald)
                        .frame(width: 72, height: 72)
                        .background(
                            Circle()
                                .fill(LeafTheme.brandEmerald.opacity(0.12))
                        )
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Authenticate with biometrics")
            } else {
                Spacer()
                    .frame(width: 72, height: 72)
            }

        case .delete:
            Button {
                triggerKeyHaptic()
                onDelete()
            } label: {
                Image(systemName: "delete.backward.fill")
                    .font(.system(size: 22, weight: .regular))
                    .foregroundStyle(LeafTheme.textPrimary(for: colorScheme))
                    .frame(width: 72, height: 72)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Delete digit")
        }
    }

    private func triggerKeyHaptic() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
}
