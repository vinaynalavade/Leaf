import SwiftUI

/// Main native iOS view for the Leaf Financial Statements, PDF Generation & Export module.
/// Provides one-tap presets, custom date/format statement generation, in-app PDF previewing,
/// native iOS file sharing via ShareLink, and SQLite-backed export history.
public struct StatementsView: View {
    @Environment(AppContainer.self) private var container
    @Environment(\.colorScheme) private var colorScheme
    @State private var viewModel: StatementsViewModel?

    public init() {}

    public var body: some View {
        ZStack {
            LeafTheme.canvas(for: colorScheme).ignoresSafeArea()

            if let vm = viewModel {
                ScrollView {
                    VStack(spacing: 22) {
                        // 1. Hero Action Card
                        heroCard(vm)

                        // 2. Quick 1-Tap Presets
                        quickPresetsSection(vm)

                        // 3. Statement Archive / History
                        statementsArchiveSection(vm)

                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                }
                .refreshable {
                    await vm.loadStatements()
                }
                .sheet(isPresented: Binding(
                    get: { vm.isGenerateSheetPresented },
                    set: { vm.isGenerateSheetPresented = $0 }
                )) {
                    GenerateStatementSheet(viewModel: vm)
                }
                .sheet(item: Binding(
                    get: { vm.previewStatement },
                    set: { vm.previewStatement = $0 }
                )) { statement in
                    PdfViewerSheet(statement: statement)
                }
                .sheet(item: Binding(
                    get: { vm.exportItem },
                    set: { vm.exportItem = $0 }
                )) { item in
                    DocumentPickerExportView(url: item.url) { _ in
                        vm.exportItem = nil
                    }
                }
                .confirmationDialog(
                    "Delete Statement?",
                    isPresented: Binding(
                        get: { vm.isDeleteConfirmationPresented },
                        set: { vm.isDeleteConfirmationPresented = $0 }
                    ),
                    titleVisibility: .visible
                ) {
                    Button("Delete Statement", role: .destructive) {
                        Task { await vm.deleteConfirmed() }
                    }
                    Button("Cancel", role: .cancel) {}
                } message: {
                    Text("This will permanently remove the generated statement file and metadata from your device.")
                }
            } else {
                ProgressView()
                    .tint(LeafTheme.accent(for: colorScheme))
            }
        }
        .navigationTitle("Statements & Export")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            if viewModel == nil {
                let vm = StatementsViewModel(
                    getStatementsUseCase: container.getStatementsUseCase,
                    generateStatementUseCase: container.generateStatementUseCase,
                    deleteStatementUseCase: container.deleteStatementUseCase
                )
                self.viewModel = vm
                await vm.loadStatements()
            }
        }
    }

    // MARK: - Hero Card

    @ViewBuilder
    private func heroCard(_ vm: StatementsViewModel) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.18))
                        .frame(width: 44, height: 44)

                    Image(systemName: "doc.text.fill")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Financial Statements")
                        .font(LeafTypography.titleMedium)
                        .foregroundStyle(.white)

                    Text("Official PDF reports & CSV ledgers")
                        .font(LeafTypography.caption)
                        .foregroundStyle(Color.white.opacity(0.85))
                }

                Spacer()
            }

            Text("Generate bank-grade statements reflecting operating cash flows, checking account balance movements, and segregated savings allocations.")
                .font(LeafTypography.caption)
                .foregroundStyle(Color.white.opacity(0.85))
                .fixedSize(horizontal: false, vertical: true)

            Button {
                vm.isGenerateSheetPresented = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 16, weight: .semibold))

                    Text("Generate New Statement")
                        .font(LeafTypography.bodyBold)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(colorScheme == .dark ? LeafTheme.brandEmerald : Color.white)
                .foregroundStyle(colorScheme == .dark ? Color.white : LeafTheme.accentLight)
                .cornerRadius(10)
            }
        }
        .padding(18)
        .background(LeafTheme.heroGradient(for: colorScheme))
        .cornerRadius(16)
        .shadow(color: LeafTheme.brandEmerald.opacity(0.2), radius: 10, x: 0, y: 4)
    }

    // MARK: - Quick Presets

    @ViewBuilder
    private func quickPresetsSection(_ vm: StatementsViewModel) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("QUICK EXPORT PRESETS")
                .font(LeafTypography.captionBold)
                .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
                .padding(.horizontal, 4)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    presetButton(
                        title: "This Month",
                        subtitle: "PDF Statement",
                        icon: "doc.fill",
                        iconColor: LeafTheme.expenseCoral,
                        isLoading: vm.isGenerating && vm.selectedPeriod == .thisMonth && vm.selectedFormat == .pdf
                    ) {
                        Task { await vm.quickGenerate(period: .thisMonth, format: .pdf) }
                    }

                    presetButton(
                        title: "Last Month",
                        subtitle: "PDF Statement",
                        icon: "doc.fill",
                        iconColor: LeafTheme.expenseCoral,
                        isLoading: vm.isGenerating && vm.selectedPeriod == .lastMonth && vm.selectedFormat == .pdf
                    ) {
                        Task { await vm.quickGenerate(period: .lastMonth, format: .pdf) }
                    }

                    presetButton(
                        title: "This Year",
                        subtitle: "Full Year PDF",
                        icon: "doc.fill",
                        iconColor: LeafTheme.expenseCoral,
                        isLoading: vm.isGenerating && vm.selectedPeriod == .thisYear && vm.selectedFormat == .pdf
                    ) {
                        Task { await vm.quickGenerate(period: .thisYear, format: .pdf) }
                    }

                    presetButton(
                        title: "All Activity",
                        subtitle: "CSV Ledger",
                        icon: "tablecells.fill",
                        iconColor: LeafTheme.infoBlue,
                        isLoading: vm.isGenerating && vm.selectedPeriod == .allTime && vm.selectedFormat == .csvTransactions
                    ) {
                        Task { await vm.quickGenerate(period: .allTime, format: .csvTransactions) }
                    }
                }
                .padding(.horizontal, 2)
            }
        }
    }

    @ViewBuilder
    private func presetButton(
        title: String,
        subtitle: String,
        icon: String,
        iconColor: Color,
        isLoading: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(iconColor.opacity(0.12))
                        .frame(width: 34, height: 34)

                    if isLoading {
                        ProgressView()
                            .scaleEffect(0.7)
                    } else {
                        Image(systemName: icon)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(iconColor)
                    }
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(LeafTypography.bodyBold)
                        .foregroundStyle(LeafTheme.textPrimary(for: colorScheme))

                    Text(subtitle)
                        .font(LeafTypography.caption)
                        .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(LeafTheme.card(for: colorScheme))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(LeafTheme.border(for: colorScheme), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Statements Archive

    @ViewBuilder
    private func statementsArchiveSection(_ vm: StatementsViewModel) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("STATEMENT ARCHIVE (\(vm.statements.count))")
                    .font(LeafTypography.captionBold)
                    .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))

                Spacer()

                if vm.isLoading {
                    ProgressView()
                        .scaleEffect(0.7)
                        .tint(LeafTheme.accent(for: colorScheme))
                }
            }
            .padding(.horizontal, 4)

            if vm.statements.isEmpty && !vm.isLoading {
                emptyArchiveView(vm)
            } else {
                LazyVStack(spacing: 10) {
                    ForEach(vm.statements) { statement in
                        statementRow(statement, vm: vm)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func emptyArchiveView(_ vm: StatementsViewModel) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "folder.badge.gearshape")
                .font(.system(size: 42))
                .foregroundStyle(LeafTheme.textSecondary(for: colorScheme).opacity(0.5))

            Text("No Statements Generated")
                .font(LeafTypography.titleSmall)
                .foregroundStyle(LeafTheme.textPrimary(for: colorScheme))

            Text("Select a period or preset above to compile your first financial report.")
                .font(LeafTypography.caption)
                .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 36)
        .background(LeafTheme.card(for: colorScheme))
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(LeafTheme.border(for: colorScheme), lineWidth: 1)
        )
    }

    @ViewBuilder
    private func statementRow(_ statement: SavedStatement, vm: StatementsViewModel) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 12) {
                // Format Icon Badge
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(statement.format == .pdf ? LeafTheme.expenseCoral.opacity(0.12) : LeafTheme.infoBlue.opacity(0.12))
                        .frame(width: 40, height: 40)

                    Image(systemName: statement.format.systemIcon)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(statement.format == .pdf ? LeafTheme.expenseCoral : LeafTheme.infoBlue)
                }

                // Details
                VStack(alignment: .leading, spacing: 3) {
                    Text(statement.title)
                        .font(LeafTypography.bodyBold)
                        .foregroundStyle(LeafTheme.textPrimary(for: colorScheme))

                    Text("\(statement.formattedPeriod)  •  \(statement.formattedFileSize)")
                        .font(LeafTypography.caption)
                        .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))

                    Text("Generated \(statement.formattedGeneratedDate)")
                        .font(Font.system(size: 11, weight: .regular))
                        .foregroundStyle(LeafTheme.textSecondary(for: colorScheme).opacity(0.8))
                }

                Spacer()

                // Actions Menu
                HStack(spacing: 6) {
                    if statement.format == .pdf && statement.fileExists {
                        Button {
                            vm.previewStatement = statement
                        } label: {
                            Image(systemName: "eye.fill")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(LeafTheme.brandEmerald)
                                .padding(7)
                                .background(LeafTheme.brandEmerald.opacity(0.1))
                                .clipShape(Circle())
                        }
                    }

                    if statement.fileExists {
                        // Native File Export to Files app
                        Button {
                            vm.exportToFiles(statement)
                        } label: {
                            Image(systemName: "folder.badge.plus")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(LeafTheme.infoBlue)
                                .padding(7)
                                .background(LeafTheme.infoBlue.opacity(0.1))
                                .clipShape(Circle())
                        }

                        // Native Share sheet
                        ShareLink(
                            item: statement.fileURL,
                            preview: SharePreview(statement.title, image: Image(systemName: statement.format.systemIcon))
                        ) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(LeafTheme.accent(for: colorScheme))
                                .padding(7)
                                .background(LeafTheme.accent(for: colorScheme).opacity(0.1))
                                .clipShape(Circle())
                        }
                    }

                    // Regenerate statement for the same period
                    Button {
                        Task { await vm.regenerateStatement(statement) }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(LeafTheme.accent(for: colorScheme))
                            .padding(7)
                            .background(LeafTheme.accent(for: colorScheme).opacity(0.1))
                            .clipShape(Circle())
                    }

                    // Delete statement
                    Button {
                        vm.confirmDelete(statement)
                    } label: {
                        Image(systemName: "trash")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(LeafTheme.expenseCoral)
                            .padding(7)
                            .background(LeafTheme.expenseCoral.opacity(0.1))
                            .clipShape(Circle())
                    }
                }
            }

            // Financial Summary Pill inside row
            HStack(spacing: 12) {
                summaryChip(
                    title: "Operating Cash Flow",
                    amount: statement.operatingCashFlow.description,
                    isPositive: !statement.operatingCashFlow.isNegative
                )

                summaryChip(
                    title: "Transactions",
                    amount: "\(statement.transactionCount) items",
                    isPositive: nil
                )
            }
        }
        .padding(14)
        .background(LeafTheme.card(for: colorScheme))
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(LeafTheme.border(for: colorScheme), lineWidth: 1)
        )
    }

    @ViewBuilder
    private func summaryChip(title: String, amount: String, isPositive: Bool?) -> some View {
        HStack(spacing: 4) {
            Text(title + ":")
                .font(Font.system(size: 11, weight: .regular))
                .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))

            Text(amount)
                .font(Font.system(size: 11, weight: .semibold))
                .foregroundStyle(
                    isPositive == nil ? LeafTheme.textPrimary(for: colorScheme) :
                    (isPositive == true ? LeafTheme.incomeGreen : LeafTheme.expenseCoral)
                )
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(LeafTheme.canvas(for: colorScheme))
        .cornerRadius(6)
    }
}

