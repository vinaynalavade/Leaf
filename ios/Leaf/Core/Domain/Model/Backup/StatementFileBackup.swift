import Foundation

/// Encapsulates the binary contents and filename of an exported statement PDF or CSV inside the encrypted backup.
public struct StatementFileBackup: Codable, Sendable {
    public let filename: String
    public let statementId: Int64
    public let fileDataBase64: String

    public init(filename: String, statementId: Int64, fileData: Data) {
        self.filename = filename
        self.statementId = statementId
        self.fileDataBase64 = fileData.base64EncodedString()
    }

    public var fileData: Data? {
        Data(base64Encoded: fileDataBase64)
    }
}

