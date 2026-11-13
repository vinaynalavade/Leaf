import Foundation
import UIKit
import PDFKit
import CoreGraphics

/// Generates complete, multi-page financial statement PDFs using Core Graphics and `UIGraphicsPDFRenderer`.
/// Produces a bank-grade report incorporating:
/// - Executive Financial Summary with segregated Operating Cash Flow and Checking Balance Movement
/// - Balances reconciliation (Opening, Closing, Net Movement)
/// - Earned Income breakdown by category with percentages and transaction counts
/// - Ordinary Expenses breakdown by category with percentages and transaction counts
/// - Detailed Savings activity (Contributions & Withdrawals with goal names, dates, amounts)
/// - Budget performance review for all applicable budgets
/// - Complete chronological Transaction Ledger spanning across multiple pages
/// - Repeated table headers when tables continue across page breaks
/// - Consistent page numbering ("Page X of Y") and confidentiality footers on all pages
public final class PdfStatementGenerator: @unchecked Sendable {

    // Standard A4 dimensions in points (72 points / inch)
    private let pageWidth: CGFloat = 595.2
    private let pageHeight: CGFloat = 841.8

    // Margins
    private let marginX: CGFloat = 36.0
    private let marginTop: CGFloat = 36.0
    private let marginBottom: CGFloat = 38.0

    private var contentWidth: CGFloat {
        pageWidth - (marginX * 2.0)
    }

    // Color Palette
    private let colorPrimary = UIColor(red: 17/255, green: 24/255, blue: 39/255, alpha: 1.0)       // Slate 900
    private let colorSecondary = UIColor(red: 75/255, green: 85/255, blue: 99/255, alpha: 1.0)    // Slate 600
    private let colorMuted = UIColor(red: 156/255, green: 163/255, blue: 175/255, alpha: 1.0)     // Slate 400
    private let colorBrand = UIColor(red: 16/255, green: 163/255, blue: 115/255, alpha: 1.0)      // Leaf Emerald
    private let colorBrandDark = UIColor(red: 12/255, green: 115/255, blue: 82/255, alpha: 1.0)  // Deep Emerald
    private let colorCardBg = UIColor(red: 248/255, green: 250/255, blue: 252/255, alpha: 1.0)     // Slate 50
    private let colorRowAlt = UIColor(red: 251/255, green: 252/255, blue: 254/255, alpha: 1.0)
    private let colorBorder = UIColor(red: 226/255, green: 232/255, blue: 240/255, alpha: 1.0)    // Slate 200
    private let colorIncome = UIColor(red: 16/255, green: 140/255, blue: 75/255, alpha: 1.0)      // Green 600
    private let colorExpense = UIColor(red: 220/255, green: 38/255, blue: 38/255, alpha: 1.0)     // Red 600
    private let colorTransfer = UIColor(red: 59/255, green: 130/255, blue: 246/255, alpha: 1.0)   // Blue 500

    private let dateFormatter: DateFormatter
    private let shortDateFormatter: DateFormatter

    public init() {
        let df = DateFormatter()
        df.locale = Locale(identifier: "en_US_POSIX")
        df.dateFormat = "dd MMMM yyyy"
        self.dateFormatter = df

        let sdf = DateFormatter()
        sdf.locale = Locale(identifier: "en_US_POSIX")
        sdf.dateFormat = "dd MMM yyyy"
        self.shortDateFormatter = sdf
    }

    // MARK: - Public PDF Generation

    /// Generates full PDF binary data from the compiled `FinancialStatementData`.
    public func generatePdf(data: FinancialStatementData) -> Data {
        let format = UIGraphicsPDFRendererFormat()
        let pageBounds = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)

        // Pass 1: Measure total pages so footer displays exact "Page X of Y"
        var measuredPages = 1
        let dummyRenderer = UIGraphicsPDFRenderer(bounds: pageBounds, format: format)
        _ = dummyRenderer.pdfData { context in
            measuredPages = renderDocument(data: data, totalPages: 1, isDryRun: true, context: context)
        }
        if measuredPages < 1 { measuredPages = 1 }

        // Pass 2: Render final PDF data with accurate totalPages
        let finalRenderer = UIGraphicsPDFRenderer(bounds: pageBounds, format: format)
        return finalRenderer.pdfData { context in
            _ = renderDocument(data: data, totalPages: measuredPages, isDryRun: false, context: context)
        }
    }

    // MARK: - Core Multi-Page Renderer

    private func renderDocument(
        data: FinancialStatementData,
        totalPages: Int,
        isDryRun: Bool,
        context: UIGraphicsPDFRendererContext
    ) -> Int {
        var pageNumber = 1
        context.beginPage()

        var cursorY: CGFloat = marginTop

        // 1. Draw Brand Header & Executive Summary
        if !isDryRun {
            drawBrandHeader(data: data, at: &cursorY)
            drawFinancialSummaryCard(data: data, at: &cursorY)
        } else {
            cursorY += 215.0
        }

        // Helper for page overflow with table header repetition
        func checkPageOverflow(neededHeight: CGFloat, headerRepetition: (() -> Void)? = nil) {
            if (cursorY + neededHeight) > (pageHeight - marginBottom - 25.0) {
                if !isDryRun { drawFooter(pageNumber: pageNumber, totalPages: totalPages) }
                pageNumber += 1
                context.beginPage()
                cursorY = marginTop
                if !isDryRun {
                    drawContinuedHeader(title: data.title, at: &cursorY)
                    headerRepetition?()
                } else {
                    cursorY += 24.0
                }
            }
        }

        // 2. Earned Income Breakdown Table
        if !data.incomeBreakdown.isEmpty {
            checkPageOverflow(neededHeight: 65.0)
            if !isDryRun {
                drawSectionTitle("EARNED INCOME BREAKDOWN (By Category)", at: &cursorY)
                drawIncomeTableHeader(at: &cursorY)
            } else {
                cursorY += 34.0
            }

            for (index, item) in data.incomeBreakdown.enumerated() {
                checkPageOverflow(neededHeight: 18.0) {
                    self.drawIncomeTableHeader(at: &cursorY)
                }
                if !isDryRun {
                    drawCategoryRow(
                        categoryName: item.category.name,
                        count: item.transactionCount,
                        sharePct: item.percentageOfTotal,
                        amount: item.amount,
                        currency: data.currency,
                        amountColor: colorIncome,
                        index: index,
                        at: cursorY
                    )
                }
                cursorY += 18.0
            }
            cursorY += 10.0
        }

        // 3. Ordinary Expense Breakdown Table (All categories)
        if !data.categoryBreakdown.isEmpty {
            checkPageOverflow(neededHeight: 65.0)
            if !isDryRun {
                drawSectionTitle("ORDINARY EXPENSE BREAKDOWN (By Category)", at: &cursorY)
                drawExpenseTableHeader(at: &cursorY)
            } else {
                cursorY += 34.0
            }

            for (index, item) in data.categoryBreakdown.enumerated() {
                checkPageOverflow(neededHeight: 18.0) {
                    self.drawExpenseTableHeader(at: &cursorY)
                }
                if !isDryRun {
                    drawCategoryRow(
                        categoryName: item.category.name,
                        count: item.transactionCount,
                        sharePct: item.percentageOfTotal,
                        amount: item.amount,
                        currency: data.currency,
                        amountColor: colorExpense,
                        index: index,
                        at: cursorY
                    )
                }
                cursorY += 18.0
            }
            cursorY += 10.0
        }

        // 4. Detailed Savings Contributions & Withdrawals Table
        if !data.detailedSavings.isEmpty {
            checkPageOverflow(neededHeight: 65.0)
            if !isDryRun {
                drawSectionTitle("SAVINGS ACTIVITY (Contributions & Withdrawals)", at: &cursorY)
                drawSavingsTableHeader(at: &cursorY)
            } else {
                cursorY += 34.0
            }

            for (index, item) in data.detailedSavings.enumerated() {
                checkPageOverflow(neededHeight: 18.0) {
                    self.drawSavingsTableHeader(at: &cursorY)
                }
                if !isDryRun {
                    drawSavingsRow(item: item, currency: data.currency, index: index, at: cursorY)
                }
                cursorY += 18.0
            }
            cursorY += 10.0
        }

        // 5. Budget Performance Table
        if !data.budgetSummaries.isEmpty {
            checkPageOverflow(neededHeight: 65.0)
            if !isDryRun {
                drawSectionTitle("BUDGET PERFORMANCE FOR PERIOD", at: &cursorY)
                drawBudgetTableHeader(at: &cursorY)
            } else {
                cursorY += 34.0
            }

            for (index, b) in data.budgetSummaries.enumerated() {
                checkPageOverflow(neededHeight: 18.0) {
                    self.drawBudgetTableHeader(at: &cursorY)
                }
                if !isDryRun {
                    drawBudgetRow(b: b, currency: data.currency, index: index, at: cursorY)
                }
                cursorY += 18.0
            }
            cursorY += 10.0
        }

        // 6. Complete Chronological Transaction Ledger
        let txRowHeight: CGFloat = 20.0
        checkPageOverflow(neededHeight: 65.0)

        if !isDryRun {
            drawSectionTitle("TRANSACTION LEDGER", at: &cursorY)
            drawLedgerHeader(at: &cursorY)
        } else {
            cursorY += 34.0
        }

        for (index, tx) in data.transactions.enumerated() {
            checkPageOverflow(neededHeight: txRowHeight) {
                self.drawLedgerHeader(at: &cursorY)
            }
            if !isDryRun {
                drawLedgerRow(tx: tx, index: index, currency: data.currency, at: cursorY)
            }
            cursorY += txRowHeight
        }

        if data.transactions.isEmpty && !isDryRun {
            drawEmptyLedgerRow(at: cursorY)
            cursorY += txRowHeight
        }

        // Final Page Footer
        if !isDryRun {
            drawFooter(pageNumber: pageNumber, totalPages: totalPages)
        }

        return pageNumber
    }

    // MARK: - Section Headers & Brand Mark

    private func drawBrandHeader(data: FinancialStatementData, at cursorY: inout CGFloat) {
        let startY = cursorY

        // Leaf Brand Mark (Emerald Rounded Rectangle with "L")
        let iconRect = CGRect(x: marginX, y: startY, width: 32, height: 32)
        let iconPath = UIBezierPath(roundedRect: iconRect, cornerRadius: 8.0)
        colorBrand.setFill()
        iconPath.fill()

        let lAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 18, weight: .bold),
            .foregroundColor: UIColor.white
        ]
        let lText = "L"
        let lSize = lText.size(withAttributes: lAttrs)
        lText.draw(at: CGPoint(x: iconRect.midX - (lSize.width / 2.0), y: iconRect.midY - (lSize.height / 2.0)), withAttributes: lAttrs)

        // Brand Title
        let brandAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 13, weight: .bold),
            .foregroundColor: colorPrimary
        ]
        "LEAF".draw(at: CGPoint(x: marginX + 40.0, y: startY + 2.0), withAttributes: brandAttrs)

        let subtitleAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 8.5, weight: .regular),
            .foregroundColor: colorSecondary
        ]
        "Personal Financial Statement".draw(at: CGPoint(x: marginX + 40.0, y: startY + 18.0), withAttributes: subtitleAttrs)

        // Right side: Generation metadata
        let genDateStr = "Generated on \(shortDateFormatter.string(from: data.generatedAt))"
        let rightAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 8.5, weight: .medium),
            .foregroundColor: colorSecondary
        ]
        let rightSize = genDateStr.size(withAttributes: rightAttrs)
        genDateStr.draw(at: CGPoint(x: marginX + contentWidth - rightSize.width, y: startY + 2.0), withAttributes: rightAttrs)

        let confText = "Official Financial Ledger"
        let confAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 8.0, weight: .regular),
            .foregroundColor: colorMuted
        ]
        let confSize = confText.size(withAttributes: confAttrs)
        confText.draw(at: CGPoint(x: marginX + contentWidth - confSize.width, y: startY + 18.0), withAttributes: confAttrs)

        cursorY = startY + 44.0

        // Document Title
        let titleAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 18, weight: .bold),
            .foregroundColor: colorPrimary
        ]
        data.title.draw(at: CGPoint(x: marginX, y: cursorY), withAttributes: titleAttrs)
        cursorY += 24.0

        // Period Subtitle
        let periodStr: String
        if case .allTime = data.period {
            periodStr = "All Recorded Activity  •  Full Financial History"
        } else {
            periodStr = "\(data.period.displayName)  •  \(dateFormatter.string(from: data.dateInterval.start)) – \(dateFormatter.string(from: data.dateInterval.end))"
        }
        let periodAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 10, weight: .medium),
            .foregroundColor: colorBrandDark
        ]
        periodStr.draw(at: CGPoint(x: marginX, y: cursorY), withAttributes: periodAttrs)
        cursorY += 18.0

        // Accent Separator Line
        drawLine(from: CGPoint(x: marginX, y: cursorY), to: CGPoint(x: marginX + contentWidth, y: cursorY), color: colorBorder, width: 0.75)
        cursorY += 12.0
    }

    private func drawContinuedHeader(title: String, at cursorY: inout CGFloat) {
        let text = "\(title) — Continued"
        let attrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 9, weight: .medium),
            .foregroundColor: colorSecondary
        ]
        text.draw(at: CGPoint(x: marginX, y: cursorY), withAttributes: attrs)
        cursorY += 16.0
        drawLine(from: CGPoint(x: marginX, y: cursorY), to: CGPoint(x: marginX + contentWidth, y: cursorY), color: colorBorder, width: 0.5)
        cursorY += 8.0
    }

    private func drawSectionTitle(_ title: String, at cursorY: inout CGFloat) {
        let secAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 9.5, weight: .bold),
            .foregroundColor: colorPrimary
        ]
        title.draw(at: CGPoint(x: marginX, y: cursorY), withAttributes: secAttrs)
        cursorY += 15.0
    }

    // MARK: - Executive Financial Summary Card

    private func drawFinancialSummaryCard(data: FinancialStatementData, at cursorY: inout CGFloat) {
        let cardRect = CGRect(x: marginX, y: cursorY, width: contentWidth, height: 110.0)
        let cardPath = UIBezierPath(roundedRect: cardRect, cornerRadius: 8.0)
        colorCardBg.setFill()
        cardPath.fill()
        colorBorder.setStroke()
        cardPath.lineWidth = 0.75
        cardPath.stroke()

        // Section Title inside card
        let secAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 9.5, weight: .bold),
            .foregroundColor: colorPrimary
        ]
        "FINANCIAL POSITION & CASH FLOW SUMMARY".draw(at: CGPoint(x: marginX + 12.0, y: cursorY + 10.0), withAttributes: secAttrs)

        let colWidth = (contentWidth - 24.0) / 3.0
        let row1Y = cursorY + 30.0
        let row2Y = cursorY + 70.0

        // Column 1: Checking Balances
        drawKpiBlock(
            label: "Opening Balance",
            value: data.openingBalance.formatted(with: data.currency),
            valueColor: colorPrimary,
            at: CGPoint(x: marginX + 12.0, y: row1Y),
            width: colWidth
        )
        drawKpiBlock(
            label: "Closing Balance",
            value: data.closingBalance.formatted(with: data.currency),
            valueColor: colorPrimary,
            at: CGPoint(x: marginX + 12.0, y: row2Y),
            width: colWidth
        )

        // Column 2: Operating Cash Flow
        let ocfColor = data.operatingCashFlow.isNegative ? colorExpense : colorIncome
        drawKpiBlock(
            label: "Earned Income",
            value: data.earnedIncome.formatted(with: data.currency),
            valueColor: colorIncome,
            at: CGPoint(x: marginX + 12.0 + colWidth, y: row1Y),
            width: colWidth
        )
        drawKpiBlock(
            label: "Operating Cash Flow",
            value: data.operatingCashFlow.formatted(with: data.currency),
            valueColor: ocfColor,
            subtitle: "Unspent Income: \(String(format: "%.1f%%", data.unspentIncomeRate))",
            at: CGPoint(x: marginX + 12.0 + colWidth, y: row2Y),
            width: colWidth
        )

        // Column 3: Checking Balance Movement & Savings
        drawKpiBlock(
            label: "Ordinary Expenses",
            value: data.ordinaryExpenses.formatted(with: data.currency),
            valueColor: colorExpense,
            at: CGPoint(x: marginX + 12.0 + (colWidth * 2.0), y: row1Y),
            width: colWidth
        )
        drawKpiBlock(
            label: "Checking Movement",
            value: data.checkingBalanceMovement.formatted(with: data.currency),
            valueColor: data.checkingBalanceMovement.isNegative ? colorExpense : colorIncome,
            subtitle: "Net Savings: \(data.netSavingsContributions.formatted(with: data.currency))",
            at: CGPoint(x: marginX + 12.0 + (colWidth * 2.0), y: row2Y),
            width: colWidth
        )

        cursorY += 122.0
    }

    private func drawKpiBlock(
        label: String,
        value: String,
        valueColor: UIColor,
        subtitle: String? = nil,
        at point: CGPoint,
        width: CGFloat
    ) {
        let labelAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 7.5, weight: .medium),
            .foregroundColor: colorSecondary
        ]
        label.draw(at: point, withAttributes: labelAttrs)

        let valAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 11, weight: .bold),
            .foregroundColor: valueColor
        ]
        value.draw(at: CGPoint(x: point.x, y: point.y + 11.0), withAttributes: valAttrs)

        if let sub = subtitle {
            let subAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 7.0, weight: .regular),
                .foregroundColor: colorMuted
            ]
            sub.draw(at: CGPoint(x: point.x, y: point.y + 25.0), withAttributes: subAttrs)
        }
    }

    // MARK: - Income & Expense Category Tables

    private func drawIncomeTableHeader(at cursorY: inout CGFloat) {
        let subBgRect = CGRect(x: marginX, y: cursorY, width: contentWidth, height: 16.0)
        colorCardBg.setFill()
        UIRectFill(subBgRect)

        let hAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 8, weight: .bold),
            .foregroundColor: colorSecondary
        ]
        "Income Source / Category".draw(at: CGPoint(x: marginX + 6.0, y: cursorY + 3.0), withAttributes: hAttrs)
        "Transactions".draw(at: CGPoint(x: marginX + 220.0, y: cursorY + 3.0), withAttributes: hAttrs)
        "Share of Income (%)".draw(at: CGPoint(x: marginX + 320.0, y: cursorY + 3.0), withAttributes: hAttrs)

        let amtH = "Amount"
        let amtSize = amtH.size(withAttributes: hAttrs)
        amtH.draw(at: CGPoint(x: marginX + contentWidth - amtSize.width - 6.0, y: cursorY + 3.0), withAttributes: hAttrs)
        cursorY += 18.0
    }

    private func drawExpenseTableHeader(at cursorY: inout CGFloat) {
        let subBgRect = CGRect(x: marginX, y: cursorY, width: contentWidth, height: 16.0)
        colorCardBg.setFill()
        UIRectFill(subBgRect)

        let hAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 8, weight: .bold),
            .foregroundColor: colorSecondary
        ]
        "Expense Category".draw(at: CGPoint(x: marginX + 6.0, y: cursorY + 3.0), withAttributes: hAttrs)
        "Transactions".draw(at: CGPoint(x: marginX + 220.0, y: cursorY + 3.0), withAttributes: hAttrs)
        "Share of Expenses (%)".draw(at: CGPoint(x: marginX + 320.0, y: cursorY + 3.0), withAttributes: hAttrs)

        let amtH = "Amount"
        let amtSize = amtH.size(withAttributes: hAttrs)
        amtH.draw(at: CGPoint(x: marginX + contentWidth - amtSize.width - 6.0, y: cursorY + 3.0), withAttributes: hAttrs)
        cursorY += 18.0
    }

    private func drawCategoryRow(
        categoryName: String,
        count: Int,
        sharePct: Double,
        amount: Amount,
        currency: Currency,
        amountColor: UIColor,
        index: Int,
        at cursorY: CGFloat
    ) {
        if index % 2 == 1 {
            let rRect = CGRect(x: marginX, y: cursorY, width: contentWidth, height: 16.0)
            colorRowAlt.setFill()
            UIRectFill(rRect)
        }

        let nameAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 8.5, weight: .regular),
            .foregroundColor: colorPrimary
        ]
        categoryName.draw(at: CGPoint(x: marginX + 6.0, y: cursorY + 2.5), withAttributes: nameAttrs)

        let countAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 8.0, weight: .regular),
            .foregroundColor: colorSecondary
        ]
        "\(count)".draw(at: CGPoint(x: marginX + 220.0, y: cursorY + 2.5), withAttributes: countAttrs)

        let shareStr = String(format: "%.1f%%", sharePct)
        shareStr.draw(at: CGPoint(x: marginX + 320.0, y: cursorY + 2.5), withAttributes: countAttrs)

        let amtStr = amount.formatted(with: currency)
        let amtAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 8.5, weight: .medium),
            .foregroundColor: amountColor
        ]
        let aSize = amtStr.size(withAttributes: amtAttrs)
        amtStr.draw(at: CGPoint(x: marginX + contentWidth - aSize.width - 6.0, y: cursorY + 2.5), withAttributes: amtAttrs)
    }

    // MARK: - Detailed Savings Activity Table

    private func drawSavingsTableHeader(at cursorY: inout CGFloat) {
        let subBgRect = CGRect(x: marginX, y: cursorY, width: contentWidth, height: 16.0)
        colorCardBg.setFill()
        UIRectFill(subBgRect)

        let hAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 8, weight: .bold),
            .foregroundColor: colorSecondary
        ]
        "Date".draw(at: CGPoint(x: marginX + 6.0, y: cursorY + 3.0), withAttributes: hAttrs)
        "Savings Goal".draw(at: CGPoint(x: marginX + 80.0, y: cursorY + 3.0), withAttributes: hAttrs)
        "Action Type".draw(at: CGPoint(x: marginX + 260.0, y: cursorY + 3.0), withAttributes: hAttrs)
        "Note".draw(at: CGPoint(x: marginX + 345.0, y: cursorY + 3.0), withAttributes: hAttrs)

        let amtH = "Amount"
        let amtSize = amtH.size(withAttributes: hAttrs)
        amtH.draw(at: CGPoint(x: marginX + contentWidth - amtSize.width - 6.0, y: cursorY + 3.0), withAttributes: hAttrs)
        cursorY += 18.0
    }

    private func drawSavingsRow(item: DetailedSavingsItem, currency: Currency, index: Int, at cursorY: CGFloat) {
        if index % 2 == 1 {
            let rRect = CGRect(x: marginX, y: cursorY, width: contentWidth, height: 16.0)
            colorRowAlt.setFill()
            UIRectFill(rRect)
        }

        let secAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 7.5, weight: .regular),
            .foregroundColor: colorSecondary
        ]

        // Date
        shortDateFormatter.string(from: item.date).draw(at: CGPoint(x: marginX + 6.0, y: cursorY + 2.5), withAttributes: secAttrs)

        // Goal Title
        let nameRect = CGRect(x: marginX + 80.0, y: cursorY + 2.5, width: 170.0, height: 14.0)
        let pStyle = NSMutableParagraphStyle()
        pStyle.lineBreakMode = .byTruncatingTail
        let nameAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 8.0, weight: .medium),
            .foregroundColor: colorPrimary,
            .paragraphStyle: pStyle
        ]
        item.goalTitle.draw(in: nameRect, withAttributes: nameAttrs)

        // Action Type
        let typeStr = item.isWithdrawal ? "Withdrawal" : "Deposit"
        let typeColor = item.isWithdrawal ? colorExpense : colorIncome
        let typeAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 8.0, weight: .semibold),
            .foregroundColor: typeColor
        ]
        typeStr.draw(at: CGPoint(x: marginX + 260.0, y: cursorY + 2.5), withAttributes: typeAttrs)

        // Note
        let noteStr = item.note?.isEmpty == false ? item.note! : "—"
        let noteRect = CGRect(x: marginX + 345.0, y: cursorY + 2.5, width: 85.0, height: 14.0)
        noteStr.draw(in: noteRect, withAttributes: secAttrs)

        // Amount
        let prefix = item.isWithdrawal ? "-" : "+"
        let amtFormatted = "\(prefix)\(item.amount.formatted(with: currency))"
        let amtAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 8.0, weight: .bold),
            .foregroundColor: typeColor
        ]
        let amtSize = amtFormatted.size(withAttributes: amtAttrs)
        amtFormatted.draw(at: CGPoint(x: marginX + contentWidth - amtSize.width - 6.0, y: cursorY + 2.5), withAttributes: amtAttrs)
    }

    // MARK: - Budget Performance Table

    private func drawBudgetTableHeader(at cursorY: inout CGFloat) {
        let subBgRect = CGRect(x: marginX, y: cursorY, width: contentWidth, height: 16.0)
        colorCardBg.setFill()
        UIRectFill(subBgRect)

        let hAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 8, weight: .bold),
            .foregroundColor: colorSecondary
        ]
        "Budget Target / Category".draw(at: CGPoint(x: marginX + 6.0, y: cursorY + 3.0), withAttributes: hAttrs)
        "Limit".draw(at: CGPoint(x: marginX + 190.0, y: cursorY + 3.0), withAttributes: hAttrs)
        "Spent".draw(at: CGPoint(x: marginX + 280.0, y: cursorY + 3.0), withAttributes: hAttrs)
        "Remaining".draw(at: CGPoint(x: marginX + 370.0, y: cursorY + 3.0), withAttributes: hAttrs)

        let utilH = "Utilisation"
        let utilSize = utilH.size(withAttributes: hAttrs)
        utilH.draw(at: CGPoint(x: marginX + contentWidth - utilSize.width - 6.0, y: cursorY + 3.0), withAttributes: hAttrs)
        cursorY += 18.0
    }

    private func drawBudgetRow(b: BudgetInsightItem, currency: Currency, index: Int, at cursorY: CGFloat) {
        if index % 2 == 1 {
            let rRect = CGRect(x: marginX, y: cursorY, width: contentWidth, height: 16.0)
            colorRowAlt.setFill()
            UIRectFill(rRect)
        }

        let name = b.category?.name ?? "Overall Budget"
        let nameAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 8.5, weight: .regular),
            .foregroundColor: colorPrimary
        ]
        name.draw(at: CGPoint(x: marginX + 6.0, y: cursorY + 2.5), withAttributes: nameAttrs)

        let valAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 8.0, weight: .regular),
            .foregroundColor: colorSecondary
        ]
        b.limitAmount.formatted(with: currency).draw(at: CGPoint(x: marginX + 190.0, y: cursorY + 2.5), withAttributes: valAttrs)
        b.spentAmount.formatted(with: currency).draw(at: CGPoint(x: marginX + 280.0, y: cursorY + 2.5), withAttributes: valAttrs)
        b.remainingAmount.formatted(with: currency).draw(at: CGPoint(x: marginX + 370.0, y: cursorY + 2.5), withAttributes: valAttrs)

        let utilStr = String(format: "%.1f%%", b.utilisationPercentage)
        let utilColor = b.utilisationPercentage > 100.0 ? colorExpense : (b.utilisationPercentage > 85.0 ? UIColor.systemOrange : colorBrand)
        let utilAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 8.5, weight: .bold),
            .foregroundColor: utilColor
        ]
        let uSize = utilStr.size(withAttributes: utilAttrs)
        utilStr.draw(at: CGPoint(x: marginX + contentWidth - uSize.width - 6.0, y: cursorY + 2.5), withAttributes: utilAttrs)
    }

    // MARK: - Transaction Ledger Table

    private func drawLedgerHeader(at cursorY: inout CGFloat) {
        let headerRect = CGRect(x: marginX, y: cursorY, width: contentWidth, height: 18.0)
        colorCardBg.setFill()
        UIRectFill(headerRect)

        let hAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 8, weight: .bold),
            .foregroundColor: colorSecondary
        ]

        // Columns: Date (55), Description (175), Category (105), Method (55), Type (55), Amount (78.2)
        "Date".draw(at: CGPoint(x: marginX + 6.0, y: cursorY + 4.0), withAttributes: hAttrs)
        "Description".draw(at: CGPoint(x: marginX + 65.0, y: cursorY + 4.0), withAttributes: hAttrs)
        "Category".draw(at: CGPoint(x: marginX + 240.0, y: cursorY + 4.0), withAttributes: hAttrs)
        "Method".draw(at: CGPoint(x: marginX + 345.0, y: cursorY + 4.0), withAttributes: hAttrs)
        "Type".draw(at: CGPoint(x: marginX + 400.0, y: cursorY + 4.0), withAttributes: hAttrs)

        let amtTitle = "Amount"
        let aSize = amtTitle.size(withAttributes: hAttrs)
        amtTitle.draw(at: CGPoint(x: marginX + contentWidth - aSize.width - 6.0, y: cursorY + 4.0), withAttributes: hAttrs)

        cursorY += 20.0
    }

    private func drawLedgerRow(tx: Transaction, index: Int, currency: Currency, at cursorY: CGFloat) {
        if index % 2 == 1 {
            let rowRect = CGRect(x: marginX, y: cursorY, width: contentWidth, height: 18.0)
            colorRowAlt.setFill()
            UIRectFill(rowRect)
        }

        let date = Date(timeIntervalSince1970: TimeInterval(tx.timestamp) / 1000.0)
        let dateStr = shortDateFormatter.string(from: date)

        let secAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 7.5, weight: .regular),
            .foregroundColor: colorSecondary
        ]

        // Date
        dateStr.draw(at: CGPoint(x: marginX + 6.0, y: cursorY + 3.5), withAttributes: secAttrs)

        // Description / Note (truncated with ellipsis if too long)
        let desc = (tx.note?.isEmpty == false ? tx.note! : (tx.category?.name ?? "Transaction"))
        let descRect = CGRect(x: marginX + 65.0, y: cursorY + 3.5, width: 170.0, height: 14.0)
        let pStyle = NSMutableParagraphStyle()
        pStyle.lineBreakMode = .byTruncatingTail
        let descAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 7.5, weight: .regular),
            .foregroundColor: colorPrimary,
            .paragraphStyle: pStyle
        ]
        desc.draw(in: descRect, withAttributes: descAttrs)

        // Category
        let catName = tx.category?.name ?? "Uncategorized"
        let catRect = CGRect(x: marginX + 240.0, y: cursorY + 3.5, width: 100.0, height: 14.0)
        catName.draw(in: catRect, withAttributes: descAttrs)

        // Payment Method
        tx.paymentMethod.displayName.draw(at: CGPoint(x: marginX + 345.0, y: cursorY + 3.5), withAttributes: secAttrs)

        // Type
        let typeStr: String
        let typeColor: UIColor
        if tx.isInternalTransfer {
            typeStr = "Transfer"
            typeColor = colorTransfer
        } else {
            switch tx.type {
            case .income:
                typeStr = "Income"
                typeColor = colorIncome
            case .expense:
                typeStr = "Expense"
                typeColor = colorExpense
            }
        }
        let typeAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 7.5, weight: .medium),
            .foregroundColor: typeColor
        ]
        typeStr.draw(at: CGPoint(x: marginX + 400.0, y: cursorY + 3.5), withAttributes: typeAttrs)

        // Amount (Right Aligned)
        let prefix = (tx.type == .income && !tx.isInternalTransfer) ? "+" : ((tx.type == .expense && !tx.isInternalTransfer) ? "-" : "")
        let amtFormatted = "\(prefix)\(tx.amount.formatted(with: currency))"
        let isForeign = !tx.isPrimaryCurrency(primaryCode: currency.code)

        let amtAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 7.5, weight: .bold),
            .foregroundColor: typeColor
        ]
        let amtSize = amtFormatted.size(withAttributes: amtAttrs)
        let amtY: CGFloat = isForeign ? (cursorY + 2.0) : (cursorY + 4.0)
        amtFormatted.draw(at: CGPoint(x: marginX + contentWidth - amtSize.width - 6.0, y: amtY), withAttributes: amtAttrs)

        if isForeign {
            let foreignStr = "\(tx.currencyCode) \(tx.originalAmount.formatted(currency: tx.originalCurrency))"
            let foreignAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 6.0, weight: .regular),
                .foregroundColor: colorSecondary
            ]
            let fSize = foreignStr.size(withAttributes: foreignAttrs)
            foreignStr.draw(at: CGPoint(x: marginX + contentWidth - fSize.width - 6.0, y: cursorY + 11.0), withAttributes: foreignAttrs)
        }
    }

    private func drawEmptyLedgerRow(at cursorY: CGFloat) {
        let attrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.italicSystemFont(ofSize: 8.5),
            .foregroundColor: colorMuted
        ]
        let msg = "No transactions recorded for this period."
        let size = msg.size(withAttributes: attrs)
        msg.draw(at: CGPoint(x: marginX + (contentWidth - size.width) / 2.0, y: cursorY + 4.0), withAttributes: attrs)
    }

    private func drawFooter(pageNumber: Int, totalPages: Int) {
        let footerY = pageHeight - marginBottom
        drawLine(from: CGPoint(x: marginX, y: footerY), to: CGPoint(x: marginX + contentWidth, y: footerY), color: colorBorder, width: 0.5)

        let footerAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 7.5, weight: .regular),
            .foregroundColor: colorMuted
        ]

        let leftText = "Generated by Leaf — Personal Finance Statement • Strictly Confidential"
        leftText.draw(at: CGPoint(x: marginX, y: footerY + 6.0), withAttributes: footerAttrs)

        let pageStr = "Page \(pageNumber) of \(totalPages)"
        let pSize = pageStr.size(withAttributes: footerAttrs)
        pageStr.draw(at: CGPoint(x: marginX + contentWidth - pSize.width, y: footerY + 6.0), withAttributes: footerAttrs)
    }

    // MARK: - CoreGraphics Drawing Helpers

    private func drawLine(from start: CGPoint, to end: CGPoint, color: UIColor, width: CGFloat) {
        guard let ctx = UIGraphicsGetCurrentContext() else { return }
        ctx.saveGState()
        ctx.setStrokeColor(color.cgColor)
        ctx.setLineWidth(width)
        ctx.move(to: start)
        ctx.addLine(to: end)
        ctx.strokePath()
        ctx.restoreGState()
    }
}
