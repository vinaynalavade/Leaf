# FEATURE SPECIFICATION: FEAT-11 — FINANCIAL TOOLS & CALCULATORS

## 1. Feature ID
`FEAT-11`

## 2. Feature Name
Financial Calculators (EMI, SIP, FD, RD, GST, Discount) & In-Field Arithmetic Engine

## 3. Purpose
Provides a complete, offline financial calculation suite designed to help users plan investments, analyze borrowing costs, compute tax components, calculate sales discounts, and perform live mathematical calculations directly within transaction input fields.

## 4. Current Implementation Status
**VERIFIED (IMPLEMENTED)** — Complete with mathematical engine, unit tests, in-field expression evaluator, and individual tool screens.

## 5. User-Facing Functionality
- **Tools Landing Hub (`ToolsLandingScreen`)**:
  - Grid of available calculators with icons and descriptions:
    1. **Loan / EMI Calculator**: Monthly installment and interest cost.
    2. **SIP Investment Calculator**: Systematic investment plan returns.
    3. **Fixed Deposit (FD) Calculator**: Quarterly compounded fixed term deposit.
    4. **Recurring Deposit (RD) Calculator**: Monthly installments with compounding.
    5. **GST Tax Calculator**: Inclusive and exclusive Goods & Services Tax.
    6. **Discount Calculator**: Retail percentage discounts and final price.
- **Calculator Layout & Features**:
  - Shared template with TopBar, input controls, prominent result card, and detailed breakdown rows.
  - Live recalculation on every keystroke.
  - Preset quick chips for common rates (e.g. GST 5%, 12%, 18%, 28%).
- **In-Field Arithmetic Expression Evaluator**:
  - Evaluates expressions (e.g. `1200 + 450 * 2 - 100`) directly inside transaction amount fields.
  - Displays live evaluated preview before committing.

## 6. Entry Points
- Navigation menu -> "Financial Tools" (`Screen.Tools`).
- Dashboard quick tool links.
- Transaction amount field input (triggers live expression evaluator).

## 7. Screen Structure
```text
ToolsLandingScreen
├── TopBar (Back Button, Title "Financial Tools")
└── LazyVerticalGrid (2 columns)
    ├── ToolCard (EMI Calculator)
    ├── ToolCard (SIP Calculator)
    ├── ToolCard (FD Calculator)
    ├── ToolCard (RD Calculator)
    ├── ToolCard (GST Calculator)
    └── ToolCard (Discount Calculator)

IndividualCalculatorScreen (CalculatorLayout)
├── TopBar (Back Button, Title)
├── Scrollable Column
│   ├── InputsSection (OutlinedTextFields, Segmented Buttons, Preset Chips)
│   ├── PrimaryResultCard (Total Amount / Monthly Payment in Emerald/Brand styling)
│   └── BreakdownDetailsCard (Principal, Total Interest / Tax, Maturity / Gross Total)
```

## 8. UI Components
- `CalculatorLayout`: Reusable container with inputs and breakdown slots.
- `BreakdownRow`: Label, formatted currency amount, and optional color accent.
- `FinancialCalculatorEngine`: Pure Kotlin mathematical calculation engine.
- `EvaluateCalculatorExpressionUseCase`: Dijkstra Shunting-Yard arithmetic parser.

## 9. User Interactions
- Tap calculator card: Navigates to that calculator.
- Enter numbers: Real-time calculation on every character typed.
- Tap GST preset chip (5%, 12%, 18%, 28%): Updates selected tax rate immediately.
- Toggle GST Inclusive vs Exclusive: Recalculates net and tax components.

## 10. Input Fields & Validation Rules
| Calculator | Inputs | Range / Validation Constraints |
| :--- | :--- | :--- |
| **EMI** | Principal, Annual Rate %, Tenure (Months) | Principal $> 0$, Rate $\ge 0\%$, Tenure $\ge 1$ month |
| **SIP** | Monthly Investment, Annual Return %, Tenure (Years) | Monthly $> 0$, Return $[0\%, 50\%]$, Tenure $\ge 1$ year |
| **FD** | Principal, Annual Rate %, Tenure (Years) | Principal $> 0$, Rate $\ge 0\%$, Tenure $> 0$ years |
| **RD** | Monthly Deposit, Annual Rate %, Tenure (Months) | Monthly $> 0$, Rate $\ge 0\%$, Tenure $\ge 1$ month |
| **GST** | Amount, GST Rate %, Mode (Inclusive/Exclusive) | Amount $> 0$, GST Rate $\ge 0\%$ |
| **Discount** | Original Price, Discount % | Price $> 0$, Discount $[0\%, 100\%]$ |

## 11. Formulas & Business Logic

### 11.1 Equated Monthly Installment (EMI)
$$\text{monthlyRate } r = \frac{\text{annualRatePercent}}{12 \times 100}$$
$$\text{factor} = (1 + r)^n \quad (n = \text{tenureMonths})$$
$$\text{EMI} = P \times \frac{r \times \text{factor}}{\text{factor} - 1}$$
$$\text{Total Payment} = \text{EMI} \times n, \quad \text{Total Interest} = \max(0.0, \text{Total Payment} - P)$$
*Boundary:* If $r = 0$, $\text{EMI} = P / n$, $\text{Total Interest} = 0.0$.

### 11.2 Systematic Investment Plan (SIP)
Beginning-of-month annuity-due compounding:
$$\text{monthlyRate } i = \frac{\text{annualExpectedReturnPercent}}{12 \times 100}, \quad n = \text{tenureYears} \times 12$$
$$\text{Total Invested} = M \times n$$
$$\text{Maturity } A = M \times \left[\frac{(1 + i)^n - 1}{i}\right] \times (1 + i)$$
$$\text{Estimated Returns} = \max(0.0, A - \text{Total Invested})$$
*Boundary:* If $i = 0$, $A = \text{Total Invested}$, $\text{Returns} = 0.0$.

### 11.3 Fixed Deposit (FD)
Quarterly compounding:
$$\text{rate } r = \frac{\text{annualRatePercent}}{100}, \quad \text{quarters } q = 4 \times \text{tenureYears}$$
$$\text{Maturity } A = P \times \left(1 + \frac{r}{4}\right)^q$$
$$\text{Total Interest} = \max(0.0, A - P)$$

### 11.4 Recurring Deposit (RD)
Quarterly compounding on monthly tranches:
$$\text{rate } r = \frac{\text{annualRatePercent}}{100}, \quad n = \text{tenureMonths}$$
$$\text{Total Invested} = M \times n$$
$$\text{Maturity } A = \sum_{m=1}^{n} M \times \left(1 + \frac{r}{4}\right)^{\frac{4(n - m + 1)}{12}}$$
$$\text{Total Interest} = \max(0.0, A - \text{Total Invested})$$

### 11.5 GST Calculator
- **Exclusive (Net Amount given):**
  $$\text{GST Amount} = \text{Amount} \times \frac{\text{rate}}{100}$$
  $$\text{CGST} = \text{SGST} = \frac{\text{GST Amount}}{2}, \quad \text{Total Amount} = \text{Amount} + \text{GST Amount}$$
- **Inclusive (Gross Amount given):**
  $$\text{Net Amount} = \frac{\text{Amount} \times 100}{100 + \text{rate}}$$
  $$\text{GST Amount} = \text{Amount} - \text{Net Amount}, \quad \text{CGST} = \text{SGST} = \frac{\text{GST Amount}}{2}$$

### 11.6 Discount Calculator
$$\text{Discount Amount} = \text{Original Price} \times \frac{\text{clampedDiscount}}{100}$$
$$\text{Final Price} = \max(0.0, \text{Original Price} - \text{Discount Amount})$$

### 11.7 In-Field Expression Evaluator
- Implements Dijkstra's Shunting-Yard algorithm using `BigDecimal`.
- Precedence: `×`, `÷` (precedence 2) evaluated before `+`, `-` (precedence 1).
- Unary minus supported: `-100 + 50`.
- Division by zero throws `ArithmeticException("Cannot divide by zero")`.
- Half-up rounding to currency decimal digits.

## 12. Database Interactions
None (stateless calculators; zero database footprint).

## 13. State Management
- Compose local state (`remember { mutableStateOf(...) }`) for fast keystroke recalculations.

## 14. Navigation
- `Screen.Tools` $\to$ `Screen.EmiCalculator`, `Screen.SipCalculator`, `Screen.FdCalculator`, `Screen.RdCalculator`, `Screen.DiscountCalculator`, `Screen.GstCalculator`.

## 15. Error Handling
- Invalid or incomplete input displays ₹0.00 without throwing exceptions or crashing.

## 16. Dependencies
- `FinancialCalculatorEngine`
- `EvaluateCalculatorExpressionUseCase`

## 17. Relevant Android Source Files
- `app/src/main/java/com/vinaynalavade/expensetracker/core/calculator/FinancialCalculatorEngine.kt`
- `app/src/main/java/com/vinaynalavade/expensetracker/domain/usecase/EvaluateCalculatorExpressionUseCase.kt`
- `app/src/main/java/com/vinaynalavade/expensetracker/presentation/tools/` (all calculator screens)

## 18. Relevant Tests
- `app/src/test/java/com/vinaynalavade/expensetracker/FinancialCalculatorEngineTest.kt`
- `app/src/test/java/com/vinaynalavade/expensetracker/CalculatorExpressionEvaluatorTest.kt`

## 19. iOS Implementation Expectations
- Implement as Swift struct `FinancialCalculatorEngine` with identical mathematical formulas.
- SwiftUI screens: `EmiCalculatorView.swift`, `SipCalculatorView.swift`, `FdCalculatorView.swift`, `RdCalculatorView.swift`, `GstCalculatorView.swift`, `DiscountCalculatorView.swift`.
- Use `Decimal` / `Double` matching Android precision.

## 20. Acceptance Criteria
1. EMI calculation: ₹1,00,000 at 10.5% for 12 months yields monthly EMI of ₹8,814.86 $\pm 0.05$.
2. SIP calculation: ₹5,000/mo at 12% for 10 years yields total invested ₹6,00,000 and maturity ₹11,61,695.38 $\pm 1.0$.
3. FD calculation: ₹1,00,000 at 7.5% for 5 years with quarterly compounding yields maturity of ₹1,44,994.80 $\pm 1.0$.
4. Arithmetic evaluator evaluates `100 + 50 * 2` to `200` (respecting precedence).

