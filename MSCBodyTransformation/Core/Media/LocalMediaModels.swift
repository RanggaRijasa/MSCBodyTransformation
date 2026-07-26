import Foundation

nonisolated enum LocalMediaSource: String, Codable, Sendable {
    case photoLibrary = "photo_library"
    case camera
    case bundledSample = "bundled_sample"
}

nonisolated struct MediaProcessingInput: Sendable {
    let data: Data
    let declaredMIMEType: String?
    let source: LocalMediaSource
}

nonisolated struct MediaProcessingConfiguration: Sendable {
    let maximumDimension: Int
    let thumbnailDimension: Int
    let maximumInputBytes: Int
    let compressionQuality: Double

    static let evidence = Self(
        maximumDimension: 1_600,
        thumbnailDimension: 320,
        maximumInputBytes: 20 * 1_024 * 1_024,
        compressionQuality: 0.82
    )
}

nonisolated struct LocalMediaResult:
    Codable,
    Equatable,
    Identifiable,
    Sendable
{
    let id: UUID
    let localURL: URL
    let thumbnailURL: URL
    let byteSize: Int
    let width: Int
    let height: Int
    let mimeType: String
    let source: LocalMediaSource
}

nonisolated enum LocalMediaError: Error, Equatable, Sendable {
    case unsupportedMIMEType
    case inputTooLarge(maximumBytes: Int)
    case invalidImage
    case processingFailed
    case permissionDenied
    case cameraUnavailable
    case cameraUsageDescriptionMissing
}

nonisolated protocol MediaProcessing: Sendable {
    func process(
        _ input: MediaProcessingInput
    ) async throws -> LocalMediaResult
}

nonisolated struct ImageDimensionDecision: Equatable, Sendable {
    let width: Int
    let height: Int

    static func resized(
        originalWidth: Int,
        originalHeight: Int,
        maximumDimension: Int
    ) -> Self {
        guard originalWidth > 0,
              originalHeight > 0,
              maximumDimension > 0 else {
            return Self(width: 0, height: 0)
        }
        let largest = max(originalWidth, originalHeight)
        guard largest > maximumDimension else {
            return Self(width: originalWidth, height: originalHeight)
        }
        let scale = Double(maximumDimension) / Double(largest)
        return Self(
            width: max(Int((Double(originalWidth) * scale).rounded()), 1),
            height: max(Int((Double(originalHeight) * scale).rounded()), 1)
        )
    }
}

nonisolated enum MediaInputValidator {
    static let supportedImageMIMETypes: Set<String> = [
        "image/jpeg",
        "image/png",
        "image/heic",
        "image/heif"
    ]

    static func validate(
        mimeType: String?,
        byteCount: Int,
        maximumBytes: Int
    ) throws {
        guard byteCount <= maximumBytes else {
            throw LocalMediaError.inputTooLarge(
                maximumBytes: maximumBytes
            )
        }
        if let mimeType,
           !supportedImageMIMETypes.contains(mimeType.lowercased()) {
            throw LocalMediaError.unsupportedMIMEType
        }
    }
}

nonisolated enum MediaMetadataPolicy {
    static let locationMetadataKeys: Set<String> = [
        "{GPS}",
        "GPS",
        "kCGImagePropertyGPSDictionary",
        "latitude",
        "longitude",
        "location"
    ]

    static func requiresLocationRemoval(
        metadataKeys: Set<String>
    ) -> Bool {
        !metadataKeys.intersection(locationMetadataKeys).isEmpty
    }
}
