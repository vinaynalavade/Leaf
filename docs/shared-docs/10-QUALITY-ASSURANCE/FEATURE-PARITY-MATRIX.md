# Leaf Quality Assurance: Complete Feature Parity Matrix

## 1. Executive Summary
This document provides the definitive feature parity matrix across all **69 functional capabilities** discovered in the Leaf Android application. It establishes the technical implementation roadmap for the native iOS application, identifying target technologies, APIs, and verification milestones.

---

## 2. Parity Status Key
- **PARITY-REQUIRED**: Must be implemented natively in Phase 1 with 100% mathematical and behavioral parity.
- **PARITY-ADAPTED**: Functional parity required, but adapted to native iOS conventions (e.g., WidgetKit, Keychain, SF Symbols, App Store lookup).
- **PLANNED**: Identified as roadmap or partial in Android; scheduled for future iOS enhancement.

---

## 3. Comprehensive Feature Parity Matrix

| Feature ID | Feature Name | Module | Android Implementation | iOS Native Recommendation | Parity Priority |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `FEAT-01.1` | Net Balance Overview | Dashboard | `BalanceHeroCard.kt` | SwiftUI Card with `HeroEmeraldGradient` | **PARITY-REQUIRED** |
| `FEAT-01.2` | Cashflow Income/Expense Wells | Dashboard | `BalanceHeroCard.kt` | Monospaced tabular stat columns | **PARITY-REQUIRED** |
| `FEAT-01.3` | Balance Privacy Obfuscation | Dashboard | `EyeToggleButton` (`••••••`) | `@AppStorage("isBalanceVisible")` | **PARITY-REQUIRED** |
| `FEAT-01.4` | Quick Action Shortcuts | Dashboard | `QuickActionPills.kt` | SwiftUI Capsule Buttons with Haptics | **PARITY-REQUIRED** |
| `FEAT-01.5` | Dynamic Contextual Greeting | Dashboard | `DashboardScreen.kt` | `Calendar.current` time evaluation | **PARITY-REQUIRED** |
| `FEAT-01.6` | Category Spending Donut Chart | Dashboard | `CategoryDonutChart.kt` | Swift Charts `SectorMark` (iOS 17) | **PARITY-REQUIRED** |
| `FEAT-01.7` | Recent Activity Feed | Dashboard | `TransactionItemCard.kt` | `LazyVStack` with continuous squircles | **PARITY-REQUIRED** |
| `FEAT-01.8` | Inline Budget Consumption Bar | Dashboard | `DashboardBudgetCard.kt` | 4-tier threshold colored `ProgressView`| **PARITY-REQUIRED** |
| `FEAT-02.1` | Expense Logging | Transactions | `AddEditTransactionSheet.kt` | SwiftUI `.sheet` with large keypad | **PARITY-REQUIRED** |
| `FEAT-02.2` | Income Logging | Transactions | `AddEditTransactionSheet.kt` | Green accent styled entry modal | **PARITY-REQUIRED** |
| `FEAT-02.3` | Edit Existing Transaction | Transactions | `AddEditTransactionSheet.kt` | Reactive edit form with DB update | **PARITY-REQUIRED** |
| `FEAT-02.4` | Swipe-to-Delete Transaction | Transactions | `SwipeToDismissBox` | SwiftUI `.swipeActions(edge: .trailing)`| **PARITY-REQUIRED** |
| `FEAT-02.5` | Category Taxonomy Assignment | Transactions | `CategorySelector.kt` | Flow layout with squircle chips | **PARITY-REQUIRED** |
| `FEAT-02.6` | Payment Source (Cash/Account) | Transactions | `PaymentMethod` toggle | Segmented `Picker` (`.segmented`) | **PARITY-REQUIRED** |
| `FEAT-02.7` | Full-Text Transaction Search | Transactions | `SearchTextField` / DAO query | `.searchable(text: $query)` | **PARITY-REQUIRED** |
| `FEAT-02.8` | Multi-Criteria Filtering | Transactions | `TransactionFilterSheet.kt` | Dedicated Filter `.sheet` | **PARITY-REQUIRED** |
| `FEAT-02.9` | Transaction Sorting | Transactions | Date, Amount, Title sorts | Menu with `Picker` | **PARITY-REQUIRED** |
| `FEAT-02.10`| Floating Quick-Add Window | Transactions | `QuickAddTransactionActivity` | Lightweight modal sheet | **PARITY-ADAPTED** |
| `FEAT-03.1` | Equal Bill Splitting | Split | `SplitCalculationEngine.kt` | Deterministic remainder distribution | **PARITY-REQUIRED** |
| `FEAT-03.2` | Custom Exact Split Allocation | Split | `CreateSplitScreen.kt` | Exact zero-sum input validator | **PARITY-REQUIRED** |
| `FEAT-03.3` | Itemized Consumption Splitting| Split | `SplitItem` & `SplitItemJson` | Multi-item consumer selector | **PARITY-REQUIRED** |
| `FEAT-03.4` | Remainder Penny Allocation | Split | Remainder $R \to$ first $R$ | Exact integer arithmetic logic | **PARITY-REQUIRED** |
| `FEAT-03.5` | Participant Settle-Up | Split | `SettleParticipantUseCase.kt` | Settle checkbox with timestamp | **PARITY-REQUIRED** |
| `FEAT-03.6` | WhatsApp Split Sharing | Split | `WhatsAppShareHelper.kt` | `URL(string: "whatsapp://send?text=...")` | **PARITY-ADAPTED** |
| `FEAT-03.7` | Dynamic UPI QR Generator | Split | Custom Bitmap QR renderer | `CoreImage.CIFilter.qrCodeGenerator` | **PARITY-ADAPTED** |
| `FEAT-03.8` | Ledger Outflow Integration | Split | `add_to_transactions = 1` | Linked `EXPENSE` generation | **PARITY-REQUIRED** |
| `FEAT-03.9` | Ledger Settlement Inflow | Split | `settlement_transaction_id` | Linked `INCOME` generation | **PARITY-REQUIRED** |
| `FEAT-03.10`| Split Groups Management | Split | `SplitGroupScreen.kt` | Group categories & expense tags | **PARITY-REQUIRED** |
| `FEAT-03.11`| Transitive Net Debt Simplifier| Split | `NetBalanceEngine.kt` | Pairwise debt cancellation engine | **PARITY-REQUIRED** |
| `FEAT-04.1` | Monthly Category Budgets | Planning | `BudgetListScreen.kt` | Category limit cards with progress | **PARITY-REQUIRED** |
| `FEAT-04.2` | Overall Monthly Budget Cap | Planning | `BudgetEntity(category_id=null)`| Master monthly cap tracker | **PARITY-REQUIRED** |
| `FEAT-04.3` | 4-Tier Budget Color Alerts | Planning | Green/Amber/Warning/Red | Exact threshold color engine | **PARITY-REQUIRED** |
| `FEAT-04.4` | Month & Year Period Switching | Planning | Calendar month stepper | Month navigation header | **PARITY-REQUIRED** |
| `FEAT-05.1` | Savings Goals Creation | Planning | `AddEditGoalDialog.kt` | Goal cards with custom icons | **PARITY-REQUIRED** |
| `FEAT-05.2` | Goal Progress Tracking Ring | Planning | Circular / Linear progress | SwiftUI `ProgressView(value:total:)` | **PARITY-REQUIRED** |
| `FEAT-05.3` | Milestone Contribution Log | Planning | `SavingsGoalDetailScreen.kt` | Contribution history list | **PARITY-REQUIRED** |
| `FEAT-05.4` | Required Monthly Deficit Calc | Planning | `ChronoUnit.MONTHS.between` | Calendar ceiling savings formula | **PARITY-REQUIRED** |
| `FEAT-05.5` | Goal Archival Lifecycle | Planning | `is_archived = 1` | Archived goals section filter | **PARITY-REQUIRED** |
| `FEAT-06.1` | Spending vs Income Analytics | Insights | Monthly comparison bars | SwiftUI `Charts` grouped bars | **PARITY-REQUIRED** |
| `FEAT-06.2` | Cashflow Savings Rate | Insights | Net savings percentage | Metric card: $(Inc-Exp)/Inc \times 100$ | **PARITY-REQUIRED** |
| `FEAT-06.3` | Category Rollup Ranking | Insights | Top spending category rows | Ranked category breakdown list | **PARITY-REQUIRED** |
| `FEAT-07.1` | Continuous Monthly Ledger | Statements | `MonthlyLedgerScreen.kt` | Continuous opening/closing balance | **PARITY-REQUIRED** |
| `FEAT-07.2` | Vector Bank-Grade PDF Engine | Statements | `PdfUtils.kt` (Android Canvas) | `UIGraphicsPDFRenderer` (PDFKit) | **PARITY-ADAPTED** |
| `FEAT-07.3` | In-App PDF Viewer | Statements | `PdfViewerScreen.kt` | `PDFView` inside `UIViewRepresentable` | **PARITY-ADAPTED** |
| `FEAT-08.1` | Interactive Monthly Calendar | Calendar | `CalendarScreen.kt` | SwiftUI Calendar grid view | **PARITY-REQUIRED** |
| `FEAT-08.2` | Daily Spending Indicator Badges| Calendar | Daily aggregated total pills | Dynamic daily sum badges | **PARITY-REQUIRED** |
| `FEAT-08.3` | Day Selection Transaction Feed| Calendar | Selected date ledger list | Filtered transaction list | **PARITY-REQUIRED** |
| `FEAT-09.1` | Recurring Transaction Rules | Recurring | `RecurringListScreen.kt` | Subscriptions & recurring rules | **PARITY-REQUIRED** |
| `FEAT-09.2` | Background Auto-Generation | Recurring | `RecurringTransactionWorker.kt` | `BGAppRefreshTask` / app launch | **PARITY-ADAPTED** |
| `FEAT-10.1` | Financial Calendar Reminders | Reminders | `ReminderListScreen.kt` | Bill, EMI, Credit card alerts | **PARITY-REQUIRED** |
| `FEAT-10.2` | Smart Reminder Suppression | Reminders | Suppress 9 PM if logged today | Contextual local notification check | **PARITY-REQUIRED** |
| `FEAT-10.3` | 1-Tap Mark as Paid | Reminders | Direct inline settlement | Interactive notification / UI action | **PARITY-REQUIRED** |
| `FEAT-11.1` | Loan EMI Calculator | Tools | `FinancialCalculatorEngine.kt` | Native Swift banking power formula | **PARITY-REQUIRED** |
| `FEAT-11.2` | SIP Wealth Growth Planner | Tools | Annuity Due formula | Beginning-of-month formula | **PARITY-REQUIRED** |
| `FEAT-11.3` | Fixed Deposit (FD) Tool | Tools | Quarterly compounding | $A = P(1+r/4)^{4t}$ formula | **PARITY-REQUIRED** |
| `FEAT-11.4` | Recurring Deposit (RD) Tool | Tools | Monthly stream compounding | Sum of compounded deposits | **PARITY-REQUIRED** |
| `FEAT-11.5` | GST & Discount Calculators | Tools | Inclusive / Exclusive tax | Precise percentage calculators | **PARITY-REQUIRED** |
| `FEAT-12.1` | 4-Digit PIN Security Vault | Security | Salted SHA-256 in prefs | Apple **Keychain Services** | **PARITY-ADAPTED** |
| `FEAT-12.2` | Biometric Authentication | Security | Android `BiometricPrompt` | **LocalAuthentication** (Face ID) | **PARITY-ADAPTED** |
| `FEAT-12.3` | App Switcher Privacy Blur | Security | `FLAG_SECURE` | Blur on `sceneWillResignActive` | **PARITY-ADAPTED** |
| `FEAT-12.4` | 5 Failed Attempts Cooldown | Security | 30-second rate-limiting | Timestamp lockout in Keychain | **PARITY-REQUIRED** |
| `FEAT-13.1` | Local JSON v2 Export/Import | Backup | Structured JSON serializer | Universal JSON v2 Engine | **PARITY-REQUIRED** |
| `FEAT-13.2` | Full Database CSV Export | Backup | Tabular CSV generator | Spreadsheet CSV export | **PARITY-REQUIRED** |
| `FEAT-13.3` | Google Drive Cloud Sync | Backup | Google Drive v3 REST client | iCloud Drive (Default) + Drive | **PARITY-ADAPTED** |
| `FEAT-14.1` | 20 Pre-Seeded Categories | Categories | 12 Expense, 8 Income | SQLite seeding transaction | **PARITY-REQUIRED** |
| `FEAT-14.2` | Custom Category Builder | Categories | 22 Icons, 12 Swatches | Flow layout picker with SF Symbols | **PARITY-ADAPTED** |
| `FEAT-14.3` | Category Deletion Safety | Categories | Restrict default & in-use | Strict validation query check | **PARITY-REQUIRED** |
| `FEAT-15.1` | Currency Configuration | Settings | 9 global currencies | Exact subunit scaling factors | **PARITY-REQUIRED** |
| `FEAT-16.1` | 5-Step Visual App Tour | Onboarding | `AppTourScreen.kt` | SwiftUI `TabView` with page dots | **PARITY-REQUIRED** |
| `FEAT-17.1` | Home Screen Glanceable Widgets| Widgets | 4x2, 2x1, 1x1 AppWidgets | **WidgetKit** interactive widgets | **PARITY-ADAPTED** |
| `FEAT-18.1` | In-App Release Discovery | Updates | GitHub Releases REST client | **iTunes Lookup API** for App Store| **PARITY-ADAPTED** |
| `FEAT-19.1` | Easter Egg Delight Universe | Delights | `EasterEggEngine.kt` | Exact same easter egg predicates | **PARITY-REQUIRED** |

