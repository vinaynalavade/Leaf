import Foundation
import UIKit

/// Manages secure local file storage for receipt images attached to expenses.
/// Enforces on-device storage, Apple file protection (.complete), image downscaling
/// for storage efficiency, and clean lifecycle management of temporary scan images.
public final class ReceiptStorageService: @unchecked Sendable {

    public static let shared = ReceiptStorageService()

    private let fileManager = FileManager.default
    private let maxDimension: CGFloat = 1800.0
    private let compressionQuality: CGFloat = 0.85

    public init() {}

    // MARK: - Directory Resolution

    /// Directory for permanently saved receipt attachments: <Documents>/Receipts
    public var receiptsDirectoryURL: URL {
        let docs = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSTemporaryDirectory())
        let dir = docs.appendingPathComponent("Receipts", isDirectory: true)
        if !fileManager.fileExists(atPath: dir.path) {
            try? fileManager.createDirectory(at: dir, withIntermediateDirectories: true)
            try? fileManager.setAttributes([.protectionKey: FileProtectionType.complete], ofItemAtPath: dir.path)
        }
        return dir
    }

    /// Directory for temporary images during scanning/OCR review: <tmp>/ReceiptScan_Temp
    public var tempDirectoryURL: URL {
        let temp = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("ReceiptScan_Temp", isDirectory: true)
        if !fileManager.fileExists(atPath: temp.path) {
            try? fileManager.createDirectory(at: temp, withIntermediateDirectories: true)
        }
        return temp
    }

    // MARK: - Save Operations

    /// Saves a captured or imported image temporarily during OCR review.
    /// Returns the file URL of the temporary image.
    public func saveTemporaryImage(_ image: UIImage) throws -> URL {
        let preparedImage = downscaleIfNeeded(image)
        guard let data = preparedImage.jpegData(compressionQuality: compressionQuality) else {
            throw ReceiptStorageError.compressionFailed
        }

        let filename = "temp_receipt_\(UUID().uuidString).jpg"
        let fileURL = tempDirectoryURL.appendingPathComponent(filename)
        try data.write(to: fileURL, options: .atomic)
        try? fileManager.setAttributes([.protectionKey: FileProtectionType.completeUnlessOpen], ofItemAtPath: fileURL.path)
        return fileURL
    }

    /// Commits a temporary receipt image into permanent app storage.
    /// Returns the relative path inside <Documents>/Receipts (e.g. "Receipts/receipt_<uuid>.jpg").
    public func commitTemporaryImage(tempURL: URL) throws -> String {
        guard fileManager.fileExists(atPath: tempURL.path) else {
            throw ReceiptStorageError.fileNotFound
        }

        let filename = "receipt_\(UUID().uuidString).jpg"
        let destinationURL = receiptsDirectoryURL.appendingPathComponent(filename)

        if fileManager.fileExists(atPath: destinationURL.path) {
            try fileManager.removeItem(at: destinationURL)
        }

        try fileManager.moveItem(at: tempURL, to: destinationURL)
        try? fileManager.setAttributes([.protectionKey: FileProtectionType.complete], ofItemAtPath: destinationURL.path)

        // Return relative path for portability across app container upgrades
        return "Receipts/\(filename)"
    }

    /// Saves an image directly into permanent receipt storage.
    /// Returns the relative path (e.g. "Receipts/receipt_<uuid>.jpg").
    public func savePermanentImage(_ image: UIImage) throws -> String {
        let preparedImage = downscaleIfNeeded(image)
        guard let data = preparedImage.jpegData(compressionQuality: compressionQuality) else {
            throw ReceiptStorageError.compressionFailed
        }

        let filename = "receipt_\(UUID().uuidString).jpg"
        let destinationURL = receiptsDirectoryURL.appendingPathComponent(filename)
        try data.write(to: destinationURL, options: .atomic)
        try? fileManager.setAttributes([.protectionKey: FileProtectionType.complete], ofItemAtPath: destinationURL.path)

        return "Receipts/\(filename)"
    }

    // MARK: - Load Operations

    /// Resolves a full local URL from a relative path or absolute path.
    public func resolveURL(for path: String) -> URL? {
        if path.hasPrefix("/") {
            // Absolute path
            return URL(fileURLWithPath: path)
        }

        // Relative path inside Documents
        if let docs = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first {
            let fullURL = docs.appendingPathComponent(path)
            if fileManager.fileExists(atPath: fullURL.path) {
                return fullURL
            }
        }

        return nil
    }

    /// Loads a receipt UIImage from disk.
    public func loadReceiptImage(path: String) -> UIImage? {
        guard let url = resolveURL(for: path) else { return nil }
        guard let data = try? Data(contentsOf: url) else { return nil }
        return UIImage(data: data)
    }

    // MARK: - Deletion & Cleanup

    /// Safely deletes a permanent receipt image file.
    public func deleteReceiptImage(path: String) {
        guard let url = resolveURL(for: path) else { return }
        try? fileManager.removeItem(at: url)
    }

    /// Cleans up all files in the temporary scanning folder.
    public func cleanupTemporaryImages() {
        guard let contents = try? fileManager.contentsOfDirectory(at: tempDirectoryURL, includingPropertiesForKeys: nil) else {
            return
        }
        for file in contents {
            try? fileManager.removeItem(at: file)
        }
    }

    // MARK: - Image Downscaling

    private func downscaleIfNeeded(_ image: UIImage) -> UIImage {
        let size = image.size
        let maxSide = max(size.width, size.height)
        guard maxSide > maxDimension else { return image }

        let scale = maxDimension / maxSide
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)

        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}

public enum ReceiptStorageError: LocalizedError {
    case compressionFailed
    case fileNotFound
    case writeFailed

    public var errorDescription: String? {
        switch self {
        case .compressionFailed:
            return "Failed to process receipt image data."
        case .fileNotFound:
            return "Temporary receipt image could not be found."
        case .writeFailed:
            return "Failed to save receipt image to disk."
        }
    }
}

