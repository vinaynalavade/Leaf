import Foundation
import SwiftUI
import UIKit
import PhotosUI

public enum ReceiptScannerState: Equatable {
    case idle
    case capturingCamera
    case processing(status: String)
    case review
    case error(ReceiptScanError)

    public static func == (lhs: ReceiptScannerState, rhs: ReceiptScannerState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle), (.capturingCamera, .capturingCamera), (.review, .review):
            return true
        case (.processing(let s1), .processing(let s2)):
            return s1 == s2
        case (.error(let e1), .error(let e2)):
            return e1.localizedDescription == e2.localizedDescription
        default:
            return false
        }
    }
}

/// Observable coordinator managing the complete lifecycle of on-device receipt scanning,
/// OCR execution via Vision, confidence extraction, user review/correction, and duplicate-safe expense creation.
@Observable
public final class ReceiptScannerViewModel: @unchecked Sendable {

    // MARK: - Dependencies
    private let processReceiptImageUseCase: ProcessReceiptImageUseCase
    private let addTransactionUseCase: AddTransactionUseCase
    private let receiptStorageService: ReceiptStorageService

    // MARK: - Presentation State
    public var state: ReceiptScannerState = .idle
    public var ocrResult: ReceiptOCRResult? = nil
    public var capturedImage: UIImage? = nil
    public var currency: Currency = .default
    public var categories: [Category] = []

    // MARK: - Review Form Editable Fields
    public var merchantInput: String = ""
    public var amountInput: String = ""
    public var selectedDate: Date = Date()
    public var selectedCategoryId: Int64 = 1
    public var selectedPaymentMethod: PaymentMethod = .cash
    public var subtotalInput: String = ""
    public var taxInput: String = ""
    public var noteInput: String = ""

    // Confidence metadata for review display
    public var merchantConfidence: ReceiptConfidence = .low
    public var amountConfidence: ReceiptConfidence = .low
    public var dateConfidence: ReceiptConfidence = .low
    public var isCategorySuggested: Bool = false
    public var suggestedCategoryName: String? = nil

    public var isSubmitting: Bool = false
    public var errorMessage: String? = nil

    public init(
        processReceiptImageUseCase: ProcessReceiptImageUseCase,
        addTransactionUseCase: AddTransactionUseCase,
        receiptStorageService: ReceiptStorageService = ReceiptStorageService.shared,
        currency: Currency = .default,
        categories: [Category] = []
    ) {
        self.processReceiptImageUseCase = processReceiptImageUseCase
        self.addTransactionUseCase = addTransactionUseCase
        self.receiptStorageService = receiptStorageService
        self.currency = currency
        self.categories = categories.filter { $0.type == .expense }
    }

    // MARK: - Process Image Pipeline

    @MainActor
    public func processImage(_ image: UIImage) async {
        self.capturedImage = image
        self.state = .processing(status: "Analyzing receipt on-device...")
        self.errorMessage = nil

        do {
            let result = try await processReceiptImageUseCase.execute(image: image)
            self.ocrResult = result

            // Populate editable review fields
            self.merchantInput = result.merchant.value ?? ""
            self.merchantConfidence = result.merchant.confidence

            if let totalAmt = result.totalAmount.value {
                self.amountInput = totalAmt.toInputString(currency: currency)
                self.amountConfidence = result.totalAmount.confidence
            } else {
                self.amountInput = ""
                self.amountConfidence = .low
            }

            self.selectedDate = result.date.value ?? Date()
            self.dateConfidence = result.date.confidence

            if let catId = result.suggestedCategoryId.value, categories.contains(where: { $0.id == catId }) {
                self.selectedCategoryId = catId
                self.isCategorySuggested = true
                self.suggestedCategoryName = result.suggestedCategoryName
            } else if let firstCat = categories.first {
                self.selectedCategoryId = firstCat.id
                self.isCategorySuggested = false
            }

            if let subtotal = result.subtotal.value {
                self.subtotalInput = subtotal.toInputString(currency: currency)
            } else {
                self.subtotalInput = ""
            }

            if let tax = result.taxAmount.value {
                self.taxInput = tax.toInputString(currency: currency)
            } else {
                self.taxInput = ""
            }

            // Note defaults to Merchant name if non-empty
            self.noteInput = result.merchant.value ?? ""

            // If image is too blurry, flag error for review
            if result.isBlurry {
                self.errorMessage = "The receipt image appears blurry. Extracted details may be inaccurate."
            }

            self.state = .review
        } catch let scanError as ReceiptScanError {
            self.state = .error(scanError)
        } catch {
            self.state = .error(.ocrProcessingFailed(error.localizedDescription))
        }
    }

    // MARK: - PhotosPicker Processing

    @MainActor
    public func processPhotosPickerItem(_ item: PhotosPickerItem?) async {
        guard let item = item else { return }

        self.state = .processing(status: "Loading photo...")
        do {
            guard let data = try await item.loadTransferable(type: Data.self),
                  let image = UIImage(data: data) else {
                self.state = .error(.imageLoadingFailed)
                return
            }
            await processImage(image.normalizedOrientation())
        } catch {
            self.state = .error(.imageLoadingFailed)
        }
    }

    // MARK: - Confirm & Save Expense

    @MainActor
    public func confirmAndSaveExpense() async -> Bool {
        guard !isSubmitting else { return false }

        // 1. Validation
        guard let amount = Amount.fromStringOrNull(amountInput, currency: currency),
              amount.subunits > 0 else {
            self.errorMessage = "Please enter a valid expense amount greater than zero."
            return false
        }

        guard selectedCategoryId > 0 else {
            self.errorMessage = "Please select a valid expense category."
            return false
        }

        isSubmitting = true
        errorMessage = nil

        do {
            // 2. Commit temporary image to permanent storage
            var savedReceiptPath: String? = nil
            if let tempURL = ocrResult?.tempImageURL {
                savedReceiptPath = try? receiptStorageService.commitTemporaryImage(tempURL: tempURL)
            } else if let img = capturedImage {
                savedReceiptPath = try? receiptStorageService.savePermanentImage(img)
            }

            // 3. Save standard Expense transaction
            let timestamp = Int64(selectedDate.timeIntervalSince1970 * 1000)
            let trimmedNote = noteInput.trimmingCharacters(in: .whitespacesAndNewlines)
            let finalNote = trimmedNote.isEmpty ? (merchantInput.isEmpty ? nil : merchantInput) : trimmedNote

            _ = try await addTransactionUseCase.execute(
                amount: amount,
                type: .expense,
                categoryId: selectedCategoryId,
                paymentMethod: selectedPaymentMethod,
                note: finalNote,
                timestamp: timestamp,
                receiptImagePath: savedReceiptPath
            )

            isSubmitting = false
            return true
        } catch {
            self.errorMessage = error.localizedDescription
            self.isSubmitting = false
            return false
        }
    }

    // MARK: - Actions

    public func retake() {
        receiptStorageService.cleanupTemporaryImages()
        self.ocrResult = nil
        self.capturedImage = nil
        self.errorMessage = nil
        self.state = .idle
    }

    public func cancel() {
        receiptStorageService.cleanupTemporaryImages()
    }
}

