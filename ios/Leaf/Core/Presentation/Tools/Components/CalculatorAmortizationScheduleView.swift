import SwiftUI

/// Month-by-month loan amortisation table showing principal, interest, and remaining balance.
public struct CalculatorAmortizationScheduleView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss

    public let schedule: [EmiAmortizationMonth]
    public let currency: Currency

    public init(schedule: [EmiAmortizationMonth], currency: Currency) {
        self.schedule = schedule
        self.currency = currency
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                LeafTheme.canvas(for: colorScheme).ignoresSafeArea()

                VStack(spacing: 0) {
                    // Header Bar
                    HStack {
                        Text("Month")
                            .frame(width: 50, alignment: .leading)
                        Text("Principal")
                            .frame(maxWidth: .infinity, alignment: .trailing)
                        Text("Interest")
                            .frame(maxWidth: .infinity, alignment: .trailing)
                        Text("Balance")
                            .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                    .font(LeafTypography.captionBold)
                    .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(LeafTheme.cardElevated(for: colorScheme))

                    Divider()

                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(schedule) { item in
                                HStack {
                                    Text("\(item.month)")
                                        .font(LeafTypography.captionBold)
                                        .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
                                        .frame(width: 50, alignment: .leading)

                                    Text(Amount(subunits: Int64(round(item.principalPayment * Double(currency.subunitFactor)))).formatted(with: currency))
                                        .font(Font.system(size: 13, weight: .medium, design: .rounded))
                                        .foregroundStyle(LeafTheme.brandEmerald)
                                        .frame(maxWidth: .infinity, alignment: .trailing)

                                    Text(Amount(subunits: Int64(round(item.interestPayment * Double(currency.subunitFactor)))).formatted(with: currency))
                                        .font(Font.system(size: 13, weight: .medium, design: .rounded))
                                        .foregroundStyle(LeafTheme.expenseCoral)
                                        .frame(maxWidth: .infinity, alignment: .trailing)

                                    Text(Amount(subunits: Int64(round(item.remainingBalance * Double(currency.subunitFactor)))).formatted(with: currency))
                                        .font(Font.system(size: 13, weight: .regular, design: .rounded))
                                        .foregroundStyle(LeafTheme.textPrimary(for: colorScheme))
                                        .frame(maxWidth: .infinity, alignment: .trailing)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(item.month % 2 == 0 ? LeafTheme.card(for: colorScheme) : Color.clear)

                                Divider()
                            }
                        }
                    }
                }
            }
            .navigationTitle("Amortisation Schedule")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(LeafTypography.bodyBold)
                    .foregroundStyle(LeafTheme.accent(for: colorScheme))
                }
            }
        }
    }
}

