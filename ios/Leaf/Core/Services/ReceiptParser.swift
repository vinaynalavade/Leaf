import Foundation

/// Robust financial receipt parsing engine.
/// Extracts merchant, total amount, transaction date, tax, subtotal, and currency
/// from raw OCR lines using domain-specific rules, heuristics, and confidence evaluation.
public final class ReceiptParser: Sendable {

    public static let shared = ReceiptParser()

    public init() {}

    // MARK: - Primary Parse Method

    public func parseReceipt(
        lines: [RecognizedReceiptLine],
        fallbackCurrency: Currency = .default,
        categories: [Category] = []
    ) -> ReceiptOCRResult {
        let rawTexts = lines.map(\.text)
        let fullText = rawTexts.joined(separator: "\n")

        // 1. Currency Extraction
        let currencyResult = extractCurrency(lines: lines, fallbackCurrency: fallbackCurrency)
        let activeCurrency = currencyResult.value ?? fallbackCurrency

        // 2. Merchant Extraction
        let merchantResult = extractMerchant(lines: lines)

        // 3. Total Amount Extraction
        let totalAmountResult = extractTotalAmount(lines: lines, currency: activeCurrency)

        // 4. Subtotal Extraction
        let subtotalResult = extractSubtotal(lines: lines, currency: activeCurrency)

        // 5. Tax Amount Extraction
        let taxResult = extractTaxAmount(lines: lines, currency: activeCurrency)

        // 6. Date Extraction
        let dateResult = extractDate(lines: lines)

        // 7. Category Suggestion
        let categoryResult = suggestCategory(
            merchant: merchantResult.value,
            fullText: fullText,
            categories: categories
        )

        // 8. Overall Confidence
        var overallConfidence: ReceiptConfidence = .high
        if totalAmountResult.confidence == .low || merchantResult.confidence == .low {
            overallConfidence = .low
        } else if totalAmountResult.confidence == .medium || merchantResult.confidence == .medium || dateResult.confidence == .medium {
            overallConfidence = .medium
        }

        return ReceiptOCRResult(
            rawLines: rawTexts,
            fullText: fullText,
            merchant: merchantResult,
            totalAmount: totalAmountResult,
            date: dateResult,
            taxAmount: taxResult,
            subtotal: subtotalResult,
            currency: currencyResult,
            suggestedCategoryId: categoryResult.field,
            suggestedCategoryName: categoryResult.name,
            overallConfidence: overallConfidence,
            isBlurry: false,
            tempImageURL: nil
        )
    }

    // MARK: - 1. Merchant Extraction

    private func extractMerchant(lines: [RecognizedReceiptLine]) -> ReceiptExtractedField<String> {
        // Disallowed keywords in receipt headers
        let disallowedKeywords = [
            "tax invoice", "retail invoice", "cash receipt", "invoice", "receipt",
            "bill of supply", "customer copy", "duplicate", "original", "welcome",
            "gstin", "gst no", "vat no", "tin", "ein", "cin", "reg no", "tax id",
            "phone", "tel:", "mob:", "ph:", "fax:", "+91", "www.", ".com", ".in", "@",
            "street", "road", "ave", "avenue", "floor", "lane", "block", "pincode", "pin:", "zip:",
            "cashier", "order #", "table #", "pos", "terminal"
        ]

        // Inspect the first 7 lines
        let candidateLines = lines.prefix(7)

        for line in candidateLines {
            let cleaned = line.text.trimmingCharacters(in: .whitespacesAndNewlines)
            let lower = cleaned.lowercased()

            // Skip lines that are too short or too long
            guard cleaned.count >= 3 && cleaned.count <= 60 else { continue }

            // Skip lines with disallowed words
            if disallowedKeywords.contains(where: { lower.contains($0) }) {
                continue }

            // Skip lines that are primarily digits or phone numbers
            let digitsCount = cleaned.filter(\.isNumber).count
            let lettersCount = cleaned.filter(\.isLetter).count
            guard lettersCount >= 3 && Double(digitsCount) / Double(cleaned.count) < 0.35 else {
                continue
            }

            // Skip date/time lines
            if isDateLine(cleaned) {
                continue
            }

            // High confidence if high OCR confidence, otherwise medium
            let conf: ReceiptConfidence = line.confidence >= 0.80 ? .high : .medium
            return ReceiptExtractedField(
                value: cleaned,
                confidence: conf,
                rawText: cleaned,
                sourceLabel: "Header"
            )
        }

        // Fallback: Use first line if it contains any letters
        if let first = lines.first {
            let cleaned = first.text.trimmingCharacters(in: .whitespacesAndNewlines)
            if cleaned.filter(\.isLetter).count >= 2 {
                return ReceiptExtractedField(
                    value: cleaned,
                    confidence: .low,
                    rawText: cleaned,
                    sourceLabel: "Fallback Header"
                )
            }
        }

        return ReceiptExtractedField(value: nil, confidence: .low)
    }

    // MARK: - 2. Total Amount Extraction

    private func extractTotalAmount(lines: [RecognizedReceiptLine], currency: Currency) -> ReceiptExtractedField<Amount> {
        let strongTotalLabels = [
            "grand total", "net payable", "amount paid", "total payable",
            "amount due", "final total", "balance due", "bal due", "net amount due"
        ]
        let standardTotalLabels = [
            "total amount", "total due", "total"
        ]
        let exclusionLabels = [
            "subtotal", "sub total", "sub-total", "tax", "gst", "cgst", "sgst", "vat",
            "discount", "disc", "savings", "cash", "change", "tendered", "round off"
        ]

        var bestCandidate: (amount: Amount, conf: ReceiptConfidence, raw: String, label: String, score: Int)? = nil

        for (index, line) in lines.enumerated() {
            let lineText = line.text.lowercased()

            // Check if line contains exclusion words without total
            let isExcluded = exclusionLabels.contains(where: { lineText.contains($0) })
            let isStrong = strongTotalLabels.contains(where: { lineText.contains($0) })
            let isStandard = standardTotalLabels.contains(where: { lineText.contains($0) })

            // Determine label match
            var labelScore = 0
            var matchedLabel = ""

            if isStrong {
                labelScore = 100
                matchedLabel = strongTotalLabels.first(where: { lineText.contains($0) }) ?? "Total"
            } else if isStandard && !isExcluded {
                labelScore = 70
                matchedLabel = standardTotalLabels.first(where: { lineText.contains($0) }) ?? "Total"
            } else if lineText.contains("total") && isExcluded {
                // E.g. "SUBTOTAL" -> ignore for final total
                continue
            }

            guard labelScore > 0 else { continue }

            // 1. Look for amount in the SAME line
            if let parsed = parseFirstMonetaryAmount(from: line.text, currency: currency) {
                let conf: ReceiptConfidence = (line.confidence >= 0.75 && labelScore >= 70) ? .high : .medium
                if labelScore > (bestCandidate?.score ?? 0) {
                    bestCandidate = (parsed.amount, conf, parsed.raw, matchedLabel, labelScore)
                }
                continue
            }

            // 2. Look for amount in the NEXT line (common in multi-column or wrapped receipts)
            if index + 1 < lines.count {
                let nextLine = lines[index + 1]
                if let parsed = parseFirstMonetaryAmount(from: nextLine.text, currency: currency) {
                    let conf: ReceiptConfidence = .medium
                    let score = labelScore - 10
                    if score > (bestCandidate?.score ?? 0) {
                        bestCandidate = (parsed.amount, conf, parsed.raw, matchedLabel, score)
                    }
                }
            }
        }

        if let best = bestCandidate {
            return ReceiptExtractedField(
                value: best.amount,
                confidence: best.conf,
                rawText: best.raw,
                sourceLabel: best.label
            )
        }

        // Fallback: Scan lower 40% of receipt lines for lone monetary amount
        let lowerLines = lines.suffix(max(1, lines.count / 2))
        var candidateAmounts: [(Amount, String, Float)] = []
        for line in lowerLines {
            let lower = line.text.lowercased()
            if exclusionLabels.contains(where: { lower.contains($0) }) { continue }
            if let parsed = parseFirstMonetaryAmount(from: line.text, currency: currency) {
                candidateAmounts.append((parsed.amount, parsed.raw, line.confidence))
            }
        }

        if let largest = candidateAmounts.max(by: { $0.0.subunits < $1.0.subunits }), largest.0.subunits > 0 {
            return ReceiptExtractedField(
                value: largest.0,
                confidence: .low,
                rawText: largest.1,
                sourceLabel: "Estimated Total"
            )
        }

        return ReceiptExtractedField(value: nil, confidence: .low)
    }

    // MARK: - 3. Subtotal Extraction

    private func extractSubtotal(lines: [RecognizedReceiptLine], currency: Currency) -> ReceiptExtractedField<Amount> {
        let subtotalLabels = ["subtotal", "sub total", "sub-total", "net amount", "taxable amount"]

        for (index, line) in lines.enumerated() {
            let lower = line.text.lowercased()
            guard subtotalLabels.contains(where: { lower.contains($0) }) else { continue }

            if let parsed = parseFirstMonetaryAmount(from: line.text, currency: currency) {
                let conf: ReceiptConfidence = line.confidence >= 0.75 ? .high : .medium
                return ReceiptExtractedField(
                    value: parsed.amount,
                    confidence: conf,
                    rawText: parsed.raw,
                    sourceLabel: "Subtotal"
                )
            }

            if index + 1 < lines.count {
                let nextLine = lines[index + 1]
                if let parsed = parseFirstMonetaryAmount(from: nextLine.text, currency: currency) {
                    return ReceiptExtractedField(
                        value: parsed.amount,
                        confidence: .medium,
                        rawText: parsed.raw,
                        sourceLabel: "Subtotal"
                    )
                }
            }
        }

        return ReceiptExtractedField(value: nil, confidence: .low)
    }

    // MARK: - 4. Tax Amount Extraction

    private func extractTaxAmount(lines: [RecognizedReceiptLine], currency: Currency) -> ReceiptExtractedField<Amount> {
        let taxLabels = ["tax", "gst", "cgst", "sgst", "igst", "vat", "sales tax"]

        var accumulatedSubunits: Int64 = 0
        var foundTax = false
        var taxConfidence: ReceiptConfidence = .high

        for line in lines {
            let lower = line.text.lowercased()
            // Ignore tax registration/header lines
            if lower.contains("gstin") || lower.contains("tax id") || lower.contains("vat no") {
                continue
            }

            guard taxLabels.contains(where: { lower.contains($0) }) else { continue }

            if let parsed = parseFirstMonetaryAmount(from: line.text, currency: currency) {
                accumulatedSubunits += parsed.amount.subunits
                foundTax = true
                if line.confidence < 0.75 { taxConfidence = .medium }
            }
        }

        if foundTax && accumulatedSubunits > 0 {
            return ReceiptExtractedField(
                value: Amount(subunits: accumulatedSubunits),
                confidence: taxConfidence,
                sourceLabel: "Tax"
            )
        }

        return ReceiptExtractedField(value: nil, confidence: .low)
    }

    // MARK: - 5. Date Extraction

    private func extractDate(lines: [RecognizedReceiptLine]) -> ReceiptExtractedField<Date> {
        let calendar = Calendar.current
        let now = Date()

        for line in lines {
            let text = line.text.trimmingCharacters(in: .whitespacesAndNewlines)
            if let parsedDate = parseDateString(from: text) {
                // Validation: Discard dates in future (> 1 day ahead) or older than year 2000
                let components = calendar.dateComponents([.year], from: parsedDate)
                if let year = components.year, year >= 2000, parsedDate <= now.addingTimeInterval(86400) {
                    let conf: ReceiptConfidence = line.confidence >= 0.80 ? .high : .medium
                    return ReceiptExtractedField(
                        value: parsedDate,
                        confidence: conf,
                        rawText: text,
                        sourceLabel: "Receipt Date"
                    )
                }
            }
        }

        // Default to today with low confidence
        return ReceiptExtractedField(
            value: Date(),
            confidence: .low,
            isAssumed: true,
            sourceLabel: "Today (Default)"
        )
    }

    // MARK: - 6. Currency Extraction

    private func extractCurrency(lines: [RecognizedReceiptLine], fallbackCurrency: Currency) -> ReceiptExtractedField<Currency> {
        let allText = lines.map(\.text).joined(separator: " ")

        if allText.contains("₹") || allText.contains("Rs") || allText.contains("INR") {
            return ReceiptExtractedField(value: Currency.fromCode("INR"), confidence: .high, rawText: "INR")
        } else if allText.contains("€") || allText.contains("EUR") {
            return ReceiptExtractedField(value: Currency.fromCode("EUR"), confidence: .high, rawText: "EUR")
        } else if allText.contains("£") || allText.contains("GBP") {
            return ReceiptExtractedField(value: Currency.fromCode("GBP"), confidence: .high, rawText: "GBP")
        } else if allText.contains("$") {
            // $ could be USD, CAD, AUD - use fallback if it's a dollar currency, otherwise USD
            let matched = fallbackCurrency.symbol == "$" ? fallbackCurrency : Currency.fromCode("USD")
            return ReceiptExtractedField(value: matched, confidence: .high, rawText: "$")
        }

        return ReceiptExtractedField(
            value: fallbackCurrency,
            confidence: .medium,
            isAssumed: true,
            sourceLabel: "App Setting"
        )
    }

    // MARK: - 7. Category Suggestion

    private func suggestCategory(
        merchant: String?,
        fullText: String,
        categories: [Category]
    ) -> (field: ReceiptExtractedField<Int64>, name: String?) {
        let combined = "\(merchant ?? "") \(fullText)".lowercased()

        let categoryRules: [(keywords: [String], targetNames: [String])] = [
            (
                ["restaurant", "cafe", "coffee", "bakery", "pizza", "burger", "diner", "bar", "grill", "bistro", "kitchen", "mcdonald", "starbucks", "subway", "dominos", "kfc", "swiggy", "zomato", "food", "dining", "eats", "brewery", "dhaba"],
                ["Food & Dining", "Food", "Dining", "Meals"]
            ),
            (
                ["supermarket", "grocery", "market", "mart", "provisions", "fruits", "vegetables", "walmart", "target", "trader joe", "whole foods", "costco", "bigbasket", "blinkit", "zepto", "dmart", "safeway", "spencer", "spices"],
                ["Groceries", "Grocery", "Supplies"]
            ),
            (
                ["fuel", "petrol", "diesel", "gas", "shell", "bp", "chevron", "exxon", "uber", "lyft", "taxi", "cab", "transit", "metro", "train", "parking", "toll", "ola", "indian oil", "hpcl", "bpcl"],
                ["Transportation", "Transport", "Travel", "Fuel"]
            ),
            (
                ["apparel", "clothing", "fashion", "shoes", "retail", "boutique", "electronics", "apple", "amazon", "zara", "h&m", "bookstore", "mall", "store", "uniqlo", "nike", "adidas", "wear"],
                ["Shopping", "Personal", "Clothing"]
            ),
            (
                ["pharmacy", "chemist", "drugstore", "clinic", "hospital", "doctor", "dental", "medicine", "apollo", "cvs", "walgreens", "medplus", "gym", "fitness", "healthcare"],
                ["Health", "Medical", "Healthcare", "Fitness"]
            ),
            (
                ["cinema", "movie", "theatre", "ticket", "concert", "amusement", "bowling", "games", "imax", "pvr", "inox"],
                ["Entertainment", "Recreation", "Fun"]
            ),
            (
                ["electric", "water", "utility", "telecom", "broadband", "internet", "mobile", "airtel", "jio", "vodafone", "at&t", "verizon", "wifi"],
                ["Bills & Utilities", "Utilities", "Bills"]
            )
        ]

        for rule in categoryRules {
            if rule.keywords.contains(where: { combined.contains($0) }) {
                // Find matching category in the user's category list
                for targetName in rule.targetNames {
                    if let matched = categories.first(where: { $0.type == .expense && $0.name.localizedCaseInsensitiveContains(targetName) }) {
                        return (
                            ReceiptExtractedField(
                                value: matched.id,
                                confidence: .medium,
                                rawText: matched.name,
                                sourceLabel: "Suggested"
                            ),
                            matched.name
                        )
                    }
                }
            }
        }

        // Default fallback to first expense category if available
        if let firstExpenseCat = categories.first(where: { $0.type == .expense }) {
            return (
                ReceiptExtractedField(
                    value: firstExpenseCat.id,
                    confidence: .low,
                    isAssumed: true,
                    sourceLabel: "Default"
                ),
                firstExpenseCat.name
            )
        }

        return (ReceiptExtractedField(value: 1, confidence: .low, isAssumed: true), nil)
    }

    // MARK: - Helper Methods

    private func parseFirstMonetaryAmount(from line: String, currency: Currency) -> (amount: Amount, raw: String)? {
        // Regex matches currency numbers like: 1,234.50, 1234.50, 45.00, 1234,50, 45
        // Avoid matches with phone numbers (10 digits) or years (19xx, 20xx)
        let pattern = #"(?:[\$€£₹]|Rs\.?|INR)?\s*([0-9]{1,3}(?:[, ][0-9]{3})*(?:\.[0-9]{1,2})|[0-9]+(?:\.[0-9]{1,2})|[0-9]+(?:,[0-9]{2}))\b"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else {
            return nil
        }

        let nsString = line as NSString
        let matches = regex.matches(in: line, options: [], range: NSRange(location: 0, length: nsString.length))

        for match in matches {
            guard match.numberOfRanges > 1 else { continue }
            let matchRange = match.range(at: 1)
            var numString = nsString.substring(with: matchRange)

            // Normalize comma decimal separator if present: 12,50 -> 12.50
            if numString.contains(",") && !numString.contains(".") {
                let parts = numString.split(separator: ",")
                if parts.count == 2 && parts[1].count <= 2 {
                    numString = "\(parts[0]).\(parts[1])"
                } else {
                    numString = numString.replacingOccurrences(of: ",", with: "")
                }
            } else {
                numString = numString.replacingOccurrences(of: ",", with: "").replacingOccurrences(of: " ", with: "")
            }

            // Exclude single years (2020-2030) without decimal
            if !numString.contains(".") {
                if let intVal = Int(numString), intVal >= 2020 && intVal <= 2035 {
                    continue
                }
            }

            if let amt = Amount.fromStringOrNull(numString, currency: currency), amt.subunits > 0 {
                return (amt, numString)
            }
        }

        return nil
    }

    private func parseDateString(from text: String) -> Date? {
        let datePatterns = [
            // YYYY-MM-DD or YYYY/MM/DD
            #"(\d{4}[-/.]\d{1,2}[-/.]\d{1,2})"#,
            // DD/MM/YYYY or DD-MM-YYYY or DD.MM.YYYY
            #"(\d{1,2}[-/.]\d{1,2}[-/.]\d{2,4})"#,
            // 12 Nov 2026 or 12 November 2026 or Nov 12, 2026
            #"(\d{1,2}\s+[A-Za-z]{3,9}\s+\d{2,4})"#,
            #"([A-Za-z]{3,9}\s+\d{1,2},?\s+\d{2,4})"#
        ]

        let formats = [
            "yyyy-MM-dd", "yyyy/MM/dd", "yyyy.MM.dd",
            "dd-MM-yyyy", "dd/MM/yyyy", "dd.MM.yyyy",
            "MM/dd/yyyy", "MM-dd-yyyy",
            "dd-MM-yy", "dd/MM/yy", "MM/dd/yy",
            "dd MMM yyyy", "dd MMMM yyyy",
            "MMM dd, yyyy", "MMMM dd, yyyy",
            "dd-MMM-yyyy", "dd-MMM-yy"
        ]

        let nsString = text as NSString

        for pattern in datePatterns {
            guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else { continue }
            let matches = regex.matches(in: text, options: [], range: NSRange(location: 0, length: nsString.length))

            for match in matches {
                let matchedStr = nsString.substring(with: match.range(at: 1))
                let df = DateFormatter()
                df.locale = Locale(identifier: "en_US_POSIX")

                for fmt in formats {
                    df.dateFormat = fmt
                    if let d = df.date(from: matchedStr) {
                        return d
                    }
                }
            }
        }

        return nil
    }

    private func isDateLine(_ line: String) -> Bool {
        return parseDateString(from: line) != nil
    }
}

