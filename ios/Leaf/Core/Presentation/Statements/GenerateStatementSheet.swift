import SwiftUI

/// Modal sheet allowing the user to configure and generate a new financial statement or export.
public struct GenerateStatementSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @Bindable var viewModel: StatementsViewModel

    public init(viewModel: StatementsViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                LeafTheme.canvas(for: colorScheme).ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // 1. Period Selection Section
                        periodSection

                        // 2. Custom Date Range Pickers (if custom selected)
                        if viewModel.selectedPeriod.isCustom {
                            customDateSection
                        }

                        // 3. Format Selection Section
                        formatSection

                        // 4. Custom Title Section (Optional)
                        titleSection

                        // 5. Action Button
                        generateButton
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 20)
                }
            }
            .navigationTitle("Generate Statement")
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
    }

    // MARK: - Sections

    @ViewBuilder
    private var periodSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("STATEMENT PERIOD")
                .font(LeafTypography.captionBold)
                .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
                .padding(.horizontal, 4)

            VStack(spacing: 8) {
                ForEach([
                    StatementPeriod.thisMonth,
                    StatementPeriod.lastMonth,
                    StatementPeriod.previous3Months,
                    StatementPeriod.previous6Months,
                    StatementPeriod.thisYear,
                    StatementPeriod.previousYear,
                    StatementPeriod.allTime,
                    StatementPeriod.custom
                ], id: \.self) { period in
                    Button {
                        viewModel.selectedPeriod = period
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(period.displayName)
                                    .font(LeafTypography.bodyBold)
                                    .foregroundStyle(LeafTheme.textPrimary(for: colorScheme))

                                if !period.isCustom {
                                    Text(period.formattedRange())
                                        .font(LeafTypography.caption)
                                        .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
                                }
                            }

                            Spacer()

                            if viewModel.selectedPeriod == period {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 20))
                                    .foregroundStyle(LeafTheme.brandEmerald)
                            } else {
                                Image(systemName: "circle")
                                    .font(.system(size: 20))
                                    .foregroundStyle(LeafTheme.border(for: colorScheme))
                            }
                        }
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(viewModel.selectedPeriod == period ? LeafTheme.brandEmerald.opacity(0.08) : LeafTheme.card(for: colorScheme))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(viewModel.selectedPeriod == period ? LeafTheme.brandEmerald : LeafTheme.border(for: colorScheme), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    @ViewBuilder
    private var customDateSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("CUSTOM DATE RANGE")
                .font(LeafTypography.captionBold)
                .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
                .padding(.horizontal, 4)

            VStack(spacing: 12) {
                DatePicker(
                    "Start Date",
                    selection: $viewModel.customStartDate,
                    displayedComponents: .date
                )
                .font(LeafTypography.bodyMedium)

                Divider()

                DatePicker(
                    "End Date",
                    selection: $viewModel.customEndDate,
                    in: viewModel.customStartDate...,
                    displayedComponents: .date
                )
                .font(LeafTypography.bodyMedium)
            }
            .padding(14)
            .background(LeafTheme.card(for: colorScheme))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(LeafTheme.border(for: colorScheme), lineWidth: 1)
            )
        }
    }

    @ViewBuilder
    private var formatSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("EXPORT FORMAT")
                .font(LeafTypography.captionBold)
                .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
                .padding(.horizontal, 4)

            VStack(spacing: 8) {
                ForEach([
                    StatementFormat.pdf,
                    StatementFormat.csvTransactions,
                    StatementFormat.csvCategorySummary,
                    StatementFormat.csvFinancialSummary
                ], id: \.self) { format in
                    Button {
                        viewModel.selectedFormat = format
                    } label: {
                        HStack(spacing: 12) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(format == .pdf ? LeafTheme.expenseCoral.opacity(0.12) : LeafTheme.infoBlue.opacity(0.12))
                                    .frame(width: 38, height: 38)

                                Image(systemName: format.systemIcon)
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundStyle(format == .pdf ? LeafTheme.expenseCoral : LeafTheme.infoBlue)
                            }

                            VStack(alignment: .leading, spacing: 2) {
                                Text(format.displayName)
                                    .font(LeafTypography.bodyBold)
                                    .foregroundStyle(LeafTheme.textPrimary(for: colorScheme))

                                Text(formatDescription(for: format))
                                    .font(LeafTypography.caption)
                                    .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
                            }

                            Spacer()

                            if viewModel.selectedFormat == format {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 20))
                                    .foregroundStyle(LeafTheme.brandEmerald)
                            } else {
                                Image(systemName: "circle")
                                    .font(.system(size: 20))
                                    .foregroundStyle(LeafTheme.border(for: colorScheme))
                            }
                        }
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(viewModel.selectedFormat == format ? LeafTheme.brandEmerald.opacity(0.08) : LeafTheme.card(for: colorScheme))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(viewModel.selectedFormat == format ? LeafTheme.brandEmerald : LeafTheme.border(for: colorScheme), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    @ViewBuilder
    private var titleSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("CUSTOM TITLE (OPTIONAL)")
                .font(LeafTypography.captionBold)
                .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
                .padding(.horizontal, 4)

            TextField(
                viewModel.selectedPeriod.defaultTitle(),
                text: $viewModel.customTitle
            )
            .font(LeafTypography.bodyMedium)
            .padding(12)
            .background(LeafTheme.card(for: colorScheme))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(LeafTheme.border(for: colorScheme), lineWidth: 1)
            )
        }
    }

    @ViewBuilder
    private var generateButton: some View {
        VStack(spacing: 8) {
            Button {
                Task {
                    await viewModel.generateFromSheet()
                }
            } label: {
                HStack(spacing: 8) {
                    if viewModel.isGenerating {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Image(systemName: "arrow.down.doc.fill")
                            .font(.system(size: 16, weight: .bold))
                    }

                    Text(viewModel.isGenerating ? "Compiling Statement..." : "Generate Statement")
                        .font(LeafTypography.bodyBold)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(LeafTheme.heroGradient(for: colorScheme))
                .foregroundStyle(.white)
                .cornerRadius(12)
                .shadow(color: LeafTheme.brandEmerald.opacity(0.3), radius: 8, x: 0, y: 4)
            }
            .disabled(viewModel.isGenerating)

            if let error = viewModel.errorMessage {
                Text(error)
                    .font(LeafTypography.caption)
                    .foregroundStyle(LeafTheme.expenseCoral)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.top, 10)
    }

    private func formatDescription(for format: StatementFormat) -> String {
        switch format {
        case .pdf:
            return "Professional multi-page document with summary and ledger"
        case .csvTransactions:
            return "Itemized raw ledger with dates, descriptions, categories & amounts"
        case .csvCategorySummary:
            return "Summarized spend, share percentages, and transaction counts"
        case .csvFinancialSummary:
            return "Executive KPI summary with cash flow and balance movement"
        }
    }
}

