import Foundation

nonisolated struct MockSeedData: Sendable {
    let users: [AppUser]
    let participantProfiles: [ParticipantProfile]
    let coachProfiles: [CoachProfile]
    let programs: [Program]
    let enrollments: [ProgramEnrollment]
    let weighIns: [WeighIn]
    let submissions: [StepSubmission]
    let leaderboardEntries: [LeaderboardEntry]
    let winners: [ProgramWinner]
    let managedContent: [ManagedContent]
    let auditEvents: [AuditEvent]
    let coachApplications: [CoachApplication]

    static func load(
        using loader: LocalFixtureLoader = LocalFixtureLoader()
    ) throws -> Self {
        let users = try loader.load(UsersFixture.self, fileName: "users")
        let coaches = try loader.load(CoachesFixture.self, fileName: "coaches")
        let programs = try loader.load(
            ProgramsFixture.self,
            fileName: "programs"
        )
        let enrollments = try loader.load(
            EnrollmentsFixture.self,
            fileName: "enrollments"
        )
        let submissions = try loader.load(
            SubmissionsFixture.self,
            fileName: "submissions"
        )
        let leaderboard = try loader.load(
            LeaderboardFixture.self,
            fileName: "leaderboard"
        )
        let managedContent = try loader.load(
            ManagedContentFixture.self,
            fileName: "managed_content"
        )

        let coachApplications = try makeCoachApplications(
            users: users.users,
            participantProfiles: users.participantProfiles
        )

        return Self(
            users: users.users,
            participantProfiles: users.participantProfiles,
            coachProfiles: coaches.coachProfiles,
            programs: programs.programs,
            enrollments: enrollments.enrollments,
            weighIns: enrollments.weighIns,
            submissions: submissions.submissions,
            leaderboardEntries: leaderboard.entries,
            winners: leaderboard.winners,
            managedContent: managedContent.content,
            auditEvents: managedContent.auditEvents,
            coachApplications: coachApplications
        )
    }

    private static func makeCoachApplications(
        users: [AppUser],
        participantProfiles: [ParticipantProfile]
    ) throws -> [CoachApplication] {
        guard
            let userID = UUID(
                uuidString: "00000000-0000-0000-0000-000000000105"
            ),
            let applicationID = UUID(
                uuidString: "40000000-0000-0000-0000-000000000105"
            ),
            let user = users.first(where: { $0.id == userID }),
            let profile = participantProfiles.first(where: {
                $0.userID == userID
            })
        else {
            throw DomainError.invalidFixture(
                file: "users",
                reason: "Fixture pengajuan Coach tidak lengkap."
            )
        }

        let verifiedAt = Date(timeIntervalSince1970: 1_785_456_000)
        let period = CoachAccessPeriodCalculator().period(
            startingAt: verifiedAt
        )
        return [
            CoachApplication(
                id: applicationID,
                userID: user.id,
                participantProfileID: profile.id,
                displayNameSnapshot: profile.displayName,
                phoneNumberSnapshot: profile.phoneNumber ?? "",
                memberLevel: .millionaireTeam,
                hasCompletedHOMSTS: true,
                hasCompletedICT: true,
                termsVersion: "coach-terms-v1",
                status: .pendingAdminApproval,
                payment: CoachPaymentPreview(
                    priceBand: .leadership,
                    amountMinorUnits: CoachPriceBand.leadership
                        .amountMinorUnits,
                    state: .verified,
                    verifiedAt: verifiedAt,
                    accessStartsAt: period.start,
                    accessEndsAt: period.end
                ),
                createdAt: verifiedAt,
                submittedAt: verifiedAt,
                updatedAt: verifiedAt,
                decision: nil
            )
        ]
    }
}
