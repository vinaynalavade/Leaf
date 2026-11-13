# Leaf Quality Assurance: Acceptance Criteria Specifications

## 1. Executive Summary
This document defines the formal acceptance criteria for Leaf in executable **Gherkin (Given-When-Then)** syntax. Every requirement must be satisfied for the native iOS application to be certified production-ready.

---

## 2. Core Feature Acceptance Criteria

### AC-01: Net Balance Accuracy & Calibration
```gherkin
Feature: Real-Time Net Balance Computation
  Scenario: Net balance reflects base opening balance and continuous transaction sums
    Given the user has calibrated an opening balance of ₹10,000.00 (1,000,000 subunits)
    And has recorded an Income transaction of ₹5,000.00 (500,000 subunits)
    And has recorded an Expense transaction of ₹2,500.00 (250,000 subunits)
    When the user views the Dashboard
    Then the Hero Balance Card must display "₹12,500.00"
    And the Income stat well must display "₹5,000.00"
    And the Expense stat well must display "₹2,500.00"
```

### AC-02: Rapid Transaction Logging
```gherkin
Feature: Fast Transaction Logging
  Scenario: Logging a valid expense within 3 seconds
    Given the user is on the Dashboard
    When the user taps the "+ Expense" quick action button
    And enters "180.00"
    And selects category "Food & Dining"
    And taps "Save"
    Then an EXPENSE record of 18000 subunits must be inserted into the database
    And the Dashboard net balance must decrement by ₹180.00
    And the transaction entry sheet must dismiss with tactile haptic feedback
```

### AC-03: Bill Split Zero-Sum Remainder Reconciliation
```gherkin
Feature: Equal Split Penny Reconciliation
  Scenario: Dividing an odd amount among participants leaves zero remainder
    Given a total bill of ₹100.00 (10,000 paise)
    And 3 participants: "Me", "Rahul", "Priya"
    When the user calculates an Equal Split
    Then Participant "Me" must be allocated 3334 paise (₹33.34)
    And Participant "Rahul" must be allocated 3333 paise (₹33.33)
    And Participant "Priya" must be allocated 3333 paise (₹33.33)
    And the sum of all shares must equal exactly 10,000 paise (₹100.00)
```

### AC-04: Split Settlement Ledger Integration
```gherkin
Feature: Automatic Settlement Income Transaction Generation
  Scenario: Marking an unsettled split participant as settled
    Given an unsettled split expense where "Rahul" owes "Me" ₹800.00
    When the user toggles "Mark as Settled" on Rahul's participant row
    Then Rahul's status must update to "SETTLED" with the current timestamp
    And an INCOME transaction titled "Settlement: Rahul ([BillTitle])" of ₹800.00 must be inserted into transactions
    And the user's liquid net balance must increase by ₹800.00
```

### AC-05: Monthly Budget Threshold Color Transitions
```gherkin
Feature: Budget Threshold Visualization
  Scenario Outline: Category progress bar dynamically colors according to consumption
    Given a monthly budget limit of ₹10,000.00 for category "Shopping"
    When total shopping expenses reach <SpendAmount>
    Then the progress percentage must be <Percentage>
    And the progress bar color must be <Color>

    Examples:
      | SpendAmount | Percentage | Color         |
      | ₹5,000.00   | 50.0%      | Emerald Green |
      | ₹8,000.00   | 80.0%      | Amber Gold    |
      | ₹10,000.00  | 100.0%     | Warning Amber |
      | ₹11,000.00  | 110.0%     | Crimson Red   |
```

### AC-06: Continuous Financial Continuity in Monthly Statements
```gherkin
Feature: Monthly Statement Continuity
  Scenario: Continuous opening balance equals previous month's closing balance
    Given the user has transactions in October and November
    When the user views the November Monthly Ledger
    Then the November Opening Balance must strictly equal the October Closing Balance
    And all transaction rows must align to monospaced tabular digits
```

### AC-07: Evening Reminder Smart Suppression
```gherkin
Feature: Contextual Reminder Suppression
  Scenario: 9:00 PM reminder is suppressed if transactions were logged today
    Given daily reminder is enabled for 21:00
    And the user has logged at least one transaction today at 14:00
    When the clock reaches 21:00
    Then no push notification must be displayed to the user
```

### AC-08: 5 Failed PIN Attempts Lockout
```gherkin
Feature: App Lock Vault Brute-Force Rate Limiting
  Scenario: 5 incorrect PIN attempts locks the application
    Given App Lock is enabled
    When an incorrect 4-digit PIN is entered 5 consecutive times
    Then the numeric keypad must become disabled
    And a 30-second countdown lockout banner must appear
    And restarting the app must NOT reset the remaining lockout cooldown
```

### AC-09: Category Deletion Integrity Protection
```gherkin
Feature: Category Deletion Safety
  Scenario: Attempting to delete a default or in-use category is blocked
    Given category "Food & Dining" is a system default
    When the user attempts to delete "Food & Dining"
    Then the deletion must be blocked with message "Default system categories cannot be deleted."
    
  Scenario: Custom category with active transactions cannot be deleted
    Given custom category "Books" has 3 logged transactions
    When the user attempts to delete "Books"
    Then the deletion must be blocked with message "Cannot delete category 'Books' because existing transactions depend on it."
```

### AC-10: Cross-Platform Backup JSON Roundtrip
```gherkin
Feature: Backup and Restore Integrity
  Scenario: Exporting and restoring a backup preserves exact financial figures
    Given a database with 100 transactions, 5 splits, and 2 budgets
    When the user exports a JSON v2 backup
    And clears the database
    And restores the JSON v2 backup
    Then all 100 transactions, 5 splits, and 2 budgets must be restored
    And the Net Balance must match the original value down to 0 subunits
```

