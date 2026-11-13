import Foundation
import CryptoKit
import CommonCrypto

public enum BackupCryptoError: LocalizedError {
    case keyDerivationFailed
    case encryptionFailed
    case decryptionFailed
    case invalidPasswordOrTamperedData
    case invalidBackupFormat
    case unsupportedVersion(Int)
    case maliciousOrInvalidIterationCount(Int)
    case unsupportedCryptographicAlgorithm(String)

    public var errorDescription: String? {
        switch self {
        case .keyDerivationFailed:
            return "Failed to derive encryption key from password."
        case .encryptionFailed:
            return "Encryption failed while creating the backup file."
        case .decryptionFailed:
            return "Failed to decrypt the backup file."
        case .invalidPasswordOrTamperedData:
            return "Incorrect backup password or the backup file has been corrupted or tampered with."
        case .invalidBackupFormat:
            return "The selected file is not a valid Leaf encrypted backup."
        case .unsupportedVersion(let version):
            return "Backup format version \(version) is not supported by this version of Leaf."
        case .maliciousOrInvalidIterationCount(let count):
            return "Backup specifies an invalid or unsafe iteration count (\(count))."
        case .unsupportedCryptographicAlgorithm(let algo):
            return "Cryptographic algorithm '\(algo)' is not supported."
        }
    }
}

/// Cryptographic engine utilizing Apple's CryptoKit (AES-GCM 256) and CommonCrypto (PBKDF2-HMAC-SHA256).
/// Hardened with 600,000 PBKDF2 iterations by default and safe boundary validation for untrusted inputs.
public final class BackupCryptoEngine: Sendable {

    public static let shared = BackupCryptoEngine()

    public init() {}

    // MARK: - Key Derivation (PBKDF2-HMAC-SHA256)

    /// Derives a 256-bit symmetric encryption key from a user password and cryptographically secure salt.
    public func deriveKey(
        password: String,
        salt: Data,
        iterations: Int = LeafBackupContainer.defaultIterations
    ) throws -> SymmetricKey {
        guard let passwordData = password.data(using: .utf8) else {
            throw BackupCryptoError.keyDerivationFailed
        }

        let keyByteCount = 32 // 256 bits
        var derivedKeyData = Data(repeating: 0, count: keyByteCount)

        let status = derivedKeyData.withUnsafeMutableBytes { derivedKeyBytes in
            passwordData.withUnsafeBytes { passwordBytes in
                salt.withUnsafeBytes { saltBytes in
                    CCKeyDerivationPBKDF(
                        CCPBKDFAlgorithm(kCCPBKDF2),
                        passwordBytes.baseAddress?.assumingMemoryBound(to: Int8.self),
                        passwordData.count,
                        saltBytes.baseAddress?.assumingMemoryBound(to: UInt8.self),
                        salt.count,
                        CCPseudoRandomAlgorithm(kCCPRFHmacAlgSHA256),
                        UInt32(iterations),
                        derivedKeyBytes.baseAddress?.assumingMemoryBound(to: UInt8.self),
                        keyByteCount
                    )
                }
            }
        }

        guard status == kCCSuccess else {
            throw BackupCryptoError.keyDerivationFailed
        }

        return SymmetricKey(data: derivedKeyData)
    }

    /// Generates cryptographically secure random bytes for salting.
    public func generateRandomSalt(byteCount: Int = 16) throws -> Data {
        var bytes = [UInt8](repeating: 0, count: byteCount)
        let status = SecRandomCopyBytes(kSecRandomDefault, byteCount, &bytes)
        guard status == errSecSuccess else {
            throw BackupCryptoError.keyDerivationFailed
        }
        return Data(bytes)
    }

    // MARK: - Encryption (AES-GCM 256)

    /// Encrypts raw plaintext JSON data into a portable `LeafBackupContainer`.
    public func encrypt(
        plaintextData: Data,
        password: String,
        appVersion: String,
        iterations: Int = LeafBackupContainer.defaultIterations
    ) throws -> LeafBackupContainer {
        let salt = try generateRandomSalt(byteCount: 16)
        let key = try deriveKey(password: password, salt: salt, iterations: iterations)

        let nonce = AES.GCM.Nonce()
        let sealedBox: AES.GCM.SealedBox
        do {
            sealedBox = try AES.GCM.seal(plaintextData, using: key, nonce: nonce)
        } catch {
            throw BackupCryptoError.encryptionFailed
        }

        return LeafBackupContainer(
            formatVersion: LeafBackupContainer.currentFormatVersion,
            appVersion: appVersion,
            createdAt: Int64(Date().timeIntervalSince1970 * 1000),
            kdfAlgorithm: LeafBackupContainer.defaultKdfAlgorithm,
            encryptionAlgorithm: LeafBackupContainer.defaultEncryptionAlgorithm,
            saltBase64: salt.base64EncodedString(),
            nonceBase64: Data(nonce).base64EncodedString(),
            iterations: iterations,
            ciphertextBase64: sealedBox.ciphertext.base64EncodedString(),
            tagBase64: sealedBox.tag.base64EncodedString()
        )
    }

    // MARK: - Decryption (AES-GCM 256)

    /// Decrypts a `LeafBackupContainer` using the user's password.
    public func decrypt(
        container: LeafBackupContainer,
        password: String
    ) throws -> Data {
        guard container.formatVersion <= LeafBackupContainer.currentFormatVersion else {
            throw BackupCryptoError.unsupportedVersion(container.formatVersion)
        }

        // Bounded iteration count validation to protect against denial of service
        guard container.iterations >= LeafBackupContainer.minAllowedIterations &&
              container.iterations <= LeafBackupContainer.maxAllowedIterations else {
            throw BackupCryptoError.maliciousOrInvalidIterationCount(container.iterations)
        }

        // Cryptographic algorithm validation
        guard container.kdfAlgorithm == LeafBackupContainer.defaultKdfAlgorithm else {
            throw BackupCryptoError.unsupportedCryptographicAlgorithm(container.kdfAlgorithm)
        }
        guard container.encryptionAlgorithm == LeafBackupContainer.defaultEncryptionAlgorithm else {
            throw BackupCryptoError.unsupportedCryptographicAlgorithm(container.encryptionAlgorithm)
        }

        guard let salt = Data(base64Encoded: container.saltBase64),
              let nonceData = Data(base64Encoded: container.nonceBase64),
              let ciphertext = Data(base64Encoded: container.ciphertextBase64),
              let tag = Data(base64Encoded: container.tagBase64) else {
            throw BackupCryptoError.invalidBackupFormat
        }

        let key = try deriveKey(password: password, salt: salt, iterations: container.iterations)

        do {
            let nonce = try AES.GCM.Nonce(data: nonceData)
            let sealedBox = try AES.GCM.SealedBox(nonce: nonce, ciphertext: ciphertext, tag: tag)
            return try AES.GCM.open(sealedBox, using: key)
        } catch {
            // Authentication failure indicates incorrect password or altered ciphertext/tag
            throw BackupCryptoError.invalidPasswordOrTamperedData
        }
    }
}
