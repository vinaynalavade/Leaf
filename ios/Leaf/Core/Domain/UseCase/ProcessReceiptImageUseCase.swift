import Foundation
import UIKit

/// Orchestrates the receipt scanning pipeline:
/// Staging the image in secure temporary app storage, running the on-device Apple Vision OCR engine,
/// parsing financial fields (merchant, amount, date, tax, subtotal, currency), and suggesting categories.
public final class ProcessReceiptImageUseCase: Sendable {

    private let receiptOCRService: ReceiptOCRServiceProtocol
    private let receiptStorageService: ReceiptStorageService
    private let preferencesRepository: UserPreferencesRepositoryProtocol
    private let categoryRepository: CategoryRepositoryProtocol

    public init(
        receiptOCRService: ReceiptOCRServiceProtocol = ReceiptOCRService.shared,
        receiptStorageService: ReceiptStorageService = ReceiptStorageService.shared,
        preferencesRepository: UserPreferencesRepositoryProtocol,
        categoryRepository: CategoryRepositoryProtocol
    ) {
        self.receiptOCRService = receiptOCRService
        self.receiptStorageService = receiptStorageService
        self.preferencesRepository = preferencesRepository
        self.categoryRepository = categoryRepository
    }

    public func execute(image: UIImage) async throws -> ReceiptOCRResult {
        // 1. Stage temporary image for review
        let tempURL = try receiptStorageService.saveTemporaryImage(image)

        // 2. Perform on-device Apple Vision text recognition
        let ocrOutput = try await receiptOCRService.recognizeReceiptText(from: image)

        // 3. Resolve active currency and available categories
        let prefs = try? await preferencesRepository.getUserPreferences()
        let currency = Currency.fromCode(prefs?.currencyCode ?? "INR")
        let categories = (try? await categoryRepository.getAllCategories()) ?? []

        // 4. Parse extracted text lines with financial heuristics
        var result = ReceiptParser.shared.parseReceipt(
            lines: ocrOutput.lines,
            fallbackCurrency: currency,
            categories: categories
        )

        result.isBlurry = ocrOutput.isBlurry
        result.tempImageURL = tempURL

        return result
    }
}

