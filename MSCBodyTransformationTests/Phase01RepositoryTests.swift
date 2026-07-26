import Foundation
import Testing
@testable import MSCBodyTransformation

@Suite("Repository lokal Phase 01")
struct Phase01RepositoryTests {
    @Test("Role switcher menyediakan ketiga fake session")
    func roleSwitcherProvidesAllFakeSessions() async throws {
        let repository = try makeRepository()

        for role in UserRole.allCases {
            let session = try await repository.switchDebugRole(to: role)
            #expect(session.state == .active)
            #expect(session.role == role)
        }

        await repository.setDebugScenario(.loggedOut)
        #expect(try await repository.loadCurrentSession().state == .loggedOut)

        await repository.setDebugScenario(
            .onboardingIncomplete(.participant)
        )
        #expect(
            try await repository.loadCurrentSession().requiresOnboarding
        )

        await repository.setDebugScenario(.expired)
        do {
            _ = try await repository.loadCurrentSession()
            Issue.record("Session kedaluwarsa seharusnya gagal.")
        } catch let error as DomainError {
            #expect(error == .sessionExpired)
        }
    }

    @Test("Pembuatan enrollment duplikat bersifat idempoten")
    func duplicateEnrollmentIsIdempotent() async throws {
        let repository = try makeRepository()
        let programID = try #require(
            try await repository.activeProgram()?.id
        )
        let participantID = UUID(
            uuidString: "20000000-0000-0000-0000-000000000001"
        )!
        let existing = try #require(
            try await repository.enrollment(
                programID: programID,
                participantID: participantID
            )
        )
        let duplicate = ProgramEnrollment(
            id: UUID(),
            programID: programID,
            participantID: participantID,
            coachID: existing.coachID,
            status: .active,
            enrolledAt: Date()
        )

        let result = try await repository.createEnrollment(duplicate)

        #expect(result.id == existing.id)
        #expect(
            try await repository.enrollments(
                participantID: participantID
            ).filter { $0.programID == programID }.count == 1
        )
    }

    @Test("Completion paralel hanya menyimpan satu submission")
    func concurrentCompletionStoresOneSubmission() async throws {
        let repository = try makeRepository()
        let enrollmentID = UUID(
            uuidString: "40000000-0000-0000-0000-000000000001"
        )!
        let stepID = UUID(
            uuidString: "12000000-0000-0000-0000-000000000021"
        )!
        let submission = StepSubmission(
            id: UUID(
                uuidString: "50000000-0000-0000-0000-000000009999"
            )!,
            enrollmentID: enrollmentID,
            stepID: stepID,
            evidence: [],
            status: .approved,
            submittedAt: Date(timeIntervalSince1970: 1_785_028_400),
            reviewedAt: nil,
            reviewerID: nil,
            reviewNote: nil
        )

        try await withThrowingTaskGroup(of: StepSubmission.self) { group in
            for _ in 0..<50 {
                group.addTask {
                    try await repository.completeStep(submission: submission)
                }
            }
            for try await result in group {
                #expect(result.id == submission.id)
            }
        }

        let stored = try await repository.submissions(
            enrollmentID: enrollmentID
        )
        #expect(stored.filter { $0.stepID == stepID }.count == 1)
    }

    @Test("Seed coach menyediakan peserta dan antrian review")
    func coachSeedProvidesParticipantsAndReviewQueue() async throws {
        let repository = try makeRepository()
        let coachID = UUID(
            uuidString: "30000000-0000-0000-0000-000000000101"
        )!

        let participants = try await repository.assignedParticipants(
            coachID: coachID
        )
        let queue = try await repository.reviewQueue(coachID: coachID)
        let wallet = try await repository.wallet(coachID: coachID)

        #expect(participants.count == 6)
        #expect(queue.count == 3)
        #expect(wallet.availableSeatCredits == 8)
    }

    private func makeRepository() throws -> InMemoryAppRepository {
        InMemoryAppRepository(seed: try MockSeedData.load())
    }
}
