import Foundation

nonisolated enum DomainError: Error, Equatable, Sendable {
    case validation(field: String, reason: String)
    case notFound(resource: String)
    case permissionDenied
    case conflict(reason: String)
    case offline
    case timeout
    case sessionExpired
    case invalidFixture(file: String, reason: String)
    case unknown
}

nonisolated struct DomainErrorMessage: Equatable, Sendable {
    let titleKey: String
    let messageKey: String
}

nonisolated enum DomainErrorMessageMapper {
    static func message(for error: DomainError) -> DomainErrorMessage {
        switch error {
        case .validation:
            DomainErrorMessage(
                titleKey: "error.validation.title",
                messageKey: "error.validation.message"
            )
        case .notFound:
            DomainErrorMessage(
                titleKey: "error.not_found.title",
                messageKey: "error.not_found.message"
            )
        case .permissionDenied:
            DomainErrorMessage(
                titleKey: "error.permission.title",
                messageKey: "error.permission.message"
            )
        case .conflict:
            DomainErrorMessage(
                titleKey: "error.conflict.title",
                messageKey: "error.conflict.message"
            )
        case .offline:
            DomainErrorMessage(
                titleKey: "error.offline.title",
                messageKey: "error.offline.message"
            )
        case .timeout:
            DomainErrorMessage(
                titleKey: "error.timeout.title",
                messageKey: "error.timeout.message"
            )
        case .sessionExpired:
            DomainErrorMessage(
                titleKey: "error.session_expired.title",
                messageKey: "error.session_expired.message"
            )
        case .invalidFixture, .unknown:
            DomainErrorMessage(
                titleKey: "error.unknown.title",
                messageKey: "error.unknown.message"
            )
        }
    }
}
