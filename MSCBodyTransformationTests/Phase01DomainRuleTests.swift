import Foundation
import Testing
@testable import MSCBodyTransformation

@Suite("Aturan domain Phase 01")
struct Phase01DomainRuleTests {
    @Test("Progress mengabaikan submission ditolak dan duplikat")
    func progressIgnoresRejectedAndDuplicateSubmissions() {
        let enrollmentID = UUID()
        let acceptedStepID = UUID()
        let rejectedStepID = UUID()
        let date = Date(timeIntervalSince1970: 1_785_028_400)
        let submissions = [
            makeSubmission(
                id: UUID(),
                enrollmentID: enrollmentID,
                stepID: acceptedStepID,
                status: .approved,
                date: date
            ),
            makeSubmission(
                id: UUID(),
                enrollmentID: enrollmentID,
                stepID: acceptedStepID,
                status: .pending,
                date: date
            ),
            makeSubmission(
                id: UUID(),
                enrollmentID: enrollmentID,
                stepID: rejectedStepID,
                status: .rejected,
                date: date
            )
        ]

        let result = ProgramProgressCalculator().percentage(
            totalStepCount: 5,
            submissions: submissions
        )

        #expect(result == 20)
    }

    @Test("Akses hari menghormati hidden, read-only, lalu jadwal")
    func visibilityRespectsModeAndSchedule() {
        let now = Date(timeIntervalSince1970: 1_785_028_400)
        let calculator = ProgramDayAccessCalculator()
        let hidden = makeDay(date: now, visibility: .hidden)
        let readOnly = makeDay(date: now, visibility: .readOnly)
        let current = makeDay(date: now, visibility: .standard)
        let future = makeDay(
            date: now.addingTimeInterval(86_400),
            visibility: .standard
        )
        let past = makeDay(
            date: now.addingTimeInterval(-86_400),
            visibility: .standard
        )

        #expect(
            calculator.access(
                for: hidden,
                now: now,
                timeZoneIdentifier: "Asia/Makassar"
            ) == .hidden
        )
        #expect(
            calculator.access(
                for: readOnly,
                now: now,
                timeZoneIdentifier: "Asia/Makassar"
            ) == .readOnly
        )
        #expect(
            calculator.access(
                for: current,
                now: now,
                timeZoneIdentifier: "Asia/Makassar"
            ) == .available
        )
        #expect(
            calculator.access(
                for: future,
                now: now,
                timeZoneIdentifier: "Asia/Makassar"
            ) == .locked
        )
        #expect(
            calculator.access(
                for: past,
                now: now,
                timeZoneIdentifier: "Asia/Makassar"
            ) == .available
        )
    }

    @Test("Kenaikan berat tidak menghasilkan poin negatif")
    func weightGainDoesNotProduceNegativePoints() {
        let calculator = WeightScoreCalculator()

        #expect(
            calculator.calculate(
                initialWeightKilograms: Decimal(string: "75.0")!,
                finalWeightKilograms: Decimal(string: "76.5")!,
                pointsPerKilogram: 10
            ) == 0
        )
        #expect(
            calculator.calculate(
                initialWeightKilograms: Decimal(string: "75.0")!,
                finalWeightKilograms: Decimal(string: "73.25")!,
                pointsPerKilogram: 10
            ) == 18
        )
    }

    @Test("Error domain dipetakan ke copy key yang dapat dilokalkan")
    func domainErrorsMapToLocalizableKeys() {
        let message = DomainErrorMessageMapper.message(
            for: .permissionDenied
        )

        #expect(message.titleKey == "error.permission.title")
        #expect(message.messageKey == "error.permission.message")
    }

    private func makeSubmission(
        id: UUID,
        enrollmentID: UUID,
        stepID: UUID,
        status: SubmissionStatus,
        date: Date
    ) -> StepSubmission {
        StepSubmission(
            id: id,
            enrollmentID: enrollmentID,
            stepID: stepID,
            status: status,
            submittedAt: date,
            reviewedAt: nil,
            reviewerID: nil,
            reviewNote: nil
        )
    }

    private func makeDay(
        date: Date,
        visibility: ProgramDayVisibilityMode
    ) -> ProgramDay {
        ProgramDay(
            id: UUID(),
            programID: UUID(),
            dayNumber: 1,
            title: "Hari uji",
            scheduledDate: date,
            visibilityMode: visibility,
            steps: []
        )
    }
}
