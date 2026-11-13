# FEATURE SPECIFICATION: FEAT-03 — SPLIT & COLLECT (SPLIT 2.0)

## 1. Feature ID
`FEAT-03`

## 2. Feature Name
Split & Collect: Group Expenses, Itemized Bill Splitting, Net Balance Engine & WhatsApp Settlement

## 3. Purpose
Comprehensive group expense sharing and settlement management system. Allows users to split shared bills equally, item-by-item, or via custom direct shares; compute directional net debts; display UPI QR codes for instant payments; generate dynamic, personalized WhatsApp reminder messages; and integrate shared expenses into the main financial ledger.

## 4. Current Implementation Status
**VERIFIED (IMPLEMENTED)** — Complete with multi-step creation wizard, pure mathematical calculation engine, directional graph net balance engine, QR storage, and dedicated unit test suites.

## 5. User-Facing Functionality
- **Split Landing Screen (`SplitLandingScreen`)**:
  - Net Balance Summary Banner: Displays "Owed to you" (Green), "You owe" (Rose), and total group spend.
  - Directional Debt Cards: Displays pairwise settlement cards ("Rahul owes you ₹350.00", "You owe Priya ₹120.00").
  - Group Management: Create new groups, view groups, filter expenses by group.
  - Expense List: History of all split expenses with settlement status badges (`PENDING`, `PARTIALLY_SETTLED`, `SETTLED`).
- **Create Split Wizard (`CreateSplitScreen`)**:
  - **Step 1: Bill Basics**: Title, Total Amount, Date, Category, Group assignment, Payment Source (Cash/Account), "Add to Transactions" toggle.
  - **Step 2: Participants**: Add participants by name or from Android/iOS Contacts picker. Mark who paid ("Me" or another participant).
  - **Step 3: Split Method & Allocation**:
    - *Equal Split*: Automatically calculates equal shares with deterministic paisa reconciliation.
    - *Itemized Custom Split (Split 2.0)*: Add individual item lines (e.g., Pizza ₹600, Coke ₹150), assign consumers to each item, and designate who shares the remaining unallocated balance.
    - *Direct Custom Split*: Manually enter exact amounts per person with real-time overallocated/underallocated feedback.
  - **Step 4: UPI QR Code & Summary**: Attach an image of a UPI payment QR code (saved to app-private storage); view final review.
- **Split Detail Screen (`SplitDetailScreen`)**:
  - Full breakdown of each participant's share, items consumed, paid amount, and settlement status.
  - "Mark as Settled" toggle per participant with payment source selection.
  - WhatsApp Direct Reminder: Generates a tailored message and launches WhatsApp chat targeting the participant's phone number.
  - Consolidated WhatsApp Share: Shares summary to group chat.
  - View full-screen UPI QR code for scanning.

## 6. Entry Points
- Bottom navigation tab "Split" (`Screen.Split`).
- Dashboard Quick Action "Split Bill".
- From within a specific Split Group card.

## 7. Screen Structure
```text
SplitLandingScreen
├── TopBar (Title "Split & Collect", Group filter dropdown, "+ New Group" action)
├── NetBalanceSummaryBanner (Owed to you vs You owe summary)
├── Directional Debt Cards Horizontal/Vertical List
├── Group Filter Chips Row ("All", "Trip", "Roommates", "+ Add Group")
└── Split Expenses LazyColumn
    └── SplitExpenseCard (Title, Date, Total Amount, My Share, Settlement Badge)
```

## 8. UI Components
- `NetBalanceSummaryBanner`: Elevated card summarizing directional debts.
- `SplitExpenseCard`: Summary card showing participant count, your share, and status.
- `ItemizedItemRow`: Item name, amount, consumer avatars, and custom allocation controls.
- `ParticipantSettlementRow`: Name, phone indicator, share amount, status badge, "Mark Paid" button, WhatsApp share button.
- `QrCodePreviewDialog`: Dialog displaying high-resolution saved UPI QR code.

## 9. User Interactions
- Tap "+ New Split": Opens Create Split flow.
- Add Participant: Type name or pick from Contacts.
- Switch Split Method: Toggles between Equal, Itemized, and Direct custom modes.
- Tap WhatsApp button next to participant: Generates personalized text and launches WhatsApp.
- Tap "Mark Settled": Updates participant status to `SETTLED`; prompts for payment source (Cash/Account); logs ledger transaction if enabled.

## 10. Input Fields
| Field Name | Type | Validation / Constraints | Mandatory |
| :--- | :--- | :--- | :--- |
| **Title** | String | Non-blank, max 100 chars | Yes |
| **Total Amount** | Decimal / Subunits | $> 0$, integer subunits | Yes |
| **Date** | Long (Epoch) | Valid date | Yes |
| **Category** | Long (`categoryId`) | Valid category ID | Yes |
| **Paid By** | String | Name of participant who paid the bill | Yes |
| **Split Method** | Enum (`SplitMethod`) | `EQUAL`, `CUSTOM` | Yes |
| **Participants** | List<SplitParticipant> | $\ge 2$ participants (including "Me") | Yes |
| **Items (Itemized)**| List<SplitItem> | Sum of items $\le$ total bill | No |
| **UPI QR Image** | Uri / File path | Valid image file | No |
| **Add to Transactions** | Boolean | Default: false | Yes |

## 11. Validation Rules
- `validateCustomSplit`: Allocated sum must exactly equal total bill amount.
  - If sum < total: Displays "Remaining: ₹X.XX" (Save disabled).
  - If sum > total: Displays "Overallocated: ₹X.XX" (Save disabled).
- Equal split remainder: Must never discard or lose remaining paise/cents.

## 12. Business Rules
- **Payer Identification:** Participant with `isCurrentUser == true` represents the device owner ("Me").
- **Directional Debt Resolution (`NetBalanceEngine`):**
  - If Participant A owes Payer B ₹500, and in another expense B owes A ₹200, net balance collapses to A owes B ₹300.
  - Debts are grouped and sorted by descending net amount.
- **Ledger Integration (`addToTransactions == true`):**
  - Upon creation: Inserts Expense transaction in main ledger for `totalAmount` with note `"Split – [Title]"`.
  - Upon external participant settlement: Inserts Income transaction for their share with note `"[Participant] — [Title] settlement"`.
  - Current user ("Me") never generates an income settlement transaction.
  - Deleting split expense or reverting settlement status to `PENDING` preserves existing ledger transactions as immutable financial history.

## 13. Calculation Logic
### Equal Split Formula:
$$B = \lfloor \text{Total Subunits} / N \rfloor, \quad R = \text{Total Subunits} \pmod N$$
Participant $i$ receives:
$$\text{Share}_i = \begin{cases} B + 1 & \text{if } i < R \\ B & \text{if } i \ge R \end{cases}$$
Sum of all shares $\equiv \text{Total Subunits}$ exactly.

### Itemized Split Formula:
For item $k$ with amount $A_k$ shared among $C_k$ consumers:
$$\text{ItemShare}_{i, k} = \lfloor A_k / C_k \rfloor + (1 \text{ if } \text{index}(i) < A_k \pmod{C_k} \text{ else } 0)$$
Remaining bill amount:
$$\Delta = \text{Total Bill} - \sum A_k$$
If $\Delta > 0$, it is split equally among designated shared participants with remainder reconciliation.

## 14. Database Interactions
- Tables: `split_expenses`, `split_participants`, `split_groups`.
- `SplitDao.insertSplitExpenseWithParticipants(expense, participants)`: Atomic Room transaction.
- `SplitDao.updateParticipantSettlementWithTransaction(...)`.
- Foreign key cascading: Deleting a split expense cascades deletion to its participants, while setting `group_id` to null on expenses if a group is deleted.

## 15. State Management
- `CreateSplitViewModel`: Manages step progression, active items list, participant phone numbers, live validation, and QR saving.
- `SplitLandingViewModel`: Combines split expenses flow with `NetBalanceEngine` calculations.

## 16. Navigation
- `Screen.Split` $\to$ `Screen.CreateSplit` $\to$ `Screen.SplitDetail/{id}` $\to$ `Screen.EditSplit/{id}`.

## 17. Error Handling
- Invalid allocations prevent advancing to review/save.
- Missing camera/storage permissions for QR are handled with graceful inline notices.

## 18. Empty States
- When no splits exist: Displays "No split expenses yet. Tap + to split a dinner, trip, or group bill."
- When all debts are settled: Banner displays "All settled up! Zero outstanding balance."

## 19. Loading States
- QR image loading runs asynchronously via background I/O dispatcher.

## 20. Edge Cases
- Odd paise splits (e.g. ₹100 among 3 people): Yields ₹34, ₹33, ₹33. Total = ₹100.00.
- Single participant split: Prevented by validation ($\ge 2$ required).
- Non-Indian phone numbers for WhatsApp: Handled gracefully by preserving full `+` international format.

## 21. Dependencies
- `SplitRepository`
- `SplitCalculationEngine`
- `NetBalanceEngine`
- `SplitQrStorageManager`
- `WhatsAppShareHelper`

## 22. Relevant Android Source Files
- `app/src/main/java/com/vinaynalavade/expensetracker/domain/split/SplitCalculationEngine.kt`
- `app/src/main/java/com/vinaynalavade/expensetracker/core/split/NetBalanceEngine.kt`
- `app/src/main/java/com/vinaynalavade/expensetracker/core/share/WhatsAppShareHelper.kt`
- `app/src/main/java/com/vinaynalavade/expensetracker/presentation/split/create/CreateSplitViewModel.kt`
- `app/src/main/java/com/vinaynalavade/expensetracker/data/repository/SplitRepositoryImpl.kt`

## 23. Relevant Tests
- `app/src/test/java/com/vinaynalavade/expensetracker/SplitCalculationEngineTest.kt`
- `app/src/test/java/com/vinaynalavade/expensetracker/SplitDomainTest.kt`
- `app/src/test/java/com/vinaynalavade/expensetracker/SharedFinanceNetBalanceTest.kt`
- `app/src/test/java/com/vinaynalavade/expensetracker/SplitTransactionIntegrationTest.kt`
- `app/src/test/java/com/vinaynalavade/expensetracker/WhatsAppShareHelperTest.kt`

## 24. iOS Implementation Expectations
- Implement as native SwiftUI `SplitLandingView.swift` and multi-step `CreateSplitView.swift`.
- Use Contacts framework (`CNContactPickerViewController`) for native iOS contact selection.
- WhatsApp deep-linking via `URL(string: "https://api.whatsapp.com/send?phone=...&text=...")` with `UIApplication.shared.open()`.
- PhotosPicker (`PhotosUI`) for QR code image selection, stored in app's `Application Support` directory.

## 25. Acceptance Criteria
1. Mathematical reconciliation: The sum of calculated participant shares strictly equals the total expense in all cases.
2. Net balance engine accurately computes pairwise debt cancellations across multiple expenses.
3. WhatsApp sharing formats the message with recipient name, bill title, total bill, and share amount.
4. Enabling "Add to Transactions" creates an expense transaction in the primary ledger and income transactions on settlement.

