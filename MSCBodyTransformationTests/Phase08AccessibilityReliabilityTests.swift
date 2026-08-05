import Foundation
import Testing
@testable import MSCBodyTransformation

@Suite("Phase 08 — aksesibilitas, demo, dan reliabilitas")
struct Phase08AccessibilityReliabilityTests {
    @Test("Launcher menyediakan seluruh skenario deterministik")
    func completeScenarioCatalog() {
        #expect(AppDemoScenario.allCases.count == 29)
        #expect(AppDemoScenario.scenarios(for: DemoRole.guest).count == 13)
        #expect(AppDemoScenario.scenarios(for: UserRole.participant).count == 12)
        #expect(AppDemoScenario.scenarios(for: UserRole.coach).count == 8)
        #expect(AppDemoScenario.scenarios(for: UserRole.admin).count == 9)

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
                for: UserRole.participant
            ) == .participant(.leaderboard)
        )
        #expect(
            AppDemoScenario.coachIdentifier.initialTab(for: UserRole.coach)
                == .coach(.dashboard)
        )
        #expect(
            AppDemoScenario.coachActiveParticipants.initialTab(for: UserRole.coach)
                == .coach(.dashboard)
        )
        #expect(
            AppDemoScenario.adminDashboard.initialTab(for: UserRole.admin)
                == .admin(.overview)
        )
        #expect(
            AppDemoScenario.adminDraftCMS.initialTab(for: UserRole.admin)
                == .admin(.programs)
        )
        #expect(
            AppDemoScenario.defaultScenario(for: UserRole.admin)
                == .adminDashboard
        )
    }

    @Test("Onboarding menjelaskan tahap tanpa bergantung pada tab")
    func participantEntryStagePresentationIsExplicit() {
        let login = ParticipantEntryStagePresentation(stage: .login)
        let profile = ParticipantEntryStagePresentation(stage: .profile)

        #expect(login.currentStep == 1)
        #expect(profile.currentStep == 2)
        #expect(login.totalSteps == 3)
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

        let adminDefault = DebugLaunchConfiguration(
            arguments: [
                "MSCBodyTransformation",
                "-DemoRole", "admin"
            ]
        )
        #expect(adminDefault.scenario == .adminDashboard)
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
