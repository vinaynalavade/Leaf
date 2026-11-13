# Leaf Issues & Technical Debt: Known Inconsistencies & Edge-Case Hazards

## 1. Executive Summary
During the comprehensive architectural audit of the Android codebase, several subtle inconsistencies, edge-case hazards, and historical quirks were identified. This document serves as a defensive roadmap to ensure these issues are resolved or deliberately avoided during the native iOS implementation.

---

## 2. Identified Inconsistencies & Hazards

### 2.1 Fallback Uncategorized In-Memory Construct
- **Android Observation**: In `Category.kt`, `Category.UNCATEGORIZED` (`id = 0L`, name `"Other"`, icon `"category"`) is an in-memory object and does **not** exist as a physical row in the `categories` SQLite table.
- **Risk**: If an imported transaction or external JSON payload contains `category_id = 0`, SQLite foreign key verification (`FOREIGN KEY(category_id) REFERENCES categories(id)`) will fail if foreign keys are enforced via `PRAGMA foreign_keys = ON;`.
- **iOS Recommendation**: Either seed an explicit "Other / Uncategorized" system category with `id = 0` (or `id = 20`) in SQLite, or ensure imported records are sanitized to reference a valid default category ID.

### 2.2 Split Deletion Foreign Key Nullability
- **Android Observation**: In `Migration_4_5`, `expense_transaction_id` was added to `split_expenses`, and `settlement_transaction_id` was added to `split_participants`. However, neither column has a strict SQLite foreign key constraint defined in the database schema; they are maintained as soft integer references.
- **Risk**: If a user manually deletes a transaction from the main ledger, the split expense still holds the dead integer ID.
- **iOS Recommendation**: In the iOS database schema, add formal foreign keys with `ON DELETE SET NULL`:
  `FOREIGN KEY(expense_transaction_id) REFERENCES transactions(id) ON DELETE SET NULL`.

### 2.3 `items_json` Embedded String vs. Relational Table
- **Android Observation**: In Migration 9->10 (Split 2.0 itemization), itemized items and custom allocations were introduced as an embedded JSON string column (`split_expenses.items_json TEXT`) rather than creating a normalized `split_items` table.
- **Risk**: Querying or aggregating itemized expenses (e.g., "How much did Rahul spend on drinks across all splits?") requires parsing raw JSON strings in application memory rather than fast SQL index queries.
- **iOS Recommendation**: Support parsing `items_json` for cross-platform backup compatibility, but consider normalizing into a dedicated `split_items` table for internal iOS persistence if advanced item analytics are planned.

### 2.4 Daylight Saving Time (DST) Jumps on Local Alarms
- **Android Observation**: The daily 9:00 PM reminder relies on `AlarmManager.setExactAndAllowWhileIdle()` by adding 24 hours ($86,400,000$ ms) to the previous alarm.
- **Risk**: On the night of a DST transition (+1 hour or -1 hour), adding fixed milliseconds causes the reminder to fire at 8:00 PM or 10:00 PM instead of 9:00 PM local wall-clock time.
- **iOS Recommendation**: On iOS, use `UNCalendarNotificationTrigger(dateMatching: DateComponents(hour: 21, minute: 0), repeats: true)`, which is handled natively by `UserNotifications` and automatically respects DST shifts.

### 2.5 GitHub API Unauthenticated Rate Limiting
- **Android Observation**: `GitHubReleaseService` queries `api.github.com` without an API token, which has an IP limit of 60 requests per hour. On shared Wi-Fi networks (colleges, offices), users occasionally receive HTTP 403.
- **iOS Resolution**: Not applicable to iOS, as updates are discovered via the public iTunes Lookup API and downloaded through the Apple App Store.

