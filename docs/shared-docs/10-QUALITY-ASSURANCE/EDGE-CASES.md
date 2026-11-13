# Leaf Quality Assurance: Comprehensive Edge Cases & Boundary Conditions

## 1. Executive Summary
Financial software breaks at the boundaries: fractional cents, leap years, timezone adjustments, and sudden device restarts. This document details the specific edge cases discovered during the Android repository audit and establishes the defensive engineering requirements for native iOS implementation.

---

## 2. Mathematical & Financial Edge Cases

### 2.1 The "Leaked Penny" Bill Split Edge Case
- **Scenario**: A bill cannot be divided evenly among participants (e.g. ₹100 divided among 3, 6, or 7 people).
- **Hazard**: Independent rounding leaves an unaccounted remainder (₹99.99 total instead of ₹100.00).
- **Enforced Solution**: Compute integer remainder $R = \text{Total} \pmod N$. Allocate $+1$ subunit to the first $R$ participants in the list. The sum of all shares must strictly equal the total bill down to 0 subunits.

### 2.2 Subunit Integer Overflow & Boundary Limits
- **Scenario**: A user logs multi-crore amounts or performs cumulative additions over 20 years.
- **Hazard**: 64-bit signed integer overflow (`Long.MAX_VALUE` wrap-around into negative numbers).
- **Enforced Solution**: Enforce a strict ceiling of $10^{14}$ subunits (₹100 Crore / \$1 Trillion) per transaction and input validation. This ceiling guarantees that millions of transactions can be aggregated without approaching `Int64.max` ($9.22 \times 10^{18}$).

### 2.3 Negative Net Balance Handling
- **Scenario**: A user spends more money than their current calibrated liquid balance, resulting in a negative net balance (e.g. overdraft or unlogged initial income).
- **Hazard**: Software crashes or formats amounts with broken symbols (e.g. `₹-500.00`).
- **Enforced Solution**: `Amount` supports negative values seamlessly. Format strings must display `-₹500.00` with Rose accent styling, and dashboards must remain fully functional.

### 2.4 Zero-Division in Financial Calculators
- **Scenario**: In EMI, SIP, or RD calculators, user inputs tenure $= 0$ months or interest rate $= 0.0\%$.
- **Hazard**: `NaN` or `Infinity` crashes in exponential power functions (`(1+r)^n / ((1+r)^n - 1)`).
- **Enforced Solution**: Guard clauses intercept zero tenure and zero interest rate. For $r = 0$, $\text{EMI} = \text{Principal} / \text{TenureMonths}$.

---

## 3. Temporal, Calendar & Timezone Edge Cases

### 3.1 Month Boundary Days & Leap Years
- **Scenario**: Recurring transaction or reminder configured for the 31st of every month (e.g., February has 28 or 29 days; April has 30 days).
- **Hazard**: Calendar date calculations throw `DateTimeException` (e.g. "February 31 does not exist").
- **Enforced Solution**: Clamping to the last valid day of the target month:
  $$\text{ScheduledDay} = \min(\text{ConfiguredDayOfMonth}, \text{targetMonth.lengthOfMonth()})$$
  In February of a non-leap year, a 31st-of-month rule fires on February 28. In a leap year, it fires on February 29.

### 3.2 Timezone & Daylight Saving Time (DST) Transitions
- **Scenario**: The user travels internationally across timezones or crosses a 1-hour DST jump.
- **Hazard**: Transactions logged on the same calendar day appear on different dates, or 24-hour reminder alarms fire an hour early/late.
- **Enforced Solution**:
  - Timestamps in SQLite are stored strictly as UTC Epoch Milliseconds.
  - Date boundaries for monthly queries are computed using the user's current local device timezone (`ZoneId.systemDefault()`).

### 3.3 Smart Evening Reminder Suppression
- **Scenario**: At 9:00 PM, the daily evening reminder alarm triggers.
- **Rule**: If the user has **already logged at least one transaction today**, the reminder must be silently suppressed.
- **Edge Condition**: User logged a transaction at 11:00 AM, but deleted it at 4:00 PM. At 9:00 PM, zero active transactions exist. The reminder must fire.

---

## 4. Security & Storage Edge Cases

### 4.1 5 Failed PIN Attempts & Process Killing
- **Scenario**: An unauthorized user fails PIN entry 5 times, triggering a 30-second lockout. The attacker force-quits the app and relaunches it immediately.
- **Hazard**: In-memory attempt counter is reset, bypassing rate limiting.
- **Enforced Solution**: Lockout timestamp is persisted to encrypted storage (`SecurePinManager` / Keychain). Upon cold relaunch, the app compares `currentTimeMillis()` against `lockoutExpiresAt`. If less than 30 seconds have elapsed, the lockout persists.

### 4.2 Category Deletion Protection
- **Scenario**: User attempts to delete a custom category that was used in transactions 2 years ago.
- **Hazard**: Deleting the category would create dangling foreign keys (`ON DELETE RESTRICT` failure) or leave historical transactions without a category.
- **Enforced Solution**: `DeleteCategoryUseCase` queries the database for any transactions referencing the category ID. If count $> 0$, deletion is blocked with a friendly explanation.

### 4.3 Database Restoration over Active Sessions
- **Scenario**: User imports a backup JSON while active database observers are listening.
- **Hazard**: Partial table wiping followed by exception leaves database in an inconsistent state.
- **Enforced Solution**: The entire restore operation executes within an atomic SQLite transaction (`BEGIN TRANSACTION ... COMMIT`). If parsing or insertion fails at any point, `ROLLBACK` restores the previous database state completely.

