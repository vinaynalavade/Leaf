import Foundation

/// Metadata representing an existing backup file in Google Drive's appDataFolder.
public struct GoogleBackupMetadata: Codable, Hashable, Sendable {
    public let fileId: String
    public let name: String
    public let modifiedTime: Int64
    public let sizeBytes: Int64

    public init(
        fileId: String,
        name: String = GoogleDriveRestService.backupFileName,
        modifiedTime: Int64,
        sizeBytes: Int64
    ) {
        self.fileId = fileId
        self.name = name
        self.modifiedTime = modifiedTime
        self.sizeBytes = sizeBytes
    }

    public var formattedDate: String {
        let date = Date(timeIntervalSince1970: Double(modifiedTime) / 1000.0)
        return DateFormatter.localizedString(from: date, dateStyle: .medium, timeStyle: .short)
    }

    public var formattedSize: String {
        let byteCountFormatter = ByteCountFormatter()
        byteCountFormatter.allowedUnits = [.useKB, .useMB]
        byteCountFormatter.countStyle = .file
        return byteCountFormatter.string(fromByteCount: sizeBytes)
    }
}

/// Lightweight, dependency-free Google Drive v3 REST API client communicating with appDataFolder.
/// Directly mirrors the Android reference implementation for zero friction cross-platform backup compatibility.
public final class GoogleDriveRestService: Sendable {
    public static let backupFileName = "leaf_backup.json"
    public static let legacyBackupFileName = "kharchaflow_backup.json"

    private static let baseApiUrl = "https://www.googleapis.com/drive/v3"
    private static let baseUploadUrl = "https://www.googleapis.com/upload/drive/v3"

    private let session: URLSession

    public init(session: URLSession = .shared) {
        self.session = session
    }

    /// Searches for the primary Leaf backup file inside the user's hidden appDataFolder.
    public func findBackupFile(accessToken: String) async throws -> GoogleBackupMetadata? {
        // If simulated token, return local mock or nil
        if accessToken.hasPrefix("ya29.leaf_drive_access_token_") {
            return getSimulatedBackupMetadata()
        }

        let query = "(\(escapeQuery(name: Self.backupFileName)) or \(escapeQuery(name: Self.legacyBackupFileName))) and trashed = false"
        guard let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "\(Self.baseApiUrl)/files?spaces=appDataFolder&q=\(encodedQuery)&fields=files(id,name,modifiedTime,size)") else {
            throw GoogleDriveError.invalidUrl
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 15

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw GoogleDriveError.networkError("Invalid server response")
        }

        if httpResponse.statusCode == 200 {
            guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let files = json["files"] as? [[String: Any]],
                  let first = files.first,
                  let fileId = first["id"] as? String else {
                return nil
            }

            let name = first["name"] as? String ?? Self.backupFileName
            let size = Int64(first["size"] as? String ?? "0") ?? (first["size"] as? Int64 ?? 0)
            let modifiedStr = first["modifiedTime"] as? String ?? ""
            let epochMillis = parseIso8601ToEpoch(modifiedStr)

            return GoogleBackupMetadata(fileId: fileId, name: name, modifiedTime: epochMillis, sizeBytes: size)
        } else if httpResponse.statusCode == 401 {
            throw GoogleDriveError.unauthorized
        } else {
            let msg = String(data: data, encoding: .utf8) ?? "HTTP \(httpResponse.statusCode)"
            throw GoogleDriveError.apiError(msg)
        }
    }

    /// Uploads a new backup file to appDataFolder using a multipart upload request.
    public func createBackupFile(accessToken: String, jsonContent: String) async throws -> GoogleBackupMetadata {
        if accessToken.hasPrefix("ya29.leaf_drive_access_token_") {
            return saveSimulatedBackup(jsonContent: jsonContent)
        }

        guard let url = URL(string: "\(Self.baseUploadUrl)/files?uploadType=multipart") else {
            throw GoogleDriveError.invalidUrl
        }

        let boundary = "===============\(Int64(Date().timeIntervalSince1970 * 1000))=="
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("multipart/related; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30

        let metadataDict: [String: Any] = [
            "name": Self.backupFileName,
            "parents": ["appDataFolder"],
            "description": "Leaf automatic application backup"
        ]
        let metadataData = try JSONSerialization.data(withJSONObject: metadataDict)

        guard let contentData = jsonContent.data(using: .utf8) else {
            throw GoogleDriveError.invalidData
        }

        var body = Data()
        body.append("--\(boundary)\r\nContent-Type: application/json; charset=UTF-8\r\n\r\n".data(using: .utf8)!)
        body.append(metadataData)
        body.append("\r\n--\(boundary)\r\nContent-Type: application/json\r\n\r\n".data(using: .utf8)!)
        body.append(contentData)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        request.httpBody = body

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw GoogleDriveError.networkError("Invalid server response")
        }

        if httpResponse.statusCode == 200 || httpResponse.statusCode == 201 {
            guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let fileId = json["id"] as? String else {
                throw GoogleDriveError.apiError("Missing file ID in upload response")
            }

            return GoogleBackupMetadata(
                fileId: fileId,
                name: Self.backupFileName,
                modifiedTime: Int64(Date().timeIntervalSince1970 * 1000),
                sizeBytes: Int64(contentData.count)
            )
        } else if httpResponse.statusCode == 401 {
            throw GoogleDriveError.unauthorized
        } else {
            let msg = String(data: data, encoding: .utf8) ?? "HTTP \(httpResponse.statusCode)"
            throw GoogleDriveError.apiError(msg)
        }
    }

    /// Updates existing backup file content in appDataFolder.
    public func updateBackupFile(accessToken: String, fileId: String, jsonContent: String) async throws -> GoogleBackupMetadata {
        if accessToken.hasPrefix("ya29.leaf_drive_access_token_") {
            return saveSimulatedBackup(jsonContent: jsonContent)
        }

        guard let url = URL(string: "\(Self.baseUploadUrl)/files/\(fileId)?uploadType=media") else {
            throw GoogleDriveError.invalidUrl
        }

        guard let contentData = jsonContent.data(using: .utf8) else {
            throw GoogleDriveError.invalidData
        }

        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = contentData
        request.timeoutInterval = 30

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw GoogleDriveError.networkError("Invalid server response")
        }

        if httpResponse.statusCode == 200 {
            return GoogleBackupMetadata(
                fileId: fileId,
                name: Self.backupFileName,
                modifiedTime: Int64(Date().timeIntervalSince1970 * 1000),
                sizeBytes: Int64(contentData.count)
            )
        } else if httpResponse.statusCode == 401 {
            throw GoogleDriveError.unauthorized
        } else {
            let msg = String(data: data, encoding: .utf8) ?? "HTTP \(httpResponse.statusCode)"
            throw GoogleDriveError.apiError(msg)
        }
    }

    /// Downloads the JSON payload of the backup file.
    public func downloadBackupFile(accessToken: String, fileId: String) async throws -> String {
        if accessToken.hasPrefix("ya29.leaf_drive_access_token_") {
            return loadSimulatedBackup()
        }

        guard let url = URL(string: "\(Self.baseApiUrl)/files/\(fileId)?alt=media") else {
            throw GoogleDriveError.invalidUrl
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 30

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw GoogleDriveError.networkError("Invalid server response")
        }

        if httpResponse.statusCode == 200 {
            guard let content = String(data: data, encoding: .utf8) else {
                throw GoogleDriveError.invalidData
            }
            return content
        } else if httpResponse.statusCode == 401 {
            throw GoogleDriveError.unauthorized
        } else {
            let msg = String(data: data, encoding: .utf8) ?? "HTTP \(httpResponse.statusCode)"
            throw GoogleDriveError.apiError(msg)
        }
    }

    // MARK: - Simulation Storage for Offline / Development Mode

    private static let simStorageKey = "leaf_simulated_google_drive_backup"
    private static let simMetaKey = "leaf_simulated_google_drive_meta"

    private func saveSimulatedBackup(jsonContent: String) -> GoogleBackupMetadata {
        UserDefaults.standard.set(jsonContent, forKey: Self.simStorageKey)
        let now = Int64(Date().timeIntervalSince1970 * 1000)
        let meta = GoogleBackupMetadata(
            fileId: "sim_file_" + UUID().uuidString.prefix(8),
            name: Self.backupFileName,
            modifiedTime: now,
            sizeBytes: Int64(jsonContent.utf8.count)
        )
        if let encoded = try? JSONEncoder().encode(meta) {
            UserDefaults.standard.set(encoded, forKey: Self.simMetaKey)
        }
        return meta
    }

    private func getSimulatedBackupMetadata() -> GoogleBackupMetadata? {
        guard let data = UserDefaults.standard.data(forKey: Self.simMetaKey),
              let meta = try? JSONDecoder().decode(GoogleBackupMetadata.self, from: data) else {
            return nil
        }
        return meta
    }

    private func loadSimulatedBackup() -> String {
        return UserDefaults.standard.string(forKey: Self.simStorageKey) ?? "{}"
    }

    // MARK: - Helpers

    private func escapeQuery(name: String) -> String {
        "name = '\(name)'"
    }

    private func parseIso8601ToEpoch(_ isoStr: String) -> Int64 {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: isoStr) {
            return Int64(date.timeIntervalSince1970 * 1000)
        }
        formatter.formatOptions = [.withInternetDateTime]
        if let date = formatter.date(from: isoStr) {
            return Int64(date.timeIntervalSince1970 * 1000)
        }
        return Int64(Date().timeIntervalSince1970 * 1000)
    }
}

public enum GoogleDriveError: LocalizedError, Sendable {
    case invalidUrl
    case invalidData
    case unauthorized
    case apiError(String)
    case networkError(String)

    public var errorDescription: String? {
        switch self {
        case .invalidUrl:
            return "Invalid Google Drive endpoint URL."
        case .invalidData:
            return "Unable to serialize or parse backup content."
        case .unauthorized:
            return "Google Drive authorization expired (401). Please reconnect your Google account."
        case .apiError(let msg):
            return "Google Drive API error: \(msg)"
        case .networkError(let msg):
            return "Network error contacting Google Drive: \(msg)"
        }
    }
}
