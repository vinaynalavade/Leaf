import SwiftUI

/// Luxury hero result display card for financial calculations.
public struct CalculatorResultHeroCard: View {
    @Environment(\.colorScheme) private var colorScheme

    public let title: String
    public let formattedAmount: String
    public let subtitle: String
    public var accentGradient: LinearGradient?
    public var secondaryPills: [(label: String, value: String)] = []

    public init(
        title: String,
        formattedAmount: String,
        subtitle: String,
        accentGradient: LinearGradient? = nil,
        secondaryPills: [(label: String, value: String)] = []
    ) {
        self.title = title
        self.formattedAmount = formattedAmount
        self.subtitle = subtitle
        self.accentGradient = accentGradient
        self.secondaryPills = secondaryPills
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title.uppercased())
                    .font(Font.system(size: 11, weight: .bold))
                    .foregroundStyle(Color.white.opacity(0.85))

                Text(formattedAmount)
                    .font(Font.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.white)
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)

                Text(subtitle)
                    .font(LeafTypography.caption)
                    .foregroundStyle(Color.white.opacity(0.85))
            }

            if !secondaryPills.isEmpty {
                Divider()
                    .overlay(Color.white.opacity(0.2))

                HStack(spacing: 12) {
                    ForEach(0..<secondaryPills.count, id: \.self) { idx in
                        let pill = secondaryPills[idx]
                        VStack(alignment: .leading, spacing: 2) {
                            Text(pill.label)
                                .font(Font.system(size: 10, weight: .medium))
                                .foregroundStyle(Color.white.opacity(0.75))

                            Text(pill.value)
                                .font(Font.system(size: 13, weight: .bold, design: .rounded))
                                .foregroundStyle(Color.white)
                        }

                        if idx < secondaryPills.count - 1 {
                            Spacer()
                        }
                    }
                }
            }
        }
        .padding(18)
        .background(accentGradient ?? LeafTheme.heroGradient(for: colorScheme))
        .cornerRadius(16)
        .shadow(color: LeafTheme.brandEmerald.opacity(0.25), radius: 10, x: 0, y: 4)
    }
}

