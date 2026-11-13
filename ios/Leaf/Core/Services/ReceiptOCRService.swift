import Foundation
import UIKit
import Vision

/// Represents a single text line recognized by the Vision OCR framework with its geometry and confidence.
public struct RecognizedReceiptLine: Sendable {
    public let text: String
    public let confidence: Float
    public let boundingBox: CGRect  // Normalized coordinates (0...1) where (0,0) is bottom-left in Vision

    public init(text: String, confidence: Float, boundingBox: CGRect) {
        self.text = text
        self.confidence = confidence
        self.boundingBox = boundingBox
    }
}

/// Raw payload returned by the on-device Vision OCR engine.
public struct OCRScanOutput: Sendable {
    public let lines: [RecognizedReceiptLine]
    public let rawText: String
    public let isBlurry: Bool
    public let averageConfidence: Float

    public init(
        lines: [RecognizedReceiptLine],
        rawText: String,
        isBlurry: Bool,
        averageConfidence: Float
    ) {
        self.lines = lines
        self.rawText = rawText
        self.isBlurry = isBlurry
        self.averageConfidence = averageConfidence
    }
}

/// Protocol defining the on-device receipt text recognition service.
public protocol ReceiptOCRServiceProtocol: Sendable {
    func recognizeReceiptText(from image: UIImage) async throws -> OCRScanOutput
}

/// Native on-device OCR engine utilizing Apple's Vision framework (`VNRecognizeTextRequest`).
/// Configured for high accuracy financial receipt parsing without external network or cloud calls.
public final class ReceiptOCRService: ReceiptOCRServiceProtocol, Sendable {

    public static let shared = ReceiptOCRService()

    public init() {}

    public func recognizeReceiptText(from image: UIImage) async throws -> OCRScanOutput {
        guard let cgImage = image.cgImage else {
            throw ReceiptScanError.imageLoadingFailed
        }

        let orientation = CGImagePropertyOrientation(image.imageOrientation)

        return try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: ReceiptScanError.ocrProcessingFailed(error.localizedDescription))
                    return
                }

                guard let observations = request.results as? [VNRecognizedTextObservation], !observations.isEmpty else {
                    continuation.resume(throwing: ReceiptScanError.noTextRecognized)
                    return
                }

                var recognizedLines: [RecognizedReceiptLine] = []
                var confidenceSum: Float = 0.0

                for obs in observations {
                    guard let topCandidate = obs.topCandidates(1).first else { continue }
                    let lineText = topCandidate.string.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !lineText.isEmpty else { continue }

                    confidenceSum += topCandidate.confidence
                    recognizedLines.append(
                        RecognizedReceiptLine(
                            text: lineText,
                            confidence: topCandidate.confidence,
                            boundingBox: obs.boundingBox
                        )
                    )
                }

                guard !recognizedLines.isEmpty else {
                    continuation.resume(throwing: ReceiptScanError.noTextRecognized)
                    return
                }

                // In Vision coordinate space, y=0 is at the bottom.
                // Sort lines from top of the receipt to the bottom (descending y), then left to right (ascending x)
                recognizedLines.sort { lineA, lineB in
                    let deltaY = abs(lineA.boundingBox.origin.y - lineB.boundingBox.origin.y)
                    if deltaY < 0.015 { // Same horizontal line
                        return lineA.boundingBox.origin.x < lineB.boundingBox.origin.x
                    }
                    return lineA.boundingBox.origin.y > lineB.boundingBox.origin.y
                }

                let count = Float(recognizedLines.count)
                let avgConfidence = confidenceSum / count
                let fullText = recognizedLines.map(\.text).joined(separator: "\n")

                // Blurriness detection: If avg confidence is extremely low (< 0.35) and lines are sparse
                let isBlurry = avgConfidence < 0.40 && count < 4

                let output = OCRScanOutput(
                    lines: recognizedLines,
                    rawText: fullText,
                    isBlurry: isBlurry,
                    averageConfidence: avgConfidence
                )

                continuation.resume(returning: output)
            }

            // Configure Vision text recognition for maximum accuracy on receipt typography
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            request.recognitionLanguages = ["en-US", "en-GB", "en-IN"]
            if #available(iOS 16.0, *) {
                request.automaticallyDetectsLanguage = true
            }

            let handler = VNImageRequestHandler(cgImage: cgImage, orientation: orientation, options: [:])

            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    try handler.perform([request])
                } catch {
                    continuation.resume(throwing: ReceiptScanError.ocrProcessingFailed(error.localizedDescription))
                }
            }
        }
    }
}

// MARK: - CGImagePropertyOrientation Helper

extension CGImagePropertyOrientation {
    init(_ uiOrientation: UIImage.Orientation) {
        switch uiOrientation {
        case .up: self = .up
        case .upMirrored: self = .upMirrored
        case .down: self = .down
        case .downMirrored: self = .downMirrored
        case .left: self = .left
        case .leftMirrored: self = .leftMirrored
        case .right: self = .right
        case .rightMirrored: self = .rightMirrored
        @unknown default: self = .up
        }
    }
}

