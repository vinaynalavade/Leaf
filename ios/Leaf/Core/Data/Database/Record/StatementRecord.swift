import Foundation
import GRDB

public struct StatementRecord: Codable, FetchableRecord, MutablePersistableRecord, TableRecord, Sendable {
    public static let databaseTableName = "statements"

    public var id: Int64?
    public var title: String
    public var periodType: String
    public var startDate: Int64
    public var endDate: Int64
    public var format: String
    public var filePath: String
    public var fileSize: Int64
    public var totalIncomeSubunits: Int64
    public var totalExpenseSubunits: Int64
    public var operatingCashflowSubunits: Int64
    public var transactionCount: Int
    public var generatedAt: Int64

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case periodType = "period_type"
        case startDate = "start_date"
        case endDate = "end_date"
        case format
        case filePath = "file_path"
        case fileSize = "file_size"
        case totalIncomeSubunits = "total_income_subunits"
        case totalExpenseSubunits = "total_expense_subunits"
        case operatingCashflowSubunits = "operating_cashflow_subunits"
        case transactionCount = "transaction_count"
        case generatedAt = "generated_at"
    }

    public init(
        id: Int64? = nil,
        title: String,
        periodType: String,
        startDate: Int64,
        endDate: Int64,
        format: String,
        filePath: String,
        fileSize: Int64 = 0,
        totalIncomeSubunits: Int64 = 0,
        totalExpenseSubunits: Int64 = 0,
        operatingCashflowSubunits: Int64 = 0,
        transactionCount: Int = 0,
        generatedAt: Int64 = Int64(Date().timeIntervalSince1970 * 1000)
    ) {
        self.id = id
        self.title = title
        self.periodType = periodType
        self.startDate = startDate
        self.endDate = endDate
        self.format = format
        self.filePath = filePath
        self.fileSize = fileSize
        self.totalIncomeSubunits = totalIncomeSubunits
        self.totalExpenseSubunits = totalExpenseSubunits
        self.operatingCashflowSubunits = operatingCashflowSubunits
        self.transactionCount = transactionCount
        self.generatedAt = generatedAt
    }

    public init(from statement: SavedStatement) {
        self.init(
            id: statement.id > 0 ? statement.id : nil,
            title: statement.title,
            periodType: statement.periodType,
            startDate: statement.startDate,
            endDate: statement.endDate,
            format: statement.format.rawValue,
            filePath: statement.filePath,
            fileSize: statement.fileSize,
            totalIncomeSubunits: statement.totalIncome.subunits,
            totalExpenseSubunits: statement.totalExpense.subunits,
            operatingCashflowSubunits: statement.operatingCashFlow.subunits,
            transactionCount: statement.transactionCount,
            generatedAt: statement.generatedAt
        )
    }

    public func toDomain() -> SavedStatement {
        SavedStatement(
            id: id ?? 0,
            title: title,
            periodType: periodType,
            startDate: startDate,
            endDate: endDate,
            format: StatementFormat(rawValue: format) ?? .pdf,
            filePath: filePath,
            fileSize: fileSize,
            totalIncome: Amount(totalIncomeSubunits),
            totalExpense: Amount(totalExpenseSubunits),
            operatingCashFlow: Amount(operatingCashflowSubunits),
            transactionCount: transactionCount,
            generatedAt: generatedAt
        )
    }

    public mutating func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }
}

