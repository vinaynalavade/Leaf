# Leaf

> **Offline-First Personal Finance & Ledger Suite for Android (v1.1.4) and iOS (v1.1.4)**

Leaf is a modern, privacy-first personal finance and expense management platform containing native implementations for both **Android** (v1.1.4, Build 16) and Apple **iOS** (v1.1.4, Build 3). Designed around strict financial precision, zero proprietary servers, zero advertising, and zero user telemetry, Leaf empowers individuals to manage personal expenses, dual-ledger cash/bank accounts, budgets, debt settlements, and recurring obligations with complete confidentiality.

---

## Table of Contents

- [Overview & Philosophy](#overview--philosophy)
- [Key Features](#key-features)
  - [Precision Monetary Engine](#precision-monetary-engine)
  - [Dual-Ledger Accounting & Atomic Transfers](#dual-ledger-accounting--atomic-transfers)
  - [Complete Expense & Income Tracking](#complete-expense--income-tracking)
  - [Split & Collect (Debt Reconciliation)](#split--collect-debt-reconciliation)
  - [Budgets & Savings Goals](#budgets--savings-goals)
  - [Recurring Transactions & Reminders](#recurring-transactions--reminders)
  - [Statements & Reports](#statements--reports)
  - [Home Screen Widgets](#home-screen-widgets)
  - [Cryptographic Security & Privacy Shield](#cryptographic-security--privacy-shield)
- [Repository Architecture](#repository-architecture)
- [Technology Stacks](#technology-stacks)
  - [Android Technology Stack](#android-technology-stack)
  - [iOS Technology Stack](#ios-technology-stack)
- [System Requirements](#system-requirements)
- [Build Instructions](#build-instructions)
  - [Android Build Instructions (Windows / PowerShell)](#android-build-instructions-windows--powershell)
  - [iOS Build Instructions (macOS / Xcode)](#ios-build-instructions-macos--xcode)
- [Privacy & Security Model](#privacy--security-model)
- [Current Known Limitations](#current-known-limitations)
- [Documentation Directory](#documentation-directory)
- [Contributing](#contributing)
- [Security Policy](#security-policy)
- [License](#license)

---

## Overview & Philosophy

Most commercial personal finance software forces users to entrust their sensitive financial history to third-party cloud backends, exposes personal data to advertising telemetry, or introduces subtle rounding errors through floating-point arithmetic.

Leaf takes an uncompromising engineering approach:
- **100% Offline-First:** Your financial records reside exclusively on your physical device in local SQLite databases.
- **Subunit Integer Precision:** Every monetary computation is executed in exact integer subunits (paise, cents, yen) using 64-bit integers (`Long` / `Int64`), entirely eliminating floating-point rounding errors.
- **Zero Third-Party Telemetry:** No analytics SDKs, no behavioral tracking, no crash-reporting backends, and no proprietary servers.
- **Open Standards:** Data ownership is preserved through RFC 4180 CSV exports and universal JSON v2 backup archives.
- **Authentic Platform Native Experiences:** Native Kotlin with Jetpack Compose for Android; native Swift with SwiftUI for iOS.

---

## Key Features

### Precision Monetary Engine
- **Subunit Scaling:** Prevents precision decay in balances, interest rates, and split remainders.
  - Standard currencies (INR, USD, EUR, GBP, AED, SGD, CAD, AUD): 2 decimal places ($1.00 \equiv 100$ subunits).
  - Zero-decimal currencies (JPY, KRW): 0 decimal places ($1 \equiv 1$ subunit).
  - High-precision support for currencies with up to 3 decimal places.
- **Max Monetary Bound:** Safely bounds calculations up to $10^{14}$ subunits ($1,000,000,000,000.00).

### Dual-Ledger Accounting & Atomic Transfers
- **Segregated Cash & Account Ledgers:** Independent tracking for physical Cash (`💵 Cash`) and electronic/bank accounts (`💳 Account`).
- **Balance-Neutral Inter-Ledger Transfers:** Move money between Cash and Bank with zero double counting. Transfers are balance-neutral and excluded from ordinary spending/income metrics.
- **Atomic Linking & Reversals:** Paired transfer records are linked via `transfer_pair_id`. Deleting or updating either leg atomically synchronizes or removes both entries. One-tap transfer reversal restores original balances without data loss.
- **Default Source Selection:** Configurable default payment method automatically selected during Quick Add and standard transaction entry.

### Complete Expense & Income Tracking
- **CRUD Lifecycle:** Add, edit with pre-populated values, delete with non-destructive undo snackbars.
- **Temporal Grouping & Search:** Grouped automatically by month and day ("Today", "Yesterday", and exact timestamps). Real-time search across notes, categories, and payment methods with instant type filtering.
- **Custom Categories:** Curated icons and color palettes with case-insensitive duplicate protection. System defaults are protected to prevent orphaned records.
- **Ledger Continuity & Carry-Forward:** Opening ledger balances carry forward month-to-month to provide unbroken financial continuity.
- **Day-Wise Calendar View:** Visual calendar highlighting daily spending distributions and cash flow.

### Split & Collect (Debt Reconciliation)
- **Deterministic Penny Reconciliation:** Divides bills equally or unequally across participants. Remainder pennies ($R = \text{Total} \pmod N$) are deterministically distributed to ensure the sum of individual shares strictly equals the total bill.
- **Debt Netting Engine:** Calculates direct and reverse obligations to determine the minimal settlement amounts.
- **Settle-Up & Payment Recording:** Log full or partial settlements with instant status updates (`PENDING`, `PARTIALLY_SETTLED`, `SETTLED`).
- **Group Analytics:** View per-group spending breakdowns, participant balance sheets, and itemized splits.

### Budgets & Savings Goals
- **4-Tier Visual Thresholds:**
  - `< 75%`: On Track (Green)
  - `75% - 99.9%`: Approaching Limit (Amber)
  - `100%`: Limit Reached (Amber Warning)
  - `> 100%`: Over Budget (Red)
- **Featured Budget Intelligence:** Automatically highlights the primary budget requiring user attention.
- **Savings Goals & Contributions:** Track target dates, progress percentages, and log milestone contributions.

### Recurring Transactions & Reminders
- **Deterministic Scheduling:** Manage recurring salaries, subscriptions, EMIs, and bills with flexible frequencies (Daily, Weekly, Monthly, Yearly).
- **Duplicate-Proof Auto-Generation:** Safe background evaluation prevents duplicate entries for the same cycle.
- **Smart Evening Reminder (9:00 PM):** Context-aware notification engine that suppresses reminders if transactions were already logged during the day.

### Statements & Reports
- **On-Device Vector PDF Statements:** Generate bank-grade statements directly on device using native platform graphics engines (Android `PdfDocument` / iOS `PDFKit` / `UIGraphicsPDFRenderer`). Features chronological transaction lists, running balances, and category summaries.
- **RFC 4180 CSV Export:** Export clean CSV files with standard headers for spreadsheet auditing.

### Home Screen Widgets
- **Android Widgets (AppWidgetProvider):** Complete native widget suite offering full feature parity with iOS:
  - **Small (2x2 / 2x1):** Glanceable Current Balance & Today's Expense widgets (`ExpenseTrackerWidgetProvider`, `TodayExpenseWidgetProvider`) with instant touch triggers and eye balance privacy toggle.
  - **Medium (4x2):** Matches iOS `LeafMediumWidgetView` with Total Balance, eye privacy toggle, cash flow wells (Income & Spent), Monthly Budget progress bar with percentage indicator, and 2 quick actions (`+ Add Expense`, `Split & Collect`).
  - **Large (4x4):** Matches iOS `LeafLargeWidgetView` with Total Balance, privacy toggle, monthly inflow/outflow, monthly budget progress bar, update timestamp, and 3 quick action buttons (`+ Expense`, `Split Bill`, `Planning`).
- **iOS Widgets (WidgetKit):** Small, Medium, and Large widgets powered by iOS 17+ App Intents (`ToggleWidgetBalancePrivacyIntent`) and App Group data sharing (`group.com.vinaynalavade.Leaf`). Includes interactive balance concealment and an in-app Widget Showcase.

### Cryptographic Security & Privacy Shield
- **Salted Key Derivation:** 6-digit PIN vault backed by PBKDF2-HMAC-SHA256 with a 16-byte cryptographically secure random salt stored in Android EncryptedSharedPreferences or Apple Keychain Services (`kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly`).
- **Biometric Authentication:** Face ID / Touch ID on iOS; BiometricPrompt on Android with hardware-backed cryptographic checks.
- **Multitasking Privacy Concealment:** Automatically blurs or masks application screens and hides balances whenever the app enters the background or app switcher.
- **Quick Balance Masking:** One-tap eye icon across dashboards and widgets to conceal account balances (`₹••••••`).

---

## Repository Architecture

The repository is structured as a unified monorepo with clean separation between the Android application, the native iOS application, documentation, website, and supporting tools:

```text
Leaf-GitHub-Ready/
├── app/                          # Native Android Application module
│   ├── src/                      # Kotlin source code, resources, and unit tests
│   │   ├── main/                 # AndroidManifest, java/com/vinaynalavade/expensetracker, res/
│   │   └── test/                 # 59 Android unit test suites
│   ├── build.gradle.kts          # Android application build configuration
│   └── proguard-rules.pro        # ProGuard / R8 code shrinking and obfuscation rules
├── gradle/                       # Android Gradle build system
│   ├── wrapper/                  # Gradle wrapper binaries and properties
│   └── libs.versions.toml        # Gradle Version Catalog (dependencies & plugins)
├── gradlew                       # Gradle wrapper shell script (macOS / Linux)
├── gradlew.bat                   # Gradle wrapper batch script (Windows)
├── build.gradle.kts              # Root Android Gradle build script
├── settings.gradle.kts           # Root Android Gradle project settings
├── gradle.properties             # JVM arguments and AndroidX configuration
├── signing.properties.example    # Safe template for Android release signing credentials
├── ios/                          # Native iOS Application project
│   ├── Leaf.xcodeproj/           # Xcode project and shared build schemes
│   ├── Leaf/                     # Native Swift / SwiftUI application source
│   │   ├── App/                  # App entrypoint (LeafApp.swift) and AppContainer DI
│   │   ├── Core/                 # Data, DesignSystem, Domain, Presentation, Services, Widgets
│   │   ├── Resources/            # Info.plist, Assets.xcassets (AppIcon, LeafLogo, Colors)
│   │   └── Leaf.entitlements     # App Group entitlements (group.com.vinaynalavade.Leaf)
│   ├── LeafWidgetsExtension/     # WidgetKit extension (Info.plist, entitlements)
│   ├── LeafTests/                # 10 native Swift unit test suites
│   ├── scripts/                  # Xcode project verification and maintenance scripts
│   ├── docs/                     # iOS frozen specification copy
│   ├── Package.swift             # Swift Package Manager manifest (LeafCore library target)
│   ├── Package.resolved          # SPM dependency lockfile (GRDB.swift 6.29.3)
│   ├── RELEASE_NOTES.md          # iOS release notes (v1.1.4 Build 3)
│   ├── README.md                 # iOS workspace development guide
│   └── .gitignore                # iOS-specific git ignore rules
├── docs/                         # Authoritative Project Documentation
│   ├── LEAF_MASTER_DOCUMENTATION.md   # Unified master specification (schemas, formulas, tokens)
│   ├── LEAF_DOCUMENTATION_AUDIT.md    # Codebase audit report & reconciliation certification
│   ├── RELEASE_UPDATE_SPEC.md         # Release upgrade specification
│   ├── ANDROID_README.md              # Original Android project documentation
│   └── shared-docs/                   # Complete 61-document engineering specification suite
├── website/                      # Static product showcase & privacy landing page
├── tools/                        # Python utility scripts (build_branding_assets.py)
├── .github/                      # CI/CD workflows (GitHub Pages website deployment)
├── README.md                     # This repository overview and documentation
├── LICENSE                       # GNU General Public License v3.0 (GPLv3)
├── CONTRIBUTING.md               # Contribution guidelines for Android and iOS
├── SECURITY.md                   # Security vulnerability reporting policy
└── .gitignore                    # Unified root gitignore for Android, iOS, OS, and secrets
```

---

## Technology Stacks

### Android Technology Stack

| Layer | Technology | Details |
| :--- | :--- | :--- |
| **Language** | Kotlin 2.0+ | Modern Kotlin idioms, value classes (`@JvmInline`), Coroutines, Flow |
| **UI Framework** | Jetpack Compose | Material Design 3, dynamic theme tokens, Compose Navigation |
| **Persistence** | Room (SQLite) | Room 2.6+, SQLite Schema v11 (Separate Ledgers & Transfers), deterministic migration tests, KSP |
| **Preferences** | Jetpack DataStore | DataStore Preferences for user settings and security flags |
| **Asynchronous Engine** | Kotlin Coroutines | `StateFlow`, `SharedFlow`, structured concurrency |
| **Architecture** | Clean 4-Layer | Core, Domain, Data, Presentation with manual DI (`AppContainer`) |
| **PDF Generation** | Android `PdfDocument` | Native on-device PDF generation without third-party dependencies |
| **SDK Levels** | Min SDK 26 / Target SDK 35 | Supports Android 8.0 (Oreo) through Android 15 (Vanilla Ice Cream) |
| **Build System** | Gradle (Kotlin DSL) | Version Catalog (`libs.versions.toml`), ProGuard / R8 enabled |

### iOS Technology Stack

| Layer | Technology | Details |
| :--- | :--- | :--- |
| **Language** | Swift 5.10 / Swift 6 | Modern async/await, actor isolation, structured concurrency |
| **UI Framework** | SwiftUI (iOS 17+) | Declarative layouts, squircle cards, SF Symbols, sheet detents |
| **Persistence** | GRDB.swift (SQLite) | GRDB 6.29.3, thread-safe database pooling, Schema v10 parity |
| **State Management** | Observation Framework | `@Observable` MVVM architecture |
| **Navigation** | `NavigationStack` | Typed enum routing (`LeafRoute`) |
| **Security** | Apple Keychain Services | `kSecClassGenericPassword` with salted PBKDF2-HMAC-SHA256 PIN |
| **Widgets** | WidgetKit & App Intents | Small, Medium, Large widgets with App Group `group.com.vinaynalavade.Leaf` |
| **PDF Export** | `PDFKit` / `UIGraphicsPDFRenderer` | Native vector statement generation |
| **Target Platforms** | iOS 17.0+ (iPhone & iPad) | Designed for modern Apple Silicon and 64-bit devices |

---

## System Requirements

### Android Development Requirements
- **Operating System:** Windows 10/11, macOS Sonoma+, or modern Linux distribution
- **Java Development Kit:** OpenJDK 17 or OpenJDK 21
- **Android Studio:** Android Studio Ladybug (2024.2.1) or newer
- **Android SDK:** API Level 35 SDK Platform and Build-Tools

### iOS Development Requirements
- **Operating System:** macOS Sonoma (14.0+) or macOS Sequoia (15.0+)
- **IDE:** Xcode 15.4 or Xcode 16+
- **Apple Developer Account:** Required for provisioning App Groups and physical device testing
- **Deployment Target:** iOS 17.0 or higher

---

## Build Instructions

### Android Build Instructions (Windows / PowerShell)

1. **Verify Prerequisites:**
   Open PowerShell and confirm Java 17+ is installed and accessible:
   ```powershell
   java -version
   ```

2. **Navigate to Repository Root:**
   ```powershell
   cd "X:\Leaf Altogether\Leaf-GitHub-Ready"
   ```

3. **Assemble Debug APK:**
   Debug builds use standard auto-generated Android debug keystores and do not require private credentials:
   ```powershell
   .\gradlew.bat assembleDebug
   ```
   The compiled debug APK will be located at:
   `app\build\outputs\apk\debug\app-debug.apk`

4. **Run Android Unit Tests:**
   Execute the complete suite of 59 unit tests:
   ```powershell
   .\gradlew.bat testDebugUnitTest
   ```

5. **Release Build Configuration:**
   Release builds require code signing credentials. To configure release signing:
   - Copy `signing.properties.example` to `signing.properties` in the project root (or `~/.android/leaf-signing.properties`).
   - Populate `STORE_FILE`, `STORE_PASSWORD`, `KEY_ALIAS`, and `KEY_PASSWORD`.
   - Alternatively, supply environment variables (`LEAF_KEYSTORE_PATH`, `LEAF_KEYSTORE_PASSWORD`, `LEAF_KEY_ALIAS`, `LEAF_KEY_PASSWORD`).
   ```powershell
   .\gradlew.bat assembleRelease
   ```

---

### iOS Build Instructions (macOS / Xcode)

1. **Navigate to iOS Directory:**
   ```bash
   cd ios
   ```

2. **Open Project in Xcode:**
   ```bash
   open Leaf.xcodeproj
   ```
   Xcode will automatically resolve and link the Swift Package Manager dependency (`GRDB.swift` v6.29.3).

3. **Build via Xcode CLI (`xcodebuild`):**
   To build for the iOS Simulator:
   ```bash
   xcodebuild -project Leaf.xcodeproj \
              -scheme Leaf \
              -destination 'platform=iOS Simulator,name=iPhone 16' \
              build
   ```

4. **Run Native iOS Tests:**
   Execute all 10 unit test suites in `LeafTests`:
   ```bash
   xcodebuild test \
              -project Leaf.xcodeproj \
              -scheme Leaf \
              -destination 'platform=iOS Simulator,name=iPhone 16'
   ```

5. **Alternative SPM Test Execution:**
   The `LeafCore` package target can also be tested using Swift Package Manager directly:
   ```bash
   cd ios
   swift test
   ```

---

## Privacy & Security Model

Leaf is engineered from the ground up to guarantee personal financial privacy:

1. **No External Backends:** Leaf does not operate any proprietary servers, analytics aggregators, or user databases. All data remains exclusively on your device.
2. **Local Cryptographic Protection:** User PINs are never stored in plaintext. They are salted with a 16-byte random salt and derived using PBKDF2-HMAC-SHA256, stored in hardware-backed storage (`kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly` on iOS; Android Keystore-backed EncryptedSharedPreferences).
3. **App Group Isolation (iOS):** Widget data sharing is strictly scoped to the local App Group container (`group.com.vinaynalavade.Leaf`) with minimal glanceable balance projections.
4. **Multitasking Concealment:** Sensitive balances and financial records are concealed with a privacy shield whenever the app is backgrounded.
5. **No Trackers:** Leaf contains zero third-party advertising SDKs, tracking pixels, or telemetry beacons.

---

## Current Known Limitations

- **Google Drive Backup on iOS:** While the Android implementation provides automated and manual backup to the user's private Google Drive `appDataFolder`, the native iOS Google Drive integration is currently in an experimental phase and is **not yet production-ready**. iOS users should utilize local JSON v2 exports or iCloud backups for data protection.
- **Cross-Platform Real-Time Sync:** Leaf is strictly offline-first. There is currently no direct peer-to-peer or server-mediated real-time synchronization between an Android device and an iOS device. Cross-platform migration is performed via JSON v2 backup files (`leaf_backup.json`).
- **On-Device Receipt OCR:** Optical character recognition for receipts relies on local platform machine learning engines (Android Google ML Kit / Apple Vision framework) and requires physical camera access. Performance varies by device hardware and lighting conditions.

---

## Documentation Directory

The `docs/` folder contains comprehensive specifications, schemas, and architectural audit reports:

- **[`docs/LEAF_MASTER_DOCUMENTATION.md`](docs/LEAF_MASTER_DOCUMENTATION.md)**: Frozen product blueprint covering mathematical models, SQLite v10 schemas, JSON v2 serialization schemas, color tokens, and business rules.
- **[`docs/LEAF_DOCUMENTATION_AUDIT.md`](docs/LEAF_DOCUMENTATION_AUDIT.md)**: Audit report certifying cross-platform schema compatibility, enum parity, and data contracts between Kotlin and Swift.
- **[`docs/RELEASE_UPDATE_SPEC.md`](docs/RELEASE_UPDATE_SPEC.md)**: In-app release notes and update notification engine specification.
- **[`docs/shared-docs/`](docs/shared-docs/)**: Original 61-document technical breakdown covering feature-by-feature specifications, user flows, database migrations, and testing matrices.
- **[`docs/ANDROID_README.md`](docs/ANDROID_README.md)**: Original standalone Android application documentation.
- **[`ios/README.md`](ios/README.md)** & **[`ios/RELEASE_NOTES.md`](ios/RELEASE_NOTES.md)**: iOS workspace development documentation and release notes for v1.1.4 (Build 3).

---

## Contributing

Contributions from the open-source community are welcome. Please read [CONTRIBUTING.md](CONTRIBUTING.md) for details on code style, architecture conventions, pull request workflows, and development guidelines for both Android and iOS.

---

## Security Policy

We treat user security and privacy with paramount importance. If you discover a potential vulnerability or data leakage flaw, please report it responsibly according to the instructions in [SECURITY.md](SECURITY.md). Do not submit security reports through public GitHub issues.

---

## License

Leaf is open-source software licensed under the **GNU General Public License v3.0 (GPLv3)**. See [LICENSE](LICENSE) for the complete license terms.

