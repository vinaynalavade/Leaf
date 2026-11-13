import Foundation

/// Represents the level of algorithmic confidence in an extracted receipt field.
public enum ReceiptConfidence: String, Codable, Sendable {
    case high
    case medium
    case low

    public var displayName: String {
        switch self {
        case .high: return "High"
        case .medium: return "Review Needed"
        case .low: return "Uncertain"
        }
    }
}

/// A wrapper around an extracted receipt field conveying value, confidence, and detection context.
public struct ReceiptExtractedField<T: Sendable>: Sendable {
    public var value: T?
    public var confidence: ReceiptConfidence
    public var rawText: String?
    public var isAssumed: Bool
    public var sourceLabel: String?

    public init(
        value: T?,
        confidence: ReceiptConfidence = .low,
        rawText: String? = nil,
        isAssumed: Bool = false,
        sourceLabel: String? = nil
    ) {
        self.value = value
        self.confidence = confidence
        self.rawText = rawText
        self.isAssumed = isAssumed
        self.sourceLabel = sourceLabel
    }

    public static var empty: ReceiptExtractedField<T> {
        ReceiptExtractedField(value: nil, confidence: .low)
    }
}

