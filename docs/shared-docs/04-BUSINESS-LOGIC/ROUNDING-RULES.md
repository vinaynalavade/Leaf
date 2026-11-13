# Leaf Business Logic: Rounding Rules & Precision Specifications

## 1. The Cardinal Rule: Subunits Only
In Leaf, floating-point numbers (`Float`, `Double`) are strictly prohibited for:
- Database column storage.
- Repository return models representing money.
- Transaction amounts, balances, totals, debts, budgets, and savings goals.
- Ledger aggregation and summation.

Floating-point representations in IEEE 754 format introduce well-known binary representation errors (e.g. `0.1 + 0.2 = 0.30000000000000004`). In financial software, such errors compound across transactions and cause balance drift.

Every monetary value is modeled as an instance of the value class `Amount(val subunits: Long)`:
```kotlin
@JvmInline
value class Amount(val subunits: Long)
```

On iOS, this must be implemented as:
```swift
struct Amount: RawRepresentable, Equatable, Comparable, Hashable, Codable {
    let rawValue: Int64
    init(rawValue: Int64) { self.rawValue = rawValue }
    init(_ subunits: Int64) { self.rawValue = subunits }
}
```

---

## 2. Currency Subunit Scale Factors
Leaf supports 9 global currencies. The subunit factor determines how many subunits constitute 1 primary currency unit:

| Currency | Code | Symbol | Decimal Digits | Subunit Factor | Smallest Unit Name | Example Display (12550 Subunits) |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| Indian Rupee | `INR` | ₹ | 2 | 100 | Paisa | ₹125.50 |
| US Dollar | `USD` | $ | 2 | 100 | Cent | $125.50 |
| Euro | `EUR` | € | 2 | 100 | Cent | €125.50 |
| British Pound | `GBP` | £ | 2 | 100 | Penny | £125.50 |
| UAE Dirham | `AED` | د.إ | 2 | 100 | Fils | د.إ125.50 |
| Singapore Dollar | `SGD` | S$ | 2 | 100 | Cent | S$125.50 |
| Canadian Dollar | `CAD` | C$ | 2 | 100 | Cent | C$125.50 |
| Australian Dollar| `AUD` | A$ | 2 | 100 | Cent | A$125.50 |
| Japanese Yen | `JPY` | ¥ | 0 | 1 | Yen (Whole) | ¥12,550 |

---

## 3. String Input Parsing without Floating-Point Conversions
When a user inputs a monetary value via keyboard or clipboard (e.g. `"125.50"`), it must be parsed directly into subunits using string splitting and integer arithmetic, **never** via `Double.parseDouble()`.

### Parsing Algorithm (`Amount.fromStringOrNull`)
1. Remove all grouping commas: `clean = input.replace(",", "").trim()`.
2. Check for negative prefix `"-"`.
3. Split string by decimal point `"."`.
4. If more than 1 decimal point exists, reject as invalid (`null`).
5. Extract integer `mainPart` before decimal point. Convert via `toLongOrNull()`.
6. Extract `fractionPart` after decimal point:
   - If length exceeds `currency.decimalDigits`, truncate to `currency.decimalDigits`.
   - If length is less than `currency.decimalDigits`, pad with trailing zeros (e.g., `"5"` becomes `"50"` for 2 decimals).
   - Convert fraction via `toLongOrNull()`.
7. Compute total:
   $$\text{totalSubunits} = (\text{mainVal} \times \text{currency.subunitFactor}) + \text{fractionVal}$$
8. Apply negative sign if original string was prefixed with `"-"`.

This ensures strings like `"0.07"` parse exactly to `7L` subunits, avoiding the `0.069999999` IEEE 754 trap.

---

## 4. Zero-Sum Penny Reconciliation in Bill Splitting
When an amount cannot be evenly divided by the number of participants, rounding individual shares using standard half-up rounding creates a "leaked penny" or "ghost penny" error.

**Bad Approach (Rounding each share independently)**:
- Total: ₹100.00 (10,000 paise). Participants: 3.
- $10,000 / 3 = 3333.3333$ paise.
- Rounded to nearest paisa: ₹33.33 each.
- Sum: $33.33 \times 3 = ₹99.99$. Result: ₹0.01 lost into the void.

**Leaf Approach (Deterministic Integer Partitioning)**:
1. Compute integer base quotient:
   $$\text{baseSubunits} = \lfloor \text{totalSubunits} / N \rfloor$$
2. Compute integer remainder:
   $$\text{remainder} = \text{totalSubunits} \pmod N$$
3. Distribute $+1$ subunit to each of the first $\text{remainder}$ participants in the list:
   - Participant 0: $\text{baseSubunits} + 1$
   - Participant 1: $\text{baseSubunits} + 1$ (if $1 < \text{remainder}$)
   - Participant $k$: $\text{baseSubunits}$ (for $k \ge \text{remainder}$)
4. **Invariant**:
   $$\sum_{i=0}^{N-1} \text{share}_i \equiv \text{totalSubunits}$$

### Concrete Test Vectors
| Total Bill | Participants | Base Share | Remainder | Allocated Shares | Sum Check |
| :--- | :--- | :--- | :--- | :--- | :--- |
| ₹100.00 (10,000) | 3 | 3333 paise | 1 paisa | ₹33.34, ₹33.33, ₹33.33 | 10,000 (₹100.00) ✓ |
| ₹50.00 (5,000) | 3 | 1666 paise | 2 paise | ₹16.67, ₹16.67, ₹16.66 | 5,000 (₹50.00) ✓ |
| ₹10.00 (1,000) | 6 | 166 paise | 4 paise | ₹1.67 (×4), ₹1.66 (×2) | 1,000 (₹10.00) ✓ |
| ¥1,000 (1,000) | 3 | ¥333 | 1 yen | ¥334, ¥333, ¥333 | 1,000 (¥1,000) ✓ |

---

## 5. Half-Up Rounding for Percentage & Financial Tool Displays
While underlying records are stored as integer subunits, display percentages and financial calculator outputs (EMI, SIP, FD) employ **Half-Up Rounding** (`RoundingMode.HALF_UP`).

### Rules
1. **Percentages**:
   - Formatted to 1 decimal place: `##0.0%`.
   - $0.05\%$ rounds up to $0.1\%$.
2. **Financial Calculators (EMI / SIP / Compound Interest)**:
   - Intermediate formulas calculate in high-precision `Double`.
   - Final outputs (monthly installment, total interest, maturity amount) are rounded to 2 decimal places using Half-Up before presentation to the user:
     $$\text{Display} = \frac{\lfloor (\text{value} \times 100) + 0.5 \rfloor}{100.0}$$
3. **Paisa-Level Ceilings in Goal Deficits**:
   - When determining required monthly savings for a savings goal, integer division uses **ceiling** division so the user never falls short of the target:
     $$\text{RequiredMonthly} = \lceil \text{Deficit} / \text{MonthsRemaining} \rceil = \lfloor (\text{Deficit} + \text{MonthsRemaining} - 1) / \text{MonthsRemaining} \rfloor$$

---

## 6. Overflow Prevention & Numerical Boundaries
To prevent 64-bit integer overflows when computing large sums across years of historical transactions:
- **Maximum Individual Transaction**: $10^{14}$ subunits (₹1,00,00,00,000 / ₹1,000 Crore).
- **Maximum Accumulated Balance**: $10^{15}$ subunits.
- Since signed 64-bit integers support up to $9.22 \times 10^{18}$ (`Long.MAX_VALUE`), a ceiling of $10^{14}$ guarantees that several million transactions can be summed without approaching the 64-bit boundary.

