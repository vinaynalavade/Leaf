import SwiftUI
import UIKit

/// Wrapper for a file URL to be exported via native document picker.
public struct ExportItem: Identifiable, Sendable {
    public var id: String { url.absoluteString }
    public let url: URL
    public let title: String

    public init(url: URL, title: String) {
        self.url = url
        self.title = title
    }
}

/// Native iOS Document Picker for exporting PDF and CSV files to the iOS Files app (iCloud Drive / local device).
public struct DocumentPickerExportView: UIViewControllerRepresentable {
    public let url: URL
    public let onCompletion: ((URL?) -> Void)?

    public init(url: URL, onCompletion: ((URL?) -> Void)? = nil) {
        self.url = url
        self.onCompletion = onCompletion
    }

    public func makeCoordinator() -> Coordinator {
        Coordinator(onCompletion: onCompletion)
    }

    public func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forExporting: [url], asCopy: true)
        picker.delegate = context.coordinator
        picker.allowsMultipleSelection = false
        return picker
    }

    public func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}

    public final class Coordinator: NSObject, UIDocumentPickerDelegate {
        private let onCompletion: ((URL?) -> Void)?

        init(onCompletion: ((URL?) -> Void)?) {
            self.onCompletion = onCompletion
        }

        public func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            onCompletion?(urls.first)
        }

        public func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            onCompletion?(nil)
        }
    }
}

