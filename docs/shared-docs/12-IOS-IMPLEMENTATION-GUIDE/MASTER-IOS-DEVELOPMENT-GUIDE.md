# Leaf Master iOS Development Guide: Architectural Mandates & Implementation Protocol

> **CRITICAL NOTICE TO THE DEVELOPER / AI AGENT BUILDING THE NATIVE iOS APPLICATION**:
> You are tasked with implementing Leaf natively for Apple iPhone devices inside the `ios/` workspace directory. 
> You MUST read and strictly adhere to every mandate, constraint, and architectural standard documented in this master guide. 

---

## 1. Core Mission & Inviolable Rules

Your objective is to recreate the complete, polished Leaf product experience natively using **Swift** and **SwiftUI**. You are **NOT** copying Android Kotlin code. You are translating domain logic, calculation precision, and user experience into idiomatic, native Apple platform standards.

### The Five Inviolable Mandates
1. **The Subunit Rule (Zero Floating-Point Drift)**:
   - Floating-point types (`Float`, `Double`) are **STRICTLY FORBIDDEN** for storing, summing, or persisting money.
   - All monetary amounts in the database, repositories, and domain models MUST use `Amount` (`Int64` subunits / paise / cents).
   - Division remainders in bill splitting MUST be reconciled using deterministic integer partitioning ($R = \text{Total} \pmod N$ distributed to first $R$).
2. **Database Schema Parity**:
   - The database MUST implement **Schema Version 10** with the exact 10 tables, column names, foreign keys, cascades, and default values specified in `shared-docs/05-DATABASE/DATABASE-SCHEMA.md`.
   - The 20 default categories must be seeded upon database creation.
3. **Apple Human Interface Guidelines (HIG) Native Fidelity**:
   - Do not emulate Android UI controls on iOS. Use native SwiftUI `TabView`, `NavigationStack`, `.sheet`, SF Symbols, and continuous squircles (`.continuous`).
   - Use tabular numbers (`.monospacedDigit()`) for all currency amounts.
4. **Security & Privacy Isolation**:
   - The 4-digit PIN hash and 16-byte cryptographic salt MUST be stored in the **Apple Keychain Services**, NEVER in UserDefaults or unencrypted plists.
   - PIN secrets must NEVER be included in backup JSON exports.
5. **Continuous Financial Continuity**:
   - Monthly statement calculations MUST preserve continuous financial continuity: the opening balance of Month $M_k$ must strictly equal the closing balance of Month $M_{k-1}$.

---

## 2. Technology Stack & Dependencies

| Layer | Standard / Library | Minimum Version | Rationale |
| :--- | :--- | :--- | :--- |
| **Language** | **Swift 5.10 / Swift 6** | Swift 5.10+ | Strict concurrency checking (`@MainActor`, Sendable). |
| **UI Framework** | **SwiftUI** | iOS 17.0+ | Modern declarative UI, `@Observable`, native interactive widgets. |
| **Persistence** | **GRDB.swift** | v6.24.0+ | Direct SQLite schema parity with Android Room, 100% binary backup compatibility, blazing speed. |
| **Charts** | **Swift Charts** | iOS 17.0+ | Native `SectorMark` for category donuts, `BarMark` for cashflow trends. |
| **Security** | **KeychainAccess** / Native `Security.framework` | iOS 17.0+ | Hardware-backed Secure Enclave PIN vault storage. |
| **Biometrics** | **LocalAuthentication** | iOS 17.0+ | Face ID and Touch ID biometric authentication. |
| **PDF Generation** | **PDFKit** | iOS 17.0+ | Vector-grade bank statements via `UIGraphicsPDFRenderer`. |
| **Widgets** | **WidgetKit** & **AppIntents** | iOS 17.0+ | Glanceable and interactive home screen widgets. |

---

## 3. Mandatory Development Workflow & Phasing

When beginning the development task inside `ios/`, execute the work in the strict 8-phase sequence detailed in `shared-docs/12-IOS-IMPLEMENTATION-GUIDE/DEVELOPMENT-PHASES.md`:

```
Phase 1: Project Scaffolding & Core Primitives (Amount, Currency, Theme Tokens)
    ↓
Phase 2: Database Layer & Migrations (GRDB Schema v10, Records, 20 Default Categories)
    ↓
Phase 3: Domain Layer & Repository Implementations (UseCases, Calculation Engines)
    ↓
Phase 4: Transactions Ledger & Dashboard Feature (Hero Card, Donut Chart, Quick Log)
    ↓
Phase 5: Split & Collect 2.0 Module (Equal, Custom, Itemized, WhatsApp, QR)
    ↓
Phase 6: Planning Hub (Monthly Budgets with 4-Tier Thresholds, Savings Goals)
    ↓
Phase 7: Analytics, Monthly Ledger & Bank-Grade PDF Export
    ↓
Phase 8: Security Vault (Keychain PIN, Face ID), Home Widgets & Final Polish
```

---

## 4. Coding Standards & Architectural Conventions

### 4.1 Value Types & Immutability
- Prefer `struct` over `class` for all domain entities, models, and states.
- Classes are reserved strictly for `@Observable` ViewModels and service containers.
- All properties should be `let` unless mutation is explicitly required.

### 4.2 Error Handling Contract
- Use typed `AppResult<T>` or Swift `throws` with dedicated domain error enums:
  ```swift
  enum AppError: Error, LocalizedError {
      case validation(message: String)
      case notFound(message: String)
      case security(message: String)
      case database(message: String)
  }
  ```

### 4.3 View Separation & Performance
- Break complex views into small, focused subviews.
- Avoid performing heavy computations in SwiftUI body properties. Delegate filtering, sorting, and summations to ViewModels or UseCases.
- Use `LazyVStack` and `LazyVGrid` for transaction and category lists.

---

## 5. Definition of Done (DoD) for the iOS Application
The iOS application is certified complete only when:
1. All 69 features in `FEATURE-PARITY-MATRIX.md` are implemented and verified.
2. All unit tests for `Amount`, `SplitCalculationEngine`, `FinancialCalculatorEngine`, and `NetBalanceEngine` pass with 100% assertion parity against the Android test suite.
3. A JSON backup exported from the Android app can be successfully imported into the iOS app with **0 subunits deviation** in Net Balance and Category totals.
4. VoiceOver accessibility labels are verified on all buttons, amounts, and progress indicators.
5. The app compiles with zero Swift compiler warnings under strict concurrency.

