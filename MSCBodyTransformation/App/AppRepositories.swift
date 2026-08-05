import Foundation

nonisolated struct AppRepositories: Sendable {
    let session: any SessionRepository
    let authentication: any AuthenticationRepository
    let profiles: any ProfileRepository
    let coachDirectory: any CoachDirectoryRepository
    let programs: any ProgramRepository
    let enrollments: any EnrollmentRepository
    let submissions: any SubmissionRepository
    let weighIns: any WeighInRepository
    let leaderboard: any LeaderboardRepository
    let coachParticipants: any CoachParticipantRepository
    let managedContent: any ManagedContentRepository
    let adminPeople: any AdminPeopleRepository
    let coachApplications: any CoachApplicationRepository
    let adminProgramDrafts: any AdminProgramDraftRepository
    let audit: any AuditRepository
    let participantDemo: any ParticipantDemoRepository

    init(repository: InMemoryAppRepository) {
        session = repository
        authentication = repository
        profiles = repository
        coachDirectory = repository
        programs = repository
        enrollments = repository
        submissions = repository
        weighIns = repository
        leaderboard = repository
        coachParticipants = repository
        managedContent = repository
        adminPeople = repository
        coachApplications = repository
        adminProgramDrafts = repository
        audit = repository
        participantDemo = repository
    }

    init(
        session: any SessionRepository,
        authentication: any AuthenticationRepository,
        profiles: any ProfileRepository,
        phase11Fallback repository: InMemoryAppRepository
    ) {
        self.session = session
        self.authentication = authentication
        self.profiles = profiles
        coachDirectory = repository
        programs = repository
        enrollments = repository
        submissions = repository
        weighIns = repository
        leaderboard = repository
        coachParticipants = repository
        managedContent = repository
        adminPeople = repository
        coachApplications = repository
        adminProgramDrafts = repository
        audit = repository
        participantDemo = repository
    }
}
