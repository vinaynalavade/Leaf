import SwiftUI
import PDFKit

/// Native PDF Viewer modal sheet using PDFKit to preview generated financial statements.
/// Supports smooth pinch-to-zoom, page thumbnail navigation, and standard iOS ShareLink.
public struct PdfViewerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @State private var isExportingToFiles: Bool = false

    public let statement: SavedStatement

    public init(statement: SavedStatement) {
        self.statement = statement
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                LeafTheme.canvas(for: colorScheme).ignoresSafeArea()

                if statement.fileExists, let document = PDFDocument(url: statement.fileURL) {
                    PDFKitRepresentedView(document: document)
                        .edgesIgnoringSafeArea(.bottom)
                } else {
                    VStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 40))
                            .foregroundStyle(LeafTheme.expenseCoral)

                        Text("Statement File Unavailable")
                            .font(LeafTypography.titleMedium)
                            .foregroundStyle(LeafTheme.textPrimary(for: colorScheme))

                        Text("The physical PDF file could not be found at:\n\(statement.filePath)")
                            .font(LeafTypography.caption)
                            .multilineTextAlignment(.center)
                            .foregroundStyle(LeafTheme.textSecondary(for: colorScheme))
                            .padding(.horizontal, 32)
                    }
                }
            }
            .navigationTitle(statement.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(LeafTypography.bodyBold)
                    .foregroundStyle(LeafTheme.accent(for: colorScheme))
                }

                ToolbarItem(placement: .primaryAction) {
                    if statement.fileExists {
                        HStack(spacing: 16) {
                            Button {
                                isExportingToFiles = true
                            } label: {
                                Image(systemName: "folder.badge.plus")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundStyle(LeafTheme.accent(for: colorScheme))
                            }

                            ShareLink(
                                item: statement.fileURL,
                                preview: SharePreview(statement.title, image: Image(systemName: "doc.text.fill"))
                            ) {
                                Image(systemName: "square.and.arrow.up")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundStyle(LeafTheme.accent(for: colorScheme))
                            }
                        }
                    }
                }
            }
            .sheet(isPresented: $isExportingToFiles) {
                DocumentPickerExportView(url: statement.fileURL) { _ in
                    isExportingToFiles = false
                }
            }
        }
    }
}

/// SwiftUI wrapper around UIKit's `PDFView`.
struct PDFKitRepresentedView: UIViewRepresentable {
    let document: PDFDocument

    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.document = document
        pdfView.autoScales = true
        pdfView.displayMode = .singlePageContinuous
        pdfView.displayDirection = .vertical
        pdfView.displaysPageBreaks = true
        pdfView.backgroundColor = .systemGroupedBackground
        return pdfView
    }

    func updateUIView(_ uiView: PDFView, context: Context) {
        if uiView.document !== document {
            uiView.document = document
        }
    }
}

