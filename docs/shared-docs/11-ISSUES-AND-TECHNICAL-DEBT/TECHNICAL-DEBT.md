# Leaf Issues & Technical Debt: Codebase Debt Catalog & Modernization Guide

## 1. Executive Summary
This document catalogs the technical debt identified in the Android repository. The goal of this analysis is to prevent propagating legacy naming artifacts, architectural compromises, and technical shortcuts into the new native iOS codebase.

---

## 2. Legacy Product Rebranding Debt: "KharchaFlow" Artifacts

Before its official rebranding as **Leaf**, the project was titled **KharchaFlow**. While the user-facing UI, logos, and strings have been completely updated, several internal naming artifacts remain embedded in the codebase:

| Legacy Artifact | Source Location | Impact / Debt Description | iOS Native Guidance |
| :--- | :--- | :--- | :--- |
| `kharchaflow_security_vault` | `SecurePinManager.kt` | EncryptedSharedPreferences master filename for storing PIN salt and hash. | Name Keychain service strictly `com.vinaynalavade.Leaf.keychain`. |
| `KharchaFlow` APK Search Fallback | `GitHubReleaseService.kt` | Regex fallback searching for `KharchaFlow-v*.apk` in release assets. | Not applicable on iOS. |
| Legacy v1 Backup JSON Keys | `BackupRestoreManager.kt` | Code paths supporting JSON v1 backups referencing `kharchaflow` root keys. | Support v1 parser as a legacy fallback, but write only `appName: "Leaf"`. |

---

## 3. Database & Persistence Technical Debt

### 3.1 Room `exportSchema = false`
- **Location**: `ExpenseTrackerDatabase.kt` line 43.
- **Debt**: Room's automatic JSON schema export feature is disabled (`exportSchema = false`). Consequently, schema definitions and migration validation files were not generated into version control.
- **iOS Resolution**: Store full SQL schema definitions and explicit migration tests in the iOS repository under `Tests/MigrationTests.swift`.

### 3.2 Unindexed Unique Budget Constraint Removal (Migration 6 -> 7)
- **Location**: `ExpenseTrackerDatabase.kt` line 204 (`MIGRATION_6_7`).
- **Debt**: Room dropped the strict composite unique indices `index_budgets_overall_unique` and `index_budgets_category_unique` without replacing them with equivalent SQLite constraints. Uniqueness is currently enforced only in application-level Kotlin UseCases (`SaveBudgetUseCase`).
- **iOS Resolution**: Re-establish composite unique indices in the iOS database creation script:
  `CREATE UNIQUE INDEX IF NOT EXISTS index_budgets_category_unique ON budgets (year, month, category_id);`

---

## 4. Architecture & Dependency Injection Debt

### 4.1 Manual Service Locator Boilerplate
- **Location**: `AppContainer.kt`.
- **Debt**: The manual `AppContainer` pattern requires hundreds of lines of lazy property instantiations for every DAO, repository, use case, and manager.
- **iOS Resolution**: Implement modern Swift Dependency Injection using either:
  1. A structured dependency container conforming to protocols.
  2. The SwiftUI `@Environment` injection pattern with mockable protocol types.

### 4.2 Lack of Visual Regression / Snapshot Tests
- **Debt**: The Android codebase contains 59 unit test files with comprehensive business logic coverage, but zero automated screenshot/snapshot tests verifying UI layout stability across dynamic font scaling.
- **iOS Resolution**: Introduce **Swift Snapshot Testing** (`pointfreeco/swift-snapshot-testing`) for the Balance Hero Card, Category Donut Chart, and Transaction Item Card in both Light and Dark modes.

