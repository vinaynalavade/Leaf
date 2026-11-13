# Leaf Architecture: Native iOS Architecture & Technology Selection Blueprint

## 1. Executive Summary & Recommended Target
This document outlines the architectural blueprint for engineering Leaf natively for Apple iOS devices. The objective is to build a top-tier native iOS application in Swift and SwiftUI that honors Apple's design philosophy while maintaining 100% financial and business parity with the Android application.

### Recommended Target Platform
- **Language**: Swift 5.10 / Swift 6 (Strict Concurrency Checking).
- **UI Framework**: SwiftUI (Declarative, reactive UI).
- **Minimum Deployment Target**: **iOS 17.0** (Recommended).
  - *Rationale*: iOS 17 provides the `@Observable` observation macro, native interactive widgets via `AppIntent`, Swift Charts `SectorMark` for donut charts, and advanced `NavigationStack` transitions. (If iOS 16 support is required, use `ObservableObject` / `@Published`).

---

## 2. Persistence Layer Evaluation & Recommendation

Choosing the right persistence technology is critical for financial apps requiring data integrity, strict migration tracking, and cross-platform backup compatibility.

| Evaluation Criteria | Apple SwiftData | Apple Core Data | Native SQLite via GRDB.swift |
| :--- | :--- | :--- | :--- |
| **Parity with Android SQLite** | Low (Internal schema abstraction) | Moderate (SQLite store, but altered table schemas) | **Exact 100% Match** (Can read Android `.db` directly) |
| **64-bit Subunit Precision** | Excellent (`Int64`) | Excellent (`Integer 64`) | **Flawless** (`INTEGER` / `Int64`) |
| **Reactive Observability** | `@Query` (SwiftUI only) | `NSFetchedResultsController` | **`ValueObservation`** (Pure Swift reactive streams) |
| **Complex Multi-Table Joins** | Immature in early versions | Verbose, moderate performance | **Blazing Fast** (Native raw SQL & typed associations) |
| **Migration Control** | Automatic / lightweight | Versioned mapping models | **Explicit SQL Migrations** (Matches Room 1:1) |
| **Direct DB File Restore** | Incompatible | Extremely difficult | **Instant 1-Click SQLite File Import** |

### Definitive Persistence Recommendation: **GRDB.swift**
**GRDB.swift** is the premier SQLite toolkit for native iOS applications.
- **Why**: It allows the iOS app to execute the **exact same SQLite schema and migrations (v1 to v10)** as Android Room. A user can export their Android SQLite database and restore it directly on an iPhone with zero transformation.
- **Alternative**: If a pure Apple zero-dependency approach is required by enterprise policy, implement **Core Data** with an SQLite persistent store and custom value transformers.

---

## 3. iOS Architectural Pattern: MVVM + Modern Swift Concurrency

Leaf iOS will follow the **Clean MVVM** architectural pattern:

```
┌─────────────────────────────────────────────────────────────┐
│                    PRESENTATION LAYER                       │
│  SwiftUI Views • ViewModels (@Observable, @MainActor)       │
│  NavigationStack • Sheet Modals • Environment Injections    │
└──────────────────────────────┬──────────────────────────────┘
                               │ (Calls UseCases / Awaits Async Streams)
                               ▼
┌─────────────────────────────────────────────────────────────┐
│                       DOMAIN LAYER                          │
│  Domain Structs (Transaction, Category, Amount)             │
│  Pure Calculation Engines (Split, Financial, NetBalance)    │
│  Domain Use Cases (SaveTransactionUseCase, etc.)            │
│  Repository Protocols (TransactionRepositoryProtocol)       │
└──────────────────────────────┬──────────────────────────────┘
                               │ (Implements Protocols)
                               ▼
┌─────────────────────────────────────────────────────────────┐
│                        DATA LAYER                           │
│  Repository Implementations • GRDB Database & Record Types  │
│  Database Pool (WAL Mode) • Keychain PIN Vault              │
│  UserDefaults (Non-sensitive) • iCloud Drive Sync Engine    │
└─────────────────────────────────────────────────────────────┘
```

### 3.1 View & ViewModel Layer
- **ViewModels**: Annotated with `@Observable` and `@MainActor`.
- **State Flow**: ViewModels expose immutable domain structs. Mutations execute asynchronously and update published properties on the main thread:
  ```swift
  @Observable
  @MainActor
  final class DashboardViewModel {
      private(set) var netBalance: Amount = .zero
      private(set) var recentTransactions: [Transaction] = []
      private(set) var isLoading: Bool = false
      
      private let getFinancialSummaryUseCase: GetFinancialSummaryUseCase
      
      init(getFinancialSummaryUseCase: GetFinancialSummaryUseCase) {
          self.getFinancialSummaryUseCase = getFinancialSummaryUseCase
      }
      
      func loadData() async {
          // Asynchronous stream observation
      }
  }
  ```

### 3.2 Domain Layer (Pure Swift)
- Independent of UIKit, SwiftUI, or persistence frameworks.
- Domain models are immutable value-type `struct`s conforming to `Identifiable`, `Equatable`, and `Codable`.
- Calculation engines implemented as stateless, thread-safe `enum` or `struct` namespaces with static pure functions.

### 3.3 Data Layer (GRDB & Protocols)
- Repositories conform to domain protocols, allowing trivial mocking for unit tests.
- Database access uses `DatabasePool` configured with Write-Ahead Logging (`WAL`) and multi-reader concurrency.

---

## 4. Dependency Injection via SwiftUI Environment

An `AppContainer` singleton manages repository and use case lifecycles, injected at the root of the app:

```swift
@MainActor
final class AppContainer: ObservableObject {
    let databasePool: DatabasePool
    let transactionRepository: TransactionRepositoryProtocol
    let categoryRepository: CategoryRepositoryProtocol
    let userPreferencesStore: UserPreferencesStore
    let securePinManager: SecurePinManager
    
    init() {
        // Initialize SQLite pool, repositories, and managers
    }
}

// In App Entry Point:
@main
struct LeafApp: App {
    @StateObject private var container = AppContainer()
    
    var body: some Scene {
        WindowGroup {
            RootContentView()
                .environmentObject(container)
        }
    }
}
```

---

## 5. Security & Hardware Integration on iOS

| Android Component | iOS Native Implementation |
| :--- | :--- |
| **Secure PIN Vault** | **Apple Keychain Services** (`kSecClassGenericPassword` with `kSecAttrAccessibleWhenUnlockedThisDeviceOnly`). |
| **Biometric Auth** | **LocalAuthentication Framework** (`LAContext.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics)` for Face ID / Touch ID). |
| **App Switcher Privacy** | Listen to `sceneWillResignActiveNotification`; place visual blur overlay over key window. |
| **Home Screen Widgets** | **WidgetKit** with `TimelineProvider` and interactive `AppIntent`. |
| **Haptic Feedback** | **Core Haptics** / `UIImpactFeedbackGenerator(.light / .medium)`. |
| **PDF Rendering** | **PDFKit** (`UIGraphicsPDFRenderer` for generation; `PDFView` for display). |

