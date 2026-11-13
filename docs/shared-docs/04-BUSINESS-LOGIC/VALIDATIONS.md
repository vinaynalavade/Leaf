# Leaf Business Logic: Comprehensive Input Validations & System Constraints

## 1. Executive Summary
This document establishes the exhaustive catalog of validation rules, numerical constraints, string limitations, and business invariants enforced across Leaf. Every rule documented here has a direct counterpart in the Android repository and must be implemented with identical precision in the native iOS application.

---

## 2. Transactions Validation Matrix

| Field | Type / Representation | Invariant & Constraints | Android Reference | iOS Equivalent Rule |
| :--- | :--- | :--- | :--- | :--- |
| `amount` | `Amount` (Subunits) | Must be strictly positive: `amount.subunits > 0L`. Maximum allowed value: $10^{14}$ subunits. | `SaveTransactionUseCase.kt` | `amount > 0 && amount <= 100_000_000_000_000` |
| `title` | `String` | `title.trim().isNotBlank()`. Maximum length: 100 characters. | `SaveTransactionUseCase.kt` | `!title.trim().isEmpty && title.count <= 100` |
| `type` | `TransactionType` | Must be either `INCOME` or `EXPENSE`. | `TransactionType.kt` | `enum TransactionType: String { case income, expense }` |
| `category` | `Category` | Must reference an existing database category where `category.type == transaction.type`. | `SaveTransactionUseCase.kt` | Enforce foreign key validation |
| `date` | `Long` (Epoch Millis) | Must be a valid epoch millisecond integer ($> 0$). Historical logging and future dates are permitted. | `DateTimeUtils.kt` | `date.timeIntervalSince1970 > 0` |
| `note` | `String?` | Optional. Maximum length: 500 characters if present. | `Transaction.kt` | `note?.count ?? 0 <= 500` |
| `paymentMethod` | `PaymentMethod` | Must be either `CASH` or `ACCOUNT`. | `PaymentMethod.kt` | `enum PaymentMethod: String { case cash, account }` |

---

## 3. Split & Collect 2.0 Validation Matrix

| Field / Component | Invariant & Constraints | Error Message on Failure | Android Reference |
| :--- | :--- | :--- | :--- |
| `totalAmount` | `totalAmount.subunits > 0L`. Cannot be zero or negative. | *"Total bill amount must be greater than zero."* | `CreateSplitViewModel.kt` |
| `title` | `title.trim().isNotBlank()`. Maximum 100 characters. | *"Please enter a description for the split."* | `CreateSplitViewModel.kt` |
| `participants` Count | Minimum 2 participants required (e.g. "Me" and at least 1 other). | *"At least 2 participants are required to split a bill."* | `SplitCalculationEngine.kt` |
| Participant Names | Trimmed, non-empty, and case-insensitively unique in the list. | *"Participant names must be unique."* | `CreateSplitViewModel.kt` |
| Custom Allocation Sum | Sum of custom amounts must match `totalAmount.subunits` exactly ($0$ tolerance). | *"Allocated amounts do not match total bill. Difference: [amount]"* | `SplitCalculationEngine.kt` |
| Itemized Items | Each item amount $> 0$. Assigned consumers must be a non-empty subset of the bill participants. | *"Item '[name]' must have at least one assigned consumer."* | `SplitItem.kt` |
| Itemized Sum Check | Sum of item amounts cannot exceed `totalAmount.subunits`. | *"Total itemized items exceed the bill total."* | `SplitCalculationEngine.kt` |
| Settlement Integrity | Cannot settle an already settled participant. | *"Participant is already settled."* | `SettleParticipantUseCase.kt` |

---

## 4. Planning & Budgeting Validation Matrix

| Field | Constraints | Error Message on Failure | Android Reference |
| :--- | :--- | :--- | :--- |
| `amount` | `amount.subunits > 0L`. Must be positive. | *"Budget amount must be greater than zero."* | `SaveBudgetUseCase.kt` |
| `month` | Integer in range $1 \dots 12$. | *"Invalid month (1-12)."* | `BudgetEntity.kt` |
| `year` | Integer in range $2000 \dots 2100$. | *"Invalid year."* | `BudgetEntity.kt` |
| Category Uniqueness | Only one budget record per `(year, month, category_id)` tuple. | *"A budget already exists for this category in the selected month."* | `BudgetDao.kt` |
| Overall Uniqueness | Only one overall budget record per `(year, month, category_id = null)` tuple. | *"An overall budget already exists for the selected month."* | `BudgetDao.kt` |

---

## 5. Savings Goals Validation Matrix

| Field | Constraints | Error Message on Failure | Android Reference |
| :--- | :--- | :--- | :--- |
| `name` | `name.trim().isNotBlank()`. Maximum 80 characters. | *"Goal name cannot be empty."* | `SaveSavingsGoalUseCase.kt` |
| `targetAmount` | `targetAmount.subunits > 0L`. Must be positive. | *"Target amount must be greater than zero."* | `SaveSavingsGoalUseCase.kt` |
| `targetDate` | Optional epoch millis. If set, must be in the future relative to goal creation. | *"Target date must be in the future."* | `AddEditGoalDialog.kt` |
| `contribution` | Subunits must be $> 0L$. Cannot contribute zero or negative funds. | *"Contribution amount must be greater than zero."* | `AddContributionUseCase.kt` |

---

## 6. Categories Validation Matrix

| Field / Action | Invariant & Constraints | Failure Handling | Android Reference |
| :--- | :--- | :--- | :--- |
| `name` | Trimmed, non-empty. Maximum 50 characters. | Error banner: *"Category name cannot be empty."* | `SaveCategoryUseCase.kt` |
| Duplicate Check | Case-insensitive match against categories of the same `type`. | Error banner: *"A [type] category named '[name]' already exists."* | `SaveCategoryUseCase.kt` |
| Icon Identifier | Must match one of the 22 approved vector identifiers. | Fallback to `"category"` | `AddEditCategoryDialog.kt` |
| Color Hex | Must match 6-character hex `#RRGGBB`. | Fallback to `#64748B` | `AddEditCategoryDialog.kt` |
| Delete System Default | Cannot delete where `is_default == true`. | Exception / Result Error: *"Default system categories cannot be deleted."* | `DeleteCategoryUseCase.kt` |
| Delete In-Use Category | Cannot delete if any transaction in database references this category ID. | Exception / Result Error: *"Cannot delete category because existing transactions depend on it."* | `DeleteCategoryUseCase.kt` |

---

## 7. Reminders Validation Matrix

| Field | Constraints | Default Value | Android Reference |
| :--- | :--- | :--- | :--- |
| `title` | Trimmed, non-empty (max 100 characters). | Required | `ReminderEntity.kt` |
| `amount` | `amount_subunits >= 0L` (can be 0 for purely informational reminders). | `0L` | `ReminderEntity.kt` |
| `type` | Must be one of `EMI`, `CREDIT_CARD`, `BILL`, `CUSTOM`. | `CUSTOM` | `ReminderType.kt` |
| `dueDate` | Valid future or current epoch millis ($> 0$). | Required | `ReminderEntity.kt` |
| `notificationHour` | Integer in range $0 \dots 23$. | `9` (9:00 AM) | `ReminderEntity.kt` |
| `notificationMinute` | Integer in range $0 \dots 59$. | `0` | `ReminderEntity.kt` |
| `reminderOffsetDays` | Integer in range $0 \dots 30$. | `1` (1 day before) | `ReminderEntity.kt` |

---

## 8. Security & App Lock Constraints

| Mechanism | Constraint / Invariant | Android Reference | iOS Equivalent |
| :--- | :--- | :--- | :--- |
| PIN Format | Strictly 4 numeric digits: `^\d{4}$`. | `SecurePinManager.kt` | `NSRegularExpression(pattern: "^\\d{4}$")` |
| PIN Salt | 16-byte cryptographically secure random bytes (`SecureRandom`). | `SecurePinManager.kt` | `SecRandomCopyBytes` |
| Max Failed Attempts | Exactly 5 consecutive incorrect attempts allowed. | `SecurePinManager.kt` | Local attempt counter |
| Lockout Duration | 30-second rate-limit lockout enforced upon 5 failed attempts. | `SecurePinManager.kt` | Timestamp cooldown comparison |
| Biometric Fallback | Device PIN / passcode fallback permitted if biometrics fail. | `AppLockManager.kt` | `LAContext.evaluatePolicy` |

---

## 9. Currency & Formatting Constraints

| Constraint | Specification |
| :--- | :--- |
| Negative Amount Display | Prefixed with `-` symbol before the currency symbol (e.g. `-₹500.00`). |
| Thousand Grouping | Uses standard localized grouping: Indian format (`#,##,##0.00`) for INR; International format (`#,##0.00`) for USD/EUR/GBP. |
| Zero Handling | Zero subunits always formats cleanly as `₹0.00` (or `¥0` for JPY), never blank or `null`. |

