import Foundation
import SwiftUI

/// Coordinator ViewModel for the Statements & Export module.
/// Manages loading statement history, compiling and saving PDF/CSV statements,
/// triggering native share flows, previewing PDFs, and handling deletions.
@Observable
public final class StatementsViewModel {

    // Dependencies
    private let getStatementsUseCase: GetStatementsUseCase
    private let generateStatementUseCase: GenerateStatementUseCase
    private let deleteStatementUseCase: DeleteStatementUseCase

    // State
    public var statements: [SavedStatement] = []
    public var isLoading: Bool = false
    public var isGenerating: Bool = false
    public var errorMessage: String? = nil

    // Sheet Presentations
    public var isGenerateSheetPresented: Bool = false
    public var previewStatement: SavedStatement? = nil
    public var statementToShare: SavedStatement? = nil
    public var statementToDelete: SavedStatement? = nil
    public var isDeleteConfirmationPresented: Bool = false
    public var exportItem: ExportItem? = nil

    // Form inputs for generation sheet
    public var selectedPeriod: StatementPeriod = .thisMonth
    public var selectedFormat: StatementFormat = .pdf
    public var customStartDate: Date = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()
    public var customEndDate: Date = Date()
    public var customTitle: String = ""

    public init(
        getStatementsUseCase: GetStatementsUseCase,
        generateStatementUseCase: GenerateStatementUseCase,
        deleteStatementUseCase: DeleteStatementUseCase
    ) {
        self.getStatementsUseCase = getStatementsUseCase
        self.generateStatementUseCase = generateStatementUseCase
        self.deleteStatementUseCase = deleteStatementUseCase
    }

    // MARK: - Actions

    @MainActor
    public func loadStatements() async {
        isLoading = true
        errorMessage = nil
        do {
            let loaded = try await getStatementsUseCase.execute()
            self.statements = loaded
        } catch {
            self.errorMessage = "Failed to load statements: \(error.localizedDescription)"
        }
        isLoading = false
    }

    @MainActor
    public func generateStatement(
        period: StatementPeriod,
        format: StatementFormat,
        customStartDate: Date? = nil,
        customEndDate: Date? = nil,
        customTitle: String? = nil
    ) async -> SavedStatement? {
        isGenerating = true
        errorMessage = nil

        let titleToUse = (customTitle?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false) ? customTitle : nil

        do {
            let newStatement = try await generateStatementUseCase.execute(
                period: period,
                format: format,
                customStartDate: customStartDate,
                customEndDate: customEndDate,
                customTitle: titleToUse
            )
            // Prepend new statement to the local list
            self.statements.insert(newStatement, at: 0)
            self.isGenerating = false
            self.isGenerateSheetPresented = false

            // Auto-open preview if it's a PDF
            if format == .pdf {
                self.previewStatement = newStatement
            }

            return newStatement
        } catch {
            self.errorMessage = "Failed to generate statement: \(error.localizedDescription)"
            self.isGenerating = false
            return nil
        }
    }

    @MainActor
    public func generateFromSheet() async {
        _ = await generateStatement(
            period: selectedPeriod,
            format: selectedFormat,
            customStartDate: { if case .custom(let s, _) = selectedPeriod { return s } else { return nil } }(),
            customEndDate: { if case .custom(_, let e) = selectedPeriod { return e } else { return nil } }(),
            customTitle: customTitle.isEmpty ? nil : customTitle
        )
    }

    @MainActor
    public func quickGenerate(period: StatementPeriod, format: StatementFormat) async {
        _ = await generateStatement(
            period: period,
            format: format,
            customStartDate: nil,
            customEndDate: nil,
            customTitle: nil
        )
    }

    @MainActor
    public func exportToFiles(_ statement: SavedStatement) {
        self.exportItem = ExportItem(url: statement.fileURL, title: statement.title)
    }

    @MainActor
    public func regenerateStatement(_ statement: SavedStatement) async {
        let period: StatementPeriod
        switch statement.periodType {
        case "thisMonth": period = .thisMonth
        case "lastMonth": period = .lastMonth
        case "previous3Months": period = .previous3Months
        case "previous6Months": period = .previous6Months
        case "thisYear": period = .thisYear
        case "previousYear": period = .previousYear
        case "allTime": period = .allTime
        default:
            let start = Date(timeIntervalSince1970: Double(statement.startDate) / 1000.0)
            let end = Date(timeIntervalSince1970: Double(statement.endDate) / 1000.0)
            period = .custom(startDate: start, endDate: end)
        }

        var customStart: Date? = nil
        var customEnd: Date? = nil
        if case .custom(let s, let e) = period {
            customStart = s
            customEnd = e
        }

        _ = await generateStatement(
            period: period,
            format: statement.format,
            customStartDate: customStart,
            customEndDate: customEnd,
            customTitle: statement.title
        )
    }

    @MainActor
    public func confirmDelete(_ statement: SavedStatement) {
        self.statementToDelete = statement
        self.isDeleteConfirmationPresented = true
    }

    @MainActor
    public func deleteConfirmed() async {
        guard let statement = statementToDelete else { return }
        do {
            try await deleteStatementUseCase.execute(id: statement.id)
            self.statements.removeAll { $0.id == statement.id }
            self.statementToDelete = nil
        } catch {
            self.errorMessage = "Failed to delete statement: \(error.localizedDescription)"
        }
    }
}

