# Leaf Architecture: Android Application Architecture Audit

## 1. Executive Summary
The Android Leaf application is engineered using **Clean Architecture** combined with **Unidirectional Data Flow (UDF)**. It maintains strict boundaries between presentation, domain, and data layers, ensuring business logic and financial calculations are 100% decoupled from Android framework APIs.

---

## 2. Layer-by-Layer Architectural Breakdown

```
┌─────────────────────────────────────────────────────────────┐
│                    PRESENTATION LAYER                       │
│  Jetpack Compose UI • Screen Composables • ViewModels       │
│  StateFlow<UiState> • User Intents / Actions • Theme Tokens │
└──────────────────────────────┬──────────────────────────────┘
                               │ (Calls UseCases / Collects Domain Models)
                               ▼
┌─────────────────────────────────────────────────────────────┐
│                       DOMAIN LAYER                          │
│  Pure Kotlin Business Logic • Domain Models (Transaction)   │
│  Calculation Engines (Split, Financial, NetBalance)         │
│  Use Cases (SaveTransaction, SettleParticipant, etc.)       │
│  Repository Interfaces (TransactionRepository, etc.)        │
└──────────────────────────────┬──────────────────────────────┘
                               │ (Implements Interfaces)
                               ▼
┌─────────────────────────────────────────────────────────────┐
│                        DATA LAYER                           │
│  Repository Implementations • Room Database & DAOs          │
│  Database Entities (TransactionEntity) • Mappers            │
│  DataStore Preferences • Google Drive Client • Workers      │
└─────────────────────────────────────────────────────────────┘
```

### 2.1 Presentation Layer (`presentation/`)
- **Jetpack Compose**: 100% declarative UI authored without legacy XML layouts (except for AppWidget RemoteViews).
- **ViewModels**: Extend `androidx.lifecycle.ViewModel`. They expose immutable `StateFlow<UiState>` to the UI and process user actions via public member functions.
- **State Preservation**: UI states are collected in Composables using `collectAsStateWithLifecycle()` to stop collection when the app enters the background.

### 2.2 Domain Layer (`domain/`)
- **Pure Kotlin**: Zero dependencies on `android.*` packages.
- **Single-Responsibility Use Cases**: Encapsulate distinct business workflows (`SaveTransactionUseCase`, `DeleteCategoryUseCase`, `GetWidgetFinancialSummaryUseCase`).
- **Deterministic Engines**: Pure singleton calculation objects (`SplitCalculationEngine`, `FinancialCalculatorEngine`, `NetBalanceEngine`).

### 2.3 Data Layer (`data/`)
- **Room Persistence**: Embedded SQLite datastore backed by Room ORM. Room DAOs expose reactive `kotlinx.coroutines.flow.Flow` streams for real-time UI updates.
- **Mappers**: Explicit bidirectional mapping functions between database entities (`TransactionEntity`) and domain models (`Transaction`).
- **Preferences**: Non-sensitive settings persisted via `androidx.datastore.preferences`.

---

## 3. Dependency Injection Architecture (`AppContainer.kt`)

Rather than relying on reflection-heavy DI frameworks (such as Dagger-Hilt), Leaf uses a lightweight, compile-time manual **Service Locator / Dependency Container** pattern via `AppContainer`:

```kotlin
class AppContainer(private val context: Context) {
    // Database & DAOs
    val database: ExpenseTrackerDatabase by lazy { ExpenseTrackerDatabase.getInstance(context) }
    val transactionDao by lazy { database.transactionDao() }
    val categoryDao by lazy { database.categoryDao() }
    
    // Repositories
    val transactionRepository: TransactionRepository by lazy {
        TransactionRepositoryImpl(transactionDao, categoryDao)
    }
    
    // Use Cases
    val saveTransactionUseCase by lazy { SaveTransactionUseCase(transactionRepository) }
    
    // Security & Preferences
    val securePinManager by lazy { SecurePinManager(context) }
    val userPreferencesRepository: UserPreferencesRepository by lazy {
        UserPreferencesRepositoryImpl(UserPreferencesDataStore(context))
    }
}
```
- **Lifecycle**: Owned by `ExpenseTrackerApp` (`Application` subclass) and accessed across activities and ViewModel factories.

---

## 4. Reactive State Flow & Threading Model

- **Threading Strategy**:
  - UI State Observation: Main Thread (`Dispatchers.Main.immediate`).
  - Database & Filesystem IO: Background Worker Thread Pool (`Dispatchers.IO`).
  - Heavy Calculations & PDF Generation: Default Computation Thread Pool (`Dispatchers.Default`).
- **Reactive Chain**:
  `SQLite Mutation -> Room Invalidation Tracker -> DAO Flow -> Repository Flow -> UseCase Transformation -> ViewModel StateFlow -> Compose Recomposition`.

---

## 5. Architectural Strengths & Key Learnings for iOS
1. **Separation of Concerns**: Domain logic is cleanly isolated. Calculation engines can be ported almost line-by-line into Swift.
2. **Explicit Dependency Injection**: No magical reflection makes tracking dependencies and instantiating ViewModels straightforward.
3. **Immutability Contract**: Domain entities use Kotlin `val` properties, mirroring Swift value-type `struct` behavior.

