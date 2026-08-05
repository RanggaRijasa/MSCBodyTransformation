import Foundation

nonisolated enum UserRole: String, Codable, CaseIterable, Sendable {
    case participant
    case coach
    case admin
}

nonisolated struct AppUser: Codable, Equatable, Identifiable, Sendable {
    let id: UUID
    var email: String
    var displayName: String
    var role: UserRole
    var hasCompletedOnboarding: Bool
    var isCoachApprovalPending: Bool
    let createdAt: Date
}

nonisolated struct ParticipantProfile: Codable, Equatable, Identifiable, Sendable {
    let id: UUID
    let userID: UUID
    var coachID: UUID?
    var displayName: String
    var city: String
    var phoneNumber: String?
    var localPhotoReference: String?
    var memberLevel: MemberLevel? = nil
}

nonisolated struct CoachProfile: Codable, Equatable, Identifiable, Sendable {
    let id: UUID
    let userID: UUID
    let enrollmentIdentifier: String
    var displayName: String
    var biography: String
    var city: String
    var localPhotoReference: String?
    var isPublic: Bool
    var isApproved: Bool
}
