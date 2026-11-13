# Leaf — Native iOS Application Workspace

Welcome to the native iOS development workspace for **Leaf**, a calm, privacy-first personal finance ledger and deterministic shared expense manager.

This workspace (`Leaf-iOS`) is dedicated to building the complete, native Apple iOS implementation of Leaf using **Swift**, **SwiftUI**, and modern iOS platform frameworks.

---

## 1. Authoritative Specification & Blueprint

Before implementing any feature or architecture in this workspace, developers and AI agents **MUST** consult the frozen master specification located at:

👉 **[`docs/LEAF_MASTER_DOCUMENTATION.md`](docs/LEAF_MASTER_DOCUMENTATION.md)**

This document is the authoritative product blueprint. It contains complete mathematical specifications, database schemas, JSON serialization schemas, design tokens, screen-by-screen requirements, and cross-platform compatibility rules derived and audited from the existing Android implementation.

---

## 2. Core Architecture & Technology Stack

The iOS implementation is not a port or wrapper; it is an idiomatic, native Swift application designed specifically for Apple platforms:

| Architectural Tier | Native iOS Technology | Implementation Notes |
| :--- | :--- | :--- |
| **Language & Concurrency** | **Swift 5.10 / Swift 6** | Modern async/await, structured concurrency, actor isolation for database access. |
| **User Interface** | **SwiftUI (iOS 17+)** | Declarative UI, continuous squircle cards, SF Symbols, custom sheets with presentation detents. |
| **State Management** | **Observation (`@Observable`)** | Clean MVVM architecture without legacy Combine boilerplate. |
| **Navigation** | **`NavigationStack`** | Typed path routing driven by enum-based `LeafRoute` destinations. |
| **Persistence Engine** | **SQLite via `GRDB.swift`** | High-performance, thread-safe SQLite wrapper matching Android Room Schema Version 10. |
| **Monetary Precision** | **`Amount` Value Struct** | Pure integer arithmetic (`Int64` subunits). Zero floating-point representation. |
| **App Security & PIN** | **Apple Keychain Services** | Hardware-backed `kSecClassGenericPassword` with `LocalAuthentication` (Face ID / Touch ID). |
| **Cloud Synchronization** | **iCloud Drive + Google Drive** | Ubiquity container (`leaf_backup.json`) + optional Google Drive v3 REST for cross-platform restore. |
| **Home Screen Widgets** | **WidgetKit + App Intents** | Small/Medium interactive balance and quick logging widgets. |
| **Ledger Statement Export** | **PDFKit (`UIGraphicsPDFRenderer`)** | Multi-page vector PDF generation matching official tax and audit formats. |

---

## 3. Strict Cross-Platform Compatibility Rules

To guarantee flawless interoperability with existing Android backups and cross-platform workflows, the iOS application must strictly adhere to the following rules:

### A. Subunit Financial Arithmetic
- All monetary amounts in memory, SQLite, and JSON backups are stored as **64-bit signed integers (`Int64`) representing currency subunits** (paise, cents, yen).
- Standard currencies use 2 decimal places ($1.00 \equiv 100$). Zero-decimal currencies (e.g., JPY, KRW) use 0 decimal places ($1 \equiv 1$). Three-decimal currencies (e.g., BHD, KWD) use 3 decimal places ($1.000 \equiv 1000$).
- Standard decimal math (`Double` or `Float`) is strictly forbidden for financial calculations.

### B. Universal JSON v2 Backup Format
- **Root Envelope**: Flat root JSON object. There is **NO nested `"data"` wrapper**.
- **Collection Keys**: camelCase strings: `categories`, `transactions`, `recurringTransactions`, `budgets`, `savingsGoals`, `savingsGoalContributions`, `splitGroups`, `splitExpenses`, `splitParticipants`, `reminders`.
- **Parser Nullability**: `categories` and `transactions` are **strictly mandatory**. If missing, throw an error. The other 8 collections are optional and default to empty arrays (`[]`).
- **Backup File Name**: `leaf_backup.json` (with legacy fallback to `kharchaflow_backup.json`).

### C. CSV Export Header
- Header must match RFC 4180 standard:
  ```csv
  Date,Type,Category,Amount,Currency,Payment Method,Note,Created At
  ```
- Amounts in CSV are formatted decimal strings (e.g., `"180.50"`), not integer subunits.

### D. Default Categories
- The database must seed the exact 20 default categories (12 Expense, 8 Income) defined in Section 10 of the master documentation with `is_default = 1`.

---

## 4. Visual Identity & Design Tokens

Leaf uses the signature **"Emerald & Obsidian"** design system:

```
┌─────────────────────────────────────────────────────────────┐
│                    EMERALD & OBSIDIAN                       │
├──────────────────────────────┬──────────────────────────────┤
│ DARK MODE: OBSIDIAN NIGHT    │ LIGHT MODE: WARM CANVAS      │
│ Base Canvas: #0A0C0F         │ Base Canvas: #F4F6F9         │
│ Card Surface: #14171E        │ Card Surface: #FFFFFF        │
│ Elevated Card: #1C202A       │ Elevated Card: #F0F3F7       │
│ Accent Emerald: #05B38C      │ Accent Emerald: #028166      │
│ Success Green: #10B981       │ Success Green: #10B981       │
│ Expense Coral: #EF4444       │ Expense Coral: #EF4444       │
└──────────────────────────────┴──────────────────────────────┘
```

- Typography: **SF Pro Text** and **SF Pro Rounded** with `.monospacedDigit()` for financial figures.
- Shapes: Continuous corner curvature squircles (`RoundedRectangle(cornerRadius: ..., style: .continuous)`).

---

## 5. Implementation Roadmap for iOS Development

When starting development in this workspace, follow this step-by-step phased plan:

1. **Phase 1: Project Scaffolding & SPM Setup**
   - Create Xcode project targeting iOS 17.0+ with bundle identifier `com.vinaynalavade.Leaf`.
   - Add Swift Package Manager dependencies: `GRDB.swift` (and optional Google Sign-In SDK).
2. **Phase 2: Core Domain Models & Subunit Arithmetic**
   - Implement `Amount` value struct with `Int64` storage, arithmetic operators, and currency formatting.
   - Implement `Currency` enum supporting the 9 global currencies (INR, USD, EUR, GBP, JPY, CAD, AUD, SGD, AED).
   - Implement `SplitCalculationEngine` with deterministic penny reconciliation.
3. **Phase 3: Database & Persistence Layer**
   - Implement GRDB SQLite schema v10 with all 10 tables, foreign key constraints, indexes, and migrations.
   - Implement default category seed script (20 categories).
4. **Phase 4: Universal JSON Serialization & Interop Verification**
   - Implement Swift `Codable` structs for Universal JSON v2.
   - Create test fixture `leaf_cross_platform_fixture_v2.json` and verify bidirectional import/export with Android.
5. **Phase 5: Presentation Layer (SwiftUI)**
   - Build theme colors, typography styles, and reusable squircle card components.
   - Implement root `NavigationStack` and 5-tab shell (Dashboard, Transactions, Split, Planning, Settings).
   - Build high-speed transaction entry sheet (< 3 second entry target).
6. **Phase 6: Security, Biometrics & Extensions**
   - Integrate Keychain Services for 4-digit PIN storage and lockout mechanism.
   - Integrate `LocalAuthentication` for Face ID / Touch ID.
   - Implement WidgetKit widgets for Quick Balance and Recent Spending.
   - Implement PDFKit vector statement generator.
7. **Phase 7: Test Suite & Parity Validation**
   - Adapt and execute the 59 baseline unit test suites in Swift XCTest.
   - Verify 100% calculation and data parity.

---

## 6. Directory Structure

```
Leaf-iOS/
├── README.md                      # This orientation guide
├── .gitignore                     # Xcode / Swift ignore rules
└── docs/
    └── LEAF_MASTER_DOCUMENTATION.md # Authoritative frozen master specification
```

