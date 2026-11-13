import SwiftUI

/// Reusable disclosure card presenting financial calculation assumptions, compounding rules,
/// and regulatory/statutory disclaimers to ensure full transparency and avoid misleading claims.
public struct CalculatorAssumptionDisclosureCard: View {
    @Environment(\.colorScheme) private var colorScheme

    public let title: String
    public let assumptions: [String]
    public let disclaimer: String?

    public init(
        title: String = "Calculation Assumptions & Methodology",
        assumptions: [String],
        disclaimer: String? = nil
    ) {
        self.title = title
        self.assumptions = assumptions
        self.disclaimer = disclaimer
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "info.circle.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(LeafTheme.brandEmerald)

                Text(title.uppercased())
                    .font(LeafTypography.captionBold)
                    .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
            }

            VStack(alignment: .leading, spacing: 8) {
                ForEach(assumptions, id: \.self) { item in
                    HStack(alignment: .top, spacing: 8) {
                        Text("•")
                            .font(LeafTypography.bodySmallBold)
                            .foregroundStyle(LeafTheme.brandEmerald)

                        Text(item)
                            .font(LeafTypography.caption)
                            .foregroundStyle(LeafTheme.textPrimary(for: colorScheme))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }

            if let disclaimer = disclaimer {
                Divider()
                    .padding(.vertical, 2)

                HStack(alignment: .top, spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 11))
                        .foregroundStyle(LeafTheme.warningGold)
                        .padding(.top, 1)

                    Text(disclaimer)
                        .font(LeafTypography.caption)
                        .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(LeafTheme.card(for: colorScheme))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(LeafTheme.border(for: colorScheme), lineWidth: 1)
        )
    }
}

