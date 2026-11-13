import SwiftUI
import PhotosUI

/// Unified modal sheet providing camera scanning, photo library import, on-device OCR execution,
/// and confidence-aware review for logging expenses from receipts.
public struct ReceiptScannerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    @State private var viewModel: ReceiptScannerViewModel
    @State private var selectedPhotoItem: PhotosPickerItem? = nil
    public let onSaveComplete: () -> Void

    public init(
        processReceiptImageUseCase: ProcessReceiptImageUseCase,
        addTransactionUseCase: AddTransactionUseCase,
        currency: Currency,
        categories: [Category],
        onSaveComplete: @escaping () -> Void
    ) {
        self.onSaveComplete = onSaveComplete
        self._viewModel = State(
            initialValue: ReceiptScannerViewModel(
                processReceiptImageUseCase: processReceiptImageUseCase,
                addTransactionUseCase: addTransactionUseCase,
                currency: currency,
                categories: categories
            )
        )
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                LeafTheme.canvas(for: colorScheme).ignoresSafeArea()

                switch viewModel.state {
                case .idle:
                    idleSelectionView

                case .capturingCamera:
                    ReceiptCameraView(
                        onImageCaptured: { image in
                            Task { await viewModel.processImage(image) }
                        },
                        onCancel: {
                            viewModel.state = .idle
                        }
                    )
                    .ignoresSafeArea()

                case .processing(let status):
                    processingView(status: status)

                case .review:
                    ReceiptReviewView(
                        viewModel: viewModel,
                        onSaveComplete: {
                            onSaveComplete()
                            dismiss()
                        },
                        onCancel: {
                            viewModel.cancel()
                            dismiss()
                        }
                    )

                case .error(let error):
                    errorView(error: error)
                }
            }
            .navigationTitle(navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if viewModel.state == .idle || viewModel.state == .error(.totalNotFound) {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            viewModel.cancel()
                            dismiss()
                        }
                        .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
                    }
                }
            }
            .onChange(of: selectedPhotoItem) { _, newItem in
                if let item = newItem {
                    Task {
                        await viewModel.processPhotosPickerItem(item)
                    }
                }
            }
        }
    }

    private var navigationTitle: String {
        switch viewModel.state {
        case .idle: return "Scan Receipt"
        case .capturingCamera: return "Capture Receipt"
        case .processing: return "Processing"
        case .review: return "Review Expense"
        case .error: return "Scan Failed"
        }
    }

    // MARK: - 1. Idle Selection View

    private var idleSelectionView: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header Banner
                VStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(LeafTheme.brandEmerald.opacity(0.12))
                            .frame(width: 80, height: 80)

                        Image(systemName: "doc.text.viewfinder")
                            .font(.system(size: 38, weight: .semibold))
                            .foregroundStyle(LeafTheme.brandEmerald)
                    }
                    .padding(.top, 16)

                    Text("Smart Receipt Scanning")
                        .font(LeafTypography.titleMedium)
                        .foregroundStyle(LeafTheme.textPrimary(for: colorScheme))

                    Text("Scan paper bills or import electronic receipts to automatically detect merchants, amounts, and dates on-device.")
                        .font(LeafTypography.bodyMedium)
                        .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }

                // Action Buttons
                VStack(spacing: 12) {
                    // Camera Button
                    Button(action: {
                        viewModel.state = .capturingCamera
                    }) {
                        HStack(spacing: 10) {
                            Image(systemName: "camera.fill")
                                .font(.system(size: 16, weight: .bold))
                            Text("Scan with Camera")
                                .font(LeafTypography.headline)
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(LeafTheme.brandEmerald)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }

                    // PhotosPicker Button
                    PhotosPicker(
                        selection: $selectedPhotoItem,
                        matching: .images,
                        photoLibrary: .shared()
                    ) {
                        HStack(spacing: 10) {
                            Image(systemName: "photo.on.rectangle.angled")
                                .font(.system(size: 16, weight: .semibold))
                            Text("Import from Photos")
                                .font(LeafTypography.headline)
                        }
                        .foregroundStyle(LeafTheme.textPrimary(for: colorScheme))
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(colorScheme == .dark ? LeafTheme.cardDark : LeafTheme.cardLight)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(LeafTheme.cardBorder(for: colorScheme), lineWidth: 0.75)
                        )
                    }
                }
                .padding(.horizontal)

                // Scanning Tips Card
                SquircleCard(cornerRadius: 18) {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 6) {
                            Image(systemName: "lightbulb.fill")
                                .foregroundStyle(LeafTheme.amberWarning)
                            Text("TIPS FOR BEST ACCURACY")
                                .font(LeafTypography.captionBold)
                                .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
                                .tracking(0.5)
                        }

                        tipRow(icon: "sun.max", text: "Ensure good lighting and avoid reflections or shadows")
                        tipRow(icon: "viewfinder", text: "Flatten folded receipts and capture the entire bill")
                        tipRow(icon: "lock.shield", text: "100% on-device Vision OCR — your data never leaves your iPhone")
                    }
                    .padding(16)
                }
                .padding(.horizontal)
            }
            .padding(.bottom, 24)
        }
    }

    private func tipRow(icon: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 13))
                .foregroundStyle(LeafTheme.brandEmerald)
                .frame(width: 18)
                .padding(.top, 2)

            Text(text)
                .font(LeafTypography.captionRegular)
                .foregroundStyle(LeafTheme.textPrimary(for: colorScheme))
        }
    }

    // MARK: - 2. Processing View

    private func processingView(status: String) -> some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .stroke(LeafTheme.brandEmerald.opacity(0.2), lineWidth: 4)
                    .frame(width: 88, height: 88)

                ProgressView()
                    .tint(LeafTheme.brandEmerald)
                    .scaleEffect(1.4)
            }

            VStack(spacing: 6) {
                Text(status)
                    .font(LeafTypography.titleMedium)
                    .foregroundStyle(LeafTheme.textPrimary(for: colorScheme))

                Text("Running Apple Vision Text Recognition on-device")
                    .font(LeafTypography.captionRegular)
                    .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    // MARK: - 3. Error View

    private func errorView(error: ReceiptScanError) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 52))
                .foregroundStyle(LeafTheme.expenseCoral)

            VStack(spacing: 8) {
                Text("Scan Incomplete")
                    .font(LeafTypography.titleMedium)
                    .foregroundStyle(LeafTheme.textPrimary(for: colorScheme))

                Text(error.localizedDescription)
                    .font(LeafTypography.bodyMedium)
                    .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            VStack(spacing: 12) {
                Button(action: { viewModel.retake() }) {
                    Text("Try Again")
                        .font(LeafTypography.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(LeafTheme.brandEmerald)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }

                Button(action: {
                    viewModel.cancel()
                    dismiss()
                }) {
                    Text("Cancel")
                        .font(LeafTypography.subheadline)
                        .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
                }
            }
            .padding(.horizontal, 32)
            .padding(.top, 12)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

