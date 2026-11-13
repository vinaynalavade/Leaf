# Contributing to Leaf

Thank you for your interest in contributing to Leaf! We welcome contributions from the community to make Leaf the leading open-source, privacy-first personal finance platform for both Android and Apple iOS.

Please take a moment to review this guide before submitting issues or pull requests.

---

## 🛠️ Development Environments & Setup

Leaf contains native applications for two mobile platforms:
1. **Android** (Kotlin, Jetpack Compose, Room)
2. **iOS** (Swift, SwiftUI, GRDB.swift)

### Android Setup
- **JDK:** OpenJDK 17 or OpenJDK 21
- **Android Studio:** Android Studio Ladybug (2024.2.1) or newer
- **Android SDK:** API Level 35 SDK Platform and Build-Tools installed

```powershell
# Windows PowerShell
.\gradlew.bat assembleDebug
.\gradlew.bat testDebugUnitTest

# macOS / Linux
./gradlew assembleDebug
./gradlew testDebugUnitTest
```

### iOS Setup
- **Operating System:** macOS Sonoma (14.0+) or macOS Sequoia (15.0+)
- **Xcode:** Xcode 15.4 or Xcode 16+
- **Platform:** iOS 17.0+ deployment target

```bash
# Open Xcode Project
cd ios
open Leaf.xcodeproj

# Build via CLI
xcodebuild -project Leaf.xcodeproj -scheme Leaf -destination 'platform=iOS Simulator,name=iPhone 16' build

# Run Swift Unit Tests
xcodebuild test -project Leaf.xcodeproj -scheme Leaf -destination 'platform=iOS Simulator,name=iPhone 16'

# Alternative SPM CLI Tests
cd ios
swift test
```

---

## 📐 Architecture & Engineering Standards

Leaf enforces strict separation of concerns to keep business and mathematical logic independent of UI frameworks:

### Android Clean 4-Layer Architecture
```text
com.vinaynalavade.expensetracker
├── core/           # Domain-agnostic models (Amount, Currency), Result taxonomy, Utils
├── data/           # Room Database, DAOs, Entities, DataStore, Repository implementations
├── domain/         # Pure Kotlin models, Repository interfaces, Use cases, Validators
├── presentation/   # Compose UI, ViewModels, Themes, Navigation, Widgets
└── di/             # Manual Dependency Injection (AppContainer)
```

### iOS Native Swift Architecture
```text
ios/Leaf/
├── App/            # Entry point (LeafApp.swift) and AppContainer dependency graph
└── Core/
    ├── Domain/     # Pure Swift models (Amount, Currency, Transaction), Use cases, Protocols
    ├── Data/       # GRDB.swift SQLite Database, Migrations, Seeds, Repository implementations
    ├── Presentation/ # SwiftUI Views, ViewModels (@Observable), Theme, Navigation
    ├── Services/   # Local authentication, Keychain vault, PDF generator, Backup engine
    └── Widgets/    # Shared WidgetKit models and App Intents
```

---

## 🪙 Core Mathematical & Data Contracts

All contributions across Android and iOS must strictly adhere to the following contracts:

1. **Subunit Financial Arithmetic:**
   - Never use floating-point types (`Float` / `Double`) to represent or calculate monetary currency.
   - All monetary figures must use `Amount` wrapping a signed 64-bit integer (`Long` on Android, `Int64` on iOS) representing currency subunits (paise, cents, yen).
2. **Offline-First Principle:**
   - Leaf operates 100% locally. Do not introduce proprietary servers, remote analytics, third-party trackers, or crash-reporting SDKs.
3. **Database Schema Parity (Schema v10):**
   - Both platforms implement identical SQLite table schemas, indexes, and foreign key cascades.
   - Any database schema changes must be accompanied by explicit forward migrations and tests on both platforms.
4. **Universal Backup Serialization (JSON v2):**
   - Backup files (`leaf_backup.json`) follow a flat JSON envelope format with camelCase keys (`categories`, `transactions`, `recurringTransactions`, `budgets`, etc.).
   - Compatibility must be maintained to ensure a backup generated on Android can be seamlessly restored on iOS, and vice versa.

---

## 🔀 Submitting Pull Requests

1. **Create a Topic Branch:**
   ```bash
   git checkout -b feature/your-feature-name
   # or
   git checkout -b fix/issue-description
   ```
2. **Commit Guidelines:**
   - Write clear, imperative commit messages (e.g. `feat(android): add category filter to statement export`, `fix(ios): prevent duplicate split participant selection`).
3. **Run Tests Locally:**
   - Verify that all unit test suites pass prior to opening a PR:
     - Android: `./gradlew testDebugUnitTest`
     - iOS: `xcodebuild test -project ios/Leaf.xcodeproj -scheme Leaf -destination 'platform=iOS Simulator,name=iPhone 16'`
4. **Open a Pull Request:**
   - Provide a concise summary of the problem solved and the implementation details.
   - Attach screenshots or screen recordings for any visual changes.

---

## 🐛 Reporting Issues

- **Bug Reports:** Search existing issues before opening a new ticket. Include the operating system (Android or iOS), app version, device model, reproduction steps, expected behavior, and relevant logs.
- **Feature Requests:** Open an issue detailing the user story, proposed solution, and why it benefits offline personal finance management.

---

## 🔒 Security Reports

If you discover a security vulnerability or sensitive data leakage, please do **NOT** open a public issue. Refer to [SECURITY.md](SECURITY.md) for private reporting instructions.

---

## 📄 License

By contributing to Leaf, you agree that your contributions will be licensed under the **GNU General Public License v3.0 (GPLv3)**.

