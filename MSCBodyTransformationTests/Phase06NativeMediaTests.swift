import Foundation
import ImageIO
import Testing
import UIKit
import UniformTypeIdentifiers
@testable import MSCBodyTransformation

@Suite("Media dan QR lokal Phase 06")
struct Phase06NativeMediaTests {
    @Test("Dimensi gambar diperkecil tanpa mengubah rasio")
    func imageDimensionDecision() {
        #expect(
            ImageDimensionDecision.resized(
                originalWidth: 4_000,
                originalHeight: 3_000,
                maximumDimension: 1_600
            ) == ImageDimensionDecision(width: 1_600, height: 1_200)
        )
        #expect(
            ImageDimensionDecision.resized(
                originalWidth: 800,
                originalHeight: 600,
                maximumDimension: 1_600
            ) == ImageDimensionDecision(width: 800, height: 600)
        )
    }

    @Test("Validator menerima MIME gambar dan menolak format lain")
    func mimeValidation() throws {
        try MediaInputValidator.validate(
            mimeType: "image/heic",
            byteCount: 1_024,
            maximumBytes: 2_048
        )
        #expect(throws: LocalMediaError.unsupportedMIMEType) {
            try MediaInputValidator.validate(
                mimeType: "application/pdf",
                byteCount: 1_024,
                maximumBytes: 2_048
            )
        }
    }

    @Test("Validator menolak file yang melewati batas ukuran")
    func fileSizeLimit() {
        #expect(
            throws: LocalMediaError.inputTooLarge(
                maximumBytes: 1_024
            )
        ) {
            try MediaInputValidator.validate(
                mimeType: "image/jpeg",
                byteCount: 1_025,
                maximumBytes: 1_024
            )
        }
    }

    @Test("Kebijakan metadata mengenali data lokasi")
    func metadataRemovalDecision() {
        #expect(
            MediaMetadataPolicy.requiresLocationRemoval(
                metadataKeys: ["{GPS}", "{Exif}"]
            )
        )
        #expect(
            !MediaMetadataPolicy.requiresLocationRemoval(
                metadataKeys: ["{Exif}", "{TIFF}"]
            )
        )
    }

    @Test("Pipeline menulis JPEG baru tanpa metadata lokasi")
    func imagePipelineRemovesLocationMetadata() async throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(
                "phase06-pipeline-\(UUID().uuidString)",
                isDirectory: true
            )
        defer {
            try? FileManager.default.removeItem(at: directory)
        }
        let renderer = UIGraphicsImageRenderer(
            size: CGSize(width: 100, height: 50)
        )
        let image = renderer.image { context in
            UIColor.systemRed.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 100, height: 50))
        }
        let sourceData = NSMutableData()
        let destination = try #require(
            CGImageDestinationCreateWithData(
                sourceData,
                UTType.jpeg.identifier as CFString,
                1,
                nil
            )
        )
        let sourceImage = try #require(image.cgImage)
        let properties: [CFString: Any] = [
            kCGImagePropertyGPSDictionary: [
                kCGImagePropertyGPSLatitude: 1.23,
                kCGImagePropertyGPSLongitude: 4.56
            ]
        ]
        CGImageDestinationAddImage(
            destination,
            sourceImage,
            properties as CFDictionary
        )
        #expect(CGImageDestinationFinalize(destination))

        let result = try await NativeImageProcessor(
            fileStore: LocalMediaFileStore(directory: directory)
        ).process(
            MediaProcessingInput(
                data: sourceData as Data,
                declaredMIMEType: "image/jpeg",
                source: .bundledSample
            )
        )
        let outputSource = try #require(
            CGImageSourceCreateWithURL(
                result.localURL as CFURL,
                nil
            )
        )
        let outputProperties = try #require(
            CGImageSourceCopyPropertiesAtIndex(
                outputSource,
                0,
                nil
            ) as? [CFString: Any]
        )

        #expect(outputProperties[kCGImagePropertyGPSDictionary] == nil)
        #expect(result.mimeType == "image/jpeg")
        #expect(result.width == sourceImage.width)
        #expect(result.height == sourceImage.height)
        #expect(result.byteSize > 0)
    }

    @Test("Parser QR mengembalikan token opaque yang dinormalisasi")
    func qrPayloadParser() throws {
        let payload = try LocalInvitePayloadParser().payload(
            from: "msc-demo://join/coach-raka-7k9q"
        )

        #expect(payload.opaqueToken == "COACH-RAKA-7K9Q")
    }

    @Test("Payload QR memetakan identifier opaque ke Coach")
    func qrPayloadMapsOpaqueIdentifierToCoach() throws {
        let seed = try MockSeedData.load()
        let payload = try LocalInvitePayloadParser().payload(
            from: "msc-demo://join/coach-raka-7k9q"
        )
        let coach = try #require(
            seed.coachProfiles.first {
                $0.enrollmentIdentifier == payload.opaqueToken
            }
        )

        #expect(coach.displayName == "Coach Raka")
        #expect(coach.isApproved)
    }

    @Test("Parser hanya menerima scheme dan host lokal yang disetujui")
    func approvedSchemeAndHost() {
        #expect(throws: DomainError.self) {
            try LocalInvitePayloadParser().payload(
                from: "https://join/MSC7HARI"
            )
        }
        #expect(throws: DomainError.self) {
            try LocalInvitePayloadParser().payload(
                from: "msc-demo://admin/MSC7HARI"
            )
        }
    }

    @Test("Parser menolak URL arbitrer dan route tambahan")
    func invalidQRRejection() {
        #expect(throws: DomainError.self) {
            try LocalInvitePayloadParser().payload(
                from: "https://contoh.invalid/ubah-role/admin"
            )
        }
        #expect(throws: DomainError.self) {
            try LocalInvitePayloadParser().payload(
                from: "msc-demo://join/MSC7HARI/admin"
            )
        }
    }

    @Test("Pertanyaan foto wajib tidak dapat diselesaikan kosong")
    func evidenceRequirementValidation() throws {
        let program = try #require(
            MockSeedData.load().programs.first {
                $0.status == .active
            }
        )
        let question = try #require(
            program.days.flatMap(\.steps).first {
                $0.content?.questions.contains {
                    $0.kind == .photoUpload
                } == true
            }?.content?.questions.first { $0.kind == .photoUpload }
        )

        #expect(throws: DomainError.self) {
            try StepAnswerValidator().validate(
                questions: [question],
                answers: []
            )
        }
    }

    @Test("Pembersihan hanya menghapus file demo yang sudah yatim")
    func temporaryFileCleanup() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(
                "phase06-test-\(UUID().uuidString)",
                isDirectory: true
            )
        defer {
            try? FileManager.default.removeItem(at: directory)
        }
        let store = LocalMediaFileStore(directory: directory)
        try store.prepareDirectory()
        let oldURL = store.url(
            identifier: UUID(),
            suffix: "old",
            extension: "jpg"
        )
        let recentURL = store.url(
            identifier: UUID(),
            suffix: "recent",
            extension: "jpg"
        )
        try Data([0x01]).write(to: oldURL)
        try Data([0x02]).write(to: recentURL)
        let now = Date()
        try FileManager.default.setAttributes(
            [.modificationDate: now.addingTimeInterval(-7_200)],
            ofItemAtPath: oldURL.path
        )
        try FileManager.default.setAttributes(
            [.modificationDate: now],
            ofItemAtPath: recentURL.path
        )

        let removed = try store.cleanOrphans(
            olderThan: now.addingTimeInterval(-3_600)
        )

        #expect(removed == 1)
        #expect(!FileManager.default.fileExists(atPath: oldURL.path))
        #expect(FileManager.default.fileExists(atPath: recentURL.path))
    }
}
