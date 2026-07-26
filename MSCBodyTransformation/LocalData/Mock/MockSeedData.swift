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
    let wallets: [CoachWallet]
    let creditLedgerEntries: [CreditLedgerEntry]
    let invites: [CoachInvite]
    let managedContent: [ManagedContent]
    let auditEvents: [AuditEvent]

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
            wallets: coaches.wallets,
            creditLedgerEntries: coaches.creditLedgerEntries,
            invites: coaches.invites,
            managedContent: managedContent.content,
            auditEvents: managedContent.auditEvents
        )
    }
}
