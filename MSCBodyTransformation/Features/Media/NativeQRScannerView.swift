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
                    scannerSurface {
                        DataScannerQRCodeView(onScan: handleScan)
                    }
                case .avFoundation:
                    scannerSurface {
                        AVFoundationQRCodeView(onScan: handleScan)
                    }
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

    private func scannerSurface<Scanner: View>(
        @ViewBuilder scanner: () -> Scanner
    ) -> some View {
        ZStack {
            scanner()
                .ignoresSafeArea()

            QRScannerOverlay()
        }
        .background(Color.black)
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

private struct QRScannerOverlay: View {
    @Environment(\.accessibilityReduceMotion)
    private var reduceMotion

    @State private var scanLinePosition: CGFloat = -1

    var body: some View {
        GeometryReader { proxy in
            let frameSize = min(
                max(proxy.size.width - (AppSpacing.xLarge * 2), 220),
                320
            )

            VStack(spacing: AppSpacing.large) {
                Spacer()

                ZStack {
                    RoundedRectangle(
                        cornerRadius: AppRadius.large,
                        style: .continuous
                    )
                    .fill(Color.black.opacity(0.08))

                    ScannerCornerShape()
                        .stroke(
                            Color.white,
                            style: StrokeStyle(
                                lineWidth: 5,
                                lineCap: .round,
                                lineJoin: .round
                            )
                        )

                    if !reduceMotion {
                        Rectangle()
                            .fill(Color.brandPrimary)
                            .frame(height: 2)
                            .shadow(
                                color: Color.brandPrimary.opacity(0.8),
                                radius: AppSpacing.xSmall
                            )
                            .padding(.horizontal, AppSpacing.medium)
                            .offset(
                                y: scanLinePosition
                                    * ((frameSize / 2) - AppSpacing.large)
                            )
                    }
                }
                .frame(width: frameSize, height: frameSize)
                .accessibilityHidden(true)

                Text("participant.invite.scan_message")
                    .font(.headline)
                    .foregroundStyle(Color.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, AppSpacing.xLarge)
                    .padding(.vertical, AppSpacing.small)
                    .background(
                        Color.black.opacity(0.62),
                        in: Capsule()
                    )

                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.black.opacity(0.18))
        }
        .allowsHitTesting(false)
        .onAppear {
            guard !reduceMotion else { return }
            scanLinePosition = -1
            withAnimation(
                .easeInOut(duration: 1.8)
                    .repeatForever(autoreverses: true)
            ) {
                scanLinePosition = 1
            }
        }
    }
}

private struct ScannerCornerShape: Shape {
    func path(in rect: CGRect) -> Path {
        let cornerLength = min(rect.width, rect.height) * 0.22
        var path = Path()

        path.move(to: CGPoint(x: 0, y: cornerLength))
        path.addLine(to: CGPoint(x: 0, y: 0))
        path.addLine(to: CGPoint(x: cornerLength, y: 0))

        path.move(to: CGPoint(x: rect.maxX - cornerLength, y: 0))
        path.addLine(to: CGPoint(x: rect.maxX, y: 0))
        path.addLine(to: CGPoint(x: rect.maxX, y: cornerLength))

        path.move(to: CGPoint(x: rect.maxX, y: rect.maxY - cornerLength))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(
            to: CGPoint(x: rect.maxX - cornerLength, y: rect.maxY)
        )

        path.move(
            to: CGPoint(x: cornerLength, y: rect.maxY)
        )
        path.addLine(to: CGPoint(x: 0, y: rect.maxY))
        path.addLine(
            to: CGPoint(x: 0, y: rect.maxY - cornerLength)
        )

        return path
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
    ) {
        guard !uiViewController.isScanning else { return }
        try? uiViewController.startScanning()
    }

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
            session.beginConfiguration()
            session.sessionPreset = .high

            guard let device = AVCaptureDevice.default(
                .builtInWideAngleCamera,
                for: .video,
                position: .back
            ),
            let input = try? AVCaptureDeviceInput(device: device),
            session.canAddInput(input) else {
                session.commitConfiguration()
                return
            }
            session.addInput(input)
            let output = AVCaptureMetadataOutput()
            guard session.canAddOutput(output) else {
                session.commitConfiguration()
                return
            }
            session.addOutput(output)
            output.setMetadataObjectsDelegate(self, queue: .main)
            output.metadataObjectTypes = [.qr]
            session.commitConfiguration()

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
