import Foundation

nonisolated enum ProgramStatus: String, Codable, CaseIterable, Sendable {
    case draft
    case preparingCommerce = "preparing_commerce"
    case scheduled
    case active
    case completed
    case archived
}

nonisolated enum ProgramDayVisibilityMode: String, Codable, CaseIterable, Sendable {
    case standard
    case hidden
    case readOnly = "read_only"
}

nonisolated enum ProgramDayAccess: String, Equatable, Sendable {
    case hidden
    case locked
    case readOnly = "read_only"
    case available
}

nonisolated enum StepInstructionMediaKind: String, Codable, CaseIterable, Sendable {
    case image
    case video
}

nonisolated struct StepInstructionMedia: Codable, Equatable, Sendable {
    let kind: StepInstructionMediaKind
    let resourceName: String
    let accessibilityLabel: String
}

nonisolated enum SubmissionVerificationMode: String, Codable, CaseIterable, Sendable {
    case automatic
    case coachReview = "coach_review"
}

nonisolated struct ProgramStep: Codable, Equatable, Identifiable, Sendable {
    let id: UUID
    let programDayID: UUID
    var order: Int
    var title: String
    var instructions: String
    var instructionMedia: StepInstructionMedia?
    var verificationMode: SubmissionVerificationMode
    var content: ProgramStepContent? = nil
}

nonisolated struct ProgramDay: Codable, Equatable, Identifiable, Sendable {
    let id: UUID
    let programID: UUID
    var dayNumber: Int
    var title: String
    var scheduledDate: Date
    var visibilityMode: ProgramDayVisibilityMode
    var steps: [ProgramStep]
    var summary: String? = nil
}

nonisolated struct Program: Codable, Equatable, Identifiable, Sendable {
    let id: UUID
    var sourceProgramID: UUID? = nil
    var title: String
    var summary: String
    var category: String? = nil
    var coverLocalReference: String? = nil
    var coverAlternativeText: String? = nil
    var price: Decimal?
    var status: ProgramStatus
    var startDate: Date
    var endDate: Date
    var timeZoneIdentifier: String
    var weightPointsPerKilogram: Decimal
    var scoringConfiguration: ProgramScoringConfiguration? = nil
    var commerceConfiguration: ProgramCommerceConfiguration? = nil
    var pace: AdminProgramPace? = nil
    var durationMode: AdminProgramDurationMode? = nil
    var participantLimit: Int? = nil
    var pastStepPolicy: PastStepPolicy? = nil
    var futureStepPolicy: FutureStepPolicy? = nil
    var wellnessDisclaimer: String? = nil
    var days: [ProgramDay]

    var effectiveScoringConfiguration: ProgramScoringConfiguration {
        scoringConfiguration ?? ProgramScoringConfiguration(
            pointsPerActivity: 0,
            pointsPerWeightLossKilogram: weightPointsPerKilogram,
            quizPassingPercentage: 70
        )
    }

    var effectiveCommerceConfiguration: ProgramCommerceConfiguration {
        commerceConfiguration ?? ProgramCommerceConfiguration(
            pricingMode: price == nil ? .free : .paid,
            desiredPrice: price,
            platformAvailability: CommercePlatform.allCases.map {
                ProgramPlatformAvailability(
                    platform: $0,
                    isEnabled: true,
                    provisioningStatus: price == nil ? .notRequired : .notRequested
                )
            }
        )
    }

    var durationInDays: Int {
        if !days.isEmpty {
            return days.count
        }

        let secondsPerDay: TimeInterval = 24 * 60 * 60
        let interval = max(endDate.timeIntervalSince(startDate), 0)
        return max(Int(ceil(interval / secondsPerDay)), 1)
    }

    func lifecycleStatus(at date: Date) -> ProgramStatus {
        switch status {
        case .draft, .preparingCommerce, .completed, .archived:
            return status
        case .scheduled, .active:
            if date < startDate {
                return .scheduled
            }
            if date > endDate {
                return .completed
            }
            return .active
        }
    }
}
