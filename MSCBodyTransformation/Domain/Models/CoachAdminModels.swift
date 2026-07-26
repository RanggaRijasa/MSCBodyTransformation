import Foundation

nonisolated struct CoachWallet: Codable, Equatable, Identifiable, Sendable {
    let id: UUID
    let coachID: UUID
    var availableSeatCredits: Int
    var updatedAt: Date
}

nonisolated enum CreditLedgerEntryKind: String, Codable, CaseIterable, Sendable {
    case purchase
    case reservation
    case refund
    case adjustment
}

nonisolated struct CreditLedgerEntry: Codable, Equatable, Identifiable, Sendable {
    let id: UUID
    let walletID: UUID
    let kind: CreditLedgerEntryKind
    let seatCreditDelta: Int
    let note: String
    let createdAt: Date
}

nonisolated enum CoachInviteStatus: String, Codable, CaseIterable, Sendable {
    case active
    case redeemed
    case expired
    case revoked
}

nonisolated struct CoachInvite: Codable, Equatable, Identifiable, Sendable {
    let id: UUID
    let code: String
    let coachID: UUID
    let programID: UUID
    var status: CoachInviteStatus
    let createdAt: Date
    let expiresAt: Date
    var redeemedByParticipantID: UUID?
}

nonisolated enum ManagedContentKind: String, Codable, CaseIterable, Sendable {
    case winnerBanner = "winner_banner"
    case announcement
    case wellnessDisclaimer = "wellness_disclaimer"
}

nonisolated struct ManagedContent: Codable, Equatable, Identifiable, Sendable {
    let id: UUID
    let kind: ManagedContentKind
    var title: String
    var body: String
    var isPublished: Bool
    var updatedAt: Date
}

nonisolated enum AuditEventKind: String, Codable, CaseIterable, Sendable {
    case programCreated = "program_created"
    case programUpdated = "program_updated"
    case submissionReviewed = "submission_reviewed"
    case scoreAdjusted = "score_adjusted"
    case inviteRedeemed = "invite_redeemed"
}

nonisolated struct AuditEvent: Codable, Equatable, Identifiable, Sendable {
    let id: UUID
    let kind: AuditEventKind
    let actorUserID: UUID
    let subjectID: UUID
    let summary: String
    let createdAt: Date
}
