import Foundation
import Observation
import Photos
import PhotosUI
import SwiftUI

nonisolated enum PhotoLibraryAccessState: Equatable, Sendable {
    case full
    case limited
    case denied
    case restricted
    case notDetermined

    static var current: Self {
        switch PHPhotoLibrary.authorizationStatus(for: .readWrite) {
        case .authorized:
            .full
        case .limited:
            .limited
        case .denied:
            .denied
        case .restricted:
            .restricted
        case .notDetermined:
            .notDetermined
        @unknown default:
            .restricted
        }
    }
}

@MainActor
@Observable
final class LocalEvidenceMediaState {
    private let processor: any MediaProcessing
    private let fileStore: LocalMediaFileStore
    private var retryInput: MediaProcessingInput?

    var result: LocalMediaResult?
    var progress = 0.0
    var isProcessing = false
    var error: LocalMediaError?
    var libraryAccess = PhotoLibraryAccessState.current

    init(
        processor: any MediaProcessing = NativeImageProcessor(),
        fileStore: LocalMediaFileStore = LocalMediaFileStore()
    ) {
        self.processor = processor
        self.fileStore = fileStore
    }

    func importPhoto(_ item: PhotosPickerItem) async {
        do {
            libraryAccess = .current
            guard let data = try await item.loadTransferable(
                type: Data.self
            ) else {
                throw LocalMediaError.invalidImage
            }
            let mimeType = item.supportedContentTypes
                .compactMap(\.preferredMIMEType)
                .first
            await process(
                MediaProcessingInput(
                    data: data,
                    declaredMIMEType: mimeType,
                    source: .photoLibrary
                )
            )
        } catch is CancellationError {
            return
        } catch let mediaError as LocalMediaError {
            error = mediaError
        } catch {
            self.error = .processingFailed
        }
    }

    func importCameraData(_ data: Data) async {
        await process(
            MediaProcessingInput(
                data: data,
                declaredMIMEType: "image/jpeg",
                source: .camera
            )
        )
    }

    func retry() async {
        guard let retryInput else { return }
        await process(retryInput)
    }

    func remove() {
        guard let result else { return }
        try? fileStore.remove(url: result.localURL)
        try? fileStore.remove(url: result.thumbnailURL)
        self.result = nil
        progress = 0
        error = nil
        retryInput = nil
    }

    func cleanupOrphans(now: Date = Date()) async {
        let threshold = now.addingTimeInterval(-24 * 60 * 60)
        _ = try? fileStore.cleanOrphans(olderThan: threshold)
    }

    private func process(_ input: MediaProcessingInput) async {
        retryInput = input
        isProcessing = true
        defer { isProcessing = false }
        error = nil
        progress = 0.12
        do {
            let previous = result
            progress = 0.45
            let processed = try await processor.process(input)
            guard !Task.isCancelled else { return }
            progress = 1
            result = processed
            if let previous {
                try? fileStore.remove(url: previous.localURL)
                try? fileStore.remove(url: previous.thumbnailURL)
            }
        } catch is CancellationError {
            return
        } catch let mediaError as LocalMediaError {
            error = mediaError
            progress = 0
        } catch {
            self.error = .processingFailed
            progress = 0
        }
    }
}
