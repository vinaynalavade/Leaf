# FEATURE SPECIFICATION: FEAT-13 — BACKUP, RESTORE & CLOUD SYNC

## 1. Feature ID
`FEAT-13`

## 2. Feature Name
Data Backup & Restore: Versioned JSON (v1 & v2), RFC-4180 CSV & Cloud Sync

## 3. Purpose
Guarantees 100% user data ownership and disaster recovery without proprietary servers. Supports full application versioned JSON backups, flexible RFC-4180 CSV export/import, private cloud backup sync to personal Google Drive `appDataFolder` (and iOS CloudKit / iCloud Drive), automated background backups, and smart restore prompts on re-installation.

## 4. Current Implementation Status
**VERIFIED (IMPLEMENTED)** — Complete with pure Kotlin zero-dependency JSON parser, CSV helper, WorkManager scheduler, Google Drive REST service, and automated serialization/deserialization tests.

## 5. User-Facing Functionality
- **Backup & Restore Screen (`BackupScreen`)**:
  - **Local Backup & Restore**:
    - "Create Backup (JSON)": Generates encrypted/structured JSON file and opens system save/share sheet.
    - "Restore from File": Selects JSON backup file, validates schema, previews contents (transactions count, categories count, creation date), and restores with confirmation.
  - **CSV Export & Import**:
    - "Export Transactions (CSV)": Exports all transactions as RFC-4180 CSV with standard header.
    - "Import Transactions (CSV)": Imports external bank or spreadsheet CSVs with header detection and error preview.
  - **Google Drive Cloud Sync**:
    - "Connect Google Account": Signs in via OAuth2 to personal Google Drive.
    - Displays connected account email, avatar, and last backup timestamp.
    - "Back Up to Drive Now": Uploads `leaf_backup.json` to private `appDataFolder`.
    - "Restore from Drive": Downloads and validates cloud backup.
    - "Automatic Daily Backup" switch toggle.
    - "Disconnect Account" button.
- **Smart Restore Prompt (`RestorePromptDialog`)**:
  - Automatically checks on first launch if the connected account or device has an existing cloud backup.
  - Prompts: "Found an existing backup from [Date]. Would you like to restore your data?"

## 6. Entry Points
- Settings menu -> "Backup & Restore" (`Screen.BackupRestore`).
- First launch welcome onboarding flow.

## 7. Screen Structure
```text
BackupScreen
├── TopBar (Back Button, Title "Backup & Restore")
├── CloudBackupSection
│   ├── Google Account Card (Avatar, Email, Status)
│   ├── Last Cloud Backup Timestamp ("2 hours ago")
│   ├── Button "Back Up to Cloud" & Button "Restore from Cloud"
│   └── Switch "Automatic Daily Backup"
├── LocalFileSection
│   ├── Action Card "Create JSON Backup"
│   └── Action Card "Restore from JSON File"
└── CsvSection
    ├── Action Card "Export Transactions (CSV)"
    └── Action Card "Import Transactions (CSV)"
```

## 8. UI Components
- `BackupScreen`: Container view.
- `ReplaceDataConfirmationDialog`: Critical warning dialog explaining that restore replaces local records.
- `RestorePreviewDialog`: Displays backup version, app version, transaction count, category count, and creation date before restoring.
- `JsonBackupParser`: Pure dependency-free JSON serializer and deserializer.
- `CsvTransactionHelper`: RFC-4180 compliant CSV generator and parser.

## 9. User Interactions
- Tap "Create Backup": Generates file named `leaf_backup_YYYYMMDD_HHMMSS.json`.
- Tap "Restore from File": Opens document picker (`*/*` or `application/json`).
- Tap "Import CSV": Opens file picker for `.csv`. Displays summary of valid vs invalid rows before importing.

## 10. Backup File Specifications

### 10.1 Versioned JSON Backup (`BackupData`)
Current schema version: **Version 2** (Backward compatible with Version 1).
```json
{
  "backupVersion": 2,
  "appVersion": "1.1.3",
  "createdAt": 1730000000000,
  "preferences": {
    "openingBalanceSubunits": 100000,
    "currencyCode": "INR",
    "themeMode": "SYSTEM",
    "dailyReminderEnabled": true,
    "dailyReminderHour": 21,
    "dailyReminderMinute": 0,
    "emiRemindersEnabled": true,
    "notificationsMasterEnabled": true,
    "budgetAlertsEnabled": true,
    "monthlyBudgetLimitSubunits": 5000000,
    "recurringRemindersEnabled": true,
    "recurringReminderAdvanceDays": 1,
    "savingsGoalNotificationsEnabled": true
  },
  "categories": [ ... ],
  "transactions": [ ... ],
  "recurringTransactions": [ ... ],
  "budgets": [ ... ],
  "savingsGoals": [ ... ],
  "savingsGoalContributions": [ ... ],
  "splitGroups": [ ... ],
  "splitExpenses": [ ... ],
  "splitParticipants": [ ... ],
  "reminders": [ ... ]
}
```

### 10.2 CSV Format (`CsvTransactionHelper`)
- Header: `Date,Type,Category,Amount,Currency,Payment Method,Note,Created At`
- Escaping: Standard RFC-4180 quotes with `""` escape sequence.
- Date parser fallback: Parses `yyyy-MM-dd HH:mm:ss`, `yyyy-MM-dd`, or raw epoch milliseconds.

## 11. Validation Rules
- `ValidateBackupUseCase`:
  - Must be a valid JSON object with `categories` and `transactions` arrays.
  - Verifies presence of required fields (`id`, `amountSubunits`, `type`, `categoryId`, `timestamp`).
  - Unsupported future versions rejected with user-friendly message.
- `ValidateImportUseCase`:
  - Rejects CSV rows with negative amounts, missing types, or invalid dates.
  - Matches category names case-insensitively; creates new category if not found.

## 12. Business Rules
- **Full Database Replacement:** Restoring a backup replaces local database entities atomically to prevent duplicate keys or foreign key collisions.
- **Rescheduling Reminders:** After a successful restore, all scheduled alarms and reminders are automatically rescheduled (`RescheduleAllRemindersUseCase`).
- **Security Credentials Omission:** Application PIN hashes, salts, lockout counters, and OAuth tokens are strictly excluded from backups.
- **Cloud Storage Scope:** Stored inside the private `appDataFolder` of Google Drive (hidden from user's regular Drive file list to prevent accidental corruption).

## 13. Calculation Logic
- Subunits: Preserved as exact integers in both JSON and CSV imports/exports.

## 14. Database Interactions
- Atomic transaction execution:
  ```kotlin
  database.withTransaction {
      clearAllTables()
      categoryDao.insertCategories(...)
      transactionDao.insertTransactions(...)
      budgetDao.insertBudgets(...)
      // ... all tables
  }
  ```

## 15. State Management
- `BackupViewModel`: Exposes `uiState: StateFlow<BackupUiState>` tracking cloud connection, upload progress, and validation dialogs.

## 16. Navigation
- Accessible from Settings. File picker launches system document picker.

## 17. Error Handling
- Corrupted JSON / malformed syntax: Emits `AppError.BackupError` with exact error message without modifying current data.
- Cloud upload failure: Records `lastBackupStatus = "FAILED"` and `lastBackupError`.

## 18. Edge Cases
- Restoring v1 backup on v2 app: Automatically supplies empty lists for new tables (budgets, savings goals, split expenses, reminders) without failing.
- CSV import with non-standard column order: Header scanner maps column positions dynamically.

## 19. Dependencies
- `BackupRepository`
- `GoogleDriveBackupRepository`
- `JsonBackupParser`
- `CsvTransactionHelper`
- `RescheduleAllRemindersUseCase`

## 20. Relevant Android Source Files
- `app/src/main/java/com/vinaynalavade/expensetracker/core/backup/BackupData.kt`
- `app/src/main/java/com/vinaynalavade/expensetracker/core/backup/JsonBackupParser.kt`
- `app/src/main/java/com/vinaynalavade/expensetracker/core/backup/CsvTransactionHelper.kt`
- `app/src/main/java/com/vinaynalavade/expensetracker/data/repository/BackupRepositoryImpl.kt`
- `app/src/main/java/com/vinaynalavade/expensetracker/data/repository/GoogleDriveBackupRepositoryImpl.kt`

## 21. Relevant Tests
- `app/src/test/java/com/vinaynalavade/expensetracker/BackupSerializationTest.kt`
- `app/src/test/java/com/vinaynalavade/expensetracker/BackupValidationTest.kt`
- `app/src/test/java/com/vinaynalavade/expensetracker/BackupRestoreV2Test.kt`
- `app/src/test/java/com/vinaynalavade/expensetracker/TransactionExportImportTest.kt`

## 22. iOS Implementation Expectations
- Implement as `BackupRestoreView.swift`.
- Use SwiftUI `.fileExporter` and `.fileImporter` with `UniformTypeIdentifiers` (`UTType.json`, `UTType.commaSeparatedText`).
- **iOS Cloud Storage Mapping:**
  - Support **iCloud Drive / CloudKit** as the native Apple private cloud sync solution.
  - Optionally support Google Drive OAuth sync via Google Sign-In SDK for cross-platform backup sharing.
  - JSON serialization logic (`Codable`) must produce identical JSON keys to ensure cross-platform import parity between Android and iOS.

## 23. Acceptance Criteria
1. JSON backup generated on Android restores flawlessly on iOS with 100% data parity.
2. CSV export follows standard RFC-4180 format and imports cleanly into Excel or Apple Numbers.
3. Restoring data resets and reschedules all reminders and daily notifications automatically.
4. Security PIN and biometrics are never overwritten by restoring a backup.

