# Leaf Architecture: Android to iOS Technology Translation Matrix

## 1. Executive Summary
This document provides an exhaustive architectural translation dictionary mapping every Android technology, framework, pattern, and idiom used in Leaf directly to its native Apple iOS counterpart.

---

## 2. Language & Core Paradigm Mapping

| Android / Kotlin Paradigm | iOS / Swift Paradigm | Implementation Details & Behavioral Notes |
| :--- | :--- | :--- |
| `data class` | `struct` (`Equatable`, `Codable`, `Hashable`) | Swift value types provide value semantics and automatic memberwise initializers. |
| `@JvmInline value class Amount(val subunits: Long)` | `struct Amount: RawRepresentable` | Swift value type wrapping `Int64` with operator overloading (`+`, `-`, `<`, `==`). |
| `sealed interface` / `sealed class` | `enum` with Associated Values | Swift enums model closed polymorphism with pattern matching (`switch`). |
| `Flow<T>` (Cold Reactive Stream) | `AsyncSequence` / `AsyncStream<T>` / `CurrentValueSubject` | Reactive data streaming from persistence layer into ViewModels. |
| `StateFlow<T>` (Hot State Holder) | `@Observable` property / `CurrentValueSubject<T, Never>` | Exposes real-time UI state observed by SwiftUI views. |
| `suspend fun` (Coroutines) | `async` / `await` | Native Swift Concurrency model with cooperative cancellation. |
| `Dispatchers.IO` | `Task.detached(priority: .background)` or background `Actor` | Offloads disk/database operations off the main thread. |
| `Dispatchers.Main.immediate` | `@MainActor` | Guarantees UI mutations execute synchronously on the main runloop. |
| `by lazy` | `lazy var` or closure initialization | Lazy instantiation of singleton dependencies in service container. |

---

## 3. Framework & Platform Mapping Matrix

| Functional Area | Android Implementation | iOS Native Implementation |
| :--- | :--- | :--- |
| **UI Framework** | Jetpack Compose (Declarative) | **SwiftUI** (Declarative) |
| **Design System** | Material 3 (`ColorScheme`, `Shapes`, `Typography`) | **Apple Human Interface Guidelines** (`Color`, `.continuous`, Dynamic Type) |
| **Navigation** | `NavHost` with Compose Navigation & BottomBar | `TabView` + `NavigationStack` with typed destination routes |
| **Sheets & Dialogs** | `ModalBottomSheet`, `AlertDialog` | `.sheet(isPresented:)`, `.alert()`, `.confirmationDialog()` |
| **Local Database** | Room ORM over SQLite (`expense_tracker.db`) | **GRDB.swift** over SQLite (or Apple **Core Data**) |
| **Preferences** | `androidx.datastore.preferences` | **`UserDefaults`** / `@AppStorage` |
| **Secure PIN Vault** | `EncryptedSharedPreferences` (AES-256-GCM) | **Apple Keychain Services** (`Security.framework`) |
| **Biometric Auth** | `androidx.biometric.BiometricPrompt` | **`LocalAuthentication`** (`LAContext`, Face ID / Touch ID) |
| **Recents Privacy** | `WindowManager.LayoutParams.FLAG_SECURE` | Blurred overlay on `sceneWillResignActiveNotification` |
| **Scheduled Reminders** | `AlarmManager` with `BroadcastReceiver` | **`UserNotifications`** (`UNCalendarNotificationTrigger`) |
| **Background Tasks** | `WorkManager` (`CoroutineWorker`) | **`BackgroundTasks`** (`BGAppRefreshTask`) |
| **Home Screen Widgets** | `AppWidgetProvider` with `RemoteViews` | **WidgetKit** (`TimelineProvider` & interactive `AppIntent`) |
| **Launcher Shortcuts** | `ShortcutManager` via `shortcuts.xml` | **`UIApplicationShortcutItem`** ("Quick Actions") |
| **PDF Generation** | Android `PdfDocument` with `Canvas` drawing | **`UIGraphicsPDFRenderer`** (`PDFKit`) |
| **PDF Viewing** | Custom Compose Canvas / AndroidView renderer | **`PDFKit.PDFView`** inside `UIViewRepresentable` |
| **QR Code Generation** | Custom Bitmap Matrix renderer | **`CoreImage`** (`CIFilter.qrCodeGenerator()`) |
| **Haptic Feedback** | `LocalHapticFeedback.current` | **`UIImpactFeedbackGenerator`** / **Core Haptics** |
| **Photo Picking** | `ActivityResultContracts.PickVisualMedia` | **`PhotosUI.PhotosPicker`** |
| **External Sharing** | `Intent.ACTION_SEND` with `FileProvider` | **`UIActivityViewController`** (`ShareLink`) |
| **Dependency Injection**| Manual Container (`AppContainer.kt`) | Manual Container (`AppContainer.swift`) via `@EnvironmentObject` |

---

## 4. Architectural Layer Translation

### Presentation Layer
```
Android: Composable Screen  ──>  ViewModel (StateFlow)  ──>  UseCases
iOS:     SwiftUI View       ──>  ViewModel (@Observable) ──>  UseCases
```

### Data Layer
```
Android: UseCase  ──>  Repository  ──>  Room DAO  ──>  SQLite Database
iOS:     UseCase  ──>  Repository  ──>  GRDB / CoreData ──>  SQLite Database
```

