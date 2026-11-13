import SwiftUI
import UIKit
import AVFoundation

/// Native iOS camera capture interface for receipts with AVFoundation authorization checks.
/// Wraps `UIImagePickerController` configured for photo capture and supports orientation adjustments.
public struct ReceiptCameraView: UIViewControllerRepresentable {
    public let onImageCaptured: (UIImage) -> Void
    public let onCancel: () -> Void

    public init(
        onImageCaptured: @escaping (UIImage) -> Void,
        onCancel: @escaping () -> Void
    ) {
        self.onImageCaptured = onImageCaptured
        self.onCancel = onCancel
    }

    public func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    public func makeUIViewController(context: Context) -> UIViewController {
        let status = AVCaptureDevice.authorizationStatus(for: .video)

        switch status {
        case .authorized:
            let picker = UIImagePickerController()
            picker.sourceType = .camera
            picker.cameraCaptureMode = .photo
            picker.cameraDevice = .rear
            picker.cameraFlashMode = .auto
            picker.delegate = context.coordinator
            return picker

        case .notDetermined:
            let container = UIViewController()
            container.view.backgroundColor = .black
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    if granted {
                        // Recreate when permission granted
                        context.coordinator.parent.onCancel()
                    }
                }
            }
            return container

        case .denied, .restricted:
            return UIHostingController(
                rootView: CameraPermissionDeniedView(onCancel: onCancel)
            )

        @unknown default:
            return UIHostingController(
                rootView: CameraPermissionDeniedView(onCancel: onCancel)
            )
        }
    }

    public func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}

    public final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ReceiptCameraView

        init(_ parent: ReceiptCameraView) {
            self.parent = parent
        }

        public func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            if let image = info[.originalImage] as? UIImage {
                // Normalize orientation before passing
                let normalized = image.normalizedOrientation()
                parent.onImageCaptured(normalized)
            } else {
                parent.onCancel()
            }
        }

        public func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.onCancel()
        }
    }
}

/// Fallback view presented when camera permissions have been denied or restricted.
struct CameraPermissionDeniedView: View {
    let onCancel: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "camera.fill")
                .font(.system(size: 56))
                .foregroundStyle(LeafTheme.expenseCoral)

            Text("Camera Access Required")
                .font(LeafTypography.titleLarge)
                .foregroundStyle(.white)

            Text("Leaf needs access to your device camera to scan physical receipts and extract expense details on-device.")
                .font(LeafTypography.bodyMedium)
                .foregroundStyle(Color.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Button(action: {
                if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settingsURL)
                }
            }) {
                Text("Open iOS Settings")
                    .font(LeafTypography.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(LeafTheme.brandEmerald)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .padding(.horizontal, 32)
            .padding(.top, 8)

            Button("Cancel", action: onCancel)
                .font(LeafTypography.bodyMedium)
                .foregroundStyle(Color.gray)
                .padding(.top, 4)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.ignoresSafeArea())
    }
}

// MARK: - UIImage Orientation Helper

extension UIImage {
    /// Fixes image orientation so that the pixel buffer aligns with `.up`.
    func normalizedOrientation() -> UIImage {
        if imageOrientation == .up { return self }

        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        draw(in: CGRect(origin: .zero, size: size))
        let normalized = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return normalized ?? self
    }
}

