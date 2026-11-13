import SwiftUI

/// Detailed category analytics drill-down view showing category spend metrics,
/// daily average, and full transaction history within the selected period.
public struct CategoryDetailAnalyticsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @Environment(AppContainer.self) private var container

    public let item: CategoryAnalysisItem
    public let period: InsightsPeriod
    public let currency: Currency

    @State private var transactions: [Transaction] = []
    @State private var isLoading: Bool = true
    @State private var errorMessage: String? = nil

    public init(
        item: CategoryAnalysisItem,
        period: InsightsPeriod,
        currency: Currency
    ) {
        self.item = item
        self.period = period
        self.currency = currency
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                LeafTheme.canvas(for: colorScheme).ignoresSafeArea()

                if isLoading {
                    ProgressView()
                        .tint(LeafTheme.accent(for: colorScheme))
                } else {
                    ScrollView {
                        VStack(spacing: 20) {
                            // Category Hero Header Card
                            categoryHeroCard

                            // Transaction History Feed for this Category
                            transactionsSection
                        }
                        .padding(.vertical, 16)
                    }
                }
            }
            .navigationTitle(item.category.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(LeafTypography.bodyMedium)
                    .foregroundStyle(LeafTheme.accent(for: colorScheme))
                }
            }
            .task {
                await loadCategoryTransactions()
            }
        }
    }

    @ViewBuilder
    private var categoryHeroCard: some View {
        SquircleCard {
            VStack(spacing: 16) {
                HStack(spacing: 14) {
                    CategoryIconBadge(
                        iconName: item.category.iconName,
                        colorHex: item.category.colorHex,
                        size: 52
                    )

                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.category.name)
                            .font(LeafTypography.titleMedium)
                            .foregroundStyle(LeafTheme.textPrimary(for: colorScheme))

                        Text(period.formattedRange())
                            .font(LeafTypography.caption)
                            .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 2) {
                        Text(item.amount.formatted(with: currency))
                            .font(LeafTypography.balanceHero)
                            .foregroundStyle(LeafTheme.expenseCoral)

                        Text("\(String(format: "%.1f%%", item.percentageOfTotal)) of total spend")
                            .font(LeafTypography.caption)
                            .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
                    }
                }

                Divider()
                    .overlay(LeafTheme.cardBorder(for: colorScheme))

                // Sub-metrics
                HStack(spacing: 16) {
                    subMetric(
                        label: "TRANSACTIONS",
                        value: "\(item.transactionCount)"
                    )

                    let avgSubunits = item.transactionCount > 0 ? item.amount.subunits / Int64(item.transactionCount) : 0
                    subMetric(
                        label: "AVERAGE / TX",
                        value: Amount(avgSubunits).formatted(with: currency)
                    )

                    if let change = item.changePercentageVsPrevious {
                        let isIncrease = change > 0
                        subMetric(
                            label: "VS PREV PERIOD",
                            value: String(format: "%@%.0f%%", isIncrease ? "+" : "", change),
                            color: isIncrease ? LeafTheme.expenseCoral : LeafTheme.brandEmerald
                        )
                    }
                }
            }
            .padding(16)
        }
        .padding(.horizontal, 16)
    }

    @ViewBuilder
    private func subMetric(label: String, value: String, color: Color? = nil) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(label)
                .font(.system(size: 9, weight: .bold, design: .rounded))
                .tracking(0.6)
                .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))

            Text(value)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(color ?? LeafTheme.textPrimary(for: colorScheme))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private var transactionsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("TRANSACTION ACTIVITY")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .tracking(1.0)
                    .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))

                Spacer()

                Text("\(transactions.count) records")
                    .font(LeafTypography.caption)
                    .foregroundStyle(LeafTheme.textTertiary(for: colorScheme))
            }
            .padding(.horizontal, 16)

            if transactions.isEmpty {
                SquircleCard {
                    Text("No transactions found for this period")
                        .font(LeafTypography.subheadline)
                        .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(24)
                }
                .padding(.horizontal, 16)
            } else {
                VStack(spacing: 8) {
                    ForEach(transactions) { tx in
                        transactionRow(tx)
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }

    @ViewBuilder
    private func transactionRow(_ tx: Transaction) -> some View {
        SquircleCard {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(tx.note?.isEmpty == false ? tx.note! : item.category.name)
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(LeafTheme.textPrimary(for: colorScheme))
                        .lineLimit(1)

                    HStack(spacing: 6) {
                        Text(formatDate(tx.timestamp))
                            .font(LeafTypography.caption)
                            .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))

                        Text("• \(tx.paymentMethod.displayName)")
                                .font(LeafTypography.caption)
                                .foregroundStyle(LeafTheme.textTertiary(for: colorScheme))
                    }
                }

                Spacer()

                Text("-\(tx.amount.formatted(with: currency))")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(LeafTheme.expenseCoral)
            }
            .padding(12)
        }
    }

    private func formatDate(_ timestamp: Int64) -> String {
        let date = Date(timeIntervalSince1970: Double(timestamp) / 1000.0)
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, h:mm a"
        return formatter.string(from: date)
    }

    private func loadCategoryTransactions() async {
        isLoading = true
        let interval = period.dateInterval()
        let startEpoch = Int64(interval.start.timeIntervalSince1970 * 1000)
        let endEpoch = Int64(interval.end.timeIntervalSince1970 * 1000)

        do {
            let all = try await container.transactionRepository.getTransactionsBetween(
                startEpoch: startEpoch,
                endEpoch: endEpoch
            )
            // Filter strictly to this category, ordinary expenses, not internal transfers
            let filtered = all.filter {
                $0.category?.id == item.category.id &&
                $0.type == .expense &&
                !$0.isInternalTransfer
            }
            .sorted(by: { $0.timestamp > $1.timestamp })

            await MainActor.run {
                self.transactions = filtered
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }
}

