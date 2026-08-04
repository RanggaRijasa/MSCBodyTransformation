import AVFoundation
import AVKit
import Combine
import PhotosUI
import SwiftUI
import UIKit

struct LocalMediaThumbnailView: View {
    let result: LocalMediaResult

    var body: some View {
        Group {
            if let image = UIImage(
                contentsOfFile: result.thumbnailURL.path
            ) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                ContentUnavailableView(
                    "Pratinjau tidak tersedia",
                    systemImage: "photo"
                )
            }
        }
        .frame(maxWidth: .infinity, minHeight: 160, maxHeight: 220)
        .clipShape(
            RoundedRectangle(
                cornerRadius: AppRadius.medium,
                style: .continuous
            )
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Bukti foto terlampir")
        .accessibilityValue(
            "\(result.width) kali \(result.height) piksel"
        )
        .accessibilityIdentifier("participant.evidence.thumbnail")
    }
}

struct LocalVideoPlayerView: View {
    let resourceName: String
    let textAlternative: String
    let configuration: ProgramVideoCompletionConfiguration?
    @Binding var completionPercentage: Int

    @State private var player: AVPlayer?
    @State private var isUnavailable = false
    private let progressTimer = Timer.publish(
        every: 0.5,
        on: .main,
        in: .common
    ).autoconnect()

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.small) {
            if let player {
                VideoPlayer(player: player)
                    .frame(minHeight: 210)
                    .clipShape(
                        RoundedRectangle(
                            cornerRadius: AppRadius.medium,
                            style: .continuous
                        )
                    )
                    .accessibilityLabel("Video petunjuk lokal")
                    .accessibilityHint(
                        configuration?.isAutoplayEnabled == true
                            ? "Video diputar otomatis dan dapat dijeda."
                            : "Gunakan kontrol pemutar untuk memulai."
                    )
                    .accessibilityIdentifier("participant.video.player")
            } else if isUnavailable {
                ContentUnavailableView(
                    "Video tidak tersedia",
                    systemImage: "play.slash",
                    description: Text(textAlternative)
                )
                .frame(minHeight: 210)
            } else {
                ProgressView("Menyiapkan video lokal…")
                    .frame(maxWidth: .infinity, minHeight: 210)
            }
            Label(textAlternative, systemImage: "captions.bubble")
                .font(AppTypography.secondary)
                .foregroundStyle(Color.appSecondaryText)
            if configuration?.isRequiredToWatch == true {
                ProgressView(
                    value: Double(completionPercentage),
                    total: 100
                ) {
                    Text("Progres tontonan")
                } currentValueLabel: {
                    Text("\(completionPercentage)%")
                        .monospacedDigit()
                }
            }
        }
        .task(id: resourceName) {
            preparePlayer()
        }
        .onDisappear {
            persistCurrentPosition()
            player?.pause()
        }
        .onReceive(progressTimer) { _ in
            updateProgress()
        }
    }

    private func preparePlayer() {
        guard let url = Bundle.main.url(
            forResource: resourceName,
            withExtension: "mp4"
        ) else {
            isUnavailable = true
            player = nil
            return
        }
        let player = AVPlayer(url: url)
        let savedPosition = UserDefaults.standard.double(
            forKey: resumeKey
        )
        if savedPosition > 0 {
            player.seek(
                to: CMTime(
                    seconds: savedPosition,
                    preferredTimescale: 600
                )
            )
        }
        self.player = player
        isUnavailable = false
        if configuration?.isAutoplayEnabled == true {
            player.play()
        }
    }

    private var resumeKey: String {
        "participant.video.resume.\(resourceName)"
    }

    private func updateProgress() {
        guard let player else { return }
        let currentSeconds = player.currentTime().seconds
        let durationSeconds = player.currentItem?.duration.seconds ?? 0
        guard currentSeconds.isFinite,
              durationSeconds.isFinite,
              durationSeconds > 0 else {
            return
        }
        completionPercentage = min(
            max(Int((currentSeconds / durationSeconds * 100).rounded()), 0),
            100
        )
        persistCurrentPosition()
    }

    private func persistCurrentPosition() {
        guard let seconds = player?.currentTime().seconds,
              seconds.isFinite,
              seconds >= 0 else {
            return
        }
        UserDefaults.standard.set(seconds, forKey: resumeKey)
    }
}

@MainActor
struct NativeShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(
        context: Context
    ) -> UIActivityViewController {
        UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: nil
        )
    }

    func updateUIViewController(
        _ uiViewController: UIActivityViewController,
        context: Context
    ) {}
}

@MainActor
struct NativeCameraCaptureSheet: View {
    @Environment(\.dismiss) private var dismiss
    let onCapture: (Data) -> Void

    @State private var state: CameraState = .checking

    var body: some View {
        NavigationStack {
            Group {
                switch state {
                case .checking:
                    ProgressView("Memeriksa kamera…")
                case .ready:
                    SystemCameraPicker { data in
                        onCapture(data)
                        dismiss()
                    } onCancel: {
                        dismiss()
                    }
                    .ignoresSafeArea()
                case .unavailable:
                    cameraUnavailableView(
                        title: "Kamera tidak tersedia",
                        message: "Gunakan pemilih Foto pada layar sebelumnya."
                    )
                case .denied:
                    cameraUnavailableView(
                        title: "Akses kamera ditolak",
                        message:
                            "Izinkan kamera di Pengaturan, atau gunakan "
                            + "pemilih foto."
                    )
                case .missingUsageDescription:
                    cameraUnavailableView(
                        title: "Kamera belum dikonfigurasi",
                        message:
                            "Tambahkan deskripsi penggunaan kamera pada "
                            + "target aplikasi sebelum uji perangkat fisik."
                    )
                }
            }
            .navigationTitle("Ambil foto")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if state != .ready {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Tutup") { dismiss() }
                    }
                }
            }
        }
        .task { await prepare() }
        .accessibilityIdentifier("participant.camera.sheet")
    }

    private func cameraUnavailableView(
        title: String,
        message: String
    ) -> some View {
        ContentUnavailableView {
            Label(title, systemImage: "camera.fill")
        } description: {
            Text(message)
        } actions: {
            Button("Pilih alternatif") { dismiss() }
        }
    }

    private func prepare() async {
#if targetEnvironment(simulator)
        state = .unavailable
#else
        guard Bundle.main.object(
            forInfoDictionaryKey: "NSCameraUsageDescription"
        ) != nil else {
            state = .missingUsageDescription
            return
        }
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            state = .unavailable
            return
        }
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            state = .ready
        case .notDetermined:
            state = await AVCaptureDevice.requestAccess(for: .video)
                ? .ready
                : .denied
        case .denied, .restricted:
            state = .denied
        @unknown default:
            state = .unavailable
        }
#endif
    }
}

private extension NativeCameraCaptureSheet {
    enum CameraState: Equatable {
        case checking
        case ready
        case unavailable
        case denied
        case missingUsageDescription
    }
}

@MainActor
private struct SystemCameraPicker: UIViewControllerRepresentable {
    let onCapture: (Data) -> Void
    let onCancel: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onCapture: onCapture, onCancel: onCancel)
    }

    func makeUIViewController(
        context: Context
    ) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.cameraCaptureMode = .photo
        picker.delegate = context.coordinator
        picker.accessibilityLabel = "Kamera bukti"
        return picker
    }

    func updateUIViewController(
        _ uiViewController: UIImagePickerController,
        context: Context
    ) {}

    final class Coordinator:
        NSObject,
        UINavigationControllerDelegate,
        UIImagePickerControllerDelegate
    {
        let onCapture: (Data) -> Void
        let onCancel: () -> Void

        init(
            onCapture: @escaping (Data) -> Void,
            onCancel: @escaping () -> Void
        ) {
            self.onCapture = onCapture
            self.onCancel = onCancel
        }

        func imagePickerControllerDidCancel(
            _ picker: UIImagePickerController
        ) {
            onCancel()
        }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info:
                [UIImagePickerController.InfoKey: Any]
        ) {
            guard let image = info[.originalImage] as? UIImage,
                  let data = image.jpegData(compressionQuality: 0.95) else {
                onCancel()
                return
            }
            onCapture(data)
        }
    }
}
