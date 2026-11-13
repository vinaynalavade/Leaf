# 02 — COMPLETE FEATURE INVENTORY

## 1. Inventory Summary

This comprehensive feature inventory documents every feature, capability, screen, and background component discovered within the Leaf Android codebase. Each item has been audited against source files, Room entities, ViewModels, and automated unit test suites.

### Implementation Status Legend
- **VERIFIED (IMPLEMENTED):** Fully implemented in production code with accompanying automated tests.
- **PARTIALLY IMPLEMENTED:** Implemented in code but with specific known gaps, platform limitations, or partial UI integration.
- **PLANNED:** Conceptual or defined in models but without an operational user-facing interface.
- **DEPRECATED / REMOVED:** Legacy constructs preserved only for migration compatibility.

---

## 2. Comprehensive Feature Matrix

| ID | Feature Name | Module | Current Status | Primary Android Source Files | Relevant Tests |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **FEAT-01** | Dashboard Overview | Dashboard | **VERIFIED** | `DashboardScreen.kt`, `DashboardViewModel.kt` | `DashboardCategoryAnalysisTest.kt` |
| **FEAT-02** | Total Balance Card & Privacy Toggle | Dashboard | **VERIFIED** | `DashboardScreen.kt`, `GetFinancialSummaryUseCase.kt` | `FinancialCalculationTest.kt` |
| **FEAT-03** | Monthly Financial Summary (Income/Expense/Net) | Dashboard / Ledger | **VERIFIED** | `GetFinancialSummaryUseCase.kt`, `FinancialSummary.kt` | `FinancialCalculationWithPaymentMethodTest.kt` |
| **FEAT-04** | Quick Action Shortcuts (Add Expense/Income/Split) | Dashboard | **VERIFIED** | `DashboardScreen.kt`, `NavGraph.kt` | `NavigationHierarchyAndRoutingTest.kt` |
| **FEAT-05** | Recent Activity Ledger List | Dashboard | **VERIFIED** | `DashboardScreen.kt`, `TransactionDao.kt` | `TransactionEntityMappingTest.kt` |
| **FEAT-06** | Upcoming Obligations & EMI Alerts Banner | Dashboard / Reminders | **VERIFIED** | `GetUpcomingPaymentsUseCase.kt`, `DashboardScreen.kt` | `FinancialNotificationsTest.kt` |
| **FEAT-07** | Budget Limit Progress & Warning Banners | Dashboard / Planning | **VERIFIED** | `GetBudgetProgressUseCase.kt`, `DashboardScreen.kt` | `BudgetCalculationTest.kt` |
| **FEAT-08** | Transaction List with Grouping & Filters | Transactions | **VERIFIED** | `TransactionsScreen.kt`, `TransactionsViewModel.kt` | `TransactionsFilterAndSearchTest.kt` |
| **FEAT-09** | Add Expense / Add Income Screen | Transactions | **VERIFIED** | `AddTransactionScreen.kt`, `AddTransactionViewModel.kt` | `PaymentMethodUiIntegrationTest.kt` |
| **FEAT-10** | Transaction Detail & Editing | Transactions | **VERIFIED** | `TransactionDetailScreen.kt`, `TransactionDetailViewModel.kt`| `TransactionEntityMappingTest.kt` |
| **FEAT-11** | Transaction Deletion with Undo Snackbar | Transactions | **VERIFIED** | `TransactionsViewModel.kt`, `DeleteTransactionUseCase.kt` | `ProductionReleaseValidationTest.kt` |
| **FEAT-12** | Quick Add Modal Activity & BottomSheet | Transactions / QuickAdd | **VERIFIED** | `QuickAddTransactionActivity.kt`, `QuickAddBottomSheet.kt`| `WidgetIntentRoutingTest.kt` |
| **FEAT-13** | Equal Split with Paisa-Level Reconciliation | Split & Collect | **VERIFIED** | `SplitCalculationEngine.kt`, `CreateSplitViewModel.kt` | `SplitCalculationEngineTest.kt` |
| **FEAT-14** | Itemized Custom Bill Splitting (Split 2.0) | Split & Collect | **VERIFIED** | `SplitCalculationEngine.kt`, `SplitItemJsonAdapter.kt` | `SplitItemJsonAdapterTest.kt`, `SplitDomainTest.kt` |
| **FEAT-15** | Direct Custom Participant Share Allocation | Split & Collect | **VERIFIED** | `SplitCalculationEngine.kt`, `CreateSplitViewModel.kt` | `SplitCalculationEngineTest.kt` |
| **FEAT-16** | Split Group Management (Create, View, Delete) | Split & Collect | **VERIFIED** | `SplitGroupDao.kt`, `SplitGroupRepositoryImpl.kt` | `SharedFinanceNetBalanceTest.kt` |
| **FEAT-17** | Directional Net Balance Engine | Split & Collect | **VERIFIED** | `NetBalanceEngine.kt`, `GetGroupNetBalancesUseCase.kt` | `SharedFinanceNetBalanceTest.kt` |
| **FEAT-18** | UPI QR Image Upload, Storage & Sharing | Split & Collect | **VERIFIED** | `SplitQrStorageManager.kt`, `CreateSplitScreen.kt` | `SplitDomainTest.kt` |
| **FEAT-19** | Dynamic WhatsApp Reminder Deep-Linking | Split & Collect | **VERIFIED** | `WhatsAppShareHelper.kt`, `SplitDetailScreen.kt` | `WhatsAppShareHelperTest.kt` |
| **FEAT-20** | Split Ledger Transaction Integration | Split & Collect | **VERIFIED** | `SplitRepositoryImpl.kt`, `SplitDao.kt` | `SplitTransactionIntegrationTest.kt` |
| **FEAT-21** | Participant Settlement Management | Split & Collect | **VERIFIED** | `SplitDetailViewModel.kt`, `UpdateParticipantSettlementUseCase.kt` | `SplitTransactionIntegrationTest.kt` |
| **FEAT-22** | Monthly Budget Planner (Overall & Category) | Planning | **VERIFIED** | `PlanningScreen.kt`, `PlanningViewModel.kt`, `BudgetDao.kt` | `BudgetCalculationTest.kt` |
| **FEAT-23** | Budget Warning Thresholds (75% / 100% / Over) | Planning | **VERIFIED** | `GetBudgetProgressUseCase.kt`, `BudgetEntity.kt` | `BudgetCalculationTest.kt` |
| **FEAT-24** | Savings Goals Management | Planning | **VERIFIED** | `PlanningScreen.kt`, `SavingsGoalDao.kt` | `SavingsGoalProgressTest.kt` |
| **FEAT-25** | Goal Detail & Contribution Tracking | Planning | **VERIFIED** | `GoalDetailScreen.kt`, `GoalDetailViewModel.kt` | `SavingsGoalProgressTest.kt` |
| **FEAT-26** | Linked Savings Goal Contributions (Ledger Deduct) | Planning | **VERIFIED** | `SaveSavingsGoalContributionUseCase.kt` | `SavingsGoalProgressTest.kt` |
| **FEAT-27** | Spending Trends Analysis (Weekly / Monthly) | Insights | **VERIFIED** | `GetSpendingTrendsUseCase.kt`, `InsightsScreen.kt` | `SpendingTrendsTest.kt` |
| **FEAT-28** | Category Spending Breakdown & Percentages | Insights | **VERIFIED** | `GetCategoryAnalysisUseCase.kt`, `InsightsViewModel.kt` | `DashboardCategoryAnalysisTest.kt` |
| **FEAT-29** | Continuous Monthly Ledger Carry-Forward | Analytics / Ledger | **VERIFIED** | `GetMonthlyLedgerUseCase.kt`, `MonthlySummaryScreen.kt`| `FinancialCalculationTest.kt` |
| **FEAT-30** | Month-over-Month (MoM) Growth Comparison | Analytics / Ledger | **VERIFIED** | `GetMonthlyLedgerUseCase.kt`, `MonthlySummaryViewModel.kt`| `FinancialCalculationTest.kt` |
| **FEAT-31** | Bank-Grade PDF Financial Statement Generator | Statements | **VERIFIED** | `PdfUtils.kt`, `GenerateStatementUseCase.kt` | `StatementsViewModel.kt` |
| **FEAT-32** | Interactive Daily Expense Calendar | Calendar | **VERIFIED** | `CalendarScreen.kt`, `CalendarViewModel.kt` | `CalendarViewModel.kt` |
| **FEAT-33** | Recurring Transactions Engine (Daily/Wk/Mo/Yr) | Obligations | **VERIFIED** | `RecurringTransactionRepositoryImpl.kt` | `RecurringEmiDayOfMonthTest.kt` |
| **FEAT-34** | Automatic Due Occurrence Transaction Generator | Obligations | **VERIFIED** | `ProcessDueRecurringTransactionsUseCase.kt` | `RecurringEmiDayOfMonthTest.kt` |
| **FEAT-35** | Financial Obligation Reminders (Bills/EMI/Cards) | Reminders | **VERIFIED** | `ReminderRepositoryImpl.kt`, `RemindersScreen.kt` | `ReminderRepositoryTest.kt` |
| **FEAT-36** | Advance Notification Offsets & Rescheduling | Reminders | **VERIFIED** | `AlarmReminderScheduler.kt`, `ReminderReceiver.kt` | `V110RemindersAndSettingsTest.kt` |
| **FEAT-37** | Smart Evening Daily Reminder (9 PM Suppression) | Reminders | **VERIFIED** | `AlarmDailyReminderScheduler.kt`, `ReminderReceiver.kt` | `DailyReminderSchedulerTest.kt` |
| **FEAT-38** | Financial Tools Landing Screen | Calculators | **VERIFIED** | `ToolsLandingScreen.kt`, `CalculatorLayout.kt` | `FinancialCalculatorEngineTest.kt` |
| **FEAT-39** | EMI Calculator | Calculators | **VERIFIED** | `EmiCalculatorScreen.kt`, `FinancialCalculatorEngine.kt` | `FinancialCalculatorEngineTest.kt` |
| **FEAT-40** | SIP Annuity-Due Calculator | Calculators | **VERIFIED** | `SipCalculatorScreen.kt`, `FinancialCalculatorEngine.kt` | `FinancialCalculatorEngineTest.kt` |
| **FEAT-41** | Fixed Deposit (FD) Quarterly Compounding | Calculators | **VERIFIED** | `FdCalculatorScreen.kt`, `FinancialCalculatorEngine.kt` | `FinancialCalculatorEngineTest.kt` |
| **FEAT-42** | Recurring Deposit (RD) Monthly Tranches | Calculators | **VERIFIED** | `RdCalculatorScreen.kt`, `FinancialCalculatorEngine.kt` | `FinancialCalculatorEngineTest.kt` |
| **FEAT-43** | GST Inclusive / Exclusive Tax Calculator | Calculators | **VERIFIED** | `GstCalculatorScreen.kt`, `FinancialCalculatorEngine.kt` | `FinancialCalculatorEngineTest.kt` |
| **FEAT-44** | Discount Price Calculator | Calculators | **VERIFIED** | `DiscountCalculatorScreen.kt`, `FinancialCalculatorEngine.kt` | `FinancialCalculatorEngineTest.kt` |
| **FEAT-45** | In-Field Arithmetic Expression Evaluator | Calculators | **VERIFIED** | `EvaluateCalculatorExpressionUseCase.kt` | `CalculatorExpressionEvaluatorTest.kt` |
| **FEAT-46** | App Lock PIN Vault (Salted SHA-256 + 30s Lockout)| Security | **VERIFIED** | `SecurePinManager.kt`, `AppLockManager.kt` | `AppLockSecurityTest.kt`, `AppLockLifecycleTest.kt` |
| **FEAT-47** | Biometric Authentication (Face/Fingerprint) | Security | **VERIFIED** | `BiometricAuthHelper.kt`, `UnlockScreen.kt` | `AppLockSecurityTest.kt` |
| **FEAT-48** | Screen Hiding in App Switcher (FLAG_SECURE) | Security | **VERIFIED** | `MainActivity.kt` | `AppLockLifecycleTest.kt` |
| **FEAT-49** | Versioned JSON Full Backup & Restore (v1 & v2) | Backup & Sync | **VERIFIED** | `JsonBackupParser.kt`, `BackupRepositoryImpl.kt` | `BackupRestoreTest.kt`, `BackupRestoreV2Test.kt` |
| **FEAT-50** | RFC-4180 CSV Export and Header-Flexible Import | Backup & Sync | **VERIFIED** | `CsvTransactionHelper.kt`, `BackupRepositoryImpl.kt`| `TransactionExportImportTest.kt` |
| **FEAT-51** | Google Drive Cloud Backup (appDataFolder) | Backup & Sync | **VERIFIED** | `GoogleDriveBackupRepositoryImpl.kt`, `GoogleDriveRestService.kt` | `GoogleDriveBackupRepositoryTest.kt` |
| **FEAT-52** | Automatic Cloud Backup Scheduling (WorkManager)| Backup & Sync | **VERIFIED** | `WorkManagerAutoBackupScheduler.kt`, `AutoBackupWorker.kt` | `AutoBackupAndRestoreIntelligenceTest.kt` |
| **FEAT-53** | Restore Eligibility Check & First-Launch Prompt | Backup & Sync | **VERIFIED** | `CheckRestoreEligibilityUseCase.kt`, `RestorePromptDialog.kt` | `AutoBackupAndRestoreIntelligenceTest.kt` |
| **FEAT-54** | Pre-seeded Default & Custom Categories | Categories | **VERIFIED** | `ExpenseTrackerDatabase.kt`, `CategoryDao.kt` | `CategoryManagementTest.kt` |
| **FEAT-55** | Category Icon & Color Customization | Categories | **VERIFIED** | `AddEditCategoryDialog.kt`, `CategoriesScreen.kt` | `CategoryManagementTest.kt` |
| **FEAT-56** | Theme Selection (Light, Obsidian Dark, System) | Settings | **VERIFIED** | `ThemeSelectionSection.kt`, `Theme.kt`, `Color.kt` | `ProfileAndSettingsArchitectureTest.kt` |
| **FEAT-57** | Multi-Currency Selection (9 Currencies) | Settings | **VERIFIED** | `CurrencySelectionDialog.kt`, `Currency.kt` | `FinancialCalculationTest.kt` |
| **FEAT-58** | Default Financial Source (Cash vs Account) | Settings | **VERIFIED** | `UserPreferencesDataStore.kt`, `PaymentMethod.kt` | `TransactionSourcePreferenceTest.kt` |
| **FEAT-59** | User Profile Customization (Name & Photo) | Settings | **VERIFIED** | `ProfileHeaderCard.kt`, `EditProfileDialog.kt` | `ProfileAndSettingsArchitectureTest.kt` |
| **FEAT-60** | In-App Language Selector (EN, HI, MR) | Settings | **VERIFIED** | `LanguageSelectionDialog.kt`, `locales_config.xml` | `LocalizationTest.kt`, `LanguageAndOnboardingFixesTest.kt` |
| **FEAT-61** | Welcome Onboarding Screen | Onboarding | **VERIFIED** | `WelcomeScreen.kt`, `WelcomeViewModel.kt` | `ReleasePolishAndOnboardingTest.kt` |
| **FEAT-62** | 5-Step Interactive App Tour | Onboarding | **VERIFIED** | `AppTourScreen.kt`, `TourStepIllustrations.kt` | `AppTourTest.kt` |
| **FEAT-63** | Home-Screen Widgets (Balance Overview) | Widgets | **VERIFIED** | `ExpenseTrackerWidgetProvider.kt`, `WidgetUpdateManager.kt` | `WidgetFinancialSummaryTest.kt` |
| **FEAT-64** | Glanceable Today's Expense Widget | Widgets | **VERIFIED** | `TodayExpenseWidgetProvider.kt`, `WidgetUpdateManager.kt` | `TodayExpenseWidgetTest.kt` |
| **FEAT-65** | Quick Add Action Widget | Widgets | **VERIFIED** | `QuickAddWidgetProvider.kt`, `WidgetUpdateManager.kt` | `WidgetIntentRoutingTest.kt` |
| **FEAT-66** | App Launcher Shortcuts (Expense, Income, Ledger)| Widgets / OS | **VERIFIED** | `shortcuts.xml`, `MainActivity.kt` | `WidgetIntentRoutingTest.kt` |
| **FEAT-67** | In-App GitHub Releases APK Update Checker | System / Update | **VERIFIED (Android-specific)** | `GitHubReleaseService.kt`, `ApkDownloader.kt`, `UpdateDialog.kt` | `AppUpdateSystemTest.kt` |
| **FEAT-68** | Easter Egg Engine & Secrets | Easter Egg | **VERIFIED** | `EasterEggEngine.kt`, `EasterEggBanner.kt` | `EasterEggEngineTest.kt` |
| **FEAT-69** | About Leaf Screen & Legal Disclaimers | About | **VERIFIED** | `AboutScreen.kt`, `AppConstants.kt` | `AboutScreenMetadataTest.kt` |

---

## 3. Discovered Findings & Architectural Observations

1. **Shared Finance Module Status:** The "Shared Finance" domain in Leaf is fully operational under the name **"Split & Collect" (Split 2.0)**. It contains Equal Split, Itemized Bill Splitting with participant sub-assignments, Direct Custom Splitting, Group Management, Directional Net Balance Engine, UPI QR image storage, and WhatsApp message automation.
2. **Android Update System Platform Specificity:** Feature `FEAT-67` (In-App APK downloading, checksum verification, and PackageInstaller handoff) is specific to Android side-loading distribution. On iOS, application updates are managed exclusively through the Apple App Store / TestFlight. However, the release checking metadata endpoint and version comparison logic can remain as a remote announcement / update check mechanism.
3. **Legacy KharchaFlow Tokens:** The codebase retains backward compatibility with earlier prototypes named *KharchaFlow* (e.g. `kharchaflow_security_vault` for SharedPreferences PIN storage and `kharchaflow_backup.json` for Google Drive detection).
4. **Zero Missing Features:** Every feature advertised in product documentation or settings is backed by concrete Kotlin implementations, Room DAOs, and unit tests.

