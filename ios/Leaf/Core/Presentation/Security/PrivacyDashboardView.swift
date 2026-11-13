import SwiftUI
import UserNotifications

/// The centralized Privacy & Security Dashboard for Leaf iOS.
/// Provides configuration for biometric app locks, encrypted backups, local storage protection details,
/// data exports, and irreversible data wiping.
public struct PrivacyDashboardView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(AppContainer.self) private var container

    @State private var viewModel: PrivacyDashboardViewModel?
    @State private var isDeleteSheetPresented: Bool = false
    @State private var isBackupSheetPresented: Bool = false
    @State private var isStatementsPresented: Bool = false
    @State private var isAppLockSetupPresented: Bool = false
    @State private var isDisableAppLockPresented: Bool = false
    @State private var isChangePinPresented: Bool = false
    @State private var isSuccessAlertPresented: Bool = false
    @State private var successAlertMessage: String = ""

    public init() {}

    public var body: some View {
        ZStack {
            LeafTheme.canvas(for: colorScheme).ignoresSafeArea()

            if let vm = viewModel {
                ScrollView {
                    VStack(spacing: 20) {
                        // 1. Biometric App Lock Section
                        appLockSection(vm)

                        // 2. Data Protection & Backups Card
                        backupSection(vm)

                        // 3. Local Storage & Hardware Encryption
                        localStorageSection()

                        // 4. Data Export & Portability
                        dataExportSection()

                        // 5. Destructive Danger Zone
                        dangerZoneSection(vm)

                        Spacer(minLength: 32)
                    }
                    .padding(.top, 16)
                }
                .refreshable {
                    vm.loadData()
                }
            } else {
                ProgressView()
                    .tint(LeafTheme.brandEmerald)
            }
        }
        .navigationTitle("Privacy & Security")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if viewModel == nil {
                self.viewModel = PrivacyDashboardViewModel(
                    preferencesRepository: container.preferencesRepository,
                    appLockService: container.appLockService,
                    deleteAllFinancialDataUseCase: container.deleteAllFinancialDataUseCase,
                    notificationService: container.notificationService
                )
            } else {
                viewModel?.loadData()
            }
        }
        .sheet(isPresented: $isDeleteSheetPresented) {
            DeleteDataConfirmationSheet(onDataDeleted: {
                viewModel?.loadData()
                successAlertMessage = "All financial records, recurring schedules, statement files, and personal data have been completely erased."
                isSuccessAlertPresented = true
            })
        }
        .sheet(isPresented: $isStatementsPresented) {
            NavigationStack {
                StatementsView()
            }
        }
        .sheet(isPresented: $isAppLockSetupPresented) {
            AppLockSetupSheet(onSetupCompleted: {
                viewModel?.loadData()
            })
        }
        .sheet(isPresented: $isDisableAppLockPresented) {
            DisableAppLockSheet(onDisabled: {
                viewModel?.loadData()
            })
        }
        .sheet(isPresented: $isChangePinPresented) {
            ChangePinSheet()
        }
        .alert("Complete", isPresented: $isSuccessAlertPresented) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(successAlertMessage)
        }
    }

    // MARK: - 1. App Lock & Biometrics

    @ViewBuilder
    private func appLockSection(_ vm: PrivacyDashboardViewModel) -> some View {
        SquircleCard(cornerRadius: 16) {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(LeafTheme.brandEmerald.opacity(0.12))
                            .frame(width: 38, height: 38)

                        Image(systemName: "lock.shield.fill")
                            .font(.system(size: 18))
                            .foregroundStyle(LeafTheme.brandEmerald)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("App Lock & PIN")
                            .font(LeafTypography.bodyBold)
                            .foregroundStyle(LeafTheme.textPrimary(for: colorScheme))

                        Text(vm.isAppLockEnabled ? "Secured with 6-digit PIN" : "PIN protection is disabled")
                            .font(LeafTypography.caption)
                            .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
                    }

                    Spacer()

                    Toggle("", isOn: Binding(
                        get: { vm.isAppLockEnabled },
                        set: { newValue in
                            if newValue {
                                isAppLockSetupPresented = true
                            } else {
                                isDisableAppLockPresented = true
                            }
                        }
                    ))
                    .labelsHidden()
                    .tint(LeafTheme.brandEmerald)
                }

                if vm.isAppLockEnabled {
                    Divider()

                    Button {
                        isChangePinPresented = true
                    } label: {
                        HStack {
                            Label("Change 6-Digit PIN", systemImage: "key.fill")
                                .font(LeafTypography.body)
                                .foregroundStyle(LeafTheme.textPrimary(for: colorScheme))
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(LeafTheme.textTertiary(for: colorScheme))
                        }
                    }

                    if vm.biometricType != .none {
                        Divider()

                        HStack {
                            Label("Unlock with \(vm.biometricType.rawValue)", systemImage: vm.biometricType.iconName)
                                .font(LeafTypography.body)
                                .foregroundStyle(LeafTheme.textPrimary(for: colorScheme))

                            Spacer()

                            Toggle("", isOn: Binding(
                                get: { vm.isBiometricEnabled },
                                set: { vm.setBiometricEnabled($0) }
                            ))
                            .labelsHidden()
                            .tint(LeafTheme.brandEmerald)
                        }
                    }

                    Divider()

                    HStack {
                        Text("Auto-Lock Timeout")
                            .font(LeafTypography.caption)
                            .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))

                        Spacer()

                        Picker("Timeout", selection: Binding(
                            get: { vm.selectedTimeout },
                            set: { vm.updateTimeout(timeout: $0) }
                        )) {
                            ForEach(AutoLockTimeout.allCases) { timeout in
                                Text(timeout.displayName).tag(timeout)
                            }
                        }
                        .pickerStyle(.menu)
                        .tint(LeafTheme.brandEmerald)
                    }
                }
            }
            .padding(16)
        }
        .padding(.horizontal)
    }

    // MARK: - 2. Backups & Data Protection

    @ViewBuilder
    private func backupSection(_ vm: PrivacyDashboardViewModel) -> some View {
        SquircleCard(cornerRadius: 16) {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.blue.opacity(0.12))
                            .frame(width: 38, height: 38)

                        Image(systemName: "lock.doc.fill")
                            .font(.system(size: 18))
                            .foregroundStyle(Color.blue)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Encrypted Backups")
                            .font(LeafTypography.bodyBold)
                            .foregroundStyle(LeafTheme.textPrimary(for: colorScheme))

                        if let date = vm.lastBackupDate {
                            Text("Last: \(DateFormatter.localizedString(from: date, dateStyle: .short, timeStyle: .short))")
                                .font(LeafTypography.caption)
                                .foregroundStyle(LeafTheme.brandEmerald)
                        } else {
                            Text("No backup created yet")
                                .font(LeafTypography.caption)
                                .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
                        }
                    }

                    Spacer()

                    NavigationLink {
                        BackupRestoreView()
                    } label: {
                        HStack(spacing: 4) {
                            Text("Manage")
                                .font(LeafTypography.captionBold)
                                .foregroundStyle(LeafTheme.brandEmerald)
                            Image(systemName: "chevron.right")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(LeafTheme.brandEmerald)
                        }
                    }
                }

                Divider()

                Text("Backups are encrypted using AES-256-GCM authenticated encryption with PBKDF2-HMAC-SHA256 key derivation (600,000 work factor iterations). Leaf does not store or escrow backup passwords; lost passwords cannot be reset or recovered.")
                    .font(LeafTypography.caption)
                    .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
                    .lineSpacing(2)
            }
            .padding(16)
        }
        .padding(.horizontal)
    }

    // MARK: - 3. Local Storage Architecture

    @ViewBuilder
    private func localStorageSection() -> some View {
        SquircleCard(cornerRadius: 16) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 8) {
                    Image(systemName: "internaldrive.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(LeafTheme.brandEmerald)

                    Text("LOCAL STORAGE & HARDWARE PROTECTION")
                        .font(LeafTypography.captionBold)
                        .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
                }

                HStack {
                    Text("Storage Engine")
                        .font(LeafTypography.caption)
                        .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
                    Spacer()
                    Text("Local SQLite (GRDB)")
                        .font(LeafTypography.captionBold)
                        .foregroundStyle(LeafTheme.textPrimary(for: colorScheme))
                }

                HStack {
                    Text("iOS Data Protection")
                        .font(LeafTypography.caption)
                        .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
                    Spacer()
                    Text("Complete (When Locked)")
                        .font(LeafTypography.captionBold)
                        .foregroundStyle(LeafTheme.brandEmerald)
                }

                HStack {
                    Text("Multitasking Privacy Shield")
                        .font(LeafTypography.caption)
                        .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
                    Spacer()
                    Text("Active (Masks App Switcher)")
                        .font(LeafTypography.captionBold)
                        .foregroundStyle(LeafTheme.brandEmerald)
                }

                HStack {
                    Text("Cloud Sync / External Servers")
                        .font(LeafTypography.caption)
                        .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
                    Spacer()
                    Text("None (100% On-Device)")
                        .font(LeafTypography.captionBold)
                        .foregroundStyle(LeafTheme.textPrimary(for: colorScheme))
                }
            }
            .padding(16)
        }
        .padding(.horizontal)
    }

    // MARK: - 4. Data Export

    @ViewBuilder
    private func dataExportSection() -> some View {
        SquircleCard(cornerRadius: 16) {
            VStack(alignment: .leading, spacing: 12) {
                Text("DATA PORTABILITY & EXPORT")
                    .font(LeafTypography.captionBold)
                    .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))

                Button {
                    isStatementsPresented = true
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "doc.text.fill")
                            .font(.system(size: 16))
                            .foregroundStyle(LeafTheme.brandEmerald)

                        VStack(alignment: .leading, spacing: 1) {
                            Text("Export Financial Statements")
                                .font(LeafTypography.bodyBold)
                                .foregroundStyle(LeafTheme.textPrimary(for: colorScheme))
                            Text("Generate audit-grade PDF reports & CSV transaction ledgers")
                                .font(LeafTypography.caption)
                                .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
                    }
                }
                .buttonStyle(.plain)

                Divider()

                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "info.circle")
                        .font(.system(size: 13))
                        .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))

                    Text("Exported CSV and PDF files are standard unencrypted documents intended for personal bookkeeping or tax reporting. Store them securely.")
                        .font(LeafTypography.caption)
                        .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
                        .lineSpacing(2)
                }
            }
            .padding(16)
        }
        .padding(.horizontal)
    }

    // MARK: - 5. Danger Zone

    @ViewBuilder
    private func dangerZoneSection(_ vm: PrivacyDashboardViewModel) -> some View {
        SquircleCard(cornerRadius: 16) {
            VStack(alignment: .leading, spacing: 12) {
                Text("DANGER ZONE")
                    .font(LeafTypography.captionBold)
                    .foregroundStyle(LeafTheme.expenseCoral)

                Text("Permanently erase all accounts, transactions, budgets, goals, statement documents, and settings from this device.")
                    .font(LeafTypography.caption)
                    .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))

                Button {
                    isDeleteSheetPresented = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "trash.fill")
                        Text("Delete All Financial Data")
                    }
                    .font(LeafTypography.captionBold)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(LeafTheme.expenseCoral.opacity(0.12))
                    .foregroundStyle(LeafTheme.expenseCoral)
                    .cornerRadius(10)
                }
                .buttonStyle(.plain)
            }
            .padding(16)
        }
        .padding(.horizontal)
    }
}
