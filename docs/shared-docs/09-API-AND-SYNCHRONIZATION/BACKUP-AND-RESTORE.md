# Leaf API & Synchronization: Backup File Schemas, Serialization & CSV Specifications

## 1. Executive Summary
This document specifies the exact JSON serialization format, versioning protocols, and CSV export structures used by Leaf. The JSON schema defined here is the universal data exchange standard between Android and iOS.

---

## 2. Universal JSON Backup Schema (Version 2)

A standard Leaf backup file is named:
`Leaf_Backup_YYYY-MM-DD_HH-mm.json`

### Top-Level JSON Structure
```json
{
  "version": 2,
  "schemaVersion": 10,
  "appName": "Leaf",
  "exportTimestamp": 1730718000000,
  "currencyCode": "INR",
  "data": {
    "categories": [ ... ],
    "transactions": [ ... ],
    "recurring_transactions": [ ... ],
    "split_groups": [ ... ],
    "split_expenses": [ ... ],
    "split_participants": [ ... ],
    "budgets": [ ... ],
    "savings_goals": [ ... ],
    "savings_goal_contributions": [ ... ],
    "reminders": [ ... ],
    "user_preferences": { ... }
  }
}
```

---

## 3. Entity Serialization Specifications

### 3.1 `categories`
```json
{
  "id": 1,
  "name": "Food & Dining",
  "iconName": "restaurant",
  "colorHex": "#EF4444",
  "type": "EXPENSE",
  "isDefault": true
}
```

### 3.2 `transactions`
```json
{
  "id": 101,
  "amountSubunits": 18000,
  "type": "EXPENSE",
  "categoryId": 1,
  "paymentMethod": "CASH",
  "note": "Coffee and bagel",
  "timestamp": 1730718000000,
  "createdAt": 1730718000000,
  "updatedAt": 1730718000000
}
```

### 3.3 `split_expenses` & `split_participants`
```json
{
  "id": 201,
  "title": "Weekend Dinner",
  "totalAmountSubunits": 320000,
  "date": 1730718000000,
  "categoryId": 1,
  "paidBy": "Me",
  "splitMethod": "EQUAL",
  "addToTransactions": true,
  "expenseTransactionId": 102,
  "paymentMethod": "ACCOUNT",
  "groupId": null,
  "itemsJson": null
}
```
```json
{
  "id": 301,
  "splitExpenseId": 201,
  "name": "Rahul",
  "isCurrentUser": false,
  "amountSubunits": 80000,
  "settlementStatus": "PENDING",
  "settledAt": null,
  "settlementTransactionId": null,
  "phoneNumber": "+919876543210"
}
```

### 3.4 `budgets`
```json
{
  "id": 401,
  "categoryId": 1,
  "amountSubunits": 1500000,
  "month": 11,
  "year": 2026
}
```

### 3.5 `savings_goals` & `contributions`
```json
{
  "id": 501,
  "name": "Japan Trip",
  "targetAmountSubunits": 15000000,
  "targetDate": 1756980000000,
  "note": "Vacation fund",
  "iconName": "flight",
  "colorHex": "#3B82F6",
  "isArchived": false
}
```
```json
{
  "id": 601,
  "goalId": 501,
  "amountSubunits": 1500000,
  "note": "November deposit",
  "timestamp": 1730718000000,
  "transactionId": 103
}
```

### 3.6 `reminders`
```json
{
  "id": 701,
  "title": "Electricity Bill",
  "description": "State power board",
  "amountSubunits": 245000,
  "type": "BILL",
  "dueDate": 1731672000000,
  "recurrence": "MONTHLY",
  "configuredDayOfMonth": 15,
  "reminderOffsetDays": 2,
  "notificationHour": 9,
  "notificationMinute": 0,
  "isEnabled": true,
  "isPaid": false,
  "lastPaidDate": null
}
```

### 3.7 `user_preferences` (Non-Sensitive)
```json
{
  "themeMode": "LIGHT",
  "currency": "INR",
  "openingBalanceSubunits": 5000000,
  "defaultIncomeSource": "ACCOUNT",
  "defaultExpenseSource": "CASH",
  "appLanguage": "EN",
  "userName": "Vinay",
  "dailyReminderHour": 21,
  "dailyReminderMinute": 0
}
```
> [!IMPORTANT]
> **Security Strict Rule**: PIN hashes, PIN salts, and biometric authorization flags are **NEVER** included in backup JSON payloads. Restoring a backup on a new device will prompt the user to establish a fresh local PIN if App Lock is desired.

---

## 4. CSV Export Format Specification

Leaf exports transactions to standard CSV for spreadsheet analysis (Excel, Google Sheets, Numbers).

### Headers
`ID,Date,Time,Type,Category,Amount,Currency,Payment Method,Note`

### Sample Output
```csv
ID,Date,Time,Type,Category,Amount,Currency,Payment Method,Note
101,2026-11-04,15:30:00,EXPENSE,Food & Dining,180.00,INR,CASH,Coffee and bagel
102,2026-11-04,13:00:00,INCOME,Salary,100000.00,INR,ACCOUNT,Monthly company payroll
103,2026-11-03,20:45:00,EXPENSE,Bills & Utilities,2450.00,INR,ACCOUNT,Electricity bill
```
- **Rules**:
  - Amounts are output in human-readable primary currency units with 2 decimal places (e.g. `180.00`), using `.` as decimal separator.
  - Commas inside `Note` fields are wrapped in double quotes (`"Note with, comma"`).

