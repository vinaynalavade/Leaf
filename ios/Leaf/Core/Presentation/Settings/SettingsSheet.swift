import SwiftUI

/// Comprehensive Settings and user preferences screen matching the complete Android reference implementation.
/// Covers Profile & Google Account, Theme/Appearance, Currency & Regional, Google Drive Cloud Backup,
/// App Lock & Biometrics, Daily Notifications, Financial Modules, and About Leaf.
public struct SettingsSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @Environment(AppContainer.self) private var container

    // State: Profile & Account
    @State private var profileName: String = ""
    @State private var googleUser: GoogleAccountProfile? = nil
    @State private var isGoogleSigningIn: Bool = false

    // State: Preferences
    @State private var selectedCurrency: Currency = .usd
    @State private var selectedTheme: String = "SYSTEM"
    @State private var dailyReminderEnabled: Bool = false
    @State private var reminderTime: Date = Calendar.current.date(bySettingHour: 21, minute: 0, second: 0, of: Date()) ?? Date()
    @State private var autoBackupEnabled: Bool = false
    @State private var defaultTransactionSource: PaymentMethod = .cash

    // State: App Lock
    @State private var appLockEnabled: Bool = false
    @State private var biometricEnabled: Bool = false
    @State private var autoLockDurationSeconds: Int64 = 0
    @State private var isAppLockSetupPresented: Bool = false
    @State private var isDisableAppLockPresented: Bool = false
    @State private var isChangePinPresented: Bool = false

    // State: Google Drive Backup
    @State private var lastBackupTimestamp: Int64 = 0
    @State private var isBackingUpGoogle: Bool = false
    @State private var isRestoringGoogle: Bool = false
    @State private var showRestoreConfirmation: Bool = false
    @State private var alertTitle: String = ""
    @State private var alertMessage: String = ""
    @State private var showAlert: Bool = false

    @State private var isSaved: Bool = false

    public init() {}

    private var initials: String {
        let trimmed = profileName.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return "L" }
        let parts = trimmed.split(separator: " ")
        if parts.count >= 2 {
            return "\(parts[0].prefix(1))\(parts[1].prefix(1))".uppercased()
        }
        return String(trimmed.prefix(2)).uppercased()
    }

    private var formattedLastBackup: String {
        if lastBackupTimestamp > 0 {
            let date = Date(timeIntervalSince1970: Double(lastBackupTimestamp) / 1000.0)
            return DateFormatter.localizedString(from: date, dateStyle: .medium, timeStyle: .short)
        }
        return "Never"
    }

    private func triggerHaptic() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()
        generator.impactOccurred()
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                LeafTheme.canvas(for: colorScheme).ignoresSafeArea()

                Form {
                    // MARK: - 1. Profile & Google Account
                    Section {
                        HStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(LeafTheme.brandEmerald.opacity(0.18))
                                    .frame(width: 60, height: 60)
                                Text(initials)
                                    .font(.system(size: 22, weight: .bold, design: .rounded))
                                    .foregroundStyle(LeafTheme.brandEmerald)
                            }
                            .overlay(
                                Circle().stroke(LeafTheme.brandEmerald, lineWidth: 1.5)
                            )

                            VStack(alignment: .leading, spacing: 4) {
                                TextField("Your Name", text: $profileName)
                                    .font(.system(size: 17, weight: .bold, design: .rounded))
                                    .foregroundStyle(LeafTheme.textPrimary(for: colorScheme))

                                if let gUser = googleUser {
                                    HStack(spacing: 4) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.system(size: 11))
                                            .foregroundStyle(LeafTheme.brandEmerald)
                                        Text(gUser.email)
                                            .font(LeafTypography.captionRegular)
                                            .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
                                            .lineLimit(1)
                                    }
                                } else {
                                    Text("Local Account • Not synced")
                                        .font(LeafTypography.captionRegular)
                                        .foregroundStyle(LeafTheme.textTertiary(for: colorScheme))
                                }
                            }
                        }
                        .padding(.vertical, 4)

                        // Google Account Sign In / Status
                        if let gUser = googleUser {
                            HStack {
                                Label("Google Account", systemImage: "person.badge.shield.checkmark.fill")
                                    .foregroundStyle(LeafTheme.textPrimary(for: colorScheme))
                                Spacer()
                                Button("Disconnect") {
                                    triggerHaptic()
                                    Task {
                                        await container.googleAuthService.signOut()
                                        googleUser = nil
                                    }
                                }
                                .font(LeafTypography.captionBold)
                                .foregroundStyle(LeafTheme.expenseCoral)
                            }
                        } else {
                            Button(action: {
                                triggerHaptic()
                                signInWithGoogle()
                            }) {
                                HStack {
                                    Label("Connect Google Account", systemImage: "link.circle.fill")
                                        .foregroundStyle(LeafTheme.brandEmerald)
                                    Spacer()
                                    if isGoogleSigningIn {
                                        ProgressView().tint(LeafTheme.brandEmerald)
                                    }
                                }
                            }
                        }
                    } header: {
                        Text("Profile & Account")
                    }

                    // MARK: - 2. Appearance & Theme
                    Section {
                        Picker("Appearance", selection: $selectedTheme) {
                            Text("System").tag("SYSTEM")
                            Text("Light").tag("LIGHT")
                            Text("Dark").tag("DARK")
                        }
                        .pickerStyle(.segmented)
                        .onChange(of: selectedTheme) { _, newTheme in
                            container.setThemeMode(newTheme)
                        }
                    } header: {
                        Text("Appearance & Theme")
                    }

                    // MARK: - 3. Currency & Regional
                    Section {
                        Picker("Primary Currency", selection: $selectedCurrency) {
                            Text("USD ($)").tag(Currency.usd)
                            Text("EUR (€)").tag(Currency.eur)
                            Text("GBP (£)").tag(Currency.gbp)
                            Text("INR (₹)").tag(Currency.inr)
                            Text("CAD ($)").tag(Currency.cad)
                            Text("AUD ($)").tag(Currency.aud)
                            Text("JPY (¥)").tag(Currency.jpy)
                        }

                        NavigationLink {
                            CurrencySettingsView()
                        } label: {
                            Label("Exchange Rates & Currency Settings", systemImage: "dollarsign.arrow.circlepath")
                                .foregroundStyle(LeafTheme.textPrimary(for: colorScheme))
                        }

                        NavigationLink {
                            TravelWalletsListView()
                        } label: {
                            Label("Travel Wallets & Multi-Currency Trips", systemImage: "airplane.departure")
                                .foregroundStyle(LeafTheme.textPrimary(for: colorScheme))
                        }
                    } header: {
                        Text("Currency & Regional")
                    }

                    // MARK: - 3b. Default Payment Source & Ledgers
                    Section {
                        Picker("Default Source", selection: $defaultTransactionSource) {
                            Text("Cash").tag(PaymentMethod.cash)
                            Text("Account").tag(PaymentMethod.account)
                        }
                        .pickerStyle(.segmented)
                        .onChange(of: defaultTransactionSource) { _, newSource in
                            container.preferencesRepository.setDefaultTransactionSource(newSource)
                        }

                        NavigationLink {
                            LedgersHubView()
                        } label: {
                            Label("Cash & Account Ledgers", systemImage: "creditcard.and.123")
                                .foregroundStyle(LeafTheme.textPrimary(for: colorScheme))
                        }
                    } header: {
                        Text("Default Payment Source")
                    } footer: {
                        Text("Newly created expenses and transactions will automatically preselect this source.")
                    }

                    // MARK: - 4. Google Drive Cloud Backup & Restore
                    Section {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Last Google Drive Backup")
                                    .font(LeafTypography.bodyMedium)
                                    .foregroundStyle(LeafTheme.textPrimary(for: colorScheme))
                                Text(formattedLastBackup)
                                    .font(LeafTypography.captionRegular)
                                    .foregroundStyle(lastBackupTimestamp > 0 ? LeafTheme.brandEmerald : LeafTheme.textTertiary(for: colorScheme))
                            }
                            Spacer()
                            Image(systemName: "icloud.and.arrow.up.fill")
                                .foregroundStyle(LeafTheme.brandEmerald)
                        }

                        Button(action: {
                            triggerHaptic()
                            performGoogleBackup()
                        }) {
                            HStack {
                                Label("Back Up to Google Drive Now", systemImage: "arrow.clockwise.icloud.fill")
                                    .foregroundStyle(LeafTheme.brandEmerald)
                                Spacer()
                                if isBackingUpGoogle {
                                    ProgressView().tint(LeafTheme.brandEmerald)
                                }
                            }
                        }
                        .disabled(isBackingUpGoogle || isRestoringGoogle)

                        Button(action: {
                            triggerHaptic()
                            showRestoreConfirmation = true
                        }) {
                            HStack {
                                Label("Restore from Google Drive", systemImage: "arrow.counterclockwise.icloud.fill")
                                    .foregroundStyle(LeafTheme.textPrimary(for: colorScheme))
                                Spacer()
                                if isRestoringGoogle {
                                    ProgressView().tint(LeafTheme.brandEmerald)
                                }
                            }
                        }
                        .disabled(isBackingUpGoogle || isRestoringGoogle)

                        Toggle("Automatic Daily Cloud Backup", isOn: $autoBackupEnabled)
                            .tint(LeafTheme.brandEmerald)
                            .onChange(of: autoBackupEnabled) { _, val in
                                container.preferencesRepository.setAutomaticBackupEnabled(val)
                            }

                        NavigationLink {
                            BackupRestoreView()
                        } label: {
                            Label("Local AES-GCM Encrypted Backups", systemImage: "lock.shield.fill")
                                .foregroundStyle(LeafTheme.textPrimary(for: colorScheme))
                        }
                    } header: {
                        Text("Cloud Backup & Google Drive")
                    } footer: {
                        Text("Cloud backups are stored in your private Google Drive appDataFolder, isolated from third-party access.")
                    }

                    // MARK: - 5. Security & App Lock
                    Section {
                        Toggle("App Lock", isOn: Binding(
                            get: { appLockEnabled },
                            set: { newValue in
                                if newValue {
                                    isAppLockSetupPresented = true
                                } else {
                                    isDisableAppLockPresented = true
                                }
                            }
                        ))
                        .tint(LeafTheme.brandEmerald)

                        if appLockEnabled {
                            Button {
                                isChangePinPresented = true
                            } label: {
                                HStack {
                                    Label("Change 6-Digit PIN", systemImage: "key.fill")
                                        .foregroundStyle(LeafTheme.textPrimary(for: colorScheme))
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundStyle(LeafTheme.textTertiary(for: colorScheme))
                                }
                            }

                            if container.appLockService.availableBiometricType != .none {
                                Toggle("Unlock with \(container.appLockService.availableBiometricType.rawValue)", isOn: Binding(
                                    get: { biometricEnabled },
                                    set: { newValue in
                                        biometricEnabled = newValue
                                        container.appLockService.setBiometricEnabled(newValue)
                                    }
                                ))
                                .tint(LeafTheme.brandEmerald)
                            }

                            Picker("Auto-Lock Timeout", selection: $autoLockDurationSeconds) {
                                Text("Immediately").tag(Int64(0))
                                Text("After 1 minute").tag(Int64(60))
                                Text("After 5 minutes").tag(Int64(300))
                                Text("After 15 minutes").tag(Int64(900))
                            }
                            .onChange(of: autoLockDurationSeconds) { _, secs in
                                container.appLockService.setAutoLockTimeout(AutoLockTimeout(rawValue: secs) ?? .immediately)
                            }
                        }

                        NavigationLink {
                            PrivacyDashboardView()
                        } label: {
                            Label("Privacy & Security Dashboard", systemImage: "hand.raised.fill")
                                .foregroundStyle(LeafTheme.textPrimary(for: colorScheme))
                        }
                    } header: {
                        Text("Security & Privacy")
                    } footer: {
                        Text(appLockEnabled ? "Leaf requires authentication to open. PIN is stored in your secure device Keychain." : "Protect access to your personal financial records with a 6-digit PIN.")
                    }

                    // MARK: - 6. Notifications & Daily Reminders
                    Section {
                        Toggle("Daily Expense Reminder", isOn: $dailyReminderEnabled)
                            .tint(LeafTheme.brandEmerald)
                            .onChange(of: dailyReminderEnabled) { _, enabled in
                                saveReminderSettings(enabled: enabled)
                            }

                        if dailyReminderEnabled {
                            DatePicker(
                                "Reminder Time",
                                selection: $reminderTime,
                                displayedComponents: .hourAndMinute
                            )
                            .onChange(of: reminderTime) { _, _ in
                                saveReminderSettings(enabled: dailyReminderEnabled)
                            }
                        }

                        NavigationLink {
                            RecurringHubView()
                        } label: {
                            Label("Bill Reminders & Subscriptions", systemImage: "calendar.badge.clock")
                                .foregroundStyle(LeafTheme.textPrimary(for: colorScheme))
                        }
                    } header: {
                        Text("Notifications & Reminders")
                    }

                    // MARK: - 7. Financial Management & Tools
                    Section {
                        NavigationLink {
                            StatementsView()
                        } label: {
                            Label("Financial Statements & CSV/PDF Export", systemImage: "doc.text.fill")
                                .foregroundStyle(LeafTheme.textPrimary(for: colorScheme))
                        }

                        NavigationLink {
                            ToolsLandingView()
                        } label: {
                            Label("Financial Calculators (EMI, SIP, GST)", systemImage: "function")
                                .foregroundStyle(LeafTheme.textPrimary(for: colorScheme))
                        }

                        NavigationLink {
                            WidgetShowcaseView()
                        } label: {
                            Label("Home Screen Widgets & Preview", systemImage: "square.grid.2x2")
                                .foregroundStyle(LeafTheme.textPrimary(for: colorScheme))
                        }
                    } header: {
                        Text("Tools & Export")
                    }

                    // MARK: - 8. About Leaf
                    Section {
                        HStack(spacing: 12) {
                            Image("LeafLogo")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 36, height: 36)

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Leaf for iOS")
                                    .font(.system(size: 16, weight: .bold, design: .rounded))
                                    .foregroundStyle(LeafTheme.textPrimary(for: colorScheme))
                                let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
                                let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
                                Text("Version \(appVersion) (\(buildNumber))")
                                    .font(LeafTypography.captionRegular)
                                    .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
                            }
                        }
                        .padding(.vertical, 4)

                        HStack {
                            Text("Database Engine")
                            Spacer()
                            Text("SQLite + GRDB (Hardware Encrypted)")
                                .font(LeafTypography.captionBold)
                                .foregroundStyle(LeafTheme.brandEmerald)
                        }

                        HStack {
                            Text("Developer")
                            Spacer()
                            Text("Vinay Nalavade")
                                .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
                        }
                    } header: {
                        Text("About Leaf")
                    }

                    // MARK: - 9. Save Changes CTA
                    Section {
                        Button(action: savePreferences) {
                            HStack {
                                Spacer()
                                Text(isSaved ? "Saved Successfully!" : "Save Changes")
                                    .font(LeafTypography.titleMedium)
                                    .foregroundStyle(isSaved ? LeafTheme.brandEmerald : LeafTheme.accent(for: colorScheme))
                                Spacer()
                            }
                        }
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        savePreferences()
                        dismiss()
                    }
                    .foregroundStyle(LeafTheme.brandEmerald)
                    .fontWeight(.bold)
                }
            }
            .task {
                loadCurrentPreferences()
            }
            .sheet(isPresented: $isAppLockSetupPresented) {
                AppLockSetupSheet(onSetupCompleted: {
                    loadCurrentPreferences()
                })
            }
            .sheet(isPresented: $isDisableAppLockPresented) {
                DisableAppLockSheet(onDisabled: {
                    loadCurrentPreferences()
                })
            }
            .sheet(isPresented: $isChangePinPresented) {
                ChangePinSheet()
            }
            .confirmationDialog(
                "Restore from Google Drive?",
                isPresented: $showRestoreConfirmation,
                titleVisibility: .visible
            ) {
                Button("Restore Backup", role: .destructive) {
                    performGoogleRestore()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Restoring will replace current local transactions and budgets with your Google Drive backup. Existing statement documents are preserved.")
            }
            .alert(alertTitle, isPresented: $showAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(alertMessage)
            }
        }
    }

    // MARK: - Actions

    private func loadCurrentPreferences() {
        let prefs = container.preferencesRepository.getUserPreferences()
        self.profileName = prefs.profileName ?? ""
        self.selectedCurrency = prefs.currency
        self.selectedTheme = prefs.themeMode
        self.dailyReminderEnabled = prefs.dailyReminderEnabled
        self.autoBackupEnabled = prefs.automaticBackupEnabled
        self.defaultTransactionSource = prefs.defaultTransactionSource
        self.appLockEnabled = container.appLockService.isAppLockEnabled && container.appLockService.isPinConfigured
        self.biometricEnabled = container.appLockService.isBiometricEnabled
        self.autoLockDurationSeconds = prefs.autoLockDurationSeconds
        self.lastBackupTimestamp = prefs.lastBackupTimestamp

        let calendar = Calendar.current
        self.reminderTime = calendar.date(bySettingHour: prefs.dailyReminderHour, minute: prefs.dailyReminderMinute, second: 0, of: Date()) ?? Date()

        self.googleUser = container.googleAuthService.currentUser
    }

    private func savePreferences() {
        container.preferencesRepository.setProfileName(profileName)
        container.preferencesRepository.setCurrencyCode(selectedCurrency.code)
        container.setThemeMode(selectedTheme)
        container.preferencesRepository.setAutoLockDurationSeconds(autoLockDurationSeconds)
        container.preferencesRepository.setAutomaticBackupEnabled(autoBackupEnabled)
        container.preferencesRepository.setDefaultTransactionSource(defaultTransactionSource)
        saveReminderSettings(enabled: dailyReminderEnabled)

        // Trigger widget update with new user preferences / currency
        let summary = container.transactionRepository
        Task {
            let prefs = container.preferencesRepository.getUserPreferences()
            let snapshot = WidgetDataManager.shared.loadSnapshot()
            let updated = WidgetFinancialSnapshot(
                currentBalanceSubunits: snapshot.currentBalanceSubunits,
                monthlyIncomeSubunits: snapshot.monthlyIncomeSubunits,
                monthlyExpenseSubunits: snapshot.monthlyExpenseSubunits,
                currencyCode: prefs.currencyCode,
                budgetLimitSubunits: snapshot.budgetLimitSubunits,
                budgetSpentSubunits: snapshot.budgetSpentSubunits,
                budgetProgressRatio: snapshot.budgetProgressRatio,
                lastUpdated: Date()
            )
            WidgetDataManager.shared.saveSnapshot(updated)
        }

        self.isSaved = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            self.isSaved = false
        }
    }

    private func saveReminderSettings(enabled: Bool) {
        let cal = Calendar.current
        let hour = cal.component(.hour, from: reminderTime)
        let min = cal.component(.minute, from: reminderTime)
        container.preferencesRepository.setDailyReminder(enabled: enabled, hour: hour, minute: min)
        if enabled {
            container.notificationService.scheduleDailyExpenseReminder(hour: hour, minute: min)
        } else {
            container.notificationService.cancelDailyExpenseReminder()
        }
    }

    private func signInWithGoogle() {
        isGoogleSigningIn = true
        Task {
            do {
                let user = try await container.googleAuthService.signIn()
                self.googleUser = user
                self.alertTitle = "Connected"
                self.alertMessage = "Signed in as \(user.email). Google Drive sync is active."
                self.showAlert = true
            } catch {
                self.alertTitle = "Sign In Failed"
                self.alertMessage = error.localizedDescription
                self.showAlert = true
            }
            self.isGoogleSigningIn = false
        }
    }

    private func performGoogleBackup() {
        isBackingUpGoogle = true
        Task {
            do {
                let meta = try await container.googleDriveBackupService.performGoogleDriveBackup()
                self.lastBackupTimestamp = meta.modifiedTime
                self.alertTitle = "Backup Succeeded"
                self.alertMessage = "Uploaded \(meta.formattedSize) to Google Drive appDataFolder at \(meta.formattedDate)."
                self.showAlert = true
            } catch {
                self.alertTitle = "Backup Failed"
                self.alertMessage = error.localizedDescription
                self.showAlert = true
            }
            self.isBackingUpGoogle = false
        }
    }

    private func performGoogleRestore() {
        isRestoringGoogle = true
        Task {
            do {
                let summary = try await container.googleDriveBackupService.performGoogleDriveRestore()
                self.alertTitle = "Restoration Complete"
                self.alertMessage = "Restored \(summary.transactionCount) transactions, \(summary.budgetCount) budgets, and \(summary.splitExpenseCount) splits from Google Drive."
                self.showAlert = true
                loadCurrentPreferences()
            } catch {
                self.alertTitle = "Restoration Failed"
                self.alertMessage = error.localizedDescription
                self.showAlert = true
            }
            self.isRestoringGoogle = false
        }
    }
}
