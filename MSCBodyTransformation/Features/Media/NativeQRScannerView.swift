import AVFoundation
import SwiftUI
import UIKit
import Vision

@MainActor
struct LocalQRScannerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("settings.hapticsEnabled")
    private var hapticsEnabled = true

    let demoPayload: String
    let onValidIdentifier: (String) -> Void

    @State private var scannerMode: ScannerMode = .checking
    @State private var validationMessage: String?

    init(
        demoPayload: String = "msc-demo://join/COACH-RAKA-7K9Q",
        onValidIdentifier: @escaping (String) -> Void
    ) {
        self.demoPayload = demoPayload
        self.onValidIdentifier = onValidIdentifier
    }

    var body: some View {
        NavigationStack {
            Group {
                switch scannerMode {
                case .checking:
                    ProgressView("Menyiapkan pemindai…")
                case .avFoundation:
                    scannerSurface {
                        AVFoundationQRCodeView(onScan: handleScan)
                    }
                case .unavailable:
                    unsupportedView(
                        title: "Pemindai tidak tersedia",
                        message:
                            "Pemindaian QR memerlukan perangkat dengan kamera."
                    )
                case .permissionDenied:
                    unsupportedView(
                        title: "Akses kamera ditolak",
                        message:
                            "Izinkan kamera di Pengaturan untuk memindai "
                            + "QR coach."
                    )
                case .missingUsageDescription:
                    unsupportedView(
                        title: "Kamera belum dikonfigurasi",
                        message:
                            "Pemindaian QR belum tersedia pada build ini."
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
            .navigationTitle("Pindai QR coach")
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
                handleScan(demoPayload)
            }
            .accessibilityIdentifier("participant.qr.use-demo")
#endif
            Button("Tutup") {
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
        // DataScanner dapat berpindah antar-lensa secara otomatis pada perangkat
        // multi-camera. Enrollment memakai kamera wide fisik agar framing QR
        // tetap stabil dan sesi capture tidak berulang kali dibangun ulang.
        scannerMode = .avFoundation
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
            onValidIdentifier(payload.opaqueToken)
            dismiss()
        } catch let error as DomainError {
            validationMessage = ParticipantFormatting.fieldReason(error)
        } catch {
            validationMessage = "QR coach tidak valid."
        }
    }
}

private extension LocalQRScannerSheet {
    enum ScannerMode: Equatable {
        case checking
        case avFoundation
        case unavailable
        case permissionDenied
        case missingUsageDescription
    }
}

private struct QRScannerOverlay: View {
    @Environment(\.accessibilityReduceMotion)
    private var reduceMotion

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
                        QRScannerScanLine(
                            travelDistance:
                                (frameSize / 2) - AppSpacing.large
                        )
                    }
                }
                .frame(width: frameSize, height: frameSize)
                .accessibilityHidden(true)

                Text("participant.qr.scan_message")
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
    }
}

private struct QRScannerScanLine: View {
    let travelDistance: CGFloat

    var body: some View {
        PhaseAnimator([-1.0, 1.0]) { position in
            Rectangle()
                .fill(Color.brandPrimary)
                .frame(height: 2)
                .shadow(
                    color: Color.brandPrimary.opacity(0.8),
                    radius: AppSpacing.xSmall
                )
                .padding(.horizontal, AppSpacing.medium)
                .offset(y: position * travelDistance)
        } animation: { _ in
            .easeInOut(duration: 1.8)
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
            session.sessionPreset = .hd1280x720

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

            do {
                try configureStableCapture(on: device)
            } catch {
                // Tetap lanjut dengan perangkat wide fisik. Konfigurasi default
                // masih dapat memindai QR tanpa beralih ke perangkat virtual.
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
            controller.onViewWillDisappear = { [weak capture] in
                capture?.stop()
            }
            capture.start()
        }

        private func configureStableCapture(
            on device: AVCaptureDevice
        ) throws {
            try device.lockForConfiguration()
            defer { device.unlockForConfiguration() }

            device.videoZoomFactor = 1
            device.isSubjectAreaChangeMonitoringEnabled = false
            if device.isFocusModeSupported(.continuousAutoFocus) {
                device.focusMode = .continuousAutoFocus
            }
            if device.isExposureModeSupported(.continuousAutoExposure) {
                device.exposureMode = .continuousAutoExposure
            }
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
    var onViewWillDisappear: (() -> Void)?

    override func viewDidLoad() {
        super.viewDidLoad()
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer.frame = view.bounds
    }

    override func viewWillDisappear(_ animated: Bool) {
        onViewWillDisappear?()
        super.viewWillDisappear(animated)
    }
}
