import Foundation
import Security
import CryptoKit
import CommonCrypto

/// Cryptographic result of a PIN entry verification attempt.
public enum PinVerificationResult: Equatable, Sendable {
    case success
    case incorrect(remainingAttempts: Int)
    case lockedOut(secondsRemaining: Int)
}

/// Manages secure, salted 6-digit PIN derivation, verification, and temporary lockout throttling.
/// Enforces storage strictly inside Apple Keychain via `KeychainService`
/// with `kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly`.
/// Uses PBKDF2-HMAC-SHA256 with 100,000 iterations for cryptographically hardened protection,
/// while providing transparent, automatic migration for legacy PINs.
public final class SecurePinManager: @unchecked Sendable {

    public static let shared = SecurePinManager()

    public static let pinLength: Int = 6
    public static let maxFailedAttempts: Int = 5
    public static let lockoutDurationSeconds: Int = 30
    public static let pbkdf2Iterations: Int = 100_000

    private static let keyPinSalt = "leaf_sec_pin_salt"
    private static let keyPinHash = "leaf_sec_pin_hash"
    private static let keyPinVersion = "leaf_sec_pin_version"
    private static let currentVersion = "v2_pbkdf2"

    private let keychain: KeychainService
    private let lock = NSLock()

    private var failedAttempts: Int = 0
    private var lockoutUntil: Date? = nil

    public init(keychain: KeychainService = .shared) {
        self.keychain = keychain
    }

    /// Checks whether a valid 6-digit PIN is currently configured in the secure Keychain.
    public func isPinConfigured() -> Bool {
        lock.lock()
        defer { lock.unlock() }

        guard let salt = keychain.load(key: Self.keyPinSalt), !salt.isEmpty,
              let hash = keychain.load(key: Self.keyPinHash), !hash.isEmpty else {
            return false
        }
        return true
    }

    /// Validates and cryptographically stores a new 6-digit PIN into the Keychain
    /// using PBKDF2-HMAC-SHA256 with 100,000 rounds and a fresh 16-byte random salt.
    @discardableResult
    public func savePin(_ pin: String) -> Bool {
        lock.lock()
        defer { lock.unlock() }

        guard pin.count == Self.pinLength, pin.allSatisfy(\.isNumber) else {
            return false
        }

        var saltBytes = [UInt8](repeating: 0, count: 16)
        let status = SecRandomCopyBytes(kSecRandomDefault, saltBytes.count, &saltBytes)
        guard status == errSecSuccess else {
            return false
        }

        let saltData = Data(saltBytes)
        guard let hashData = computePBKDF2Hash(pin: pin, salt: saltData) else {
            return false
        }

        let savedSalt = keychain.save(key: Self.keyPinSalt, data: saltData)
        let savedHash = keychain.save(key: Self.keyPinHash, data: hashData)
        _ = keychain.save(key: Self.keyPinVersion, data: Data(Self.currentVersion.utf8))

        if savedSalt && savedHash {
            failedAttempts = 0
            lockoutUntil = nil
            return true
        }
        return false
    }

    /// Verifies the entered PIN against the salt and hash stored in the Keychain.
    /// Supports automatic seamless upgrade from legacy single-pass hashes to PBKDF2-HMAC-SHA256.
    /// Implements rate limiting and 30-second lockout after 5 consecutive failures.
    public func verifyPin(_ pin: String) -> PinVerificationResult {
        lock.lock()
        defer { lock.unlock() }

        // 1. Check active lockout
        if let until = lockoutUntil {
            let now = Date()
            if until > now {
                let secondsRemaining = Int(until.timeIntervalSince(now).rounded(.up))
                return .lockedOut(secondsRemaining: max(1, secondsRemaining))
            } else {
                // Lockout expired; reset for next batch
                lockoutUntil = nil
                failedAttempts = 0
            }
        }

        // 2. Load stored credentials from Keychain
        guard let saltData = keychain.load(key: Self.keyPinSalt),
              let storedHashData = keychain.load(key: Self.keyPinHash) else {
            return .incorrect(remainingAttempts: 0)
        }

        // 3. Verify against PBKDF2-HMAC-SHA256
        var isMatch = false
        if let pbkdf2Hash = computePBKDF2Hash(pin: pin, salt: saltData) {
            if constantTimeCompare(storedHashData, pbkdf2Hash) {
                isMatch = true
            }
        }

        // 4. Safe migration fallback: If not matched via PBKDF2, test legacy single-pass SHA-256
        if !isMatch {
            let legacyHash = computeLegacySaltedHash(pin: pin, salt: saltData)
            if constantTimeCompare(storedHashData, legacyHash) {
                // Verified against legacy hash - seamlessly upgrade to PBKDF2-HMAC-SHA256 in Keychain
                if let upgradedHash = computePBKDF2Hash(pin: pin, salt: saltData) {
                    _ = keychain.save(key: Self.keyPinHash, data: upgradedHash)
                    _ = keychain.save(key: Self.keyPinVersion, data: Data(Self.currentVersion.utf8))
                }
                isMatch = true
            }
        }

        if isMatch {
            failedAttempts = 0
            lockoutUntil = nil
            return .success
        } else {
            failedAttempts += 1
            if failedAttempts >= Self.maxFailedAttempts {
                lockoutUntil = Date().addingTimeInterval(TimeInterval(Self.lockoutDurationSeconds))
                return .lockedOut(secondsRemaining: Self.lockoutDurationSeconds)
            } else {
                let remaining = Self.maxFailedAttempts - failedAttempts
                return .incorrect(remainingAttempts: remaining)
            }
        }
    }

    /// Checks the remaining seconds of an active lockout, if any.
    public func getLockoutSecondsRemaining() -> Int {
        lock.lock()
        defer { lock.unlock() }

        guard let until = lockoutUntil else { return 0 }
        let now = Date()
        if until > now {
            return max(1, Int(until.timeIntervalSince(now).rounded(.up)))
        }
        return 0
    }

    /// Permanently removes the configured PIN from the Keychain.
    @discardableResult
    public func clearPin() -> Bool {
        lock.lock()
        defer { lock.unlock() }

        let saltDeleted = keychain.delete(key: Self.keyPinSalt)
        let hashDeleted = keychain.delete(key: Self.keyPinHash)
        _ = keychain.delete(key: Self.keyPinVersion)
        failedAttempts = 0
        lockoutUntil = nil
        return saltDeleted && hashDeleted
    }

    // MARK: - Cryptographic Helpers

    /// Computes PBKDF2-HMAC-SHA256 derived key (32 bytes) with 100,000 iterations.
    private func computePBKDF2Hash(pin: String, salt: Data, iterations: Int = pbkdf2Iterations) -> Data? {
        guard let pinData = pin.data(using: .utf8) else { return nil }
        let keyByteCount = 32
        var derivedKeyData = Data(repeating: 0, count: keyByteCount)

        let status = derivedKeyData.withUnsafeMutableBytes { derivedKeyBytes in
            pinData.withUnsafeBytes { pinBytes in
                salt.withUnsafeBytes { saltBytes in
                    CCKeyDerivationPBKDF(
                        CCPBKDFAlgorithm(kCCPBKDF2),
                        pinBytes.baseAddress?.assumingMemoryBound(to: Int8.self),
                        pinData.count,
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

        guard status == kCCSuccess else { return nil }
        return derivedKeyData
    }

    /// Legacy single-pass SHA-256 for backwards-compatible migration.
    private func computeLegacySaltedHash(pin: String, salt: Data) -> Data {
        var hasher = SHA256()
        hasher.update(data: salt)
        if let pinData = pin.data(using: .utf8) {
            hasher.update(data: pinData)
        }
        let digest = hasher.finalize()
        return Data(digest)
    }

    private func constantTimeCompare(_ a: Data, _ b: Data) -> Bool {
        guard a.count == b.count else { return false }
        var result: UInt8 = 0
        for (byteA, byteB) in zip(a, b) {
            result |= byteA ^ byteB
        }
        return result == 0
    }
}
