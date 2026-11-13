import SwiftUI

/// Clean sheet allowing the user to select an arbitrary custom date range for insights.
public struct CustomDateRangeSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    @State private var startDate: Date
    @State private var endDate: Date
    public let onApply: (Date, Date) -> Void

    public init(
        initialStartDate: Date = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date(),
        initialEndDate: Date = Date(),
        onApply: @escaping (Date, Date) -> Void
    ) {
        self._startDate = State(initialValue: initialStartDate)
        self._endDate = State(initialValue: initialEndDate)
        self.onApply = onApply
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                LeafTheme.canvas(for: colorScheme).ignoresSafeArea()

                VStack(spacing: 24) {
                    SquircleCard {
                        VStack(spacing: 16) {
                            DatePicker(
                                "Start Date",
                                selection: $startDate,
                                in: ...endDate,
                                displayedComponents: [.date]
                            )
                            .font(LeafTypography.bodyMedium)
                            .tint(LeafTheme.brandEmerald)

                            Divider()
                                .overlay(LeafTheme.cardBorder(for: colorScheme))

                            DatePicker(
                                "End Date",
                                selection: $endDate,
                                in: startDate...Date(),
                                displayedComponents: [.date]
                            )
                            .font(LeafTypography.bodyMedium)
                            .tint(LeafTheme.brandEmerald)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 16)

                    Spacer()

                    Button(action: {
                        onApply(startDate, endDate)
                    }) {
                        Text("Apply Date Range")
                            .font(LeafTypography.titleMedium)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(LeafTheme.brandEmerald)
                            )
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 24)
                }
            }
            .navigationTitle("Custom Date Range")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
                }
            }
        }
        .presentationDetents([.height(340)])
    }
}

