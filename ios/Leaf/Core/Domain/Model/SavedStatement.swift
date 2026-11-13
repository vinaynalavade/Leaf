import Foundation

/// Persistent statement record representing an exported PDF or CSV report saved to disk.
public struct SavedStatement: Identifiable, Hashable, Sendable {
    public let id: Int64
    public let title: String
    public let periodType: String
    public let startDate: Int64
    public let endDate: Int64
    public let format: StatementFormat
    public let filePath: String
    public let fileSize: Int64
    public let totalIncome: Amount
    public let totalExpense: Amount
    public let operatingCashFlow: Amount
    public let transactionCount: Int
    public let generatedAt: Int64

    public init(
        id: Int64 = 0,
        title: String,
        periodType: String,
        startDate: Int64,
        endDate: Int64,
        format: StatementFormat,
        filePath: String,
        fileSize: Int64,
        totalIncome: Amount,
        totalExpense: Amount,
        operatingCashFlow: Amount,
        transactionCount: Int,
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
        self.totalIncome = totalIncome
        self.totalExpense = totalExpense
        self.operatingCashFlow = operatingCashFlow
        self.transactionCount = transactionCount
        self.generatedAt = generatedAt
    }

    /// Local file URL for previewing, sharing, or exporting.
    public var fileURL: URL {
        URL(fileURLWithPath: filePath)
    }

    /// Checks if the physical file exists at `filePath`.
    public var fileExists: Bool {
        FileManager.default.fileExists(atPath: filePath)
    }

    public var formattedGeneratedDate: String {
        let date = Date(timeIntervalSince1970: Double(generatedAt) / 1000.0)
        let formatter = DateFormatter()
        formatter.dateFormat = "dd MMM yyyy, h:mm a"
        return formatter.string(from: date)
    }

    public var formattedPeriod: String {
        let start = Date(timeIntervalSince1970: Double(startDate) / 1000.0)
        let end = Date(timeIntervalSince1970: Double(endDate) / 1000.0)
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return "\(formatter.string(from: start)) – \(formatter.string(from: end))"
    }

    public var formattedFileSize: String {
        if fileSize >= 1_048_576 {
            return String(format: "%.1f MB", Double(fileSize) / 1_048_576.0)
        } else if fileSize >= 1024 {
            return String(format: "%.0f KB", Double(fileSize) / 1024.0)
        } else {
            return "\(fileSize) B"
        }
    }
}

