# FEATURE SPECIFICATION: FEAT-07 — PDF FINANCIAL STATEMENTS

## 1. Feature ID
`FEAT-07`

## 2. Feature Name
Bank-Grade On-Device PDF Statement Generator

## 3. Purpose
Generates high-precision, professional financial statement documents directly on the device in PDF format. Includes running balance calculations, multi-page vector layout, right-aligned figures, date range filtering, and system share sheet export.

## 4. Current Implementation Status
**VERIFIED (IMPLEMENTED)** — Complete with native zero-dependency vector PDF generator and automated unit tests.

## 5. User-Facing Functionality
- **Statements Screen (`StatementsScreen`)**:
  - Quick Date Range Presets: "This Month", "Last Month", "Last 3 Months", "This Year", "All Time", "Custom Range".
  - Date Range Pickers: Start Date and End Date selectors.
  - Preview Metrics: Displays Statement Period, Total Income, Total Expenses, Net Change, and Transaction Count for the selected range.
  - "Generate & Share PDF" Primary Action.
- **Generated PDF Document Specification**:
  - **Standard Paper Size**: International A4 (595pt $\times$ 842pt at 72dpi).
  - **Header Section**:
    - App Brand: "LEAF" in Emerald Dark (`#064E3B`), bold 22pt.
    - Creator Branding: "Crafted with 💚 in India".
    - Document Title: "Financial Statement", right-aligned bold 14pt.
    - Statement Metadata: Date Range ("01 Oct 2026 – 31 Oct 2026"), Generated Timestamp.
  - **Executive Summary Box**:
    - Opening Balance (carried forward up to statement start).
    - Total Inflows (Income).
    - Total Outflows (Expenses).
    - Net Savings / Deficit.
    - Closing Balance.
  - **Transaction Ledger Table**:
    - Columns: DATE, DESCRIPTION, CATEGORY, INCOME, EXPENSE, BALANCE.
    - Bank-standard alignment: Text columns left-aligned; numerical amounts right-aligned.
    - Multi-page pagination: Automatic page breaking at 30 rows per page with repeated table headers and footer page numbers ("Page 1 of 3").
  - **File Sharing**: Automatically launches Android/iOS system share sheet to AirDrop, Print, save to Files, email, or share via WhatsApp/Drive.

## 6. Entry Points
- Settings menu -> "Export Statement (PDF)".
- Insights / Monthly Summary action menu.
- Screen route: `Screen.Statements`.

## 7. Screen Structure
```text
StatementsScreen
├── TopBar (Back Button, Title "Financial Statements")
├── PresetChipsRow ("This Month", "Last Month", "Last 3 Months", "Custom")
├── CustomDateRangePickers (Start Date, End Date)
├── SummaryPreviewCard (Opening Balance, Income, Expense, Closing Balance, Tx Count)
└── PinnedBottomBar
    └── Button "Generate & Share PDF" (with Loading Spinner)
```

## 8. UI Components
- `StatementsScreen`: Container view.
- `DateRangeSelector`: Preset chips and custom date input triggers.
- `StatementSummaryCard`: Preview card detailing figures before export.
- `PdfUtils`: Pure vector document rendering engine.

## 9. User Interactions
- Tap date preset: Updates start and end dates instantly.
- Tap custom date: Opens date picker.
- Tap "Generate & Share PDF": Compiles report model, renders PDF to app-private cache, and opens native share sheet.

## 10. Input Fields
| Field Name | Type | Validation / Constraints | Mandatory |
| :--- | :--- | :--- | :--- |
| **Start Date** | Long (Epoch) | Start Date $\le$ End Date | Yes |
| **End Date** | Long (Epoch) | End Date $\ge$ Start Date | Yes |

## 11. Validation Rules
- Start date cannot be after end date; automatically swaps or validates if user selects inverted range.
- Empty transaction range: Still generates a valid statement showing opening and closing balance with "No transactions in selected period".

## 12. Business Rules
- **Opening Balance for Statement:**
  Calculated as base opening balance + all historical transactions strictly before `startDateEpoch`.
- **Running Balance in Table:**
  Transactions are sorted chronologically (or newest-first based on setting); running balance updates row-by-row:
  $$\text{Row Balance} = \text{Previous Balance} + \text{Income} - \text{Expense}$$
- **Zero-Dependency Vector Output:** Document is drawn purely using vector primitives (lines, text, fills) for infinite sharpness when printed or zoomed.

## 13. Calculation Logic
- Pre-statement opening balance carry-forward calculation identical to `GetMonthlyLedgerUseCase`.
- Running row balance evaluated sequentially.

## 14. Database Interactions
- `TransactionDao.getTransactionsBetween(startDateEpoch, endDateEpoch)`.
- `TransactionDao.getTransactions()` for historical opening balance calculation.

## 15. State Management
- `StatementsViewModel`: Manages selected date bounds, preview summaries, generation state, and export errors.

## 16. Navigation
- Pushed onto navigation stack from Settings or Insights; back button returns to caller.

## 17. Error Handling
- Storage or file write errors display a descriptive error snackbar.
- Temporary PDF cached in `cacheDir/statements/` to prevent disk bloat.

## 18. Empty States
- When 0 transactions exist: Document still generates successfully with summary metrics and an empty table notice.

## 19. Loading States
- Generate button shows progress indicator while building multi-page canvas.

## 20. Edge Cases
- Statements with hundreds of transactions: Automatically paginated across 10+ pages without memory leaks.
- Multi-currency: Uses the active currency symbol and scaling factor.

## 21. Dependencies
- `GenerateStatementUseCase`
- `TransactionRepository`
- `UserPreferencesRepository`
- `PdfUtils`

## 22. Relevant Android Source Files
- `app/src/main/java/com/vinaynalavade/expensetracker/core/utils/PdfUtils.kt`
- `app/src/main/java/com/vinaynalavade/expensetracker/domain/usecase/GenerateStatementUseCase.kt`
- `app/src/main/java/com/vinaynalavade/expensetracker/presentation/statements/StatementsScreen.kt`
- `app/src/main/java/com/vinaynalavade/expensetracker/presentation/statements/StatementsViewModel.kt`

## 23. Relevant Tests
- `app/src/test/java/com/vinaynalavade/expensetracker/FinancialCalculationTest.kt`

## 24. iOS Implementation Expectations
- Implement on iOS using `PDFKit` (`UIGraphicsPDFRenderer`):
  - Canvas width 595.2pt, height 841.8pt (A4).
  - Multi-page rendering with page context bounds.
  - Present via `UIActivityViewController` or SwiftUI `ShareLink(item: pdfURL)`.

## 25. Acceptance Criteria
1. PDF renders crisp vector text, emerald branding, summary box, and transaction rows.
2. Opening balance plus total income minus total expense strictly matches the closing balance.
3. Multi-page statements repeat table headers on every page with correct page numbering.
4. Native share sheet presents AirDrop, Files, Mail, Print, and messaging options.

