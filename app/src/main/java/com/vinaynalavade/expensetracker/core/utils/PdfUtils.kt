package com.vinaynalavade.expensetracker.core.utils

import android.content.Context
import android.content.Intent
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.Typeface
import android.graphics.pdf.PdfDocument
import androidx.core.content.FileProvider
import com.vinaynalavade.expensetracker.core.constants.AppConstants
import com.vinaynalavade.expensetracker.domain.model.StatementReport
import com.vinaynalavade.expensetracker.domain.model.TransactionType
import java.io.File
import java.io.FileOutputStream
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

/**
 * On-device PDF generator for professional Leaf financial statements.
 * Features bank-grade right-aligned figures, robust multi-page rendering,
 * newest-first transaction ordering, and clean typography.
 */
object PdfUtils {

    fun generateStatementPdf(context: Context, report: StatementReport): File {
        val pdfDocument = PdfDocument()
        val pageWidth = 595 // A4 standard width at 72dpi
        val pageHeight = 842 // A4 standard height at 72dpi

        val paint = Paint(Paint.ANTI_ALIAS_FLAG)
        val textPaint = Paint(Paint.ANTI_ALIAS_FLAG)

        val sansSerif = Typeface.create("sans-serif", Typeface.NORMAL)
        val sansSerifMedium = Typeface.create("sans-serif-medium", Typeface.NORMAL)
        val sansSerifBold = Typeface.create("sans-serif", Typeface.BOLD)

        var pageNumber = 1
        var pageInfo = PdfDocument.PageInfo.Builder(pageWidth, pageHeight, pageNumber).create()
        var page = pdfDocument.startPage(pageInfo)
        var canvas = page.canvas

        val margin = 36f
        var currentY = margin + 20f

        // Column X coordinates and right-alignment boundaries
        val dateX = margin + 6f
        val descX = margin + 74f
        val catX = margin + 225f

        val inRight = margin + 375f
        val outRight = margin + 445f
        val balRight = pageWidth - margin - 8f

        fun drawTableHeader(c: Canvas, y: Float) {
            paint.color = Color.rgb(241, 245, 249)
            paint.style = Paint.Style.FILL
            c.drawRoundRect(margin, y, pageWidth - margin, y + 22f, 4f, 4f, paint)

            textPaint.textSize = 8.5f
            textPaint.typeface = sansSerifBold
            textPaint.color = Color.rgb(71, 85, 105)

            // Left-aligned text columns
            textPaint.textAlign = Paint.Align.LEFT
            c.drawText("DATE", dateX, y + 14.5f, textPaint)
            c.drawText("DESCRIPTION", descX, y + 14.5f, textPaint)
            c.drawText("CATEGORY", catX, y + 14.5f, textPaint)

            // Right-aligned numerical columns
            textPaint.textAlign = Paint.Align.RIGHT
            c.drawText("INCOME", inRight, y + 14.5f, textPaint)
            c.drawText("EXPENSE", outRight, y + 14.5f, textPaint)
            c.drawText("BALANCE", balRight, y + 14.5f, textPaint)

            textPaint.textAlign = Paint.Align.LEFT
        }

        // 1. Draw Document Header
        textPaint.typeface = sansSerifBold
        textPaint.textSize = 22f
        textPaint.color = Color.rgb(6, 78, 59) // Emerald Dark
        canvas.drawText("LEAF", margin, currentY, textPaint)

        textPaint.textSize = 9.5f
        textPaint.typeface = sansSerif
        textPaint.color = Color.rgb(100, 116, 139)
        canvas.drawText(AppConstants.CREATOR_BRANDING, margin, currentY + 14f, textPaint)

        textPaint.textSize = 14f
        textPaint.typeface = sansSerifBold
        textPaint.color = Color.rgb(15, 23, 42)
        textPaint.textAlign = Paint.Align.RIGHT
        canvas.drawText("Financial Statement", pageWidth - margin, currentY, textPaint)

        textPaint.textSize = 9f
        textPaint.typeface = sansSerif
        textPaint.color = Color.rgb(100, 116, 139)
        val dateText = "Generated: ${SimpleDateFormat("dd MMM yyyy, hh:mm a", Locale.getDefault()).format(Date())}"
        canvas.drawText(dateText, pageWidth - margin, currentY + 14f, textPaint)

        textPaint.textAlign = Paint.Align.LEFT
        currentY += 34f

        // Divider
        paint.color = Color.rgb(226, 232, 240)
        paint.strokeWidth = 1.25f
        canvas.drawLine(margin, currentY, pageWidth - margin, currentY, paint)

        currentY += 18f

        // 2. Period & Currency Context
        textPaint.textSize = 10.5f
        textPaint.typeface = sansSerifBold
        textPaint.color = Color.rgb(79, 70, 229)
        canvas.drawText("Statement Period: ${report.periodTitle}", margin, currentY, textPaint)

        textPaint.textAlign = Paint.Align.RIGHT
        val currText = "Base Currency: ${report.currency.name} (${report.currency.symbol})"
        canvas.drawText(currText, pageWidth - margin, currentY, textPaint)
        textPaint.textAlign = Paint.Align.LEFT

        currentY += 18f

        // 3. Summary Box (4 metric tiles)
        paint.color = Color.rgb(248, 250, 252)
        paint.style = Paint.Style.FILL
        canvas.drawRoundRect(margin, currentY, pageWidth - margin, currentY + 52f, 8f, 8f, paint)

        paint.color = Color.rgb(226, 232, 240)
        paint.style = Paint.Style.STROKE
        paint.strokeWidth = 1f
        canvas.drawRoundRect(margin, currentY, pageWidth - margin, currentY + 52f, 8f, 8f, paint)

        val colWidth = (pageWidth - margin * 2) / 4
        val sumY = currentY + 17f

        fun drawSummaryCol(title: String, amountStr: String, colIdx: Int, color: Int) {
            val colX = margin + colIdx * colWidth + 12f
            textPaint.textSize = 8f
            textPaint.typeface = sansSerifMedium
            textPaint.color = Color.rgb(100, 116, 139)
            canvas.drawText(title.uppercase(), colX, sumY, textPaint)

            textPaint.textSize = 11f
            textPaint.typeface = sansSerifBold
            textPaint.color = color
            canvas.drawText(amountStr, colX, sumY + 18f, textPaint)
        }

        drawSummaryCol("Opening Balance", report.openingBalance.format(report.currency), 0, Color.rgb(15, 23, 42))
        drawSummaryCol("Total Income", "+ " + report.totalIncome.format(report.currency), 1, Color.rgb(16, 185, 129))
        drawSummaryCol("Total Expense", "- " + report.totalExpense.format(report.currency), 2, Color.rgb(239, 68, 68))
        drawSummaryCol("Closing Balance", report.closingBalance.format(report.currency), 3, Color.rgb(79, 70, 229))

        currentY += 70f

        // 4. Ledger Table Header
        drawTableHeader(canvas, currentY)
        currentY += 26f

        // 5. Table Rows (Newest first)
        val rowHeight = 22f
        val bottomThreshold = pageHeight - margin - 30f

        report.ledgerItems.forEachIndexed { index, item ->
            if (currentY + rowHeight > bottomThreshold) {
                // Draw Footer for current page
                drawPageFooter(canvas, pageNumber, margin, pageWidth, pageHeight, textPaint, sansSerif)
                pdfDocument.finishPage(page)

                pageNumber++
                pageInfo = PdfDocument.PageInfo.Builder(pageWidth, pageHeight, pageNumber).create()
                page = pdfDocument.startPage(pageInfo)
                canvas = page.canvas
                currentY = margin + 20f

                // Redraw repeated table header on new page
                drawTableHeader(canvas, currentY)
                currentY += 26f
            }

            // Alternating row background
            if (index % 2 == 1) {
                paint.color = Color.rgb(248, 250, 252)
                paint.style = Paint.Style.FILL
                canvas.drawRect(margin, currentY - 4f, pageWidth - margin, currentY + rowHeight - 6f, paint)
            }

            textPaint.typeface = sansSerif
            textPaint.textSize = 8.5f
            textPaint.color = Color.rgb(15, 23, 42)
            textPaint.textAlign = Paint.Align.LEFT

            canvas.drawText(item.dateString, dateX, currentY + 10f, textPaint)

            val cleanDesc = if (item.description.length > 26) item.description.take(23) + "..." else item.description
            canvas.drawText(cleanDesc, descX, currentY + 10f, textPaint)

            val cleanCat = if (item.categoryName.length > 18) item.categoryName.take(15) + "..." else item.categoryName
            canvas.drawText(cleanCat, catX, currentY + 10f, textPaint)

            // Right-aligned amounts
            textPaint.textAlign = Paint.Align.RIGHT

            // Income
            if (item.type == TransactionType.INCOME && item.amount != null) {
                textPaint.color = Color.rgb(16, 185, 129)
                canvas.drawText("+ " + item.amount.format(report.currency, includeSymbol = false), inRight, currentY + 10f, textPaint)
            } else {
                textPaint.color = Color.rgb(148, 163, 184)
                canvas.drawText("—", inRight, currentY + 10f, textPaint)
            }

            // Expense
            if (item.type == TransactionType.EXPENSE && item.amount != null) {
                textPaint.color = Color.rgb(239, 68, 68)
                canvas.drawText("- " + item.amount.format(report.currency, includeSymbol = false), outRight, currentY + 10f, textPaint)
            } else {
                textPaint.color = Color.rgb(148, 163, 184)
                canvas.drawText("—", outRight, currentY + 10f, textPaint)
            }

            // Running Balance
            textPaint.typeface = sansSerifBold
            textPaint.color = Color.rgb(15, 23, 42)
            canvas.drawText(item.runningBalance.format(report.currency), balRight, currentY + 10f, textPaint)

            textPaint.textAlign = Paint.Align.LEFT
            currentY += rowHeight
        }

        drawPageFooter(canvas, pageNumber, margin, pageWidth, pageHeight, textPaint, sansSerif)
        pdfDocument.finishPage(page)

        val statementsDir = File(context.cacheDir, "statements").apply { mkdirs() }
        val fileName = "Leaf_Statement_${System.currentTimeMillis()}.pdf"
        val outputFile = File(statementsDir, fileName)

        FileOutputStream(outputFile).use { out ->
            pdfDocument.writeTo(out)
        }
        pdfDocument.close()

        return outputFile
    }

    private fun drawPageFooter(
        canvas: Canvas,
        pageNumber: Int,
        margin: Float,
        pageWidth: Int,
        pageHeight: Int,
        textPaint: Paint,
        sansSerif: Typeface
    ) {
        val footerY = pageHeight - margin + 12f
        textPaint.textSize = 8f
        textPaint.typeface = sansSerif
        textPaint.color = Color.rgb(148, 163, 184)
        textPaint.textAlign = Paint.Align.LEFT

        canvas.drawText("Leaf • ${AppConstants.CREATOR_BRANDING}", margin, footerY, textPaint)

        textPaint.textAlign = Paint.Align.RIGHT
        canvas.drawText("Page $pageNumber", pageWidth - margin, footerY, textPaint)
        textPaint.textAlign = Paint.Align.LEFT
    }

    fun createShareIntent(context: Context, pdfFile: File): Intent {
        val uri = FileProvider.getUriForFile(
            context,
            "${context.packageName}.fileprovider",
            pdfFile
        )

        return Intent(Intent.ACTION_SEND).apply {
            type = "application/pdf"
            putExtra(Intent.EXTRA_STREAM, uri)
            putExtra(Intent.EXTRA_SUBJECT, "Leaf Financial Statement")
            putExtra(Intent.EXTRA_TEXT, "Here is my Leaf financial statement.")
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        }
    }
}
