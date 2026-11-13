import Foundation

/// Service responsible for serializing compiled `FinancialStatementData` into RFC 4180 compliant CSV files.
/// Includes UTF-8 BOM encoding so spreadsheet applications (e.g. Microsoft Excel, Apple Numbers, Google Sheets)
/// open financial files cleanly with proper character encodings.
public final class CsvStatementGenerator: @unchecked Sendable {

    private let dateFormatter: DateFormatter
    private let timeFormatter: DateFormatter

    public init() {
        let df = DateFormatter()
        df.locale = Locale(identifier: "en_US_POSIX")
        df.dateFormat = "yyyy-MM-dd"
        self.dateFormatter = df

        let tf = DateFormatter()
        tf.locale = Locale(identifier: "en_US_POSIX")
        tf.dateFormat = "HH:mm:ss"
        self.timeFormatter = tf
    }

    // MARK: - Public Export Endpoints

    /// Generates a full transaction ledger CSV with individual transactions, categories, and direction.
    public func generateTransactionsCsv(data: FinancialStatementData) -> String {
        var lines: [String] = []

        // RFC 4180 Header
        lines.append(makeCsvRow([
            "Date",
            "Time",
            "Description",
            "Category",
            "Type",
            "Direction",
            "Primary Amount",
            "Primary Currency",
            "Original Amount",
            "Original Currency",
            "Exchange Rate",
            "Payment Method",
            "Internal Transfer",
            "Notes"
        ]))

        // Transaction Rows
        for tx in data.transactions {
            let date = Date(timeIntervalSince1970: TimeInterval(tx.timestamp) / 1000.0)
            let dateStr = dateFormatter.string(from: date)
            let timeStr = timeFormatter.string(from: date)
            let categoryName = tx.category?.name ?? "Uncategorized"
            let typeStr = tx.isInternalTransfer ? "TRANSFER" : tx.type.rawValue.uppercased()
            let directionStr = tx.type == .income ? "INFLOW" : "OUTFLOW"
            let amountStr = formatAmountDecimal(tx.amount, currency: data.currency)
            let origAmountStr = formatAmountDecimal(tx.originalAmount, currency: tx.originalCurrency)
            let origCurrencyStr = tx.currencyCode
            let exchangeRateStr = String(format: "%.4f", tx.exchangeRate)
            let methodStr = tx.paymentMethod.displayName
            let isTransferStr = tx.isInternalTransfer ? "YES" : "NO"
            let noteStr = tx.note ?? ""

            lines.append(makeCsvRow([
                dateStr,
                timeStr,
                noteStr.isEmpty ? categoryName : noteStr,
                categoryName,
                typeStr,
                directionStr,
                amountStr,
                data.currency.code,
                origAmountStr,
                origCurrencyStr,
                exchangeRateStr,
                methodStr,
                isTransferStr,
                noteStr
            ]))
        }

        return prependUtf8Bom(lines.joined(separator: "\r\n"))
    }

    /// Generates an analytical category breakdown CSV summarizing spend per category and percentage share.
    public func generateCategorySummaryCsv(data: FinancialStatementData) -> String {
        var lines: [String] = []

        lines.append(makeCsvRow([
            "Category Name",
            "Transaction Count",
            "Total Spend",
            "Currency",
            "Percentage of Expenses",
            "Previous Period Spend",
            "Period Change (%)"
        ]))

        for item in data.categoryBreakdown {
            let amountStr = formatAmountDecimal(item.amount, currency: data.currency)
            let percentageStr = String(format: "%.1f%%", item.percentageOfTotal)
            let prevAmountStr = item.previousPeriodAmount != nil ? formatAmountDecimal(item.previousPeriodAmount!, currency: data.currency) : ""
            let changeStr: String
            if let change = item.changePercentageVsPrevious {
                changeStr = String(format: "%+.1f%%", change)
            } else {
                changeStr = "N/A"
            }

            lines.append(makeCsvRow([
                item.category.name,
                "\(item.transactionCount)",
                amountStr,
                data.currency.code,
                percentageStr,
                prevAmountStr,
                changeStr
            ]))
        }

        return prependUtf8Bom(lines.joined(separator: "\r\n"))
    }

    /// Generates an executive financial summary CSV with all key accounting KPIs:
    /// Operating Cash Flow, Checking Balance Movement, Unspent Income Rate, and Segregated Savings.
    public func generateFinancialSummaryCsv(data: FinancialStatementData) -> String {
        var lines: [String] = []

        // Statement Metadata Header
        lines.append(makeCsvRow(["Statement Title", data.title]))
        lines.append(makeCsvRow(["Statement Period", data.period.displayName]))
        lines.append(makeCsvRow(["Date Interval", "\(dateFormatter.string(from: data.dateInterval.start)) to \(dateFormatter.string(from: data.dateInterval.end))"]))
        lines.append(makeCsvRow(["Currency", data.currency.code]))
        lines.append(makeCsvRow(["Generated At", "\(dateFormatter.string(from: data.generatedAt)) \(timeFormatter.string(from: data.generatedAt))"]))
        lines.append("")

        // Financial KPIs Header
        lines.append(makeCsvRow([
            "Financial Metric",
            "Amount / Value",
            "Unit / Currency",
            "Accounting Description"
        ]))

        let kpis: [(metric: String, value: String, unit: String, desc: String)] = [
            ("Opening Balance", formatAmountDecimal(data.openingBalance, currency: data.currency), data.currency.code, "Total liquid balance across checking/cash at period start"),
            ("Closing Balance", formatAmountDecimal(data.closingBalance, currency: data.currency), data.currency.code, "Total liquid balance across checking/cash at period end"),
            ("Checking Inflows", formatAmountDecimal(data.totalCheckingInflow, currency: data.currency), data.currency.code, "All funds deposited into checking account (including savings withdrawals)"),
            ("Checking Outflows", formatAmountDecimal(data.totalCheckingOutflow, currency: data.currency), data.currency.code, "All funds withdrawn from checking account (including savings deposits)"),
            ("Checking Balance Movement", formatAmountDecimal(data.checkingBalanceMovement, currency: data.currency), data.currency.code, "Net liquid checking movement: Inflows minus Outflows"),
            ("Earned Income", formatAmountDecimal(data.earnedIncome, currency: data.currency), data.currency.code, "Total ordinary income earned (excludes internal transfers and savings withdrawals)"),
            ("Ordinary Expenses", formatAmountDecimal(data.ordinaryExpenses, currency: data.currency), data.currency.code, "Total ordinary living expenses (excludes internal transfers and savings deposits)"),
            ("Operating Cash Flow", formatAmountDecimal(data.operatingCashFlow, currency: data.currency), data.currency.code, "Net financial health: Earned Income minus Ordinary Expenses"),
            ("Unspent Income Rate", String(format: "%.1f%%", data.unspentIncomeRate), "%", "Portion of earned income not consumed by ordinary expenses"),
            ("Net Savings Contributions", formatAmountDecimal(data.netSavingsContributions, currency: data.currency), data.currency.code, "Dedicated capital allocated into savings goals"),
            ("Actual Savings Contribution Rate", String(format: "%.1f%%", data.actualSavingsRate), "%", "Portion of earned income dedicated to savings goals"),
            ("Total Transactions Recorded", "\(data.transactionCount)", "Count", "Total ledger entries recorded in period")
        ]

        for kpi in kpis {
            lines.append(makeCsvRow([kpi.metric, kpi.value, kpi.unit, kpi.desc]))
        }

        // Budget Performance Section (if applicable)
        if !data.budgetSummaries.isEmpty {
            lines.append("")
            lines.append(makeCsvRow(["Budget Performance", "", "", ""]))
            lines.append(makeCsvRow(["Budget Name", "Limit", "Spent", "Utilisation (%)"]))
            for b in data.budgetSummaries {
                let limitStr = formatAmountDecimal(b.limitAmount, currency: data.currency)
                let spentStr = formatAmountDecimal(b.spentAmount, currency: data.currency)
                let utilStr = String(format: "%.1f%%", b.utilisationPercentage)
                let name = b.category?.name ?? "Overall Budget"
                lines.append(makeCsvRow([name, limitStr, spentStr, utilStr]))
            }
        }

        // Detailed Savings Activity Section (if applicable)
        if !data.detailedSavings.isEmpty {
            lines.append("")
            lines.append(makeCsvRow(["Detailed Savings Activity", "", "", ""]))
            lines.append(makeCsvRow(["Date", "Savings Goal", "Action Type", "Amount", "Currency", "Note"]))
            for s in data.detailedSavings {
                let dateStr = dateFormatter.string(from: s.date)
                let typeStr = s.isWithdrawal ? "WITHDRAWAL" : "DEPOSIT"
                let amtStr = (s.isWithdrawal ? "-" : "+") + formatAmountDecimal(s.amount, currency: data.currency)
                lines.append(makeCsvRow([dateStr, s.goalTitle, typeStr, amtStr, data.currency.code, s.note ?? ""]))
            }
        }

        return prependUtf8Bom(lines.joined(separator: "\r\n"))
    }

    // MARK: - Helpers

    /// Formats Amount to standard decimal string (e.g. 1250.50).
    private func formatAmountDecimal(_ amount: Amount, currency: Currency) -> String {
        let absVal = abs(amount.subunits)
        let main = absVal / currency.subunitFactor
        let frac = absVal % currency.subunitFactor
        let sign = amount.subunits < 0 ? "-" : ""

        if currency.decimalDigits > 0 {
            let fracStr = String(format: "%0*d", currency.decimalDigits, frac)
            return "\(sign)\(main).\(fracStr)"
        } else {
            return "\(sign)\(main)"
        }
    }

    /// RFC 4180 compliant row assembly with quoting and escape doubling.
    private func makeCsvRow(_ fields: [String]) -> String {
        return fields.map { escapeCsvField($0) }.joined(separator: ",")
    }

    /// Escapes commas, quotes, and newlines according to RFC 4180.
    private func escapeCsvField(_ field: String) -> String {
        if field.contains(",") || field.contains("\"") || field.contains("\n") || field.contains("\r") {
            let escaped = field.replacingOccurrences(of: "\"", with: "\"\"")
            return "\"\(escaped)\""
        }
        return field
    }

    /// Adds UTF-8 Byte Order Mark (BOM) so Excel opens UTF-8 files seamlessly.
    private func prependUtf8Bom(_ text: String) -> String {
        return "\u{FEFF}" + text
    }
}

