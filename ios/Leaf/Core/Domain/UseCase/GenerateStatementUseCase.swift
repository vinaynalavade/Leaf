import Foundation

/// Orchestrates the generation of financial statements in PDF or CSV formats.
/// Compiles the analytical financial dataset, renders the file using the appropriate generator,
/// persists the file securely in the app's sandboxed Documents/Statements directory,
/// and stores the record in SQLite for history and re-export.
public final class GenerateStatementUseCase: Sendable {

    private let compileStatementDataUseCase: CompileStatementDataUseCase
    private let pdfGenerator: PdfStatementGenerator
    private let csvGenerator: CsvStatementGenerator
    private let statementRepository: StatementRepositoryProtocol

    public init(
        compileStatementDataUseCase: CompileStatementDataUseCase,
        pdfGenerator: PdfStatementGenerator = PdfStatementGenerator(),
        csvGenerator: CsvStatementGenerator = CsvStatementGenerator(),
        statementRepository: StatementRepositoryProtocol
    ) {
        self.compileStatementDataUseCase = compileStatementDataUseCase
        self.pdfGenerator = pdfGenerator
        self.csvGenerator = csvGenerator
        self.statementRepository = statementRepository
    }

    /// Compiles statement data, renders PDF or CSV, saves to disk, and records metadata in database.
    public func execute(
        period: StatementPeriod,
        format: StatementFormat,
        customStartDate: Date? = nil,
        customEndDate: Date? = nil,
        customTitle: String? = nil
    ) async throws -> SavedStatement {
        // 1. Compile statement dataset
        let data = try await compileStatementDataUseCase.execute(
            period: period,
            customTitle: customTitle
        )

        // 2. Generate file payload
        let fileData: Data
        switch format {
        case .pdf:
            fileData = pdfGenerator.generatePdf(data: data)
        case .csvTransactions:
            let csvStr = csvGenerator.generateTransactionsCsv(data: data)
            fileData = Data(csvStr.utf8)
        case .csvCategorySummary:
            let csvStr = csvGenerator.generateCategorySummaryCsv(data: data)
            fileData = Data(csvStr.utf8)
        case .csvFinancialSummary:
            let csvStr = csvGenerator.generateFinancialSummaryCsv(data: data)
            fileData = Data(csvStr.utf8)
        }

        // 3. Resolve destination directory in Application Documents
        let fileManager = FileManager.default
        let docsUrl: URL
        if let userDocs = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first {
            docsUrl = userDocs.appendingPathComponent("Statements", isDirectory: true)
        } else {
            docsUrl = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("Statements", isDirectory: true)
        }

        if !fileManager.fileExists(atPath: docsUrl.path) {
            try fileManager.createDirectory(at: docsUrl, withIntermediateDirectories: true)
        }
        try? fileManager.setAttributes([.protectionKey: FileProtectionType.complete], ofItemAtPath: docsUrl.path)

        // 4. Generate unique filename: Leaf_{Period}_{Format}_{Timestamp}.{ext}
        let timestamp = Int(Date().timeIntervalSince1970)
        let formatSuffix: String
        switch format {
        case .pdf: formatSuffix = "Statement"
        case .csvTransactions: formatSuffix = "Transactions"
        case .csvCategorySummary: formatSuffix = "Categories"
        case .csvFinancialSummary: formatSuffix = "Summary"
        }
        let fileName = "Leaf_\(period.filenamePrefix)_\(formatSuffix)_\(timestamp).\(format.fileExtension)"
        let fileUrl = docsUrl.appendingPathComponent(fileName)

        // 5. Write file atomically with complete hardware encryption
        try fileData.write(to: fileUrl, options: [.atomic, .completeFileProtection])

        let startMs = Int64(data.dateInterval.start.timeIntervalSince1970 * 1000)
        let endMs = Int64(data.dateInterval.end.timeIntervalSince1970 * 1000)
        let nowMs = Int64(Date().timeIntervalSince1970 * 1000)

        // 6. Record in Database
        let statementToInsert = SavedStatement(
            id: 0,
            title: data.title,
            periodType: period.id,
            startDate: startMs,
            endDate: endMs,
            format: format,
            filePath: fileUrl.path,
            fileSize: Int64(fileData.count),
            totalIncome: data.earnedIncome,
            totalExpense: data.ordinaryExpenses,
            operatingCashFlow: data.operatingCashFlow,
            transactionCount: data.transactionCount,
            generatedAt: nowMs
        )

        let insertedId = try await statementRepository.insertStatement(statementToInsert)

        return SavedStatement(
            id: insertedId,
            title: statementToInsert.title,
            periodType: statementToInsert.periodType,
            startDate: statementToInsert.startDate,
            endDate: statementToInsert.endDate,
            format: statementToInsert.format,
            filePath: statementToInsert.filePath,
            fileSize: statementToInsert.fileSize,
            totalIncome: statementToInsert.totalIncome,
            totalExpense: statementToInsert.totalExpense,
            operatingCashFlow: statementToInsert.operatingCashFlow,
            transactionCount: statementToInsert.transactionCount,
            generatedAt: statementToInsert.generatedAt
        )
    }
}

