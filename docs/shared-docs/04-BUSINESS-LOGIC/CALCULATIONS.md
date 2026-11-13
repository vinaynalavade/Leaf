# Leaf Business Logic: Financial Calculations & Formulas

## 1. Executive Summary & Core Financial Philosophy
In personal finance applications, calculation accuracy is a non-negotiable trust contract. A single paisa discrepancy or rounding bug undermines user confidence in the entire product. 

Leaf's core calculation architecture adheres to two absolute invariants:
1. **Subunit Integer Arithmetic**: All monetary quantities stored in the database or aggregated in ledgers are 64-bit signed integers representing the smallest currency unit (paise for INR, cents for USD/EUR, whole yen for JPY). Floating-point data types (`Float`, `Double`) are strictly prohibited in persistence and summation.
2. **Deterministic Zero-Sum Reconciliation**: In shared division (e.g., splitting a ₹100 bill among 3 people), the sum of all participant shares must equal the total bill down to the exact subunit:
   $$\sum_{i=1}^N \text{ParticipantShare}_i \equiv \text{TotalBill}$$

---

## 2. Core Financial Continuity & Net Balance Formulas

### 2.1 Liquid Net Balance
The user's real-time net liquid position across all accounts:
$$\text{NetBalance} = \text{OpeningBalanceSubunits} + \sum_{t \in \mathcal{T}_{\text{income}}} t.\text{amount\_subunits} - \sum_{t \in \mathcal{T}_{\text{expense}}} t.\text{amount\_subunits}$$
Where:
- $\text{OpeningBalanceSubunits}$ is the calibrated starting capital from user preferences.
- $\mathcal{T}_{\text{income}}$ is the set of all recorded Income transactions.
- $\mathcal{T}_{\text{expense}}$ is the set of all recorded Expense transactions.

### 2.2 Monthly Opening & Closing Balance Chain
Continuous financial continuity is preserved month-to-month. The opening balance of month $M_k$ is the closing balance of month $M_{k-1}$:
$$\text{OpeningBalance}(M_k) = \text{OpeningBalanceSubunits} + \sum_{t \in \mathcal{T}_{< M_k}, t.\text{type}=\text{INC}} t.\text{subunits} - \sum_{t \in \mathcal{T}_{< M_k}, t.\text{type}=\text{EXP}} t.\text{subunits}$$
$$\text{ClosingBalance}(M_k) = \text{OpeningBalance}(M_k) + \text{TotalIncome}(M_k) - \text{TotalExpense}(M_k)$$

### 2.3 Monthly Net Cashflow & Savings Rate
$$\text{NetCashflow}(M_k) = \text{TotalIncome}(M_k) - \text{TotalExpense}(M_k)$$
$$\text{SavingsRate}(M_k) = \begin{cases} \left( \frac{\text{NetCashflow}(M_k)}{\text{TotalIncome}(M_k)} \right) \times 100 & \text{if } \text{TotalIncome}(M_k) > 0 \\ 0.0 & \text{otherwise} \end{cases}$$

---

## 3. Split & Collect 2.0 Arithmetic

### 3.1 Equal Split with Deterministic Remainder Allocation
When dividing total amount $A$ among $N$ participants ($P_0, P_1, \dots, P_{N-1}$):
$$\text{BaseShare} = \lfloor A / N \rfloor$$
$$\text{Remainder } R = A \pmod N$$
Each participant's allocated share $S_i$ (for $i \in \{0, 1, \dots, N-1\}$):
$$S_i = \begin{cases} \text{BaseShare} + 1 & \text{if } i < R \\ \text{BaseShare} & \text{if } i \ge R \end{cases}$$

**Verification Proof**:
$$\sum_{i=0}^{N-1} S_i = \sum_{i=0}^{R-1} (\text{BaseShare} + 1) + \sum_{i=R}^{N-1} \text{BaseShare} = R \cdot (\text{BaseShare} + 1) + (N - R) \cdot \text{BaseShare} = N \cdot \text{BaseShare} + R = A$$

### 3.2 Itemized Split & Consumption Allocation
For a bill with items $I_1, I_2, \dots, I_m$ where each item has amount $A(I_j)$ and consumer set $C(I_j) \subseteq \{P_0, \dots, P_{N-1}\}$:
1. **Per-Item Share**:
   For each participant $P_k \in C(I_j)$, the item share is:
   $$\text{ItemShare}(P_k, I_j) = \lfloor A(I_j) / |C(I_j)| \rfloor + \begin{cases} 1 & \text{if } \text{index}(P_k, C(I_j)) < (A(I_j) \pmod{|C(I_j)|}) \\ 0 & \text{otherwise} \end{cases}$$
2. **Itemized Subtotal**:
   $$\text{ItemizedTotal}(P_k) = \sum_{j : P_k \in C(I_j)} \text{ItemShare}(P_k, I_j)$$
3. **Unallocated / Shared Base Remainder**:
   $$\text{SharedRemainder} = \text{TotalBill} - \sum_{j=1}^m A(I_j)$$
   Divided equally among the designated shared participants $C_{\text{shared}}$ using the same deterministic penny algorithm.

### 3.3 Directional Net Debt Simplification
When multiple shared bills exist in a group, pairwise debt is simplified transitively to minimize the number of repayments:
$$\text{NetDebt}(A \to B) = \sum \text{UnsettledShares}(A \text{ owes } B) - \sum \text{UnsettledShares}(B \text{ owes } A)$$
If $\text{NetDebt}(A \to B) > 0$, participant $A$ owes $B$. If negative, $B$ owes $A$ the absolute difference.

---

## 4. Planning & Budget Tracking Formulas

### 4.1 Budget Consumption Percentage
For a budget with target limit $L$ and active category expenses $E$:
$$\text{ConsumptionPercent} = \begin{cases} \left( \frac{E}{L} \right) \times 100 & \text{if } L > 0 \\ 0.0 & \text{otherwise} \end{cases}$$

### 4.2 Threshold Classifications
- **On Track**: $\text{ConsumptionPercent} < 75.0\%$
- **Approaching Limit**: $75.0\% \le \text{ConsumptionPercent} < 100.0\%$
- **Limit Reached**: $\text{ConsumptionPercent} == 100.0\%$
- **Over Budget**: $\text{ConsumptionPercent} > 100.0\%$

### 4.3 Daily Recommended Safe Spend
Given remaining budget $R = L - E$ and remaining days in month $D_{\text{remaining}}$:
$$\text{DailySafeSpend} = \begin{cases} \lfloor R / D_{\text{remaining}} \rfloor & \text{if } R > 0 \text{ and } D_{\text{remaining}} > 0 \\ 0 & \text{otherwise} \end{cases}$$

---

## 5. Savings Goals Mathematics

### 5.1 Goal Progress Percentage
For goal target $T$ and cumulative contributions $C = \sum c_i$:
$$\text{ProgressPercent} = \min\left(100.0, \frac{C}{T} \times 100\right)$$

### 5.2 Required Monthly Contribution Rate
Given target date $t_{\text{target}}$, current date $t_{\text{now}}$, and remaining deficit $\Delta = T - C$:
$$\text{MonthsRemaining} = \max\left(1, \text{ChronoUnit.MONTHS.between}(t_{\text{now}}, t_{\text{target}})\right)$$
$$\text{RequiredMonthlySavings} = \lceil \Delta / \text{MonthsRemaining} \rceil$$

---

## 6. Financial Calculators Engine (`FinancialCalculatorEngine`)

### 6.1 Equated Monthly Installment (EMI)
$$\text{MonthlyRate } r = \frac{\text{AnnualRatePercent}}{12 \times 100}$$
$$\text{Factor } f = (1 + r)^n \quad \text{where } n = \text{TenureMonths}$$
$$\text{EMI} = P \times r \times \frac{f}{f - 1}$$
$$\text{TotalPayment} = \text{EMI} \times n$$
$$\text{TotalInterest} = \text{TotalPayment} - P$$
*Boundary Condition*: If $r == 0$, $\text{EMI} = P / n$, $\text{TotalInterest} = 0$.

### 6.2 Systematic Investment Plan (SIP)
Using monthly beginning-of-period compounding (Annuity Due):
$$\text{MonthlyRate } i = \frac{\text{AnnualRatePercent}}{12 \times 100}$$
$$\text{TotalMonths } n = \text{TenureYears} \times 12$$
$$\text{MaturityValue } M = P \times \left[ \frac{(1 + i)^n - 1}{i} \right] \times (1 + i)$$
$$\text{TotalInvested} = P \times n$$
$$\text{EstimatedReturns} = M - \text{TotalInvested}$$
*Clamping*: Annual expected return is clamped to $[0.0\%, 50.0\%]$.

### 6.3 Fixed Deposit (FD)
Quarterly compounding convention standard in banking:
$$\text{Rate } r = \frac{\text{AnnualRatePercent}}{100}$$
$$\text{Quarters } q = 4 \times \text{TenureYears}$$
$$\text{MaturityValue } A = P \times \left(1 + \frac{r}{4}\right)^q$$
$$\text{TotalInterest} = A - P$$

### 6.4 Recurring Deposit (RD)
Quarterly compounding per monthly deposit stream:
$$A = \sum_{m=1}^n \left[ P \times \left(1 + \frac{r}{4}\right)^{\frac{4 \times (n - m + 1)}{12}} \right]$$
$$\text{TotalInvested} = P \times n$$
$$\text{TotalInterest} = A - \text{TotalInvested}$$

### 6.5 Discount & GST Formulas
- **Discount**:
  $$\text{DiscountAmount} = P \times \left(\frac{d}{100}\right), \quad \text{FinalPrice} = P - \text{DiscountAmount}$$
- **GST Exclusive**:
  $$\text{GST} = P \times \left(\frac{r}{100}\right), \quad \text{Total} = P + \text{GST}, \quad \text{CGST} = \text{SGST} = \frac{\text{GST}}{2}$$
- **GST Inclusive**:
  $$\text{NetAmount} = \frac{P \times 100}{100 + r}, \quad \text{GST} = P - \text{NetAmount}, \quad \text{CGST} = \text{SGST} = \frac{\text{GST}}{2}$$

---

## 7. Numerical Precision & Limits
| Constraint | Value | Rationale |
| :--- | :--- | :--- |
| Representation | Signed 64-bit Integer (`Long` / `Int64`) | Avoids binary floating-point rounding errors |
| Subunit Ceiling | $10^{14}$ subunits | ₹100 Crore / \$1 Trillion ceiling prevents integer overflow in cumulative additions |
| Subunit Floor | $-10^{14}$ subunits | Negative net balance ceiling |
| Rate Limits | $[0.0, 100.0]$ | Interest & discount percentage input bounding |

---

## 8. Android vs. iOS Reference Implementations
- **Android**: `core/calculator/FinancialCalculatorEngine.kt`, `domain/split/SplitCalculationEngine.kt`, `core/split/NetBalanceEngine.kt`.
- **iOS**: Replicate verbatim as Swift `struct` utilities (`FinancialCalculatorEngine.swift`, `SplitCalculationEngine.swift`, `NetBalanceEngine.swift`) utilizing `Double` for mathematical power models and `Int64` for subunit ledgers.

