import Foundation
import Testing
@testable import MSCBodyTransformation

@Suite("Fondasi aplikasi")
struct MSCBodyTransformationTests {
    @Test("Konfigurasi demo lokal menggunakan locale Indonesia")
    func localDemoConfigurationUsesIndonesianLocale() {
        let configuration = AppConfiguration.localDemo

        #expect(configuration.mode == .localDemo)
        #expect(configuration.localeIdentifier == "id-ID")
        #expect(!configuration.isEmailPasswordAuthenticationVisible)
    }

    @Test("Clock tetap mengembalikan tanggal deterministik")
    func fixedClockReturnsDeterministicDate() {
        let expectedDate = Date(timeIntervalSince1970: 1_785_028_400)
        let clock = FixedClock(now: expectedDate)

        #expect(clock.now() == expectedDate)
    }

    @Test("Generator identifier deterministik mengembalikan UUID yang sama")
    func deterministicIdentifierGeneratorReturnsSameIdentifier() {
        let expectedIdentifier = UUID(
            uuid: (
                0, 0, 0, 0,
                0, 0,
                0, 0,
                0, 0,
                0, 0, 0, 0, 0, 7
            )
        )
        let generator = DeterministicIdentifierGenerator(
            identifier: expectedIdentifier
        )

        #expect(generator.makeIdentifier() == expectedIdentifier)
        #expect(generator.makeIdentifier() == expectedIdentifier)
    }
}
