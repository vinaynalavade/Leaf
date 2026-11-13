import SwiftUI
import UniformTypeIdentifiers

/// Sheet guiding the user through selecting, authenticating, previewing, and atomically restoring a `.leafbackup` file.
/// Shows real-time progress phases, enforces pre-restore confirmation, and guarantees consistent database and filesystem states.
public struct RestoreBackupSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @Environment(AppContainer.self) private var container

    @State private var selectedFileURL: URL? = nil
    @State private var password: String = ""
    @State private var isPasswordVisible: Bool = false

    @State private var isValidating: Bool = false
    @State private var isRestoring: Bool = false
    @State private var restoreProgressState: RestoreProgressState = .idle
    @State private var errorMessage: String? = nil

    @State private var validatedPayload: LeafBackupPayload? = nil
    @State private var validatedSummary: BackupSummary? = nil
    @State private var isDocumentPickerPresented: Bool = false
    @State private var isReplaceConfirmationPresented: Bool = false
    @State private var isRestoreSuccessful: Bool = false

    public let onRestoreCompleted: (() -> Void)?

    public init(onRestoreCompleted: (() -> Void)? = nil) {
        self.onRestoreCompleted = onRestoreCompleted
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                LeafTheme.canvas(for: colorScheme).ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        if isRestoreSuccessful {
                            restorationSuccessView()
                        } else if isRestoring {
                            restorationProgressView()
                        } else if let summary = validatedSummary {
                            restorationPreviewView(summary: summary)
                        } else {
                            fileSelectionAndAuthView()
                        }
                    }
                    .padding(.top, 16)
                }
            }
            .navigationTitle(isRestoreSuccessful ? "Restore Complete" : (isRestoring ? "Restoring..." : "Restore from Backup"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    if !isRestoring {
                        Button(isRestoreSuccessful ? "Done" : "Cancel") {
                            dismiss()
                        }
                    }
                }
            }
            .fileImporter(
                isPresented: $isDocumentPickerPresented,
                allowedContentTypes: [.data, UTType(filenameExtension: "leafbackup") ?? .data],
                allowsMultipleSelection: false
            ) { result in
                switch result {
                case .success(let urls):
                    if let first = urls.first {
                        self.selectedFileURL = first
                        self.errorMessage = nil
                        self.validatedSummary = nil
                        self.validatedPayload = nil
                    }
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                }
            }
            .alert("Replace Current Financial Data?", isPresented: $isReplaceConfirmationPresented) {
                Button("Replace All Data", role: .destructive) {
                    executeRestoration()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This action replaces all transactions, categories, budgets, savings goals, and statement files currently on this device with the contents of the backup. A safety snapshot is created before changes occur.")
            }
        }
    }

    // MARK: - Step 1: File Selection & Password Entry

    @ViewBuilder
    private func fileSelectionAndAuthView() -> some View {
        VStack(spacing: 16) {
            // File Selection Card
            SquircleCard(cornerRadius: 14) {
                VStack(spacing: 12) {
                    HStack(spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(LeafTheme.brandEmerald.opacity(0.12))
                                .frame(width: 44, height: 44)

                            Image(systemName: "doc.zipper")
                                .font(.system(size: 20))
                                .foregroundStyle(LeafTheme.brandEmerald)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text(selectedFileURL?.lastPathComponent ?? "Select Backup File")
                                .font(LeafTypography.bodyBold)
                                .foregroundStyle(LeafTheme.textPrimary(for: colorScheme))
                                .lineLimit(1)

                            Text(selectedFileURL != nil ? "Ready for passphrase authentication" : "Supports .leafbackup files")
                                .font(LeafTypography.caption)
                                .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
                        }

                        Spacer()

                        Button {
                            isDocumentPickerPresented = true
                        } label: {
                            Text(selectedFileURL != nil ? "Change" : "Browse")
                                .font(LeafTypography.captionBold)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(LeafTheme.card(for: colorScheme))
                                .foregroundStyle(LeafTheme.brandEmerald)
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(LeafTheme.brandEmerald, lineWidth: 1)
                                )
                        }
                    }
                }
                .padding(14)
            }
            .padding(.horizontal)

            // Password Input
            if selectedFileURL != nil {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Backup Passphrase")
                        .font(LeafTypography.captionBold)
                        .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))

                    HStack {
                        if isPasswordVisible {
                            TextField("Enter backup passphrase", text: $password)
                                .font(LeafTypography.bodyMedium)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled(true)
                        } else {
                            SecureField("Enter backup passphrase", text: $password)
                                .font(LeafTypography.bodyMedium)
                        }

                        Button {
                            isPasswordVisible.toggle()
                        } label: {
                            Image(systemName: isPasswordVisible ? "eye.slash" : "eye")
                                .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
                        }
                    }
                    .padding(12)
                    .background(LeafTheme.card(for: colorScheme))
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(LeafTheme.border(for: colorScheme), lineWidth: 1)
                    )
                }
                .padding(.horizontal)

                // Inspect / Authenticate Button
                Button {
                    validateSelectedBackup()
                } label: {
                    HStack(spacing: 8) {
                        if isValidating {
                            ProgressView()
                                .tint(Color.white)
                            Text(restoreProgressState.title)
                        } else {
                            Image(systemName: "checkmark.shield")
                            Text("Unlock & Preview Backup")
                        }
                    }
                    .font(LeafTypography.bodyBold)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(!password.isEmpty && !isValidating ? LeafTheme.brandEmerald : Color.gray.opacity(0.4))
                    .foregroundStyle(Color.white)
                    .cornerRadius(12)
                }
                .disabled(password.isEmpty || isValidating)
                .padding(.horizontal)
                .padding(.top, 4)
            }

            if let error = errorMessage {
                Text(error)
                    .font(LeafTypography.captionBold)
                    .foregroundStyle(LeafTheme.expenseCoral)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
        }
    }

    // MARK: - Step 2: Inspection Preview & Confirmation

    @ViewBuilder
    private func restorationPreviewView(summary: BackupSummary) -> some View {
        VStack(spacing: 16) {
            // Preview Header
            HStack(spacing: 10) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(LeafTheme.brandEmerald)

                Text("Backup Authenticated & Verified")
                    .font(LeafTypography.titleMedium)
                    .foregroundStyle(LeafTheme.textPrimary(for: colorScheme))
            }
            .padding(.top, 4)

            // Record Breakdown Card
            SquircleCard(cornerRadius: 14) {
                VStack(spacing: 10) {
                    detailRow(title: "Backup Date", value: DateFormatter.localizedString(from: summary.createdAt, dateStyle: .medium, timeStyle: .short))
                    detailRow(title: "Leaf Version", value: summary.appVersion)
                    detailRow(title: "Currency", value: summary.currencyCode)
                    detailRow(title: "Encryption", value: "\(summary.encryptionAlgorithm) (\(summary.kdfIterations.formatted()) iterations)")
                    Divider()
                    detailRow(title: "Transactions", value: "\(summary.transactionCount)")
                    detailRow(title: "Categories", value: "\(summary.categoryCount)")
                    detailRow(title: "Budgets", value: "\(summary.budgetCount)")
                    detailRow(title: "Savings Goals", value: "\(summary.savingsGoalCount)")
                    detailRow(title: "Recurring Schedules", value: "\(summary.recurringScheduleCount)")
                    detailRow(title: "Split Records", value: "\(summary.splitExpenseCount)")
                    detailRow(title: "Statement Documents", value: "\(summary.statementFileCount) files")
                    Divider()
                    detailRow(title: "Total Records to Restore", value: "\(summary.totalRecordCount)")
                }
                .padding(14)
            }
            .padding(.horizontal)

            if summary.missingStatementFileCount > 0 {
                SquircleCard(cornerRadius: 12) {
                    HStack(spacing: 10) {
                        Image(systemName: "info.circle.fill")
                            .font(.system(size: 18))
                            .foregroundStyle(LeafTheme.warningGold)

                        Text("\(summary.missingStatementFileCount) historical statement file(s) are not included in this backup. Their ledger records will be restored, but document attachments may be unavailable.")
                            .font(LeafTypography.caption)
                            .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
                            .lineSpacing(2)
                    }
                    .padding(12)
                }
                .padding(.horizontal)
            }

            // Warning Disclosure & Rollback Guarantee
            SquircleCard(cornerRadius: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.system(size: 14))
                            .foregroundStyle(LeafTheme.brandEmerald)

                        Text("ATOMIC RESTORATION & CRASH RECOVERY")
                            .font(LeafTypography.captionBold)
                            .foregroundStyle(LeafTheme.brandEmerald)
                    }

                    Text("Full Replacement Mode: All financial records and statements currently on this device will be replaced with this backup. A pre-restore safety snapshot is maintained until the restore reaches the durable commit point. If any interruption or crash occurs prior to commitment, your previous data will be completely rolled back.")
                        .font(LeafTypography.caption)
                        .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
                        .lineSpacing(2)
                }
                .padding(12)
            }
            .padding(.horizontal)

            if let error = errorMessage {
                Text(error)
                    .font(LeafTypography.captionBold)
                    .foregroundStyle(LeafTheme.expenseCoral)
                    .padding(.horizontal)
            }

            // Restore Action Button
            Button {
                isReplaceConfirmationPresented = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.triangle.2.circlepath")
                    Text("Restore & Replace Current Data")
                }
                .font(LeafTypography.bodyBold)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(LeafTheme.expenseCoral)
                .foregroundStyle(Color.white)
                .cornerRadius(12)
            }
            .padding(.horizontal)

            Button {
                self.validatedSummary = nil
                self.validatedPayload = nil
                self.password = ""
            } label: {
                Text("Select Different File")
                    .font(LeafTypography.captionBold)
                    .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
            }
            .padding(.top, 4)
        }
    }

    // MARK: - Step 3: Active Restoration Progress View

    @ViewBuilder
    private func restorationProgressView() -> some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .stroke(LeafTheme.brandEmerald.opacity(0.15), lineWidth: 6)
                    .frame(width: 80, height: 80)

                ProgressView()
                    .tint(LeafTheme.brandEmerald)
                    .scaleEffect(1.6)
            }
            .padding(.top, 30)

            VStack(spacing: 8) {
                Text(restoreProgressState.title)
                    .font(LeafTypography.titleMedium)
                    .foregroundStyle(LeafTheme.textPrimary(for: colorScheme))

                Text("Safely restoring financial records and statement files...")
                    .font(LeafTypography.caption)
                    .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
            }

            // Progress Bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 8)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(LeafTheme.brandEmerald)
                        .frame(width: max(10, geo.size.width * CGFloat(restoreProgressState.progressRatio)), height: 8)
                        .animation(.easeInOut(duration: 0.3), value: restoreProgressState)
                }
            }
            .frame(height: 8)
            .padding(.horizontal, 32)

            SquircleCard(cornerRadius: 14) {
                VStack(alignment: .leading, spacing: 12) {
                    progressStepRow(
                        title: "1. Staging statement files",
                        isActive: restoreProgressState == .preparing,
                        isDone: restoreProgressState == .restoringRecords || restoreProgressState == .restoringStatements || restoreProgressState == .finalizing || restoreProgressState == .completed
                    )
                    progressStepRow(
                        title: "2. Pre-restore safety snapshot",
                        isActive: restoreProgressState == .preparing,
                        isDone: restoreProgressState == .restoringRecords || restoreProgressState == .restoringStatements || restoreProgressState == .finalizing || restoreProgressState == .completed
                    )
                    progressStepRow(
                        title: "3. Restoring financial records",
                        isActive: restoreProgressState == .restoringRecords,
                        isDone: restoreProgressState == .restoringStatements || restoreProgressState == .finalizing || restoreProgressState == .completed
                    )
                    progressStepRow(
                        title: "4. Restoring statement files",
                        isActive: restoreProgressState == .restoringStatements,
                        isDone: restoreProgressState == .finalizing || restoreProgressState == .completed
                    )
                    progressStepRow(
                        title: "5. Committing & finalizing consistency",
                        isActive: restoreProgressState == .finalizing,
                        isDone: restoreProgressState == .completed
                    )
                }
                .padding(16)
            }
            .padding(.horizontal)

            Text("Please do not close Leaf or lock your device.")
                .font(LeafTypography.caption)
                .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
                .padding(.top, 8)
        }
    }

    @ViewBuilder
    private func progressStepRow(title: String, isActive: Bool, isDone: Bool) -> some View {
        HStack(spacing: 10) {
            if isDone {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(LeafTheme.brandEmerald)
                    .font(.system(size: 16))
            } else if isActive {
                ProgressView()
                    .tint(LeafTheme.brandEmerald)
                    .scaleEffect(0.8)
                    .frame(width: 16, height: 16)
            } else {
                Circle()
                    .stroke(Color.gray.opacity(0.3), lineWidth: 1.5)
                    .frame(width: 16, height: 16)
            }

            Text(title)
                .font(isActive ? LeafTypography.captionBold : LeafTypography.caption)
                .foregroundStyle(isActive ? LeafTheme.brandEmerald : (isDone ? LeafTheme.textPrimary(for: colorScheme) : LeafTheme.textSecondary(for: colorScheme)))

            Spacer()
        }
    }

    // MARK: - Step 4: Success View

    @ViewBuilder
    private func restorationSuccessView() -> some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 60))
                .foregroundStyle(LeafTheme.brandEmerald)
                .padding(.top, 20)

            VStack(spacing: 6) {
                Text("Database & Statements Restored")
                    .font(LeafTypography.titleMedium)
                    .foregroundStyle(LeafTheme.textPrimary(for: colorScheme))

                Text("All financial transactions, categories, budgets, recurring schedules, and statement files are verified and consistent.")
                    .font(LeafTypography.caption)
                    .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            Button {
                dismiss()
                onRestoreCompleted?()
            } label: {
                Text("Finish")
                    .font(LeafTypography.bodyBold)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(LeafTheme.brandEmerald)
                    .foregroundStyle(Color.white)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)
        }
    }

    @ViewBuilder
    private func detailRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(LeafTypography.caption)
                .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
            Spacer()
            Text(value)
                .font(LeafTypography.captionBold)
                .foregroundStyle(LeafTheme.textPrimary(for: colorScheme))
        }
    }

    // MARK: - Operations

    private func validateSelectedBackup() {
        guard let url = selectedFileURL else { return }
        isValidating = true
        errorMessage = nil
        restoreProgressState = .validating

        Task {
            do {
                let result = try await container.validateBackupUseCase.execute(fileURL: url, password: password) { state in
                    Task { @MainActor in
                        self.restoreProgressState = state
                    }
                }
                await MainActor.run {
                    self.validatedPayload = result.payload
                    self.validatedSummary = result.summary
                    self.isValidating = false
                    self.restoreProgressState = .idle
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isValidating = false
                    self.restoreProgressState = .idle
                }
            }
        }
    }

    private func executeRestoration() {
        guard let payload = validatedPayload else { return }
        isRestoring = true
        errorMessage = nil
        restoreProgressState = .preparing

        Task {
            do {
                try await container.restoreBackupUseCase.execute(payload: payload) { state in
                    Task { @MainActor in
                        self.restoreProgressState = state
                    }
                }
                await MainActor.run {
                    self.isRestoring = false
                    self.isRestoreSuccessful = true
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isRestoring = false
                    self.restoreProgressState = .idle
                }
            }
        }
    }
}
