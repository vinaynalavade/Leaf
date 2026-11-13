# Leaf Quality Assurance: Comprehensive Test Strategy & Parity Framework

## 1. Executive Summary
The primary mandate of the Leaf iOS quality assurance strategy is **100% financial calculation accuracy and behavioral parity with Android**. Because users entrust Leaf with their daily financial records, bugs in ledger sums, rounding reconciliations, or database integrity are classified as critical severity blockers.

---

## 2. Testing Pyramid & Coverage Thresholds

```
            / \
           /   \        10% UI & End-to-End Tests
          /     \       (XCUITest, User Journeys)
         /───────\
        /         \     30% Integration Tests
       /           \    (GRDB SQLite, DAOs, UseCase-Repository)
      /─────────────\
     /               \  60% Pure Unit & Engine Tests
    /                 \ (Financial Engines, Amount, Split, NetBalance)
   ─────────────────────
```

| Layer | Target Coverage | Scope & Focus | Tools / Frameworks |
| :--- | :--- | :--- | :--- |
| **Financial Engines & Math** | **100%** | `Amount`, `SplitCalculationEngine`, `FinancialCalculatorEngine`, `NetBalanceEngine`. | XCTest, Swift Testing |
| **Domain Use Cases** | **95%+** | Validation gates, duplicate detection, cascading deletion blocks. | XCTest with Mock Repositories |
| **Database & Persistence** | **90%+** | Schema v10 integrity, foreign key cascades, transaction atomicity. | In-memory GRDB SQLite pool |
| **UI & Flow Integration** | **80%+** | ViewModels, state flow transitions, form validations, sheet presentations. | XCUITest, SwiftUI ViewInspector |
| **Cross-Platform Parity** | **100%** | Exact parity against the 59 Android unit tests and Android test vectors. | Automated Test Matrix Runner |

---

## 3. Four-Tier Testing Methodology

### Tier 1: Pure Unit Testing (Engines & Value Objects)
- Test deterministic pure functions without mocking or platform abstractions.
- Validate `Amount` string parsing for every global currency, padding, and truncation.
- Verify zero-sum penny reconciliation across prime numbers of participants ($N \in \{3, 7, 11, 13, 17\}$).

### Tier 2: Repository & SQLite Integration Testing
- Use an in-memory SQLite database initialized with the exact Schema Version 10.
- Verify that foreign key `ON DELETE RESTRICT` actively blocks category deletion when linked transactions exist.
- Verify that `ON DELETE CASCADE` purges split participants when a split expense is removed.
- Verify that transactional inserts roll back cleanly if an error occurs mid-stream.

### Tier 3: ViewModel & State Machine Testing
- Test ViewModels under `@MainActor`.
- Verify that actions emit the expected `UiState` sequences.
- Verify that AppLock rate limits after 5 failed PIN attempts and locks for exactly 30 seconds.

### Tier 4: Cross-Platform Parity Testing
- Export a test dataset from the Android application (`leaf_parity_test_suite.json`).
- Import the dataset into the iOS application.
- Execute automated assertions comparing:
  - Total net balance.
  - Category donut slice percentages.
  - Monthly ledger opening and closing balances.
  - Split group debt simplifications.
  - Expected delta: **0.0000 subunits** (absolute zero deviation).

