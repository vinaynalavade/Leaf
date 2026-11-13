# Leaf Architecture: Xcode Project Structure & File Layout

## 1. Executive Summary
This document provides the blueprint for the native iOS Xcode project structure for Leaf. It is organized to mirror the Clean Architecture principles of the Android application while following modern Apple engineering best practices.

---

## 2. Recommended Directory & Group Hierarchy

```
Leaf/
├── App/
│   ├── LeafApp.swift                         // App Entry Point (@main)
│   ├── AppContainer.swift                    // Dependency Injection Container
│   ├── SceneDelegate.swift                   // Window lifecycle & recents privacy blur
│   └── Configuration/
│       ├── Info.plist                        // Bundle config, permissions, shortcuts
│       └── Leaf.entitlements                 // Keychain sharing, iCloud Drive, Face ID
│
├── Core/
│   ├── Models/
│   │   ├── Amount.swift                      // Subunit Int64 wrapper with operators
│   │   ├── Currency.swift                    // 9 currencies, formatters, decimal factors
│   │   ├── FinancialEnums.swift              // TransactionType, PaymentMethod, etc.
│   │   └── AppResult.swift                   // Success / Error sealed result model
│   ├── Calculators/
│   │   ├── FinancialCalculatorEngine.swift   // EMI, SIP, FD, RD, GST, Discount
│   │   ├── SplitCalculationEngine.swift      // Equal, Custom, Itemized, Zero-sum
│   │   ├── NetBalanceEngine.swift            // Pairwise directional debt simplification
│   │   └── EasterEggEngine.swift             // Observational micro-delight predicates
│   ├── Security/
│   │   ├── KeychainManager.swift             // Secure PIN salt & hash vault
│   │   ├── SecurePinManager.swift            // SHA-256 + 16-byte salt verification
│   │   └── AppLockManager.swift              // Biometrics (LAContext) & rate-limiting
│   └── Utils/
│       ├── DateTimeUtils.swift               // Epoch conversions & date formatting
│       ├── PdfStatementGenerator.swift       // Bank-grade vector PDF rendering (PDFKit)
│       ├── QrCodeGenerator.swift             // CIFilter UPI QR code generator
│       └── WhatsAppShareHelper.swift         // URL-encoded breakdown message builder
│
├── Data/
│   ├── Database/
│   │   ├── LeafDatabase.swift                // GRDB DatabasePool / SQLite connection
│   │   ├── DatabaseMigrations.swift          // SQL migrations v1 to v10
│   │   └── Records/                          // SQLite record representations
│   │       ├── TransactionRecord.swift
│   │       ├── CategoryRecord.swift
│   │       ├── RecurringRecord.swift
│   │       ├── SplitExpenseRecord.swift
│   │       ├── SplitParticipantRecord.swift
│   │       ├── SplitGroupRecord.swift
│   │       ├── BudgetRecord.swift
│   │       ├── SavingsGoalRecord.swift
│   │       ├── SavingsContributionRecord.swift
│   │       └── ReminderRecord.swift
│   ├── Repositories/
│   │   ├── TransactionRepositoryImpl.swift
│   │   ├── CategoryRepositoryImpl.swift
│   │   ├── SplitRepositoryImpl.swift
│   │   ├── BudgetRepositoryImpl.swift
│   │   ├── SavingsGoalRepositoryImpl.swift
│   │   ├── ReminderRepositoryImpl.swift
│   │   └── RecurringRepositoryImpl.swift
│   ├── Preferences/
│   │   ├── UserPreferencesStore.swift        // UserDefaults wrapper with @AppStorage
│   │   └── PreferenceKeys.swift
│   └── Sync/
│       ├── BackupRestoreManager.swift        // JSON v2 export / import engine
│       ├── ICloudSyncService.swift           // Native Apple iCloud Drive vault
│       └── GoogleDriveService.swift          // Cross-platform Drive sync (optional)
│
├── Domain/
│   ├── Models/
│   │   ├── Transaction.swift
│   │   ├── Category.swift
│   │   ├── SplitExpense.swift
│   │   ├── SplitParticipant.swift
│   │   ├── SplitGroup.swift
│   │   ├── Budget.swift
│   │   ├── SavingsGoal.swift
│   │   ├── Reminder.swift
│   │   └── UserPreferences.swift
│   ├── Repositories/                         // Protocol contracts
│   │   ├── TransactionRepositoryProtocol.swift
│   │   ├── CategoryRepositoryProtocol.swift
│   │   ├── SplitRepositoryProtocol.swift
│   │   ├── BudgetRepositoryProtocol.swift
│   │   ├── SavingsGoalRepositoryProtocol.swift
│   │   └── ReminderRepositoryProtocol.swift
│   └── UseCases/                             // Business workflow interactors
│       ├── Transactions/
│       │   ├── SaveTransactionUseCase.swift
│       │   ├── DeleteTransactionUseCase.swift
│       │   └── GetFinancialSummaryUseCase.swift
│       ├── Categories/
│       │   ├── SaveCategoryUseCase.swift
│       │   └── DeleteCategoryUseCase.swift
│       ├── Split/
│       │   ├── SaveSplitExpenseUseCase.swift
│       │   └── SettleParticipantUseCase.swift
│       ├── Planning/
│       │   ├── SaveBudgetUseCase.swift
│       │   └── AddSavingsContributionUseCase.swift
│       └── Reminders/
│           ├── ScheduleReminderUseCase.swift
│           └── MarkReminderPaidUseCase.swift
│
├── Presentation/
│   ├── Theme/
│   │   ├── Colors.swift                      // Obsidian, Canvas, Emerald, Rose, Swatches
│   │   ├── Typography.swift                  // Dynamic type styles, monospaced digits
│   │   ├── Shapes.swift                      // Continuous squircles, capsules, sheets
│   │   ├── Spacing.swift                     // Standard 4pt/8pt grid spacing constants
│   │   └── Gradients.swift                   // Hero Emerald & Obsidian gradients
│   ├── Components/
│   │   ├── BalanceHeroCard.swift
│   │   ├── CategoryIconBadge.swift
│   │   ├── TransactionRowItem.swift
│   │   ├── CategoryDonutChart.swift
│   │   ├── QuickActionPills.swift
│   │   ├── BudgetProgressBar.swift
│   │   ├── SettingsTile.swift
│   │   └── EmptyStateView.swift
│   └── Features/
│       ├── Root/
│       │   ├── RootContentView.swift         // Manages AppLock barrier vs MainTabHost
│       │   └── MainTabHostView.swift         // 5-tab persistent bottom bar
│       ├── Dashboard/
│       ├── Transactions/
│       ├── Split/
│       ├── Planning/
│       ├── Insights/
│       ├── Calendar/
│       ├── Recurring/
│       ├── Reminders/
│       ├── Calculators/
│       ├── Settings/
│       ├── Onboarding/
│       └── AppLock/
│
├── LeafWidgets/                              // WidgetKit Target
│   ├── LeafWidgetsBundle.swift
│   ├── FinancialOverviewWidget.swift         // Medium 4x2 widget
│   ├── TodayExpenseWidget.swift              // Small 2x1 widget
│   └── WidgetTimelineProvider.swift
│
├── Resources/
│   ├── Assets.xcassets                       // Brand logo, app icons, color assets
│   ├── Localizable.xcstrings                 // String catalogs for EN, HI, MR
│   └── Preview Content/                      // Sample mock data for SwiftUI previews
│
└── Tests/
    ├── UnitTests/
    │   ├── AmountTests.swift
    │   ├── FinancialCalculatorEngineTests.swift
    │   ├── SplitCalculationEngineTests.swift
    │   ├── NetBalanceEngineTests.swift
    │   ├── SaveCategoryUseCaseTests.swift
    │   └── MigrationTests.swift
    └── UITests/
        ├── OnboardingFlowTests.swift
        ├── TransactionLoggingFlowTests.swift
        └── SplitBillFlowTests.swift
```

