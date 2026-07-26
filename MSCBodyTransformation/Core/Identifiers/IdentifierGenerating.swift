import Foundation

nonisolated protocol IdentifierGenerating: Sendable {
    func makeIdentifier() -> UUID
}
