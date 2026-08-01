import Foundation

nonisolated struct CoachIdentity: Equatable, Sendable {
    let user: AppUser
    let profile: CoachProfile
}

nonisolated struct CoachDataService: Sendable {
    let environment: AppEnvironment

    func identity() async throws -> CoachIdentity {
        guard let repositories = environment.repositories else {
            throw environment.bootstrapError ?? DomainError.unknown
        }
        var session = try await repositories.session.loadCurrentSession()
        if session.role != .coach {
            session = try await repositories.session.switchDebugRole(to: .coach)
        }
        guard let user = session.user, user.role == .coach else {
            throw DomainError.permissionDenied
        }
        let profile = try await repositories.profiles.coachProfile(
            userID: user.id
        )
        return CoachIdentity(user: user, profile: profile)
    }

    func participantSummaries(
        coachID: UUID
    ) async throws -> [CoachParticipantSummary] {
        guard let repositories = environment.repositories else {
            throw environment.bootstrapError ?? DomainError.unknown
        }
        let profiles = try await repositories.coachParticipants
            .assignedParticipants(coachID: coachID)
        let programs = try await repositories.programs.programs()
        let programsByID = Dictionary(
            uniqueKeysWithValues: programs.map { ($0.id, $0) }
        )

        var summaries: [CoachParticipantSummary] = []
        for profile in profiles {
            summaries.append(
                try await summary(
                    for: profile,
                    coachID: coachID,
                    programsByID: programsByID,
                    repositories: repositories
                )
            )
        }
        return summaries
    }

    func participantSummary(
        participantID: UUID,
        coachID: UUID
    ) async throws -> CoachParticipantSummary {
        guard let repositories = environment.repositories else {
            throw environment.bootstrapError ?? DomainError.unknown
        }
        let profile = try await repositories.coachParticipants
            .assignedParticipant(id: participantID, coachID: coachID)
        let programs = try await repositories.programs.programs()
        return try await summary(
            for: profile,
            coachID: coachID,
            programsByID: Dictionary(
                uniqueKeysWithValues: programs.map { ($0.id, $0) }
            ),
            repositories: repositories
        )
    }

    func reviewItems(
        coachID: UUID
    ) async throws -> [CoachReviewItem] {
        guard let repositories = environment.repositories else {
            throw environment.bootstrapError ?? DomainError.unknown
        }
        let profiles = try await repositories.coachParticipants
            .assignedParticipants(coachID: coachID)
        let programs = try await repositories.programs.programs()
        let programsByID = Dictionary(
            uniqueKeysWithValues: programs.map { ($0.id, $0) }
        )

        var reviewItems: [CoachReviewItem] = []
        for profile in profiles {
            let enrollments = try await repositories.enrollments.enrollments(
                participantID: profile.id
            )
            .filter { $0.coachID == coachID }

            for enrollment in enrollments {
                guard let program = programsByID[enrollment.programID] else {
                    continue
                }
                let submissions = try await repositories.submissions
                    .submissions(enrollmentID: enrollment.id)
                let leaderboard = try await repositories.leaderboard
                    .leaderboard(programID: program.id)
                let score = leaderboard.first {
                    $0.participantID == profile.id
                }?.score.totalPoints ?? 0

                reviewItems.append(
                    contentsOf: submissions.compactMap { submission in
                        guard !submission.evidence.isEmpty,
                              let day = program.days.first(where: { day in
                                  day.steps.contains {
                                      $0.id == submission.stepID
                                  }
                              }),
                              let step = day.steps.first(where: {
                                  $0.id == submission.stepID
                              }) else {
                            return nil
                        }
                        return CoachReviewItem(
                            submission: submission,
                            participant: profile,
                            enrollment: enrollment,
                            program: program,
                            day: day,
                            step: step,
                            scoreBeforeReview: score
                        )
                    }
                )
            }
        }

        return reviewItems.sorted { lhs, rhs in
            let lhsNeedsAction = lhs.submission.status == .pending
                && lhs.step.verificationMode == .coachReview
            let rhsNeedsAction = rhs.submission.status == .pending
                && rhs.step.verificationMode == .coachReview
            if lhsNeedsAction != rhsNeedsAction {
                return lhsNeedsAction
            }
            return lhs.submission.submittedAt > rhs.submission.submittedAt
        }
    }

    private func summary(
        for profile: ParticipantProfile,
        coachID: UUID,
        programsByID: [UUID: Program],
        repositories: AppRepositories
    ) async throws -> CoachParticipantSummary {
        let enrollments = try await repositories.enrollments.enrollments(
            participantID: profile.id
        )
        .filter { $0.coachID == coachID }
        let associatedPrograms = enrollments.compactMap {
            programsByID[$0.programID]
        }
        let enrollment = enrollments.sorted {
            if $0.status == .active, $1.status != .active {
                return true
            }
            if $0.status != .active, $1.status == .active {
                return false
            }
            return $0.enrolledAt > $1.enrolledAt
        }.first

        guard let enrollment else {
            return CoachParticipantSummary(
                profile: profile,
                enrollment: nil,
                program: nil,
                submissions: [],
                weighIns: [],
                leaderboardEntry: nil,
                associatedPrograms: associatedPrograms
            )
        }

        let submissions = try await repositories.submissions.submissions(
            enrollmentID: enrollment.id
        )
        let weighIns = try await repositories.weighIns.weighIns(
            enrollmentID: enrollment.id
        )
        let leaderboard = try await repositories.leaderboard.leaderboard(
            programID: enrollment.programID
        )
        return CoachParticipantSummary(
            profile: profile,
            enrollment: enrollment,
            program: programsByID[enrollment.programID],
            submissions: submissions,
            weighIns: weighIns,
            leaderboardEntry: leaderboard.first {
                $0.participantID == profile.id
            },
            associatedPrograms: associatedPrograms
        )
    }
}
