import Foundation

nonisolated struct AppRepositories: Sendable {
    let session: any SessionRepository
    let authentication: any AuthenticationRepository
    let profiles: any ProfileRepository
    let authenticatedParticipantReads:
        (any AuthenticatedParticipantReadRepository)?
    let coachDirectory: any CoachDirectoryRepository
    let publicCoachDirectory: any PublicCoachDirectoryRepository
    let programs: any ProgramRepository
    let publicPrograms: any PublicProgramRepository
    let enrollments: any EnrollmentRepository
    let submissions: any SubmissionRepository
    let weighIns: any WeighInRepository
    let leaderboard: any LeaderboardRepository
    let publicLeaderboard: any PublicLeaderboardRepository
    let coachParticipants: any CoachParticipantRepository
    let managedContent: any ManagedContentRepository
    let publicManagedContent: any PublicManagedContentRepository
    let adminPeople: any AdminPeopleRepository
    let coachApplications: any CoachApplicationRepository
    let adminProgramDrafts: any AdminProgramDraftRepository
    let audit: any AuditRepository
    let participantDemo: any ParticipantDemoRepository

    init(repository: InMemoryAppRepository) {
        session = repository
        authentication = repository
        profiles = repository
        authenticatedParticipantReads = nil
        coachDirectory = repository
        publicCoachDirectory = repository
        programs = repository
        publicPrograms = repository
        enrollments = repository
        submissions = repository
        weighIns = repository
        leaderboard = repository
        publicLeaderboard = repository
        coachParticipants = repository
        managedContent = repository
        publicManagedContent = repository
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
        authenticatedParticipantReads:
            any AuthenticatedParticipantReadRepository,
        publicCoachDirectory: any PublicCoachDirectoryRepository,
        publicPrograms: any PublicProgramRepository,
        publicLeaderboard: any PublicLeaderboardRepository,
        publicManagedContent: any PublicManagedContentRepository,
        phase11Fallback repository: InMemoryAppRepository
    ) {
        self.session = session
        self.authentication = authentication
        self.profiles = profiles
        self.authenticatedParticipantReads = authenticatedParticipantReads
        self.publicCoachDirectory = publicCoachDirectory
        self.publicPrograms = publicPrograms
        self.publicLeaderboard = publicLeaderboard
        self.publicManagedContent = publicManagedContent
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
