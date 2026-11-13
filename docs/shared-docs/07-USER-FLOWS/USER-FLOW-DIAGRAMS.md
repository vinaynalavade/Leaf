# Leaf User Flows: Visual User Flow Diagrams

## 1. Executive Summary
This document provides visual flowcharts modeling the operational states, decision gates, and data persistence pipelines for Leaf's core workflows.

---

## 2. Flowchart 1: Transaction Logging Pipeline

```mermaid
flowchart TD
    Start([User Initiates Log]) --> InputCheck{Input Method}
    InputCheck -->|Dashboard + Button| OpenSheet[Open AddEditTransactionSheet]
    InputCheck -->|Widget / App Shortcut| OpenSheet
    InputCheck -->|Floating Activity| QuickWin[Open QuickAddTransactionActivity]
    
    OpenSheet --> FocusAmount[Focus Number Keypad]
    QuickWin --> FocusAmount
    
    FocusAmount --> EnterAmount[User Inputs Numeric Value]
    EnterAmount --> ValidateAmount{amount.subunits > 0?}
    ValidateAmount -->|No / Zero| DisableSave[Disable Save Button]
    ValidateAmount -->|Yes| SelectCategory[Select Category]
    
    SelectCategory --> PaymentMethod[Select Payment Method: CASH or ACCOUNT]
    PaymentMethod --> OptionalFields[Optional: Note, Timestamp Adjustment]
    OptionalFields --> TapSave[User Taps 'Save']
    
    TapSave --> PreFlightCheck{Category & Subunits Valid?}
    PreFlightCheck -->|No| ShowError[Display Validation Banner]
    PreFlightCheck -->|Yes| InsertDB[(Atomic SQLite Insert: transactions)]
    
    InsertDB --> ReactiveNotify[Notify Room / CoreData Flows]
    ReactiveNotify --> UpdateHero[Update Dashboard Net Balance]
    ReactiveNotify --> UpdateDonut[Recompute Category Donut Chart]
    ReactiveNotify --> TriggerWidget[Dispatch ACTION_WIDGET_REFRESH]
    TriggerWidget --> Dismiss[Dismiss Modal Sheet with Haptic Feedback]
    Dismiss --> End([Done])
```

---

## 3. Flowchart 2: Split & Collect 2.0 (Bill Splitting & Settlement)

```mermaid
flowchart TD
    StartSplit([User Taps + New Split]) --> InputMeta[Enter Title, Total Bill, Payer & Participants]
    InputMeta --> ChooseMethod{Split Method}
    
    ChooseMethod -->|Equal Split| CalcEqual[Run calculateEqualSplit: Remainder to first R]
    ChooseMethod -->|Custom Amount| CalcCustom[User enters custom amounts per person]
    ChooseMethod -->|Itemized Split| CalcItemized[Add Items & Assign Consumers per item]
    
    CalcCustom --> ValidateCustom{Sum == Total Bill?}
    ValidateCustom -->|No| ShowDiff[Show Exact Remainder / Overallocated Banner]
    ValidateCustom -->|Yes| ReadySave[Enable Save]
    
    CalcEqual --> ReadySave
    CalcItemized --> ReadySave
    
    ReadySave --> CheckAddToLedger{Add my share to personal expenses?}
    CheckAddToLedger -->|Yes| FlagLedger[Flag addToTransactions = 1]
    CheckAddToLedger -->|No| FlagLedgerNo[Flag addToTransactions = 0]
    
    FlagLedger --> SaveSplitDB[(Atomic DB Insert: split_expenses + split_participants)]
    FlagLedgerNo --> SaveSplitDB
    
    SaveSplitDB --> CheckPayer{Is Payer Current User?}
    CheckPayer -->|Yes & addToTransactions| AutoExpense[(Insert linked EXPENSE in transactions)]
    CheckPayer -->|No| NoExpense[No expense created for user]
    
    AutoExpense --> SplitSaved[Open SplitDetailScreen]
    NoExpense --> SplitSaved
    
    SplitSaved --> ShareAction{User Action}
    ShareAction -->|Share WhatsApp| GenWA[Format Text with Breakdown & UPI -> Launch WhatsApp]
    ShareAction -->|Show QR| GenQR[Render UPI QR Code Modal for scanning]
    ShareAction -->|Mark Settled| SettleParticipant[User toggles 'Mark as Settled']
    
    SettleParticipant --> SettleDB[(Update split_participants: SETTLED + timestamp)]
    SettleDB --> AutoIncome[(Insert linked INCOME transaction in transactions)]
    AutoIncome --> UpdateDebts[Recompute Net Group Debts]
    UpdateDebts --> EndSplit([Done])
```

---

## 4. Flowchart 3: App Lock & Security Vault State Machine

```mermaid
stateDiagram-v2
    [*] --> Locked : App Cold Launch
    
    state Locked {
        [*] --> CheckingBiometrics
        CheckingBiometrics --> BiometricPrompt : Biometrics Enabled
        CheckingBiometrics --> EnterPIN : PIN Only
        
        BiometricPrompt --> Unlocked : Auth Success
        BiometricPrompt --> EnterPIN : Auth Failed / Cancelled
        
        EnterPIN --> ValidatePIN : 4 Digits Entered
        ValidatePIN --> Unlocked : SHA256(PIN + Salt) Matches
        ValidatePIN --> FailedAttempt : Hash Mismatch
        
        FailedAttempt --> EnterPIN : Attempts < 5
        FailedAttempt --> RateLimited : Attempts == 5
        
        RateLimited --> EnterPIN : 30 Seconds Cooldown Elapsed
    }
    
    state Unlocked {
        [*] --> ActiveSession
        ActiveSession --> Backgrounded : User exits app
        Backgrounded --> ActiveSession : User returns within autoLockGracePeriod
        Backgrounded --> Locked : autoLockDuration expired
    }
    
    Unlocked --> [*] : App Process Terminated
```

---

## 5. Flowchart 4: Cross-Platform Backup & Restore Pipeline

```mermaid
flowchart TD
    StartBackup([User Taps Export Backup]) --> GatherData[Query All 10 DB Tables + UserPreferences]
    GatherData --> BuildJSON[Construct JSON v2 Payload with Metadata]
    BuildJSON --> SaveFile[Save to Local Device or Upload to Google Drive]
    SaveFile --> BackupDone([Export Complete])
    
    StartRestore([User Selects Backup File]) --> ReadPayload[Read JSON Payload]
    ReadPayload --> ValidateSchema{Check version & required arrays}
    ValidateSchema -->|Corrupted / Invalid| RejectBackup[Display 'Invalid backup file format']
    ValidateSchema -->|Valid| PromptConfirm[Display Warning: All existing data will be replaced]
    
    PromptConfirm --> UserConfirm{User Confirms Restore?}
    UserConfirm -->|Cancel| Abort([Restore Aborted])
    UserConfirm -->|Confirm| BeginTxn[(BEGIN ATOMIC TRANSACTION)]
    
    BeginTxn --> ClearTables[Wipe existing records in all 10 tables]
    ClearTables --> RestoreCategories[Restore Categories]
    RestoreCategories --> RestoreTransactions[Restore Transactions]
    RestoreTransactions --> RestoreSplits[Restore Splits & Participants]
    RestoreSplits --> RestoreBudgets[Restore Budgets]
    RestoreBudgets --> RestoreSavings[Restore Goals & Contributions]
    RestoreSavings --> RestoreReminders[Restore Reminders]
    RestoreReminders --> RestorePrefs[Restore User Preferences (Excluding PIN Vault)]
    
    RestorePrefs --> CommitTxn[(COMMIT TRANSACTION)]
    CommitTxn --> RecomputeAll[Trigger full balance & widget recalculation]
    RecomputeAll --> RestartUI[Navigate to Dashboard with success toast]
    RestartUI --> EndRestore([Done])
```

