# FEATURE SPECIFICATION: FEAT-05 — SAVINGS GOALS & CONTRIBUTIONS

## 1. Feature ID
`FEAT-05`

## 2. Feature Name
Target-Driven Savings Goals, Contributions & Ledger Deductions

## 3. Purpose
Empowers users to define, track, and achieve specific financial targets (e.g., Vacation, Emergency Fund, Tech Upgrade) with progress percentage tracking, contribution logs, optional automated ledger account deductions, and goal archiving.

## 4. Current Implementation Status
**VERIFIED (IMPLEMENTED)** — Complete with separate contribution table, ledger transaction linkage, archiving, and automated tests.

## 5. User-Facing Functionality
- **Savings Goals Tab (`PlanningScreen`)**:
  - List of active savings goals with target amount, current amount saved, and progress percentage.
  - Progress bar and completion checkmark badge when $\ge 100\%$.
  - "+ Add Goal" action.
  - "Archived Goals" section for historical completed/retired targets.
- **Goal Detail Screen (`GoalDetailScreen`)**:
  - Hero header with custom icon, color, goal title, target amount, current saved amount, and target completion date.
  - Quick action "+ Add Contribution".
  - Chronological history of all contributions with date, note, and amount.
  - Option to delete individual contributions.
  - Goal settings menu: Edit Goal, Archive/Unarchive Goal, Delete Goal (with optional deletion of linked transactions).
- **Add Contribution Dialog**:
  - Enter contribution amount.
  - Optional note (e.g. "Monthly savings", "Bonus deposit").
  - "Deduct from Account" toggle: When checked, automatically logs a corresponding Expense transaction under category "Savings & Goals" in the main ledger.

## 6. Entry Points
- Bottom navigation tab "Planning" (`Screen.Planning`), "Savings" tab.
- Dashboard savings goals glance widget.
- Navigation from Goal Card to `Screen.GoalDetail/{goalId}`.

## 7. Screen Structure
```text
GoalDetailScreen
├── TopBar (Back Button, Title, Goal Edit/Archive/Delete Menu)
├── GoalHeroCard (Color Accent Background)
│   ├── Icon in Squircle, Goal Name, Target Date
│   ├── Saved Amount vs Target Amount Display
│   └── Large Circular or Linear Progress Bar (0% to 100%)
├── ContributionsSectionHeader ("Contribution History", "+ Add" Action)
└── ContributionsLazyColumn
    └── ContributionRowItem (Date, Note, Amount, Delete Icon)
```

## 8. UI Components
- `SavingsGoalCard`: Grid or list card displaying target, current saved, and progress bar.
- `GoalDetailScreen`: Main detail container.
- `AddEditGoalDialog`: Modal for creating/updating name, target, date, icon, and color.
- `AddContributionDialog`: Modal for adding funds with account deduction switch.
- `ConfirmDeleteGoalDialog`: Confirmation dialog with checkbox "Also delete linked transactions from ledger".

## 9. User Interactions
- Tap "+ Add Goal": Opens goal creation dialog.
- Tap Goal Card: Navigates to `Screen.GoalDetail`.
- Tap "+ Add Contribution": Opens contribution dialog; toggling "Deduct from Account" creates a linked transaction.
- Tap Archive: Moves goal to archived state (hidden from active view, contributions locked).
- Tap Delete: Deletes goal and contributions; prompts whether to delete linked ledger transactions.

## 10. Input Fields
### Goal Creation
| Field Name | Type | Validation / Constraints | Mandatory |
| :--- | :--- | :--- | :--- |
| **Name** | String | Non-blank, max 60 chars | Yes |
| **Target Amount**| Subunits | $> 0$, integer subunits $\le 10^{14}$ | Yes |
| **Target Date** | Long? (Epoch) | Future date recommended | No |
| **Icon Name** | String | Predefined icon catalog (default "savings") | Yes |
| **Color Hex** | String | Valid hex color (default "#10B981") | Yes |
| **Note** | String | Optional description | No |

### Contribution
| Field Name | Type | Validation / Constraints | Mandatory |
| :--- | :--- | :--- | :--- |
| **Amount** | Subunits | $> 0$, integer subunits $\le 10^{14}$ | Yes |
| **Note** | String | Optional note snippet | No |
| **Deduct Account**| Boolean | Creates linked expense transaction if true | Yes |

## 11. Validation Rules
- `targetAmount` must be strictly positive.
- Cannot add or modify contributions for an archived savings goal.
- Contribution timestamp cannot be in the future.
- Contribution amount cannot exceed $10^{14}$ subunits.

## 12. Business Rules
- **Progress Calculation:**
  $$\text{Current Saved} = \sum_{\text{c} \in \text{Contributions}} \text{c.amount.subunits}$$
  $$\text{Progress Percentage} = \min\left(100.0, \frac{\text{Current Saved}}{\text{Target Amount}} \times 100.0\right)$$
  $$\text{isCompleted} \iff \text{Current Saved} \ge \text{Target Amount}$$
- **Ledger Integration (`deductFromAccount == true`):**
  - Finds or automatically creates the system internal category `"Savings & Goals"` (`TransactionType.EXPENSE`, color `#10B981`, icon `savings`).
  - Creates an Expense transaction with `paymentMethod = PaymentMethod.ACCOUNT`, note `"Contribution: [Goal Name]"`.
  - Links the generated `transactionId` in `savings_goal_contributions`.
- **Deletion Safety:** Deleting a contribution or goal can optionally delete the linked ledger transaction if the user confirms, preventing orphaned ledger expenses.

## 13. Calculation Logic
- Subunits: 64-bit integer addition of all contribution subunits.
- Remaining amount: $\max(0L, \text{Target Subunits} - \text{Current Saved Subunits})$.

## 14. Database Interactions
- Tables: `savings_goals`, `savings_goal_contributions`.
- Foreign key: `savings_goal_contributions.goal_id` references `savings_goals.id` with `ON DELETE CASCADE`.
- Foreign key: `savings_goal_contributions.transaction_id` references `transactions.id` with `ON DELETE SET NULL`.
- Relation query: `SavingsGoalWithContributions` fetches goal and contributions reactively.

## 15. State Management
- `PlanningViewModel` & `GoalDetailViewModel`: Expose reactive StateFlows combining goal details and contributions.

## 16. Navigation
- `Screen.Planning` $\to$ `Screen.GoalDetail/{goalId}`.

## 17. Error Handling
- Attempting to contribute to an archived goal returns `AppResult.Error(ValidationError)`.
- Input validation displays inline red messages.

## 18. Empty States
- When no goals exist: Displays "No savings goals set. Create a goal to start building your dreams."
- When goal has no contributions: Displays "No contributions yet. Tap + to add your first deposit."

## 19. Loading States
- Asynchronous database operations display circular spinner on button.

## 20. Edge Cases
- Current saved exceeds target (e.g. Saved ₹12,000 of ₹10,000 target): Progress is clamped at 100.0% for graphical bars; exact figure displays ₹12,000 / ₹10,000 (120%).
- Linked transaction deleted directly in Transactions screen: Foreign key `ON DELETE SET NULL` automatically nulls `transaction_id` without deleting the contribution record.

## 21. Dependencies
- `SavingsGoalRepository`
- `TransactionRepository`
- `CategoryRepository`
- `SaveSavingsGoalContributionUseCase`

## 22. Relevant Android Source Files
- `app/src/main/java/com/vinaynalavade/expensetracker/domain/model/SavingsGoal.kt`
- `app/src/main/java/com/vinaynalavade/expensetracker/domain/usecase/SaveSavingsGoalContributionUseCase.kt`
- `app/src/main/java/com/vinaynalavade/expensetracker/presentation/planning/GoalDetailScreen.kt`
- `app/src/main/java/com/vinaynalavade/expensetracker/presentation/planning/GoalDetailViewModel.kt`

## 23. Relevant Tests
- `app/src/test/java/com/vinaynalavade/expensetracker/SavingsGoalProgressTest.kt`

## 24. iOS Implementation Expectations
- Implement as `SavingsGoalCardView.swift` and `GoalDetailView.swift`.
- Use SwiftUI `Gauge` or custom circular progress view for completion visualization.
- Context menu (`.contextMenu`) on goal cards for Quick Add Contribution, Archive, and Delete.

## 25. Acceptance Criteria
1. Adding contributions updates the saved total and progress percentage in real time.
2. Toggling "Deduct from Account" creates a valid Expense transaction under "Savings & Goals".
3. Archiving a goal hides it from active goals and disables further contributions.
4. When saved amount equals or exceeds target, goal is flagged as completed.

