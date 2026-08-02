import Foundation
import Testing
@testable import MSCBodyTransformation

@Suite("Phase 08 — aksesibilitas, demo, dan reliabilitas")
struct Phase08AccessibilityReliabilityTests {
    @Test("Launcher menyediakan seluruh 18 skenario deterministik")
    func completeScenarioCatalog() {
        #expect(AppDemoScenario.allCases.count == 18)
        #expect(AppDemoScenario.scenarios(for: .participant).count == 12)
        #expect(AppDemoScenario.scenarios(for: .coach).count == 8)
        #expect(AppDemoScenario.scenarios(for: .admin).count == 8)

        for role in UserRole.allCases {
            #expect(
                AppDemoScenario.scenarios(for: role).allSatisfy {
                    $0.supports(role)
                }
            )
        }
    }

    @Test("Skenario membuka tab yang sesuai dengan tujuan demo")
    func scenarioInitialTabs() {
        #expect(
            AppDemoScenario.participantFinalLeaderboard.initialTab(
                for: .participant
            ) == .participant(.leaderboard)
        )
        #expect(
            AppDemoScenario.coachWalletZero.initialTab(for: .coach)
                == .coach(.dashboard)
        )
        #expect(
            AppDemoScenario.coachActiveParticipants.initialTab(for: .coach)
                == .coach(.dashboard)
        )
        #expect(
            AppDemoScenario.adminDraftCMS.initialTab(for: .admin)
                == .admin(.programs)
        )
    }

    @Test("Onboarding menjelaskan tahap tanpa bergantung pada tab")
    func participantEntryStagePresentationIsExplicit() {
        let login = ParticipantEntryStagePresentation(stage: .login)
        let profile = ParticipantEntryStagePresentation(stage: .profile)
        let weighIn = ParticipantEntryStagePresentation(
            stage: .initialWeighIn
        )

        #expect(login.currentStep == 1)
        #expect(profile.currentStep == 2)
        #expect(weighIn.currentStep == 4)
        #expect(login.totalSteps == 4)
        #expect(profile.titleKey == "participant.entry.stage.profile")
    }

    @Test("Status final leaderboard memakai satu presentasi konsisten")
    func finalLeaderboardStatusIsConsistent() throws {
        let seed = try MockSeedData.load()
        let program = try #require(
            seed.programs.first(where: { $0.status == .active })
        )

        let provisional = ParticipantLeaderboardStatusPresentation(
            program: program,
            showsFinalLeaderboard: false,
            hasLockedWinners: false
        )
        let final = ParticipantLeaderboardStatusPresentation(
            program: program,
            showsFinalLeaderboard: true,
            hasLockedWinners: false
        )

        #expect(!provisional.isFinal)
        #expect(
            provisional.badgeTitleKey
                == "participant.leaderboard.status.in_progress"
        )
        #expect(final.isFinal)
        #expect(
            final.badgeTitleKey
                == "participant.leaderboard.status.completed"
        )
    }

    @Test("Poster program membedakan partisipasi dan status operasional")
    func programPosterParticipationStatusIsParticipantSpecific() throws {
        let seed = try MockSeedData.load()
        var enrollment = try #require(
            seed.enrollments.first(where: { $0.status == .active })
        )

        #expect(
            ParticipantProgramParticipationStatus.make(
                programID: enrollment.programID,
                enrollments: [enrollment]
            ) == .enrolled
        )

        enrollment.status = .cancelled
        #expect(
            ParticipantProgramParticipationStatus.make(
                programID: enrollment.programID,
                enrollments: [enrollment]
            ) == .notEnrolled
        )
    }

    @MainActor
    @Test("Skenario tanpa program menyembunyikan enrollment aktif")
    func noProgramScenarioHidesActiveEnrollments() async {
        let store = ParticipantJourneyStore(environment: .preview)
        await store.load()

        store.hidesActiveProgramForDemo = true

        #expect(store.currentProgram == nil)
        #expect(store.currentEnrollment == nil)
        #expect(
            store.visibleEnrollments.allSatisfy {
                $0.status == .completed || $0.status == .cancelled
            }
        )
    }

#if DEBUG
    @Test("Nama launch lama tetap dipetakan tanpa mengubah skenario")
    func legacyLaunchArgumentsRemainCompatible() {
        let participant = DebugLaunchConfiguration(
            arguments: [
                "MSCBodyTransformation",
                "-DemoScenario", "participant_active"
            ]
        )
        let admin = DebugLaunchConfiguration(
            arguments: [
                "MSCBodyTransformation",
                "-DemoRole", "admin",
                "-DemoScenario", "admin_draft_editor"
            ]
        )

        #expect(participant.scenario == .participantActive)
        #expect(admin.scenario == .adminDraftCMS)
    }
#endif

    @Test("Sesi lokal dapat dipulihkan setelah state logged out")
    func fakeSessionRestoration() async throws {
        let repository = try makeRepository()
        await repository.setDebugScenario(.loggedOut)
        let loggedOut = try await repository.loadCurrentSession()
        #expect(loggedOut.state == .loggedOut)
        #expect(loggedOut.user == nil)

        _ = try await repository.switchDebugRole(to: .coach)
        let restored = try await repository.loadCurrentSession()
        #expect(restored.state == .active)
        #expect(restored.role == .coach)
    }

    @Test("Skenario saldo nol dapat diulang tanpa nilai negatif")
    func walletZeroScenarioIsIdempotent() async throws {
        let seed = try MockSeedData.load()
        let coachID = try #require(
            seed.coachProfiles.first(where: { $0.isApproved })?.id
        )
        let repository = InMemoryAppRepository(seed: seed)
        _ = try await repository.setSeatCredits(
            coachID: coachID,
            amount: 0,
            updatedAt: Date(timeIntervalSince1970: 0)
        )
        _ = try await repository.setSeatCredits(
            coachID: coachID,
            amount: 0,
            updatedAt: Date(timeIntervalSince1970: 0)
        )

        let wallet = try await repository.wallet(
            coachID: coachID
        )
        #expect(wallet.availableSeatCredits == 0)
    }

    @Test("Hari pertama mereset progres tetapi mempertahankan pendaftaran")
    func dayOneScenarioResetsOnlyProgress() async throws {
        let seed = try MockSeedData.load()
        let enrollment = try #require(
            seed.enrollments.first(where: { $0.status == .active })
        )
        let repository = InMemoryAppRepository(seed: seed)

        await repository.resetParticipantProgress(
            participantID: enrollment.participantID
        )

        let enrollments = try await repository.enrollments(
            participantID: enrollment.participantID
        )
        let submissions = try await repository.submissions(
            enrollmentID: enrollment.id
        )
        let weighIns = try await repository.weighIns(
            enrollmentID: enrollment.id
        )
        #expect(enrollments.contains { $0.id == enrollment.id })
        #expect(submissions.isEmpty)
        #expect(weighIns.contains { $0.type == .initial })
        #expect(!weighIns.contains { $0.type == .final })
    }

    @Test("Semua error kritis memiliki judul dan pesan lokal")
    func criticalErrorsHaveActionableCopyKeys() {
        let errors: [DomainError] = [
            .permissionDenied,
            .offline,
            .timeout,
            .sessionExpired,
            .unknown
        ]

        for error in errors {
            let message = DomainErrorMessageMapper.message(for: error)
            #expect(!message.titleKey.isEmpty)
            #expect(!message.messageKey.isEmpty)
            #expect(message.titleKey.hasPrefix("error."))
            #expect(message.messageKey.hasPrefix("error."))
        }
    }

    private func makeRepository() throws -> InMemoryAppRepository {
        InMemoryAppRepository(
            seed: try MockSeedData.load()
        )
    }
}
