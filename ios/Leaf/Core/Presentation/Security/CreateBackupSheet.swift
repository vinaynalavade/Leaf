import SwiftUI

/// Sheet for creating a hardened, password-protected, AES-GCM 256 encrypted `.leafbackup` file.
/// Validates passphrase quality using real-time strength evaluation, requires confirmation,
/// enforces a minimum 12-character passphrase policy, and discloses the unrecoverable nature of lost backup passwords.
public struct CreateBackupSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @Environment(AppContainer.self) private var container

    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    @State private var isPasswordVisible: Bool = false
    @State private var isCreating: Bool = false
    @State private var errorMessage: String? = nil

    @State private var createdBackupURL: URL? = nil
    @State private var backupSummary: BackupSummary? = nil
    @State private var isShareSheetPresented: Bool = false

    public let onBackupCreated: (() -> Void)?

    public init(onBackupCreated: (() -> Void)? = nil) {
        self.onBackupCreated = onBackupCreated
    }

    private var passwordStrength: PasswordStrength {
        PasswordStrength.evaluate(password)
    }

    private var isPasswordValid: Bool {
        password.count >= BackupService.minimumPasswordLength
    }

    private var doPasswordsMatch: Bool {
        !password.isEmpty && password == confirmPassword
    }

    private var canCreateBackup: Bool {
        isPasswordValid && doPasswordsMatch && !isCreating
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                LeafTheme.canvas(for: colorScheme).ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        if let summary = backupSummary, let url = createdBackupURL {
                            successView(summary: summary, url: url)
                        } else {
                            creationForm()
                        }
                    }
                    .padding(.top, 16)
                }
            }
            .navigationTitle("Create Encrypted Backup")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(backupSummary != nil ? "Done" : "Cancel") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $isShareSheetPresented) {
                if let url = createdBackupURL {
                    ShareSheetView(activityItems: [url])
                }
            }
        }
    }

    @ViewBuilder
    private func creationForm() -> some View {
        VStack(spacing: 16) {
            // Security Badge
            HStack(spacing: 8) {
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(LeafTheme.brandEmerald)

                Text("AES-256-GCM • 600,000 PBKDF2 Iterations")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(LeafTheme.brandEmerald)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(LeafTheme.brandEmerald.opacity(0.12))
            .cornerRadius(8)

            // Password Instructions & Unrecoverability Warning
            SquircleCard(cornerRadius: 14) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("SET BACKUP PASSPHRASE")
                        .font(LeafTypography.captionBold)
                        .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))

                    Text("Enter a long passphrase of at least 12 characters. Spaces, multi-word phrases (e.g., 4 or more random words), and Unicode characters are supported and strongly recommended.")
                        .font(LeafTypography.caption)
                        .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
                        .lineSpacing(2)

                    HStack(spacing: 6) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(LeafTheme.warningGold)

                        Text("Leaf does not store this password. If lost, your backup is permanently unrecoverable.")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(LeafTheme.warningGold)
                    }
                    .padding(.top, 4)
                }
                .padding(14)
            }
            .padding(.horizontal)

            // Password Input Fields
            VStack(spacing: 14) {
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Passphrase (min. 12 characters)")
                            .font(LeafTypography.captionBold)
                            .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))

                        Spacer()

                        if !password.isEmpty {
                            Text(passwordStrength.title)
                                .font(LeafTypography.captionBold)
                                .foregroundStyle(passwordStrength.color)
                        }
                    }

                    HStack {
                        if isPasswordVisible {
                            TextField("Enter passphrase", text: $password)
                                .font(LeafTypography.bodyMedium)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled(true)
                        } else {
                            SecureField("Enter passphrase", text: $password)
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

                    // Strength Indicator Bar & Dynamic Guidance
                    if !password.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 3)
                                        .fill(Color.gray.opacity(0.2))
                                        .frame(height: 5)

                                    RoundedRectangle(cornerRadius: 3)
                                        .fill(passwordStrength.color)
                                        .frame(width: max(12, geo.size.width * CGFloat(passwordStrength.progressRatio)), height: 5)
                                        .animation(.easeInOut(duration: 0.2), value: passwordStrength)
                                }
                            }
                            .frame(height: 5)
                            .padding(.top, 2)

                            if password.count < BackupService.minimumPasswordLength {
                                Text("\(BackupService.minimumPasswordLength - password.count) more characters needed (minimum 12)")
                                    .font(.system(size: 11))
                                    .foregroundStyle(LeafTheme.expenseCoral)
                            } else {
                                Text(passwordStrength.guidanceMessage)
                                    .font(.system(size: 11))
                                    .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
                            }
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("Confirm Passphrase")
                        .font(LeafTypography.captionBold)
                        .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))

                    SecureField("Re-enter passphrase", text: $confirmPassword)
                        .font(LeafTypography.bodyMedium)
                        .padding(12)
                        .background(LeafTheme.card(for: colorScheme))
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(
                                    (!confirmPassword.isEmpty && !doPasswordsMatch)
                                        ? LeafTheme.expenseCoral
                                        : LeafTheme.border(for: colorScheme),
                                    lineWidth: 1
                                )
                        )

                    if !confirmPassword.isEmpty && !doPasswordsMatch {
                        Text("Passphrases do not match.")
                            .font(LeafTypography.caption)
                            .foregroundStyle(LeafTheme.expenseCoral)
                    }
                }
            }
            .padding(.horizontal)

            if let error = errorMessage {
                Text(error)
                    .font(LeafTypography.captionBold)
                    .foregroundStyle(LeafTheme.expenseCoral)
                    .padding(.horizontal)
            }

            // Create Button
            Button {
                generateBackup()
            } label: {
                HStack(spacing: 8) {
                    if isCreating {
                        ProgressView()
                            .tint(Color.white)
                        Text("Deriving Keys & Encrypting...")
                    } else {
                        Image(systemName: "arrow.down.doc.fill")
                        Text("Create Encrypted Backup")
                    }
                }
                .font(LeafTypography.bodyBold)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(canCreateBackup ? LeafTheme.brandEmerald : Color.gray.opacity(0.4))
                .foregroundStyle(Color.white)
                .cornerRadius(12)
            }
            .disabled(!canCreateBackup)
            .padding(.horizontal)
            .padding(.top, 8)
        }
    }

    @ViewBuilder
    private func successView(summary: BackupSummary, url: URL) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 56))
                .foregroundStyle(LeafTheme.brandEmerald)
                .padding(.top, 10)

            VStack(spacing: 6) {
                Text("Backup Created Successfully")
                    .font(LeafTypography.titleMedium)
                    .foregroundStyle(LeafTheme.textPrimary(for: colorScheme))

                Text("Your financial records and generated statement documents are safely encrypted in .leafbackup format.")
                    .font(LeafTypography.caption)
                    .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }

            // Summary Card
            SquircleCard(cornerRadius: 14) {
                VStack(spacing: 10) {
                    detailRow(title: "File Size", value: summary.fileSizeFormatted)
                    detailRow(title: "Encryption", value: "\(summary.encryptionAlgorithm) (\(summary.kdfIterations.formatted()) iterations)")
                    Divider()
                    detailRow(title: "Transactions", value: "\(summary.transactionCount)")
                    detailRow(title: "Budgets & Goals", value: "\(summary.budgetCount + summary.savingsGoalCount)")
                    detailRow(title: "Recurring Schedules", value: "\(summary.recurringScheduleCount)")
                    detailRow(title: "Split Records", value: "\(summary.splitExpenseCount)")
                    detailRow(title: "Statement Documents", value: "\(summary.statementFileCount) attached")
                    Divider()
                    detailRow(title: "Total Records", value: "\(summary.totalRecordCount)")
                }
                .padding(14)
            }
            .padding(.horizontal)

            // Export / Share Actions
            VStack(spacing: 10) {
                Button {
                    isShareSheetPresented = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "square.and.arrow.up")
                        Text("Share or Save to Files")
                    }
                    .font(LeafTypography.bodyBold)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(LeafTheme.brandEmerald)
                    .foregroundStyle(Color.white)
                    .cornerRadius(12)
                }

                Button {
                    dismiss()
                } label: {
                    Text("Done")
                        .font(LeafTypography.bodyBold)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(LeafTheme.card(for: colorScheme))
                        .foregroundStyle(LeafTheme.textPrimary(for: colorScheme))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(LeafTheme.border(for: colorScheme), lineWidth: 1)
                        )
                }
            }
            .padding(.horizontal)
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

    private func generateBackup() {
        guard canCreateBackup else { return }
        isCreating = true
        errorMessage = nil

        Task {
            do {
                let result = try await container.createBackupUseCase.execute(password: password)
                await MainActor.run {
                    self.createdBackupURL = result.fileURL
                    self.backupSummary = result.summary
                    self.isCreating = false
                    self.onBackupCreated?()
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isCreating = false
                }
            }
        }
    }
}
