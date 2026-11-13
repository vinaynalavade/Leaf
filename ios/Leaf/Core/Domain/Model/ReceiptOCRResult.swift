import Foundation
import UIKit

/// Aggregates all extracted financial fields and diagnostic metadata from a scanned receipt.
public struct ReceiptOCRResult: Sendable {
    public var rawLines: [String]
    public var fullText: String
    public var merchant: ReceiptExtractedField<String>
    public var totalAmount: ReceiptExtractedField<Amount>
    public var date: ReceiptExtractedField<Date>
    public var taxAmount: ReceiptExtractedField<Amount>
    public var subtotal: ReceiptExtractedField<Amount>
    public var currency: ReceiptExtractedField<Currency>
    public var suggestedCategoryId: ReceiptExtractedField<Int64>
    public var suggestedCategoryName: String?
    public var overallConfidence: ReceiptConfidence
    public var isBlurry: Bool
    public var tempImageURL: URL?

    public init(
        rawLines: [String] = [],
        fullText: String = "",
        merchant: ReceiptExtractedField<String> = .empty,
        totalAmount: ReceiptExtractedField<Amount> = .empty,
        date: ReceiptExtractedField<Date> = .empty,
        taxAmount: ReceiptExtractedField<Amount> = .empty,
        subtotal: ReceiptExtractedField<Amount> = .empty,
        currency: ReceiptExtractedField<Currency> = .empty,
        suggestedCategoryId: ReceiptExtractedField<Int64> = .empty,
        suggestedCategoryName: String? = nil,
        overallConfidence: ReceiptConfidence = .low,
        isBlurry: Bool = false,
        tempImageURL: URL? = nil
    ) {
        self.rawLines = rawLines
        self.fullText = fullText
        self.merchant = merchant
        self.totalAmount = totalAmount
        self.date = date
        self.taxAmount = taxAmount
        self.subtotal = subtotal
        self.currency = currency
        self.suggestedCategoryId = suggestedCategoryId
        self.suggestedCategoryName = suggestedCategoryName
        self.overallConfidence = overallConfidence
        self.isBlurry = isBlurry
        self.tempImageURL = tempImageURL
    }

    public static var empty: ReceiptOCRResult {
        ReceiptOCRResult()
    }
}

/// Domain errors encountered during the receipt scanning and extraction lifecycle.
public enum ReceiptScanError: LocalizedError, Equatable {
    case cameraPermissionDenied
    case imageCaptureFailed
    case imageLoadingFailed
    case noTextRecognized
    case imageTooBlurry
    case totalNotFound
    case ocrProcessingFailed(String)

    public var errorDescription: String? {
        switch self {
        case .cameraPermissionDenied:
            return "Camera access is required to scan physical receipts. Please enable Camera permissions in iOS Settings."
        case .imageCaptureFailed:
            return "Failed to capture receipt photo. Please try again."
        case .imageLoadingFailed:
            return "Unable to load the selected receipt image file."
        case .noTextRecognized:
            return "No recognizable text found in the image. Please ensure the receipt is well-lit, in focus, and flat."
        case .imageTooBlurry:
            return "The receipt image appears blurry or low contrast. Please hold the camera steady and retake."
        case .totalNotFound:
            return "Could not automatically identify the total amount. You can review and enter the amount manually."
        case .ocrProcessingFailed(let msg):
            return "Receipt OCR processing failed: \(msg)"
        }
    }
}

