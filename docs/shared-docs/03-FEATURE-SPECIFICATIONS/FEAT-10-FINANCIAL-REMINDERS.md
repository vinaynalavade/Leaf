# FEATURE SPECIFICATION: FEAT-10 — FINANCIAL OBLIGATIONS & REMINDERS

## 1. Feature ID
`FEAT-10`

## 2. Feature Name
Financial Reminders: Bills, Loan EMIs, Credit Cards & Smart Suppression

## 3. Purpose
Comprehensive financial obligation tracking preventing missed bill deadlines, late payment penalties, and loan defaults. Supports configurable notification offsets, month-end day pinning, in-notification quick actions ("Mark as Paid", "Snooze"), and an intelligent evening reminder engine that quietly suppresses alerts if transactions were already logged.

## 4. Current Implementation Status
**VERIFIED (IMPLEMENTED)** — Complete with separate `reminders` table, AlarmManager scheduler, broadcast receivers, notification channels, custom chime, and automated tests.

## 5. User-Facing Functionality
- **Reminders Screen (`RemindersScreen`)**:
  - Filter tabs: `UPCOMING` (Due soon), `PAID` (Completed in current cycle), `ALL`.
  - Reminder Card: Displays obligation type icon (Loan, Bill, Card, Rent, Subscription), Title, Due Date, Due in X days badge, Amount, and direct "Mark Paid" button.
  - "+ Add Reminder" primary action.
- **Add / Edit Reminder Screen**:
  - Title (e.g. "HDFC Home Loan EMI", "Electricity Bill", "Credit Card Due").
  - Amount and Type: `LOAN_EMI`, `CREDIT_CARD`, `BILL`, `INSURANCE`, `RENT`, `SUBSCRIPTION`, `CUSTOM`.
  - Next Due Date (DatePicker).
  - Recurrence: `ONE_TIME`, `DAILY`, `WEEKLY`, `MONTHLY`, `YEARLY`.
  - Advance Offsets: Predefined options ("On due date", "1 day before", "2 days before", "3 days before", "5 days before", "7 days before", "Custom").
  - Notification Time: Hour and minute (default 09:00 AM).
- **Mark Paid Workflow**:
  - Tapping "Mark Paid" presents options:
    - Mark Paid only.
    - Mark Paid & Record Transaction in Ledger (prompts for Cash vs Account payment method).
  - Automatically advances recurrence to the next due cycle while keeping track of `lastPaidDate`.
- **In-Notification Actions**:
  - Direct Action: "Mark Paid" (updates reminder and clears notification).
  - Direct Action: "Snooze" (re-alerts in 3 hours).
- **Smart Evening Reminder (9:00 PM)**:
  - Daily reminder to log expenses.
  - **Smart Suppression Engine**: Automatically inspects local database; if user already recorded any transaction today, the 9 PM reminder is quietly suppressed.

## 6. Entry Points
- Navigation menu -> "Reminders" (`Screen.Reminders`).
- Dashboard banner "Upcoming Bills".
- Notification tray tap.

## 7. Screen Structure
```text
RemindersScreen
├── TopBar (Back Button, Title "Reminders", "+ Add" Action)
├── FilterTabs (Upcoming, Paid, All)
└── LazyColumn
    └── ReminderCard
        ├── Type Icon Squircle, Title, Amount
        ├── Due Date Pill ("Due tomorrow" / "Due in 3 days" / "Overdue by 2 days")
        ├── "Mark as Paid" Action Button
        └── Switch Toggle (Enable / Disable)
```

## 8. UI Components
- `ReminderCard`: Elevated card with visual status indicators.
- `ReminderOffsetPicker`: Multi-select chip group for advance notification alerts.
- `MarkPaidDialog`: Confirmation dialog with "Record Transaction in Ledger" checkbox.
- `NotificationHelper`: System notification builder with custom Leaf sound chime.

## 9. User Interactions
- Tap "Mark Paid": Opens confirmation modal; advances due date.
- Tap toggle: Enables/disables notifications and schedules.
- Tap reminder row: Opens edit dialog.
- Swipe or delete: Removes reminder and cancels scheduled alarms.

## 10. Input Fields
| Field Name | Type | Validation / Constraints | Mandatory |
| :--- | :--- | :--- | :--- |
| **Title** | String | Non-blank, max 60 chars | Yes |
| **Amount** | Subunits | $> 0$, integer subunits $\le 10^{14}$ | Yes |
| **Type** | Enum (`ReminderType`) | `LOAN_EMI`, `CREDIT_CARD`, `BILL`, etc. | Yes |
| **Due Date** | Long (Epoch) | Valid date | Yes |
| **Recurrence** | Enum (`ReminderRecurrence`)| `ONE_TIME`, `DAILY`, `WEEKLY`, `MONTHLY`, `YEARLY`| Yes |
| **Offset Days** | Integer / String | Primary offset + comma-separated secondary offsets | Yes |
| **Notification Time**| Hour & Minute | 0..23, 0..59 (Default 9:00 AM) | Yes |

## 11. Validation Rules
- Due date cannot be in the past when creating a new active reminder.
- Notification hour (0..23) and minute (0..59) must be within standard clock bounds.

## 12. Business Rules
- **Mark Paid & Ledger Logging:**
  When a reminder is marked as paid with `recordTransaction = true`, it maps the obligation type to an existing standard category:
  - `LOAN_EMI` $\to$ `"EMI & Loans"`
  - `CREDIT_CARD`, `BILL`, `INSURANCE` $\to$ `"Bills & Utilities"`
  - `RENT` $\to$ `"Housing & Rent"`
  - `SUBSCRIPTION` $\to$ `"Subscriptions"`
  - `CUSTOM` $\to$ `"Other Expense"`
  and creates an Expense transaction with note `"Payment: [Title]"`.
- **Recurrence Cycle Advance (`calculateNextDueDate`):**
  - If `ONE_TIME`: Sets `isPaid = true`, records `lastPaidDate = now`, keeps due date.
  - If recurring: Computes next due date (clamping day of month to 28/29/30/31), sets `isPaid = false` (ready for next cycle) and `lastPaidDate = now`.
- **Smart Evening Reminder Suppression:**
  Evaluated at scheduled evening hour (default 9:00 PM). If `transactionsBetween(startOfDay, endOfDay)` is non-empty, the notification is quietly cancelled without disturbing the user.

## 13. Calculation Logic
- Days until due:
  $$\text{daysUntil} = \text{ChronoUnit.DAYS.between}(\text{today}, \text{dueDate})$$
  - $\text{daysUntil} < 0 \implies \text{Overdue}$ (Rose red badge).
  - $\text{daysUntil} == 0 \implies \text{Due today}$ (Amber badge).
  - $\text{daysUntil} == 1 \implies \text{Due tomorrow}$ (Amber badge).
  - $\text{daysUntil} > 1 \implies \text{"Due in } X \text{ days"}$ (Neutral badge).

## 14. Database Interactions
- Table: `reminders`.
- `ReminderDao.getAllReminders()`, `ReminderDao.getActiveReminders()`.
- `ReminderDao.markReminderPaid(id, isPaid, lastPaidDate, nextDueDate, updatedAt)`.

## 15. State Management
- `RemindersViewModel`: Exposes `RemindersUiState(upcoming, paid, all, selectedTab)`.
- `AlarmReminderScheduler`: Schedules alarm intents via Android `AlarmManager.setAndAllowWhileIdle()`.

## 16. Navigation
- Pushed from navigation menu or dashboard banner.

## 17. Error Handling
- Alarms and notifications survive device reboots via `BootReceiver`.

## 18. Empty States
- When no reminders exist: "No upcoming reminders. Set reminders for your rent, loan EMIs, and bills to avoid late fees."

## 19. Loading States
- Renders placeholder rows during initial load.

## 20. Edge Cases
- Obligation due on 31st marked paid in January: Next due date advances to February 28th (or 29th). In March, it automatically targets March 31st.
- Multiple advance offsets (e.g. 7 days before AND 1 day before AND on due date): Handled without duplicate alarms.

## 21. Dependencies
- `ReminderRepository`
- `TransactionRepository`
- `CategoryRepository`
- `ReminderScheduler`
- `NotificationHelper`

## 22. Relevant Android Source Files
- `app/src/main/java/com/vinaynalavade/expensetracker/domain/model/Reminder.kt`
- `app/src/main/java/com/vinaynalavade/expensetracker/data/repository/ReminderRepositoryImpl.kt`
- `app/src/main/java/com/vinaynalavade/expensetracker/core/notification/AlarmReminderScheduler.kt`
- `app/src/main/java/com/vinaynalavade/expensetracker/core/receiver/ReminderReceiver.kt`
- `app/src/main/java/com/vinaynalavade/expensetracker/presentation/reminders/RemindersScreen.kt`

## 23. Relevant Tests
- `app/src/test/java/com/vinaynalavade/expensetracker/ReminderRepositoryTest.kt`
- `app/src/test/java/com/vinaynalavade/expensetracker/DailyReminderSchedulerTest.kt`
- `app/src/test/java/com/vinaynalavade/expensetracker/FinancialNotificationsTest.kt`

## 24. iOS Implementation Expectations
- Implement as `RemindersListView.swift`.
- Notifications managed via `UserNotifications` framework (`UNUserNotificationCenter`):
  - Request authorization (`.alert, .sound, .badge`).
  - Schedule local notification triggers via `UNCalendarNotificationTrigger`.
  - Notification actions ("Mark Paid", "Snooze") registered via `UNNotificationCategory` and handled in `UNUserNotificationCenterDelegate`.
  - Notification custom sound via `UNNotificationSound(named: "leaf_chime.caf")`.

## 25. Acceptance Criteria
1. Marking a recurring reminder as paid advances the due date to the next cycle and keeps it active.
2. Checking "Record in Ledger" creates an Expense transaction in the correct category.
3. If an expense is logged on a given day, the 9 PM evening reminder does not alert.
4. Notifications trigger at the configured hour and advance offsets.

