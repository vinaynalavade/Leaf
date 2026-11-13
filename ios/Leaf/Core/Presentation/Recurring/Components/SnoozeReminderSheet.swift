import SwiftUI

/// Action sheet to snooze an upcoming bill reminder by a chosen duration.
public struct SnoozeReminderSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    public let occurrenceTitle: String
    public let onSnooze: (Int) -> Void

    public init(
        occurrenceTitle: String,
        onSnooze: @escaping (Int) -> Void
    ) {
        self.occurrenceTitle = occurrenceTitle
        self.onSnooze = onSnooze
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                LeafTheme.canvas(for: colorScheme).ignoresSafeArea()

                VStack(spacing: 20) {
                    VStack(spacing: 6) {
                        Image(systemName: "bell.badge.fill")
                            .font(.system(size: 36))
                            .foregroundStyle(LeafTheme.brandEmerald)
                            .padding(.top, 10)

                        Text("Snooze Reminder")
                            .font(LeafTypography.titleMedium)
                            .foregroundStyle(LeafTheme.textPrimary(for: colorScheme))

                        Text("Remind me later about \(occurrenceTitle)")
                            .font(LeafTypography.caption)
                            .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
                    }

                    VStack(spacing: 10) {
                        snoozeButton(title: "1 Day (Tomorrow)", days: 1)
                        snoozeButton(title: "2 Days", days: 2)
                        snoozeButton(title: "3 Days", days: 3)
                        snoozeButton(title: "1 Week", days: 7)
                    }
                    .padding(.horizontal, 20)

                    Spacer()
                }
                .padding(.top, 20)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(LeafTheme.accent(for: colorScheme))
                }
            }
        }
        .presentationDetents([.height(340)])
        .presentationDragIndicator(.visible)
    }

    @ViewBuilder
    private func snoozeButton(title: String, days: Int) -> some View {
        Button {
            onSnooze(days)
            dismiss()
        } label: {
            HStack {
                Text(title)
                    .font(LeafTypography.bodyMedium)
                    .foregroundStyle(LeafTheme.textPrimary(for: colorScheme))

                Spacer()

                Image(systemName: "clock.arrow.circlepath")
                    .font(.system(size: 14))
                    .foregroundStyle(LeafTheme.brandEmerald)
            }
            .padding(14)
            .background(LeafTheme.card(for: colorScheme))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(LeafTheme.border(for: colorScheme), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

