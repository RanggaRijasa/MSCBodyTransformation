import Foundation

nonisolated struct AuthenticatedAccountReadModel:
    Equatable,
    Sendable
{
    let publicProfileID: UUID
    let role: UserRole
    let displayName: String
    let city: String
    let phoneNumber: String?
    let currentCoachID: UUID?
    let avatarReference: String?
    let memberLevel: MemberLevel?
    let onboardingStatus: ProfileOnboardingStatus
    let accountPurpose: AccountPurpose

    func participantProfile(userID: UUID) throws -> ParticipantProfile {
        guard role == .participant else {
            throw DomainError.permissionDenied
        }
        return ParticipantProfile(
            id: userID,
            userID: userID,
            coachID: currentCoachID,
            displayName: displayName,
            city: city,
            phoneNumber: phoneNumber,
            localPhotoReference: avatarReference,
            memberLevel: memberLevel
        )
    }
}

nonisolated struct AuthenticatedProgramDayAccessState:
    Equatable,
    Identifiable,
    Sendable
{
    var id: UUID { programDayID }
    let enrollmentID: UUID
    let programID: UUID
    let programDayID: UUID
    let dayNumber: Int
    let access: ProgramDayAccess
    let isCurrentDay: Bool
}

nonisolated struct AuthenticatedDashboardSummary:
    Equatable,
    Sendable
{
    let role: UserRole
    let activeEnrollmentCount: Int
    let completedEnrollmentCount: Int
    let pendingSubmissionCount: Int
    let assignedParticipantCount: Int
}

nonisolated struct AuthenticatedAssignedCoachReadModel:
    Equatable,
    Sendable
{
    let publicProfileID: UUID
    let profile: CoachProfile
}

nonisolated struct AuthenticatedParticipantReadSnapshot:
    Equatable,
    Sendable
{
    let account: AuthenticatedAccountReadModel
    let programs: [Program]
    let enrollments: [ProgramEnrollment]
    let enrollmentContexts: [ProgramEnrollmentContext]
    let assignedCoach: AuthenticatedAssignedCoachReadModel?
    let dayAccessStates: [AuthenticatedProgramDayAccessState]
    let dashboardSummary: AuthenticatedDashboardSummary

}
