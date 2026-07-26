import Foundation

nonisolated struct AppRepositories: Sendable {
    let session: any SessionRepository
    let profiles: any ProfileRepository
    let coachDirectory: any CoachDirectoryRepository
    let programs: any ProgramRepository
    let enrollments: any EnrollmentRepository
    let submissions: any SubmissionRepository
    let weighIns: any WeighInRepository
    let leaderboard: any LeaderboardRepository
    let coachParticipants: any CoachParticipantRepository
    let invites: any InviteRepository
    let wallet: any WalletRepository
    let managedContent: any ManagedContentRepository
    let adminPeople: any AdminPeopleRepository
    let adminProgramDrafts: any AdminProgramDraftRepository
    let audit: any AuditRepository
    let participantDemo: any ParticipantDemoRepository
    let coachDemo: any CoachDemoRepository

    init(repository: InMemoryAppRepository) {
        session = repository
        profiles = repository
        coachDirectory = repository
        programs = repository
        enrollments = repository
        submissions = repository
        weighIns = repository
        leaderboard = repository
        coachParticipants = repository
        invites = repository
        wallet = repository
        managedContent = repository
        adminPeople = repository
        adminProgramDrafts = repository
        audit = repository
        participantDemo = repository
        coachDemo = repository
    }
}
