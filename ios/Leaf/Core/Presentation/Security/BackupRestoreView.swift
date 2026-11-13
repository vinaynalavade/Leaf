import SwiftUI

/// Dedicated screen for creating encrypted backups, restoring existing backups, and inspecting backup metadata.
public struct BackupRestoreView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(AppContainer.self) private var container

    @State private var lastBackupDate: Date? = nil
    @State private var isCreateSheetPresented: Bool = false
    @State private var isRestoreSheetPresented: Bool = false
    @State private var alertMessage: String? = nil
    @State private var isSuccessAlertPresented: Bool = false

    public init() {}

    public var body: some View {
        ZStack {
            LeafTheme.canvas(for: colorScheme).ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    // 1. Hero Status Card
                    backupHeroCard()

                    // 2. Main Actions
                    backupActionsRow()

                    // 3. Educational Information Sections
                    includedDataSection()
                    securityArchitectureSection()

                    Spacer(minLength: 32)
                }
                .padding(.top, 16)
            }
        }
        .navigationTitle("Backup & Restore")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadBackupMetadata()
        }
        .sheet(isPresented: $isCreateSheetPresented) {
            CreateBackupSheet(onBackupCreated: {
                loadBackupMetadata()
            })
        }
        .sheet(isPresented: $isRestoreSheetPresented) {
            RestoreBackupSheet(onRestoreCompleted: {
                loadBackupMetadata()
                alertMessage = "Database restored successfully. All modules have been updated."
                isSuccessAlertPresented = true
            })
        }
        .alert("Restoration Complete", isPresented: $isSuccessAlertPresented) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(alertMessage ?? "")
        }
    }

    // MARK: - 1. Hero Card

    @ViewBuilder
    private func backupHeroCard() -> some View {
        SquircleCard(cornerRadius: 20) {
            VStack(spacing: 16) {
                HStack(alignment: .top) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 14)
                            .fill(LeafTheme.brandEmerald.opacity(0.12))
                            .frame(width: 48, height: 48)

                        Image(systemName: "lock.shield.fill")
                            .font(.system(size: 24))
                            .foregroundStyle(LeafTheme.brandEmerald)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("ENCRYPTED BACKUPS")
                            .font(LeafTypography.captionBold)
                            .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
                            .tracking(0.5)

                        Text(lastBackupDate != nil ? "Protected & Backed Up" : "No Backup Created")
                            .font(LeafTypography.titleMedium)
                            .foregroundStyle(LeafTheme.textPrimary(for: colorScheme))

                        if let date = lastBackupDate {
                            Text("Last backup: \(DateFormatter.localizedString(from: date, dateStyle: .medium, timeStyle: .short))")
                                .font(LeafTypography.caption)
                                .foregroundStyle(LeafTheme.brandEmerald)
                        } else {
                            Text("Create a password-protected backup to prevent data loss.")
                                .font(LeafTypography.caption)
                                .foregroundStyle(LeafTheme.warningGold)
                        }
                    }

                    Spacer()
                }

                Divider()

                HStack(spacing: 16) {
                    HStack(spacing: 6) {
                        Image(systemName: "key.fill")
                            .font(.system(size: 11))
                            .foregroundStyle(LeafTheme.brandEmerald)
                        Text("AES-GCM 256")
                            .font(LeafTypography.captionBold)
                            .foregroundStyle(LeafTheme.textPrimary(for: colorScheme))
                    }

                    HStack(spacing: 6) {
                        Image(systemName: "shield.checkered")
                            .font(.system(size: 11))
                            .foregroundStyle(LeafTheme.brandEmerald)
                        Text("PBKDF2-SHA256")
                            .font(LeafTypography.captionBold)
                            .foregroundStyle(LeafTheme.textPrimary(for: colorScheme))
                    }

                    Spacer()

                    Text(".leafbackup")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(LeafTheme.card(for: colorScheme))
                        .cornerRadius(4)
                }
            }
            .padding(16)
        }
        .padding(.horizontal)
    }

    // MARK: - 2. Action Buttons

    @ViewBuilder
    private func backupActionsRow() -> some View {
        VStack(spacing: 10) {
            Button {
                isCreateSheetPresented = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.down.doc.fill")
                    Text("Create Encrypted Backup")
                }
                .font(LeafTypography.bodyBold)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(LeafTheme.brandEmerald)
                .foregroundStyle(Color.white)
                .cornerRadius(12)
            }

            Button {
                isRestoreSheetPresented = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.up.doc.fill")
                    Text("Restore from Backup File")
                }
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

    // MARK: - 3. Informational Sections

    @ViewBuilder
    private func includedDataSection() -> some View {
        SquircleCard(cornerRadius: 16) {
            VStack(alignment: .leading, spacing: 12) {
                Text("WHAT IS INCLUDED IN A BACKUP")
                    .font(LeafTypography.captionBold)
                    .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))

                dataRow(icon: "dollarsign.circle", title: "All Transactions", subtitle: "Expenses, income, and checking account records")
                dataRow(icon: "folder", title: "Custom Categories", subtitle: "Default and custom user categories")
                dataRow(icon: "chart.bar", title: "Budgets & Limits", subtitle: "Monthly, weekly, and custom period budgets")
                dataRow(icon: "target", title: "Savings Goals", subtitle: "Goals, deposits, and withdrawal history")
                dataRow(icon: "person.2", title: "Split & Collect", subtitle: "Groups, participants, and debt settlements")
                dataRow(icon: "arrow.triangle.2.circlepath", title: "Recurring & Bills", subtitle: "Schedules, subscriptions, and occurrence ledgers")
            }
            .padding(16)
        }
        .padding(.horizontal)
    }

    @ViewBuilder
    private func securityArchitectureSection() -> some View {
        SquircleCard(cornerRadius: 16) {
            VStack(alignment: .leading, spacing: 10) {
                Text("PRIVACY & PORTABILITY")
                    .font(LeafTypography.captionBold)
                    .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))

                Text("• Zero Cloud Servers: Leaf never uploads your financial records to external servers.")
                    .font(LeafTypography.caption)
                    .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))

                Text("• Device-Independent: Backups can be restored onto any compatible iOS device running Leaf using your backup password.")
                    .font(LeafTypography.caption)
                    .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))

                Text("• Atomic Safety: Restoration uses transactional verification so existing data is never corrupted or lost if a restore fails.")
                    .font(LeafTypography.caption)
                    .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
            }
            .padding(16)
        }
        .padding(.horizontal)
    }

    @ViewBuilder
    private func dataRow(icon: String, title: String, subtitle: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(LeafTheme.brandEmerald)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(LeafTypography.bodyBold)
                    .foregroundStyle(LeafTheme.textPrimary(for: colorScheme))
                Text(subtitle)
                    .font(LeafTypography.caption)
                    .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
            }
        }
    }

    private func loadBackupMetadata() {
        let prefs = container.preferencesRepository.getUserPreferences()
        if prefs.lastBackupTimestamp > 0 {
            lastBackupDate = Date(timeIntervalSince1970: Double(prefs.lastBackupTimestamp) / 1000.0)
        } else {
            lastBackupDate = nil
        }
    }
}

