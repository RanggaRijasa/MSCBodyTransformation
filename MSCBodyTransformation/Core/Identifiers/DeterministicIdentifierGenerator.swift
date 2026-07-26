import Foundation

nonisolated struct DeterministicIdentifierGenerator: IdentifierGenerating {
    let identifier: UUID

    func makeIdentifier() -> UUID {
        identifier
    }
}
