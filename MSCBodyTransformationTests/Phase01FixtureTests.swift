import Foundation
import Testing
@testable import MSCBodyTransformation

@Suite("Fixture Phase 01")
struct Phase01FixtureTests {
    @Test("Seluruh fixture lokal dapat dimuat")
    func allLocalFixturesLoad() throws {
        let seed = try MockSeedData.load()

        #expect(seed.users.count == 18)
        #expect(seed.participantProfiles.count == 13)
        #expect(seed.coachProfiles.filter(\.isPublic).count == 4)
        #expect(seed.programs.count == 5)
        #expect(seed.enrollments.count == 14)
        #expect(seed.enrollments.contains { $0.status == .completed })
        #expect(seed.leaderboardEntries.count == 18)
        #expect(seed.managedContent.contains { $0.kind == .winnerBanner })

        let activeProgram = try #require(
            seed.programs.first { $0.status == .active }
        )
        #expect(activeProgram.days.count == 7)
        #expect(activeProgram.days.allSatisfy { !$0.steps.isEmpty })
        #expect(
            activeProgram.days.flatMap(\.steps).contains {
                $0.content?.kind == .initialWeighIn
            }
        )
        #expect(
            activeProgram.days.flatMap(\.steps).contains {
                $0.content?.kind == .finalWeighIn
            }
        )
        #expect(
            activeProgram.days.flatMap(\.steps).contains {
                $0.instructionMedia?.kind == .image
            }
        )
        #expect(
            activeProgram.days.flatMap(\.steps).contains {
                $0.instructionMedia?.kind == .video
            }
        )
        #expect(
            activeProgram.days.flatMap(\.steps).contains {
                $0.content?.questions.contains {
                    $0.kind == .shortAnswer
                } == true
            }
        )
    }

    @Test("Fixture invalid menghasilkan error domain yang jelas")
    func invalidFixtureProducesClearDomainError() {
        let decoder = FixtureDecoder()

        do {
            let _: UsersFixture = try decoder.decode(
                UsersFixture.self,
                from: Data("{invalid".utf8),
                fileName: "users.json"
            )
            Issue.record("Fixture invalid seharusnya gagal.")
        } catch let error as DomainError {
            guard case .invalidFixture(let file, let reason) = error else {
                Issue.record("Jenis error fixture tidak sesuai.")
                return
            }
            #expect(file == "users.json")
            #expect(!reason.isEmpty)
        } catch {
            Issue.record("Error seharusnya dipetakan ke DomainError.")
        }
    }

    @Test("Decimal berat badan dapat di-encode dan decode tanpa berubah")
    func decimalWeightRoundTrip() throws {
        let value = WeighIn(
            id: UUID(uuidString: "41000000-0000-0000-0000-000000009999")!,
            enrollmentID: UUID(
                uuidString: "40000000-0000-0000-0000-000000009999"
            )!,
            type: .initial,
            weightKilograms: Decimal(string: "78.5")!,
            recordedAt: Date(timeIntervalSince1970: 1_785_028_400)
        )
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let decoded = try decoder.decode(
            WeighIn.self,
            from: encoder.encode(value)
        )

        #expect(decoded.weightKilograms == value.weightKilograms)
        #expect(decoded == value)
    }

    @Test("Raw value enum persisted tetap stabil")
    func persistedEnumRawValuesStayStable() {
        #expect(UserRole.participant.rawValue == "participant")
        #expect(ProgramStatus.scheduled.rawValue == "scheduled")
        #expect(
            ProgramDayVisibilityMode.readOnly.rawValue == "read_only"
        )
        #expect(
            SubmissionVerificationMode.coachReview.rawValue == "coach_review"
        )
        #expect(EnrollmentStatus.active.rawValue == "active")
        #expect(WeighInType.final.rawValue == "final")
        #expect(SubmissionStatus.rejected.rawValue == "rejected")
        #expect(ManagedContentKind.winnerBanner.rawValue == "winner_banner")
        #expect(AuditEventKind.scoreAdjusted.rawValue == "score_adjusted")
    }

    @Test("App environment memasang repository lokal")
    func appEnvironmentInstallsLocalRepositories() {
        let environment = AppEnvironment.preview

        #expect(environment.repositories != nil)
        #expect(environment.bootstrapError == nil)
    }
}
