import AVFoundation
import SwiftUI
import UIKit
import Vision
import VisionKit

@MainActor
struct LocalQRScannerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("settings.hapticsEnabled")
    private var hapticsEnabled = true

    let onValidInvite: (String) -> Void

    @State private var scannerMode: ScannerMode = .checking
    @State private var validationMessage: String?

    var body: some View {
        NavigationStack {
            Group {
                switch scannerMode {
                case .checking:
                    ProgressView("Menyiapkan pemindai…")
                case .visionKit:
                    DataScannerQRCodeView(onScan: handleScan)
                        .ignoresSafeArea()
                case .avFoundation:
                    AVFoundationQRCodeView(onScan: handleScan)
                        .ignoresSafeArea()
                case .unavailable:
                    unsupportedView(
                        title: "Pemindai tidak tersedia",
                        message:
                            "Gunakan input kode manual untuk melanjutkan."
                    )
                case .permissionDenied:
                    unsupportedView(
                        title: "Akses kamera ditolak",
                        message:
                            "Izinkan kamera di Pengaturan, atau gunakan "
                            + "input kode manual."
                    )
                case .missingUsageDescription:
                    unsupportedView(
                        title: "Kamera belum dikonfigurasi",
                        message:
                            "Gunakan input kode manual pada build ini."
                    )
                }
            }
            .overlay(alignment: .bottom) {
                if let validationMessage {
                    Label(
                        validationMessage,
                        systemImage: "exclamationmark.triangle.fill"
                    )
                    .font(AppTypography.secondary)
                    .foregroundStyle(Color.white)
                    .padding(AppSpacing.medium)
                    .background(
                        Color.appDestructive,
                        in: RoundedRectangle(
                            cornerRadius: AppRadius.medium,
                            style: .continuous
                        )
                    )
                    .padding()
                    .accessibilityIdentifier("participant.qr.validation")
                }
            }
            .navigationTitle("Pindai QR undangan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Batal") { dismiss() }
                }
            }
        }
        .task { await prepareScanner() }
        .accessibilityIdentifier("participant.qr.scanner")
    }

    private func unsupportedView(
        title: String,
        message: String
    ) -> some View {
        ContentUnavailableView {
            Label(title, systemImage: "qrcode.viewfinder")
        } description: {
            Text(message)
        } actions: {
#if DEBUG
            Button("Gunakan QR demo lokal") {
                handleScan("msc-demo://join/MSC7HARI")
            }
            .accessibilityIdentifier("participant.qr.use-demo")
#endif
            Button("Masukkan kode manual") {
                dismiss()
            }
        }
    }

    private func prepareScanner() async {
#if targetEnvironment(simulator)
        scannerMode = .unavailable
#else
        guard Bundle.main.object(
            forInfoDictionaryKey: "NSCameraUsageDescription"
        ) != nil else {
            scannerMode = .missingUsageDescription
            return
        }
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            scannerMode = .unavailable
            return
        }
        let isAuthorized: Bool
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            isAuthorized = true
        case .notDetermined:
            isAuthorized = await AVCaptureDevice.requestAccess(for: .video)
        case .denied, .restricted:
            isAuthorized = false
        @unknown default:
            isAuthorized = false
        }
        guard isAuthorized else {
            scannerMode = .permissionDenied
            return
        }
        scannerMode = DataScannerViewController.isSupported
            && DataScannerViewController.isAvailable
            ? .visionKit
            : .avFoundation
#endif
    }

    private func handleScan(_ rawValue: String) {
        do {
            let payload = try LocalInvitePayloadParser()
                .payload(from: rawValue)
            validationMessage = nil
            if hapticsEnabled {
                UINotificationFeedbackGenerator()
                    .notificationOccurred(.success)
            }
            onValidInvite(payload.opaqueToken)
            dismiss()
        } catch let error as DomainError {
            validationMessage = ParticipantFormatting.fieldReason(error)
        } catch {
            validationMessage = "QR undangan tidak valid."
        }
    }
}

private extension LocalQRScannerSheet {
    enum ScannerMode: Equatable {
        case checking
        case visionKit
        case avFoundation
        case unavailable
        case permissionDenied
        case missingUsageDescription
    }
}

@available(iOS 16.0, *)
@MainActor
private struct DataScannerQRCodeView: UIViewControllerRepresentable {
    let onScan: (String) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onScan: onScan)
    }

    func makeUIViewController(
        context: Context
    ) -> DataScannerViewController {
        let controller = DataScannerViewController(
            recognizedDataTypes: [
                .barcode(symbologies: [.qr])
            ],
            qualityLevel: .balanced,
            recognizesMultipleItems: false,
            isHighFrameRateTrackingEnabled: false,
            isPinchToZoomEnabled: true,
            isGuidanceEnabled: true,
            isHighlightingEnabled: true
        )
        controller.delegate = context.coordinator
        try? controller.startScanning()
        return controller
    }

    func updateUIViewController(
        _ uiViewController: DataScannerViewController,
        context: Context
    ) {}

    static func dismantleUIViewController(
        _ uiViewController: DataScannerViewController,
        coordinator: Coordinator
    ) {
        uiViewController.stopScanning()
    }

    final class Coordinator:
        NSObject,
        DataScannerViewControllerDelegate
    {
        let onScan: (String) -> Void
        var hasDeliveredValue = false

        init(onScan: @escaping (String) -> Void) {
            self.onScan = onScan
        }

        func dataScanner(
            _ dataScanner: DataScannerViewController,
            didAdd addedItems: [RecognizedItem],
            allItems: [RecognizedItem]
        ) {
            guard !hasDeliveredValue else { return }
            for item in addedItems {
                if case .barcode(let barcode) = item,
                   let value = barcode.payloadStringValue {
                    hasDeliveredValue = true
                    onScan(value)
                    return
                }
            }
        }
    }
}

@MainActor
private struct AVFoundationQRCodeView: UIViewControllerRepresentable {
    let onScan: (String) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onScan: onScan)
    }

    func makeUIViewController(context: Context) -> QRPreviewController {
        let controller = QRPreviewController()
        context.coordinator.configure(controller)
        return controller
    }

    func updateUIViewController(
        _ uiViewController: QRPreviewController,
        context: Context
    ) {}

    static func dismantleUIViewController(
        _ uiViewController: QRPreviewController,
        coordinator: Coordinator
    ) {
        coordinator.stop()
    }

    final class Coordinator:
        NSObject,
        AVCaptureMetadataOutputObjectsDelegate
    {
        let onScan: (String) -> Void
        let capture = CaptureSessionController()
        var hasDeliveredValue = false

        init(onScan: @escaping (String) -> Void) {
            self.onScan = onScan
        }

        func configure(_ controller: QRPreviewController) {
            let session = capture.session
            guard let device = AVCaptureDevice.default(
                for: .video
            ),
            let input = try? AVCaptureDeviceInput(device: device),
            session.canAddInput(input) else {
                return
            }
            session.addInput(input)
            let output = AVCaptureMetadataOutput()
            guard session.canAddOutput(output) else { return }
            session.addOutput(output)
            output.setMetadataObjectsDelegate(self, queue: .main)
            output.metadataObjectTypes = [.qr]
            controller.previewLayer.session = session
            capture.start()
        }

        func stop() {
            capture.stop()
        }

        func metadataOutput(
            _ output: AVCaptureMetadataOutput,
            didOutput metadataObjects: [AVMetadataObject],
            from connection: AVCaptureConnection
        ) {
            guard !hasDeliveredValue,
                  let object = metadataObjects.first
                    as? AVMetadataMachineReadableCodeObject,
                  let value = object.stringValue else {
                return
            }
            hasDeliveredValue = true
            onScan(value)
        }
    }
}

nonisolated private final class CaptureSessionController:
    @unchecked Sendable
{
    let session = AVCaptureSession()
    private let queue = DispatchQueue(
        label: "id.mscbody.local-qr-capture",
        qos: .userInitiated
    )

    func start() {
        queue.async { [self] in
            guard !session.isRunning else { return }
            session.startRunning()
        }
    }

    func stop() {
        queue.async { [self] in
            guard session.isRunning else { return }
            session.stopRunning()
        }
    }
}

@MainActor
private final class QRPreviewController: UIViewController {
    let previewLayer = AVCaptureVideoPreviewLayer()

    override func viewDidLoad() {
        super.viewDidLoad()
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer.frame = view.bounds
    }
}
