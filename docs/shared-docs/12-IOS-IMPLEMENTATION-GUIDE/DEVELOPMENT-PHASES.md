# Leaf Master iOS Implementation: Phased Development Roadmap

## 1. Executive Summary
This document provides the step-by-step phased execution plan for implementing Leaf natively on iOS. Development must proceed sequentially through these 8 phases to guarantee stable foundations, test-driven validation, and seamless feature integration.

---

## 2. Phase-by-Phase Roadmap

### Phase 1: Project Scaffolding & Core Primitives
- **Deliverables**:
  1. Initialize Xcode project targeting iOS 17.0+ inside `ios/Leaf.xcodeproj`.
  2. Implement `Amount` value type with subunit operators (`+`, `-`, `*`, `Comparable`).
  3. Implement `Currency` enum supporting 9 global currencies with formatting algorithms.
  4. Implement `AppResult<T>` and financial enumerations (`TransactionType`, `PaymentMethod`, etc.).
  5. Implement Design System tokens (`Colors.swift`, `Typography.swift`, `Shapes.swift`, `Spacing.swift`, `Gradients.swift`).
- **Validation Milestone**: Unit tests for `Amount` string parsing and currency formatting pass 100%.

---

### Phase 2: Database Layer & Migrations (GRDB Schema v10)
- **Deliverables**:
  1. Integrate `GRDB.swift` via Swift Package Manager.
  2. Implement `LeafDatabase.swift` configuring `DatabasePool` in WAL mode.
  3. Implement `DatabaseMigrations.swift` replicating migrations 1 through 10.
  4. Implement all 10 record structs (`TransactionRecord`, `CategoryRecord`, etc.) with table associations.
  5. Implement database callback seeding the exact 20 default categories.
- **Validation Milestone**: In-memory database migration test succeeds; 20 categories are seeded upon first launch.

---

### Phase 3: Domain Layer & Repository Implementations
- **Deliverables**:
  1. Define domain model structs (`Transaction`, `Category`, `SplitExpense`, etc.).
  2. Define repository protocol contracts (`TransactionRepositoryProtocol`, etc.).
  3. Implement repositories querying GRDB and emitting reactive `AsyncStream` / Combine streams.
  4. Port calculation engines verbatim:
     - `SplitCalculationEngine.swift` (Equal, Custom, Itemized, zero-sum remainder).
     - `FinancialCalculatorEngine.swift` (EMI, SIP, FD, RD, GST, Discount).
     - `NetBalanceEngine.swift` (Transitive pairwise net debt simplifier).
     - `EasterEggEngine.swift` (Micro-delight predicates).
  5. Implement core domain use cases (`SaveTransactionUseCase`, `DeleteCategoryUseCase`, etc.).
- **Validation Milestone**: Pure unit test suite for all 4 engines passes 100% of Android test vectors.

---

### Phase 4: Transactions Ledger & Dashboard Feature
- **Deliverables**:
  1. Implement `AppContainer.swift` dependency container.
  2. Implement `MainTabHostView.swift` with 5 persistent tabs.
  3. Implement `BalanceHeroCard.swift` with eye toggle and gradient background.
  4. Implement `CategoryDonutChart.swift` using Swift Charts `SectorMark`.
  5. Implement `QuickActionPills.swift` and recent activity feed.
  6. Implement `AddEditTransactionSheet.swift` with numeric input and category picker.
  7. Implement `TransactionsListView.swift` with search, multi-filter sheet, and swipe-to-delete.
- **Validation Milestone**: User can log expenses and income in $< 3$ seconds; hero balance updates reactively.

---

### Phase 5: Split & Collect 2.0 Module
- **Deliverables**:
  1. Implement `SplitLandingView.swift` with group tabs and net debt banner ("You are owed / You owe").
  2. Implement `CreateSplitView.swift` supporting Equal, Custom Exact, and Itemized consumption splits.
  3. Implement `SplitDetailView.swift` with participant breakdown and settlement toggles.
  4. Implement `WhatsAppShareHelper.swift` pre-populating text breakdowns.
  5. Implement `QrCodeGenerator.swift` using `CoreImage` for dynamic UPI QR scanning.
  6. Implement ledger linkages: auto-generating linked expense and settlement income transactions.
- **Validation Milestone**: Splitting ₹100 among 3 participants reconciles to exact paise; settlements generate income entries.

---

### Phase 6: Planning Hub (Budgets & Savings Goals)
- **Deliverables**:
  1. Implement `PlanningView.swift` with Budgets and Savings Goals sub-tabs.
  2. Implement `BudgetsView.swift` with monthly category threshold progress bars (Green, Amber, Warning, Red).
  3. Implement `AddEditBudgetSheet.swift` for category and overall monthly limits.
  4. Implement `SavingsGoalsView.swift` with active and archived goal cards.
  5. Implement `SavingsGoalDetailView.swift` with milestone ring, contribution logs, and required monthly savings calculator.
- **Validation Milestone**: Budget progress bars transition colors accurately at 75%, 100%, and 100%+ thresholds.

---

### Phase 7: Analytics, Monthly Ledger & Bank-Grade PDF Export
- **Deliverables**:
  1. Implement `InsightsView.swift` with spending vs income grouped bars and savings rate card.
  2. Implement `MonthlyLedgerView.swift` with continuous monthly opening and closing balances.
  3. Implement `PdfStatementGenerator.swift` using `UIGraphicsPDFRenderer` (PDFKit) generating vector bank statements.
  4. Implement `PDFKitView.swift` for in-app preview with iOS native `ShareLink`.
  5. Implement `CalendarView.swift` with daily spending indicator badges.
  6. Implement `CalculatorsHubView.swift` (EMI, SIP, FD, RD, GST, Discount tools).
- **Validation Milestone**: Generated PDF matches layout, fonts, and continuous balances identical to Android output.

---

### Phase 8: Hardware, Security Vault, Widgets & Release Pre-flight
- **Deliverables**:
  1. Implement `SecurePinManager.swift` storing 16-byte random salt and SHA-256 PIN hash in Apple Keychain.
  2. Implement `AppLockView.swift` with tactile numeric keypad and LocalAuthentication (Face ID / Touch ID).
  3. Implement 5 failed PIN attempts 30-second rate-limiting cooldown.
  4. Implement App Switcher privacy blur overlay on `sceneWillResignActiveNotification`.
  5. Implement `BackupRestoreManager.swift` supporting JSON v2 export/import and CSV export.
  6. Implement WidgetKit extension (`FinancialOverviewWidget`, `TodayExpenseWidget`).
  7. Implement local notifications with smart evening suppression (`UserNotifications`).
  8. App Store pre-flight: `PrivacyInfo.xcprivacy`, App Icons, TestFlight build.
- **Validation Milestone**: App passes full acceptance criteria checklist; JSON backup roundtrip verifies with 0 subunits deviation.

