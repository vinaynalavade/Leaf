import Foundation

/// The portable, authenticated encrypted file container format for Leaf data backups (`.leafbackup`).
/// Encapsulates cryptographic parameters (salt, nonce, KDF iterations) and AES-GCM ciphertext + tag.
public struct LeafBackupContainer: Codable, Sendable {
    public static let currentFormatVersion: Int = 1
    public static let defaultIterations: Int = 600_000
    public static let minAllowedIterations: Int = 10_000
    public static let maxAllowedIterations: Int = 2_000_000

    public static let defaultKdfAlgorithm: String = "PBKDF2-HMAC-SHA256"
    public static let defaultEncryptionAlgorithm: String = "AES-256-GCM"

    public let formatVersion: Int
    public let appVersion: String
    public let createdAt: Int64
    public let kdfAlgorithm: String
    public let encryptionAlgorithm: String
    public let saltBase64: String
    public let nonceBase64: String
    public let iterations: Int
    public let ciphertextBase64: String
    public let tagBase64: String

    enum CodingKeys: String, CodingKey {
        case formatVersion
        case appVersion
        case createdAt
        case kdfAlgorithm
        case encryptionAlgorithm
        case saltBase64
        case nonceBase64
        case iterations
        case ciphertextBase64
        case tagBase64
    }

    public init(
        formatVersion: Int = currentFormatVersion,
        appVersion: String,
        createdAt: Int64 = Int64(Date().timeIntervalSince1970 * 1000),
        kdfAlgorithm: String = defaultKdfAlgorithm,
        encryptionAlgorithm: String = defaultEncryptionAlgorithm,
        saltBase64: String,
        nonceBase64: String,
        iterations: Int = defaultIterations,
        ciphertextBase64: String,
        tagBase64: String
    ) {
        self.formatVersion = formatVersion
        self.appVersion = appVersion
        self.createdAt = createdAt
        self.kdfAlgorithm = kdfAlgorithm
        self.encryptionAlgorithm = encryptionAlgorithm
        self.saltBase64 = saltBase64
        self.nonceBase64 = nonceBase64
        self.iterations = iterations
        self.ciphertextBase64 = ciphertextBase64
        self.tagBase64 = tagBase64
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.formatVersion = try container.decode(Int.self, forKey: .formatVersion)
        self.appVersion = try container.decode(String.self, forKey: .appVersion)
        self.createdAt = try container.decode(Int64.self, forKey: .createdAt)
        self.kdfAlgorithm = try container.decodeIfPresent(String.self, forKey: .kdfAlgorithm) ?? Self.defaultKdfAlgorithm
        self.encryptionAlgorithm = try container.decodeIfPresent(String.self, forKey: .encryptionAlgorithm) ?? Self.defaultEncryptionAlgorithm
        self.saltBase64 = try container.decode(String.self, forKey: .saltBase64)
        self.nonceBase64 = try container.decode(String.self, forKey: .nonceBase64)
        self.iterations = try container.decode(Int.self, forKey: .iterations)
        self.ciphertextBase64 = try container.decode(String.self, forKey: .ciphertextBase64)
        self.tagBase64 = try container.decode(String.self, forKey: .tagBase64)
    }
}
