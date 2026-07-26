import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

nonisolated struct NativeImageProcessor: MediaProcessing, Sendable {
    let configuration: MediaProcessingConfiguration
    let fileStore: LocalMediaFileStore

    init(
        configuration: MediaProcessingConfiguration = .evidence,
        fileStore: LocalMediaFileStore = LocalMediaFileStore()
    ) {
        self.configuration = configuration
        self.fileStore = fileStore
    }

    func process(
        _ input: MediaProcessingInput
    ) async throws -> LocalMediaResult {
        try Task.checkCancellation()
        try MediaInputValidator.validate(
            mimeType: input.declaredMIMEType,
            byteCount: input.data.count,
            maximumBytes: configuration.maximumInputBytes
        )

        guard let source = CGImageSourceCreateWithData(
            input.data as CFData,
            nil
        ) else {
            throw LocalMediaError.invalidImage
        }
        try Task.checkCancellation()

        guard let sourceType = CGImageSourceGetType(source),
              let sourceUTType = UTType(sourceType as String),
              let detectedMIMEType = sourceUTType.preferredMIMEType,
              MediaInputValidator.supportedImageMIMETypes.contains(
                  detectedMIMEType
              ) else {
            throw LocalMediaError.unsupportedMIMEType
        }

        let processedImage = try thumbnail(
            source: source,
            maximumDimension: configuration.maximumDimension
        )
        try Task.checkCancellation()
        let previewImage = try thumbnail(
            source: source,
            maximumDimension: configuration.thumbnailDimension
        )

        let identifier = UUID()
        let outputURL = fileStore.url(
            identifier: identifier,
            suffix: "evidence",
            extension: "jpg"
        )
        let thumbnailURL = fileStore.url(
            identifier: identifier,
            suffix: "thumbnail",
            extension: "jpg"
        )

        do {
            try fileStore.prepareDirectory()
            try writeJPEG(
                processedImage,
                to: outputURL,
                quality: configuration.compressionQuality
            )
            try Task.checkCancellation()
            try writeJPEG(
                previewImage,
                to: thumbnailURL,
                quality: 0.76
            )
            try fileStore.protect(url: outputURL)
            try fileStore.protect(url: thumbnailURL)
        } catch {
            try? fileStore.remove(url: outputURL)
            try? fileStore.remove(url: thumbnailURL)
            if error is CancellationError {
                throw error
            }
            if let mediaError = error as? LocalMediaError {
                throw mediaError
            }
            throw LocalMediaError.processingFailed
        }

        let values = try outputURL.resourceValues(
            forKeys: [.fileSizeKey]
        )
        return LocalMediaResult(
            id: identifier,
            localURL: outputURL,
            thumbnailURL: thumbnailURL,
            byteSize: values.fileSize ?? 0,
            width: processedImage.width,
            height: processedImage.height,
            mimeType: "image/jpeg",
            source: input.source
        )
    }

    private func thumbnail(
        source: CGImageSource,
        maximumDimension: Int
    ) throws -> CGImage {
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maximumDimension,
            kCGImageSourceShouldCacheImmediately: true
        ]
        guard let image = CGImageSourceCreateThumbnailAtIndex(
            source,
            0,
            options as CFDictionary
        ) else {
            throw LocalMediaError.invalidImage
        }
        return image
    }

    private func writeJPEG(
        _ image: CGImage,
        to url: URL,
        quality: Double
    ) throws {
        guard let destination = CGImageDestinationCreateWithURL(
            url as CFURL,
            UTType.jpeg.identifier as CFString,
            1,
            nil
        ) else {
            throw LocalMediaError.processingFailed
        }
        let properties: [CFString: Any] = [
            kCGImageDestinationLossyCompressionQuality: quality,
            kCGImagePropertyOrientation: 1
        ]
        CGImageDestinationAddImage(
            destination,
            image,
            properties as CFDictionary
        )
        guard CGImageDestinationFinalize(destination) else {
            throw LocalMediaError.processingFailed
        }
    }
}

nonisolated struct LocalMediaFileStore: Sendable {
    let directory: URL

    init(directory: URL? = nil) {
        self.directory = directory
            ?? FileManager.default.temporaryDirectory
                .appendingPathComponent(
                    "MSCBodyTransformationLocalMedia",
                    isDirectory: true
                )
    }

    func url(
        identifier: UUID,
        suffix: String,
        extension fileExtension: String
    ) -> URL {
        directory.appendingPathComponent(
            "\(identifier.uuidString)-\(suffix).\(fileExtension)",
            isDirectory: false
        )
    }

    func protect(url: URL) throws {
        try FileManager.default.createDirectory(
            at: directory,
            withIntermediateDirectories: true,
            attributes: [
                .protectionKey:
                    FileProtectionType.completeUntilFirstUserAuthentication
            ]
        )
        try FileManager.default.setAttributes(
            [
                .protectionKey:
                    FileProtectionType.completeUntilFirstUserAuthentication
            ],
            ofItemAtPath: url.path
        )
        var values = URLResourceValues()
        values.isExcludedFromBackup = true
        var mutableURL = url
        try mutableURL.setResourceValues(values)
    }

    func prepareDirectory() throws {
        try FileManager.default.createDirectory(
            at: directory,
            withIntermediateDirectories: true,
            attributes: [
                .protectionKey:
                    FileProtectionType.completeUntilFirstUserAuthentication
            ]
        )
    }

    func remove(url: URL) throws {
        guard FileManager.default.fileExists(atPath: url.path) else {
            return
        }
        try FileManager.default.removeItem(at: url)
    }

    func cleanOrphans(olderThan date: Date) throws -> Int {
        guard FileManager.default.fileExists(atPath: directory.path) else {
            return 0
        }
        let urls = try FileManager.default.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: [.contentModificationDateKey],
            options: [.skipsHiddenFiles]
        )
        var removed = 0
        for url in urls {
            let modifiedAt = try url.resourceValues(
                forKeys: [.contentModificationDateKey]
            ).contentModificationDate ?? .distantPast
            if modifiedAt < date {
                try remove(url: url)
                removed += 1
            }
        }
        return removed
    }
}
